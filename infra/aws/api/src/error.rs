use crate::http::Respuesta;

/// Errores de la API. `Interno` guarda el detalle solo para el log; nunca
/// sale en la respuesta.
#[derive(Debug, PartialEq)]
pub enum ErrorApi {
    Peticion,
    Token,
    Suscripcion,
    NoEncontrado,
    Metodo,
    Lleno,
    Grande,
    Cuota,
    Vacio,
    Interno(String),
}

impl ErrorApi {
    pub fn estado(&self) -> u16 {
        match self {
            Self::Peticion => 400,
            Self::Token => 401,
            Self::Suscripcion => 402,
            Self::NoEncontrado | Self::Vacio => 404,
            Self::Metodo => 405,
            Self::Lleno => 409,
            Self::Grande => 413,
            Self::Cuota => 429,
            Self::Interno(_) => 500,
        }
    }

    pub fn codigo(&self) -> &'static str {
        match self {
            Self::Peticion => "peticion",
            Self::Token => "token",
            Self::Suscripcion => "suscripcion",
            Self::NoEncontrado => "ruta",
            Self::Metodo => "metodo",
            Self::Lleno => "lleno",
            Self::Grande => "grande",
            Self::Cuota => "cuota",
            Self::Vacio => "vacio",
            Self::Interno(_) => "interno",
        }
    }
}

impl From<ErrorApi> for Respuesta {
    fn from(e: ErrorApi) -> Self {
        Respuesta::json(e.estado(), &serde_json::json!({ "error": e.codigo() }))
    }
}
