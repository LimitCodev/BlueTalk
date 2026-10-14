# Plan 10 — Fase 0: dejar BlueTalk funcional

**Para:** el agente que ejecuta (OpenCode). **Origen:** `docs/informes/auditoria-general.md` (hallazgos C1–C5, M1).
**Regla de oro:** sigue los pasos en orden. Un paso = un commit. No hagas nada que no esté aquí.

## Reglas (de `docs/plan/00-PLAN-MAESTRO.md` §5–6, resumidas)

- Commits: `TIPO: descripción en español` (≤70 caracteres, sin punto final, sin texto de IA, sin `Co-Authored-By`). Tipos: `FEAT FIX PERF TEST DOCS REFACTOR CHORE`.
- Antes de cada commit: `flutter analyze` → 0 problemas y `flutter test` → todo en verde. Excepción: los pasos 2–3 pueden dejar tests de `test/rutinas/` en rojo; el paso 5 los arregla. En ese caso, en los pasos 2–4 ejecuta solo `flutter analyze` y los tests del área tocada.
- No hagas `git push`. No edites `pubspec.yaml` (salvo el paso 7). Sin datos reales ni nombres reales.
- Si un paso falla o la realidad del código difiere de lo escrito aquí: **detente y anótalo** en `docs/informes/fase0-notas.md` en vez de improvisar.

---

## Paso 1 — Commitear lo que está sin seguimiento (C2)

Hoy `git status` muestra 23 rutas `??`. Hazlo en commits temáticos, **solo con `git add` de rutas concretas** (nunca `git add -A`):

1. `git add docs/legal lib/features/padre test/padre` → `FEAT: modo padre con gate, resumen, control y legal`
2. `git add lib/features/rutinas lib/features/salud lib/features/entorno test/rutinas` → `FEAT: rutinas, salud y entorno`
3. `git add research_notes/datos-publicos AGENTS.md docs/plan/10-fase0-funcional.md docs/plan/11-fases-1-a-3-excelencia.md docs/informes/auditoria-general.md` → `DOCS: auditoria general y plan de fase 0`

`test/rutinas` tiene tests en rojo: se commitean tal cual; el paso 5 los arregla. Comprueba con `git status --short` que no queda nada con `??`.

---

## Paso 2 — Persistir el horario (C3)

**Problema:** `SeedScheduleRepo` en `lib/data/local/mock_repos.dart` guarda las ediciones solo en un `Map` en memoria.
**Contrato:** `ScheduleRepo` (`lib/data/contracts/repos.dart`) no cambia.

1. En `lib/data/local/mock_repos.dart`, cambia `SeedScheduleRepo` para recibir también `SharedPreferences`:
   - Constructor: `SeedScheduleRepo(this._store, this._prefs);` con `final SharedPreferences _prefs;`.
   - Clave nueva: `static const _key = 'bluetalk_schedule';`
2. Modifica `_ensureLoaded()`:
   - Primero lee el seed como hoy y llena `_entries`.
   - Después, si `_prefs.getString(_key)` no es null, decodifícalo con `_tryDecodeList(raw)` y **sobrescribe** `_entries[entry.id]` con cada `ScheduleEntry.fromMap(row)` (las entradas del usuario tienen prioridad sobre el seed; las nuevas se añaden).
3. Modifica `saveEntry`: tras `_entries[entry.id] = entry;` guarda **solo las entradas modificadas por el usuario**. La forma más simple y correcta es guardar **todas** las entradas actuales:
   ```dart
   await _prefs.setString(
     _key,
     jsonEncode([for (final e in _entries.values) e.toMap()]),
   );
   ```
4. En `lib/app/di.dart`:
   ```dart
   final scheduleRepoProvider = Provider<ScheduleRepo>(
     (ref) => SeedScheduleRepo(
       ref.watch(seedStoreProvider),
       ref.watch(sharedPreferencesProvider),
     ),
   );
   ```
5. Busca otros usos de `SeedScheduleRepo(` con `grep -rn "SeedScheduleRepo(" lib test` y corrígelos.
6. **Test nuevo** en `test/data/schedule_persistence_test.dart` (sin widgets, sin assets reales):
   - `SharedPreferences.setMockInitialValues({})`.
   - Crea `SeedStore` con un lector falso que devuelve un JSON mínimo de 1 entrada (mira cómo lo hace `test/data/seeds_test.dart`).
   - Guarda una entrada nueva y una editada con `saveEntry`.
   - Crea un **segundo** `SeedScheduleRepo` con las mismas prefs y comprueba que `schedule()` devuelve la nueva y la editada, ordenadas por `timeMinutes`.
7. Commit: `FIX: el horario se guarda en el dispositivo`

---

## Paso 3 — Eventos de uso: dejar de perder `juego_fin` (M1)

**Problema:** `PrefsUsageRepo` (`mock_repos.dart`) recorta a los últimos 200 eventos de **todos** los tipos. Los `picto_tap` desplazan los `juego_fin`, y el límite diario y las métricas del padre se calculan mal.

**Política nueva** (en `record`, antes de guardar):
- Eventos `picto_tap`: conservar solo los últimos **300**.
- Cualquier otro tipo: conservar los de los últimos **14 días** (su volumen es bajo).
- Mantener el orden cronológico.

1. Sustituye las constantes `_maxEvents` por:
   ```dart
   static const _maxTaps = 300;
   static const _retencion = Duration(days: 14);
   ```
2. En `record`, después de `list.add(event);`:
   ```dart
   final limite = event.createdAt.subtract(_retencion);
   list.removeWhere(
     (e) => e.type != 'picto_tap' && e.createdAt.isBefore(limite),
   );
   var sobran = list.where((e) => e.type == 'picto_tap').length - _maxTaps;
   if (sobran > 0) {
     list.removeWhere((e) => e.type == 'picto_tap' && sobran-- > 0);
   }
   ```
   (`removeWhere` recorre en orden: elimina los `picto_tap` más antiguos primero.)
3. Actualiza el comentario de la clase: ya no es "los últimos 200 eventos".
4. **Test nuevo** en `test/data/usage_repo_test.dart`: registra 1 `juego_fin` y luego 400 `picto_tap`; comprueba que `events()` sigue conteniendo el `juego_fin` y que hay exactamente 300 `picto_tap`. Otro caso: un evento no-tap de hace 20 días desaparece al registrar uno nuevo.
5. Commit: `FIX: los toques de pictogramas ya no borran el tiempo de juego`

---

## Paso 4 — Conectar las pantallas al router (C1)

Archivo: `lib/app/router.dart`.

1. Imports nuevos:
   ```dart
   import '../features/padre/control/control_parental.dart';
   import '../features/padre/control/juegos_gate.dart';
   import '../features/padre/padre_screen.dart';
   import '../features/rutinas/rutinas_screen.dart';
   ```
2. Ruta `/home/aprender`: envolver con el guard:
   ```dart
   const JuegosGate(juegos: JuegosScreen()),
   ```
3. Ruta `/home/rutinas`: sustituir `const _TabContent('Rutinas', 'Horario del día')` por `const RutinasScreen()`. **Borra la clase `_TabContent`** si queda sin uso (el analizador avisará).
4. Ruta `/padre`: sustituir todo el `Scaffold` placeholder por `const PadreScreen()`. `PadreScreen` ya vuelve a `/home/ajustes` al salir.
5. **Bloqueo de entorno:** `RutinasScreen` abre `EntornoScreen` internamente (`rutinas_screen.dart`, caso `RutinaVista.colegio`). En esa línea, antes de mostrar `EntornoScreen`, consulta `ref.watch(bloqueosProvider).entorno`. Si está en `true`, muestra un aviso con el mismo estilo que `_AvisoBloqueado` de `juegos_gate.dart`. Para reutilizarlo sin duplicar: en `juegos_gate.dart` haz **pública** la clase `_PanelSuave` → `PanelSuave` (renombrar en ese archivo) y úsala desde `rutinas_screen.dart` con:
   - icono `Icons.lock_outline`
   - título `La sección Mi colegio está bloqueada por un adulto.`
   - texto `Pide que te la desbloqueen desde la zona de adultos.`
   - un botón `Volver` que llame a `ref.read(rutinasProvider.notifier).irAlInicio()`.
6. **Acceso al modo padre desde Ajustes:** en `lib/features/ajustes/ajustes_screen.dart`:
   - Añade una sección `SectionHeader('Zona de adultos')` con un `ListTile` (`Icons.lock_outline`, título `Modo padre`, subtítulo `Resumen, control y legal. Pide tu código.`, `trailing: chevron_right`) cuyo `onTap` haga `context.go('/padre')` (import de `go_router`).
   - Colócala **antes** de `_LegalSection`.
   - Es solo un acceso: el PIN lo pide `GateScreen`, no esta pantalla.
7. **Enlaces legales de Ajustes:** `_LegalSection` abre un diálogo "estará disponible en una versión futura". Sustituye ambos `onTap` por `context.go('/padre')` solo si es el flujo existente; **si no estás seguro, déjalo como está y anótalo en `docs/informes/fase0-notas.md`** (los textos legales se ven hoy dentro del modo padre → Legal). No inventes pantallas nuevas.
8. **Actualiza tests existentes** que afirmaban los placeholders, en `test/core/router_test.dart`:
   - Test `ruta /padre muestra el placeholder del gate` (≈línea 132): cámbialo para esperar el texto de la pantalla real. Como `legalProvider` es `null` en un arranque limpio, debe verse la vista **legal** (`LegalScreen`), no el gate. Comprueba `find.text('Modo padre')` (título del `AppBar`) y un texto de `LegalScreen`.
   - Test de `/home/rutinas` (≈línea 163): sustituye `find.text('Horario del día — próximamente')` por `find.text('Mi horario')` (tarjeta de `RutinasScreen`). Si el test ejercía además la ruta con modo calma, conserva esa parte.
9. **Tests nuevos** en `test/core/router_test.dart` o `test/padre/`:
   - Con `bloqueosProvider` en `juegos: true` (`SharedPreferences.setMockInitialValues({'padre_bloqueo_juegos': true})`), ir a `/home/aprender` muestra `Los juegos están bloqueados por un adulto.`
   - Con límite agotado (`padre_limite_juegos_min: 15` y un evento `juego_fin` de 1 000 s hoy en `bluetalk_usage`), aparece `El tiempo de juegos de hoy terminó.`
   - Con `padre_bloqueo_entorno: true`, la sección Mi colegio muestra el aviso.
10. Commit: `FEAT: conectar rutinas, modo padre y limites al router`

---

## Paso 5 — Arreglar los 11 tests de `test/rutinas/` (C5)

Ejecuta primero `flutter test test/rutinas/ 2>&1 | grep -v "^\s*#" | head -150` y trabaja de uno en uno.

**Causa conocida (9 de 11):** el texto `Mi día` aparece **dos veces** una vez dentro de la sección Bienestar: una en la cabecera de `lib/features/salud/salud_screen.dart` (≈línea 72) y otra en un `SectionHeader('Mi día')` de `DiaHoySection` / `estadisticas_view.dart` (≈línea 104) / `horario_view.dart` (≈línea 172).

**Arreglo:** los encabezados internos de resumen **no deben repetir** el título de la tarjeta. Renombra los `SectionHeader('Mi día')` de `horario_view.dart`, `estadisticas_view.dart` y `rutinas_screen.dart` (el de `DiaHoySection`) a **`Resumen de hoy`**. Deja `Mi día` solo en: la tarjeta de inicio (`rutinas_screen.dart:56`) y el título de cabecera de `salud_screen.dart:72`.
Si algún test busca ese encabezado por su texto antiguo, cambia el test a `Resumen de hoy`.

**Casos no diagnosticados (2 de 11):**
- `test/rutinas/horario_test.dart` — "tocar una actividad la marca como hecha con aviso" (espera el texto `Recreo: hecha` y no lo encuentra).
- `test/rutinas/editor_horario_test.dart` — "quitar una actividad la lleva a quitadas y se restaura" (espera `Actividades quitadas`).

Para cada uno:
1. Ejecuta solo ese test con `flutter test <archivo> --plain-name "<nombre>"`.
2. Busca avisos `warnIfMissed` (el toque cae fuera de pantalla → añade `await tester.ensureVisible(find.text('Recreo'));` antes de `tap`, o usa `tester.view.physicalSize` mayor en `harness.dart`).
3. Si el `SnackBar` no aparece porque no hay `Scaffold` en el harness, envuelve la pantalla en `Scaffold` en `pumpRutinas` (`test/rutinas/harness.dart`) como lo haría `AppShell`.
4. Si el fallo revela un **error real de la app** (no del test), corrige la app, no el test.
5. Si no lo resuelves en 3 intentos: anótalo en `docs/informes/fase0-notas.md` con el error exacto y sigue.

Al terminar: `flutter test` completo en verde.
Commit: `TEST: corregir tests de rutinas y repetir menos Mi día`

---

## Paso 6 — Tests mínimos de seguridad en `test/padre/` (C5)

`test/padre/` está vacío. Crea estos archivos (usa `SharedPreferences.setMockInitialValues`, reloj falso con `ahora: () => fecha`; no hacen falta widgets salvo el último):

1. `test/padre/pin_store_test.dart`
   - `crear('1234')` → `creado == true`; no se guarda el PIN en claro (ningún valor de las prefs contiene `1234`).
   - `verificar('1234')` → `correcto`; `verificar('0000')` → `incorrecto`.
   - 5 fallos seguidos → el 5.º deja `bloqueoRestante() > 0` y `verificar('1234')` devuelve `bloqueado`.
   - Avanzar el reloj 61 s → `verificar('1234')` vuelve a `correcto`.
   - `crear('12a4')` y `crear('123')` lanzan `FormatException`.
2. `test/padre/control_parental_test.dart`
   - `LimiteJuegos(minutosPorDia: 30, segundosUsados: 1800, extensionMinutos: 0).permitido == false`; con `extensionMinutos: 5` es `true`.
   - `minutosPorDia: 0` → `sinLimite` y `permitido == true`.
   - `cercaDelTope` es `true` con 26 de 30 minutos usados.
   - `LimiteJuegosController`: con un evento `juego_fin` de 600 s hoy, `minutosUsados == 10`; con uno de ayer, `0`. `ampliar()` suma 5.
3. `test/padre/padre_controller_test.dart`
   - Sin aceptación legal → estado `legal`; tras `legalProvider.notifier.aceptar()` → `gate`.
   - `irA(PadreVista.resumen)` sin legal aceptada no cambia el estado; `irA(PadreVista.gate)` nunca cambia nada.
   - `entrar()` → `resumen`; `cerrarSesion()` → `gate`.
4. Commit: `TEST: pruebas de PIN, limites y navegacion del modo padre`

---

## Paso 7 — Retirar dependencias sin uso (C4)

Decisión del proyecto: el MVP se queda en `SharedPreferences`, sin Supabase ni Drift.
`pubspec.yaml` se descongela **solo para este paso**.

1. Confirma que cada una tiene 0 usos: `grep -rln "<nombre>" lib test` para `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `supabase_flutter`, `connectivity_plus`, `http`, `path_provider`, `flutter_secure_storage`.
2. Si 0 usos, bórralas de `dependencies`. Quita también `drift_dev` y `build_runner` de `dev_dependencies` **solo si** no hay archivos `*.g.dart` ni `part '...g.dart'`.
3. **No quites** `flutter_local_notifications` ni `timezone`: se usan en la Fase 1 (recordatorios).
4. `flutter pub get` → `flutter analyze` → `flutter test` → `flutter build apk --debug`. Todo debe pasar.
5. Anota en `docs/ARQUITECTURA.md` (sección de decisiones) y en `README.md` que el MVP persiste en `SharedPreferences` y que Supabase/Drift quedan fuera hasta nueva decisión. Cambia en el README "Fase de planificación y arquitectura" por "MVP en desarrollo; compila y pasa tests".
6. Commit: `CHORE: quitar dependencias sin uso del MVP`

---

## Paso 8 — Onboarding sin apodo obligatorio

`lib/features/onboarding/onboarding_screen.dart`: `_canStart` exige texto, pero el comentario de `_start` dice "con o sin apodo".

1. `bool get _canStart => !_saving;`
2. Texto del botón y de ayuda: mantén `Comenzar`. Si el campo está vacío, `profileProvider.notifier.create` debe aceptar cadena vacía (revisa `profile_controller.dart`: si rechaza vacío, guarda un apodo por defecto `Amigo` o `null` según permita `ChildProfile`).
3. Actualiza el test de onboarding que espera el botón deshabilitado sin texto (busca en `test/features/` y `test/core/router_test.dart` con `grep -rn "Comenzar" test`).
4. Commit: `FIX: permitir empezar sin apodo`

---

## Paso 9 — Verificación final

Ejecuta y pega la salida resumida en `docs/informes/fase0-notas.md`:

```bash
flutter analyze
flutter test
flutter build apk --debug
git status --short   # debe estar limpio
git log --oneline -12
```

Criterios de aceptación de la Fase 0 (todos deben ser verdad):

- [ ] `flutter analyze`: 0 problemas. `flutter test`: 0 fallos.
- [ ] La pestaña **Rutinas** muestra horario, bienestar, colegio y estadísticas.
- [ ] Ajustes → **Modo padre** abre la pantalla legal la primera vez y el gate (crear PIN) después.
- [ ] Un horario editado sigue ahí tras cerrar y reabrir la app.
- [ ] Con límite de juegos agotado o bloqueo activado, **Aprender** muestra el aviso suave.
- [ ] `git status` limpio; ninguna ruta `??`.
- [ ] `docs/informes/fase0-notas.md` lista lo que no se pudo cerrar (si algo).

## Fuera de alcance (no hacer ahora)

Recordatorios con notificaciones, PIN de 6 dígitos, `allowBackup=false`, firma de release, iconos, ampliar vocabulario. Todo eso es Fase 1–3 en `docs/informes/auditoria-general.md` §7.
