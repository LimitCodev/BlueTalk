use std::collections::BTreeMap;

use serde::Deserialize;

use crate::auth::{hex, sha256};
use crate::error::ErrorApi;
use crate::estado::{Almacen, Estado, Google};
use crate::familia::verificar_integridad;
use crate::fecha::semana_iso;
use crate::http::Respuesta;

const FUNCIONES: [&str; 6] = ["comunicar", "aprender", "rutinas", "salud", "calma", "voces"];
const TRAMOS: [&str; 4] = ["0", "1-5", "6-20", "21+"];

#[derive(Deserialize)]
struct PeticionContadores {
    semana: String,
    version: String,
    c: BTreeMap<String, String>,
    integridad: String,
}

/// Cuánto se recuerda un token de Integrity ya usado (su veredicto vale 5 min, más el desfase).
const TTL_TOKEN_USADO: u64 = 600;

/// `POST /v1/contadores`: validar → Integrity (hash de `semana|version|c`) → veredicto de un solo
/// uso → sumar. Sin `fid` ni autenticación; la `version` solo entra en el hash y no se guarda.
pub async fn sumar<A: Almacen, G: Google>(e: &Estado<A, G>, cuerpo: &[u8], ahora: u64) -> Result<Respuesta, ErrorApi> {
    let p: PeticionContadores = serde_json::from_slice(cuerpo).map_err(|_| ErrorApi::Peticion)?;
    let semana_ok = p.semana == semana_iso(ahora) || p.semana == semana_iso(ahora.saturating_sub(7 * 86_400));
    let pares_ok = (1..=FUNCIONES.len()).contains(&p.c.len()) && p.c.iter().all(|(f, t)| FUNCIONES.contains(&f.as_str()) && TRAMOS.contains(&t.as_str()));
    let tamanos_ok = (1..=32).contains(&p.version.len()) && (1..=8192).contains(&p.integridad.len());
    if !semana_ok || !pares_ok || !tamanos_ok {
        return Err(ErrorApi::Peticion);
    }
    // `c` va en el hash (pares `funcion=tramo` por orden de `funcion`, unidos por `,`): un
    // veredicto robado no sirve para contar otra cosa. `BTreeMap` ya los ordena por bytes.
    let canonico = p.c.iter().map(|(f, t)| format!("{f}={t}")).collect::<Vec<_>>().join(",");
    let v = verificar_integridad(e, &p.integridad, &format!("{}|{}|{canonico}", p.semana, p.version), ahora).await?;
    // La clave sale del veredicto que Google verificó, no del texto del token: una variante no
    // canónica del mismo token daría otra clave y se podría repetir.
    let clave = hex(&sha256(format!("{}|{}", v.hash_peticion, v.timestamp_ms).as_bytes()));
    if !e.almacen.usar_token(&clave, ahora + TTL_TOKEN_USADO).await? {
        return Err(ErrorApi::Token);
    }
    let pares: Vec<(String, String)> = p.c.into_iter().collect();
    e.almacen.sumar_contadores(&p.semana, &pares).await?;
    Ok(Respuesta::vacia(204))
}
