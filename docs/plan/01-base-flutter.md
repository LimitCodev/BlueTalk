# Plan 01 — `base-flutter` (Ola 1, secuencial, esfuerzo XL)

## Progreso (actualizado antes de apagar)

- [x] Scaffold + lints + estructura feature-first (`206bf2d`)
- [x] Design tokens celeste pastel + test contraste AA (`b350f9e`)
- [x] Modo calma: grises, animaciones off, persistente (`132ff14`)
- [x] Shell go_router con 4 pestañas, /onboarding, /home/*, /padre (`b50ad61`)
- [x] Modelos de dominio (los 11) + tests `fromMap`/`toMap` (`c0354cc`, `60729e8`)
- [ ] Contratos + repos mock con seeds (paso 6) y flag `USE_SUPABASE`
- [ ] Onboarding real (paso 7)
- [ ] Ajustes completo: voz TTS placeholder, tamaño de texto, créditos (paso 8)
- [ ] `pubspec.yaml` con TODAS las deps de Olas 2–3 y congelado
- [ ] ⚠️ **Android SDK instalado** — bloquea `flutter run` y el APK (`flutter doctor` lo reporta)

Estado de calidad: `flutter analyze` 0 issues · `flutter test` 32/32 · commits sin push (push por hito).

**Depende de:** aprobación del plan 00.
**Alimenta a:** todos los demás agentes (Ola 2 no empieza hasta que este termine).
**Lee:** `docs/plan/00-PLAN-MAESTRO.md` antes de tocar nada.

## Misión

Dejar un proyecto Flutter **ejecutable, con identidad visual, arquitectura limpia y datos mock** — el cimiento sobre el cual los demás agentes solo añaden features dentro de sus carpetas.

## Alcance detallado

1. **Scaffold**
   - `flutter create` con organización `com.limitcodev.bluetalk`, app `bluetalk`.
   - Lints: `flutter_lints` + reglas extra (`prefer_const_constructors`, `avoid_print`, `unawaited_futures`).
   - Estructura de carpetas idéntica a la sección 7 del plan maestro.

2. **Tema y design system** (`lib/core/theme/`)
   - Tokens de la sección 4 del 00 (celeste pastel), con test unitario que valida contraste AA (≥4.5:1 texto, ≥3:1 UI).
   - Material 3, tipografía sans legible, base 16–18sp, escalable con `textScaleFactor`.
   - Componentes base reutilizables: `BlueButton` (≥48dp), `CardTile`, `SectionHeader`, `EmptyState`, `PictoTile`.

3. **Modo calma** (`lib/core/theme/calm_mode.dart`)
   - Especificación exacta del plan 00 sección 4 (grises por `ColorFiltered`, animaciones a 0, sin autoplay, respeta ajuste del sistema, persistente).
   - Toggle en Ajustes **y** botón visible en el shell principal.
   - Test: al activarlo, `disableAnimations=true` y flag de gris persistido.

4. **Navegación** (`lib/app/router.dart`)
   - go_router con shell fijo (bottom nav predecible): **Comunicar · Aprender · Rutinas · Ajustes**.
   - Rutas: `/onboarding`, `/home/*`, `/padre` (placeholder con gate), rutas placeholder de features para que los demás agentes solo registren su pantalla.

5. **Modelos de dominio** (`lib/data/models/`) — manuales, con `fromMap/toMap` + tests:
   `ChildProfile`, `Category`, `Pictogram`, `Story`, `GameProgress`, `ScheduleEntry`, `MoodEntry`, `HabitEntry`, `UsageEvent`, `AppSettings`, `ObservationRule`.

6. **Contratos y mock** (`lib/data/contracts/` + `lib/data/local/`)
   - Interfaces: `ProfileRepo`, `PictogramRepo`, `StoryRepo`, `GameProgressRepo`, `ScheduleRepo`, `WellbeingRepo`, `UsageRepo`, `SettingsRepo`.
   - Implementaciones mock/Drift con seeds en `assets/seed/` (categorías, 3 cuentos, horario de ejemplo, reglas de observación) → **fuente de verdad del MVP**.
   - Flag `USE_SUPABASE` (default `false`) en `lib/app/di.dart` para enchufar el remoto después sin tocar features.

7. **Onboarding** (`lib/features/onboarding/`): "Tu voz, siempre contigo 💙" → apodo local (sin PII) → home.

8. **Ajustes** (`lib/features/ajustes/`): modo calma, tamaño de texto, voz TTS (rate/pitch, placeholder hasta agente AAC), enlaces a T&C/privacidad (placeholder → agente padre), créditos de pictos.

9. **Calidad:** `flutter analyze` 0 issues, tests de tokens/router/modo calma/modelos en verde.

## Fuera de alcance

Pictogramas reales, juegos, TTS real, Supabase, notificaciones, anything en `lib/features/{comunicador,juegos,rutinas,salud,entorno,padre}`.

## Commits previstos (ejemplos — 1 por cambio)

```
CHORE: proyecto flutter con lints y estructura feature-first
FEAT: design tokens celeste pastel con test de contraste aa
FEAT: modo calma con grises y animaciones desactivadas
FEAT: shell de navegacion con rutas placeholder go_router
FEAT: modelos de dominio con tests frommap tomapping
FEAT: repositorios mock con seeds de categorias y horario
FEAT: onboarding con nombre local sin pii
FEAT: pantalla de ajustes con persistencia de preferencias
```

## Criterios de aceptación

- [ ] `flutter run` en API 24 → onboarding → home → ajustes completo.
- [ ] Activar modo calma grisa TODA la UI y persiste tras reiniciar.
- [ ] `flutter analyze` 0 issues; `flutter test` verde.
- [ ] Seeds cargan y pintan datos de ejemplo en placeholders.
- [ ] `pubspec.yaml` con TODAS las deps de las Olas 2–3 declaradas (para congelarlo): `flutter_riverpod`, `go_router`, `drift`, `sqlite3_flutter_libs`, `path_provider`, `shared_preferences`, `flutter_tts`, `local_auth`, `cryptography`, `flutter_local_notifications`, `timezone`, `supabase_flutter`, `connectivity_plus`, `flutter_svg`, `http`. Lista candidata completa y descartes: `docs/plan/09-stack-paquetes.md`.
