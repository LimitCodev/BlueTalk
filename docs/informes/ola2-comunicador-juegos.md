# Informe — aac-comunicador + juegos — 2026-10-14

Alcance: entrega **aac-comunicador** (`facac22`, `d588723`, `75b327a`, `4dab357`, `4286101`, `9bd3ee4`, `32bf473`, `aa2131f`, `cd16308`, `801e9d3`, `c02414c`, `78f538f`), entrega **juegos** (`94036dc`, `447b45b`, `6bfeb15`, `2384818`, `6e06de9`, `4ffc92b`) y su **cableado** (`8238214`). Revisión con `git log --stat` + `git show --format=full` por commit y gates ejecutados (no confiados).

Veredicto aac-comunicador: **CORRECCIONES**
Veredicto juegos: **CORRECCIONES**
Veredicto cableado `8238214`: **CORRECCIONES** (sin hallazgos propios; puntos abiertos en «Para el coordinador»)

## Verificación ejecutada

| Gate | Comando / evidencia | Resultado |
|---|---|---|
| Análisis | `flutter analyze` | **No issues found** (HEAD `78fd977`) |
| Tests de las entregas | `flutter test test/comunicador test/juegos test/core test/data test/features test/widget_test.dart` | **111/111 verdes** |
| Suite completa | `flutter test` | 128 pasan / 18 fallan → **todas las fallas en `test/rutinas/` (11) y `test/padre/` (7)**, carpetas WIP ignoradas según encargo. Tras `e91971d` (FIX rutinas, de otro agente) se re-ejecuta al pie |
| Convención de commits | `git show --format=full` de los 18 | `TIPO: español`, ≤70 car., autor `LimitCodev`, sin `Co-Authored-By` ni texto de IA; **1 cambio coherente por commit** |
| `git push` | `git log` | **0** |
| `pubspec.yaml` | `git diff 6c24de1..HEAD -- pubspec.yaml` | solo `http: ^1.6.0` (`pubspec.yaml:53`) → excepción, ver notas |
| Datos reales | `grep` de nombres/teléfonos/emails en `lib/` y `assets/` | **0** |
| PIN/claves en claro | `grep` en `lib/` | **0** (el gate es del modo padre, fuera de alcance) |
| Pictos con `<style>` | `grep` sobre 43 SVG + test `test/data/seeds_test.dart:43` (`c02414c`) | **0** |
| Autoplay | `grep speakText` → solo bajo tap (`speak_action.dart:21`) | **0 autos** |
| Modo calma en juegos | `grep Animated\|Timer` en `lib/features/juegos/` | **0** |
| Trabajo pesado en `build()` | revisión de providers/seeds: carga asíncrona cacheada, `ListView`/`GridView.builder` | **0** |
| `print`/debug | `grep "print("` en `lib/` | **0** |
| Créditos (Mulberry) | `ajustes_screen.dart:296-308` + `LICENCIA-MULBERRY.txt` | **presentes** |
| Targets ≥48 dp / AA | tests a11y de entregas + `46c839f` (AA) | verdes |

Notas de alcance (no son hallazgos):

- **Atribución**: dentro del rango `facac22…78f538f` hay commits de **base-flutter** (`5b61ccb`, `46c839f`, `c619fc1`, `b03673b`, `5eb2733`, `e64a075`) y del revisor (`c48de27`), ajenos a esta entrega; verificados en sus rutas y correctos. También conviven FIX de Fase 0 de otros agentes (`635f578`, `f41e982`, `e6b2dd2`) que cambiaron el estado durante la revisión.
- **`801e9d3` (`pubspec.yaml:53`, `http`)**: NO se trata como BLOCKER. `http` está registrado en `docs/plan/01-base-flutter.md:18` y lo pidió el hallazgo #10 de `docs/informes/ola1-base-flutter.md`. Cruce de auditoría C4: 0 `import` de `http` en `lib/` ni `test/` → dependencia declarada, sin uso. Excepción documentada.
- El hallazgo M1 de `auditoria-general.md` (toques sin límite) quedó **resuelto durante la revisión** por `f41e982` (300 toques + retención 14 días, `mock_repos.dart:270-271`); no se duplica aquí.

## BLOCKER

- Ninguno en ninguna de las dos entregas.

## MAJOR — aac-comunicador

1. `lib/features/comunicador/comunicador_screen.dart:396` y `:473` — `mainAxisExtent: 120` (y `:336` `height: 116` en favoritos) es altura fija que ignora `textScaler`: `bodyMedium` es 16 × `height 1.4` = 22,4 px/línea (`app_theme.dart:34-36`), con 108 px útiles por celda el contenido cabe hasta escala ≈1,12 (categorías), ≈1,16 (pictos) y ≈1,07 (favoritos); el slider «Letra más grande» llega a **1.6** (`ajustes_screen.dart:65-67`) y `app.dart:30-31` multiplica escala de sistema × app. El propio `aa2131f` subió 112 → 120 «para dejar margen con el textScaler del sistema», pero el margen solo cubre ~1,1, no las 1,6 de la app. A partir de esos umbrales las etiquetas nucleares se recortan con `…` (`picto_tile.dart:55-56`, `maxLines: 2`), y los tests corren a escala 1.0, así que no lo detectan. → acción: altura que escale con el texto (o `textScaler` explícito en la rejilla) + test de geometría a escala 1.6.

2. `lib/features/comunicador/saved_messages.dart:49` — `jsonDecode(raw) as List<dynamic>` sin `try`: `Prefs…` corrupto (escritura parcial/esquema viejo) lanza en `build()` del provider y rompe la vista que lo observa (`comunicador_screen.dart:133`), que es una pantalla del niño. El propio equipo ya resolvió el mismo patrón en el artista (`artista_dibujos.dart:83-93`). → acción: envolver en `try/on FormatException` y devolver `const []`.

3. Alcance de commits fuera de las carpetas dueñas (plan 08 §3): `78f538f` toca 7 archivos ajenos (`lib/app/shell.dart`, `lib/app/app_avatar.dart`, `lib/data/models/child_profile.dart`, `lib/features/ajustes/ajustes_screen.dart`, `lib/features/onboarding/profile_controller.dart`, `test/features/**`), `c02414c` toca `assets/pictos/muestra/**` + `test/data/seeds_test.dart`, `cd16308` toca `lib/app/router.dart` + `test/core/**`, `801e9d3` toca `pubspec.yaml`. Verificado: **sin contaminación con las carpetas WIP** (`lib/features/{rutinas,salud,entorno,padre}`, `test/{rutinas,padre}`) y el cableado fue pedido al coordinador. → acción: **registrar la excepción** (rutas y motivo) en el informe de la ola; si no se registra, escala a BLOCKER por «carpetas ajenas → BLOCKER».

## MINOR — aac-comunicador

1. `test/core/accessibility_test.dart:69` (compartido con juegos) — el test del shell solo audita la ruta inicial (`/home/comunicar`, `router.dart:39`): `_CategoryView` (`comunicador_screen.dart:359`) y `_MessagesView` (`:128`), justamente el núcleo del vocabulario, **nunca pasan por el checker**, mientras juegos sí tiene auditoría propia (`test/juegos/accesibilidad_test.dart`). → añadir pasos que abran una categoría y «Mis mensajes».

2. `lib/features/comunicador/comunicador_screen.dart:522-531` con `lib/data/local/mock_repos.dart:286-299` — cada toque de picto re-serializa y escribe en SharedPreferences la lista completa de hasta 300 eventos (`setString` por evento, `unawaited`). No bloquea el toque, pero es escritura a disco por pulsación en gama baja. → acción: agregar/debouncear (p. ej. escribir como máximo 1×/s o al salir).

3. `docs/informes/aac-comunicador.md:5-7` y `:93` — autoinforme contradicho por la propia entrega: «No se tocó ningún archivo fuera de las rutas dueñas» y «`pubspec.yaml` intacto» son falsos tras `cd16308`, `801e9d3`, `c02414c` y `78f538f`. → actualizar el autoinforme con el alcance real y la excepción registrada.

## MAJOR — juegos

1. `lib/features/juegos/artista/artista_dibujos.dart:76` y `:116-121` — el tope es de **50 dibujos**, no de bytes: cada guardado re-escribe en un único string de SharedPreferences todos los trazos de la galería (cada punto es un par de `double`), y el comentario `:73-74` solo asume que «cabe sin drama». Con trazos largos el JSON crece sin límite y la escritura serializa todo en el hilo principal de la app. Además `:90` captura solo `FormatException`: un JSON bien formado con esquema cambiado (`Dibujo.fromMap`, `:60-66`) lanza `TypeError` y rompe la galería. → acción: límite de tamaño (o persistir por archivo/Drift ya pendiente) y ampliar el `catch`.

## MINOR — juegos

1. `lib/features/juegos/artista/artista_screen.dart:44`, `:231`, `:254` — cada `onPanUpdate` muta `artistaProvider` (`artista_controller.dart:95`), con lo que **además del lienzo** se reconstruye `_BarraHerramientas` completa en cada movimiento del dedo. → acción: mantener el trazo activo en estado local (o `select`) y pasar al provider solo al terminar.

2. `docs/informes/juegos.md:6-8` y `:161` — autoinforme desactualizado: «`lib/app` intacto» lo contradice `8238214` (cableado), y el pendiente «cuando el router se cable a `/home/aprender`, verificar con el test de accesibilidad del shell» sigue **sin hacerse** (ver MINOR aac #1) y ya no corresponde como futuro. → actualizar.

3. `test/core/accessibility_test.dart:69` (ambas entregas) — el shell test tampoco navega a `/home/aprender`, así que la pestaña cableada y el `JuegosGate` no pasan por el checker de targets, aunque `test/core/router_test.dart:156,186,215` sí prueba su comportamiento. → recorrer la pestaña en el test del shell.

## Para el coordinador (cableado `8238214` y router)

1. **Cableado verificado**: `router.dart:54` → `ComunicadorScreen`; `router.dart:64-68` → `JuegosGate(juegos: JuegosScreen())`. El gate de límites lo añadió `e6b2dd2` (otro agente) sobre el cableado original, así que **la condición «solo con gate» ya está cumplida** y `test/core/router_test.dart` lo cubre (verdes).
2. **Pendiente de a11y**: añadir al test de `accessibility_test.dart:69` la navegación a Aprender y a una categoría (MINOR aac #1 / MINOR juegos #3).
3. **Decisión de producto, no decidida aquí**: `lib/app/router.dart` no define el comportamiento del botón **Atrás** (`PopScope`) en `/home/aprender` ni en las vistas internas — hoy es el comportamiento por defecto de go_router. Preguntar al usuario: ¿atrás sale de la app, vuelve a Comunicar o lo gestiona el gate? Dejarlo en `docs/informes/decisiones-pendientes.md`.
4. **Registrar la excepción de rutas** de MAJOR aac #3 (`78f538f`, `c02414c`, `cd16308`, `801e9d3`, `8238214`), o los escalaremos a BLOCKER en la re-verificación final.
