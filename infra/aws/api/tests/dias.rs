mod comun;
use bluetalk_api::b64;
use bluetalk_api::estado::Almacen;
use bluetalk_api::rutas::atender;
use comun::*;

/// 2026-11-26 y días vecinos, como texto.
const D0: &str = "2026-11-26";

async fn familia_activa() -> Est {
    let e = estado();
    assert_eq!(activar(&e, FID, WTOK, "compra-1").await, 201);
    e
}

fn cuerpo_dias(dias: &[(&str, &[u8])]) -> Vec<u8> {
    let v: Vec<_> = dias.iter().map(|(d, b)| serde_json::json!({ "d": d, "b": b64::codificar(b) })).collect();
    serde_json::to_vec(&serde_json::json!({ "dias": v })).unwrap()
}

async fn put(e: &Est, dias: &[(&str, &[u8])], ahora: u64) -> u16 {
    atender(e, pet("PUT", "/v1/dias", Some(AUTH), &cuerpo_dias(dias)), ahora).await.estado
}

async fn get(e: &Est, consulta: &str, ahora: u64) -> (u16, serde_json::Value) {
    let r = atender(e, pet("GET", &format!("/v1/dias{consulta}"), Some(AUTH), b""), ahora).await;
    (r.estado, serde_json::from_slice(&r.cuerpo).unwrap_or_default())
}

#[test]
fn base64_vectores_conocidos() {
    assert_eq!(b64::codificar(b"Man"), "TWFu");
    assert_eq!(b64::codificar(b"Ma"), "TWE=");
    assert_eq!(b64::codificar(b"M"), "TQ==");
    assert_eq!(b64::decodificar("TWE=").unwrap(), b"Ma");
    assert_eq!(b64::decodificar("").unwrap(), b"");
    for malo in ["TWE", "TW=E", "T===", "TW*=", "====", "TWFu\n"] {
        assert!(b64::decodificar(malo).is_none(), "{malo}");
    }
}

#[tokio::test]
async fn put_dias_guarda_y_get_los_devuelve_en_orden() {
    let e = familia_activa().await;
    assert_eq!(put(&e, &[("2026-11-26", b"tres"), ("2026-11-24", b"uno"), ("2026-11-25", b"dos")], AHORA).await, 204);
    let (estado, cuerpo) = get(&e, "?desde=2026-11-25", AHORA).await;
    assert_eq!(estado, 200);
    assert_eq!(cuerpo, serde_json::json!({ "dias": [{ "d": "2026-11-25", "b": "ZG9z" }, { "d": "2026-11-26", "b": "dHJlcw==" }] }));
}

#[tokio::test]
async fn get_devuelve_62_como_maximo() {
    let e = familia_activa().await;
    let dias: Vec<(String, Vec<u8>)> = (0..70u64).map(|n| (bluetalk_api::fecha::dia_civil(AHORA - n * 86_400), vec![1])).collect();
    e.almacen.dias.lock().unwrap().insert(FID.into(), dias.into_iter().collect());
    let (_, cuerpo) = get(&e, "?desde=2026-01-01", AHORA).await;
    assert_eq!(cuerpo["dias"].as_array().unwrap().len(), 62);
}

#[tokio::test]
async fn put_mismo_dia_dos_veces_sobrescribe() {
    let e = familia_activa().await;
    assert_eq!(put(&e, &[(D0, b"viejo")], AHORA).await, 204);
    assert_eq!(put(&e, &[(D0, b"nuevo")], AHORA).await, 204);
    let r = e.almacen.leer_dias(FID, "2000-01-01", 62).await.unwrap();
    assert_eq!(r, vec![(D0.to_string(), b"nuevo".to_vec())]);
}

#[tokio::test]
async fn ocho_dias_en_una_llamada_da_400() {
    let e = familia_activa().await;
    let nombres: Vec<String> = (0..8u64).map(|n| bluetalk_api::fecha::dia_civil(AHORA - n * 86_400)).collect();
    let dias: Vec<(&str, &[u8])> = nombres.iter().map(|d| (d.as_str(), b"x".as_slice())).collect();
    assert_eq!(put(&e, &dias, AHORA).await, 400);
    assert_eq!(put(&e, &dias[..7], AHORA).await, 204);
}

#[tokio::test]
async fn bloque_de_4097_bytes_da_413() {
    let e = familia_activa().await;
    assert_eq!(put(&e, &[(D0, &[7u8; 4096])], AHORA).await, 204);
    assert_eq!(put(&e, &[(D0, &[7u8; 4097])], AHORA).await, 413);
}

#[tokio::test]
async fn dia_futuro_mas_de_1_dia_da_400() {
    let e = familia_activa().await;
    assert_eq!(put(&e, &[("2026-11-27", b"x")], AHORA).await, 204);
    assert_eq!(put(&e, &[("2026-11-28", b"x")], AHORA).await, 400);
}

#[tokio::test]
async fn cuerpos_invalidos_dan_400_y_no_gastan_cuota() {
    let e = familia_activa().await;
    let malos: [&[u8]; 6] = [
        b"no es json",
        br#"{"dias":[]}"#,
        br#"{"dias":[{"d":"2026-02-30","b":"eA=="}]}"#,
        br#"{"dias":[{"d":"2026-11-26","b":"no base64!"}]}"#,
        br#"{"dias":[{"d":"2026-11-26","b":"eA=="},{"d":"2026-11-26","b":"eQ=="}]}"#,
        br#"{"dias":[{"d":"2026-11-26","b":""}]}"#,
    ];
    for _ in 0..3 {
        for m in malos {
            assert_eq!(atender(&e, pet("PUT", "/v1/dias", Some(AUTH), m), AHORA).await.estado, 400);
        }
    }
    for _ in 0..10 {
        assert_eq!(put(&e, &[(D0, b"x")], AHORA).await, 204);
    }
}

#[tokio::test]
async fn undecima_subida_del_dia_da_429() {
    let e = familia_activa().await;
    for _ in 0..10 {
        assert_eq!(put(&e, &[(D0, b"x")], AHORA).await, 204);
    }
    let r = atender(&e, pet("PUT", "/v1/dias", Some(AUTH), &cuerpo_dias(&[(D0, b"x")])), AHORA).await;
    assert_eq!((r.estado, r.cuerpo.as_slice()), (429, br#"{"error":"cuota"}"#.as_slice()));
    // Al día siguiente la cuota vuelve (la caché de vigencia ya venció: `hasta == AHORA + 86_400`,
    // y `hasta > ahora` es falso, así que se pregunta a Google y la suscripción sigue activa).
    assert_eq!(put(&e, &[(D0, b"x")], AHORA + 86_400).await, 204);
}

#[tokio::test]
async fn get_61_veces_da_429_en_la_61() {
    let e = familia_activa().await;
    for _ in 0..60 {
        assert_eq!(get(&e, "?desde=2026-11-01", AHORA).await.0, 200);
    }
    assert_eq!(get(&e, "?desde=2026-11-01", AHORA).await.0, 429);
}

#[tokio::test]
async fn get_sin_desde_o_desde_invalido_da_400() {
    let e = familia_activa().await;
    for q in ["", "?otro=1", "?desde=", "?desde=2026-02-30", "?desde=hoy", "?x=1&desde=2026-1-1"] {
        assert_eq!(get(&e, q, AHORA).await.0, 400, "{q}");
    }
    assert_eq!(get(&e, "?x=1&desde=2026-11-01", AHORA).await.0, 200);
}

#[tokio::test]
async fn sin_autenticacion_da_401() {
    let e = familia_activa().await;
    assert_eq!(atender(&e, pet("GET", "/v1/dias?desde=2026-11-01", None, b""), AHORA).await.estado, 401);
    assert_eq!(atender(&e, pet("PUT", "/v1/dias", None, &cuerpo_dias(&[(D0, b"x")])), AHORA).await.estado, 401);
}

// ---- vigencia ----

#[tokio::test]
async fn cache_vigente_no_llama_a_google() {
    let e = familia_activa().await;
    let antes = e.google.n_consultas();
    assert_eq!(put(&e, &[(D0, b"x")], AHORA).await, 204);
    assert_eq!(get(&e, "?desde=2026-11-01", AHORA).await.0, 200);
    assert_eq!(e.google.n_consultas(), antes);
}

/// Familia activa a la que se le vence la caché (`hasta`) en `ahora`.
async fn cache_vencida() -> (Est, u64) {
    let e = familia_activa().await;
    let ahora = AHORA + 86_401;
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().fin = FIN + 1_000;
    (e, ahora)
}

#[tokio::test]
async fn cache_vencida_y_google_activa_actualiza_hasta_y_fin() {
    let (e, ahora) = cache_vencida().await;
    let antes = e.google.n_consultas();
    assert_eq!(put(&e, &[(D0, b"x")], ahora).await, 204);
    assert_eq!(e.google.n_consultas(), antes + 1);
    let f = e.almacen.familias.lock().unwrap()[FID].clone();
    assert_eq!((f.hasta, f.fin), (ahora + 86_400, FIN + 1_000));
}

#[tokio::test]
async fn cache_vencida_y_google_inactiva_escribir_da_402() {
    let (e, ahora) = cache_vencida().await;
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().activa = false;
    assert_eq!(put(&e, &[(D0, b"x")], ahora).await, 402);
}

#[tokio::test]
async fn cache_vencida_y_google_inactiva_leer_vale_30_dias_tras_el_fin() {
    let (e, _) = cache_vencida().await;
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().activa = false;
    assert_eq!(get(&e, "?desde=2026-11-01", FIN + 2_592_000 - 1).await.0, 200);
    assert_eq!(get(&e, "?desde=2026-11-01", FIN + 2_592_000).await.0, 402);
}

#[tokio::test]
async fn si_google_falla_da_500_y_no_cambia_la_familia() {
    let (e, ahora) = cache_vencida().await;
    let antes = e.almacen.familias.lock().unwrap()[FID].clone();
    *e.google.suscripcion.lock().unwrap() = None;
    assert_eq!(put(&e, &[(D0, b"x")], ahora).await, 500);
    assert_eq!(get(&e, "?desde=2026-11-01", ahora).await.0, 500);
    let f = e.almacen.familias.lock().unwrap()[FID].clone();
    assert_eq!((f.hasta, f.fin), (antes.hasta, antes.fin));
}
