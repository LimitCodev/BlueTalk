mod comun;
use bluetalk_api::rutas::atender;
use comun::*;

const MAX: usize = 262_144;

async fn familia_activa() -> Est {
    let e = estado();
    assert_eq!(activar(&e, FID, WTOK, "compra-1").await, 201);
    e
}

async fn put(e: &Est, cuerpo: &[u8]) -> u16 {
    atender(e, pet("PUT", "/v1/respaldo", Some(AUTH), cuerpo), AHORA).await.estado
}

async fn get(e: &Est) -> (u16, Vec<u8>) {
    let r = atender(e, pet("GET", "/v1/respaldo", Some(AUTH), b""), AHORA).await;
    (r.estado, r.cuerpo)
}

async fn borrar(e: &Est) -> u16 {
    atender(e, pet("DELETE", "/v1/familia", Some(AUTH), b""), AHORA).await.estado
}

fn otro_fid(n: u8) -> String {
    format!("{}{}", "q".repeat(25), (b'a' + n) as char)
}

#[tokio::test]
async fn guarda_262144_bytes_y_lee_los_mismos() {
    let e = familia_activa().await;
    let bloque: Vec<u8> = (0..MAX).map(|i| (i % 251) as u8).collect();
    assert_eq!(put(&e, &bloque).await, 204);
    let r = atender(&e, pet("GET", "/v1/respaldo", Some(AUTH), b""), AHORA).await;
    assert_eq!((r.estado, r.tipo), (200, "application/octet-stream"));
    assert_eq!(r.cuerpo, bloque);
}

#[tokio::test]
async fn la_copia_caduca_a_los_400_dias_de_escrita() {
    let e = familia_activa().await;
    assert_eq!(put(&e, b"x").await, 204);
    assert_eq!(e.almacen.respaldos.lock().unwrap()[FID].1, AHORA + 34_560_000);
}

#[tokio::test]
async fn el_ttl_cuenta_desde_ahora_aunque_la_suscripcion_se_renueve_en_la_llamada() {
    let e = familia_activa().await;
    // Caché vencida y Google confirma una renovación: `fin` sube dentro de la misma llamada.
    let tarde = AHORA + 2 * 86_400;
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().fin = FIN + 10 * 86_400 * 365;
    assert_eq!(atender(&e, pet("PUT", "/v1/respaldo", Some(AUTH), b"x"), tarde).await.estado, 204);
    assert_eq!(e.almacen.respaldos.lock().unwrap()[FID].1, tarde + 34_560_000);
}

#[tokio::test]
async fn una_copia_nueva_sobrescribe_la_anterior() {
    let e = familia_activa().await;
    assert_eq!(put(&e, b"vieja").await, 204);
    assert_eq!(put(&e, b"nueva").await, 204);
    assert_eq!(get(&e).await, (200, b"nueva".to_vec()));
}

#[tokio::test]
async fn con_262145_bytes_da_413_y_no_gasta_cuota_ni_guarda() {
    let e = familia_activa().await;
    for _ in 0..5 {
        assert_eq!(put(&e, &vec![7u8; MAX + 1]).await, 413);
    }
    assert_eq!(get(&e).await.0, 404);
    for _ in 0..4 {
        assert_eq!(put(&e, b"x").await, 204);
    }
}

#[tokio::test]
async fn cuerpo_vacio_da_400() {
    let e = familia_activa().await;
    assert_eq!(put(&e, b"").await, 400);
}

#[tokio::test]
async fn sin_copia_el_get_da_404_vacio() {
    let e = familia_activa().await;
    let (estado, cuerpo) = get(&e).await;
    assert_eq!((estado, cuerpo.as_slice()), (404, br#"{"error":"vacio"}"#.as_slice()));
}

#[tokio::test]
async fn la_quinta_escritura_del_dia_da_429_y_al_dia_siguiente_vuelve() {
    let e = familia_activa().await;
    for _ in 0..4 {
        assert_eq!(put(&e, b"x").await, 204);
    }
    let r = atender(&e, pet("PUT", "/v1/respaldo", Some(AUTH), b"x"), AHORA).await;
    assert_eq!((r.estado, r.cuerpo.as_slice()), (429, br#"{"error":"cuota"}"#.as_slice()));
    assert_eq!(atender(&e, pet("PUT", "/v1/respaldo", Some(AUTH), b"x"), AHORA + 86_400).await.estado, 204);
}

#[tokio::test]
async fn la_lectura_once_del_dia_da_429() {
    let e = familia_activa().await;
    assert_eq!(put(&e, b"x").await, 204);
    for _ in 0..10 {
        assert_eq!(get(&e).await.0, 200);
    }
    assert_eq!(get(&e).await.0, 429);
}

#[tokio::test]
async fn sin_auth_o_con_token_malo_da_401() {
    let e = familia_activa().await;
    let malo = auth_de(FID, &"B".repeat(43));
    for auth in [None, Some(malo.as_str())] {
        for m in ["PUT", "GET"] {
            assert_eq!(atender(&e, pet(m, "/v1/respaldo", auth, b"x"), AHORA).await.estado, 401);
        }
    }
    assert_eq!(atender(&e, pet("DELETE", "/v1/familia", None, b""), AHORA).await.estado, 401);
}

#[tokio::test]
async fn con_la_suscripcion_vencida_se_lee_pero_no_se_escribe() {
    let e = familia_activa().await;
    assert_eq!(put(&e, b"copia").await, 204);
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().activa = false;
    let ya_vencida = AHORA + 2 * 86_400;
    assert_eq!(atender(&e, pet("PUT", "/v1/respaldo", Some(AUTH), b"x"), ya_vencida).await.estado, 402);
    let r = atender(&e, pet("GET", "/v1/respaldo", Some(AUTH), b""), ya_vencida).await;
    assert_eq!((r.estado, r.cuerpo), (200, b"copia".to_vec()));
}

#[tokio::test]
async fn borrar_da_204_y_deja_la_familia_sin_nada() {
    let e = familia_activa().await;
    assert_eq!(put(&e, b"copia").await, 204);
    atender(&e, pet("PUT", "/v1/dias", Some(AUTH), br#"{"dias":[{"d":"2026-11-26","b":"eA=="}]}"#), AHORA).await;
    assert_eq!(borrar(&e).await, 204);
    assert!(e.almacen.familias.lock().unwrap().is_empty());
    assert!(e.almacen.dias.lock().unwrap().is_empty());
    assert!(e.almacen.respaldos.lock().unwrap().is_empty());
}

#[tokio::test]
async fn borrar_y_reactivar_no_reinicia_la_cuota_del_dia() {
    let e = familia_activa().await;
    for _ in 0..4 {
        assert_eq!(put(&e, b"x").await, 204);
    }
    assert_eq!(borrar(&e).await, 204);
    assert_eq!(activar(&e, FID, WTOK, "compra-1").await, 201);
    assert_eq!(put(&e, b"x").await, 429);
}

#[tokio::test]
async fn despues_de_borrar_el_mismo_bt1_da_401() {
    let e = familia_activa().await;
    assert_eq!(borrar(&e).await, 204);
    for (m, ruta) in [("GET", "/v1/dias?desde=2026-11-01"), ("GET", "/v1/respaldo"), ("DELETE", "/v1/familia")] {
        assert_eq!(atender(&e, pet(m, ruta, Some(AUTH), b""), AHORA).await.estado, 401, "{m} {ruta}");
    }
}

#[tokio::test]
async fn borrar_funciona_con_la_suscripcion_vencida() {
    let e = familia_activa().await;
    e.google.suscripcion.lock().unwrap().as_mut().unwrap().activa = false;
    let antes = e.google.n_consultas();
    let r = atender(&e, pet("DELETE", "/v1/familia", Some(AUTH), b""), FIN + 365 * 86_400).await;
    assert_eq!(r.estado, 204);
    assert_eq!(e.google.n_consultas(), antes);
}

#[tokio::test]
async fn borrar_libera_el_cupo() {
    let e = estado();
    for n in 0..3 {
        assert_eq!(activar(&e, &otro_fid(n), WTOK, "compra-1").await, 201);
    }
    assert_eq!(activar(&e, &otro_fid(3), WTOK, "compra-1").await, 409);
    let auth = auth_de(&otro_fid(0), WTOK);
    assert_eq!(atender(&e, pet("DELETE", "/v1/familia", Some(&auth), b""), AHORA).await.estado, 204);
    assert_eq!(activar(&e, &otro_fid(3), WTOK, "compra-1").await, 201);
    // Las otras dos siguen intactas.
    assert!(e.almacen.familias.lock().unwrap().contains_key(&otro_fid(1)));
}
