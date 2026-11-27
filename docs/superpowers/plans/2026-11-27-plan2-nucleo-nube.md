# Plan 2: núcleo de nube en la app (clave de familia, HKDF, cifrado y cliente HTTP)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** una puerta nueva del core, `lib/core/nube/`, que genera y guarda la clave de familia `K`, deriva `fid`, `wtok` y `kenc`, sella bloques (gzip + XChaCha20-Poly1305 con AAD) y habla con la API `/v1` del Plan 1 por HTTPS con `dart:io`, sin dependencias nuevas. Sin pantallas: las usan los planes 3–6.

**Architecture:** todo vive en `lib/core/nube/`, detrás de interfaces (`CofreClave`, `ClienteNube`) con dobles en `test/core/nube/`. La configuración (URL, producto, proyecto de Google) está en un solo archivo y sale de `--dart-define`; sin ella la nube queda «no configurada» y nada llama a la red. Las pantallas nunca importan `lib/core/nube/`: lo vigila una regla nueva en `test/arquitectura/capas_test.dart`. Solo el manifiesto `play` recibe `INTERNET`.

**Tech Stack:** Flutter (Dart `^3.12.2`), `cryptography 2.9.0` (ya instalado: `Hkdf`, `Hmac.sha256`, `Sha256`, `Xchacha20.poly1305Aead`), `flutter_secure_storage 11.x` (ya instalado), `dart:io` (`HttpClient`, `gzip`, `HttpServer` en las pruebas), Riverpod 3.4.

**Spec:** `docs/superpowers/specs/2026-11-26-suscripcion-familia-nube-design.md` (§6, §7, §10 y §12). Contrato: `docs/superpowers/plans/2026-11-26-plan1-servidor-nube.md` («Contrato de la API»).

**Serie:** Plan 1 (servidor) → **Plan 2 (este)** → Plan 3 (pago e Integrity) → Plan 4 (sincronización) → Plan 5 (voces) → Plan 6 (contadores) → Plan 7 (legal y AAB).

**Depende de:** nada de la app. No necesita el servidor desplegado: el cliente se prueba contra un `HttpServer` local que imita el contrato. **Lo necesitan:** los planes 3, 4, 5 y 6.

## Global Constraints

- **Solo la edición `play`** recibe `INTERNET`, Integrity y Billing. La edición `directa` sigue compilando (`flutter build apk --debug --flavor directa`) y sus pruebas siguen en verde; en `directa` la nube está siempre «no configurada» (`nubeConfiguradaProvider == false`).
- Nada regresiona: menú `/inicio`, guía de la primera vez con la mascota, gráficos del adulto, modo calma, TalkBack, objetivos táctiles ≥48 dp y **ninguna voz automática**. Este plan no toca pantallas.
- Línea base: antes de la Tarea 1, `timeout 1200 flutter test` debe estar en verde (el tope de `textos_legales.dart` ya se corrigió en `6bf021c`). Anotar el número de pruebas en el informe. Si algo falla, parar y anotarlo como **BLOQUEADO**: no es de este plan.
- Reglas de `test/arquitectura/`: ningún archivo de UI importa `lib/core/nube/` (regla nueva de la Tarea 5); solo `CanalNativo` crea `MethodChannel`; solo la puerta del almacén (`lib/core/almacen/`) toca `SharedPreferences`. Archivos nuevos de 100 líneas como máximo (`tamano_test.dart`); los de `_deuda` solo pueden encoger.
- **Sin dependencias nuevas** en este plan (spec §11: las de Flutter son `in_app_purchase` y `qr_flutter`, y llegan en los planes 3 y 4).
- Sin llamadas reales a AWS ni a Google en las pruebas: el cliente se prueba contra `HttpServer.bind('127.0.0.1', 0)`; el resto, con `ClienteNubeFalso`.
- La clave `K` solo vive en `flutter_secure_storage` (clave `bluetalk_nube_clave`). **Nunca** en `SharedPreferences`, en logs, en mensajes de error ni en el portapapeles. Si el keystore falla, la nube no se activa (no hay respaldo sin cifrar, a diferencia del PIN).
- Antes de cada commit: `timeout 600 flutter analyze` (0 problemas) y `timeout 1200 flutter test` (todo verde).
- Commits `TIPO: descripción` en español, ≤70 caracteres, `git add` con rutas concretas, **sin** `Co-Authored-By` y **sin push**. Solo se hacen si el dueño pidió commits en esa sesión; si no, cada tarea termina en «listo para commit».
- Lo que no se pueda comprobar se escribe como **NO VERIFICADO** en `docs/informes/plan2-nucleo-evidencia.md`.

## Contrato de la API (copia del Plan 1; manda el Plan 1)

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
- Integrity: `requestHash` es el hexadecimal de `sha256("<fid>|<wh>")` en la activación (con `wh` en hexadecimal; el veredicto debe tener como máximo 300 000 ms de antigüedad y 60 000 ms de adelanto), y de `sha256("<semana>|<version>")` en los contadores.
- `funcion` admite `comunicar`, `aprender`, `rutinas`, `salud`, `calma` y `voces`. `tramo` admite `0`, `1-5`, `6-20` y `21+`. `semana` solo puede ser la semana ISO actual o la anterior.

Precisiones verificadas en el código del servidor (`infra/aws/api/src/`):

- `wh = hex(sha256(<los 43 caracteres ASCII de wtok>))`: el hash es sobre el **texto** base64url, tal como viaja (`auth.rs`, `autenticar`), no sobre los 32 bytes.
- `compra` mide de 1 a 4 096 caracteres e `integridad` de 1 a 8 192 (`familia.rs`); si no, `400`.
- Errores: JSON `{"error":"<código>"}` con `peticion` 400, `token` 401, `suscripcion` 402, `ruta`/`vacio` 404, `metodo` 405, `lleno` 409, `grande` 413, `cuota` 429, `interno` 500 (`error.rs`). El corte de gasto deja la Lambda sin concurrencia: lo que devuelva CloudFront entonces (¿`429`, `502`, `503`?) es **NO VERIFICADO**; el cliente trata `429` y todo `5xx` igual: «reintentar mañana».
- El base64 de `b` es el **estándar con relleno** (`aws_smithy_types::base64`), no base64url.
- CloudFront con OAC exige `x-amz-content-sha256: <hex sha256 del cuerpo>` en `POST` y `PUT`. Lo calcula el cliente.

## Review Focus

1. **La clave `K` nunca sale del cofre** salvo por `ClaveFamilia.codigo` y `ClaveFamilia.qr`. Ningún `toString`, log ni `ErrorNube` la contiene (Tareas 3 y 4).
2. **AAD exacto:** `"<fid>|dia|<AAAA-MM-DD>"` y `"<fid>|respaldo|-"`. Un bloque de otro día u otra familia no abre (devuelve `null`, no lanza) (Tarea 3).
3. **El vector conocido** del Apéndice A coincide byte a byte: si no, los teléfonos de la familia no se entenderían tras una actualización (Tareas 3 y 4).
4. **Fallo de red o servidor lento:** toda llamada termina en 15 s como máximo con `ErrorNube(red)`, nunca cuelga ni lanza `SocketException` hacia arriba (Tarea 4).
5. **Edición `directa` y pruebas:** sin `--dart-define`, `nubeConfiguradaProvider` es `false` y ningún provider crea un `HttpClient` (Tarea 5).

---

### Task 1: configuración de la nube y codificaciones

**Files:**
- Create: `lib/core/nube/config_nube.dart`, `lib/core/nube/codificacion.dart`
- Test: `test/core/nube/codificacion_test.dart`, `test/core/nube/config_nube_test.dart`

**Interfaces:**
- Produces:
  - `class ConfigNube { const ConfigNube({required String urlApi, required String urlVoces, required int proyectoGoogle}); const ConfigNube.deCompilacion(); static const producto = 'bluetalk_familia'; static const paquete = 'com.limitcodev.bluetalk'; bool get completa; bool get vocesListas; }`
  - `String base32(List<int> bytes)` (RFC 4648, minúscula, sin relleno)
  - `String base64UrlSinRelleno(List<int> bytes)`
  - `String hex(List<int> bytes)`
  - `Future<String> sha256Hex(List<int> bytes)`

Código de `config_nube.dart` (completo):

```dart
/// Único sitio con la configuración de la nube familiar (spec §10).
///
/// Sale de `--dart-define` al compilar (lo pasa `scripts/build-aab.sh`).
/// Sin esos valores la nube está «no configurada»: la app no enseña la
/// suscripción y no llama a la red. Así funciona igual en las pruebas, en
/// `directa` y antes de que el dueño despliegue la API.
class ConfigNube {
  const ConfigNube({
    required this.urlApi,
    required this.urlVoces,
    required this.proyectoGoogle,
  });

  const ConfigNube.deCompilacion()
      : urlApi = const String.fromEnvironment('BLUETALK_NUBE_URL'),
        urlVoces = const String.fromEnvironment('BLUETALK_CDN_URL'),
        proyectoGoogle = const int.fromEnvironment('BLUETALK_GCP_PROYECTO');

  /// Id del producto de suscripción en Play Console (Plan 1).
  static const producto = 'bluetalk_familia';
  static const paquete = 'com.limitcodev.bluetalk';

  /// Dominio de CloudFront de la API, p. ej. `https://dxxxx.cloudfront.net`.
  final String urlApi;

  /// Dominio del CDN estático (`infra/aws/cdn.yaml`), donde vive `/voces/`.
  final String urlVoces;

  /// Número del proyecto de Google Cloud vinculado a Play (Integrity).
  final int proyectoGoogle;

  bool get completa => urlApi.startsWith('https://') && proyectoGoogle > 0;

  bool get vocesListas => urlVoces.startsWith('https://');
}
```

- [ ] **Step 1: pruebas que fallan.**
  - `codificacion_test.dart` (vectores de RFC 4648 §10, pasados a minúscula):
    - `base32([]) == ''`, `base32(utf8.encode('f')) == 'my'`, `base32(utf8.encode('fo')) == 'mzxq'`, `base32(utf8.encode('foobar')) == 'mzxw6ytboi'`.
    - `base32` de 16 bytes da 26 caracteres que cumplen `^[a-z2-7]{26}$`.
    - `base64UrlSinRelleno` de 32 bytes da 43 caracteres sin `=` ni `+` ni `/`.
    - `hex([0, 15, 255]) == '000fff'`.
    - `await sha256Hex(utf8.encode('abc')) == 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad'`.
  - `config_nube_test.dart`:
    - `const ConfigNube.deCompilacion().completa == false` (las pruebas corren sin `--dart-define`).
    - `ConfigNube(urlApi: 'http://x', urlVoces: '', proyectoGoogle: 1).completa == false` (solo `https`).
    - `ConfigNube(urlApi: 'https://x', urlVoces: '', proyectoGoogle: 0).completa == false`.
    - `ConfigNube(urlApi: 'https://x', urlVoces: 'https://y', proyectoGoogle: 123).completa && .vocesListas`.
- [ ] **Step 2:** `timeout 300 flutter test test/core/nube/`. Esperado: FAIL (no existen los archivos).
- [ ] **Step 3:** implementar `codificacion.dart` (≤60 líneas). `base32` con acumulador de bits; enmascarar el acumulador tras cada byte (`acc &= (1 << bits) - 1`) para que no crezca. `base64UrlSinRelleno(b) => base64Url.encode(b).replaceAll('=', '')`. `sha256Hex` usa `Sha256().hash(bytes)` de `cryptography`.
- [ ] **Step 4:** `timeout 300 flutter test test/core/nube/` y `timeout 600 flutter analyze`. Esperado: PASS y 0 problemas.
- [ ] **Step 5:** commit `FEAT: configuracion y codificaciones de la nube familiar`.

### Task 2: clave de familia, código de 13 grupos y derivación HKDF

**Files:**
- Create: `lib/core/nube/clave_familia.dart`, `lib/core/nube/cofre_clave.dart`
- Test: `test/core/nube/clave_familia_test.dart`, `test/core/nube/cofre_clave_test.dart`

**Interfaces:**
- Consumes: `base32`, `base64UrlSinRelleno`, `sha256Hex` (Tarea 1).
- Produces:
  - `class ClaveFamilia { ClaveFamilia(List<int> bytes); factory ClaveFamilia.generar([Random? azar]); static Future<ClaveFamilia?> desdeCodigo(String texto); Future<String> codigo(); Future<String> qr(); Future<CredencialesFamilia> derivar(); String toString() => 'ClaveFamilia(***)'; }`
  - `class CredencialesFamilia { final String fid, wtok, wh; final SecretKey kenc; String get autorizacion => 'BT1 $fid.$wtok'; String toString() => 'CredencialesFamilia($fid)'; }`
  - `abstract interface class CofreClave { Future<ClaveFamilia?> leer(); Future<void> guardar(ClaveFamilia k); Future<void> borrar(); }`
  - `class CofreSeguro implements CofreClave` (sobre `FlutterSecureStorage`, clave `bluetalk_nube_clave`, valor en base64 estándar) y `class CofreMemoria implements CofreClave` (para pruebas y para la edición sin keystore).
  - Si el keystore lanza, `CofreSeguro` relanza `const ErrorNube(TipoErrorNube.cofre)` (tipo definido en la Tarea 4; en esta tarea se crea `lib/core/nube/error_nube.dart` con el `enum` completo de la Tarea 4 para no tocarlo dos veces).

Parámetros fijos (no cambiar nunca: cambiarlos deja sin acceso a las familias existentes):

| Valor | Cálculo |
|---|---|
| `K` | 32 bytes de `Random.secure()` |
| sal de HKDF | `utf8.encode('bluetalk-familia-v1')` (es el parámetro `nonce` de `Hkdf.deriveKey` en `cryptography`) |
| `fid` | `base32(HKDF-SHA256(K, sal, info: utf8('fid'), 16 bytes))` → 26 caracteres |
| `wtok` | `base64UrlSinRelleno(HKDF-SHA256(K, sal, info: utf8('wtok'), 32 bytes))` → 43 caracteres |
| `wh` | `sha256Hex(utf8.encode(wtok))` (sobre el texto) |
| `kenc` | `SecretKey(HKDF-SHA256(K, sal, info: utf8('kenc'), 32 bytes))` |
| código | `K` (256 bits) seguido de 4 bits de control = los 4 bits altos de `sha256(K)[0]`; 260 bits en base32 **mayúscula** (`A–Z2–7`) = 52 caracteres en 13 grupos de 4 unidos con `-` |
| QR | `'BTF1:'` + los 52 caracteres sin guiones |

Fragmento que decide el formato (completo):

```dart
const _alfabeto = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
final _sal = utf8.encode('bluetalk-familia-v1');

Future<List<int>> _parte(List<int> k, String info, int largo) async {
  final clave = await Hkdf(hmac: Hmac.sha256(), outputLength: largo)
      .deriveKey(secretKey: SecretKey(k), nonce: _sal, info: utf8.encode(info));
  return clave.extractBytes();
}

Future<String> _codigoPlano(List<int> k) async {
  final control = (await Sha256().hash(k)).bytes[0] >> 4;
  var n = BigInt.zero;
  for (final b in k) {
    n = (n << 8) | BigInt.from(b);
  }
  n = (n << 4) | BigInt.from(control);
  final cinco = BigInt.from(31);
  return [
    for (var i = 51; i >= 0; i--) _alfabeto[((n >> (5 * i)) & cinco).toInt()],
  ].join();
}

/// Acepta minúsculas, espacios, guiones y el prefijo `BTF1:`. Confunde a
/// propósito `0→O`, `1→I` y `8→B`, que no existen en el alfabeto.
String _normalizar(String texto) => texto
    .toUpperCase()
    .replaceFirst('BTF1:', '')
    .replaceAll('0', 'O')
    .replaceAll('1', 'I')
    .replaceAll('8', 'B')
    .replaceAll(RegExp('[^A-Z2-7]'), '');
```

`desdeCodigo`: normaliza; si no quedan exactamente 52 caracteres, `null`; reconstruye `n`; `control = n & 15`; `K` = los 32 bytes de `n >> 4` en big-endian; si `control != sha256(K)[0] >> 4`, `null` (detecta 15 de cada 16 errores de tecleo sin gastar una llamada).

- [ ] **Step 1: pruebas que fallan** (`clave_familia_test.dart`), con `K = List.generate(32, (i) => i)` y los valores del **Apéndice A**:
  - `derivar()` da `fid == 'fu7wu6tv3pzmf6yuhhqlkatvtm'`, `wtok == 'TAseB0v7lXm94Ga1quD5h_dkA6yzOCDazG0UmXcyhWQ'`, `wh == '60fec683d5998a7c0c5b2e1f9e008fa5008c2487f2596f4b8ce25335db6ff8ef'` y `hex(await kenc.extractBytes()) == '8da99c3dfec9b74b235e686713922137d55a3a7eb92de70bbf1cc3f467208e41'`.
  - `codigo() == 'AAAQ-EAYE-AUDA-OCAJ-BIFQ-YDIO-B4IB-CEQT-CQKR-MFYY-DENB-WHA5-DYPW'`.
  - `qr() == 'BTF1:AAAQEAYEAUDAOCAJBIFQYDIOB4IBCEQTCQKRMFYYDENBWHA5DYPW'`.
  - Ida y vuelta: `desdeCodigo(codigo)`, `desdeCodigo(qr)`, `desdeCodigo(codigo.toLowerCase().replaceAll('-', ' '))` y con `O` cambiada por `0` devuelven los mismos 32 bytes.
  - Cambiar un carácter del código (p. ej. el primero `A→B`) da `null` en ese vector concreto (comprobado: el nibble de control es 6). Un código de 51 caracteres da `null`.
  - `fid` determinista: dos `derivar()` de la misma `K` dan el mismo `fid`; dos `ClaveFamilia.generar()` dan `fid` distintos.
  - `ClaveFamilia(...).toString()` y `CredencialesFamilia.toString()` no contienen `wtok` ni ningún grupo del código.
  - `autorizacion == 'BT1 fu7wu6tv3pzmf6yuhhqlkatvtm.TAseB0v7lXm94Ga1quD5h_dkA6yzOCDazG0UmXcyhWQ'`.
  - `ClaveFamilia(List.filled(31, 0))` lanza `ArgumentError` (exactamente 32 bytes).
- [ ] **Step 2: pruebas que fallan** (`cofre_clave_test.dart`), con un doble de `FlutterSecureStorage` al estilo de `test/padre/harness.dart` (implementa `read`, `write` y `delete`; el resto con `noSuchMethod`):
  - Guardar y leer devuelve la misma clave; el valor guardado bajo `bluetalk_nube_clave` no es el código de familia (es base64 de los 32 bytes).
  - Sin clave guardada, `leer()` da `null`.
  - Si `write` lanza, `guardar` lanza `ErrorNube` con `tipo == TipoErrorNube.cofre`, y el mensaje no contiene la clave.
  - `borrar()` deja `leer()` en `null`.
- [ ] **Step 3:** `timeout 300 flutter test test/core/nube/`. Esperado: FAIL.
- [ ] **Step 4:** implementar. `clave_familia.dart` ≤100 líneas: si no cabe, llevar `_codigoPlano`, `_normalizar` y `desdeCodigo` a `lib/core/nube/codigo_familia.dart`.
- [ ] **Step 5:** `timeout 300 flutter test test/core/nube/` y `timeout 600 flutter analyze`. Esperado: PASS y 0 problemas.
- [ ] **Step 6:** commit `FEAT: clave de familia con codigo de 13 grupos y HKDF`.

### Task 3: sobre cifrado (gzip + XChaCha20-Poly1305 con AAD)

**Files:**
- Create: `lib/core/nube/sobre.dart`
- Test: `test/core/nube/sobre_test.dart`

**Interfaces:**
- Consumes: `CredencialesFamilia.kenc` (Tarea 2).
- Produces:
  - `List<int> aadDia(String fid, String dia)` → `utf8('<fid>|dia|<dia>')`
  - `List<int> aadRespaldo(String fid)` → `utf8('<fid>|respaldo|-')`
  - `Future<Uint8List> sellar(SecretKey kenc, List<int> claro, List<int> aad, {List<int>? nonce})`: sin comprimir; `nonce` solo para el vector de prueba.
  - `Future<List<int>?> abrir(SecretKey kenc, List<int> bloque, List<int> aad)`: `null` si la versión, la longitud, el MAC o el AAD no cuadran. Nunca lanza por datos malos.
  - `Future<Uint8List> sellarJson(SecretKey kenc, Object json, List<int> aad)`: `utf8(jsonEncode(json))` → `gzip.encode` → `sellar`.
  - `Future<Object?> abrirJson(SecretKey kenc, List<int> bloque, List<int> aad)`: `abrir` → `gzip.decode` → `jsonDecode`; `null` si cualquier paso falla.

Formato del bloque (fijo): `0x01` (versión) ‖ nonce (24 bytes) ‖ cifrado ‖ MAC (16 bytes) = `SecretBox.concatenation()` con un byte delante. Sobrecoste: 41 bytes.

```dart
const _version = 1;
final _aead = Xchacha20.poly1305Aead();

Future<Uint8List> sellar(SecretKey kenc, List<int> claro, List<int> aad,
    {List<int>? nonce}) async {
  final caja =
      await _aead.encrypt(claro, secretKey: kenc, aad: aad, nonce: nonce);
  return Uint8List.fromList([_version, ...caja.concatenation()]);
}

Future<List<int>?> abrir(SecretKey kenc, List<int> bloque, List<int> aad) async {
  if (bloque.length < 41 || bloque[0] != _version) return null;
  try {
    final caja = SecretBox.fromConcatenation(bloque.sublist(1),
        nonceLength: 24, macLength: 16);
    return await _aead.decrypt(caja, secretKey: kenc, aad: aad);
  } on SecretBoxAuthenticationError {
    return null;
  }
}
```

`abrirJson` descomprime **después** de autenticar: solo un teléfono con `kenc` puede producir un bloque que llegue a `gzip.decode`, así que no hay bomba de descompresión de terceros. Capturar `FormatException` (gzip o JSON corruptos) y devolver `null`.

- [ ] **Step 1: pruebas que fallan.**
  - **Vector conocido (Apéndice A):** con `kenc` del Apéndice A, `nonce = List.generate(24, (i) => i)`, `aad = aadDia('fu7wu6tv3pzmf6yuhhqlkatvtm', '2026-11-26')` y `claro = utf8.encode('{"r":{"dia":"2026-11-26","p":3}}')`, `hex(await sellar(...))` es exactamente el bloque del Apéndice A (73 bytes).
  - Ida y vuelta: `abrir(sellar(x))` devuelve `x` para `[]`, 1 byte y 300 000 bytes.
  - AAD cambiado: sellado para `2026-11-26` y abierto con `aadDia(fid, '2026-11-27')` da `null`; con otro `fid`, `null`; con `aadRespaldo(fid)`, `null`.
  - Bloque alterado: cambiar cualquier byte del cifrado o del MAC da `null`; versión `0x02` da `null`; 40 bytes da `null`.
  - Otra `kenc` da `null`.
  - Dos `sellar` del mismo texto dan bloques distintos (nonce aleatorio).
  - `sellarJson` + `abrirJson` devuelven el mismo mapa; un JSON de 50 000 caracteres repetidos produce un bloque de menos de 2 000 bytes (comprime antes de cifrar).
  - `abrirJson` de un bloque válido cuyo contenido no es gzip da `null`, no lanza.
- [ ] **Step 2:** `timeout 300 flutter test test/core/nube/sobre_test.dart`. Esperado: FAIL.
- [ ] **Step 3:** implementar (≤70 líneas).
- [ ] **Step 4:** `timeout 300 flutter test test/core/nube/` y `timeout 600 flutter analyze`. Esperado: PASS y 0 problemas.
- [ ] **Step 5:** commit `FEAT: sobre cifrado con XChaCha20-Poly1305 y AAD por dia`.

### Task 4: cliente HTTP de la API `/v1` con `dart:io`

**Files:**
- Create: `lib/core/nube/error_nube.dart` (si la Tarea 2 no lo creó), `lib/core/nube/cliente_nube.dart`, `lib/core/nube/cliente_nube_http.dart`, `lib/core/nube/transporte_http.dart`
- Test: `test/core/nube/cliente_nube_http_test.dart`, `test/core/nube/servidor_falso.dart`, `test/core/nube/cliente_falso.dart`

**Interfaces:**
- Produces:

```dart
enum TipoErrorNube {
  peticion, token, suscripcion, vacio, lleno, grande, cuota, corte,
  servidor, red, cofre;

  /// Se reintenta otro día; nunca en bucle (spec §7).
  bool get reintentable =>
      this == cuota || this == corte || this == servidor || this == red;
}

class ErrorNube implements Exception {
  const ErrorNube(this.tipo);
  final TipoErrorNube tipo;
  @override
  String toString() => 'ErrorNube(${tipo.name})';
}

/// 400 peticion · 401 token · 402 suscripcion · 404 vacio · 409 lleno ·
/// 413 grande · 429 cuota · 503 corte · resto servidor.
TipoErrorNube tipoDeEstado(int estado) => switch (estado) {
      400 => TipoErrorNube.peticion,
      401 => TipoErrorNube.token,
      402 => TipoErrorNube.suscripcion,
      404 => TipoErrorNube.vacio,
      409 => TipoErrorNube.lleno,
      413 => TipoErrorNube.grande,
      429 => TipoErrorNube.cuota,
      503 => TipoErrorNube.corte,
      _ => TipoErrorNube.servidor,
    };

typedef BloqueDia = ({String d, Uint8List b});

/// Puerta de la app a la API `/v1` (Plan 1). Lanza [ErrorNube]; nunca
/// `SocketException`, `TimeoutException` ni `FormatException`.
abstract interface class ClienteNube {
  /// `POST /v1/familia`. Devuelve `hasta` (segundos Unix).
  Future<int> activar({required String fid, required String wh,
      required String compra, required String integridad});
  Future<void> subirDias(CredencialesFamilia c, List<BloqueDia> dias);
  Future<List<BloqueDia>> leerDias(CredencialesFamilia c, String desde);
  Future<void> subirRespaldo(CredencialesFamilia c, Uint8List bloque);
  /// `null` si el servidor responde `404 vacio`.
  Future<Uint8List?> leerRespaldo(CredencialesFamilia c);
  Future<void> borrarFamilia(CredencialesFamilia c);
  Future<void> enviarContadores({required String semana,
      required String version, required Map<String, String> c,
      required String integridad});
}
```

- `ClienteNubeHttp(Uri base, {HttpClient Function() crear = HttpClient.new, Duration tope = const Duration(seconds: 15)}) implements ClienteNube`.
- `transporte_http.dart`: `Future<({int estado, Uint8List cuerpo})> enviarHttp(HttpClient Function() crear, Uri url, String metodo, {String? auth, List<int>? cuerpo, String tipo = 'application/json', required Duration tope})`.

Reglas del transporte (todas obligatorias):

- Un `HttpClient` por llamada, `connectionTimeout = tope`, `idleTimeout = 5 s`, cerrado con `close(force: true)` en `finally`.
- Cabeceras: `authorization` si hay `auth`; si hay cuerpo, `content-type` (`application/json; charset=utf-8` o `application/octet-stream`), `content-length` y `x-amz-content-sha256: <sha256Hex(cuerpo)>`. `user-agent: BlueTalk` (sin versión ni modelo del teléfono).
- Toda la llamada (abrir, enviar y leer) va dentro de un solo `.timeout(tope)`.
- Respuesta de más de 307 200 bytes: se corta y da `ErrorNube(servidor)`.
- `SocketException`, `HandshakeException`, `HttpException`, `TlsException` y `TimeoutException` se convierten en `ErrorNube(red)`. Nada de esto se registra con `print` ni `debugPrint`.
- Estado fuera de 2xx: `ErrorNube(tipoDeEstado(estado))`, salvo `404` en `leerRespaldo`, que devuelve `null`.

Cuerpos exactos:

| Método | Petición | Respuesta que se lee |
|---|---|---|
| `activar` | `POST /v1/familia`, `{"fid":…,"wh":…,"compra":…,"integridad":…}` | `{"hasta":<int>}` con 200 o 201 |
| `subirDias` | `PUT /v1/dias`, `auth`, `{"dias":[{"d":"2026-11-26","b":"<base64 estándar>"}]}`; lanza `ArgumentError` si hay 0 o más de 7 días o algún bloque de más de 4 096 bytes (no se gasta cuota) | 204 |
| `leerDias` | `GET /v1/dias?desde=2026-09-27`, `auth` | `{"dias":[{"d","b"}]}`; ítems con `d` o `b` inválidos se descartan |
| `subirRespaldo` | `PUT /v1/respaldo`, `auth`, binario; `ArgumentError` si pasa de 262 144 bytes | 204 |
| `leerRespaldo` | `GET /v1/respaldo`, `auth` | binario, o `null` con 404 |
| `borrarFamilia` | `DELETE /v1/familia`, `auth`, sin cuerpo | 204 |
| `enviarContadores` | `POST /v1/contadores`, `{"semana":"2026-W48","version":"1.0.0","c":{"comunicar":"6-20"},"integridad":…}` | 204 |

- [ ] **Step 1:** `test/core/nube/servidor_falso.dart`: un `HttpServer.bind(InternetAddress.loopbackIPv4, 0)` que guarda la última petición (método, ruta, consulta, cabeceras y cuerpo) y responde con el estado y el cuerpo que la prueba programa. `cerrar()` en `tearDown`.
- [ ] **Step 2:** `test/core/nube/cliente_falso.dart`: `ClienteNubeFalso implements ClienteNube` en memoria, para los planes 3–6. Guarda `dias` por `fid` (sobrescribe por `d`), `respaldo` por `fid`, cuenta llamadas por método (`llamadas['subirDias']`), aplica 4 096 y 262 144 bytes y lanza `ErrorNube(fallo)` si la prueba asigna `fallo`. Con `borrarFamilia`, olvida el `fid`, y desde entonces sus llamadas con `BT1` lanzan `ErrorNube(token)`.
- [ ] **Step 3: pruebas que fallan** (`cliente_nube_http_test.dart`; solo `test()`, nunca `testWidgets`, y `setUpAll(() => HttpOverrides.global = null)` para usar sockets reales del bucle local):
  - `activar_envia_el_json_exacto_y_lee_hasta`: el cuerpo recibido decodifica a las 4 claves exactas; `x-amz-content-sha256` es igual a `sha256Hex` del cuerpo recibido; respuesta `201 {"hasta":1795737600}` → `1795737600`.
  - `subir_dias_envia_base64_estandar_y_autorizacion`: `authorization == 'BT1 <fid>.<wtok>'` (credenciales del Apéndice A) y `b` decodifica con `base64.decode` a los bytes enviados.
  - `ocho_dias_o_bloque_de_4097_no_salen`: `ArgumentError` y el servidor no recibe ninguna petición.
  - `leer_dias_descarta_items_rotos`: `{"dias":[{"d":"2026-11-26","b":"AQID"},{"d":"x","b":"AQID"},{"d":"2026-11-27"}]}` → una sola entrada.
  - `leer_respaldo_404_da_null`.
  - Un caso por estado: 400, 401, 402, 409, 413, 429, 500 y 503 lanzan `ErrorNube` con el tipo de `tipoDeEstado`.
  - `servidor_que_no_responde_da_red_en_el_tope`: el falso acepta y nunca contesta; con `tope: Duration(milliseconds: 300)`, lanza `ErrorNube(red)` en menos de 2 s.
  - `puerto_cerrado_da_red`: base `http://127.0.0.1:1` → `ErrorNube(red)`.
  - `respuesta_de_mas_de_300kb_da_servidor`.
  - `borrar_familia_no_envia_cuerpo_ni_sha`: `content-length` ausente o 0 y sin `x-amz-content-sha256`.
- [ ] **Step 4:** `timeout 300 flutter test test/core/nube/`. Esperado: FAIL.
- [ ] **Step 5:** implementar. `cliente_nube_http.dart` ≤100 líneas (la parte de sockets vive en `transporte_http.dart`).
- [ ] **Step 6:** `timeout 300 flutter test test/core/nube/` y `timeout 600 flutter analyze`. Esperado: PASS y 0 problemas.
- [ ] **Step 7:** commit `FEAT: cliente HTTP de la nube familiar sin dependencias`.

### Task 5: providers de la nube, regla de capas e `INTERNET` solo en `play`

**Files:**
- Create: `lib/core/nube/nube_providers.dart`, `android/app/src/play/AndroidManifest.xml`
- Modify: `test/arquitectura/capas_test.dart`, `test/arquitectura/manifiesto_test.dart`
- Test: `test/core/nube/nube_providers_test.dart`

**Interfaces:**
- Consumes: `ConfigNube` (Tarea 1), `CofreSeguro` (Tarea 2), `ClienteNubeHttp` (Tarea 4), `edicionDirectaProvider` (`lib/core/plataforma/edicion.dart`).
- Produces:

```dart
final configNubeProvider =
    Provider<ConfigNube>((ref) => const ConfigNube.deCompilacion());

/// `false` en `directa`, en las pruebas y mientras el dueño no configure la
/// API: entonces nadie enseña la suscripción ni llama a la red.
final nubeConfiguradaProvider = Provider<bool>((ref) =>
    !ref.watch(edicionDirectaProvider) && ref.watch(configNubeProvider).completa);

final clienteNubeProvider = Provider<ClienteNube>(
    (ref) => ClienteNubeHttp(Uri.parse(ref.watch(configNubeProvider).urlApi)));

final cofreClaveProvider = Provider<CofreClave>((ref) => CofreSeguro());
```

Manifiesto `play` (completo):

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Edición Play: la nube familiar (opcional y de pago) y la descarga de
         las voces naturales. Solo HTTPS a la API y al CDN de BlueTalk.
         Sin ACCESS_NETWORK_STATE: si no hay red, la llamada falla y se
         reintenta otro día (spec §10). -->
    <uses-permission android:name="android.permission.INTERNET"/>
</manifest>
```

Regla nueva en `capas_test.dart` (texto de la prueba exacto):

```dart
test('ninguna pantalla ni widget importa core/nube', () {
  final fuera = dartDe('lib/features')
      .where((f) {
        final t = f.readAsStringSync();
        final esUi = t.contains("package:flutter/material.dart") ||
            t.contains("package:flutter/widgets.dart");
        return esUi && t.contains('core/nube/');
      })
      .map((f) => f.path)
      .toList();
  expect(fuera, isEmpty,
      reason: 'La UI pide a un *_providers.dart o *_controller.dart.');
});
```

Cambio en `manifiesto_test.dart`, prueba `la edición Play no declara VPN, acceso al uso ni red`:
- Renombrarla a `la edición Play solo añade INTERNET`.
- Mantener intactas las aserciones sobre `main/AndroidManifest.xml` (sigue sin `INTERNET`) y sobre `directa`.
- Sustituir `expect(File('$raiz/play/AndroidManifest.xml').existsSync(), isFalse);` por: el manifiesto `play` existe; contiene `android.permission.INTERNET`; **no** contiene `ACCESS_NETWORK_STATE`, `BIND_VPN_SERVICE`, `PACKAGE_USAGE_STATS`, `FOREGROUND_SERVICE`, `AD_ID` ni `<service`; y tiene exactamente un `<uses-permission`.

- [ ] **Step 1: pruebas que fallan.**
  - `nube_providers_test.dart`:
    - Sin overrides, `nubeConfiguradaProvider` es `false`.
    - Con `configNubeProvider` completo y `edicionDirectaProvider` en `true`, sigue `false`.
    - Con `configNubeProvider` completo y `edicionDirectaProvider` en `false`, es `true`.
  - La regla nueva de `capas_test.dart`, comprobada en los dos sentidos: crear a mano un archivo temporal en `lib/features/` que importe `material.dart` y `core/nube/` hace fallar la prueba. Borrarlo antes de seguir; no se commitea.
  - `manifiesto_test.dart` modificado. Esperado: FAIL porque el manifiesto `play` aún no existe.
- [ ] **Step 2:** crear `nube_providers.dart` y el manifiesto `play`.
- [ ] **Step 3:** `timeout 600 flutter test test/arquitectura/ test/core/nube/`. Esperado: PASS.
- [ ] **Step 4:** compilar las dos ediciones, de una en una:
  - `timeout 1800 scripts/gradle-limite.sh assemblePlayDebug`
  - `timeout 1800 scripts/gradle-limite.sh assembleDirectaDebug`

  Esperado: las dos dan `BUILD SUCCESSFUL`.
- [ ] **Step 5:** manifiesto fusionado de `playRelease`:
  - `timeout 1800 scripts/gradle-limite.sh processPlayReleaseMainManifest`
  - `grep -o 'uses-permission[^>]*name="[^"]*"' android/app/build/intermediates/merged_manifest/playRelease/processPlayReleaseMainManifest/AndroidManifest.xml`

  Esperado: `INTERNET`, `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS` y las que añadan los plugins ya instalados (anotarlas en el informe). Ninguna `AD_ID`. La ruta exacta de `intermediates` depende de la versión de AGP: si no existe, buscarla con `find android/app/build -path '*playRelease*' -name AndroidManifest.xml` y anotarla.
- [ ] **Step 6:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: 0 problemas y todo verde.
- [ ] **Step 7:** escribir `docs/informes/plan2-nucleo-evidencia.md`: comandos, número de pruebas, permisos fusionados, y lo NO VERIFICADO (la interoperabilidad con el servidor real; el código que devuelve CloudFront con el corte).
- [ ] **Step 8:** commit `FEAT: providers de la nube e INTERNET solo en la edicion Play`.

## Depende del dueño

- Nada para cerrar este plan. Todo corre con el servidor falso local.
- Más adelante (Plan 7): los valores de `BLUETALK_NUBE_URL`, `BLUETALK_CDN_URL` y `BLUETALK_GCP_PROYECTO`, que existen cuando el dueño despliegue la API (Plan 1) y vincule Google Cloud con Play.

## Apéndice A: vector conocido (calculado con Python, HKDF de RFC 5869 y XChaCha20-Poly1305 con HChaCha20; la implementación de referencia reproduce el vector A.3.1 de `draft-irtf-cfrg-xchacha-03`)

```text
K          = 000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f
sal        = "bluetalk-familia-v1"
fid        = fu7wu6tv3pzmf6yuhhqlkatvtm
wtok       = TAseB0v7lXm94Ga1quD5h_dkA6yzOCDazG0UmXcyhWQ
wh         = 60fec683d5998a7c0c5b2e1f9e008fa5008c2487f2596f4b8ce25335db6ff8ef
kenc       = 8da99c3dfec9b74b235e686713922137d55a3a7eb92de70bbf1cc3f467208e41
código     = AAAQ-EAYE-AUDA-OCAJ-BIFQ-YDIO-B4IB-CEQT-CQKR-MFYY-DENB-WHA5-DYPW
requestHash activación  = sha256("fu7wu6tv3pzmf6yuhhqlkatvtm|60fec683…f8ef")
                        = 6d0514ab8d27b2518ed0d50e6c17529fe98d75d132cfbba72ae6ed474965cacb
requestHash contadores  = sha256("2026-W48|1.0.0")
                        = 5608795d8d31a3271e50080e365614a21e33db3fb1f9cc9f759cac5b93a5c377
nonce      = 000102…17 (24 bytes)
aad        = "fu7wu6tv3pzmf6yuhhqlkatvtm|dia|2026-11-26"
claro      = {"r":{"dia":"2026-11-26","p":3}}
bloque     = 01000102030405060708090a0b0c0d0e0f10111213141516177812807091c120e0b7a0779761943ec1a3815e29026e30be436e8213b20a5e84a2017fb48ed8cc1f556cd2fc2bf9444b
             (73 bytes: 1 versión + 24 nonce + 32 cifrado + 16 MAC)
```

El servidor (Plan 1, Tarea 2) puede usar `fid`, `wh` y el `requestHash` de activación en sus pruebas para comprobar que los dos lados calculan lo mismo.
