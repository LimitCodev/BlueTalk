# Informe — aac-comunicador — 2026-10-13

Veredicto (auto-revisión): APROBADO PARA REVISIÓN DEL REVISOR

Alcance entregado: `lib/features/comunicador/**`, `test/comunicador/**`.
No se tocó ningún archivo fuera de las rutas dueñas (verificado con
`git log --stat` por commit).

## Qué se implementó (por commit)

1. `facac22` — `FEAT: estado del comunicador con frase y ajustes locales`
   - `phrase_controller.dart`: frase actual (lista de pictos, estado de
     sesión en provider global) + `phraseText()` para el TTS.
   - `comunicador_prefs.dart`: `speakOnTap` (default ON) y favoritos,
     ambos como `Notifier` persistidos en SharedPreferences (patrón
     `CalmModeController`).
   - `comunicador_controller.dart`: estado de navegación interna
     (inicio / categoría / mis mensajes) + query del buscador.
   - Tests: `test/comunicador/comunicador_estado_test.dart`.

2. `d588723` — `FEAT: servicio tts en español con aviso si falta la voz`
   - `tts_service.dart`: interfaz `TtsSpeaker` (`speak`, `stop`,
     `setRate`, `setPitch`, `hasSpanishVoice`) + implementación real
     `FlutterTtsSpeaker` (flutter_tts, voz del sistema, offline).
   - Idioma: intenta `es-ES`, luego `es-MX`, luego cualquier `es*`;
     cachea la consulta de idiomas. `speak()` corta la locución anterior
     para que mande el último toque. Nunca lanza si el sistema no tiene
     motor TTS. `ttsSpeakerProvider` es sobreescribible (tests usan un
     doble falso `FakeTtsSpeaker` en `test/comunicador/dobles.dart`).
   - `spanishVoiceWarnedProvider`: el aviso de "falta voz en español"
     se muestra una sola vez por sesión.

3. `75b327a` — `FEAT: comunicador con rejillas, barra de frase y lectura`
   - `comunicador_screen.dart`: pantalla única `ComunicadorScreen`
     (ConsumerWidget autocontenido, sin Scaffold propio; el shell pone
     AppBar + NavigationBar). Navegación interna con botón "Volver".
   - `comunicador_catalog.dart`: catálogo (categorías + 42 pictos) en un
     único `FutureProvider` cacheado; grid, buscador y favoritos leen de
     ahí sin recargas.
   - `picto_tile.dart` (SVG + palabra, estrella si favorito),
     `phrase_bar.dart` (altavoz de silencio, frase con X por picto,
     "Borrar todo", "Leer"; literal de vacío:
     "Toca los pictogramas para crear un mensaje..."),
     `speak_action.dart` (hablar bajo tap con rate/pitch de Ajustes).
   - Cada toque de picto registra `UsageEvent(type: 'picto_tap', data:
     {categoryId, pictoId})` en `usageRepoProvider` → alimenta el
     dashboard del modo padre (plan 02 §6).
   - Estados: carga (spinner), vacío (literal), error de assets con
     botón "Reintentar".
   - Tests: `comunicador_screen_test.dart` + `harness.dart`.

4. `4dab357` — `FEAT: buscador de pictogramas y favoritos a inicio`
   - Buscador por palabra sobre el catálogo completo (case-insensitive,
     también keywords), con botón de borrar y literal
     `No hay pictogramas para "X".`
   - Mantener presionado un picto lo fija/desfija en el inicio, con
     estrella, SnackBar de aviso y persistencia; sección "Mis favoritos"
     en fila horizontal lazy + pista literal cuando no hay favoritos.

5. `4286101` — `FEAT: mensajes guardados en preferencias locales`
   - `saved_messages.dart`: modelo `SavedMessage` (texto + pictoIds) y
     controlador persistido en SharedPreferences. **Pendiente de migrar
     a Drift** cuando `lib/data/local` lo soporte (plan 02 §6).
   - Botón "Guardar" en la barra de frase con diálogo de texto editable;
     vista "Mis mensajes" (icono en la cabecera del inicio): tocar un
     mensaje recarga sus pictos en la frase; botón para borrar cada uno;
     estado vacío literal.

6. `9bd3ee4` — `TEST: aviso de voz en español solo la primera vez`
   - Widget test del flujo sin voz en español: SnackBar claro en el
     primer tap, no se repite, y el habla se intenta igual (el motor
     puede tener voz por defecto).

7. Este informe — `DOCS: informe de auto revision aac-comunicador`.

## Estado de analyze y tests

- `flutter analyze lib/features/comunicador test/comunicador` → **0
  issues**.
- `flutter test test/comunicador/` → **19/19 en verde**.
- `flutter test test/comunicador test/features test/data
  test/widget_test.dart` → verde (todo el repo salvo `test/core`).
- OJO para el revisor: en el momento de la auto-revisión `flutter
  analyze` y `flutter test` del repo completo están en rojo por archivos
  **sin commitear de otro agente en paralelo**
  (`test/core/accessibility_helper.dart`, `test/core/accessibility_test.dart`).
  No los toqué (carpeta ajena); mi scope está limpio.

## Checklist plan 08 (auto-aplicada)

1. **Seguridad y datos**: sin nombres ni datos reales, sin PII, sin
   claves. Los pictos son palabras literales (comida, emociones…).
2. **Reglas plan 00**: `pubspec.yaml` intacto; cero `git push`; commits
   en convención `TIPO: descripción` sin texto de IA; solo carpetas
   dueñas.
3. **Calidad**: `flutter analyze` 0 issues en mis rutas; tests en verde;
   `GridView.builder`/`ListView.builder` lazy; `const` donde aplica; sin
   `print()`; nada pesado en `build()`.
4. **Accesibilidad**: targets ≥48dp (botones con
   `minimumSize: Size(64, 48)`; IconButton con su constraint 48 por
   defecto); lenguaje literal en español; sin autoplay (TTS solo bajo
   taps); la navegación interna no rompe el shell ni el router raíz.
5. **Rendimiento**: sin animaciones propias (Modo calma intacto); cero
   red; sin dependencias nuevas.

## Decisiones tomadas (y por qué)

- **Navegación interna en vez de rutas anidadas**: el plan 02 preveía
  `/home/categorias/*`, pero el router raíz es de Ola 1 y no debe
  tocarse. `ComunicadorScreen` gestiona categoría activa en su estado;
  mismo comportamiento para el niño, cero acoplamiento.
- **Catálogo en un solo provider**: una carga de seeds cacheada alimenta
  grid de categorías, grid de categoría, buscador y resolución de
  favoritos/mensajes. Evita N futuros concurrentes en la UI.
- **`FlutterTtsSpeaker.speak()` corta antes de hablar**: en Android,
  toques rápidos encolarían locuciones y el niño oiría frases viejas;
  con `stop()` previo manda siempre el último toque.
- **Aviso de voz ausente pero intento de habla**: si no hay voz en
  español se muestra el SnackBar una vez y se intenta hablar igual (el
  motor puede tener voz por defecto); el niño puede silenciar con el
  altavoz.
- **"Mis mensajes" en SharedPreferences**: no existe Drift todavía (ese
  setup pertenece a Ola 1 en `lib/data/local`). El controlador queda
  aislado en `saved_messages.dart` para migrar a Drift cambiando solo su
  interior.
- **Tests herméticos con `DiskAssetBundle`** (`harness.dart`): en este
  entorno, `flutter test` solo responde el canal `flutter/assets` en el
  primer `testWidgets` de un archivo; los siguientes colgaban en
  `pumpAndSettle`. La solución (leer seeds y SVG del disco con
  dart:io + overrides de DI) deja los tests rápidos y estables. **Útil
  para cualquier agente que escriba widget tests con assets.**

## Desviaciones del plan 02

- **Set de pictos**: sigue siendo la muestra Mulberry (42 SVG, licencia
  en `assets/pictos/muestra/LICENCIA-MULBERRY.txt`); el set completo
  entra cuando Ola 1/el usuario lo apruebe. Los SVGs no usan
  `cacheWidth` (es una optimización de raster); su tamaño está acotado
  por `SizedBox` 52×52 y son vectoriales ligeros.
- **Créditos**: ya están en Ajustes (Ola 1, `_CreditsSection`); no duplico
  esa sección dentro del comunicador.
- **Drift para mensajes**: pospuesto por ownership de `lib/data/local`
  (arriba).
- **"Borrar todo" sin confirmación**: el plan no la pide y una capa más
  de diálogo entorpece el flujo del niño; queda anotado como mejora
  posible.

## Pendientes (para siguientes olas)

- Migrar "mis mensajes" a Drift (`lib/data/local`) y exponerlos también
  al dashboard del modo padre.
- Set completo de pictogramas (reemplazar la muestra) + keywords de
  búsqueda (hoy el seed no incluye sinónimos).
- Cuando el router se cablee a `ComunicadorScreen`, verificar con el
  test de accesibilidad del shell que todos los targets siguen ≥48dp.
- Posible mejora: botón de silenciar/global en el AppBar del shell si el
  modo padre lo pide.
