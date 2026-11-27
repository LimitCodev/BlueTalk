# Plan 4: sincronización (subir días, teléfono lector por QR, copia de seguridad, restaurar y borrar)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:**
- El teléfono del niño sube cifrados los últimos 7 días una vez al día, al abrir la app, y una copia de seguridad a la semana.
- El teléfono de otro adulto se vincula escaneando el QR o tecleando el código, y ve los mismos informes que el modo padre.
- Un teléfono nuevo restaura la copia con el código.
- El adulto puede borrar todo de la nube.

**Architecture:** la lógica que toca `lib/core/nube/` vive en archivos sin UI de `lib/features/padre/familia/`, todos terminados en `_nube.dart`, `_providers.dart` o `_controller.dart`. Las pantallas leen `familiaProvider` y providers de esa carpeta.

Piezas:
- **Subida:** un `FutureProvider` que `lib/app/app.dart` mantiene vivo, igual que `recordatoriosProvider`.
- **Informes del lector:** reutilizan `InformesScreen` y `construirInforme` tal cual. Se sobrescribe `informeProvider` en un `ProviderScope` anidado.
- **Escáner:** el de Google Play services (`play-services-code-scanner`), por un canal Kotlin del source set `play`. No pide permiso de cámara.

**Tech Stack:** Flutter, Riverpod 3.4 (`FamilyOverride.overrideWith((ref, arg) => …)`, comprobado en `riverpod-3.4.3/lib/src/core/family.dart`), `qr_flutter` (spec §11), Kotlin con `com.google.android.gms:play-services-code-scanner`, núcleo del Plan 2 y activación del Plan 3.

**Spec:** `docs/superpowers/specs/2026-11-26-suscripcion-familia-nube-design.md` (§1, §6, §7, §10 «Fin de la suscripción»). Contrato: Plan 1, copiado en el Plan 2.

**Serie:** Plan 1 → Plan 2 → Plan 3 → **Plan 4 (este)** → Plan 5 → Plan 6 → Plan 7.

**Depende de:**
- Plan 2: `sellarJson`, `abrirJson`, `aadDia`, `aadRespaldo`, `ClienteNube`, `ClienteNubeFalso`, `ClaveFamilia.codigo/qr/desdeCodigo`.
- Plan 3: `familiaProvider`, `EstadoFamilia`, `claveNubeActivada`, `claveNubeRol`, `FamiliaScreen`, `Funcion.seguimientoFamiliar` y `CanalesEdicion.kt` de `play` con `PlayChannel`.

**Lo necesitan:**
- Plan 6, que añade su registro diario junto a la sincronización.
- Plan 7, que redacta el texto legal y la hoja de Seguridad de los datos a partir de lo que se sube aquí.

## Global Constraints

- **Solo la edición `play`** recibe `INTERNET`, Integrity, Billing y el escáner (`playImplementation`). `directa` compila y sus pruebas siguen en verde. Ahí `nubeConfiguradaProvider` es `false` y nada de esto corre.
- Nada regresiona:
  - El menú `/inicio`, la guía de la mascota, los gráficos del adulto (`InformesScreen` no cambia), el modo calma, TalkBack y los objetivos de ≥48 dp.
  - **Ninguna voz automática.**
  - Los informes locales siguen igual y nunca se borran.
- Sin trabajos en segundo plano. Solo al abrir la app, con un intento al día como máximo; si falla, se reintenta al día siguiente y nunca en bucle (spec §7). *shortcut: añadir WorkManager si los informes llegan tarde.*
- La subida y la copia solo ocurren si se cumplen las cuatro condiciones:
  - la nube está configurada;
  - el rol es `nino`;
  - `bluetalk_nube_activada == true`;
  - `Funcion.seguimientoFamiliar` está disponible según Play.

  Un usuario gratis no llama a nada que cueste dinero.
- Qué sale del teléfono, y solo cifrado:
  - `ResumenDia` sin `apps`, que son las cuentas y los tiempos de `resumen_dia.dart`, nunca frases ni textos;
  - las caritas de ánimo (1–5) de cada día;
  - en la copia de seguridad, las claves del almacén de la lista blanca de la Tarea 5.

  Nada más. El PIN, sus huellas y la aceptación legal **nunca** salen.
- La clave `K` solo se enseña en la pantalla del código (tras el PIN), sin botón de copiar y sin compartir.
- `test/arquitectura/`: la UI no importa `lib/core/nube/`; solo `CanalNativo` crea `MethodChannel`; solo `lib/core/almacen/` toca `SharedPreferences`. Archivos nuevos ≤100 líneas; los de `_deuda` solo encogen.
- Dependencias nuevas: solo `qr_flutter` (Flutter) y `com.google.android.gms:play-services-code-scanner` (Gradle `play`).
- Pruebas: sin red. Se usan `ClienteNubeFalso`, `CofreMemoria`, un `EscanerFalso` y `relojProvider` fijo. Las pruebas que montan `BlueTalkApp` no deben dejar temporizadores pendientes: el retraso de la sincronización solo existe si la nube está configurada.
- Antes de cada commit: `timeout 600 flutter analyze` (0 problemas) y `timeout 1200 flutter test` (todo verde).
- Commits:
  - Formato `TIPO: descripción`, de 70 caracteres como máximo.
  - Rutas concretas en `git add`, sin `Co-Authored-By` y **sin push**.
  - Solo se hacen si el dueño los pidió; si no, la tarea termina en «listo para commit».
- Lo que no se compruebe se marca **NO VERIFICADO** en `docs/informes/plan4-sincronizacion-evidencia.md`.

Claves nuevas del almacén (no secretas):

| Clave | Tipo | Uso |
|---|---|---|
| `bluetalk_nube_intento` | `AAAA-MM-DD` | Último día en que se intentó subir. Se escribe **antes** de llamar a la red |
| `bluetalk_nube_subida` | `AAAA-MM-DD` | Último día con subida correcta |
| `bluetalk_nube_respaldo` | `AAAA-MM-DD` | Último día con copia correcta |
| `bluetalk_nube_vencida` | bool | El servidor respondió `402` al escribir |

## Review Focus

1. **Un intento al día, pase lo que pase.** Con la red caída, con `429` o con `5xx`, la segunda apertura del mismo día no llama a la API (Tarea 2).
2. **El AAD protege el día.** Un bloque devuelto por el servidor con `d` cambiado no se abre y cuenta como «roto», sin romper el informe (Tareas 1 y 4).
3. **La restauración no pisa el PIN ni la aceptación legal.** Tampoco la sobrescriben las colas en memoria al pasar la app a segundo plano (Tarea 5).
4. **Borrar la nube no borra nada del teléfono** salvo la clave y el estado de la nube, y deja libre el cupo de 3 niños del pago (Tarea 6).
5. **El lector no puede escribir.** Un teléfono con rol `lector` nunca llama a `subirDias`, `subirRespaldo` ni `borrarFamilia` (Tareas 2, 3 y 6).

---

### Task 1: bloque cifrado de un día (ida y vuelta)

**Files:**
- Create: `lib/features/padre/familia/dias_nube.dart`
- Test: `test/padre/familia/dias_nube_test.dart`

**Interfaces:**
- Consumes: `ResumenDia` (`lib/features/padre/informes/resumen_dia.dart`), `MoodEntry` (`lib/data/models/mood_entry.dart`), `claveDia` y `fechaDeClave` (`informes/dia.dart`), `sellarJson`, `abrirJson`, `aadDia`, `BloqueDia` y `CredencialesFamilia` (Plan 2).
- Produces:
  - `Map<String, Object?> contenidoDia(ResumenDia r, List<MoodEntry> animos, {int? maxPictos})`
  - `Future<BloqueDia?> sellarDia(CredencialesFamilia c, ResumenDia r, List<MoodEntry> animos)`
  - `List<ResumenDia> diasParaSubir(List<ResumenDia> conDatos, List<MoodEntry> animos, DateTime hoy)`: los días de `hoy − 6` a `hoy` que tengan resumen o al menos un ánimo. Un día que solo tiene ánimo sale con `ResumenDia(dia: clave)` vacío.
  - `Future<({List<ResumenDia> resumenes, List<MoodEntry> animos, int rotos})> abrirDias(CredencialesFamilia c, List<BloqueDia> bloques)`

Forma exacta del JSON de un día, antes de comprimir y cifrar:

```json
{"v":1,"r":{"dia":"2026-11-26","p":12,"c":{"comida":5},"u":{"agua":3},"sj":300,"nj":2,"cu":1,"di":0,"ah":["desayuno"]},"a":[4,5]}
```

- `r` es `ResumenDia.toMap()` **sin** la clave `ap`, aunque exista: el uso de otras apps solo lo tiene `directa` y no sale nunca.
- `a` son los `mood` (1–5) de los `MoodEntry` cuyo `claveDia(date)` es ese día, en orden.
- Al abrir, cada ánimo vuelve como `MoodEntry(id: 'nube-<dia>-<i>', date: DateTime(año, mes, día, 12), mood: m)`.
- Al abrir se descartan el bloque cuyo `r.dia` no coincide con `d`, los ánimos fuera de 1–5 y un `v` distinto de 1.

Tamaño:
- El bloque sellado debe medir 4 096 bytes como máximo.
- `sellarDia` lo prueba en este orden: completo; con `u` recortado a los 30 pictos más tocados (`maxPictos: 30`); sin `u` (`maxPictos: 0`).
- Si ni así cabe, devuelve `null`. *shortcut: un día que no cabe ni sin pictos no se sube; subir en dos bloques si ocurre en la práctica.*

- [ ] **Step 1: pruebas que fallan** (credenciales del Apéndice A del Plan 2):
  - Ida y vuelta: un `ResumenDia` con todos los campos y dos ánimos se abre igual, campo por campo, y con los dos `MoodEntry` a las 12:00 de ese día.
  - `contenidoDia` de un resumen con `apps` no contiene `ap`.
  - Un bloque de `2026-11-26`, devuelto como `(d: '2026-11-27', b: …)`, da `rotos == 1` y ningún resumen.
  - Un resumen con 2 000 pictos distintos en `u` produce un bloque ≤4 096 bytes con 30 pictos o sin `u`.
  - `diasParaSubir` con `hoy = 2026-11-26`, resúmenes del 18 y del 24 y un ánimo suelto del 25 da `[24, 25]`: el 18 queda fuera de los 7 días y el 25 sale vacío con su ánimo.
  - Un `abrirDias` con una lista vacía da listas vacías y `rotos == 0`.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/dias_nube_test.dart`. Esperado: FAIL.
- [ ] **Step 3:** implementar (≤100 líneas).
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 300 flutter test test/padre/`. Esperado: verde.
- [ ] **Step 5:** commit `FEAT: dias cifrados para la nube familiar`.

### Task 2: subida diaria al abrir la app y estado «vencida»

**Files:**
- Create: `lib/features/padre/familia/sincronizacion_providers.dart`
- Modify: `lib/app/app.dart` (2 líneas: el import y `ref.listen(sincronizacionProvider, (_, _) {});` junto al de `recordatoriosProvider`), `lib/features/padre/familia/familia_estado.dart` (estado `vencida`), `lib/features/padre/familia/familia_controller.dart`
- Test: `test/padre/familia/sincronizacion_test.dart`

**Interfaces:**
- Consumes: `diasParaSubir` y `sellarDia` (Tarea 1); `resumenesRepoProvider`, `wellbeingRepoProvider` y `almacenLocalProvider` (`lib/app/di.dart`); `relojProvider`; `planProvider`; `clienteNubeProvider`, `cofreClaveProvider` y `nubeConfiguradaProvider`.
- Produces:

```dart
enum ResultadoSync { noAplica, yaHecho, subido, sinDatos, vencida, error }

/// Espera antes de subir, para no competir con el primer frame.
final esperaSyncProvider =
    Provider<Duration>((ref) => const Duration(seconds: 10));

final sincronizacionProvider = FutureProvider<ResultadoSync>((ref) async { … });
```

Orden exacto dentro del provider:
1. Si la nube no está configurada, `noAplica`. Esta comprobación va **antes** de esperar, así que no crea ningún temporizador en las pruebas.
2. `await Future<void>.delayed(ref.read(esperaSyncProvider))`.
3. Si el rol no es `nino` o `bluetalk_nube_activada` no es `true`, `noAplica`.
4. `plan = await ref.read(planProvider.future)`. Si `seguimientoFamiliar` no está disponible en ese plan, `noAplica`.
5. Si `bluetalk_nube_intento == hoy`, `yaHecho`. Si no, se guarda `bluetalk_nube_intento = hoy` **antes** de usar la red.
6. Se lee `K` del cofre; si no hay, `noAplica`. Después, `derivar()`.
7. `await repo.flush()`. Los días son `diasParaSubir(repo.rango(hoy − 6, hoy), moods, hoy)`, sellados con `sellarDia` y sin los `null`.
8. Si no hay días, `sinDatos`. Si hay, se llama a `subirDias`.
9. Copia de seguridad: si `bluetalk_nube_respaldo` falta o es anterior a `hoy − 6`, `subirRespaldo` (Tarea 5) y se guarda el día.
10. Si todo fue bien: `bluetalk_nube_subida = hoy`, se borra `bluetalk_nube_vencida` y el resultado es `subido`.

Errores:
- `ErrorNube(suscripcion)`: `bluetalk_nube_vencida = true` y `vencida`.
- Cualquier otro `ErrorNube`: `error`. Se reintenta al día siguiente porque `intento` ya es `hoy`.
- Ninguna excepción sale del provider.

En el controlador, `build()` devuelve `vencida` si `activada && almacen.booleano('bluetalk_nube_vencida') == true`. Texto en `FamiliaScreen`:

> «La suscripción terminó. Durante 30 días puedes leer los informes y restaurar la copia. Las voces vuelven a ser las del teléfono. Los informes de este teléfono no se pierden.»

Botón: `Suscribirme de nuevo` (`suscribirse`).

- [ ] **Step 1: pruebas que fallan** (`ProviderContainer` con `esperaSyncProvider` en `Duration.zero`, `ClienteNubeFalso`, `CofreMemoria` con la clave del Apéndice A, `fuenteDerechosProvider` en `DerechosFijos(Plan.premium)` y reloj fijo `2026-11-26 10:00`):
  - Con todo activo y 3 días con datos: `subido`; `llamadas['subirDias'] == 1` con 3 bloques; `bluetalk_nube_subida == '2026-11-26'`.
  - **Una vez al día:** con `fallo = red`, el primer intento da `error` y el segundo, en un contenedor nuevo con el mismo almacén, da `yaHecho`, sin una segunda llamada.
  - Al día siguiente (reloj del 27), vuelve a intentar.
  - `fallo = suscripcion` da `vencida` y `bluetalk_nube_vencida == true`. Una subida correcta después la borra.
  - Plan `gratis`: `noAplica` y 0 llamadas. Rol `lector`: `noAplica` y 0 llamadas. Nube sin configurar: `noAplica`, sin esperar.
  - La copia: el primer día se sube; al día siguiente no; a los 7 días, sí.
  - Sin días con datos: `sinDatos` y ninguna llamada a `subirDias`.
  - La regresión de `test/widget_test.dart` y de las pruebas que montan `BlueTalkApp` sigue en verde: sin la nube configurada no hay temporizadores pendientes.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/`. Esperado: FAIL.
- [ ] **Step 3:** implementar. `app.dart` sigue en 100 líneas o menos.
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde.
- [ ] **Step 5:** commit `FEAT: subida diaria cifrada al abrir la app`.

### Task 3: código de familia, QR y vincular un teléfono lector

**Files:**
- Create:
  - `android/app/src/play/kotlin/com/limitcodev/bluetalk/EscanerChannel.kt`
  - `lib/features/padre/familia/escaner_gateway.dart`
  - `lib/features/padre/familia/codigo_familia_screen.dart`
  - `lib/features/padre/familia/vincular_dialogo.dart`
- Modify:
  - `pubspec.yaml` y `pubspec.lock` (`qr_flutter`)
  - `android/app/build.gradle.kts`
  - `android/app/src/play/kotlin/com/limitcodev/bluetalk/CanalesEdicion.kt`
  - `lib/features/padre/familia/familia_estado.dart`, `familia_controller.dart` y `familia_screen.dart`
- Test: `test/padre/familia/vincular_test.dart`, `test/padre/familia/codigo_familia_test.dart`

**Interfaces:**
- Produces:
  - Estados nuevos: `lector` (este teléfono lee los informes de otra familia) y `codigoMalo`.
  - `abstract interface class EscanerCodigos { Future<String?> escanear(); }`, más `EscanerPlay` (`const CanalNativo('bluetalk/escaner').pedir<String>('escanear')`) y `final escanerProvider = Provider<EscanerCodigos>((ref) => const EscanerPlay());`.
  - En `FamiliaController`:
    - `Future<String?> codigo()`: el código formateado, solo con rol `nino` y la nube activa.
    - `Future<String?> qr()`.
    - `Future<void> vincularLector(String texto)`.
    - `Future<void> desvincular()`.
  - `build()` devuelve `lector` si `bluetalk_nube_rol == 'lector'` y hay `K` en el cofre.

`vincularLector(texto)`, en este orden:
1. `k = await ClaveFamilia.desdeCodigo(texto)`. Si es `null`, `codigoMalo`.
2. `c = await k.derivar()` y después `await cliente.leerDias(c, claveDia(hoy − 1))`, que valida la clave contra el servidor:
   - `ErrorNube(token)` → `codigoMalo`;
   - `ErrorNube(suscripcion)` → `vencida`;
   - reintentable → `sinConexion`.
3. Si va bien: `cofre.guardar(k)`, `claveNubeRol = 'lector'` y `lector`. No escribe `claveNubeActivada`.

Si el teléfono ya es el del niño (`claveNubeActivada == true`), la opción no se enseña y el método no hace nada.

`EscanerChannel.kt` (completo):

```kotlin
package com.limitcodev.bluetalk

import android.app.Activity
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.codescanner.GmsBarcodeScannerOptions
import com.google.mlkit.vision.codescanner.GmsBarcodeScanning
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/** Escáner de Google Play services: la cámara la abre Play, sin permiso. */
class EscanerChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val canal = MethodChannel(messenger, "bluetalk/escaner")

    init {
        canal.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "escanear") return result.notImplemented()
        val opciones = GmsBarcodeScannerOptions.Builder()
            .setBarcodeFormats(Barcode.FORMAT_QR_CODE)
            .build()
        GmsBarcodeScanning.getClient(activity, opciones).startScan()
            .addOnSuccessListener { result.success(it.rawValue) }
            .addOnCanceledListener { result.success(null) }
            .addOnFailureListener { result.error("escaner", it.javaClass.simpleName, null) }
    }

    fun dispose() = canal.setMethodCallHandler(null)
}
```

Gradle: `"playImplementation"("com.google.android.gms:play-services-code-scanner:16.1.0")`. Es la última versión que conoce el planificador; comprobar la estable en Google Maven y anotarla (**NO VERIFICADO**).

Pantalla del código (`CodigoFamiliaScreen`, solo con rol `nino` y la nube activa):
- `AppBar`: `Código de la familia`.
- Aviso arriba, en `Card` con el color de aviso del tema: «Quien tenga este código ve los informes de tu hijo o hija. Enséñalo solo a adultos de confianza.»
- `QrImageView(data: qr, size: 240, backgroundColor: Colors.white, semanticsLabel: 'Código QR de la familia')`. El blanco fijo es la única excepción al tema, porque un QR necesita contraste para leerse. El modo calma lo deja en grises, lo que no afecta.
- El código en 4 líneas de 3 o 4 grupos, con `fontFamily: 'monospace'`, sin `SelectableText` y sin botón de copiar. `Semantics(label: 'Código de familia: <grupos separados por comas>')`.
- Debajo: «Escríbelo en papel y guárdalo junto al código de recuperación del PIN. Sin este código no se puede recuperar la copia de seguridad.»

Diálogo de vincular (`VincularDialogo`):
- Título: `Ver los informes de un niño`.
- Botón `Escanear el código QR`, que llama a `escanerProvider` y después a `vincularLector`.
- `TextField` con la etiqueta `O escribe el código de 52 letras y números`, más el botón `Vincular`.
- Mensajes: `codigoMalo` → «El código no es correcto. Revísalo letra por letra.»; `sinConexion` → «Sin conexión con la nube. Prueba más tarde.»

En `FamiliaScreen`:
- Con `activa`: un botón `Ver el código de la familia`.
- Con `sinSuscripcion`, `porActivar` o `sinConexion`, y sin activar: un botón `Soy otro adulto: ver los informes de un niño`.
- Con `lector`, el texto «Este teléfono ve los informes de otra familia.» y los botones `Ver los informes` (Tarea 4) y `Dejar de ver estos informes` (`desvincular`, que solo borra el cofre y `claveNubeRol`).

Si `familia_screen.dart` pasa de 100 líneas, los bloques por estado van a `lib/features/padre/familia/familia_acciones.dart`.

- [ ] **Step 1: pruebas que fallan.**
  - `vincular_test.dart` (controlador): con el código del Apéndice A y el falso devolviendo días, el estado es `lector`, el rol es `lector` y el cofre tiene la clave.
  - Con un código mal tecleado: `codigoMalo` y ninguna llamada a la API.
  - Con `fallo = token`: `codigoMalo`. Con `red`: `sinConexion`.
  - `desvincular` deja el cofre vacío y el estado `sinSuscripcion`.
  - `codigo_familia_test.dart` (widget):
    - se ve el aviso exacto, el QR (`find.byType(QrImageView)`) y los 13 grupos;
    - no hay `SelectableText` ni ningún botón con «Copiar»;
    - `problemasDeAccesibilidad` da una lista vacía.
  - Vincular con `EscanerFalso('BTF1:AAAQ…')` (el QR del Apéndice A) termina en `lector`. Si el escáner devuelve `null`, nada cambia.
- [ ] **Step 2:** `timeout 300 flutter pub add qr_flutter`. Después, `timeout 300 flutter test test/padre/familia/`. Esperado: FAIL.
- [ ] **Step 3:** implementar Kotlin, Gradle y Dart.
- [ ] **Step 4:** `timeout 1800 scripts/gradle-limite.sh assemblePlayDebug assembleDirectaDebug`. Esperado: `BUILD SUCCESSFUL`. Revisar el manifiesto fusionado de `playRelease`: si el escáner añade permisos (`CAMERA`, `ACCESS_NETWORK_STATE`…), anotarlos en el informe (lo revisa el Plan 7).
- [ ] **Step 5:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde.
- [ ] **Step 6:** commit `FEAT: codigo QR de la familia y telefono lector`.

### Task 4: informes en el teléfono lector

**Files:**
- Create: `lib/features/padre/familia/informes_remotos_providers.dart`, `lib/features/padre/familia/informes_familia_screen.dart`
- Modify: `lib/features/padre/informes/informes_providers.dart` (extraer `nombresDePictos`, sin cambiar el comportamiento)
- Test: `test/padre/familia/informes_familia_test.dart`

**Interfaces:**
- Consumes: `abrirDias` (Tarea 1), `informeProvider`, `construirInforme`, `InformesScreen` (`lib/features/padre/informes/`).
- Produces:
  - `Future<Map<String, String>> nombresDePictos(Ref ref)` en `informes_providers.dart`. Es el bloque que hoy arma `nombres` dentro de `informeProvider`; `informeProvider` pasa a llamarlo.
  - `final resumenesRemotosProvider = FutureProvider.autoDispose<({List<ResumenDia> resumenes, List<MoodEntry> animos, int rotos})>`. Lee la `K` del cofre, la deriva y hace `leerDias(c, claveDia(hoy − 61))`, que es 1 sola llamada (tope de 60 al día). Después, `abrirDias`.
  - `class InformesFamiliaScreen extends ConsumerWidget`:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) => ProviderScope(
      overrides: [
        informeProvider.overrideWith((ref, periodo) async {
          final r = await ref.watch(resumenesRemotosProvider.future);
          return construirInforme(
            periodo: periodo,
            hasta: ref.watch(relojProvider)(),
            resumenes: r.resumenes,
            animos: r.animos,
            nombres: await nombresDePictos(ref),
          );
        }),
      ],
      child: const InformesScreen(),
    );
```

- Si `resumenesRemotosProvider` falla con `ErrorNube`, `InformeVista` enseña su estado de error de siempre. Hay una excepción: `suscripcion` da el texto «La suscripción de esta familia terminó hace más de 30 días.»
- Si es necesario, añadir el parámetro opcional `aviso` a `InformesScreen` sin tocar su aspecto por defecto. Anotar la decisión en el informe.
- Límite conocido: los nombres salen del vocabulario de **este** teléfono. Un picto creado a mano en el teléfono del niño se ve con su `id`. *shortcut: subir el mapa de nombres propios en la copia si alguien lo echa de menos.*
- Uso de otras apps: el lector nunca lo tiene, porque `ap` no se sube. La sección de uso de apps ya se oculta sola en `play`.

- [ ] **Step 1: pruebas que fallan.**
  - Con el falso cargado con 10 días sellados (Tarea 1), `InformesFamiliaScreen` pinta la pestaña «Semanal» con los toques de esos días: buscar un número de la serie que solo salga de los datos remotos.
  - El `informeProvider` del contenedor raíz **no** cambia. Una prueba monta `InformesScreen` normal en el mismo árbol y sigue enseñando los datos locales.
  - Un bloque roto no rompe la pantalla.
  - `llamadas['leerDias'] == 1` aunque se cambie de pestaña dos veces.
  - Regresión: `test/padre/informes/` sigue en verde tras extraer `nombresDePictos`.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/ test/padre/informes/`. Esperado: FAIL.
- [ ] **Step 3:** implementar. Si el `ProviderScope` anidado no sobrescribe el provider en Riverpod 3.4.3, no se relaja nada: se añade a `InformesScreen` un parámetro opcional `Informe Function(Periodo)?`, se explica en el informe y se marca el cambio de método como decisión.
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde.
- [ ] **Step 5:** commit `FEAT: informes de la familia en el telefono lector`.

### Task 5: copia de seguridad cifrada y restaurar en un teléfono nuevo

**Files:**
- Modify: `lib/core/almacen/almacen_local.dart` (2 métodos), `test/padre/informes/resumenes_test.dart` (el doble `_AlmacenQueCuenta` implementa los 2 métodos nuevos)
- Create: `lib/features/padre/familia/respaldo_nube.dart`, `lib/features/padre/familia/restaurar_dialogo.dart`
- Modify: `lib/features/padre/familia/sincronizacion_providers.dart` (paso 9 de la Tarea 2), `familia_controller.dart`, `familia_estado.dart`, `familia_screen.dart` (o `familia_acciones.dart`)
- Test: `test/padre/familia/respaldo_test.dart`, `test/data/almacen_local_test.dart` (crearlo si no existe)

**Interfaces:**
- Produces, en `AlmacenLocal`, con su implementación en `AlmacenPrefs`:

```dart
/// Claves guardadas con esta puerta (copia de seguridad de la nube).
Set<String> claves();            // AlmacenPrefs: _prefs.getKeys()

/// Valor tal cual: String, bool, int o List<String>; `null` si no existe.
Object? valor(String clave);     // AlmacenPrefs: _prefs.get(clave)
```

- `respaldo_nube.dart`:
  - `bool entraEnRespaldo(String clave)`
  - `Future<Uint8List?> sellarRespaldo(CredencialesFamilia c, AlmacenLocal a)`: `null` si no cabe en 262 144 bytes ni quitando lo descartable.
  - `Future<int?> restaurarRespaldo(CredencialesFamilia c, AlmacenLocal a, List<int> bloque)`: el número de claves escritas, o `null` si no abre.
- Controlador:
  - `Future<void> guardarCopiaAhora()`: solo con rol `nino` y la nube activa. Gasta 1 de las 4 escrituras del día.
  - `Future<void> restaurar(String codigo)`.
  - Estados nuevos: `sinCopia` y `restaurada`.

Lista blanca (lo que entra en la copia). Una clave entra si cumple una de estas dos reglas:
- Empieza por `bluetalk_` y no empieza por `bluetalk_nube_`, `bluetalk_contadores_` ni `bluetalk_voces_`, y no es `bluetalk_prueba_keystore`.
- Es exactamente `padre_perfil_edad`, `padre_limite_juegos_min`, `padre_limite_juegos_previo`, `padre_bloqueo_juegos`, `padre_bloqueo_entorno` o `guia_vista`.

**Nunca entran:**
- `padre_pin_*` y `padre_recup_*` (huellas, sales, intentos y bloqueos);
- `padre_legal_aceptacion` (cada teléfono acepta por su cuenta);
- `padre_biometria`;
- `padre_filtro_web_*` (solo `directa`);
- `padre_limite_extension*` (el tiempo extra de un día).

Descartables, en este orden, si la copia no cabe: `bluetalk_usage` (eventos crudos; los informes salen de `bluetalk_resumen_*`, que sí entra) y después `bluetalk_artista_dibujos`.

Forma del JSON, antes de comprimir y cifrar con `aadRespaldo(fid)`:

```json
{"v":1,"c":{"bluetalk_profile":{"t":"s","v":"{…}"},"bluetalk_calm_mode":{"t":"b","v":true},"padre_limite_juegos_min":{"t":"i","v":30},"bluetalk_fav_pictos":{"t":"l","v":["agua"]}}}
```

Tipos: `s` texto, `b` bool, `i` entero y `l` lista de textos. Al restaurar se salta toda clave que no pase `entraEnRespaldo` o cuyo tipo no cuadre: el bloque está autenticado, pero se valida igual.

`restaurar(codigo)`, en este orden. La UI pide confirmación **antes** de llamar:
1. `desdeCodigo`. Si es `null`, `codigoMalo`. Después, `derivar()`.
2. `leerRespaldo(c)`:
   - `null` → `sinCopia`;
   - `ErrorNube(token)` → `codigoMalo`;
   - `suscripcion` → `vencida`;
   - reintentable → `sinConexion`.
3. `await ref.read(prefsUsageRepoProvider).flush()` y `await ref.read(resumenesRepoProvider).flush()`.
4. `restaurarRespaldo`. Si da `null`, `codigoMalo`.
5. `cofre.guardar(k)`, `claveNubeRol = 'nino'` y `claveNubeActivada = true`.
6. `ref.invalidate(prefsUsageRepoProvider)` y `ref.invalidate(resumenesRepoProvider)`. Así sus colas en memoria, con datos viejos, ya no se vuelcan al pasar a segundo plano.
7. Estado `restaurada`.

Textos:
- Confirmación: «Esto reemplaza el perfil, los ajustes, el horario, las frases y el historial de este teléfono por los de la copia. El código del modo padre de este teléfono no cambia.» Si el cofre ya tenía otra clave, se añade: «Este teléfono deja de usar su familia anterior.» Botones: `Cancelar` y `Restaurar`.
- `restaurada`: diálogo «Copia restaurada. BlueTalk se cerrará para cargarla. Vuelve a abrirla.» con el botón `Cerrar BlueTalk`, que llama a `SystemNavigator.pop()`.
- `sinCopia`: «Esa familia no tiene copia de seguridad guardada.»
- Botón de entrada, visible sin activar (`sinSuscripcion`, `porActivar` y `sinConexion`): `Restaurar una copia en este teléfono`.
- Con `activa`: `Guardar la copia ahora`. Al terminar: «Copia guardada.» o el mensaje del error.

- [ ] **Step 1: pruebas que fallan.**
  - `almacen_local_test.dart`: `AlmacenPrefs` sobre `SharedPreferences.setMockInitialValues({'a': 1, 'b': 'x'})` devuelve `claves() == {'a', 'b'}` y `valor('a') == 1`.
  - `respaldo_test.dart`:
    - `entraEnRespaldo`: un caso por cada clave de las dos listas.
    - Ida y vuelta: un almacén con 10 claves válidas y `padre_pin_hash`, `padre_legal_aceptacion` y `bluetalk_nube_rol` se restaura en un almacén vacío con exactamente las 10 válidas.
    - Una copia de más de 262 144 bytes por culpa de `bluetalk_usage` sale sin `bluetalk_usage`. Si ni así cabe, da `null`.
    - Restaurar sobre un almacén con `padre_pin_hash = 'X'` lo deja en `'X'`.
    - Un bloque sellado para otro `fid` da `null`.
  - Controlador:
    - `restaurar` con el código bueno termina en `restaurada`, con rol `nino`, activada y la clave en el cofre.
    - Con un 404 del falso, termina en `sinCopia`.
    - Los dos `flush` ocurren antes de escribir: los dobles de los repos lo registran.
  - Sincronización: el paso 9 llama a `subirRespaldo` con un bloque que `restaurarRespaldo` abre.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/ test/data/`. Esperado: FAIL.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde, con `test/arquitectura/` incluido (`almacen_local.dart` sigue siendo la única puerta a `SharedPreferences`).
- [ ] **Step 5:** humo en el emulador, con el servidor falso **NO**. Basta comprobar que `Cerrar BlueTalk` cierra la app y que, al volver a abrirla, `main()` vuelve a leer el almacén. Para esto se puede forzar el estado `restaurada` con un `--dart-define` temporal que no se commitea. Si al reabrir no se ve lo restaurado, anotarlo como **BLOQUEADO** y no seguir.
- [ ] **Step 6:** commit `FEAT: copia de seguridad cifrada y restaurar con el codigo`.

### Task 6: borrar la nube (derecho de supresión)

**Files:**
- Create: `lib/features/padre/familia/borrar_nube_dialogo.dart`
- Modify: `familia_controller.dart`, `familia_screen.dart` (o `familia_acciones.dart`)
- Test: `test/padre/familia/borrar_nube_test.dart`

**Interfaces:**
- Produces: `Future<void> borrarNube()`, solo con rol `nino`. Para el lector existe `desvincular` (Tarea 3).

`borrarNube()`, en orden:
1. Lee `K` y la deriva.
2. `await cliente.borrarFamilia(c)`. Un `ErrorNube(token)` cuenta como borrado: el servidor ya no tenía esa familia.
3. `cofre.borrar()` y `almacen.borrar` de `bluetalk_nube_activada`, `bluetalk_nube_rol`, `bluetalk_nube_intento`, `bluetalk_nube_subida`, `bluetalk_nube_respaldo`, `bluetalk_nube_vencida`, `bluetalk_nube_confirmada` y `bluetalk_nube_reintento`. Sin `K` en el cofre, el reintento al arrancar del Plan 3 ya no vuelve a activar solo.
4. El estado se recalcula con `build()`: si Play sigue cobrando, `porActivar`; si no, `sinSuscripcion`.

Con un error reintentable no se borra nada local y el estado es `sinConexion`. Nada de los informes ni del perfil del teléfono se toca.

Diálogo (`BorrarNubeDialogo`):
- Título: `Borrar todo de la nube`.
- Texto: «Se borran de la nube todos los días y la copia de seguridad de esta familia. Los datos de este teléfono no se tocan. Los otros teléfonos dejarán de ver los informes. La suscripción de Google Play sigue activa: si ya no la quieres, cancélala en Google Play.»
- Botones: `Cancelar` y `Borrar de la nube`, este con el color de error del tema.
- Entrada en `FamiliaScreen`, con `activa` o `vencida`: botón `Borrar todo de la nube`, con `OutlinedButton` y ≥48 dp.

- [ ] **Step 1: pruebas que fallan.**
  - Tras `borrarNube`: el falso ya no tiene el `fid`, el cofre está vacío, las 8 claves no existen y `bluetalk_resumen_*` sigue igual.
  - Con `fallo = red`: `sinConexion`, y el cofre y `bluetalk_nube_activada` siguen.
  - Con `fallo = token`: se borra igual lo local.
  - Widget: cancelar el diálogo no llama a nada; confirmar llama una vez.
  - `problemasDeAccesibilidad` del diálogo da una lista vacía.
  - El lector no ve el botón.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/`. Esperado: FAIL.
- [ ] **Step 3:** implementar.
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde.
- [ ] **Step 5:** `timeout 1800 scripts/gradle-limite.sh assemblePlayDebug assembleDirectaDebug`. Esperado: `BUILD SUCCESSFUL`.
- [ ] **Step 6:** escribir `docs/informes/plan4-sincronizacion-evidencia.md`. Quedan NO VERIFICADOS:
  - la prueba con dos teléfonos físicos (QR real);
  - la interoperabilidad con el servidor real;
  - el cierre y la reapertura tras restaurar en un teléfono físico.
- [ ] **Step 7:** commit `FEAT: borrar la nube familiar desde el modo padre`.

## Depende del dueño

- API desplegada (Plan 1) y `BLUETALK_NUBE_URL` para probar de punta a punta.
- Dos teléfonos físicos con Google Play services para probar el escáner, el lector y la restauración. Datos sintéticos: un apodo ficticio, nunca un niño real.
- Que la suscripción de prueba (Plan 3) esté activa en la cuenta de prueba con licencia.
