# Redundancias — comunicador y juegos

Dos flujos con muchos botones: la barra de frase y las barras de juego. Aquí
se revisa si dos controles hacen lo mismo, si el mismo texto lleva a sitios
distintos y si hay código que carga lo mismo dos veces.

## R-10 · Barra de frase: las acciones son distintas (verificado, no tocar)

`lib/features/comunicador/phrase_bar.dart`.

| Control | Qué hace | ¿Se pisa con otro? |
|---|---|---|
| Icono altavoz | Enciende/apaga “hablar al tocar un picto” | No: es un modo, no una lectura |
| X de cada picto | Quita **ese** picto de la frase | No: “Borrar todo” vacía la frase |
| `Borrar todo` | Vacía la frase completa | No: la X quita uno a uno |
| `Guardar` | Abre diálogo para guardar en Mis mensajes | No |
| `Leer` | Pronuncia la frase completa | No: hablar-al-tocar dice una palabra |
| `Guardar` del diálogo | Confirma el guardado | Es el segundo paso del mismo flujo |

Tocar un picto agrega y (si está activo) habla su etiqueta; `Leer` habla la
frase entera. Son acciones diferentes y el plan 02 §4 las pide. **No unificar.**

Un detalle de consistencia, no de duplicado: `Borrar todo` de la frase se
ejecuta con **un** toque, mientras el `Borrar todo` del artista pide **dos**
(`artista_barra.dart:16`). En AAC, un toque accidental puede borrar el mensaje
que el niño estaba construyendo. No se propone cambiarlo ahora (el doble toque
añadiría fricción al uso normal), pero conviene decidirlo con el dueño y, si se
cambia, hacerlo igual en los dos sitios.

## R-17 · En Memoria, “Volver” sale del juego en vez de subir al selector (P2, S)

**Dónde** `lib/features/juegos/memoria/memoria_screen.dart:110` y
`lib/features/juegos/juegos_screen.dart:128`.

La cabecera `CabeceraJuego('Memoria')` siempre llama a
`juegosProvider.notifier.irAlInicio()`. Pero Memoria tiene dos subvistas:
selector de niveles y tablero. Estando en el tablero, “Volver” va al inicio de
Aprender, no al selector. El único camino visible al selector es terminar el
nivel (`Elegir otro nivel`, línea 274) o salir y volver a entrar.

En Cuentos, en cambio, “Volver” sube un nivel (lector → lista) y solo desde la
lista sale a Aprender. Dos juegos, dos comportamientos para la misma etiqueta.

**Fix pequeño**
En `MemoriaScreen`, cuando `value.enTablero` sea verdadero, mostrar una
cabecera cuyo “Volver” llame a `memoriaProvider.notifier.volverAlSelector()`;
cuando esté en el selector, dejar la de `JuegoVista.inicio`. Es el mismo
patrón que ya usa `CuentosScreen` con `CabeceraCuentos`/`CabeceraJuego`.

**Riesgo** bajo. Test: empezar un nivel, pulsar “Volver” y comprobar que se ve
el selector (“Cada nivel es más difícil”), no las tarjetas de Aprender.

## R-18 · Cuentos: “Volver” y Atrás del sistema no coinciden (P2, ya cubierto en R-03)

La cabecera del lector va a la lista (`cuentos_cabecera.dart:27`); el Atrás del
sistema va al inicio de Aprender (`atras_shell.dart:31`). El arreglo está en
`01-navegacion-y-cabeceras.md` (R-03). Se repite aquí solo para que quien lea
este módulo lo vea: **no aplicar dos arreglos distintos**.

## R-19 · El mismo catálogo de pictos se carga en tres o cuatro sitios (P2, M)

**Dónde**
- `lib/features/comunicador/comunicador_catalog.dart` — `Catalog` (categorías
  + 234 pictos + índice por id).
- `lib/features/juegos/juegos_catalog.dart` — `pictosProvider` (los temáticos,
  sin el nuclear).
- `lib/features/rutinas/rutinas_providers.dart:24` — `pictosPorIdProvider`.
- `lib/features/padre/informes/informes_providers.dart:27` — mapa de nombres.

Cada uno recorre las categorías y llama a `pictogramsOf`, que vuelve a
convertir las 234 filas del seed. No es que haya cuatro copias en memoria a la
vez (los providers viven lo que vive su pantalla), pero sí cuatro formas de
construir lo mismo y cuatro oportunidades de que una quede distinta.

**Fix pequeño**
Un solo provider de catálogo completo en `lib/data/local` o en un provider
compartido, y que los cuatro lean de él:
- `Catalog` se queda como la vista del comunicador.
- Juegos filtra por `!categoria.nuclear` sobre la misma lista.
- Rutinas e informes usan el índice `id → Pictogram` ya construido.

Se solapa con PERF-CORE-03 (caché en `SeedPictogramRepo`): si se hace primero
el caché del repo, este cambio puede esperar. **No hacer los dos a la vez.**

**Riesgo** medio: toca providers que varias pantallas observan.

## R-20 · Juegos: “Jugar nivel N+1” y “Elegir otro nivel” (verificado, no tocar)

En el panel de nivel completado (`memoria_screen.dart:265`) hay dos botones:
uno empieza el nivel siguiente y otro vuelve al selector. Son destinos
distintos y el plan 03 §2 pide ambos. No hay un tercer botón que haga lo mismo
en esa pantalla.

Lo mismo en Artista (`artista_barra.dart`): `Deshacer`, `Guardar` y
`Borrar todo` son acciones distintas; `Borrar todo` pide confirmación en el
propio botón y cualquier otra acción la cancela. `Mis dibujos` abre la galería
en una hoja inferior; dentro, tocar una miniatura carga el dibujo y el icono de
papelera borra **ese** dibujo. Cargar y borrar no se pisan.

## R-21 · “Mis mensajes”: tocar carga, papelera borra (verificado, no tocar)

`comunicador_mensajes_view.dart`: el `ListTile` entero carga el mensaje en la
barra de frase y el icono de papelera lo elimina. Son dos zonas con acciones
distintas; el texto de la papelera tiene tooltip “Borrar mensaje”. No hay botón
“Leer” en la lista: para oírlo hay que cargarlo y pulsar `Leer`. Es coherente
con “la voz solo suena bajo toque”, aunque añade dos pasos; no es una
redundancia.

## Resumen de acciones

| Acción | Archivos | Prioridad |
|---|---|---|
| “Volver” de Memoria al selector cuando hay tablero | `memoria_screen.dart` | P2 |
| Unificar la carga del catálogo (tras PERF-CORE-03) | 4 providers | P2 |
| Atrás de Cuentos (R-03) | `atras_shell.dart` | P1 (en el otro doc) |
| No tocar barra de frase, botones de nivel ni Mis mensajes | — | verificado |
