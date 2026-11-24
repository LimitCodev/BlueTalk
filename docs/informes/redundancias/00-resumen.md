# Auditoría de redundancias — resumen

Fecha: 2026-11-16 · Base: `8ccbcd6` + arreglo local del menú.

## Qué se buscó

1. **Botones que hacen lo mismo** en la misma pantalla o en pantallas que se
   ven a la vez.
2. **Caminos distintos para la misma acción** (botón visible, Atrás del
   sistema, gesto, enlace), sobre todo si se comportan distinto.
3. **Ajustes duplicados** que escriben el mismo estado desde varios sitios.
4. **Código repetido** que multiplica el mantenimiento (cabeceras, guardado
   JSON) aunque no sea un botón.

No se cuentan como redundancia los atajos deliberados a otra pantalla si
están en contextos separados y el plan los pide. Esos se anotan como
“verificado, no tocar”.

## Hallazgos

| # | Qué | Dónde | Nivel | Esfuerzo |
|---|---|---|---|---|
| R-01 | Siete cabeceras “Volver” copiadas | comunicador, juegos, rutinas, salud, estadísticas y editor | P1 | S |
| R-02 | “Salir del modo padre” duplica la X en Legal | `legal_screen.dart:153` + `padre_screen.dart:138` | P1 | S |
| R-03 | Atrás del sistema y “Volver” del cuento van a sitios distintos | `atras_shell.dart:31` vs `cuentos_cabecera.dart:27` | P1 | S |
| R-04 | Modo calma en 5 sitios, dos visibles a la vez | Inicio, shell, Ajustes, Salud, Control | P1 | S |
| R-05 | Velocidad de voz en 2 sliders con etiquetas distintas | Ajustes y “Mi día” | P1 | S |
| R-06 | Modo padre con 3 entradas | menú, Ajustes, final de la guía | P2 | — |
| R-07 | “Uso del teléfono” con 2 entradas | Resumen y Control | P2 | — |
| R-08 | Guardado JSON copiado en 10 archivos | `lib/data/local/`, features | P2 | M |
| R-09 | “Saltar” de la guía (cabecera y confirmación) | `guia_botones.dart` | — | verificado |
| R-10 | Acciones de la barra de frase | `phrase_bar.dart` | — | verificado |
| R-11 | Inicio del shell + Atrás del sistema | `shell.dart`, `atras_shell.dart` | — | verificado |
| R-12 | X del padre + Atrás del sistema | `padre_screen.dart` | — | verificado |
| R-17 | “Volver” de Memoria sale del juego, no sube al selector | `memoria_screen.dart` | P2 | S |
| R-19 | El catálogo de pictos se carga en cuatro sitios | comunicador, juegos, rutinas, informes | P2 | M |

## Orden recomendado

1. **R-03**: es el único que además de duplicar se comporta distinto; el niño
   puede acabar en el sitio equivocado. Arreglo pequeño en `manejarAtras`.
2. **R-17**: el mismo patrón en Memoria (el “Volver” sale del juego en vez de
   subir al selector de niveles). Arreglo local en `MemoriaScreen`.
3. **R-01**: una sola cabecera reutilizable; quita ~120 líneas repetidas y
   unifica el tamaño táctil.
4. **R-02, R-04 y R-05**: quitar controles duplicados. Requieren decisión de
   producto sobre dónde queda el control principal (ver cada documento).
5. **R-06 y R-07**: no tocar; son atajos con contexto distinto.
6. **R-08 y R-19**: deuda de código; R-08 se paga sola cuando se toque el
   guardado por PERF-CORE-01, y R-19 después de PERF-CORE-03.

## Cómo comprobar que no vuelve a pasar

- `test/arquitectura/` puede añadir una regla sencilla: un solo widget de
  cabecera “Volver” (buscar `OutlinedButton.icon` con `chevron_left` fuera de
  `core/widgets/`). No es urgente, pero evita la séptima copia.
- Para los ajustes, un test de widget que abra Ajustes y “Mi día” y compruebe
  que el interruptor de calma aparece una sola vez por pantalla.

## Documentos por área

- `01-navegacion-y-cabeceras.md`
- `02-ajustes-y-modos.md`
- `03-comunicador-y-juegos.md`
- `04-persistencia-y-codigo.md`
