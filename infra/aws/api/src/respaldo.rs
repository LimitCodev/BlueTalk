use crate::auth::familia_autenticada;
use crate::cuotas;
use crate::error::ErrorApi;
use crate::estado::{Almacen, Estado, Google};
use crate::fecha::dia_civil;
use crate::http::Respuesta;
use crate::vigencia::{Uso, exigir_vigencia};

const RESPALDO_MAX: usize = 262_144;
/// La copia caduca con la familia: 90 días después del fin de la suscripción.
const TTL_TRAS_FIN: u64 = 90 * 86_400;

/// `PUT /v1/respaldo`: autenticar → vigencia → validar → cuota → guardar.
pub async fn subir<A: Almacen, G: Google>(e: &Estado<A, G>, auth: Option<&str>, cuerpo: &[u8], ahora: u64) -> Result<Respuesta, ErrorApi> {
    let f = familia_autenticada(&e.almacen, auth).await?;
    exigir_vigencia(e, &f, Uso::Escribir, ahora).await?;
    if cuerpo.is_empty() {
        return Err(ErrorApi::Peticion);
    }
    if cuerpo.len() > RESPALDO_MAX {
        return Err(ErrorApi::Grande);
    }
    if !e.almacen.consumir_cuota(&f.fid, "respaldo_put", &dia_civil(ahora), cuotas::RESPALDO_PUT).await? {
        return Err(ErrorApi::Cuota);
    }
    e.almacen.guardar_respaldo(&f.fid, cuerpo, f.fin + TTL_TRAS_FIN).await?;
    Ok(Respuesta::vacia(204))
}

/// `GET /v1/respaldo`: `404 vacio` si nunca se guardó (la consulta también gasta cuota).
pub async fn bajar<A: Almacen, G: Google>(e: &Estado<A, G>, auth: Option<&str>, ahora: u64) -> Result<Respuesta, ErrorApi> {
    let f = familia_autenticada(&e.almacen, auth).await?;
    exigir_vigencia(e, &f, Uso::Leer, ahora).await?;
    if !e.almacen.consumir_cuota(&f.fid, "respaldo_get", &dia_civil(ahora), cuotas::RESPALDO_GET).await? {
        return Err(ErrorApi::Cuota);
    }
    e.almacen.leer_respaldo(&f.fid).await?.map(Respuesta::binaria).ok_or(ErrorApi::Vacio)
}
