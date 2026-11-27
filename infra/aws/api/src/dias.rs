use serde::Deserialize;

use crate::auth::familia_autenticada;
use crate::b64;
use crate::cuotas;
use crate::error::ErrorApi;
use crate::estado::{Almacen, Estado, Google};
use crate::fecha::{dia_civil, es_dia_valido};
use crate::http::Respuesta;
use crate::vigencia::{Uso, exigir_vigencia};

const BLOQUE_MAX: usize = 4096;
const DIAS_POR_LLAMADA: usize = 7;
const DIAS_POR_LECTURA: usize = 62;
/// Los días cifrados caducan a los 400 días de escritos.
const TTL_DIAS: u64 = 400 * 86_400;

#[derive(Deserialize)]
struct PeticionDias {
    dias: Vec<Dia>,
}

#[derive(Deserialize)]
struct Dia {
    d: String,
    b: String,
}

/// `PUT /v1/dias`: autenticar → vigencia → validar → cuota → guardar.
pub async fn subir<A: Almacen, G: Google>(e: &Estado<A, G>, auth: Option<&str>, cuerpo: &[u8], ahora: u64) -> Result<Respuesta, ErrorApi> {
    let f = familia_autenticada(&e.almacen, auth).await?;
    exigir_vigencia(e, &f, Uso::Escribir, ahora).await?;
    let p: PeticionDias = serde_json::from_slice(cuerpo).map_err(|_| ErrorApi::Peticion)?;
    if p.dias.is_empty() || p.dias.len() > DIAS_POR_LLAMADA {
        return Err(ErrorApi::Peticion);
    }
    let ultimo = dia_civil(ahora + 86_400);
    let mut dias: Vec<(String, Vec<u8>)> = Vec::with_capacity(p.dias.len());
    for Dia { d, b } in p.dias {
        // El almacén real rechaza claves repetidas en una misma escritura.
        if !es_dia_valido(&d) || d > ultimo || dias.iter().any(|(x, _)| *x == d) {
            return Err(ErrorApi::Peticion);
        }
        let bytes = b64::decodificar(&b).filter(|x| !x.is_empty()).ok_or(ErrorApi::Peticion)?;
        if bytes.len() > BLOQUE_MAX {
            return Err(ErrorApi::Grande);
        }
        dias.push((d, bytes));
    }
    if !e.almacen.consumir_cuota(&f.fid, "dias_put", &dia_civil(ahora), cuotas::DIAS_PUT).await? {
        return Err(ErrorApi::Cuota);
    }
    e.almacen.guardar_dias(&f.fid, &dias, ahora + TTL_DIAS).await?;
    Ok(Respuesta::vacia(204))
}

/// `GET /v1/dias?desde=AAAA-MM-DD`.
pub async fn bajar<A: Almacen, G: Google>(e: &Estado<A, G>, auth: Option<&str>, consulta: Option<&str>, ahora: u64) -> Result<Respuesta, ErrorApi> {
    let f = familia_autenticada(&e.almacen, auth).await?;
    exigir_vigencia(e, &f, Uso::Leer, ahora).await?;
    let desde = consulta
        .and_then(|q| q.split('&').find_map(|par| par.strip_prefix("desde=")))
        .filter(|d| es_dia_valido(d))
        .ok_or(ErrorApi::Peticion)?;
    if !e.almacen.consumir_cuota(&f.fid, "dias_get", &dia_civil(ahora), cuotas::DIAS_GET).await? {
        return Err(ErrorApi::Cuota);
    }
    let dias: Vec<_> = e
        .almacen
        .leer_dias(&f.fid, desde, DIAS_POR_LECTURA)
        .await?
        .into_iter()
        .map(|(d, b)| serde_json::json!({ "d": d, "b": b64::codificar(&b) }))
        .collect();
    Ok(Respuesta::json(200, &serde_json::json!({ "dias": dias })))
}
