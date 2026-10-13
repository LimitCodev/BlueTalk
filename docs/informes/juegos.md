# Informe — juegos — 2026-10-13

Veredicto (auto-revisión): APROBADO PARA REVISIÓN DEL REVISOR

Alcance entregado: `lib/features/juegos/**`, `test/juegos/**`.
No se tocó ningún archivo fuera de las rutas dueñas (verificado con
`git show --stat` por commit); `pubspec.yaml`, `lib/app`, `lib/core` y
`lib/data` intactos. Cero `git push`.

## Qué se implementó (por commit)

1. `94036dc` — `FEAT: home de juegos con tarjetas y avance`
   - `juegos_screen.dart`: único widget público `JuegosScreen`
     (ConsumerWidget autocontenido, sin Scaffold; el shell pone
     AppBar/NavigationBar). Navegación interna (inicio / memoria /
     cuentos / artista) sin rutas go_router, patrón del comunicador.
   - `juegos_controller.dart`: vista activa + registro `juego_inicio` /
     `juego_fin` con duración en segundos (`UsageRepo`, plan 03 §6).
   - `avance_juegos.dart`: sección "Avance en juegos" con
     `BarraAvance` hecha en Flutter (track + `FractionallySizedBox`,
     con semántica; sin librerías de gráficas, plan 03 §5).
   - `juegos_catalog.dart`: providers cacheados de pictos y cuentos
     seed (una sola carga de assets para los 3 juegos).
   - Tests: `harness.dart` (DiskAssetBundle + seeds del disco, patrón
     aac-comunicador) + `juegos_home_test.dart`.

2. `447b45b` — `FEAT: juego memoria con niveles desbloqueables`
   - Nivel 1 = 4 parejas y sube de 2 en 2 (hasta 9 niveles / 20
     parejas dentro de los 42 pictos de la muestra). Pictos elegidos
     al azar y barajados por nivel.
   - Feedback por estado, sin parpadeos: acierto = borde/fondo verde
     permanente, fallo = borde rojo hasta el siguiente toque.
   - Literal del plan: "Cada nivel es más difícil 💙" en el selector;
     niveles bloqueados apagados con candado.
   - Desbloqueo persistido en `GameProgressRepo` (`gameId: 'memoria'`)
     y evento `nivel_completado` para el dashboard del modo padre.

3. `6bfeb15` — `FEAT: cuentos interactivos con tarea completar cuento`
   - Lista de los 3 cuentos seed (estrella "Cuento completado" en la
     lista), lector de páginas con picto clave por página
     (`pictosClaveDePagina`: palabra del texto que coincide con una
     etiqueta de picto; fallback al picto de portada).
   - Tarea "¡Completar cuento!": la última página con un hueco y 3
     opciones táctiles sorteadas **una sola vez** al entrar en la fase
     (no saltan tras cada toque, importante para el usuario objetivo).
     Error = borde rojo en la opción tocada hasta acertar; acierto =
     "¡Cuento completado! 🎉".
   - Progreso por cuento en `GameProgressRepo` con `gameId:
     'cuentos:<id>'` (level = página más alta, stars = completado);
     re-leer un cuento no borra su estrella. Evento
     `cuento_completado`.

4. `2384818` — `FEAT: artista con custompainter y guardar en dispositivo`
   - `artista_canvas.dart`: dos pintores apilados en un `Stack` con
     `RepaintBoundary` — `TrazosPainter` (trazos terminados, repinta
     solo si cambia la lista) + `TrazoActivoPainter` (solo el trazo en
     curso). Arrastrar el dedo repinta únicamente un path, sin lag en
     API 24 (test unitario de `shouldRepaint` incluido).
   - Paleta pastel de 8 pinceles con nombre literal, grosor
     fino/medio/grueso, goma (trazos en color de fondo), deshacer
     (pila) y guardar.
   - Puntos normalizados 0–1 (y grosor en espacio de referencia 1000):
     un dibujo guardado se ve igual en cualquier pantalla y en las
     miniaturas. Sin puntos pegados (<1.5px) para no engordar el path.
   - Galería local "Mis dibujos" con miniaturas (mismo pintor),
     tocar carga el dibujo para seguir editando, borrar por dibujo.
     Persistencia en SharedPreferences (JSON) con tope de 50 dibujos.
     Evento `dibujo_guardado`.

5. `6e06de9` — `TEST: auditoría de accesibilidad de las pantallas de
   juegos`
   - `expectSinProblemasDeAccesibilidad` sobre el selector de memoria,
     la lista de cuentos, el home y el artista (targets ≥48dp).
   - Recorrido completo de los 3 juegos con
     `MediaQuery.disableAnimations` (espejo exacto de la raíz en Modo
     calma, plan 00 §4): sin animaciones propias en los juegos.

6. Este informe — `DOCS: informe de auto revision juegos`.

## Estado de analyze y tests

- `flutter analyze` (repo completo) → **0 issues**.
- `flutter test test/juegos/` → **19/19 en verde**.
- `flutter test` (repo completo) → **103/103 en verde** al cerrar.

## Checklist plan 08 (auto-aplicada)

1. **Seguridad y datos**: sin nombres ni datos reales, sin PII, sin
   claves. Pictos y cuentos son contenido literal de los seeds.
2. **Reglas plan 00**: `pubspec.yaml` intacto; cero `git push`; 6
   commits en convención `TIPO: descripción` (español, sin punto, sin
   texto de IA); solo carpetas dueñas.
3. **Calidad**: `flutter analyze` 0 issues; tests en verde;
   `ListView.builder`/`GridView` lazy, `const` donde aplica, sin
   `print()`, nada pesado en `build()` (el repintado del artista está
   fuera del árbol de widgets vía `shouldRepaint`).
4. **Accesibilidad/autismo**: targets ≥48dp auditados con
   `accessibility_tools` en home, memoria, cuentos y artista; lenguaje
   literal en español ("Cada nivel es más difícil 💙", "Toca la
   imagen que falta."); sin TTS ni autoplay en juegos; navegación
   interna que no rompe el shell ni el router raíz.
5. **Rendimiento gama baja**: sin animaciones propias; feedback por
   estado (colores fijos), no por flash; artista con dos capas y
   `RepaintBoundary`; cero red; sin dependencias nuevas.

## Decisiones tomadas (y por qué)

- **Navegación interna en vez de rutas anidadadas**: mismo porqué que
  el comunicador; el router raíz es de Ola 1 y no debe tocarse.
  `JuegosScreen` cambia de vista según `juegosProvider`.
- **Artista guardado en SharedPreferences, no Drift**: `lib/data/local`
  (Drift) pertenece a Ola 1 y aún no expone tablas de dibujos. La
  galería queda aislada en `artista_dibujos.dart` (contrato de lista
  de trazos + JSON) para migrar a Drift cambiando solo su interior,
  igual que "mis mensajes" del comunicador. Anotado como pendiente.
- **Progreso de cuentos con `gameId` por cuento** (`cuentos:<id>`):
  `GameProgress` solo tiene `level`/`stars`, así que cada cuento usa
  su propia fila (level = página, stars = completado). El resumen del
  home cuenta los `stars > 0`.
- **Pareja fallida no se voltea sola**: tras dos toques distintos las
  fichas quedan con borde de error hasta el siguiente toque. Sin
  timers ni parpadeos; más predecible para el usuario objetivo y muy
  simple de testear.
- **Opciones de "completar cuento" sorteadas al entrar en la fase**:
  si se re-sorteasen en cada rebuild, las opciones saltarían bajo el
  dedo del niño tras tocar mal. El sorteo vive en el estado.
- **Goma = pintar con color de fondo**: deshacer funciona igual para
  goma y pincel con una sola pila; sin máscaras ni blend modes
  (gama baja).
- **Tests herméticos con `DiskAssetBundle`** (`test/juegos/harness.dart`):
  misma solución que aac-comunicador para el problema del canal
  `flutter/assets` de `flutter test`.

## Desviaciones del plan 03

- **`/home/aprende`**: la ruta la cablea el agente principal en
  `lib/app/router.dart`; la entrega expone solo `JuegosScreen`.
- **Drift**: el plan preveía tablas Drift para progreso; los contratos
  de Ola 1 ya dan `GameProgressRepo` persistente (SharedPreferences
  por dentro) y la feature solo ve el contrato. La migración real a
  Drift es de `lib/data/local` (dueño: Ola 1), no de esta feature.
- **"Estadísticas de juegos" (`estadisticas_juegos.dart`)**: no existe
  ese nombre de archivo; la avance vive en `avance_juegos.dart` con el
  mismo contenido (barras nativas hechas en Flutter).
- **Nº de niveles del memoria**: el plan no fija tope; se eligieron 9
  (20 parejas máx., dentro de los 42 pictos). Subir el tope = cambiar
  `memoriaMaxNiveles` y asegurar suficientes pictos.
- **TTS en juegos**: fuera de alcance (el plan 03 no lo pide).

## Pendientes (para siguientes olas)

- Migrar la galería del artista y el progreso de juegos a Drift
  (`lib/data/local`), exponiendo también los eventos al dashboard del
  modo padre cuando ese agente lo pida.
- Sonidos suaves puntuales de acierto (plan 03, "fuera de alcance"
  salvo tonos suaves): hoy es solo feedback visual.
- Set completo de pictogramas: cuando entre el set aprobado, revisar
  que el memoria de 9 niveles siga teniendo suficientes pictos y que
  `pictosClaveDePagina` siga resolviendo bien los textos de los
  cuentos.
- Cuando el router se cable a `/home/aprender`, verificar con el test
  de accesibilidad del shell que la pestaña sigue limpia.
