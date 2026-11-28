mod comun;
use bluetalk_api::rutas::atender;
use comun::*;
use serde_json::json;

const SEMANA: &str = "2026-W48";

async fn enviar(e: &Est, cuerpo: serde_json::Value) -> u16 {
    atender(e, pet("POST", "/v1/contadores", None, &serde_json::to_vec(&cuerpo).unwrap()), AHORA).await.estado
}

fn cuerpo(semana: &str, c: serde_json::Value) -> serde_json::Value {
    json!({ "semana": semana, "version": "1.0.0", "c": c, "integridad": "tok-int" })
}

fn con_hash(e: &Est, semana: &str, version: &str) {
    e.google.veredicto.lock().unwrap().hash_peticion = hex_sha(format!("{semana}|{version}").as_bytes());
}

#[tokio::test]
async fn peticion_valida_da_204_y_suma_uno() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0");
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"comunicar": "6-20", "voces": "0"}))).await, 204);
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"comunicar": "6-20"}))).await, 204);
    let cs = e.almacen.contadores.lock().unwrap();
    assert_eq!(cs[&("C#2026-W48".to_string(), "comunicar#6-20".to_string())], 2);
    assert_eq!(cs[&("C#2026-W48".to_string(), "voces#0".to_string())], 1);
}

#[tokio::test]
async fn semana_anterior_vale() {
    let e = estado();
    con_hash(&e, "2026-W47", "1.0.0");
    assert_eq!(enviar(&e, cuerpo("2026-W47", json!({"salud": "21+"}))).await, 204);
}

#[tokio::test]
async fn funcion_o_tramo_fuera_de_la_lista_da_400() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0");
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"otra": "0"}))).await, 400);
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"calma": "7-9"}))).await, 400);
    assert!(e.almacen.contadores.lock().unwrap().is_empty());
}

#[tokio::test]
async fn semana_de_hace_dos_semanas_o_futura_da_400() {
    let e = estado();
    for s in ["2026-W46", "2026-W49", "2026-48", "x"] {
        con_hash(&e, s, "1.0.0");
        assert_eq!(enviar(&e, cuerpo(s, json!({"salud": "0"}))).await, 400, "{s}");
    }
}

#[tokio::test]
async fn hash_que_no_coincide_da_401() {
    let e = estado();
    con_hash(&e, SEMANA, "9.9.9");
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"salud": "0"}))).await, 401);
    assert!(e.almacen.contadores.lock().unwrap().is_empty());
}

#[tokio::test]
async fn veredicto_viejo_da_401() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0");
    e.google.veredicto.lock().unwrap().timestamp_ms = (AHORA - 301) * 1000;
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"salud": "0"}))).await, 401);
}

#[tokio::test]
async fn mas_de_seis_claves_o_ninguna_da_400() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0");
    let siete = json!({"comunicar":"0","aprender":"0","rutinas":"0","salud":"0","calma":"0","voces":"0","extra":"0"});
    assert_eq!(enviar(&e, cuerpo(SEMANA, siete)).await, 400);
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({}))).await, 400);
}

#[tokio::test]
async fn el_almacen_solo_guarda_claves_de_contador() {
    let e = estado();
    con_hash(&e, SEMANA, "1.0.0");
    assert_eq!(enviar(&e, cuerpo(SEMANA, json!({"comunicar": "1-5"}))).await, 204);
    assert!(e.almacen.familias.lock().unwrap().is_empty());
    let cs = e.almacen.contadores.lock().unwrap();
    assert!(cs.keys().all(|(pk, sk)| pk.starts_with("C#") && !sk.contains("1.0.0")));
}
