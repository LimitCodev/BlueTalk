# Plan 03 — `juegos` (Ola 2, paralelo, esfuerzo L)

**Depende de:** `base-flutter` (Ola 1 terminada).
**Rutas dueñas:** `lib/features/juegos/**`, `test/juegos/**`.
**Lee:** `docs/plan/00-PLAN-MAESTRO.md`.

## Misión

Reconstruir los 3 juegos de la web (memoria, cuentos, artista) con mejor arquitectura, progreso persistido local y rendimiento en gama baja. Sin animaciones pesadas; respetar Modo calma.

## Alcance detallado

1. **Home de juegos** (`/home/aprende`): tarjetas Memoria 🧠, Cuentos Interactivos, Artista 🎨 + "Avance en juegos" (progreso).

2. **Memoria** (`memoria/`)
   - Tablero de parejas por niveles ("Cada nivel es más difícil 💙"): nivel 1 = 4 pares, sube a 6, 8, 10... con pictos como contenido.
   - Estados: seleccionar nivel → jugar → acierto/fracaso (feedback suave, **sin parpadeos**, sin sonidos estridentes) → completado.
   - Desbloqueo de niveles persistido (`memoria_unlocked` en web → tabla Drift).

3. **Cuentos interactivos** (`cuentos/`)
   - Lista de 3 cuentos seed (ya en `assets/seed/` desde Ola 1).
   - Lector con páginas, picto clave por página y tarea "¡Completar cuento!" / "¡Cuento completado! 🎉" (arrastrar o tocar el elemento faltante — mecánica simple, literal).
   - Progreso persistido (`bt_completed_stories` en web → Drift).

4. **Artista** (`artista/`)
   - Lienzo con `CustomPainter` (NO librería externa): pinceles de color de la paleta pastel, grosor, goma, deshacer, guardar en galería local (sin subir a ningún lado).
   - Input táctil responsivo; sin lags en API 24 (repintado eficiente, solo el path modificado).

5. **Avance en juegos** (`estadisticas_juegos.dart`)
   - Resumen local: niveles superados, cuentos completados, dibujos guardados (recharts → reemplazado por barras simples hechas en Flutter, **se elimina la dependencia de gráficas pesadas**).

6. **Integración:** cada sesión de juego → `UsageRepo.log` (dashboard padre). Duración de sesión medida con reloj simple (no timers agresivos).

## Fuera de alcance

Online/multiplayer, premios con dinero, sección Premium, sonsorería de sonidos (solo tonos suaves puntuales).

## Commits previstos (ejemplos)

```
FEAT: home de juegos con tarjetas y avance
FEAT: juego memoria con niveles desbloqueables
FEAT: progreso de cuentos y desbloqueo persistido en drift
FEAT: cuentos interactivos con tarea completar cuento
FEAT: artista con custompainter y guardar en dispositivo
FEAT: avance en juegos con barras nativas sin graficas pesadas
FIX: lags en el lienzo del artista en dispositivos lentos
TEST: desbloqueo de nivel memoria persiste tras reiniciar
```

## Criterios de aceptación

- [ ] Los 3 juegos completos y jugables offline.
- [ ] Progreso persiste tras reiniciar la app.
- [ ] Modo calma: sin animaciones de transición/parpadeo en los juegos (feedback por estado, no por flash).
- [ ] Sin librerías de animación pesadas; `flutter analyze` 0 issues; tests en verde.
- [ ] Juego memoria en API 24 sin tirones (60 fps en interacción básica).
