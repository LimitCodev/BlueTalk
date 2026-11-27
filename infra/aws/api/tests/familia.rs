mod comun;
use bluetalk_api::rutas::atender;
use comun::*;

fn otro_fid(n: u8) -> String {
    format!("{}{}", "q".repeat(25), (b'a' + n) as char)
}

#[tokio::test]
async fn alta_nueva_da_201_y_reconoce_la_compra() {
    let e = estado();
    let r = atender(&e, pet("POST", "/v1/familia", None, &cuerpo_alta(FID, WTOK, "compra-1")), AHORA).await;
    assert_eq!(r.estado, 201);
    let cuerpo: serde_json::Value = serde_json::from_slice(&r.cuerpo).unwrap();
    assert_eq!(cuerpo["hasta"], AHORA + 86_400);
    assert_eq!(e.google.n_reconocidas(), 1);
    let f = e.almacen.familias.lock().unwrap()[FID].clone();
    assert_eq!((f.hasta, f.fin, f.token.as_str()), (AHORA + 86_400, FIN, "compra-1"));
}

#[tokio::test]
async fn hasta_es_el_fin_si_vence_antes_de_24h() {
    let e = estado();
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().fin = AHORA + 100;
    let r = atender(&e, pet("POST", "/v1/familia", None, &cuerpo_alta(FID, WTOK, "c")), AHORA).await;
    let cuerpo: serde_json::Value = serde_json::from_slice(&r.cuerpo).unwrap();
    assert_eq!(cuerpo["hasta"], AHORA + 100);
}

#[tokio::test]
async fn alta_repetida_mismo_wh_da_200() {
    let e = estado();
    assert_eq!(activar(&e, FID, WTOK, "compra-1").await, 201);
    assert_eq!(activar(&e, FID, WTOK, "compra-1").await, 200);
}

#[tokio::test]
async fn alta_repetida_otro_wh_da_401() {
    let e = estado();
    assert_eq!(activar(&e, FID, WTOK, "compra-1").await, 201);
    assert_eq!(activar(&e, FID, &"B".repeat(43), "compra-1").await, 401);
}

#[tokio::test]
async fn cuarto_fid_con_el_mismo_token_da_409() {
    let e = estado();
    for n in 0..3 {
        assert_eq!(activar(&e, &otro_fid(n), WTOK, "compra-1").await, 201);
    }
    e.google.veredicto.lock().unwrap().hash_peticion = hash_activacion(&otro_fid(3), WTOK);
    let r = atender(&e, pet("POST", "/v1/familia", None, &cuerpo_alta(&otro_fid(3), WTOK, "compra-1")), AHORA).await;
    assert_eq!((r.estado, r.cuerpo.as_slice()), (409, br#"{"error":"lleno"}"#.as_slice()));
}

async fn alta_con_veredicto(cambio: impl FnOnce(&mut bluetalk_api::google::Veredicto)) -> u16 {
    let e = estado();
    cambio(&mut e.google.veredicto.lock().unwrap());
    atender(&e, pet("POST", "/v1/familia", None, &cuerpo_alta(FID, WTOK, "c")), AHORA).await.estado
}

#[tokio::test]
async fn integridad_mala_da_401() {
    assert_eq!(alta_con_veredicto(|v| v.paquete = "com.pirata".into()).await, 401);
    assert_eq!(alta_con_veredicto(|v| v.reconocida = false).await, 401);
    assert_eq!(alta_con_veredicto(|v| v.dispositivo_ok = false).await, 401);
    assert_eq!(alta_con_veredicto(|v| v.hash_peticion = hex_sha(b"otro")).await, 401);
}

#[tokio::test]
async fn hash_de_otro_wh_da_401() {
    // El veredicto liga `fid` y `wh`: no sirve para activar con otro `wtok`.
    assert_eq!(alta_con_veredicto(|v| v.hash_peticion = hash_activacion(FID, &"B".repeat(43))).await, 401);
    // El hash antiguo, solo del `fid`, ya no vale.
    assert_eq!(alta_con_veredicto(|v| v.hash_peticion = hex_sha(FID.as_bytes())).await, 401);
}

#[tokio::test]
async fn veredicto_caducado_o_del_futuro_da_401() {
    let ahora_ms = AHORA * 1000;
    assert_eq!(alta_con_veredicto(|v| v.timestamp_ms = ahora_ms - 300_001).await, 401);
    assert_eq!(alta_con_veredicto(|v| v.timestamp_ms = ahora_ms + 60_001).await, 401);
}

#[tokio::test]
async fn veredicto_fresco_da_201() {
    let ahora_ms = AHORA * 1000;
    assert_eq!(alta_con_veredicto(|v| v.timestamp_ms = ahora_ms - 300_000).await, 201);
    assert_eq!(alta_con_veredicto(|v| v.timestamp_ms = ahora_ms + 60_000).await, 201);
}

#[tokio::test]
async fn suscripcion_inactiva_o_de_otro_producto_da_402() {
    let e = estado();
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().activa = false;
    let r = atender(&e, pet("POST", "/v1/familia", None, &cuerpo_alta(FID, WTOK, "c")), AHORA).await;
    assert_eq!(r.estado, 402);

    let e = estado();
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().producto = "otro".into();
    let r = atender(&e, pet("POST", "/v1/familia", None, &cuerpo_alta(FID, WTOK, "c")), AHORA).await;
    assert_eq!(r.estado, 402);
    assert!(e.almacen.familias.lock().unwrap().is_empty());
}

#[tokio::test]
async fn compra_ya_reconocida_no_se_reconoce_otra_vez() {
    let e = estado();
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().reconocida = true;
    assert_eq!(activar(&e, FID, WTOK, "c").await, 201);
    assert_eq!(e.google.n_reconocidas(), 0);
}

#[tokio::test]
async fn cuerpo_invalido_da_400() {
    let e = estado();
    for cuerpo in [
        b"no json".to_vec(),
        br#"{"fid":"corto","wh":"00","compra":"c","integridad":"i"}"#.to_vec(),
        serde_json::to_vec(&serde_json::json!({"fid": FID, "wh": "ZZ".repeat(32), "compra": "c", "integridad": "i"})).unwrap(),
        serde_json::to_vec(&serde_json::json!({"fid": FID, "wh": hex_sha(b"x"), "compra": "", "integridad": "i"})).unwrap(),
    ] {
        assert_eq!(atender(&e, pet("POST", "/v1/familia", None, &cuerpo), AHORA).await.estado, 400);
    }
}

#[tokio::test]
async fn google_caido_da_500_sin_guardar() {
    let e = estado();
    *e.google.suscripcion.lock().unwrap() = None;
    let r = atender(&e, pet("POST", "/v1/familia", None, &cuerpo_alta(FID, WTOK, "c")), AHORA).await;
    assert_eq!((r.estado, r.cuerpo.as_slice()), (500, br#"{"error":"interno"}"#.as_slice()));
    assert!(e.almacen.familias.lock().unwrap().is_empty());
}
