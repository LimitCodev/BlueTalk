//! Base64 estándar con relleno. shortcut: a mano porque `aws_smithy_types::base64`
//! aún no es dependencia; sustituir cuando entre el SDK de AWS (Tarea 4).

const ABC: &[u8; 64] = b"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

pub fn codificar(b: &[u8]) -> String {
    let mut s = String::with_capacity(b.len().div_ceil(3) * 4);
    for trozo in b.chunks(3) {
        let n = trozo.iter().enumerate().fold(0u32, |acc, (i, x)| acc | u32::from(*x) << (16 - 8 * i));
        for i in 0..4 {
            s.push(if i <= trozo.len() { ABC[(n >> (18 - 6 * i) & 63) as usize] as char } else { '=' });
        }
    }
    s
}

/// `None` si no es base64 con relleno válido.
pub fn decodificar(s: &str) -> Option<Vec<u8>> {
    let b = s.as_bytes();
    if !b.len().is_multiple_of(4) {
        return None;
    }
    let relleno = b.iter().rev().take_while(|c| **c == b'=').count();
    if relleno > 2 {
        return None;
    }
    let datos = &b[..b.len() - relleno];
    let mut out = Vec::with_capacity(b.len() / 4 * 3);
    let (mut acc, mut bits) = (0u32, 0);
    for c in datos {
        acc = acc << 6 | ABC.iter().position(|x| x == c)? as u32;
        bits += 6;
        if bits >= 8 {
            bits -= 8;
            out.push((acc >> bits) as u8);
            acc &= (1 << bits) - 1;
        }
    }
    Some(out)
}
