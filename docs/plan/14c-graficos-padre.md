# Plan 14C — Gráficos variados en el Modo padre

**Parte de:** `docs/plan/14-menu-mascota-graficos.md` (lee antes su §3).
**Sustituye a:** plan 13 **P5**, que no está hecho (no existen `dona.dart` ni `anillo_progreso.dart`).
Este subplan conserva sus reglas de diseño y añade más tipos de gráfico.
**Objetivo:** que el apoderado vea las estadísticas de su hijo o hija con gráficos agradables y variados.
Hoy solo hay barras y filas de números.

## 1. Lo que hay hoy

| Pantalla | Archivo | Qué muestra |
|---|---|---|
| Resumen (hoy) | `dashboard/resumen_screen.dart` (en `_deuda`, 164) | Filas `FilaMetrica` y `BarraDato` horizontales |
| Informes (semana/mes) | `informes/informes_screen.dart`, `informe_secciones.dart` | Texto, `GraficaColumnas` (pictos por día) y rankings en lista |

**Datos ya disponibles** (no hace falta registrar nada nuevo):

- `Metricas` (hoy): `pictosHoy`, `pictosDistintosHoy`, `pictosPorCategoriaHoy` + `nombresDeCategoria`,
  `sesionesJuegoHoy`, `segundosJuegoHoy`, `dias`/`eventosPorDia` (7 días), `actividadesHechasHoy`/`actividadesHorario`,
  `checkInsSemana`, `cuentosCompletados`, `dibujosGuardados`, `nivelMemoria`.
- `Informe` (semana/mes): `serie` (por día: pictos, segundos de juego, segundos de pantalla), `actual`/`anterior`
  (`Totales`), `categorias`, `pictos`, `apps` (como mucho 5 cada uno), `diasConDatos`, `segundosPantalla`,
  `diasConApps`, `animos` (valor 1–5 → veces).

**Dato que NO existe:** el tiempo por sección (minutos en Comunicar, Aprender o Rutinas).
Por eso **no** se hace la dona «¿En qué usó el tiempo?» del plan 13 P5. Queda anotada como
mejora futura en `decisiones-pendientes.md`: necesita registrar el tiempo en primer plano por pestaña.

## 2. Reglas de diseño (del plan 13 P5, se mantienen)

- Cada gráfico responde **una pregunta en lenguaje humano**, que es su título.
- Debajo del título va un **número grande y una frase** («4 de 6 actividades»).
- Etiquetas junto al dato. Nunca solo color: cada segmento lleva su texto o su icono (por el daltonismo).
- Como mucho 4 gráficos por pantalla sin desplazarse. Tarjetas grandes.
- Aviso fijo al final de cada pantalla: «Información orientativa, no es un diagnóstico».
- Sin datos: el texto «Aún no hay datos. Aparecerán cuando tu hijo o hija use la app.». Nunca un círculo vacío.
- **Animación de entrada** (agradable, no es ruido): 600 ms, `Curves.easeOutCubic`. La dona y el anillo
  se dibujan de 0 al valor; las barras y la línea crecen desde abajo. Con el modo calma o con
  `disableAnimations`, duración 0.
- **Toque:** en la dona, tocar un segmento lo resalta y pone su nombre y su valor en el centro.
  En la línea y en las columnas, tocar un día muestra su valor. Todo es opcional para entender el gráfico.
- `CustomPainter` con `shouldRepaint` correcto y `RepaintBoundary` por gráfico. **Sin paquetes de gráficos.**
- Colores de los tokens (`AppColors`/`context.colores`, colores de categoría). Siguen las 7 paletas y el modo calma.
- `Semantics(label:)` con el dato completo en texto («Rutinas de hoy: 4 de 6, 67 por ciento»).

## 3. Catálogo de gráficos

Carpeta nueva: `lib/features/padre/graficos/`. Un archivo por gráfico, de 100 líneas o menos cada uno.
La geometría va en funciones puras para poder probarla sin pintar.

| # | Archivo | Tipo | Función pura que se prueba |
|---|---|---|---|
| G1 | `tarjeta_grafico.dart` | Marco común: título-pregunta, número grande, frase, gráfico, estado vacío | — |
| G2 | `dona.dart` | Dona con segmentos y total o selección en el centro | `angulosDona(valores) → List<(inicio, barrido)>`, que suma 2π; con 5 o más grupos, los menores se agrupan en «Otras» |
| G3 | `anillo_porcentaje.dart` | Anillo de progreso con el % en el centro | `fraccion(hechas, total)` acotada a 0–1; con total 0 → estado vacío |
| G4 | `medidor.dart` | Semicírculo (medidor) con aguja, para comparar con el periodo anterior | `anguloMedidor(actual, anterior)`: el 50 % es «igual que antes» |
| G5 | `linea_tendencia.dart` | Línea suave con área rellena y punto del último día | `puntosLinea(valores, tamaño)` normaliza al máximo y no divide entre 0 |
| G6 | `calendario_calor.dart` | Cuadrícula de días del mes con intensidad por uso (4 niveles + «sin uso») | `nivelCalor(valor, maximo) → 0..4` |
| G7 | `barra_apilada.dart` | Barra 100 % apilada con caritas (para el ánimo) | `porcentajes(conteos)` suma 100 tras redondear |
| G8 | `tarjeta_kpi.dart` | Número + flecha ▲▼ + «+12 % respecto a la semana pasada» | `variacion(actual, anterior)`: con anterior 0 dice «Nuevo», no infinito |
| — | `informes/grafica_columnas.dart` (existe) | Columnas por día | Se reutiliza y se le añade la animación de entrada y el toque |

## 4. Qué va en cada pantalla

### Resumen (hoy) — `dashboard/resumen_screen.dart`

| Orden | Pregunta (título) | Gráfico | Datos |
|---|---|---|---|
| 1 | ¿Cuántas actividades hizo hoy? | G3 anillo | `actividadesHechasHoy` / `actividadesHorario` |
| 2 | ¿Qué temas usó hoy para comunicarse? | G2 dona | `pictosPorCategoriaHoy` con `nombresDeCategoria`, colores de categoría |
| 3 | Hoy en números | 4 × G8 en cuadrícula de 2×2 (sin flecha: «hoy» no tiene periodo anterior comparable) | pictos, palabras distintas, minutos de juego, sesiones |
| 4 | ¿Cómo fue esta semana? | Columnas, con hoy resaltado | `dias` / `eventosPorDia` |

Después siguen el botón de Informes y el resto de filas que no tienen gráfico (cuentos, dibujos, nivel de memoria),
como tarjetas pequeñas. **`resumen_screen.dart` está en `_deuda` y debe encoger:** las secciones pasan a
`dashboard/resumen_graficos.dart` y `dashboard/resumen_tarjetas.dart`.

### Informes (semana y mes) — `informes/`

| Orden | Pregunta (título) | Gráfico | Datos | Semana | Mes |
|---|---|---|---|---|---|
| 1 | ¿Cómo va comparado con antes? | 3 × G8 con flecha | `actual` frente a `anterior`: pictos, minutos de juego, actividades | ✔ | ✔ |
| 2 | ¿Cuántos días usó BlueTalk? | G3 anillo | `diasConDatos` / `periodo.dias` | ✔ | ✔ |
| 3 | ¿Se comunica más o menos que antes? | G4 medidor | `actual.pictos` frente a `anterior.pictos` | ✔ | ✔ |
| 4 | ¿Cómo cambió la comunicación día a día? | Semana: columnas · Mes: G5 línea | `serie[].pictos` | ✔ | ✔ |
| 5 | ¿Qué días usó la app? | G6 calendario | `serie[].pictos` | — | ✔ |
| 6 | ¿De qué temas habló más? | G2 dona | `categorias` + «Otras» = `actual.pictos − suma(top)` | ✔ | ✔ |
| 7 | ¿Cómo se ha sentido? | G7 barra apilada con caritas + frase («Más veces: tranquilo») | `animos` + `opcionesEmocion` | ✔ | ✔ |
| 8 | ¿Cuánto tiempo jugó? | Columnas de minutos | `serie[].segundosJuego` | ✔ | ✔ |
| 9 | ¿En qué apps pasó el tiempo? | G2 dona | `apps` + `segundosPantalla` | Solo si `diasConApps > 0` (edición directa) | ← |
| 10 | Palabras más usadas | Ranking actual (`lista_ranking.dart`) + barra proporcional | `pictos` | ✔ | ✔ |

- Se mantiene el texto compartible (`informe_texto.dart`): los gráficos no cambian lo que se copia.
- Se mantiene la cabecera «Del … al …» y «Orientativo. No es un diagnóstico».

## 5. Pasos y commits

1. `FEAT: dona y anillo de porcentaje para el panel del adulto`: G1, G2, G3 + tests de geometría,
   del estado vacío y de semántica.
2. `FEAT: medidor, linea, calendario y barra apilada`: G4–G7 + tests.
3. `FEAT: tarjetas con comparacion respecto al periodo anterior`: G8 + test de `variacion` (anterior 0, iguales, bajada).
4. `FEAT: animacion de entrada y toque en las graficas`: en todos, incluida `GraficaColumnas`.
   Test: con el modo calma, un solo `pump` deja el gráfico en su valor final.
5. `REFACTOR: resumen del adulto con graficos`: reorganiza el Resumen según el §4 y encoge su número en `_deuda`.
6. `FEAT: informes semanal y mensual con graficos variados`: reorganiza Informes según el §4.
7. Rendimiento: abrir Informes mensual con 30 días de datos de ejemplo. En el perfil de `integration_test`,
   el cuadro medio no pasa de 16 ms. Sin dispositivo, **NO VERIFICADO**.
8. `DOCS: evidencia de los graficos del adulto`: `docs/informes/14c-evidencia.md` con capturas en claro,
   oscuro y calma, y también sin datos.

## 6. Aceptación

- El Resumen muestra anillo, dona, cuatro números y columnas. Informes, según la tabla del §4.
- Cada gráfico tiene su pregunta, su número grande y su frase. Sin datos, sale el texto amable.
- Las animaciones se apagan con el modo calma y con «Quitar animaciones».
- La suma de la dona es 100 %, el anillo nunca pasa de 100 % y no hay división entre 0.
- `flutter analyze` con 0 problemas y `flutter test` en verde. El dueño valida en el teléfono que
  «se entiende sin leer nada» (**NO VERIFICADO** hasta entonces).
