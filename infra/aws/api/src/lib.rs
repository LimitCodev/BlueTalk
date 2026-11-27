//! API de la nube familiar de BlueTalk. La lógica no depende de `lambda_http`:
//! recibe una [`http::Peticion`] y devuelve una [`http::Respuesta`].
pub mod auth;
pub mod error;
pub mod estado;
pub mod familia;
pub mod google;
pub mod http;
pub mod rutas;
