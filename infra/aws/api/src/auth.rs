use sha2::{Digest, Sha256};

use crate::error::ErrorApi;
use crate::estado::Almacen;
use crate::familia::Familia;

pub fn sha256(b: &[u8]) -> [u8; 32] {
    Sha256::digest(b).into()
}

pub fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}

/// `fid`: 16 bytes en base32 minúscula sin relleno (26 caracteres).
pub fn fid_valido(fid: &str) -> bool {
    fid.len() == 26 && fid.bytes().all(|c| c.is_ascii_lowercase() || (b'2'..=b'7').contains(&c))
}

/// `wtok`: 32 bytes en base64url sin relleno (43 caracteres).
fn wtok_valido(w: &str) -> bool {
    w.len() == 43 && w.bytes().all(|c| c.is_ascii_alphanumeric() || c == b'-' || c == b'_')
}

/// Lee `BT1 <fid>.<wtok>` y devuelve el `fid` y `sha256(wtok)`.
/// El hash es sobre el texto base64url del token, tal como viaja.
pub fn autenticar(auth: Option<&str>) -> Result<(String, [u8; 32]), ErrorApi> {
    let (fid, wtok) = auth
        .and_then(|a| a.strip_prefix("BT1 "))
        .and_then(|a| a.split_once('.'))
        .ok_or(ErrorApi::Token)?;
    if !fid_valido(fid) || !wtok_valido(wtok) {
        return Err(ErrorApi::Token);
    }
    Ok((fid.to_string(), sha256(wtok.as_bytes())))
}

pub fn igual_tiempo_constante(a: &[u8; 32], b: &[u8; 32]) -> bool {
    a.iter().zip(b).fold(0u8, |acc, (x, y)| acc | (x ^ y)) == 0
}

/// Familia del token. Un `fid` inexistente da 401, no 404: no se revela
/// qué familias existen.
pub async fn familia_autenticada<A: Almacen>(a: &A, auth: Option<&str>) -> Result<Familia, ErrorApi> {
    let (fid, wh) = autenticar(auth)?;
    match a.familia(&fid).await? {
        Some(f) if igual_tiempo_constante(&f.wh, &wh) => Ok(f),
        _ => Err(ErrorApi::Token),
    }
}
