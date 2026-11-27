# Plan 6: contadores de investigación anónimos (D-1, opcionales y apagados por defecto)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** si el adulto lo activa tras el PIN, la app manda una vez por semana cuánto se usó cada parte la semana ISO anterior, en tramos (`0`, `1-5`, `6-20`, `21+`), junto con la versión de la app. No manda `fid`, fecha exacta, país ni nada del niño. No hace falta la suscripción. Apagado por defecto, se apaga cuando se quiera y, al apagarlo, se borra el registro local.

**Architecture:**
- Cuentas puras en `lib/features/padre/familia/contadores.dart`, sin Flutter.
- Un `FutureProvider` en `contadores_providers.dart`, que `lib/app/app.dart` mantiene vivo igual que `recordatoriosProvider`. Decide si toca enviar, arma la semana, pide un token de Integrity fresco y llama a `ClienteNube.enviarContadores` (Plan 2).
- Dos usos que hoy no quedan en ningún registro (modo calma y voz natural) se apuntan en un registro diario pequeño del almacén, **solo** mientras el interruptor está encendido.

**Tech Stack:** Flutter, Riverpod 3.4, núcleo de nube del Plan 2, `Integridad` del Plan 3 y `VozNatural` del Plan 5. Sin dependencias nuevas.

**Spec:** `docs/superpowers/specs/2026-11-26-suscripcion-familia-nube-design.md`:
- §6: `POST /contadores`.
- §7: Integrity con `requestHash = sha256("<semana>|<version>")`.
- §9: contadores D-1.

Contrato: Plan 1, Tarea 5. El servidor acepta solo la semana ISO actual o la anterior, como mucho 6 claves, y las funciones `comunicar`, `aprender`, `rutinas`, `salud`, `calma` y `voces`.

**Serie:** Plan 1 → Plan 2 → Plan 3 → Plan 4 → Plan 5 → **Plan 6 (este)** → Plan 7.

**Depende de:**
- Plan 2: `ClienteNube.enviarContadores`, `ClienteNubeFalso`, `sha256Hex` y `nubeConfiguradaProvider`.
- Plan 3: `integridadProvider`, `IntegridadFalsa` y `SeccionFamilia`.
- Plan 5: `VozNatural`, para la función `voces`.

No depende del Plan 4.

**Lo necesita:** Plan 7, para la política de privacidad y la hoja de Seguridad de los datos: «Actividad en la app → Interacciones», fin «Analítica», opcional.

## Global Constraints

- **Solo la edición `play`** recibe `INTERNET`, Integrity y Billing. En `directa`, `nubeConfiguradaProvider` es `false`: el interruptor no aparece y nunca se envía nada. `directa` compila y sus pruebas siguen en verde.
- Nada regresiona:
  - El menú `/inicio`, la guía de la mascota, los gráficos del adulto, el modo calma, TalkBack y los objetivos de ≥48 dp.
  - **Ninguna voz automática.**
  - El registro de la voz natural no cambia cuándo ni cómo suena.
- **Apagado por defecto.** Sin `bluetalk_contadores_activos == true` no se escribe el registro diario ni se llama a la red. Al apagarlo se borran `bluetalk_contadores_*`, y queda solo el interruptor en `false`.
- Lo único que sale: `{"semana":"AAAA-Www","version":"<versionApp>","c":{6 funciones: tramo},"integridad":"<token>"}`. Nunca cuentas exactas, ids de pictos, textos, `fid` ni fechas de días.
- Un envío por semana como mucho, y un intento al día como mucho. Si falla, se reintenta otro día de la misma semana; si la semana pasa sin éxito, esa semana se pierde. Así nunca se manda una semana de hace 2 (el servidor da `400`).
- Las claves `bluetalk_contadores_*` no entran en la copia de seguridad (Plan 4, Tarea 5): el permiso es de cada teléfono.
- `test/arquitectura/`: la UI no importa `lib/core/nube/`; solo `CanalNativo` crea `MethodChannel`; solo `lib/core/almacen/` toca `SharedPreferences`. Archivos nuevos ≤100 líneas; los de `_deuda` solo encogen.
- Pruebas sin Google ni AWS reales: `ClienteNubeFalso`, `IntegridadFalsa` y reloj fijo.
- Antes de cada commit: `timeout 600 flutter analyze` (0 problemas) y `timeout 1200 flutter test` (todo verde).
- Commits:
  - Formato `TIPO: descripción`, de 70 caracteres como máximo.
  - Rutas concretas en `git add`, sin `Co-Authored-By` y **sin push**.
  - Solo se hacen si el dueño los pidió; si no, la tarea termina en «listo para commit».
- Lo que no se compruebe se marca **NO VERIFICADO** en `docs/informes/plan6-contadores-evidencia.md`.

Claves del almacén:

| Clave | Tipo | Uso |
|---|---|---|
| `bluetalk_contadores_activos` | bool | El interruptor. Falta o `false` significa apagado |
| `bluetalk_contadores_dias` | lista de textos | `"calma\|AAAA-MM-DD"` y `"voces\|AAAA-MM-DD"`. Se recorta a los últimos 14 días al escribir |
| `bluetalk_contadores_enviada` | `AAAA-Www` | Última semana enviada con éxito |
| `bluetalk_contadores_intento` | `AAAA-MM-DD` | Último día en que se intentó. Se escribe **antes** de usar la red |

## Review Focus

1. **Nada sin permiso.** Con el interruptor apagado, ni registro ni red, comprobado con el almacén y el falso (Tareas 2 y 3).
2. **Semana ISO correcta** en los bordes de año: la semana 53 y el lunes que pertenece al año siguiente (Tarea 1).
3. **El hash de Integrity** es `sha256("<semana>|<version>")` con la misma `semana` y `version` del cuerpo (Tarea 2).
4. **Anonimato.** El cuerpo solo lleva tramos, y el falso lo comprueba campo por campo (Tarea 2).

---

### Task 1: cuentas de la semana en tramos y semana ISO

**Files:**
- Create: `lib/features/padre/familia/contadores.dart`
- Test: `test/padre/familia/contadores_test.dart`

**Interfaces:**
- Consumes: `ResumenDia` (`informes/resumen_dia.dart`), `MoodEntry` y `claveDia` (`informes/dia.dart`).
- Produces:

```dart
const funcionesContador = ['comunicar', 'aprender', 'rutinas', 'salud', 'calma', 'voces'];

/// `0`, `1-5`, `6-20` o `21+` (Plan 1, Tarea 5).
String tramo(int n) => n <= 0 ? '0' : n <= 5 ? '1-5' : n <= 20 ? '6-20' : '21+';

/// Semana ISO 8601 de [d], como `2026-W48`.
String semanaIso(DateTime d) {
  final dia = DateTime.utc(d.year, d.month, d.day);
  final jueves = dia.add(Duration(days: DateTime.thursday - dia.weekday));
  final semana = (jueves.difference(DateTime.utc(jueves.year)).inDays ~/ 7) + 1;
  return '${jueves.year}-W${semana.toString().padLeft(2, '0')}';
}

/// Lunes y domingo (claves `AAAA-MM-DD`) de la semana ISO anterior a [hoy].
({String semana, String desde, String hasta}) semanaAnterior(DateTime hoy);

/// Tramos de las 6 funciones para los días [desde]..[hasta] (incluidos).
Map<String, String> contarSemana({
  required String desde,
  required String hasta,
  required List<ResumenDia> resumenes,
  required List<MoodEntry> animos,
  required List<String> registro, // bluetalk_contadores_dias
});
```

Qué cuenta cada función, sumando solo los días de la semana:

| Función | Cuenta |
|---|---|
| `comunicar` | suma de `pictos` |
| `aprender` | suma de `sesionesJuego + cuentos + dibujos` |
| `rutinas` | suma de `actividadesHechas.length` |
| `salud` | número de `MoodEntry` cuyo `claveDia(date)` cae en la semana |
| `calma` | días distintos con `"calma\|<dia>"` en el registro |
| `voces` | días distintos con `"voces\|<dia>"` en el registro |

Las claves `AAAA-MM-DD` se comparan como texto: el orden lexicográfico coincide con el de las fechas.

- [ ] **Step 1: pruebas que fallan.**
  - `tramo`: `0 → '0'`, `1 → '1-5'`, `5 → '1-5'`, `6 → '6-20'`, `20 → '6-20'`, `21 → '21+'` y `-3 → '0'`.
  - `semanaIso` (comprobadas con `date +%G-W%V`):
    - `2026-11-26` da `2026-W48`;
    - `2026-11-30` da `2026-W49`;
    - `2027-01-01` da `2026-W53`;
    - `2024-12-30` da `2025-W01`;
    - `2026-01-01` da `2026-W01`.
  - `semanaAnterior(2026-11-26)` da `(semana: '2026-W47', desde: '2026-11-16', hasta: '2026-11-22')`. `semanaAnterior(2027-01-04)` da `2026-W53`, del `2026-12-28` al `2027-01-03`.
  - `contarSemana`, para la semana del 16 al 22 de noviembre de 2026, con estos datos:
    - un resumen del 15 con 100 pictos, fuera de la semana;
    - resúmenes del 16 (3 pictos, 1 sesión de juego, 1 cuento) y del 22 (4 pictos, 2 actividades);
    - 2 ánimos del 17;
    - registro `["calma|2026-11-16", "calma|2026-11-16", "voces|2026-11-23"]`.

    Esperado: `{'comunicar': '6-20', 'aprender': '1-5', 'rutinas': '1-5', 'salud': '1-5', 'calma': '1-5', 'voces': '0'}`.
  - Con listas vacías: las 6 funciones en `'0'`.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/contadores_test.dart`. Esperado: FAIL.
- [ ] **Step 3:** implementar (≤100 líneas).
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 300 flutter test test/padre/`. Esperado: verde.
- [ ] **Step 5:** commit `FEAT: cuentas semanales en tramos para los contadores`.

### Task 2: registro diario y envío semanal

**Files:**
- Create: `lib/features/padre/familia/contadores_providers.dart`
- Modify:
  - `lib/core/nube/config_nube.dart`: la constante `versionApp`.
  - `lib/app/app.dart`: 2 líneas, el import y `ref.listen(contadoresProvider, (_, _) {});`.
  - `lib/features/comunicador/voz_natural.dart`: el parámetro opcional `alSonar`.
  - `lib/features/comunicador/voz_natural_providers.dart`: pasa `alSonar`.
- Test: `test/padre/familia/contadores_envio_test.dart`, `test/core/nube/version_app_test.dart`

**Interfaces:**
- En `config_nube.dart`:

  ```dart
  /// Versión que viaja en los contadores. Igual a `version:` de pubspec.yaml
  /// sin el `+build` (lo vigila test/core/nube/version_app_test.dart).
  const versionApp = '0.1.0';
  ```

  El Plan 7 la sube a `1.0.0` junto con `pubspec.yaml`.
- En `VozNatural`, el parámetro `void Function()? alSonar`. Se llama solo cuando `reproducir` devolvió `true`. En `ttsSpeakerProvider` es `alSonar: () => registrarUso(ref, 'voces')`.
- En `contadores_providers.dart`:

```dart
final esperaContadoresProvider =
    Provider<Duration>((ref) => const Duration(seconds: 15));

/// Interruptor del adulto (Tarea 3). Apagado por defecto.
final contadoresActivosProvider =
    NotifierProvider<ContadoresActivos, bool>(ContadoresActivos.new);

/// Apunta "funcion|hoy" si el interruptor está encendido. No usa la red.
void registrarUso(Ref ref, String funcion);

enum ResultadoContadores { noAplica, yaEnviada, yaIntentado, enviada, error }

final contadoresProvider = FutureProvider<ResultadoContadores>((ref) async { … });
```

`registrarUso`:
- No hace nada si la nube no está configurada o el interruptor está apagado.
- Si no, añade `"<funcion>|<hoy>"` a `bluetalk_contadores_dias` si no estaba.
- Quita las entradas de hace más de 14 días.

`contadoresProvider`, en este orden:
1. Si la nube no está configurada, `noAplica`, antes de esperar (sin temporizador en las pruebas).
2. `ref.listen(calmModeProvider, (_, encendido) { if (encendido) registrarUso(ref, 'calma'); }, fireImmediately: true)`. Así se apunta el modo calma de hoy si está puesto al abrir o se pone después. El provider sigue vivo porque `app.dart` lo escucha.
3. Esperar `esperaContadoresProvider`. Si el interruptor está apagado, `noAplica`.
4. `s = semanaAnterior(hoy)`. Si `bluetalk_contadores_enviada == s.semana`, `yaEnviada`. Si `bluetalk_contadores_intento == hoy`, `yaIntentado`. Si no, guardar `bluetalk_contadores_intento = hoy`.
5. `await repo.flush()`, `repo.rango(s.desde, s.hasta)`, los ánimos y el registro. Con eso, `c = contarSemana(…)`.
6. `token = await integridad.token(await sha256Hex(utf8.encode('${s.semana}|$versionApp')))`. Es un token nuevo en cada intento y no se guarda. Si es `null`, `error`.
7. `await cliente.enviarContadores(semana: s.semana, version: versionApp, c: c, integridad: token)`. Después, `bluetalk_contadores_enviada = s.semana` y `enviada`.
8. Cualquier `ErrorNube` da `error`. Ninguna excepción sale del provider.

- [ ] **Step 1: pruebas que fallan.**
  - `version_app_test.dart`: lee `pubspec.yaml` con `File` y comprueba que `version:` sin el `+…` es igual a `versionApp`.
  - `contadores_envio_test.dart`, con `ProviderContainer`, `esperaContadoresProvider` en `Duration.zero`, la nube configurada, `ClienteNubeFalso`, `IntegridadFalsa` y el reloj en `2026-11-26 10:00`:
    - **Apagado** (por defecto): `noAplica`, 0 llamadas, `integridad.hashes` vacío, y `registrarUso(ref, 'calma')` no escribe nada.
    - **Encendido**, con datos de la semana 47:
      - el resultado es `enviada`;
      - el falso recibió `semana: '2026-W47'`, `version: versionApp` y exactamente las 6 claves de `funcionesContador`, con valores dentro de los 4 tramos;
      - `integridad.hashes.single == sha256Hex('2026-W47|$versionApp')`;
      - `bluetalk_contadores_enviada == '2026-W47'`.
    - Segundo arranque en la misma semana: `yaEnviada`, sin llamadas.
    - Con `fallo = red`: `error`. Un segundo arranque el mismo día da `yaIntentado`. Al día siguiente, otro intento.
    - Con `IntegridadFalsa(null)`: `error`, sin llamar a la API.
    - Con el modo calma encendido al crear el contenedor: el registro tiene `calma|2026-11-26`.
    - Una entrada de hace 20 días desaparece del registro tras un `registrarUso` nuevo.
  - En `test/comunicador/voz_natural_test.dart`: `alSonar` se llama una vez si el canal devolvió `true`, y ninguna si sonó el TTS del sistema.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/ test/core/nube/ test/comunicador/`. Esperado: FAIL.
- [ ] **Step 3:** implementar. `app.dart` sigue en ≤100 líneas.
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde, también `test/widget_test.dart`.
- [ ] **Step 5:** commit `FEAT: envio semanal de contadores anonimos con permiso`.

### Task 3: interruptor «Ayudar a mejorar BlueTalk» en el modo padre

**Files:**
- Modify: `lib/features/padre/familia/seccion_familia.dart`, `lib/features/padre/familia/contadores_providers.dart` (el notifier)
- Test: `test/padre/familia/contadores_interruptor_test.dart`

**Interfaces:**
- `ContadoresActivos`:
  - `build()` lee `bluetalk_contadores_activos`; si falta, es `false`.
  - `poner(bool v)`. Con `true`, guarda la clave. Con `false`, guarda `false` y borra `bluetalk_contadores_dias`, `bluetalk_contadores_enviada` y `bluetalk_contadores_intento`.
- En `SeccionFamilia`, debajo del `ListTile` de la suscripción y con la misma condición de visibilidad, un `SwitchListTile`:
  - título: `Ayudar a mejorar BlueTalk`;
  - subtítulo: «Una vez por semana envía cuánto se usó cada parte, en tramos como «de 1 a 5». Sin nombre, sin fechas exactas y sin nada de lo que el niño comunica. No hace falta la suscripción.»;
  - etiqueta de accesibilidad: la del título, con el estado del interruptor.

  No se enciende solo, ni se ofrece al instalar ni en la guía de la mascota.
- Al encender, un diálogo de confirmación: «Se enviará, una vez por semana, solo esto: la semana del año, la versión de la app y, para comunicar, aprender, rutinas, salud, calma y voces, un tramo (0, de 1 a 5, de 6 a 20 o más de 20). No se puede borrar después porque no lleva nada que diga de qué teléfono vino. Puedes apagarlo cuando quieras.» Botones: `Cancelar` y `Activar`.

- [ ] **Step 1: pruebas que fallan** (con `pumpPadre` y la nube configurada):
  - El interruptor aparece apagado.
  - Encenderlo abre el diálogo. `Cancelar` lo deja apagado y no escribe nada. `Activar` deja `bluetalk_contadores_activos == true`.
  - Apagarlo borra las 3 claves de datos.
  - Con la nube sin configurar o en `directa`: no aparece.
  - `problemasDeAccesibilidad` da una lista vacía. El `SwitchListTile` mide ≥48 dp de alto.
- [ ] **Step 2:** `timeout 300 flutter test test/padre/familia/`. Esperado: FAIL.
- [ ] **Step 3:** implementar. Si `seccion_familia.dart` pasa de 100 líneas, separar el interruptor en `lib/features/padre/familia/interruptor_contadores.dart`.
- [ ] **Step 4:** `timeout 600 flutter analyze` y `timeout 1200 flutter test`. Esperado: verde.
- [ ] **Step 5:** escribir `docs/informes/plan6-contadores-evidencia.md`. Queda **NO VERIFICADO** el envío contra el servidor real con un token de Integrity real.
- [ ] **Step 6:** commit `FEAT: interruptor de contadores anonimos en el modo padre`.

## Depende del dueño

- API desplegada (Plan 1) y el proyecto de Google Cloud con Integrity (Plan 3). Sin ellos, el interruptor no aparece.
- Revisión legal de que los tramos semanales sin identificador son de verdad anónimos, y de la redacción para Play (Plan 7).
- Decidir quién mira el agregado `C#<semana>` en DynamoDB y cómo. No forma parte de la app.
