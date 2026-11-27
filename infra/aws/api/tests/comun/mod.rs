//! Dobles de prueba: almacén en memoria y Google falso. Crecen por tarea.
#![allow(dead_code)]

use std::collections::HashMap;
use std::sync::Mutex;
use std::sync::atomic::{AtomicUsize, Ordering};

use bluetalk_api::error::ErrorApi;
use bluetalk_api::estado::{Almacen, Config, Estado, Google};
use bluetalk_api::familia::{Alta, Familia};
use bluetalk_api::google::{Suscripcion, Veredicto};
use bluetalk_api::http::Peticion;
use sha2::{Digest, Sha256};

pub const FID: &str = "abcdefghijklmnopqrstuvwxyz";
pub const WTOK: &str = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
pub const AUTH: &str = "BT1 abcdefghijklmnopqrstuvwxyz.AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
pub const FIN: u64 = 1_800_000_000;
pub const AHORA: u64 = 1_795_651_200; // 2026-11-26

pub fn hex_sha(b: &[u8]) -> String {
    Sha256::digest(b).iter().map(|x| format!("{x:02x}")).collect()
}

/// `requestHash` de la activación: `sha256("<fid>|<wh>")` en hexadecimal.
pub fn hash_activacion(fid: &str, wtok: &str) -> String {
    hex_sha(format!("{fid}|{}", hex_sha(wtok.as_bytes())).as_bytes())
}

pub fn auth_de(fid: &str, wtok: &str) -> String {
    format!("BT1 {fid}.{wtok}")
}

#[derive(Default)]
pub struct AlmacenMemoria {
    pub familias: Mutex<HashMap<String, Familia>>,
    pub ligaduras: Mutex<HashMap<String, Vec<String>>>,
}

impl Almacen for AlmacenMemoria {
    async fn familia(&self, fid: &str) -> Result<Option<Familia>, ErrorApi> {
        Ok(self.familias.lock().unwrap().get(fid).cloned())
    }

    async fn alta(&self, f: &Familia, token_hash: &str, max: usize) -> Result<Alta, ErrorApi> {
        let mut fams = self.familias.lock().unwrap();
        let mut ligs = self.ligaduras.lock().unwrap();
        if let Some(previa) = fams.get(&f.fid) {
            return if previa.wh == f.wh { Ok(Alta::YaExistia) } else { Err(ErrorApi::Token) };
        }
        let fids = ligs.entry(token_hash.to_string()).or_default();
        if fids.len() >= max {
            return Ok(Alta::Llena);
        }
        fids.push(f.fid.clone());
        fams.insert(f.fid.clone(), f.clone());
        Ok(Alta::Nueva)
    }

    async fn vigencia(&self, fid: &str, hasta: u64, fin: u64) -> Result<(), ErrorApi> {
        if let Some(f) = self.familias.lock().unwrap().get_mut(fid) {
            f.hasta = hasta;
            f.fin = fin;
        }
        Ok(())
    }
}

pub struct GoogleFalso {
    pub veredicto: Mutex<Veredicto>,
    /// `None` simula a Google caído.
    pub suscripcion: Mutex<Option<Suscripcion>>,
    pub consultas: AtomicUsize,
    pub reconocidas: AtomicUsize,
}

impl GoogleFalso {
    pub fn para(fid: &str, wtok: &str) -> Self {
        Self {
            veredicto: Mutex::new(Veredicto {
                paquete: "com.limitcodev.bluetalk".into(),
                reconocida: true,
                dispositivo_ok: true,
                hash_peticion: hash_activacion(fid, wtok),
                timestamp_ms: AHORA * 1000,
            }),
            suscripcion: Mutex::new(Some(Suscripcion {
                activa: true,
                producto: "bluetalk_familia".into(),
                fin: FIN,
                reconocida: false,
            })),
            consultas: AtomicUsize::new(0),
            reconocidas: AtomicUsize::new(0),
        }
    }

    pub fn n_consultas(&self) -> usize {
        self.consultas.load(Ordering::SeqCst)
    }

    pub fn n_reconocidas(&self) -> usize {
        self.reconocidas.load(Ordering::SeqCst)
    }
}

impl Google for GoogleFalso {
    async fn integridad(&self, _token: &str) -> Result<Veredicto, ErrorApi> {
        Ok(self.veredicto.lock().unwrap().clone())
    }

    async fn suscripcion(&self, _token: &str) -> Result<Suscripcion, ErrorApi> {
        self.consultas.fetch_add(1, Ordering::SeqCst);
        self.suscripcion.lock().unwrap().clone().ok_or(ErrorApi::Interno("google caído".into()))
    }

    async fn reconocer(&self, _producto: &str, _token: &str) -> Result<(), ErrorApi> {
        self.reconocidas.fetch_add(1, Ordering::SeqCst);
        Ok(())
    }
}

pub type Est = Estado<AlmacenMemoria, GoogleFalso>;

pub fn estado() -> Est {
    Estado {
        almacen: AlmacenMemoria::default(),
        google: GoogleFalso::para(FID, WTOK),
        cfg: Config { paquete: "com.limitcodev.bluetalk".into(), producto: "bluetalk_familia".into() },
    }
}

pub fn pet(metodo: &str, ruta: &str, auth: Option<&str>, cuerpo: &[u8]) -> Peticion {
    let (ruta, consulta) = match ruta.split_once('?') {
        Some((r, q)) => (r.to_string(), Some(q.to_string())),
        None => (ruta.to_string(), None),
    };
    Peticion { metodo: metodo.into(), ruta, consulta, auth: auth.map(Into::into), cuerpo: cuerpo.to_vec() }
}

/// Cuerpo de `POST /v1/familia` para `fid`/`wtok` con un token de compra.
pub fn cuerpo_alta(fid: &str, wtok: &str, compra: &str) -> Vec<u8> {
    serde_json::to_vec(&serde_json::json!({
        "fid": fid, "wh": hex_sha(wtok.as_bytes()), "compra": compra, "integridad": "tok-int"
    }))
    .unwrap()
}

/// Da de alta la familia `fid`/`wtok` y devuelve el estado HTTP.
pub async fn activar(e: &Est, fid: &str, wtok: &str, compra: &str) -> u16 {
    // Un solo `lock()`: dos en la misma sentencia se bloquean entre sí.
    e.google.veredicto.lock().unwrap().hash_peticion = hash_activacion(fid, wtok);
    bluetalk_api::rutas::atender(e, pet("POST", "/v1/familia", None, &cuerpo_alta(fid, wtok, compra)), AHORA).await.estado
}
