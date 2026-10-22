# Fase 3a — evidencia

**Fecha:** 2026-10-21 · **Rama:** `feat/rediseno-y-control-parental` · **Sin push, sin merge.**

Contenido de la fase: PIN cifrado en el keystore, bloqueo de desinstalación
(`DeviceAdminReceiver`) y asistente de permisos que no deja entrar en el panel
si falta un permiso obligatorio.

## Commits

| Commit | Qué |
|---|---|
| `34448cd` | `3a.1` PIN y código de recuperación en `flutter_secure_storage` (keystore) con migración desde `SharedPreferences` |
| `5bb784d` | `3a.2` `DeviceAdminReceiver` + `ProteccionChannel` + tile en Control |
| `53c9350` | `3a.3` `PermisosChannel` + asistente de permisos + bloqueo del paso al panel |
| *(este)* | Arreglo del defecto visto al ejecutarlo: el diagnóstico de permisos se servía de una caché vieja |

## Qué se ejecutó y qué se vio

**Máquina (todo con `taskset -c 0-3` y `nice -n 10`, wrapper
`./scripts/gradle-limite.sh`):**

- `flutter analyze` → **`No issues found!`**
- `flutter test` → **321/321 en verde** (320 previos + 1 test de regresión nuevo)
- `flutter build apk --debug` → `✓ Built build/app/outputs/flutter-apk/app-debug.apk`
- `gradle-limite.sh --stop` después de cada tarea pesada; `uptime` tras los
  lanzamientos (máx. 1 min subió a 6,75 tras la suite → esperado; bajó a 2,30
  antes de compilar). Un solo emulador, cerrado al terminar.

**Emulador `bluetalk_gama_baja` (API 28, 720×1280, 2 cores, 2048 MB):**

1. APK debug instalado con `adb install -r` (conserva datos) y arrancado.
2. Primera visita ya hecha en esta sesión: apodo «Prueba», legal aceptado,
   PIN **123456**.
3. Ajustes → Zona de adultos → «Modo padre» → PIN → se entra.
4. `aapt2 dump xmltree` sobre el APK: `ProteccionReceiver` presente en el
   manifiesto.
5. Control → «Revisar los permisos» abre el asistente; tile «Protección
   contra desinstalación — Sin activar».

### Defecto que solo salió al ejecutarlo (y su arreglo)

**Antes:** el panel del modo padre se servía con el resultado que se había
calculado al entrar en la app. Si el adulto concedía o revocaba un permiso
desde Android, BlueTalk seguía con el estado viejo: revocando `GET_USAGE_STATS`
desde `adb appops`, el panel **se seguía enseñando**.

**Causa:** `permisosProvider` es un `FutureProvider` sin invalidación. Nadie
lo recargaba al entrar en la zona ni al volver de una pantalla de Android.

**Arreglo** (`lib/features/padre/padre_screen.dart`): `_PadreScreenState`
implementa `WidgetsBindingObserver`; invalida `permisosProvider`
- en `initState` (tras el primer frame), es decir cada vez que se entra en la
  zona de adultos, y
- en `didChangeAppLifecycleState(resumed)`, es decir cada vez que se vuelve de
  Android (el adulto acaba de poder conceder o revocar ahí fuera).

El estado de carga sigue **sin bloquear**: mientras el diagnóstico no
termina, `faltanPermisos` se lee como `false`, así que se enseña el panel
(y no una pantalla vacía) y en cuanto la comprobación termina se sustituye
por el asistente si falta algún obligatorio. Puede verse el panel un
instante antes de esa sustitución; una vez comprobado que falta un
obligatorio, no se vuelve a enseñar.

**Prueba A/B (hecha, no es una afirmación):**

| Situación | Antes del arreglo | Después |
|---|---|---|
| Entra con `GET_USAGE_STATS` en `deny` | panel ✗ | asistente con «Todavía no se puede avanzar. Falta conceder: Acceso al uso de las apps» ✓ |
| Dentro del panel → `deny` → Home → volver | panel seguía ✗ | el panel se sustituye por el asistente ✓ |
| `allow` → Home → volver | — | vuelve el panel con Resumen/Control/Salud/Legal ✓ |

Capturas archivadas: `docs/informes/capturas/3a-00-asistente-permisos.png`
(asistente con el canal nativo real en el emulador), `3a-01-bloqueo-al-entrar`,
`3a-02-panel-tras-conceder`, `3a-03-bloqueo-tras-revocar` y
`3a-04-panel-restaurado` (el recorrido A/B descrito arriba).

**Test de regresión:** `test/padre/permisos_test.dart` → «si el adulto
revoca un permiso fuera de la app, al volver se vuelve a comprobar».
Comprobado que **falla si se quita el `invalidate` del `resumed`** y pasa con
él (se ejecutó una vez con la línea anulada).

### Por qué los tests no mueren solos ante un canal nativo callado

En `flutter test` el canal `bluetalk/permisos` no contesta, así que el
diagnóstico se quedaría sin resolver en muchos tests y el bloqueo quedaría
sin probar de casualidad. Se añadió en `test/padre/harness.dart` una doble
inofensiva por defecto (`todo concedido`) y un parámetro `permisos:` para
que cada test decida. La ruta de bloqueo se prueba con dobles: no es la
prueba de que el canal nativo funciona en el teléfono (eso es lo de abajo).

## Contradicción con un plan, anotada (regla de la casa)

`docs/plan/11-fases-1-a-3-excelencia.md` §1.5.7 dice textualmente
**«`flutter_secure_storage` no se usa … No lo reintroduzcas»**, y `34448cd`
lo introduce para la huella del PIN. El dueño lo aprobó el 2026-10-19
(decisión 1 en `PROGRESO.md`), por lo que esa línea del plan queda
superada por su decisión. **No se ha editado el plan**: se deja constancia
aquí y, si se reabre el plan, que se actualice ahí.

## Ronda de revisión posterior (`revisor`)

El revisor de entregas paró el commit con **1 hallazgo grave y 4 medios**.
Todo se corrigió en esta misma rama antes de commitear:

| Hallazgo | Qué se hizo |
|---|---|
| **Grave:** `BORRAR` no borraba las huellas del keystore → el gate volvía a pedir el PIN olvidado (bucle) | `AlmacenPin.borrarSecretas()`: keystore primero, y si no deja borrar **no se declara hecho** ni se toca nada; aviso literal en la pantalla. Tests: 3 unitarios + el test de widget del BORRAR ampliado con keystore (comprobado que **falla sin el arreglo**) |
| **Medio:** `uso` y `vpn` devolvían «no concedido» cuando el canal fallaba → bloqueo sin salida | Tri-estado real: `UsoTelefonoGateway.estadoPermiso()`, `FiltroWebEstado.comprobado` y `ProteccionEstado.comprobado`. Un fallo de consulta enseña «No se pudo comprobar» y no bloquea. 3 tests nuevos |
| **Medio:** el informe describía una carga sin panel que el código no hace | Texto corregido: mientras carga se enseña el panel y, si falta un obligatorio, se sustituye por el asistente |
| **Medio:** `AlmacenPin.cifrado` prometía enseñarse en pantalla y no se enseñaba | Tile «Dónde se guarda tu código» en Control, con las dos frases; `cifrado` además ya no puede quedarse en `true` con una migración a medias. 2 tests nuevos |
| **Medio:** el texto de los avisos negaba los recordatorios automáticos | Reescrito literal: solo avisa de las actividades del horario, a la hora que tú pusiste |

Leves también corregidos: comentario del doble de permisos pegado al de
`DerivadorPinPrueba` (`harness.dart`), línea sobrante en `permisos_controller.dart`,
`а` cirílica de «Registrа» en `device_admin.xml`, y este latido de
`estado-vivo.log`, reanudado después de los commits de hoy.

## NO VERIFICADO

- **Keystore real.** `3a.1` se probó con doble de keystore en tests y no se
  pasó por la pantalla de migración en un dispositivo. Queda en 3c.
- **Fricción real de desinstalación.** El `DeviceAdminReceiver` pide
  **cero políticas** (`<uses-policies />` vacío en `res/xml/device_admin.xml`):
  es fricción, no un muro. Que Android ofrezca o no «desactivar la
  administración» con PIN lo decide el fabricante, y en un teléfono con
  administrador de dispositivo corporativo puede no activarse nunca. No se ha
  probado en un teléfono físico.
- **Batería.** El asistente abre `Settings.ACTION_IGNORE_BATTERY_OPTIMIZATIONS_SETTINGS`
  (verificado con `javap` contra `~/android-sdk/platforms/android-36/android.jar`),
  que es una pantalla de ajustes y **el dueño puede ignorarla**. No es la
  exención `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`, que está restringida en
  Play Store. La app funciona sin concederla (es opcional).
- **Accesibilidad y `SYSTEM_ALERT_WINDOW`.** No se piden: aún no existe el
  servicio de bloqueo que los usa (va en la 3b). Pedirlos ahora dejaría el
  asistente sin nada a qué llevarlos. Anotado como alcance en `PROGRESO.md`.
- **`docs/plan/14-filtro-web.md` no existe** y el código lo cita en
  comentarios. Hay que escribirlo o quitar las citas; decisión pendiente.

## Resultado de la fase

Fase 3a **cerrada en código y verificada en emulador**. Falta la confirmación
del dueño para pasar a la 3b (SafeSearch, bloqueo por palabras, perfiles por
edad).
