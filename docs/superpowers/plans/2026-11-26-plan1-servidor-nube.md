# Plan 1: servidor de la nube familiar (Lambda Rust + DynamoDB + SAM)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** una API `/v1` que activa familias suscritas, guarda y entrega bloques cifrados (días y copia de seguridad), suma contadores anónimos y no puede disparar la factura de AWS.

**Architecture:** una sola Lambda en Rust (arm64, 128 MB) detrás de CloudFront (plan Free) con WAF y OAC; una tabla DynamoDB bajo demanda con tope de capacidad y TTL; Google (Integrity y Android Publisher) detrás de un trait para poder probarlo sin red. La lógica no conoce `lambda_http`: recibe una `Peticion` y devuelve una `Respuesta`.

**Tech Stack:** Rust 1.100 (edición 2024), `lambda_http`, `tokio`, `aws-config`, `aws-sdk-dynamodb`, `aws-sdk-ssm`, `serde`/`serde_json`, `jsonwebtoken`, `reqwest` (`rustls-tls`, sin `default-features`), `sha2`; `cargo-lambda`; SAM 1.172; Python 3 + PyYAML para la prueba de la plantilla.

**Spec:** `docs/superpowers/specs/2026-11-26-suscripcion-familia-nube-design.md` (§5, §7, §8 y §9).

**Serie de planes (uno por módulo; cada uno se escribe al cerrar el anterior):**

1. **Servidor** (este plan).
2. Núcleo de nube en la app: clave de familia, HKDF, cifrado y cliente HTTP.
3. Pago y verificación: `in_app_purchase`, Integrity, pantalla de suscripción tras el PIN y prueba de 7 días.
4. Sincronización: subir días, teléfono lector por QR, copia de seguridad, restaurar y borrar.
5. Voces: generar con Polly, publicar en `/voces/` y reproductor `MediaPlayer`.
6. Contadores de investigación con permiso del adulto.
7. Legal, Seguridad de los datos, capturas, `1.0.0+1` y AAB.

## Global Constraints

- Carpeta del servidor: `infra/aws/api/` (crate `bluetalk-api`). Plantilla: `infra/aws/api.yaml`.
- Región `us-east-1`. Paquete `com.limitcodev.bluetalk`. Producto `bluetalk_familia`.
- Lambda: `provided.al2023`, `arm64`, `MemorySize: 128`, `Timeout: 5`, `ReservedConcurrentExecutions: 10`, logs con retención de 3 días.
- DynamoDB: `PAY_PER_REQUEST`, `MaxReadRequestUnits: 50`, `MaxWriteRequestUnits: 50`, TTL en el atributo `ttl`.
- Cuerpo máximo: 300 KB (307 200 bytes). Bloque de día: 4 096 bytes como máximo, 7 días por llamada. Copia de seguridad: 262 144 bytes.
- Cuotas diarias por familia: `PUT /dias` 10, `GET /dias` 60, `PUT /respaldo` 4, `GET /respaldo` 10.
- Un token de compra liga 3 `fid` como máximo.
- Vigencia en caché: `min(fin del periodo, ahora + 86 400 s)`. Lectura permitida hasta `fin + 30 días`. TTL de la familia: `fin + 90 días`. TTL de los días: `ahora + 400 días`.
- Respuestas de error: JSON `{"error":"<código>"}` con los códigos `peticion` (400), `token` (401), `suscripcion` (402), `lleno` (409), `grande` (413), `cuota` (429), `interno` (500).
- Nunca se registran cuerpos, cabeceras, IP ni tokens. Nivel de log `warn`.
- Dependencias aprobadas por el dueño el 26-nov-2026. `tokio` y `aws-config` son las compañeras obligatorias de `lambda_http` y de los SDK; se anotan en el informe de evidencia. Para base64 se usa `aws_smithy_types::base64`; las fechas se calculan a mano: **no se añaden `base64`, `chrono` ni `time`**.
- No se llama a AWS ni a Google reales. Las pruebas con AWS van por `aws-emu` y la skill `probar-aws`, que pide permiso antes de ejecutar.
- Commits: `TIPO: descripción` en español, `git add` con rutas concretas, sin `Co-Authored-By` y **sin push**. Solo se hacen si el dueño pidió commits en esa sesión; si no, cada tarea termina en «listo para commit».

## Contrato de la API (lo consumen los planes 2–6)

| Método y ruta | Autenticación | Cuerpo de la petición | Éxito |
|---|---|---|---|
| `POST /v1/familia` | ninguna | JSON `{"fid","wh","compra","integridad"}` | `201 {"hasta":<s>}` (nueva) · `200 {"hasta":<s>}` (ya existía con el mismo `wh`) |
| `PUT /v1/dias` | `BT1` | JSON `{"dias":[{"d":"AAAA-MM-DD","b":"<base64>"}]}` | `204` |
| `GET /v1/dias?desde=AAAA-MM-DD` | `BT1` | — | `200 {"dias":[{"d","b"}]}` en orden ascendente, 62 como máximo |
| `PUT /v1/respaldo` | `BT1` | binario `application/octet-stream` | `204` |
| `GET /v1/respaldo` | `BT1` | — | `200` binario · `404 {"error":"vacio"}` |
| `DELETE /v1/familia` | `BT1` | — | `204` |
| `POST /v1/contadores` | ninguna | JSON `{"semana":"AAAA-Www","version","c":{funcion:tramo},"integridad"}` | `204` |

- `fid` cumple `^[a-z2-7]{26}$`; `wh` es el SHA-256 de `wtok` en 64 caracteres hexadecimales en minúscula.
- Cabecera: `Authorization: BT1 <fid>.<wtok>`, donde `wtok` es base64url sin relleno de 43 caracteres.
- Integrity: `requestHash` es el hexadecimal de `sha256(fid)` en la activación, y de `sha256("<semana>|<version>")` en los contadores.
- `funcion` admite `comunicar`, `aprender`, `rutinas`, `salud`, `calma` y `voces`. `tramo` admite `0`, `1-5`, `6-20` y `21+`. `semana` solo puede ser la semana ISO actual o la anterior.

## Review Focus

1. **Familia con la suscripción cancelada o reembolsada.** Al pasar las 24 h de caché debe recibir `402` al escribir, y `200` al leer mientras no pasen 30 días desde `fin` (Tarea 3).
2. **Dos activaciones simultáneas con el mismo token desde 4 teléfonos.** Nunca debe haber más de 3 `fid`; la escritura de la ligadura es condicional (Tareas 2 y 6).
3. **Reintento del cliente tras un fallo de red.** Repetir `PUT /dias` con los mismos días los sobrescribe sin duplicarlos y consume cuota; repetir `POST /familia` devuelve `200` (Tareas 2 y 3).
4. **Google caído o lento.** Debe responder `500 interno` sin marcar la familia como vencida ni borrar nada, y el `timeout` de `reqwest` (3 s) cabe en los 5 s de la Lambda (Tareas 3 y 7).
5. **Cabecera `Authorization` mal formada** (sin punto, `fid` inválido, base64 roto): `401`, nunca `500` ni un pánico (Tarea 2).

---

### Tarea 1: crate, tipos de petición y respuesta, router y límite de tamaño

**Files:**
- Create: `infra/aws/api/Cargo.toml`, `infra/aws/api/src/lib.rs`, `src/http.rs`, `src/error.rs`, `src/rutas.rs`, `src/estado.rs`
- Create: `infra/aws/api/.gitignore` (`/target`)
- Test: `infra/aws/api/tests/rutas.rs`

**Interfaces:**
- Produces:
  - `pub struct Peticion { pub metodo: String, pub ruta: String, pub consulta: Option<String>, pub auth: Option<String>, pub cuerpo: Vec<u8> }`
  - `pub struct Respuesta { pub estado: u16, pub tipo: &'static str, pub cuerpo: Vec<u8> }`, con `Respuesta::json(estado, &impl Serialize)`, `Respuesta::vacia(204)` y `Respuesta::binaria(Vec<u8>)`
  - `pub enum ErrorApi { Peticion, Token, Suscripcion, Lleno, Grande, Cuota, Vacio, Interno(String) }`, con `fn estado(&self) -> u16`, `fn codigo(&self) -> &'static str` e `impl From<ErrorApi> for Respuesta`. `Interno` nunca expone su texto en la respuesta.
  - `pub struct Config { pub paquete: String, pub producto: String }`
  - `pub struct Estado<A, G> { pub almacen: A, pub google: G, pub cfg: Config }`
  - `pub async fn atender<A: Almacen, G: Google>(e: &Estado<A, G>, p: Peticion, ahora: u64) -> Respuesta` en `rutas.rs` (`ahora` en segundos Unix).
  - Los traits `Almacen` y `Google` se declaran aquí vacíos y se completan en las Tareas 2–5.

- [ ] **Step 1:** instalar la herramienta aprobada: `pip install --user cargo-lambda`. Verificar con `cargo lambda --version`.
- [ ] **Step 2: prueba que falla.** Archivo `tests/rutas.rs` con dobles `AlmacenMemoria` y `GoogleFalso` en `tests/comun/mod.rs`. En esta tarea son estructuras vacías; crecen en cada tarea.

```rust
#[tokio::test] async fn ruta_desconocida_da_404() {
    let r = atender(&estado(), pet("GET", "/v1/nada", None, b""), 0).await;
    assert_eq!(r.estado, 404);
}
#[tokio::test] async fn cuerpo_de_mas_de_300kb_da_413() {
    let r = atender(&estado(), pet("PUT", "/v1/respaldo", Some(AUTH), &vec![0; 307_201]), 0).await;
    assert_eq!((r.estado, r.cuerpo.as_slice()), (413, br#"{"error":"grande"}"#.as_slice()));
}
#[tokio::test] async fn metodo_no_permitido_da_405() {
    assert_eq!(atender(&estado(), pet("PATCH", "/v1/dias", None, b""), 0).await.estado, 405);
}
```

- [ ] **Step 3:** `cd infra/aws/api && cargo test`. Esperado: no compila (faltan `atender` y `Peticion`).
- [ ] **Step 4:** implementar los tipos y `atender`. El tamaño se comprueba antes de cualquier otra cosa; después se hace un `match (metodo, ruta)`.
- [ ] **Step 5:** `cargo test` y `cargo clippy -- -D warnings`. Esperado: 3 pruebas pasan y 0 avisos.
- [ ] **Step 6:** commit `FEAT: esqueleto de la API de la nube familiar`.

### Tarea 2: autenticación y activación de la familia

**Files:**
- Create: `src/auth.rs`, `src/familia.rs`, `src/google.rs` (solo el trait y los tipos)
- Modify: `src/estado.rs` (traits), `src/rutas.rs`
- Test: `tests/familia.rs`, `tests/auth.rs`

**Interfaces:**
- Produces:
  - `pub struct Familia { pub fid: String, pub wh: [u8; 32], pub token: String, pub hasta: u64, pub fin: u64 }`
  - `pub enum Alta { Nueva, YaExistia, Llena }`
  - `trait Almacen` (todos los métodos son `async fn` y devuelven `Result<_, ErrorApi>`):
    - `familia(&self, fid: &str) -> Option<Familia>`
    - `alta(&self, f: &Familia, token_hash: &str, max: usize) -> Alta`
    - `vigencia(&self, fid: &str, hasta: u64, fin: u64) -> ()`
  - `pub struct Veredicto { pub paquete: String, pub reconocida: bool, pub dispositivo_ok: bool, pub hash_peticion: String }`
  - `pub struct Suscripcion { pub activa: bool, pub producto: String, pub fin: u64, pub reconocida: bool }`
  - `trait Google`: `integridad(&self, token: &str) -> Veredicto`, `suscripcion(&self, token: &str) -> Suscripcion`, `reconocer(&self, producto: &str, token: &str) -> ()`
  - `pub fn autenticar(auth: Option<&str>) -> Result<(String, [u8; 32]), ErrorApi>`: devuelve `fid` y `sha256(wtok)`.
  - `pub fn igual_tiempo_constante(a: &[u8; 32], b: &[u8; 32]) -> bool`
  - `pub async fn familia_autenticada<A: Almacen>(a: &A, auth: Option<&str>) -> Result<Familia, ErrorApi>`: un `fid` inexistente da `401` (no `404`) para no revelar qué familias existen.

- [ ] **Step 1: pruebas que fallan** (`GoogleFalso` configurable: veredicto, suscripción y contador de `reconocer`):
  - `auth_sin_punto_da_401`, `auth_fid_invalido_da_401`, `auth_base64_roto_da_401` y `auth_wtok_equivocado_da_401`: `assert_eq!(r.estado, 401)`.
  - `alta_nueva_da_201_y_reconoce_la_compra`: estado 201, `google.reconocidas == 1` y `hasta == min(fin, ahora + 86_400)`.
  - `alta_repetida_mismo_wh_da_200`, y la misma con otro `wh` da `401`.
  - `cuarto_fid_con_el_mismo_token_da_409`: con 3 altas previas, `r.estado == 409` y el cuerpo `{"error":"lleno"}`.
  - `integridad_mala_da_401`: un caso por cada condición (paquete distinto, `reconocida=false`, `dispositivo_ok=false`, `hash_peticion != hex(sha256(fid))`).
  - `suscripcion_inactiva_o_de_otro_producto_da_402`.
  - `compra_ya_reconocida_no_se_reconoce_otra_vez`: `google.reconocidas == 0`.
- [ ] **Step 2:** `cargo test --test familia --test auth`. Esperado: FAIL.
- [ ] **Step 3:** implementar. Orden en `POST /familia`: validar JSON y formatos (si no, `400`), luego integridad, suscripción, `alta` y, por último, `reconocer` si hace falta. `AlmacenMemoria::alta` aplica el tope de 3 de forma atómica bajo un `Mutex`.
- [ ] **Step 4:** `cargo test`. Esperado: todo PASS.
- [ ] **Step 5:** commit `FEAT: activacion de familia con Integrity y verificacion de la suscripcion`.

### Tarea 3: vigencia, cuotas y días

**Files:**
- Create: `src/vigencia.rs`, `src/cuotas.rs`, `src/dias.rs`, `src/fecha.rs`
- Modify: `src/estado.rs`, `src/rutas.rs`
- Test: `tests/dias.rs`, `tests/fecha.rs`

**Interfaces:**
- Consumes: `familia_autenticada` y `Google::suscripcion` (Tarea 2).
- Produces:
  - `pub enum Uso { Escribir, Leer }`
  - `pub async fn exigir_vigencia<A: Almacen, G: Google>(e: &Estado<A, G>, f: &Familia, uso: Uso, ahora: u64) -> Result<(), ErrorApi>`
  - Nuevos métodos de `Almacen`:
    - `consumir_cuota(&self, fid: &str, ruta: &str, dia: &str, tope: u32) -> bool`
    - `guardar_dias(&self, fid: &str, dias: &[(String, Vec<u8>)], ttl: u64) -> ()`
    - `leer_dias(&self, fid: &str, desde: &str, max: usize) -> Vec<(String, Vec<u8>)>`
  - `pub fn dia_civil(segundos: u64) -> String` (`"AAAA-MM-DD"` en UTC), `pub fn es_dia_valido(s: &str) -> bool` y `pub fn semana_iso(segundos: u64) -> String` (`"AAAA-Www"`).
  - `pub mod cuotas { pub const DIAS_PUT: u32 = 10; pub const DIAS_GET: u32 = 60; pub const RESPALDO_PUT: u32 = 4; pub const RESPALDO_GET: u32 = 10; }`

- [ ] **Step 1: pruebas que fallan.**
  - `fecha`:
    - `dia_civil(0) == "1970-01-01"`, `dia_civil(1_795_651_200) == "2026-11-26"` y `es_dia_valido("2026-02-30") == false`.
    - `semana_iso` de `2026-11-26` es `"2026-W48"` y la de `2027-01-01` es `"2026-W53"`. Verificar las dos fechas con `date -d … +%G-W%V` antes de fijarlas.
  - `vigencia`:
    - `hasta > ahora` no llama a Google: `google.consultas == 0`.
    - Con la caché vencida y Google activa, actualiza `hasta` y `fin`.
    - Con la caché vencida y Google inactiva: escribir da `402`; leer da `200` si `ahora < fin + 2_592_000` y `402` si no.
    - Si Google falla, da `500` y no cambia la familia.
  - `dias`:
    - `put_dias_guarda_y_get_los_devuelve_en_orden`.
    - `put_mismo_dia_dos_veces_sobrescribe`: `leer_dias` devuelve una sola entrada.
    - `ocho_dias_en_una_llamada_da_400`.
    - `bloque_de_4097_bytes_da_413`.
    - `dia_futuro_mas_de_1_dia_da_400`.
    - `undecima_subida_del_dia_da_429`.
    - `get_61_veces_da_429_en_la_61`.
    - `get_sin_desde_o_desde_invalido_da_400`.
- [ ] **Step 2:** `cargo test`. Esperado: FAIL.
- [ ] **Step 3:** implementar.
  - Orden de comprobaciones: autenticar, luego vigencia, luego validar cuerpo, luego cuota y, al final, guardar. Así una petición inválida no gasta cuota.
  - `fecha.rs` usa el algoritmo `days_from_civil` y su inverso, de Howard Hinnant.
- [ ] **Step 4:** `cargo test`. Esperado: PASS.
- [ ] **Step 5:** commit `FEAT: vigencia con cache de 24 h, cuotas diarias y dias cifrados`.

### Tarea 4: copia de seguridad y borrado

**Files:**
- Create: `src/respaldo.rs`
- Modify: `src/familia.rs` (`DELETE`), `src/estado.rs`, `src/rutas.rs`
- Test: `tests/respaldo.rs`

**Interfaces:**
- Produces, como métodos nuevos de `Almacen`:
  - `guardar_respaldo(&self, fid: &str, b: &[u8], ttl: u64) -> ()`
  - `leer_respaldo(&self, fid: &str) -> Option<Vec<u8>>`
  - `borrar_familia(&self, fid: &str, token_hash: &str) -> ()`: borra todos los ítems de `F#<fid>` y quita el `fid` de la ligadura del token.

- [ ] **Step 1: pruebas que fallan.**
  - Guardar 262 144 bytes y leer los mismos bytes.
  - Con 262 145 bytes da `413`.
  - Sin copia, `GET` da `404 {"error":"vacio"}`.
  - La quinta escritura del día da `429`.
  - `borrar_libera_el_cupo`: con 3 `fid` en un token, borrar uno y dar de alta otro distinto da `201`.
  - Después de borrar, `GET /dias` con el mismo `BT1` da `401`.
- [ ] **Step 2:** `cargo test --test respaldo`. Esperado: FAIL.
- [ ] **Step 3:** implementar. `DELETE` no exige vigencia: el derecho de supresión vale aunque no se pague.
- [ ] **Step 4:** `cargo test`. Esperado: PASS.
- [ ] **Step 5:** commit `FEAT: copia de seguridad cifrada y borrado de la familia`.

### Tarea 5: contadores anónimos

**Files:**
- Create: `src/contadores.rs`
- Modify: `src/estado.rs`, `src/rutas.rs`
- Test: `tests/contadores.rs`

**Interfaces:**
- Produces, como método nuevo de `Almacen`: `sumar_contadores(&self, semana: &str, pares: &[(String, String)]) -> ()`. Suma 1 a cada `<funcion>#<tramo>` en `C#<semana>`.

- [ ] **Step 1: pruebas que fallan.**
  - Una petición válida da `204`, y el almacén queda con `C#2026-W48 comunicar#6-20 == 1`.
  - Una función fuera de la lista da `400`; también un tramo fuera de la lista.
  - Una semana de hace 2 semanas da `400`.
  - Un `hash_peticion` que no coincide con `sha256("2026-W48|1.0.0")` da `401`.
  - Más de 6 claves en `c` da `400`.
  - El almacén nunca guarda la `version` ni nada que identifique al emisor. Se comprueba que el doble solo tiene claves `C#…`.
- [ ] **Step 2:** `cargo test --test contadores`. Esperado: FAIL.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** `cargo test`. Esperado: PASS.
- [ ] **Step 5:** commit `FEAT: contadores anonimos de investigacion`.

### Tarea 6: almacén DynamoDB real, probado contra `aws-emu`

**Files:**
- Create: `src/dynamo.rs`
- Test: `tests/dynamo_emu.rs`, detrás de la *feature* `emu`, que no corre en `cargo test` normal.

**Interfaces:**
- Consumes: `trait Almacen` completo (Tareas 2–5).
- Produces: `pub struct AlmacenDynamo { cliente: aws_sdk_dynamodb::Client, tabla: String }` con `impl Almacen`.
- Diseño de la tabla (`pk` y `sk` como texto; `ttl` en número):

| Ítem | `pk` | `sk` | Atributos |
|---|---|---|---|
| Familia | `F#<fid>` | `META` | `wh` (B), `tok` (S), `hasta`, `fin`, `ttl` |
| Ligadura | `T#<sha256(token) hex>` | `META` | `fids` (SS) |
| Día | `F#<fid>` | `D#AAAA-MM-DD` | `b` (B), `ttl` |
| Respaldo | `F#<fid>` | `R` | `b`, `ttl` |
| Cuota | `F#<fid>` | `Q#<día>#<ruta>` | `n`, `ttl = ahora + 172 800` |
| Contador | `C#<semana>` | `<funcion>#<tramo>` | `n` |

- Fragmentos que deciden el comportamiento:
  - **`alta`:** `TransactWriteItems` con dos escrituras.
    1. `Update` de la ligadura con `ADD fids :f` y la condición `attribute_not_exists(fids) OR size(fids) < :max OR contains(fids, :fid)`.
    2. `Put` de la familia con la condición `attribute_not_exists(pk)`.

    Si se cancela por la condición 1, se devuelve `Llena`. Si se cancela por la 2, se lee la familia: con el mismo `wh` es `YaExistia`; si no, es `Token`.
  - **`consumir_cuota`:** `UpdateItem` con `ADD n :1 SET ttl = :t` y la condición `attribute_not_exists(n) OR n < :tope`. Un `ConditionalCheckFailed` devuelve `false`.
  - **`leer_dias`:** `Query` con `pk = :p AND sk BETWEEN :desde AND :fin`, donde `:fin = "D#9999"`, `Limit = max`, orden ascendente.
  - **`borrar_familia`:** `Query` de todo `F#<fid>`, después `BatchWriteItem` de 25 en 25 reintentando los `UnprocessedItems`, y al final `UpdateItem DELETE fids :f` sobre la ligadura.

- [ ] **Step 1:** cargar la skill `probar-aws`. Presentar al dueño las operaciones esperadas (`CreateTable`, `UpdateTimeToLive`, `TransactWriteItems`, `UpdateItem`, `PutItem`, `GetItem`, `Query`, `BatchWriteItem`) y **pedir permiso** antes de ejecutar.
- [ ] **Step 2: pruebas que fallan.** `tests/dynamo_emu.rs` repite contra el emulador las pruebas de las Tareas 2–5 que tocan el almacén, con datos sintéticos. Añade `cuatro_altas_concurrentes_dejan_3_fids`, que lanza 4 `tokio::spawn` contra el mismo token. Esperado: exactamente 3 `Nueva` y 1 `Llena`.
- [ ] **Step 3:** `aws-emu medir --esperadas TransactWriteItems,UpdateItem,Query,BatchWriteItem -- cargo test --features emu --test dynamo_emu`. Esperado: FAIL.
- [ ] **Step 4:** implementar `AlmacenDynamo`. Las diferencias que aparezcan respecto de AWS real se anotan en `~/.local/share/aws-emu/diferencias.md`.
- [ ] **Step 5:** repetir el comando del paso 3. Esperado: PASS, con las operaciones esperadas medidas.
- [ ] **Step 6:** commit `FEAT: almacen DynamoDB con altas atomicas y cuotas condicionales`.

### Tarea 7: cliente real de Google (sin red en las pruebas)

**Files:**
- Create: `src/google_real.rs`
- Test: `tests/google_real.rs` y `tests/fixtures/*.json`. Las respuestas de ejemplo se escriben a mano a partir de la documentación pública; son sintéticas.

**Interfaces:**
- Produces:
  - `pub struct GoogleReal { http: reqwest::Client, cuenta: CuentaServicio, paquete: String, token: tokio::sync::Mutex<Option<(String, u64)>> }` con `impl Google`.
  - `pub fn cuenta_desde_json(s: &str) -> Result<CuentaServicio, ErrorApi>`
  - `pub fn afirmacion_jwt(c: &CuentaServicio, ahora: u64) -> Result<String, ErrorApi>`, con el alcance `https://www.googleapis.com/auth/androidpublisher https://www.googleapis.com/auth/playintegrity`.
  - `pub fn leer_suscripcion(json: &str, producto: &str) -> Result<Suscripcion, ErrorApi>`
  - `pub fn leer_veredicto(json: &str) -> Result<Veredicto, ErrorApi>`
- Endpoints:
  - Token: `POST https://oauth2.googleapis.com/token`
  - Estado de la suscripción: `GET https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{paquete}/purchases/subscriptionsv2/tokens/{token}`
  - Reconocer la compra: `POST …/applications/{paquete}/purchases/subscriptions/{producto}/tokens/{token}:acknowledge`
  - Integrity: `POST https://playintegrity.googleapis.com/v1/{paquete}:decodeIntegrityToken`
- Reglas:
  - `activa` vale `subscriptionState ∈ {SUBSCRIPTION_STATE_ACTIVE, SUBSCRIPTION_STATE_IN_GRACE_PERIOD}` y además algún `lineItems[].productId == producto`.
  - `fin` es el mayor `expiryTime` (RFC 3339 pasado a segundos) de esos ítems.
  - `reconocida` vale `acknowledgementState == ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED`.
  - `dispositivo_ok` vale `deviceRecognitionVerdict` contiene `MEETS_DEVICE_INTEGRITY`.
  - `reconocida` del veredicto vale `appRecognitionVerdict == PLAY_RECOGNIZED`.
  - `timeout` de 3 s.
  - El token OAuth se cachea hasta 60 s antes de que venza.

- [ ] **Step 1: pruebas que fallan.**
  - Fixtures de suscripción: `activa.json`, `gracia.json`, `cancelada_vencida.json`, `otro_producto.json` y `prueba_gratis.json`. La de prueba gratis debe dar `activa`.
  - Fixtures de veredicto: `veredicto_ok.json` y `veredicto_sideload.json`. La de instalación por fuera de Play da `reconocida=false`.
  - Una prueba de `afirmacion_jwt` que decodifica sin verificar y comprueba `iss`, `aud`, `scope`, y que `exp - iat == 3600`.
  - El RFC 3339 con fracciones (`2026-12-26T10:00:00.123Z`) se convierte bien.
- [ ] **Step 2:** `cargo test --test google_real`. Esperado: FAIL.
- [ ] **Step 3:** implementar. El parseo de RFC 3339 reutiliza `fecha.rs`.
- [ ] **Step 4:** `cargo test`. Esperado: PASS.
- [ ] **Step 5:** commit `FEAT: cliente de Google Play (suscripciones e Integrity)`.

### Tarea 8: `main.rs` y binario arm64

**Files:**
- Create: `src/main.rs`
- Modify: `Cargo.toml`, perfil `[profile.release]` con `opt-level = "s"`, `lto = true`, `codegen-units = 1`, `panic = "abort"` y `strip = true`.

**Interfaces:**
- Consumes: `AlmacenDynamo` (Tarea 6), `GoogleReal` (Tarea 7) y `atender` (Tarea 1).
- `main`:
  - Lee las variables `TABLA`, `PARAM_GOOGLE`, `PAQUETE` y `PRODUCTO`.
  - En el arranque en frío lee el parámetro SSM con `with_decryption(true)`, una sola vez.
  - Convierte `lambda_http::Request` en `Peticion`: `consulta` sale de `uri().query()` y `auth` de la cabecera `authorization`.
  - Calcula `ahora` con `SystemTime::now()`.
  - Configura `tracing` en nivel `warn`, sin cuerpos.

- [ ] **Step 1:** `cargo lambda build --release --arm64`. Esperado: `target/lambda/bluetalk-api/bootstrap`.
- [ ] **Step 2:** `ls -l target/lambda/bluetalk-api/bootstrap`. Anotar el tamaño en el informe; se espera menos de 10 MB.
- [ ] **Step 3:** `cargo test && cargo clippy --all-targets -- -D warnings`. Esperado: PASS y 0 avisos.
- [ ] **Step 4:** commit `FEAT: arranque de la Lambda y perfil release minimo`.

### Tarea 9: plantilla SAM, prueba sin red y script de despliegue en simulación

**Files:**
- Create: `infra/aws/api.yaml`, `infra/aws/test_api.py` y `scripts/aws/desplegar_api.sh`
- Modify: `infra/aws/test_plantilla.py`: extraer `_CargadorCfn` a `infra/aws/cfn.py` para que lo usen las dos pruebas, sin cambiar lo que comprueba.

**Interfaces:**
- Consumes: el binario de la Tarea 8 (`CodeUri: api/target/lambda/bluetalk-api/`, `Handler: bootstrap`).
- Recursos y valores fijos:
  - `Tabla`: `AWS::DynamoDB::Table`.
    - Valores de Global Constraints, con `SSESpecification` y `DeletionPolicy: Retain`.
    - Sin PITR: cuesta dinero y los datos están cifrados y respaldados en el teléfono. *shortcut: activar PITR si se pierden datos por un error del servidor*.
  - `Api`: `AWS::Serverless::Function`.
    - Valores de Global Constraints, `FunctionUrlConfig.AuthType: AWS_IAM` y la política `DynamoDBCrudPolicy` sobre `Tabla`.
    - `ssm:GetParameter` solo sobre `PARAM_GOOGLE` y `kms:Decrypt` sobre `alias/aws/ssm`.
    - `LoggingConfig` con `ApplicationLogLevel: WARN` y `LogFormat: JSON`.
  - `RegistroApi`: `AWS::Logs::LogGroup` con `RetentionInDays: 3`.
  - `OacApi`: `AWS::CloudFront::OriginAccessControl` con `OriginAccessControlOriginType: lambda` y `SigningBehavior: always`.
  - `PermisoCloudFront`: `AWS::Lambda::Permission` con `lambda:InvokeFunctionUrl` para `cloudfront.amazonaws.com` y `SourceArn` igual a la distribución.
  - `Distribucion`:
    - Origen: la Function URL.
    - Comportamiento por defecto con `CachePolicyId` CachingDisabled (`4135ea2d-6df8-44a3-9df3-4b5a84be39ad`) y `OriginRequestPolicyId` AllViewerExceptHostHeader (`b689b0a8-53d0-40ab-baf2-68738e2966ac`).
    - `AllowedMethods` con los 7 métodos y `PriceClass_All`.
    - `WebACLId: !GetAtt Waf.Arn`.
  - `Waf`: `AWS::WAFv2::WebACL` con `Scope: CLOUDFRONT` y 4 reglas.
    1. `LimitePorIp`: `RateBasedStatement` con `Limit: 300`, `EvaluationWindowSec: 300` y `AggregateKeyType: IP`.
    2. `SoloRutasConocidas`: bloquea si la URI no cumple `^/v1/(familia|dias|respaldo|contadores)$`.
    3. `AlertaActivacion`: limita `POST /v1/familia` a 10 peticiones cada 5 minutos por IP.
    4. `AWSManagedRulesCommonRuleSet` con `RuleActionOverrides` en `Count` para `SizeRestrictions_BODY`, porque bloquea cuerpos de más de 8 KB y rompería `/respaldo`.
  - `TemaGasto`: `AWS::SNS::Topic`.
  - `Presupuesto`: `AWS::Budgets::Budget` de 10 USD al mes.
    - Avisos por correo a 30 % real y 50 % previsto: 3 y 5 USD.
    - Aviso a SNS al 100 % real.
  - `Corte`: función Python 3.13 en línea, de 15 líneas como máximo, suscrita a `TemaGasto`.
    - Llama a `lambda.put_function_concurrency(FunctionName=<Api>, ReservedConcurrentExecutions=0)`.
    - Su permiso IAM se limita a `lambda:PutFunctionConcurrency` sobre el ARN de `Api`.
  - Parámetros de la plantilla: `CorreoAlarma` y `ParamGoogle` (por defecto `/bluetalk/google-cuenta-servicio`).
  - Salidas: `UrlApi`, que es el dominio de CloudFront.

- [ ] **Step 1: pruebas que fallan.** `test_api.py`, con `unittest` como `test_plantilla.py`:
  - `test_lambda_minima`: arquitectura `arm64`, 128 MB, timeout 5 y concurrencia 10.
  - `test_url_solo_con_iam`: `AuthType == "AWS_IAM"`.
  - `test_tabla_con_tope_y_ttl`: `MaxReadRequestUnits == 50 == MaxWriteRequestUnits` y `TimeToLiveSpecification.AttributeName == "ttl"`.
  - `test_logs_3_dias`.
  - `test_waf_reglas`: límite 300, la regex de rutas y `SizeRestrictions_BODY` en `Count`.
  - `test_presupuesto_y_corte`: límite 10, umbrales 30, 50 y 100, y un `Corte` que solo puede `PutFunctionConcurrency`.
  - `test_sin_registros_de_acceso`: la distribución no tiene `Logging`.
- [ ] **Step 2:** `python3 -m unittest discover -s infra/aws -p 'test_*.py'`. Esperado: FAIL en `test_api` y PASS en `test_plantilla`.
- [ ] **Step 3:** escribir `api.yaml`, `cfn.py` y `desplegar_api.sh`. El script carga `comun.sh`, compila con `cargo lambda`, ejecuta `sam deploy` con `PILA=bluetalk-api` y simula por defecto.
- [ ] **Step 4:** volver a correr las pruebas del paso 2 y además `sam validate --lint -t infra/aws/api.yaml`. Esperado: todo PASS y sin errores de lint.
- [ ] **Step 5:** `scripts/aws/desplegar_api.sh tu@correo` (simulación). Esperado: imprime `[simulación] sam deploy …` y no llama a AWS.
- [ ] **Step 6:** commit `FEAT: plantilla SAM de la API con WAF, tope de gasto y corte`.

### Tarea 10: documentación y evidencia

**Files:**
- Modify: `docs/infra/aws-freemium.md`: §1 suma la API (tabla de piezas y costes), §4 suma los pasos para conectarla y §0 pasa a decir que la nube es opcional y de pago.
- Create: `docs/informes/plan1-servidor-evidencia.md`, con los comandos ejecutados, su salida resumida, el tamaño del binario, las operaciones medidas por `aws-emu` y lo que queda NO VERIFICADO.

Queda NO VERIFICADO:
- El despliegue real.
- El plan Free de CloudFront asociado a esta distribución.
- Los precios.
- Las RTDN.

- [ ] **Step 1:** escribir los dos documentos.
- [ ] **Step 2:** correr todo de nuevo: `cd infra/aws/api && cargo test && cargo clippy --all-targets -- -D warnings`, y `python3 -m unittest discover -s infra/aws -p 'test_*.py'`. Esperado: PASS.
- [ ] **Step 3:** commit `DOCS: evidencia del plan 1 (servidor de la nube familiar)`.

**Fuera de este plan (requiere al dueño):** desplegar de verdad (`DE_VERDAD=1`), crear el parámetro SSM con la cuenta de servicio de Google y elegir el plan Free de CloudFront en la consola.
