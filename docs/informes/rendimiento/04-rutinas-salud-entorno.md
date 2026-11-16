# Rendimiento — rutinas, salud y entorno

Archivos: `lib/features/rutinas/`, `lib/features/salud/`,
`lib/features/entorno/`.

## PERF-RUT-01 · Los resúmenes leen todos los eventos y se quedan viejos (P1)

**Dónde**
- `rutinas_providers.dart:38` `hechasHoyProvider`.
- `rutinas_providers.dart:150` `resumenUsoProvider`.
- `proximaActividadProvider` depende de ambos.

Cada uno recorre la lista completa de eventos (hasta ~300 toques + 14 días de
juegos/actividades). La primera lectura no es cara porque `PrefsUsageRepo`
cachea la lista, pero se repite al invalidar y **no se refresca al cambiar el
día**: `hechasHoyProvider` usa `DateTime.now()` y solo se invalida al marcar
una actividad. Si la app queda abierta de un día para otro, “hoy” sigue
apuntando a ayer hasta que algo invalide.

**Arreglo pequeño**
- Extraer un `ayerProvider`/`hoyProvider` que emita la clave del día y haga
  que `hechasHoyProvider` dependa de él; al cambiar de día se recalcula solo.
- No hace falta un timer cada minuto: basta con comprobar al volver del
  segundo plano (`AppLifecycleState.resumed`) o al entrar en Rutinas.
- Mantener el filtro actual por `claveFecha` (es O(n) sobre ≤ 500 eventos).

**Cómo comprobarlo**
Test con reloj inyectado: dos consultas con fechas distintas devuelven
conjuntos distintos sin reiniciar la app.

---

## PERF-RUT-02 · `pictosPorIdProvider` reparsea el catálogo (P1, ver núcleo)

`rutinas_providers.dart:24` recorre categorías y llama `pictogramsOf` en
cada una. Es el mismo patrón de PERF-CORE-03; con el caché del repo se
resuelve sin tocar este provider.

---

## PERF-RUT-03 · El editor de horario ordena los 234 pictos en cada build (P2)

**Dónde** `editor_horario_view.dart:196`.

Mientras el diálogo de “nueva actividad” está abierto, cada rebuild hace
`[...pictos.values]..sort(...)`. Son 234 elementos y solo ocurre con el
diálogo abierto; no es crítico. Se puede calcular una vez en un provider
`pictosOrdenadosProvider` o en el `initState` del diálogo.

Además, `quitadasProvider` (`editor_horario_view.dart:324`) espera a
`horarioProvider` y luego vuelve a pedir `schedule()` al repo. El repo ya
tiene la lista en memoria, pero se puede reutilizar la misma lectura.

**Riesgo** bajo.

---

## PERF-RUT-04 · “Velocidad de la voz” duplicada escribe en cada tick (P1)

**Dónde** `salud_screen.dart:244` `_VozRapida`.

Es el mismo slider que `TtsSection` de Ajustes, con otra etiqueta, y persiste
en cada `onChanged` (ver PERF-CORE-02). Además de duplicar la UI, duplica el
coste. La recomendación de producto está en
`docs/informes/redundancias/02-ajustes-y-modos.md`: dejar un solo sitio para
la voz.

---

## PERF-RUT-05 · Recordatorios: reprogramación completa al cambiar el modo calma (P2)

**Dónde** `recordatorios_controller.dart:118`.

Al alternar modo calma se reprograman **todas** las actividades (no solo las
que cambian), porque cada aviso usa un canal con o sin sonido. Con 5–15
actividades son 5–15 llamadas al plugin; ocurre solo al tocar el interruptor.
Es aceptable. Si el horario crece, se puede cambiar solo el canal sin
reprogramar (el plugin no lo permite de forma directa; habría que cancelar y
crear, que es lo actual).

La inicialización del plugin (`FlutterTimezone`, canales) ocurre una vez por
proceso y no bloquea el primer frame.

---

## PERF-RUT-06 · Check-in y hábitos reescriben su lista completa (P2)

**Dónde** `repo_bienestar.dart:51` y `:65`.

Un check-in al día y unos pocos hábitos: el volumen es mínimo. Se anota por
coherencia con PERF-CORE-07, no porque duela.

---

## Lo que ya está bien

- El horario y las actividades usan `ListView.builder`; no se pintan todas
  las filas de golpe.
- `DiaHoySection` y el banner de siguiente actividad comparten providers
  cacheados; no hay dos copias del mismo cálculo.
- Las estadísticas del niño son 7 barras dibujadas con widgets, sin librería
  de gráficas.
- El editor deshabilita en vez de borrar y conserva “actividades quitadas”,
  sin reescribir el seed.
- Los recordatorios usan `inexactAllowWhileIdle` (no exigen permiso de
  alarmas exactas) y solo se reprograman cuando cambia algo.
- La sección de salud muestra el disclaimer siempre visible, sin coste de
  layout reseñable.

## Prueba manual sugerida

1. Dejar la app abierta, cambiar la fecha del emulador al día siguiente y
   entrar en Rutinas: “hechas hoy” debe empezar vacío.
2. Abrir el editor, crear una actividad y comprobar que el selector de pictos
   no tarda en abrir.
3. Activar modo calma y verificar que los avisos siguen programados (sin
   sonido) y que el cambio no congela la UI.
