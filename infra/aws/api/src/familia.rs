use serde::Deserialize;

use crate::auth::{fid_valido, hex, sha256};
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
    Nueva,
    YaExistia,
    Llena,
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

/// `POST /v1/familia`: Integrity → suscripción → alta → reconocer compra.
pub async fn activar<A: Almacen, G: Google>(e: &Estado<A, G>, cuerpo: &[u8], ahora: u64) -> Result<Respuesta, ErrorApi> {
    let p: PeticionAlta = serde_json::from_slice(cuerpo).map_err(|_| ErrorApi::Peticion)?;
    let wh = hex32(&p.wh).ok_or(ErrorApi::Peticion)?;
    let tamanos_ok = (1..=4096).contains(&p.compra.len()) && (1..=8192).contains(&p.integridad.len());
    if !fid_valido(&p.fid) || !tamanos_ok {
        return Err(ErrorApi::Peticion);
    }

    let v = e.google.integridad(&p.integridad).await?;
    let integra = v.paquete == e.cfg.paquete
        && v.reconocida
        && v.dispositivo_ok
        && v.hash_peticion == hex(&sha256(p.fid.as_bytes()));
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
    };
    if !s.reconocida {
        e.google.reconocer(&e.cfg.producto, &f.token).await?;
    }
    Ok(Respuesta::json(estado, &serde_json::json!({ "hasta": hasta })))
}
