mod comun;
use bluetalk_api::rutas::atender;
use comun::*;
use serde_json::json;
use std::sync::atomic::{AtomicUsize, Ordering};

const SEMANA: &str = "2026-W48";

async fn enviar(e: &Est, cuerpo: serde_json::Value) -> u16 {
    atender(e, pet("POST", "/v1/contadores", None, &serde_json::to_vec(&cuerpo).unwrap()), AHORA).await.estado
}

/// Cada llamada lleva un token distinto: un token solo se puede usar una vez.
fn cuerpo(semana: &str, c: serde_json::Value) -> serde_json::Value {
    static N: AtomicUsize = AtomicUsize::new(0);
    cuerpo_con_token(semana, c, &format!("tok-{}", N.fetch_add(1, Ordering::SeqCst)))
}

fn cuerpo_con_token(semana: &str, c: serde_json::Value, token: &str) -> serde_json::Value {
    json!({ "semana": semana, "version": "1.0.0", "c": c, "integridad": token })
}

/// El veredicto de Google liga `semana|version|c canónico`.
fn con_hash(e: &Est, semana: &str, version: &str, canonico: &str) {
    e.google.veredicto.lock().unwrap().hash_peticion = hex_sha(format!("{semana}|{version}|{canonico}").as_bytes());
}

#[tokio::test]
async fn peticion_valida_da_204_y_suma_uno() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0", "comunicar=6-20,voces=0");
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"voces": "0", "comunicar": "6-20"}))).await, 204);
    con_hash(&e, SEMANA, "1.0.0", "comunicar=6-20");
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"comunicar": "6-20"}))).await, 204);
    let cs = e.almacen.contadores.lock().unwrap();
    assert_eq!(cs[&("C#2026-W48".to_string(), "comunicar#6-20".to_string())], 2);
    assert_eq!(cs[&("C#2026-W48".to_string(), "voces#0".to_string())], 1);
}

#[tokio::test]
async fn hash_canonico_tiene_vector_fijo() {
    // c = {"rutinas":"1-5","comunicar":"21+"} → "2026-W48|1.0.0|comunicar=21+,rutinas=1-5"
    let e = estado();
    e.google.veredicto.lock().unwrap().hash_peticion = "95e39cfd94634f11abcd94a61bb31fd73734e9853de559e56fd7e399b0cc3e46".into();
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"rutinas": "1-5", "comunicar": "21+"}))).await, 204);
}

#[tokio::test]
async fn semana_anterior_vale() {
    let e = estado();
    con_hash(&e, "2026-W47", "1.0.0", "salud=21+");
    assert_eq!(enviar(&e, cuerpo("2026-W47", json!({"salud": "21+"}))).await, 204);
}

#[tokio::test]
async fn funcion_o_tramo_fuera_de_la_lista_da_400_sin_llamar_a_google() {
    let e = estado();
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"otra": "0"}))).await, 400);
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"calma": "7-9"}))).await, 400);
    assert!(e.almacen.contadores.lock().unwrap().is_empty());
    assert_eq!(e.google.n_integridades(), 0);
}

#[tokio::test]
async fn semana_de_hace_dos_semanas_o_futura_da_400() {
    let e = estado();
    for s in ["2026-W46", "2026-W49", "2026-48", "x"] {
        con_hash(&e, s, "1.0.0", "salud=0");
        assert_eq!(enviar(&e, cuerpo(s, json!({"salud": "0"}))).await, 400, "{s}");
    }
    assert_eq!(e.google.n_integridades(), 0);
}

#[tokio::test]
async fn hash_que_no_coincide_da_401() {
    let e = estado();
    con_hash(&e, SEMANA, "9.9.9", "salud=0");
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"salud": "0"}))).await, 401);
    assert!(e.almacen.contadores.lock().unwrap().is_empty());
}

#[tokio::test]
async fn c_distinto_al_del_hash_da_401() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0", "salud=0");
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"salud": "21+"}))).await, 401);
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"salud": "0", "voces": "0"}))).await, 401);
    assert!(e.almacen.contadores.lock().unwrap().is_empty());
}

#[tokio::test]
async fn el_mismo_token_dos_veces_da_401_y_no_suma() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0", "salud=0");
    let c = || cuerpo_con_token(SEMANA, json!({"salud": "0"}), "tok-repetido");
    assert_eq!(enviar(&e, c()).await, 204);
    assert_eq!(enviar(&e, c()).await, 401);
    assert_eq!(e.almacen.contadores.lock().unwrap().values().sum::<u64>(), 1);
    // Solo se guarda el hash del veredicto (requestHash|timestampMillis), con su caducidad.
    let clave = hex_sha(format!("{}|{}", hex_sha(b"2026-W48|1.0.0|salud=0"), AHORA * 1000).as_bytes());
    let usados = e.almacen.tokens_usados.lock().unwrap();
    assert_eq!(usados.iter().collect::<Vec<_>>(), [(&clave, &(AHORA + 600))]);
}

#[tokio::test]
async fn dos_textos_de_token_con_el_mismo_veredicto_cuentan_una_vez() {
    // Variante no canónica del mismo token: texto distinto, Google devuelve el mismo veredicto.
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0", "salud=0");
    assert_eq!(enviar(&e, cuerpo_con_token(SEMANA, json!({"salud": "0"}), "tok-A")).await, 204);
    assert_eq!(enviar(&e, cuerpo_con_token(SEMANA, json!({"salud": "0"}), "tok-A=")).await, 401);
    assert_eq!(e.almacen.contadores.lock().unwrap().values().sum::<u64>(), 1);
}

#[tokio::test]
async fn veredicto_viejo_da_401() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0", "salud=0");
    e.google.veredicto.lock().unwrap().timestamp_ms = (AHORA - 301) * 1000;
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"salud": "0"}))).await, 401);
}

#[tokio::test]
async fn mas_de_seis_claves_o_ninguna_da_400() {
    let e = estado();
    let siete = json!({"comunicar":"0","aprender":"0","rutinas":"0","salud":"0","calma":"0","voces":"0","extra":"0"});
    assert_eq!(enviar(&e, cuerpo(SEMANA, siete)).await, 400);
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({}))).await, 400);
    assert_eq!(e.google.n_integridades(), 0);
}

#[tokio::test]
async fn el_almacen_solo_guarda_contadores_y_hash_de_token() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0", "comunicar=1-5");
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"comunicar": "1-5"}))).await, 204);
    let a = &e.almacen;
    assert!(a.familias.lock().unwrap().is_empty());
    assert!(a.ligaduras.lock().unwrap().is_empty());
    assert!(a.cuotas.lock().unwrap().is_empty());
    assert!(a.dias.lock().unwrap().is_empty());
    assert!(a.respaldos.lock().unwrap().is_empty());
    let cs = a.contadores.lock().unwrap();
    assert!(cs.keys().all(|(pk, sk)| pk.starts_with("C#") && !sk.contains("1.0.0")));
    assert!(a.tokens_usados.lock().unwrap().keys().all(|k| k.len() == 64 && !k.starts_with("tok-")));
}
