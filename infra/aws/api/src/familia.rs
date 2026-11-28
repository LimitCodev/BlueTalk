use serde::Deserialize;

use crate::auth::{familia_autenticada, fid_valido, hex, sha256};
use crate::error::ErrorApi;
use crate::estado::{Almacen, Estado, Google};
use crate::http::Respuesta;

/// Segundos que se confía en una suscripción verificada antes de volver a
/// preguntar a Google.
pub const CACHE_SUSCRIPCION: u64 = 86_400;
/// Niños (fids) que cubre un mismo pago.
pub const FIDS_POR_PAGO: usize = 3;

#[derive(Clone, Debug)]
pub struct Familia {
    pub fid: String,
    pub wh: [u8; 32],
    pub token: String,
    pub hasta: u64,
    pub fin: u64,
}

#[derive(Debug, PartialEq)]
pub enum Alta {
    /// `fid` nuevo, guardado y ligado al token de compra.
    Nueva,
    /// El `fid` ya existía con el mismo `wh`; se actualizaron token, `hasta` y `fin`.
    YaExistia,
    /// El token de compra ya liga `max` fids (y este no es uno de ellos). No se guardó nada.
    Llena,
    /// El `fid` ya existe con otro `wh`. No se tocó nada: nunca se sobrescribe una familia ajena.
    OtroWh,
}

#[derive(Deserialize)]
struct PeticionAlta {
    fid: String,
    wh: String,
    compra: String,
    integridad: String,
}

fn hex32(s: &str) -> Option<[u8; 32]> {
    if s.len() != 64 || !s.bytes().all(|c| c.is_ascii_digit() || (b'a'..=b'f').contains(&c)) {
        return None;
    }
    let mut out = [0u8; 32];
    for (i, par) in s.as_bytes().chunks(2).enumerate() {
        out[i] = u8::from_str_radix(std::str::from_utf8(par).ok()?, 16).ok()?;
    }
    Some(out)
}

/// Un veredicto de Integrity vale 5 minutos; se admite 1 minuto de desfase del reloj.
const VEREDICTO_MAX_EDAD_MS: u64 = 300_000;
const VEREDICTO_MAX_ADELANTO_MS: u64 = 60_000;

/// `POST /v1/familia`: Integrity (hash de `fid|wh`, reciente) → suscripción → alta → reconocer compra.
pub async fn activar<A: Almacen, G: Google>(e: &Estado<A, G>, cuerpo: &[u8], ahora: u64) -> Result<Respuesta, ErrorApi> {
    let p: PeticionAlta = serde_json::from_slice(cuerpo).map_err(|_| ErrorApi::Peticion)?;
    let wh = hex32(&p.wh).ok_or(ErrorApi::Peticion)?;
    let tamanos_ok = (1..=4096).contains(&p.compra.len()) && (1..=8192).contains(&p.integridad.len());
    if !fid_valido(&p.fid) || !tamanos_ok {
        return Err(ErrorApi::Peticion);
    }

    let v = e.google.integridad(&p.integridad).await?;
    let ahora_ms = ahora * 1000;
    let fresco = v.timestamp_ms.saturating_add(VEREDICTO_MAX_EDAD_MS) >= ahora_ms && v.timestamp_ms <= ahora_ms + VEREDICTO_MAX_ADELANTO_MS;
    let integra = fresco
        && v.paquete == e.cfg.paquete
        && v.reconocida
        && v.dispositivo_ok
        && v.hash_peticion == hex(&sha256(format!("{}|{}", p.fid, p.wh).as_bytes()));
    if !integra {
        return Err(ErrorApi::Token);
    }

    let s = e.google.suscripcion(&p.compra).await?;
    if !s.activa || s.producto != e.cfg.producto {
        return Err(ErrorApi::Suscripcion);
    }

    let hasta = s.fin.min(ahora + CACHE_SUSCRIPCION);
    let f = Familia { fid: p.fid, wh, token: p.compra, hasta, fin: s.fin };
    let estado = match e.almacen.alta(&f, &hex(&sha256(f.token.as_bytes())), FIDS_POR_PAGO).await? {
        Alta::Nueva => 201,
        Alta::YaExistia => 200,
        Alta::Llena => return Err(ErrorApi::Lleno),
        Alta::OtroWh => return Err(ErrorApi::Token),
    };
    if !s.reconocida {
        e.google.reconocer(&e.cfg.producto, &f.token).await?;
    }
    Ok(Respuesta::json(estado, &serde_json::json!({ "hasta": hasta })))
}

/// `DELETE /v1/familia`: derecho de supresión. Solo autentica; no exige vigencia ni cuota,
/// así que vale aunque la suscripción haya vencido.
pub async fn borrar<A: Almacen, G: Google>(e: &Estado<A, G>, auth: Option<&str>) -> Result<Respuesta, ErrorApi> {
    let f = familia_autenticada(&e.almacen, auth).await?;
    e.almacen.borrar_familia(&f.fid, &hex(&sha256(f.token.as_bytes()))).await?;
    Ok(Respuesta::vacia(204))
}
