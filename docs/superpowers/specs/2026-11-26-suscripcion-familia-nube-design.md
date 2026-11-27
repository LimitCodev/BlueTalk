# Diseño: suscripción «Familia» con nube cifrada (A + B)

**Fecha:** 26-nov-2026 · **Estado:** aprobado por el dueño el 26-nov-2026
**Decisiones del dueño:** A + B (extras de voz + seguimiento familiar), opción 1 (sin cuentas, cifrado en el teléfono), tecnología moderna y configurada al detalle para costar casi nada y aguantar el abuso.

## 1. Intención

BlueTalk se publica con una suscripción mensual que paga servicios reales en AWS. Lo que se paga tiene que funcionar bien para la familia, y la factura de AWS no puede dispararse aunque alguien abuse.

**Qué recibe la familia suscrita:**

1. **Voces naturales:** un paquete de audio de Polly que se descarga una vez y suena sin red.
2. **Seguimiento familiar:** los informes del niño se ven en el teléfono del papá, la mamá o el terapeuta.
3. **Copia de seguridad:** al cambiar de teléfono se recuperan el perfil, los ajustes, el horario, las frases y el historial.

**Siempre gratis (regla de `lib/core/premium/plan.dart`):** comunicar, la voz del teléfono, las frases, las rutinas, los juegos, el modo calma y los informes locales.

## 2. Objetivos, no objetivos y antiobjetivos

**Objetivos**
- Menos de 0,01 USD de AWS por familia activa al mes.
- Un gasto máximo absoluto, con corte automático, aunque haya un ataque.
- AWS no puede leer nada del niño: todo va cifrado con una clave que solo tienen los teléfonos de la familia.
- Sin cuentas, sin correo y sin contraseñas.
- La app sigue funcionando sin red; la nube solo suma.

**No objetivos (fase 2 o nunca)**
- Panel web o de institución (opción C).
- Polly en vivo para frases nuevas: es caro y se presta al abuso.
- Sincronizar en tiempo real. Basta con una vez al día.
- La edición `directa`: queda igual, sin nube.

**Antiobjetivos (sería un fracaso aunque funcione)**
- Que comunicar o la voz básica queden detrás del pago.
- Que un usuario gratis pueda llamar a algo que cueste dinero.
- Que AWS guarde texto legible, IP o identificadores del dispositivo.
- Que se instale un SDK de analítica o de anuncios.

## 3. Restricciones

- **Política de Familias:** el público incluye menores de 13 años. La compra y la vinculación van detrás del PIN del adulto, y no se usan identificadores de publicidad.
- **Play Billing Library 8 o superior** (obligatoria desde el 31-ago-2026): `in_app_purchase` ≥ 3.3.
- **Seguridad de los datos:** lo cifrado de extremo a extremo no se declara (ayuda de Play Console, respuesta 10787469). Sí se declaran los contadores de investigación (D-1) y, probablemente, el token de compra (**NO VERIFICADO**: confirmar si cuenta como «historial de compras»).
- **Ley 29733 (Perú):** transferencia internacional de datos e inscripción del banco de datos. Revisarlo con un abogado (`solo-el-dueno-2026-11-26.md` §3).
- **Repo:** capas vigiladas por `test/arquitectura/`, archivos nuevos de 100 líneas como máximo, nada de dependencias sin permiso, `flutter analyze` en 0 y `flutter test` en verde antes de cada commit.
- **AWS real solo con el OK del dueño.** Las pruebas van por `aws-emu` con datos sintéticos.

## 4. Enfoques considerados

| Enfoque | A favor | En contra | Decisión |
|---|---|---|---|
| **1. Sin cuentas y cifrado en el teléfono** | Lo más barato y privado; sin contraseñas; lo cifrado no se declara en Play | Si se pierde la clave, se pierde la copia; sin panel web | **Elegido por el dueño** |
| 2. Cuentas de adulto (Cognito + DynamoDB legible) | Recuperación por correo; camino a instituciones | AWS lee datos de menores; más trabajo legal y más piezas | Descartado |
| Firebase o Supabase | Rápido de montar | El dueño pidió AWS; en apps de niños solo valen SDK certificados para Familias | Descartado |

## 5. Arquitectura

```text
Teléfono del niño (play)                       AWS us-east-1
 ├─ informes locales (ya existen)           ┌─ CloudFront, plan Free de tarifa plana
 ├─ cifra ResumenDia + respaldo ──HTTPS──▶  │   ├─ WAF: límite por IP y por tamaño
 ├─ Play Billing (compra tras PIN)          │   ├─ /v1/*      → Lambda URL (OAC)
 └─ Play Integrity (al activar)             │   └─ /voces/*   → S3 privado (OAC), paquete estático
                                            ├─ Lambda «bluetalk-api» (Rust, arm64, 128 MB)
Teléfono del adulto o terapeuta             │   └─ Google: Integrity + Android Publisher
 └─ escanea el QR (clave) → lee y descifra  ├─ DynamoDB, una tabla bajo demanda con tope y TTL
                                            ├─ SSM Parameter Store (credenciales de Google)
                                            └─ Budgets → SNS → Lambda «corte» (apaga la API)
```

**Por qué cada pieza (decisiones del agente):**

| Pieza | Elección | Motivo |
|---|---|---|
| Región | `us-east-1` | Lo más barato. CloudFront y WAF exigen esa región para sus certificados. La latencia da igual: la sincronización corre en segundo plano |
| Entrada | CloudFront con el plan Free de tarifa plana | 0 USD, 1 M de peticiones y 100 GB al mes, WAF incluido y **sin cobros por exceso**. Lo bloqueado por WAF no se cobra. Reemplaza a API Gateway |
| Cómputo | Una Lambda en **Rust** (`provided.al2023`, arm64, 128 MB) detrás de una Function URL protegida con OAC | Arranque en frío de unos 20 ms. Es la Lambda más barata posible, en un solo binario y con un solo arranque en frío para todas las rutas |
| Datos | **DynamoDB** bajo demanda, una sola tabla, con *maximum throughput* y TTL | Los bloques pesan 1–4 KB y caben en un ítem. Un `Query` trae un mes. El TTL borra gratis. El tope de capacidad limita el gasto |
| Voces | Paquete estático en `/voces/` de la distribución de `infra/aws/cdn.yaml` (S3 privado + OAC), sin URL firmada | La app solo lo descarga y reproduce si Play confirma la suscripción. Firmar URL exige una librería RSA más y no protege nada valioso: son audios de palabras sueltas. Un abuso de descargas no cuesta nada con el plan Free sin cobro por exceso. *shortcut: firmar URLs si aparecen paquetes de pago con contenido propio* |
| Secretos | SSM Parameter Store, `SecureString` estándar | Gratis; Secrets Manager cuesta 0,40 USD al mes por secreto |
| Infraestructura | SAM (`infra/aws/api.yaml`) | El repo ya usa CloudFormation, y en la máquina están `sam` y `sam-emu` |

**Coste estimado por familia activa al mes** (precios de lista; confirmarlos antes de desplegar):

- Unas 45 llamadas a Lambda: dentro del nivel gratuito de 1 M de peticiones al mes.
- DynamoDB: unas 40 escrituras más el almacenamiento, alrededor de 0,0002 USD.
- CloudFront, WAF y SSM: 0 USD.

Total: **menos de 0,001 USD**. La suscripción deja unos 9 USD netos por familia (CLP 10.500 menos el 15 % de Google; tipo de cambio **NO VERIFICADO**).

## 6. Criptografía (en el teléfono, con el paquete `cryptography` que ya está instalado)

- **Clave de familia `K`:** 32 bytes aleatorios generados en el teléfono del niño al activar. Se guarda en `flutter_secure_storage`. Nunca sale del teléfono, salvo por el QR o el código de familia.
- **Derivación con HKDF-SHA256 de `K`:**
  - `fid`: 16 bytes en base32, el identificador público de la familia.
  - `wtok`: 32 bytes, el token para escribir y leer. El servidor solo guarda su `SHA-256`.
  - `kenc`: 32 bytes, la clave de cifrado.
- **Cifrado de cada bloque:** primero se comprime (gzip de `dart:io`) y después se cifra con XChaCha20-Poly1305. El AAD es `fid|tipo|día`, así que un bloque no se puede mover a otro día ni a otra familia.
- **Vinculación del adulto:** el teléfono del niño, en el modo padre y tras el PIN, muestra un QR y un código de familia de 13 grupos de 4 caracteres, con el aviso «quien tenga este código ve los informes». El otro teléfono lo escanea con el **escáner de códigos de Google Play services**, que no pide permiso de cámara.
- **Recuperación:** se le pide a la familia que guarde el código de familia junto al código de recuperación del PIN. Sin el código no hay recuperación (aceptado por el dueño en la opción 1).

## 7. API (todas las rutas bajo `/v1`, cuerpo JSON y cifrado de bloques en base64)

Autenticación: `Authorization: BT1 <fid>.<wtok>`. El servidor compara `SHA-256(wtok)` en tiempo constante. CloudFront con OAC exige la cabecera `x-amz-content-sha256` en POST y PUT; la calcula el cliente.

| Ruta | Quién | Qué hace | Tope por familia |
|---|---|---|---|
| `POST /familia` | Teléfono del niño, una vez | Recibe `fid`, `sha256(wtok)`, `purchaseToken` e `integrityToken`. Verifica Integrity y la suscripción con `subscriptionsv2.get`, la **reconoce** (*acknowledge*) y guarda la familia. Un token de compra se liga a **3 `fid` como máximo** (hasta 3 niños por pago, decisión del dueño); el cuarto recibe `409` | 3 al día por IP (WAF) |
| `PUT /dias` | Teléfono del niño | Hasta 7 días por llamada, 4 KB por día | 10 llamadas al día |
| `GET /dias?desde=AAAA-MM-DD` | Cualquier teléfono vinculado | `Query` de 62 ítems como máximo | 60 al día |
| `PUT /respaldo` · `GET /respaldo` | Teléfono del niño o uno nuevo | Una sola copia que se sobrescribe; 256 KB como máximo | 4 escrituras y 10 lecturas al día |
| `DELETE /familia` | Adulto, tras el PIN | Borra todo lo de ese `fid` (derecho de supresión) | — |
| `POST /contadores` | Cualquier instalación con permiso del adulto | Ver §9. Sin `fid` y con `integrityToken` | 1 a la semana (en el cliente) y límite de WAF |

**Suscripción en el servidor:** la familia guarda `vigenteHasta = min(fin del periodo, ahora + 24 h)`. Al vencer, la siguiente llamada vuelve a consultar a Google. Así un reembolso o una cancelación se notan en menos de 24 horas sin pagar Pub/Sub ni notificaciones en tiempo real. *shortcut: si la latencia de 24 h llega a importar, se añaden las RTDN de Play.*

**Cuotas:** un solo `UpdateItem` condicional sobre el contador del día (`ADD n :1` con la condición `n < tope`). Sin lecturas extra.

**Errores:**

| Código | Significado |
|---|---|
| `401` | Token malo |
| `402` | Sin suscripción vigente |
| `413` | Bloque demasiado grande |
| `429` | Cuota agotada |
| `503` | Corte activado |

El cliente reintenta al día siguiente y nunca en bucle.

## 8. Defensa contra el abuso y contra la factura (capas, de fuera hacia dentro)

1. **CloudFront Free:** no hay cobro por exceso. Pasado el cupo se degrada el servicio, pero no se cobra.
2. **WAF** (5 reglas en el plan Free):
   - Límite por IP: 300 peticiones cada 5 minutos. Alcanza para un colegio detrás de una sola IP.
   - Cuerpo de más de 300 KB: se bloquea.
   - Solo los métodos y rutas conocidos.
   - Reglas administradas básicas.
3. **OAC:** la Lambda solo acepta llamadas que pasen por CloudFront. La Function URL directa responde 403.
4. **Lambda:**
   - Rechaza cuerpos de más de 300 KB antes de leerlos.
   - Concurrencia reservada de 10. Las cuentas nuevas pueden tener un límite total de 10, así que hay que pedir el aumento (`solo-el-dueno`).
   - Timeout de 5 s.
5. **Integrity:** solo al activar y en los contadores. Con 10.000 verificaciones al día sobra. Si se agota la cuota, los contadores se descartan y la activación pide reintentar.
6. **Cuotas por familia** en DynamoDB (§7). Un token de compra cubre 3 niños como máximo.
7. **DynamoDB:** *maximum throughput* de 50 RRU y 50 WRU. Es el techo de gasto duro de la tabla.
8. **Logs:** retención de 3 días, nivel `warn`, sin cuerpos, IP ni cabeceras.
9. **Budgets:**
   - Alarma a 3 USD reales y a 5 USD previstos.
   - A 10 USD, SNS dispara la Lambda «corte», que pone la concurrencia de la API en 0 (`503`). Se reactiva a mano.

## 9. Contadores de investigación (D-1)

- **Desactivados por defecto.** El adulto los activa tras el PIN y puede apagarlos cuando quiera.
- **Envío:** una vez por semana. Cada función (comunicar, juegos, rutinas, calma…) se manda en tramos (`0`, `1–5`, `6–20`, `21+`), junto con la versión de la app. Sin `fid`, sin fecha exacta y sin país.
- **En el servidor:** solo se suma al agregado `C#<año-semana>`. Nunca se guarda una fila por usuario.
- **En Seguridad de los datos:** «Actividad en la app → Interacciones», fin «Analítica», opcional, cifrado en tránsito. No se puede borrar porque es anónimo; se explica en la política.

## 10. Cambios en la app (solo en la edición `play`)

| Área | Cambio |
|---|---|
| Manifiesto `play` | Añadir `INTERNET` (sin `ACCESS_NETWORK_STATE`, salvo que haga falta) |
| `lib/core/nube/` (nuevo) | Cliente HTTP con `dart:io` (sin dependencia), clave de familia y cifrado. Interfaz falsa para las pruebas |
| `lib/core/premium/` | `DerechosPlayBilling`, `TiendaPlay` y nueva `Funcion.seguimientoFamiliar`. Se sustituyen en `lib/app/di.dart` |
| Kotlin `play` | Canales `Integrity` y `EscanerCodigos`. `MediaPlayer` para el MP3, con `CanalNativo` |
| `lib/features/padre/familia/` (nuevo) | Suscribirse, mostrar el QR o código, vincular este teléfono como lector, restaurar, contadores y borrar la nube |
| Informes | Fuente remota de `ResumenDia` para el teléfono lector, reutilizando `construir_informe.dart` |
| Sincronización | Al abrir la app, si hay red y el último envío es de antes de hoy. Sin trabajos en segundo plano. *shortcut: añadir WorkManager si los informes llegan tarde* |
| Voz | Con `Funcion.vocesNaturales` y el paquete descargado suena el MP3; si no, `flutter_tts` como hoy |
| Legal | `PRIVACIDAD.md`, `TERMINOS_Y_CONDICIONES.md`, `textos_legales.dart` (`versionLegal` 1.4.0) y la web publicada, todo a la vez |
| Versión | `1.0.0+1` (D-3) |

**Fin de la suscripción (decisión del agente):**
- Deja de subir.
- Durante 30 días se pueden leer y restaurar los datos.
- La voz vuelve a ser la del teléfono.
- Todo se borra a los 90 días por TTL.
- Los informes locales del teléfono nunca se pierden.

## 11. Dependencias nuevas (aprobadas por el dueño el 26-nov-2026)

- **Flutter:** `in_app_purchase` (≥ 3.3, Billing 8) y `qr_flutter`, que dibuja el QR en Dart puro.
- **Gradle `play`:** `com.google.android.play:integrity` y `com.google.android.gms:play-services-code-scanner`.
- **Rust:** `lambda_http`, `aws-sdk-dynamodb`, `aws-sdk-ssm`, `aws-sdk-lambda` (para el corte), `serde`, `jsonwebtoken` (JWT de la cuenta de servicio de Google), `reqwest` con `rustls` y `sha2`.
- **Herramienta:** `cargo-lambda`, para compilar arm64.

## 11 bis. Producto en Play (decisión del dueño)

- Suscripción mensual con **7 días de prueba gratis**. Google limita la prueba a una por cuenta.
- El precio y los países los fija el dueño. El pitch dice CLP 10.500.

## 12. Pruebas

- **Rust:** pruebas unitarias con dobles de Google y DynamoDB que cubren cuotas, `402`, `413`, la ligadura token↔`fid` y el corte. Las de integración van con `sam-emu` y `aws-emu medir --esperadas` (skill `probar-aws`).
- **Dart:** vectores de cifrado con ida y vuelta, AAD cambiado que falla y `fid` determinista. Cliente con servidor falso. Arquitectura: ninguna pantalla usa `lib/core/nube` directamente.
- **Play:** prueba interna con la licencia de prueba de Play (compras sin cobro) antes de la prueba cerrada.
- **Carga:** un script que golpea 1.000 peticiones y confirma el `429` y que WAF bloquea, con el gasto medido después.

## 13. Lo que queda al constructor

- Nombres de archivos y de proveedores, siguiendo las convenciones del repo.
- El formato exacto del código de familia (base32 con separadores).
- La pantalla de suscripción: debe seguir el tema, el modo calma y TalkBack.

## 14. Lo que solo puede hacer el dueño

Cuenta de AWS con MFA, aumento de la concurrencia de Lambda, proyecto de Google Cloud vinculado a Play con su cuenta de servicio, perfil de pagos, producto de suscripción y precio, revisión legal, keystore y OK para desplegar. Detalle en `docs/informes/solo-el-dueno-2026-11-26.md`.
