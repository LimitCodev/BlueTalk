mod comun;
use bluetalk_api::rutas::atender;
use comun::*;

#[tokio::test]
async fn ruta_desconocida_da_404() {
    let r = atender(&estado(), pet("GET", "/v1/nada", None, b""), 0).await;
    assert_eq!(r.estado, 404);
}

#[tokio::test]
async fn cuerpo_de_mas_de_300kb_da_413() {
    let r = atender(&estado(), pet("PUT", "/v1/respaldo", Some(AUTH), &vec![0; 307_201]), 0).await;
    assert_eq!((r.estado, r.cuerpo.as_slice()), (413, br#"{"error":"grande"}"#.as_slice()));
}

#[tokio::test]
async fn metodo_no_permitido_da_405() {
    assert_eq!(atender(&estado(), pet("PATCH", "/v1/dias", None, b""), 0).await.estado, 405);
}
