use crate::error::ErrorApi;
use crate::estado::{Almacen, Estado, Google};
use crate::familia;
use crate::http::{Peticion, Respuesta};

/// Cuerpo máximo aceptado (300 KB); se mira antes que nada.
pub const CUERPO_MAX: usize = 307_200;

const RUTAS: [&str; 4] = ["/v1/familia", "/v1/dias", "/v1/respaldo", "/v1/contadores"];

pub async fn atender<A: Almacen, G: Google>(e: &Estado<A, G>, p: Peticion, ahora: u64) -> Respuesta {
    match despachar(e, &p, ahora).await {
        Ok(r) => r,
        Err(err) => err.into(),
    }
}

async fn despachar<A: Almacen, G: Google>(e: &Estado<A, G>, p: &Peticion, ahora: u64) -> Result<Respuesta, ErrorApi> {
    if p.cuerpo.len() > CUERPO_MAX {
        return Err(ErrorApi::Grande);
    }
    match (p.metodo.as_str(), p.ruta.as_str()) {
        ("POST", "/v1/familia") => familia::activar(e, &p.cuerpo, ahora).await,
        (_, ruta) if RUTAS.contains(&ruta) => Err(ErrorApi::Metodo),
        _ => Err(ErrorApi::NoEncontrado),
    }
}
