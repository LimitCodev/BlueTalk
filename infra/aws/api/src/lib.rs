//! API de la nube familiar de BlueTalk. La lógica no depende de `lambda_http`:
//! recibe una [`http::Peticion`] y devuelve una [`http::Respuesta`].
pub mod auth;
pub mod b64;
pub mod contadores;
pub mod cuotas;
pub mod dias;
pub mod error;
pub mod estado;
pub mod familia;
pub mod fecha;
pub mod google;
pub mod http;
pub mod respaldo;
pub mod rutas;
pub mod vigencia;
