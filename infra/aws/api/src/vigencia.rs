use crate::error::ErrorApi;
use crate::estado::{Almacen, Estado, Google};
use crate::familia::{CACHE_SUSCRIPCION, Familia};

/// Tras el fin de la suscripción, los datos se pueden seguir leyendo 30 días.
pub const GRACIA_LECTURA: u64 = 2_592_000;

#[derive(Clone, Copy)]
pub enum Uso {
    Escribir,
    Leer,
}

/// Comprueba que la familia puede usar la nube. Con la caché (`hasta`) al día no llama a
/// Google; si venció, pregunta y renueva la caché. Si Google falla, `500` y no se cambia nada.
pub async fn exigir_vigencia<A: Almacen, G: Google>(e: &Estado<A, G>, f: &Familia, uso: Uso, ahora: u64) -> Result<(), ErrorApi> {
    if f.hasta > ahora {
        return Ok(());
    }
    let s = e.google.suscripcion(&f.token).await?;
    if s.activa && s.producto == e.cfg.producto {
        return e.almacen.vigencia(&f.fid, s.fin.min(ahora + CACHE_SUSCRIPCION), s.fin).await;
    }
    match uso {
        Uso::Leer if ahora < f.fin + GRACIA_LECTURA => Ok(()),
        _ => Err(ErrorApi::Suscripcion),
    }
}
