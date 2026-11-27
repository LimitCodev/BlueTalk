mod comun;
use bluetalk_api::auth::{autenticar, familia_autenticada, igual_tiempo_constante};
use bluetalk_api::error::ErrorApi;
use comun::*;

#[test]
fn auth_valida_devuelve_fid_y_hash() {
    let (fid, wh) = autenticar(Some(AUTH)).unwrap();
    assert_eq!(fid, FID);
    assert_eq!(wh.iter().map(|x| format!("{x:02x}")).collect::<String>(), hex_sha(WTOK.as_bytes()));
}

#[test]
fn auth_sin_punto_da_401() {
    assert_eq!(autenticar(Some("BT1 abcdefghijklmnopqrstuvwxyzAAAA")), Err(ErrorApi::Token));
}

#[test]
fn auth_fid_invalido_da_401() {
    let a = auth_de("ABCDEFGHIJKLMNOPQRSTUVWXY1", WTOK);
    assert_eq!(autenticar(Some(&a)), Err(ErrorApi::Token));
}

#[test]
fn auth_base64_roto_da_401() {
    assert_eq!(autenticar(Some(&auth_de(FID, "AAAA+/=="))), Err(ErrorApi::Token));
    assert_eq!(autenticar(Some(&auth_de(FID, &"A".repeat(44)))), Err(ErrorApi::Token));
}

#[test]
fn auth_ausente_o_esquema_distinto_da_401() {
    assert_eq!(autenticar(None), Err(ErrorApi::Token));
    assert_eq!(autenticar(Some(&AUTH.replace("BT1", "Bearer"))), Err(ErrorApi::Token));
}

#[test]
fn comparacion_en_tiempo_constante() {
    assert!(igual_tiempo_constante(&[7; 32], &[7; 32]));
    let mut b = [7; 32];
    b[31] = 8;
    assert!(!igual_tiempo_constante(&[7; 32], &b));
}

#[tokio::test]
async fn auth_wtok_equivocado_da_401() {
    let e = estado();
    assert_eq!(activar(&e, FID, WTOK, "compra-1").await, 201);
    let otro = auth_de(FID, &"B".repeat(43));
    assert_eq!(familia_autenticada(&e.almacen, Some(&otro)).await.unwrap_err(), ErrorApi::Token);
    assert_eq!(familia_autenticada(&e.almacen, Some(AUTH)).await.unwrap().fid, FID);
}

#[tokio::test]
async fn fid_inexistente_da_401_no_404() {
    let e = estado();
    assert_eq!(familia_autenticada(&e.almacen, Some(AUTH)).await.unwrap_err(), ErrorApi::Token);
}
