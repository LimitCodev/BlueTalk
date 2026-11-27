use serde::Serialize;

/// Petición ya separada del formato de Lambda.
pub struct Peticion {
    pub metodo: String,
    pub ruta: String,
    pub consulta: Option<String>,
    pub auth: Option<String>,
    pub cuerpo: Vec<u8>,
}

pub struct Respuesta {
    pub estado: u16,
    pub tipo: &'static str,
    pub cuerpo: Vec<u8>,
}

impl Respuesta {
    pub fn json(estado: u16, valor: &impl Serialize) -> Self {
        let cuerpo = serde_json::to_vec(valor).unwrap_or_default();
        Self { estado, tipo: "application/json", cuerpo }
    }

    pub fn vacia(estado: u16) -> Self {
        Self { estado, tipo: "application/json", cuerpo: Vec::new() }
    }

    pub fn binaria(cuerpo: Vec<u8>) -> Self {
        Self { estado: 200, tipo: "application/octet-stream", cuerpo }
    }
}
