# Plan 3: pago y verificación (Play Billing, Integrity, pantalla tras el PIN y prueba de 7 días)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** el adulto, dentro del modo padre (tras el PIN), ve «Suscripción Familia», paga con Google Play (con la prueba de 7 días si Play se la ofrece) y el teléfono del niño queda activado en la nube con `POST /v1/familia` y un token de Play Integrity recién pedido. Sin nube configurada, nada de esto aparece.

**Architecture:** `TiendaPlay` (sobre `in_app_purchase`) implementa el `TiendaCompras` que ya existe; `DerechosPlayBilling` implementa `FuenteDerechos`; los dos se eligen en `lib/core/premium/premium_providers.dart` solo si `nubeConfiguradaProvider` es `true`. Integrity va por un canal Kotlin del source set `play` (`PlayChannel.kt`) y por `CanalNativo`. La activación vive en `lib/features/padre/familia/familia_controller.dart`; las pantallas solo leen ese controlador.

**Tech Stack:** Flutter, Riverpod 3.4, `in_app_purchase` (≥ 3.3, Play Billing Library ≥ 8), Kotlin con `com.google.android.play:integrity` (API estándar: `StandardIntegrityManager`), núcleo de nube del Plan 2.

**Spec:** `docs/superpowers/specs/2026-11-26-suscripcion-familia-nube-design.md` (§3, §6, §7, §10, §11 y §11 bis). Contrato: Plan 1 («Contrato de la API»), copiado en el Plan 2.

**Serie:** Plan 1 → Plan 2 → **Plan 3 (este)** → Plan 4 → Plan 5 → Plan 6 → Plan 7.

**Depende de:** Plan 2 completo (`ConfigNube`, `ClaveFamilia`, `CofreClave`, `ClienteNube`, `ClienteNubeFalso`, `nubeConfiguradaProvider`, `sha256Hex`). **Lo necesitan:** Plan 4 (estado `activa` y rol `nino`), Plan 5 (`Funcion.vocesNaturales` con Billing real) y Plan 6 (`Integridad`).

## Global Constraints

- **Solo la edición `play`** recibe `INTERNET`, Integrity y Billing. `in_app_purchase` es un plugin de Flutter y se compila en las dos ediciones (Flutter no separa plugins por sabor): en `directa` se **quita** el permiso `com.android.vending.BILLING` del manifiesto fusionado y el código Dart nunca usa `TiendaPlay` (`nubeConfiguradaProvider` es `false`). Integrity va con `playImplementation`, así que no llega a `directa`. `directa` sigue compilando y con sus pruebas en verde.
- Nada regresiona: menú `/inicio`, guía de la mascota, gráficos del adulto, modo calma, TalkBack, ≥48 dp y **ninguna voz automática**. **Comunicar nunca es premium**: `Funcion` solo gana `seguimientoFamiliar`.
- Política de Familias: la compra y la activación solo existen dentro del modo padre, después del PIN. Ningún botón de compra en zonas del niño (`/inicio`, `/home/*`, Ajustes).
- `test/arquitectura/`: ningún archivo de UI importa `lib/core/nube/`; solo `CanalNativo` crea `MethodChannel` en Dart; solo `lib/core/almacen/` toca `SharedPreferences`. Archivos nuevos ≤100 líneas; los de `_deuda` solo encogen (al partir uno, se baja su número).
- Dependencias nuevas, solo las de spec §11: `in_app_purchase` (Flutter) y `com.google.android.play:integrity` (Gradle `play`). Nada más (ni `in_app_purchase_android` directo, ni `url_launcher`).
- Pruebas sin Google real: `InAppPurchase` se sustituye por un doble que se pasa al constructor de `TiendaPlay`; Integrity, por `IntegridadFalsa`; la API, por `ClienteNubeFalso` (Plan 2).
- **El token de Integrity se pide justo antes de cada activación y nunca se guarda ni se reutiliza.** `requestHash = sha256Hex(utf8.encode('<fid>|<wh>'))` (el servidor rechaza veredictos de más de 5 minutos).
- **Reconocimiento de la compra (Google reembolsa solo toda compra sin reconocer a los 3 días).**
  - **Dueño único del reconocimiento: el servidor.** Dentro de `POST /v1/familia` llama a `purchases.subscriptions…:acknowledge` de Android Publisher si `subscriptionsv2.get` dice que no está reconocida. Ya está en la spec §6, en el Plan 1 (Tarea 3, `compra_ya_reconocida_no_se_reconoce_otra_vez`) y en `infra/aws/api/src/familia.rs`.
  - Motivo: el servidor es quien da el servicio. Solo reconoce cuando la familia quedó dada de alta, y lo hace con la API autoritativa, que no depende de que la app siga abierta. Un fallo de `reconocer` responde `500`, y la app reintenta la activación (`200`, misma familia), así que el servidor vuelve a reconocer.
  - La app llama a `InAppPurchase.completePurchase` **solo después** de un `200` o `201` de `POST /v1/familia`. Solo cierra la transacción local de Play (para que `purchaseStream` no la vuelva a entregar) y no sustituye al servidor.
  - Si la activación o `completePurchase` fallan, se reintentan solas en el siguiente arranque de la app (como mucho una vez al día, por el tope de 3 altas al día por IP del WAF) y al tocar el botón (Tarea 4).
  - Consecuencia aceptada: si el teléfono no logra activarse en 3 días (sin red, Integrity rechaza la app instalada por fuera de Play…), Google devuelve el dinero solo. La pantalla lo dice (Tarea 5).
- Antes de cada commit: `timeout 600 flutter analyze` (0 problemas) y `timeout 1200 flutter test` (todo verde).
- Commits `TIPO: descripción`, ≤70 caracteres, rutas concretas, sin `Co-Authored-By`, **sin push**. Solo si el dueño pidió commits en esa sesión; si no, «listo para commit».
- Lo no comprobado va como **NO VERIFICADO** en `docs/informes/plan3-pago-evidencia.md`.

## Review Focus

1. **Doble cobro, compra sin activar o reembolso automático.** Tras pagar, si la red falla, la pantalla ofrece «Terminar la activación» y reutiliza la misma `K` (la `K` se guarda en el cofre **antes** de llamar al servidor). Repetir da `200`, no una familia nueva. `completePurchase` nunca se llama antes de un `200` o `201`, y una compra sin cerrar se reintenta en el siguiente arranque (Tarea 4).
2. **Token de Integrity fresco.** Cada intento de activación llama una vez a `Integridad.token` con el `requestHash` de ese `fid` y ese `wh` (Tarea 4).
3. **`directa` y nube sin configurar.** No aparece nada de la suscripción, `TiendaPlay` no se construye y el manifiesto fusionado de `directa` no tiene `BILLING` (Tareas 1 y 3).
4. **El plan nunca se regala.** Si Play no contesta en 5 s, o falla, el plan es `gratis` (Tarea 3).
5. **Pantalla accesible.** Todos los botones ≥48 dp con etiqueta; en modo calma, sin indicadores animados; textos literales (Tarea 5).

---

### Task 1: dependencias de pago e Integrity, y `BILLING` fuera de `directa`

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`, `android/app/build.gradle.kts`, `android/app/src/directa/AndroidManifest.xml`, `test/arquitectura/manifiesto_test.dart`

- [ ] **Step 1:** `timeout 300 flutter pub add in_app_purchase`. Comprobar en `pubspec.lock` que la versión resuelta es ≥ 3.3.0, y que la Billing Library que trae es ≥ 8.0.0:

  ```bash
  grep -rn "billingclient:billing" ~/.pub-cache/hosted/pub.dev/in_app_purchase_android-*/android/build.gradle*
  ```

  Si es menor que 8, **parar**: escribir `BLOQUEADO | plan3 tarea1 | Billing < 8` en `docs/informes/decisiones-pendientes.md` (Play exige Billing 8 desde el 31-ago-2026).
- [ ] **Step 2:** en `android/app/build.gradle.kts`, dentro de `dependencies { … }`:

  ```kotlin
  // Solo Play (spec §11): verificación del dispositivo al activar la nube.
  "playImplementation"("com.google.android.play:integrity:1.4.0")
  ```

  `1.4.0` es la última versión que conoce el planificador. Antes de fijarla, mirar la última estable en Google Maven y anotar la elegida en el informe (**NO VERIFICADO** a 27-nov-2026).
- [ ] **Step 3:** en `android/app/src/directa/AndroidManifest.xml`, junto a los demás `uses-permission`:

  ```xml
  <!-- in_app_purchase se compila en las dos ediciones (plugin de Flutter);
       el APK directo no vende nada, así que no declara el permiso. -->
  <uses-permission
      android:name="com.android.vending.BILLING"
      tools:node="remove"/>
  ```
- [ ] **Step 4: prueba que falla.** En `manifiesto_test.dart`, prueba nueva `directa quita el permiso de Billing`: el manifiesto `directa` contiene `com.android.vending.BILLING` y `tools:node="remove"` en la misma etiqueta. Hacer que falle primero con el paso 3 deshecho, y que pase después.
- [ ] **Step 5:** compilar y revisar los permisos fusionados, de una edición en una:
  - `timeout 1800 scripts/gradle-limite.sh processPlayReleaseMainManifest processDirectaReleaseMainManifest`
  - `grep -c 'com.android.vending.BILLING'` en el manifiesto fusionado de cada edición (buscarlo con `find android/app/build -path '*Release*' -name AndroidManifest.xml -path '*merged_manifest*'`).

  Esperado: `play` 1 y `directa` 0. Anotar los dos listados de permisos en el informe.
- [ ] **Step 6:** `timeout 1800 scripts/gradle-limite.sh assembleDirectaDebug`. Esperado: `BUILD SUCCESSFUL`.
- [ ] **Step 7:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: 0 problemas y todo verde.
- [ ] **Step 8:** commit `CHORE: in_app_purchase e Integrity solo para la edicion Play`.

### Task 2: canal `bluetalk/play` (Integrity y gestionar la suscripción)

**Files:**
- Create: `android/app/src/play/kotlin/com/limitcodev/bluetalk/PlayChannel.kt`, `lib/core/nube/integridad.dart`
- Modify: `android/app/src/play/kotlin/com/limitcodev/bluetalk/CanalesEdicion.kt`, `lib/core/nube/nube_providers.dart`
- Test: `test/core/nube/integridad_test.dart`

**Interfaces:**
- Produces (Dart):

```dart
/// Token de Play Integrity (API estándar) para [hashHex], o `null` si
/// Play no lo da (sin Play, sin red, app instalada por fuera de Play...).
abstract interface class Integridad {
  Future<String?> token(String hashHex);
}

class IntegridadPlay implements Integridad {
  const IntegridadPlay(this._proyecto,
      [this._canal = const CanalNativo('bluetalk/play')]);
  final int _proyecto;
  final CanalNativo _canal;

  @override
  Future<String?> token(String hashHex) => _canal
      .pedir<String>('integridad', {'proyecto': _proyecto, 'hash': hashHex});
}

class IntegridadFalsa implements Integridad {
  IntegridadFalsa([this.respuesta = 'token-falso']);
  String? respuesta;
  final hashes = <String>[];
  @override
  Future<String?> token(String hashHex) async {
    hashes.add(hashHex);
    return respuesta;
  }
}
```

- `integridadProvider = Provider<Integridad>((ref) => IntegridadPlay(ref.watch(configNubeProvider).proyectoGoogle));` en `nube_providers.dart`.
- Produces (Kotlin): canal `bluetalk/play` con dos métodos:
  - `integridad({proyecto: Long, hash: String}) -> String`
  - `abrirSuscripciones() -> Boolean`: abre `https://play.google.com/store/account/subscriptions?sku=bluetalk_familia&package=com.limitcodev.bluetalk`.

`PlayChannel.kt` (completo; sigue el estilo de `UsoTelefonoChannel.kt`):

```kotlin
package com.limitcodev.bluetalk

import android.app.Activity
import android.content.Intent
import android.net.Uri
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager.PrepareIntegrityTokenRequest
import com.google.android.play.core.integrity.StandardIntegrityManager.StandardIntegrityTokenRequest
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Edición Play: Play Integrity (API estándar) al activar la nube familiar y
 * enlace a «Suscripciones» de Google Play. El token se pide en el momento
 * y no se guarda: el servidor rechaza veredictos de más de 5 minutos.
 */
class PlayChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val canal = MethodChannel(messenger, "bluetalk/play")
    private val integridad =
        IntegrityManagerFactory.createStandard(activity.applicationContext)

    init {
        canal.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "integridad" -> pedirToken(call, result)
            "abrirSuscripciones" -> result.success(abrirSuscripciones())
            else -> result.notImplemented()
        }
    }

    private fun pedirToken(call: MethodCall, result: MethodChannel.Result) {
        val proyecto = call.argument<Number>("proyecto")?.toLong()
        val hash = call.argument<String>("hash")
        if (proyecto == null || hash == null) {
            result.error("argumentos", null, null)
            return
        }
        val preparar = PrepareIntegrityTokenRequest.builder()
            .setCloudProjectNumber(proyecto)
            .build()
        integridad.prepareIntegrityToken(preparar)
            .addOnSuccessListener { proveedor ->
                val pedido = StandardIntegrityTokenRequest.builder()
                    .setRequestHash(hash)
                    .build()
                proveedor.request(pedido)
                    .addOnSuccessListener { result.success(it.token()) }
                    .addOnFailureListener { result.error("integridad", it.javaClass.simpleName, null) }
            }
            .addOnFailureListener { result.error("integridad", it.javaClass.simpleName, null) }
    }

    private fun abrirSuscripciones(): Boolean = try {
        val url = "https://play.google.com/store/account/subscriptions" +
            "?sku=bluetalk_familia&package=com.limitcodev.bluetalk"
        activity.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)))
        true
    } catch (e: android.content.ActivityNotFoundException) {
        false
    }

    fun dispose() = canal.setMethodCallHandler(null)
}
```

`CanalesEdicion.kt` (`play`) pasa a crear `PlayChannel(activity, messenger)` y a llamar a su `dispose()`. Se quita el `@Suppress("UNUSED_PARAMETER")`, que ya no aplica.

- [ ] **Step 1: pruebas que fallan** (`integridad_test.dart`, con el patrón de `test/core/canal_nativo_test.dart`):
  - `IntegridadPlay(123).token('ab')` envía `integridad` con `{'proyecto': 123, 'hash': 'ab'}` y devuelve lo que responde el canal.
  - Sin canal (`MissingPluginException`) da `null`; un `PlatformException` da `null`.
- [ ] **Step 2:** `timeout 300 flutter test test/core/nube/integridad_test.dart`. Esperado: FAIL.
- [ ] **Step 3:** implementar Dart y Kotlin.
- [ ] **Step 4:** `timeout 1800 scripts/gradle-limite.sh assemblePlayDebug assembleDirectaDebug`. Esperado: `BUILD SUCCESSFUL`. Si cambian los nombres de clase de Integrity en la versión elegida, adaptarlos y anotarlo.
- [ ] **Step 5:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde.
- [ ] **Step 6:** commit `FEAT: canal Play con Integrity estandar y enlace a suscripciones`.

### Task 3: `TiendaPlay`, `DerechosPlayBilling` y `Funcion.seguimientoFamiliar`

**Files:**
- Create: `lib/core/premium/tienda_play.dart`, `lib/core/premium/derechos_play.dart`
- Modify: `lib/core/premium/tienda.dart`, `lib/core/premium/plan.dart`, `lib/core/premium/premium_providers.dart`
- Test: `test/core/premium_test.dart` (ampliar), `test/core/tienda_play_test.dart`

**Interfaces:**
- Consumes: `ConfigNube.producto` y `nubeConfiguradaProvider` (Plan 2), `CanalNativo('bluetalk/play')` (Tarea 2).
- Produces:
  - En `plan.dart`, entrada nueva (después de `paquetesVocabulario`):

    ```dart
    /// Informes en el teléfono de otro adulto y copia de seguridad cifrada
    /// (nube familiar, solo edición Play). Los informes locales son gratis.
    seguimientoFamiliar(Plan.premium);
    ```
  - En `tienda.dart`, el contrato crece (y `TiendaNoDisponible` lo cumple con `null`, `false` o nada):

    ```dart
    /// Compra activa en Play: lo que el servidor necesita para verificarla.
    typedef CompraVigente = ({String producto, String token});

    /// Precio que enseña Play y si ofrece la prueba gratis a esta cuenta.
    typedef OfertaFamilia = ({String precio, bool conPrueba});

    abstract interface class TiendaCompras {
      Future<bool> disponible();
      Future<OfertaFamilia?> oferta(String idProducto);
      Future<ResultadoCompra> comprar(String idProducto);
      Future<ResultadoCompra> restaurar();
      /// La suscripción activa o en gracia, o `null`. Nunca lanza.
      Future<CompraVigente?> compraVigente(String idProducto);
      /// Cierra la compra en Play (`completePurchase`) si hace falta.
      /// `true` si no quedaba nada pendiente o salió bien; `false` si falló.
      Future<bool> confirmar();
      /// Abre «Suscripciones» de Google Play. `false` si no se pudo.
      Future<bool> gestionar();
    }
    ```
  - `class TiendaPlay implements TiendaCompras { TiendaPlay(InAppPurchase iap, {CanalNativo canal = const CanalNativo('bluetalk/play'), Duration espera = const Duration(seconds: 5)}); void cerrar(); }`
  - `class DerechosPlayBilling implements FuenteDerechos { const DerechosPlayBilling(TiendaCompras tienda); }`: `premium` si `compraVigente(ConfigNube.producto) != null`; si no, o si lanza, `gratis`.
  - `premium_providers.dart`:

    ```dart
    final tiendaComprasProvider = Provider<TiendaCompras>((ref) {
      if (!ref.watch(nubeConfiguradaProvider)) return const TiendaNoDisponible();
      final tienda = TiendaPlay(InAppPurchase.instance);
      ref.onDispose(tienda.cerrar);
      return tienda;
    });

    final fuenteDerechosProvider = Provider<FuenteDerechos>((ref) =>
        ref.watch(nubeConfiguradaProvider)
            ? DerechosPlayBilling(ref.watch(tiendaComprasProvider))
            : const DerechosFijos());
    ```

Reglas de `TiendaPlay` (todas):

- Escucha `iap.purchaseStream` desde el constructor y solo mira compras con `productID == 'bluetalk_familia'`.
- `oferta`: `queryProductDetails({id})`. Play devuelve un `ProductDetails` por oferta. `conPrueba` es `true` si alguna tiene `rawPrice == 0`. `precio` es el `price` de la de mayor `rawPrice`, es decir, el precio mensual. Para comprar se guarda la oferta con prueba si existe y, si no, la base.
- `comprar`: `buyNonConsumable(purchaseParam: PurchaseParam(productDetails: <la guardada>))`. Espera el primer evento de ese producto:
  - `purchased` o `restored` → `comprado`, y guarda el `PurchaseDetails`.
  - `pending` → `pendiente`; `canceled` → `cancelado`; `error` → `error`.
  - Si no llega nada en 10 minutos (el adulto puede tardar), `error`.
- `compraVigente`: `restorePurchases()` y espera el primer lote del stream o `espera` (5 s). Devuelve `(producto, token: p.verificationData.serverVerificationData)` de una compra `purchased` o `restored`; si no, `null`. *shortcut: se fía de lo que dice Play en el teléfono para las voces; la nube la verifica el servidor.*
- `confirmar`: `completePurchase(p)` si `p.pendingCompletePurchase`, sobre el `PurchaseDetails` guardado por `comprar` o por `compraVigente`. Así funciona también tras reiniciar la app, porque `compraVigente` lo vuelve a obtener con `restorePurchases`. Si no hay ninguno guardado, no hace nada. Devuelve sin lanzar; un error del plugin se anota y la Tarea 4 lo reintenta. El reconocimiento real lo hace el servidor (ver Global Constraints).
- `gestionar`: `canal.orden('abrirSuscripciones')`.
- Ninguna excepción del plugin sale de `TiendaPlay`: se convierten en `error`, `null` o `false`.

**NO VERIFICADO** (comprobar leyendo el código del paquete en `~/.pub-cache/hosted/pub.dev/in_app_purchase_android-*/lib/` y anotarlo en el informe):
- Que `restorePurchases()` en Android emite un lote, aunque esté vacío.
- Que cada oferta llega como un `ProductDetails` propio y que la de prueba tiene `rawPrice == 0`.
- Que una compra restaurada que el servidor aún no reconoció llega con `pendingCompletePurchase == true`, y que `completePurchase` sobre una compra que el servidor ya reconoció no da error (o, si lo da, que no hace daño). El paquete no estaba en `~/.pub-cache` al escribir este plan.

Si algo de esto no se cumple, ajustar `oferta` y `compraVigente` sin añadir dependencias.

- [ ] **Step 1: pruebas que fallan.**
  - `premium_test.dart`:
    - `Funcion.seguimientoFamiliar.planMinimo == Plan.premium`. La prueba «premium abre todos los extras» la cubre sola.
    - Sin overrides, `fuenteDerechosProvider` es `DerechosFijos` y `tiendaComprasProvider` es `TiendaNoDisponible`.
    - `DerechosPlayBilling` con una tienda falsa que devuelve compra da `premium`; con `null` da `gratis`; si la tienda lanza, `gratis`.
  - `tienda_play_test.dart`, con `_IapFalso implements InAppPurchase` (`noSuchMethod` para lo que no se usa) y un `StreamController<List<PurchaseDetails>>`:
    - `comprar` con evento `purchased` da `comprado`, y luego `compraVigente` da el token de `serverVerificationData`.
    - `pending` da `pendiente`, `canceled` da `cancelado` y `error` da `error`.
    - Un evento de otro `productID` se ignora.
    - `compraVigente` sin evento en `espera: Duration(milliseconds: 50)` da `null`.
    - `oferta` con dos detalles (`rawPrice` 0 y 9.99) da `conPrueba: true` y el `precio` del de 9.99; `comprar` usa el de `rawPrice` 0.
    - `confirmar` llama a `completePurchase` solo si `pendingCompletePurchase` y da `true`; si `completePurchase` lanza, da `false` sin lanzar; sin compra guardada, da `true` sin llamar.
- [ ] **Step 2:** `timeout 300 flutter test test/core/`. Esperado: FAIL.
- [ ] **Step 3:** implementar. `tienda_play.dart` ≤100 líneas: si no cabe, separar la elección de oferta en `lib/core/premium/oferta_play.dart`.
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde, también `test/padre/` y `test/comunicador/`, que dependen de `puedeUsarProvider`.
- [ ] **Step 5:** commit `FEAT: tienda de Google Play y derechos de la suscripcion Familia`.

### Task 4: activación de la familia (controlador)

**Files:**
- Create: `lib/features/padre/familia/familia_estado.dart`, `lib/features/padre/familia/familia_controller.dart`, `lib/features/padre/familia/activacion_pendiente_providers.dart`
- Modify: `lib/app/app.dart` (2 líneas: el import y `ref.listen(activacionPendienteProvider, (_, _) {});` junto al de `recordatoriosProvider`)
- Test: `test/padre/familia/familia_controller_test.dart`, `test/padre/familia/activacion_pendiente_test.dart`

**Interfaces:**
- Consumes: `tiendaComprasProvider` (Tarea 3), `integridadProvider` (Tarea 2), `clienteNubeProvider`, `cofreClaveProvider`, `nubeConfiguradaProvider`, `ClaveFamilia`, `sha256Hex` (Plan 2), `almacenLocalProvider`.
- Produces:

```dart
enum EstadoFamilia {
  noDisponible,   // nube no configurada o edición directa: no se enseña
  sinSuscripcion,
  pagoPendiente,
  porActivar,     // Play tiene la compra; la nube aún no la registró
  activando,
  activa,
  lleno,          // 409: el pago ya cubre 3 teléfonos de niños
  sinVerificar,   // 401 o 400, o Integrity sin token
  sinPago,        // 402: Google aún no confirma el pago
  sinConexion,    // red, 429 o 5xx: se reintenta a mano o al reabrir
  errorTienda,    // Google Play no completó el pago
  sinCofre,       // el teléfono no puede guardar la clave cifrada
}

/// Claves del almacén (no secretas: estado de pantalla). La clave K vive
/// solo en el cofre (`bluetalk_nube_clave`).
const claveNubeActivada = 'bluetalk_nube_activada'; // bool
const claveNubeRol = 'bluetalk_nube_rol';           // 'nino' | 'lector'
const claveNubeConfirmada = 'bluetalk_nube_confirmada'; // bool: completePurchase hecho
const claveNubeReintento = 'bluetalk_nube_reintento';   // AAAA-MM-DD del último reintento solo

final familiaProvider =
    AsyncNotifierProvider<FamiliaController, EstadoFamilia>(FamiliaController.new);

class FamiliaController extends AsyncNotifier<EstadoFamilia> {
  Future<void> suscribirse();
  Future<void> activar();
  Future<void> gestionar();
  Future<OfertaFamilia?> oferta();
}
```

Lógica de `build()`:
1. Si `!nubeConfiguradaProvider`, el estado es `noDisponible`.
2. Si `almacen.booleano(claveNubeActivada) == true`, es `activa`.
3. Si no, mira `tienda.compraVigente(ConfigNube.producto)`: con compra es `porActivar`; sin ella, `sinSuscripcion`.

`suscribirse()`:
- Pone `activando` y llama a `tienda.comprar(producto)`.
- `cancelado` → `sinSuscripcion`; `pendiente` → `pagoPendiente`; `error` o `noDisponible` → `errorTienda`; `comprado` → `activar()`.

`activar()`, en este orden exacto:
1. Pone `activando`.
2. `compra = await tienda.compraVigente(producto)`; si es `null`, pasa a `sinSuscripcion`.
3. `k = await cofre.leer()`. Si es `null`, genera `ClaveFamilia.generar()` y la guarda **antes** de seguir. Así un reintento reutiliza el mismo `fid`.
4. `c = await k.derivar()`.
5. `token = await integridad.token(await sha256Hex(utf8.encode('${c.fid}|${c.wh}')))`. Si es `null`, pasa a `sinVerificar`.
6. `await cliente.activar(fid: c.fid, wh: c.wh, compra: compra.token, integridad: token)`.
7. Solo tras el `200` o `201`: guarda `claveNubeActivada = true` y `claveNubeRol = 'nino'`, llama a `tienda.confirmar()` y, si devuelve `true`, guarda `claveNubeConfirmada = true`. Después hace `ref.invalidate(planProvider)` (para que las voces del Plan 5 se abran sin reiniciar) y pasa a `activa`.

`suscribirse()` también invalida `planProvider` en cuanto Play responde `comprado`, aunque la activación en la nube falle después: el pago es de Play, y las voces no dependen del servidor.

Si salta `ErrorNube`:
- `lleno` → `lleno`.
- `token` o `peticion` → `sinVerificar`.
- `suscripcion` → `sinPago`.
- `cofre` → `sinCofre`.
- Los reintentables → `sinConexion`.

Ningún error llama a `tienda.confirmar()`.

**Reintento al arrancar** (`activacion_pendiente_providers.dart`), para que ninguna compra pagada quede sin activar ni sin cerrar hasta que Google la reembolse a los 3 días:

```dart
/// Espera antes de reintentar, para no competir con el primer frame.
final esperaArranqueProvider =
    Provider<Duration>((ref) => const Duration(seconds: 5));

final activacionPendienteProvider = FutureProvider<void>((ref) async { … });
```

Orden exacto:
1. Si la nube no está configurada, termina. Esta comprobación va **antes** de esperar, así que las pruebas que montan `BlueTalkApp` no dejan temporizadores.
2. Espera `esperaArranqueProvider`. Si el rol es `lector`, termina.
3. Si `claveNubeActivada == true` y `claveNubeConfirmada != true`: `tienda.compraVigente(producto)`, que vuelve a cargar el `PurchaseDetails` tras el reinicio. Después `tienda.confirmar()` y, si da `true`, `claveNubeConfirmada = true`. Es local, sin el servidor, así que corre en **cada** arranque hasta que salga bien.
4. Si `claveNubeActivada != true`, el cofre ya tiene `K` (la activación empezó en este teléfono y no terminó) y `tienda.compraVigente(producto) != null`:
   - si `claveNubeReintento == hoy`, termina;
   - si no, guarda `claveNubeReintento = hoy` **antes** de llamar, y llama a `ref.read(familiaProvider.notifier).activar()`, con un token de Integrity nuevo como siempre.

   Una vez al día como mucho, por el tope de 3 altas al día por IP del WAF (Plan 1).
5. Ninguna excepción sale del provider.

El botón de la pantalla (Tarea 5) sigue reintentando sin límite diario.

- [ ] **Step 1: pruebas que fallan**, con `ProviderContainer`, `ClienteNubeFalso`, `IntegridadFalsa`, `CofreMemoria`, una `TiendaFalsa` y `nubeConfiguradaProvider` en `true`:
  - Sin nube configurada: `noDisponible`, y la tienda no recibe llamadas.
  - Sin compra: `sinSuscripcion`. Con compra y sin activar: `porActivar`.
  - `suscribirse` con `comprado` termina en `activa`:
    - el falso recibió un `activar` con el `fid` y el `wh` de la clave del cofre;
    - `integridad.hashes.single == sha256Hex('<fid>|<wh>')`;
    - `tienda.confirmaciones == 1`;
    - el almacén tiene `bluetalk_nube_activada == true` y `bluetalk_nube_rol == 'nino'`.
  - **Reintento tras fallo de red:** con `fallo = red`, el estado es `sinConexion` y el cofre ya tiene `K`. Al quitar el fallo y llamar `activar()`, se usa el mismo `fid` y hay 2 hashes de Integrity, uno por intento.
  - `fallo = lleno` → `lleno`; `suscripcion` → `sinPago`; `token` → `sinVerificar`; `IntegridadFalsa(null)` → `sinVerificar`, sin llamar a la API.
  - Un cofre que lanza `ErrorNube(cofre)` → `sinCofre`, sin llamar a la API ni a Integrity.
  - `cancelado` → `sinSuscripcion`; `pendiente` → `pagoPendiente`; `error` → `errorTienda`.
  - **Nunca se cierra la compra sin alta:** en cada caso de error de arriba, `tienda.confirmaciones == 0`.
  - `activacion_pendiente_test.dart`, con `esperaArranqueProvider` en `Duration.zero`. Cada «arranque» es un `ProviderContainer` nuevo que comparte el mismo almacén, el mismo cofre y la misma tienda:
    - **Compra sin reconocer, se reintenta:**
      1. Arranque 1: con `fallo = red`, `suscribirse` da `sinConexion` y `tienda.confirmaciones == 0`.
      2. Se quita el fallo y se cambia el reloj al día siguiente.
      3. Arranque 2: `activacionPendienteProvider` llama a `activar` con el mismo `fid`, y `tienda.confirmaciones == 1`. El almacén tiene `bluetalk_nube_activada` y `bluetalk_nube_confirmada` en `true`.
    - **`completePurchase` que falla, se reintenta:** con la API bien y `TiendaFalsa.confirmarDa = false`, tras el arranque 1 queda `activada` y no `confirmada`. En el arranque 2 (mismo día, `confirmarDa = true`) hay una llamada nueva a `confirmar` y ninguna a la API.
    - Mismo día y sin activar: el segundo arranque **no** vuelve a llamar a la API (`llamadas['activar']` no cambia).
    - Ya activada y confirmada: el arranque no llama ni a la tienda ni a la API.
    - Sin `K` en el cofre (nunca se intentó aquí, o el adulto borró la nube en el Plan 4): no se activa solo aunque Play tenga la compra.
    - Rol `lector` o nube sin configurar: no llama a nada.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/`. Esperado: FAIL.
- [ ] **Step 3:** implementar (cada archivo ≤100 líneas; `app.dart` sigue en ≤100).
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde, también `test/widget_test.dart` y las pruebas que montan `BlueTalkApp`.
- [ ] **Step 5:** commit `FEAT: activacion de la familia con Integrity y la API`.

### Task 5: pantalla «Suscripción Familia» dentro del modo padre

**Files:**
- Create: `lib/features/padre/familia/familia_screen.dart`, `lib/features/padre/familia/seccion_familia.dart`, `lib/features/padre/control/control_permisos.dart`
- Modify: `lib/features/padre/control/control_screen.dart`, `test/arquitectura/tamano_test.dart` (bajar el tope de `control_screen.dart` al número nuevo)
- Test: `test/padre/familia/familia_screen_test.dart`

**Interfaces:**
- Consumes: `familiaProvider` (Tarea 4).
- Produces:
  - `class SeccionFamilia extends ConsumerWidget`: `SizedBox.shrink()` si el estado es `noDisponible`. Si no, `SectionHeader('Familia y nube')` y un `ListTile` con:
    - icono `Icons.family_restroom_outlined`;
    - título `Suscripción Familia`;
    - subtítulo `Voces naturales, informes en otro teléfono y copia de seguridad.`;
    - `chevron_right`; al tocarlo, `Navigator.push` de `FamiliaScreen`.
  - `class SeccionPermisos extends StatelessWidget`: el bloque «Permisos del teléfono» que hoy está dentro de `ControlScreen` (cabecera y `ListTile`), movido tal cual.
  - `class FamiliaScreen extends ConsumerWidget`: `Scaffold` con `AppBar(title: Text('Suscripción Familia'))` y `ListView`.

`control_screen.dart` (179 líneas, en `_deuda`):
- Sustituir el bloque de permisos por `const SeccionPermisos(),`.
- Añadir `const SeccionFamilia(),` justo antes de `const SectionHeader('Desbloqueo')`.
- El archivo debe **encoger**. Bajar su número en `_deuda` al recuento real.

Textos exactos de `FamiliaScreen` (lenguaje literal; ninguno es una metáfora):

| Estado | Texto principal | Botón principal |
|---|---|---|
| todos | Viñetas: «Voces naturales que suenan sin internet.» · «Ver los informes en el teléfono de otro adulto o del terapeuta.» · «Copia de seguridad para cambiar de teléfono.» Debajo: «Comunicar, la voz del teléfono, las frases, las rutinas, los juegos y el modo calma siguen gratis siempre.» y «Los datos viajan cifrados con una clave que solo tienen los teléfonos de tu familia.» | — |
| `sinSuscripcion` | Si `conPrueba`: «Los primeros 7 días son gratis. Puedes cancelar antes en Google Play.» | `Suscribirme por <precio> al mes` (si la oferta es `null`: `Suscribirme`) |
| `pagoPendiente` | «Google Play tiene el pago pendiente. Vuelve a esta pantalla cuando se confirme.» | `Comprobar de nuevo` (`activar`) |
| `porActivar` · `sinConexion` | «Ya pagaste, pero falta registrar este teléfono en la nube. Necesita internet. Si no se termina en 3 días, Google Play te devuelve el dinero.» | `Terminar la activación` |
| `activando` | «Activando…» | sin botón (en modo calma, sin indicador animado; fuera de calma, `LinearProgressIndicator`) |
| `activa` | «La suscripción está activa en este teléfono.» | `Gestionar o cancelar en Google Play` (`gestionar`) |
| `lleno` | «Este pago ya cubre 3 teléfonos de niños. Para usar este, borra la nube en uno de ellos desde su modo padre.» | `Gestionar o cancelar en Google Play` |
| `sinVerificar` | «Google Play no pudo verificar este teléfono. Instala BlueTalk desde Google Play y vuelve a intentarlo.» | `Intentar de nuevo` |
| `sinPago` | «Google aún no confirma el pago. Prueba de nuevo en unos minutos.» | `Intentar de nuevo` |
| `errorTienda` | «Google Play no completó el pago. No se cobró nada.» | `Intentar de nuevo` (`suscribirse`) |
| `sinCofre` | «Este teléfono no puede guardar la clave de la familia de forma segura. La nube no se puede activar aquí.» | — |

- Botones: `FilledButton` con `minimumSize: const Size.fromHeight(48)`.
- Sin colores fijos: todo sale del tema (`context.colores`, `Theme.of(context)`).
- Sin animaciones propias.

- [ ] **Step 1: pruebas que fallan** (`familia_screen_test.dart`, con `pumpPadre` de `test/padre/harness.dart` y `familiaProvider` sobrescrito por un controlador falso con estado fijo):
  - `ControlScreen` con `nubeConfiguradaProvider` en `false` (por defecto) **no** muestra `Suscripción Familia` y sí `Revisar los permisos`. Es la regresión de lo que ya existía.
  - Con `true` muestra `Suscripción Familia`. Al tocarlo se abre `FamiliaScreen`.
  - Un caso por estado de la tabla: aparece el texto exacto y el botón correcto.
  - `sinSuscripcion` con `conPrueba: true` muestra la línea de los 7 días; con `false`, no.
  - Accesibilidad: `problemasDeAccesibilidad(tester, …)` (de `test/core/accessibility_helper.dart`) devuelve una lista vacía para `sinSuscripcion` y `activa`. Cada botón mide ≥48 dp de alto (`tester.getSize(find.byType(FilledButton)).height >= 48`).
  - Modo calma con `activando`: no hay `LinearProgressIndicator` ni `CircularProgressIndicator`.
  - `edicionDirectaProvider` en `true` con la config completa: la sección no aparece.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/ test/padre/control_test.dart`. Esperado: FAIL.
- [ ] **Step 3:** implementar y extraer `SeccionPermisos`. Ningún archivo de esta tarea importa `lib/core/nube/`: la regla de capas del Plan 2 lo vigila.
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde, con `tamano_test.dart` incluido.
- [ ] **Step 5:** humo en el emulador:
  - `timeout 900 flutter run --flavor play --dart-define=BLUETALK_NUBE_URL=https://ejemplo.invalid --dart-define=BLUETALK_GCP_PROYECTO=1`
  - Entrar al modo padre, ir a Control y abrir «Suscripción Familia».
  - Esperado: la pantalla abre. En un emulador sin Play Store, la oferta es `null` y el botón dice `Suscribirme`; tocarlo da `errorTienda`, sin cuelgues.

  Captura en `docs/informes/capturas/plan3-familia.png`. Lo que dependa de Play real queda **NO VERIFICADO**.
- [ ] **Step 6:** escribir `docs/informes/plan3-pago-evidencia.md`.
- [ ] **Step 7:** commit `FEAT: pantalla de la suscripcion Familia en el modo padre`.

## Mejoras posteriores (no son tareas)

- **RTDN (notificaciones en tiempo real de Play por Pub/Sub).** Hoy el servidor guarda `vigenteHasta = min(fin, ahora + 24 h)` (spec §6), así que una cancelación o un reembolso tardan hasta 24 horas en notarse en la nube. Con RTDN, un tema de Pub/Sub avisaría a una Lambda que acorta `vigenteHasta` al momento. Cuesta un tema de Pub/Sub en Google Cloud, un punto de entrada autenticado más y su prueba. Solo vale la pena si esa latencia llega a importar (la spec ya lo deja como `shortcut`).
- También: avisar al adulto con una notificación local si una compra lleva más de 2 días sin activarse.

## Depende del dueño

- Producto de suscripción `bluetalk_familia` en Play Console:
  - plan base mensual y oferta de **prueba gratis de 7 días**;
  - precio y países (el pitch dice CLP 10.500).
- Perfil de pagos de Google Play.
- Cuentas de prueba con licencia (compras sin cobro).
- Proyecto de Google Cloud vinculado a Play, con Play Integrity API activada, y su **número de proyecto** (`BLUETALK_GCP_PROYECTO`).
- Cuenta de servicio con permiso de Android Publisher y de Integrity para el servidor (Plan 1, SSM).
- Subir un AAB firmado a la pista de prueba interna e instalarlo desde Play: Billing e Integrity no funcionan en un APK instalado a mano.
- Desplegar la API (Plan 1) para tener `BLUETALK_NUBE_URL`.
- Hasta entonces, todo corre con dobles, y la sección no se ve en las compilaciones sin `--dart-define`.
