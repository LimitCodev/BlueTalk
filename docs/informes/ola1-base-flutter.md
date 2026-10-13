# Informe — `base-flutter` (Ola 1) — 2026-10-13

**Veredicto: CORRECCIONES** (0 BLOCKER · 4 MAJOR · 3 MINOR · 3 Sugerencia)

**Alcance revisado:** solo Ola 1 — `lib/main.dart`, `lib/app/**`, `lib/core/theme/**`,
`lib/data/{models,contracts,local}/**`, `lib/features/{onboarding,ajustes}/**`,
`assets/seed/**`, `assets/pictos/muestra/**` (coherencia/licencia), `test/{core,data,features,widget_test.dart}`,
`pubspec.yaml`, `analysis_options.yaml`. NO revisado `lib/features/comunicador/**` ni `test/comunicador/**`
(otro agente trabaja en paralelo ahí).

**Commits revisados (rango provisto por el coordinador):** `206bf2d` → `096132a` (14 commits).
**Limitación:** no se ejecutó `git` por instrucción explícita (agente paralelo commiteando): el contenido
de los commits coincide con el alcance del plan, pero la convención de mensajes de la sección 6 del plan 00
**no se verificó aquí** — recomiendo una pasada rápida de `git log --format='%h %s'` en la revisión 1x1.

**Estado verificado por mí (no confiado en el agente):**
- `flutter analyze` → **0 issues** ✔
- `flutter test` → **53/53 en verde** ✔ (tests reales: contraste AA de tokens, calma persistida +
  `disableAnimations`, duración cero de ruta en calma, roundtrip de los 11 modelos, seeds coherentes
  con los 42 assets verificados en disco, persistencia de ajustes/perfil).

---

## MAJOR

1. **[lib/features/ajustes/ajustes_screen.dart:194] Encabezados de sección con contraste 1.74:1 (colapsa AA).**
   `_SectionHeader` pinta el título con `Theme.of(context).colorScheme.primary`, que `app_theme.dart:14`
   fija en `AppColors.primary` (#7FC9EA) sobre fondo `bg` (#F3FAFF) → **1.74:1** (verificado con la fórmula
   WCAG del propio `tokens_test.dart`; AA exige ≥4.5:1). El token `primaryStrong` existe exactamente para
   esto (`app_colors.dart:20-22`) pero tampoco alcanzaría para texto (4.22:1). Los tokens están bien; el
   **uso** los viola, y es el mismo error que repetirán los otros 4 agentes al copiar este patrón.
   → Acción: pintar el título con `AppColors.text` o `AppColors.primaryInk` (12.8:1) y añadir test de uso.

2. **[lib/data/local/mock_repos.dart:81,125,146] Tres repositorios volátiles: no hay Drift y nadie lo tiene asignado.**
   `InMemoryGameProgressRepo`, `InMemoryWellbeingRepo` e `InMemoryUsageRepo` pierden todo al reiniciar
   (avance de juegos, check-in emocional, hábitos, eventos de uso). El plan 00 §7 define `lib/data/local`
   (Drift) como **fuente de verdad del MVP**, el plan 01 §6 prometió "mock/Drift", y los agentes de la
   Ola 2 (`juegos` promete "progreso persistido offline"; `rutinas-salud` maneja hábitos) **dependen de
   esta persistencia y no pueden implementarla: la carpeta es dueña de Ola 1**. Es el riesgo de
   dependencia cruzada más grande que veo antes de abrir Ola 2.
   → Acción: o bien base-flutter entrega la capa Drift ahora, o el coordinador deja por escrito en el
   plan 01 qué ola/cuéándo la implementa, para que Ola 2 no diseñe contra un contrato que miente.

3. **[docs/plan/01-base-flutter.md:50] Componentes base prometidos y no entregados.**
   El alcance 2 del plan 01 promete `BlueButton` (≥48dp), `CardTile`, `SectionHeader`, `EmptyState`,
   `PictoTile` reutilizables; no existe ninguno (grep en `lib/` → solo `_SectionHeader` privado de
   `ajustes_screen.dart:182`). Con 4 agentes en paralelo y `lib/core` cerrado para ellos, todos van a
   inventar su propio botón/tarjeta → inconsistencia visual garantizada en una app para autistas donde
   la predecibilidad es requisito funcional, no estética.
   → Acción: extraer esos 5 componentes a una carpeta dueña de Ola 1 (p. ej. `lib/core/widgets/`) antes
   de que Ola 2 los replique.

4. **[lib/data/local/mock_repos.dart:31 y :166] Preferencias corruptas = app que no arranca.**
   `currentProfile()` hace `jsonDecode(raw) as Map<String, dynamic>` sin guardar; se ejecuta en `main()`
   (main.dart:15) **antes de `runApp`** → un JSON corrupto (escritura interrumpida por batería baja, cosa
   real en gama baja) tumba la app en el arranque sin ningún mensaje. Además `ChildProfile.fromMap`
   (child_profile.dart:19) exige `id` no nulo → cast exception con prefs viejas/parciales. `load()` de
   ajustes (:166) tiene el mismo problema (aunque ahí la UI al menos muestra AsyncError + reintentar).
   → Acción: try/catch en ambos `load` → devolver `null` / `AppSettings()` por defecto (con log no-PII),
   y defaults tolerantes en `fromMap` para `id`.

---

## MINOR

5. **[lib/features/ajustes/ajustes_screen.dart:77 + settings_controller.dart:18] Crash al mover los sliders de voz en estado de error.**
   `_TtsSection` lee `settingsProvider.value ?? const AppSettings()` y deja los sliders **activos** aunque
   la carga haya fallado (o aún cargando); al arrastrarlos, `setTextScale/setTtsRate` ejecutan
   `state.requireValue` → `StateError` no capturado. Raro pero real (prefs corruptas del punto 4).
   → Acción: deshabilitar los sliders si `settingsProvider` no es `AsyncData`, o guardar con default tolerante.

6. **[lib/features/onboarding/onboarding_screen.dart:26,93] El apodo es obligatorio; el plan lo dice opcional.**
   Plan 00 §5.2: "perfil de niño = apodo local **opcional**". Aquí el botón Comenzar está deshabilitado
   hasta escribir algo, así que una familia que no quiera poner ni apodo no puede entrar a la app.
   → Acción: añadir camino "Entrar sin apodo" (genera perfil con apodo vacío, ya lo soporta el modelo),
   o corregir el plan si la decisión cambió.

7. **[lib/features/onboarding/onboarding_screen.dart:28-33] `_saving` se queda en true si falla el guardado.**
   Si `create()` lanza (fallo de escritura), el `setState(() => _saving = true)` nunca se revierte, el
   botón queda deshabilitado para siempre y sin mensaje de error → pantalla muerta.
   → Acción: try/finally revirtiendo `_saving` + mensaje literal de error ("No se pudo guardar. Inténtalo otra vez.").

---

## Sugerencia

8. **[assets/pictos/muestra/] Sin archivo de licencia en la carpeta.** El crédito en Ajustes
   (ajustes_screen.dart:173-176, "© Mulberry Project — CC BY-SA 4.0") cumple la atribución en la app, y
   los 42 SVG referenciados por el seed existen todos ✔. Falta un `assets/pictos/muestra/LICENCIA.md` con
   fuente + URL de la licencia: CC BY-SA exige enlazarla, y Play lo puede pedir.

9. **[pubspec.yaml:66] `accessibility_tools` declarado pero sin usar.** El plan 09 §80 lo recomienda "oro
   puro para una app AAC" y no hay ni un `AccessibilityTools` en ningún test. → Cablearlo en los tests
   widget (fallar si hay targets <48dp) o quitarlo; como dev_dep no pesa, pero muerto no sirve.

10. **[pubspec.yaml:30-52] Falta `http` como dependencia directa.** El plan 01 lista `http` entre las deps
    a declarar antes de congelar; hoy solo llega transitiva vía `supabase_flutter`. Funciona, pero el
    agente `backend-supabase` tendrá que volver a pedir permiso para tocar pubspec congelado si la
    necesita directa. → Dejar constancia o añadirla ahora.

**Nota (no cuenta como hallazgo):** `app.dart:30-32` aplanla el escalado del sistema a
`TextScaler.linear(media.textScaler.scale(1.0) * appScale)`, lo que descarta escalado no lineal de
accesibilidad de Android 14+. Aceptable para MVP; reconsiderar en la pasada de accesibilidad de Ola 3.

---

## Veredicto

**La Ola 1 NO se considera cerrada todavía (CORRECCIONES), pero está muy cerca.** Lo sólido, sin relleno:
cero datos/nombres reales (grep verificado), cero PII, ningún PIN prometido que no exista (el placeholder
`/padre` dice "se activará con tu PIN" — honesto), placeholders de legales y TTS con alcance honesto,
sin autoplay, sin `print()` ni TODOs, `const` y ListView perezoso bien usados, seeds coherentes con los
modelos y con los assets en disco, y tests que prueban cosas de verdad (no relleno). Los 4 MAJOR son
acotados y con arreglo barato: uno es un color (:194), dos son defensas try/catch en `mock_repos.dart`, y
uno (Drift/persistencia + componentes base) es de decisión de coordinación más que de código. Recomiendo
que base-flutter entregue los FIX de los MAJOR 1, 3 y 4 + MINOR 5-7 de corrido (esfuerzo S), y que el
MAJOR 2 se resuelva como decisión explícita del coordinador antes de que `juegos` y `rutinas-salud`
construyan sobre repos volátiles. Tras eso, la Ola 1 queda APROBADA para abrir Ola 2.
