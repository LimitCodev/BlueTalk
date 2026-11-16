# Rendimiento — juegos

Archivos: `lib/features/juegos/`. Tres juegos con perfiles distintos: memoria
(estado pequeño), cuentos (texto + pictos) y artista (canvas en vivo).

## PERF-JUE-01 · El trazo del artista hace trabajo O(n) por cada punto (P1)

**Dónde** `lib/features/juegos/artista/artista_controller.dart:94`.

En cada `PointerMove`:
1. `_puntosDelDibujo()` recorre todos los trazos terminados y el activo para
   contar puntos (`artista_controller.dart:168`).
2. `state.copyWith(... puntos: [...activo.puntos, nuevo])` **copia la lista
   entera** de puntos del trazo activo.

Con un trazo de 3 000 puntos (el tope), el último movimiento copia 2 999
offsets y cuenta otros 3 000 números. El coste crece al cuadrado con la
duración del trazo. Un trazo normal de 100–300 puntos va bien; un dibujo
insistente empieza a perder fluidez justo cuando el niño más lo disfruta.

**Arreglo pequeño**
- Llevar un contador `_puntosTotales` en el controlador: sumar 1 al añadir y
  restar al deshacer/borrar. El tope se comprueba en O(1).
- Evitar la copia: guardar los puntos en una lista mutable del trazo activo y
  notificar con una nueva instancia **solo cuando termine** el trazo, o usar
  `List.unmodifiable` al pintar y una `List<Offset>` mutable interna.
  Riverpod exige identidad nueva para reconstruir; la capa activa puede
  escuchar un `ChangeNotifier` propio en vez del estado global.
- Alternativa intermedia: copiar solo cada N puntos y añadir el resto en
  bloques; reduce las copias sin cambiar la arquitectura.

**Cómo comprobarlo**
Dibujar un trazo largo (10 s) en perfil y mirar el tiempo de UI por frame.
Test de unidad: `continuarTrazo` 3 000 veces no debe superar un presupuesto
de tiempo y debe cortar exactamente en el tope.

**Riesgo** medio: toca el estado que pinta el lienzo; probar deshacer,
goma, cargar dibujo y guardar.

---

## PERF-JUE-02 · Guardar un dibujo codifica la galería entera en el hilo de UI (P2)

**Dónde** `lib/features/juegos/artista/artista_dibujos.dart:125`.

`_persistir` hace `jsonEncode` de hasta 30 dibujos × 3 000 puntos. En el peor
caso son ~90 000 pares de coordenadas; el string puede superar varios MB y se
construye en el isolate principal. Guardar puede congelar la UI un instante.

**Arreglo pequeño**
- Mover el `jsonEncode` a `Isolate.run` (igual que el PIN) y escribir el
  string resultante. La lista de mapas es transferible.
- Mejor aún: una clave de preferencias por dibujo
  (`bluetalk_dibujo_<id>`), así guardar uno no reescribe los otros 29. El
  listado carga solo ids y miniaturas.
- La carga inicial de la galería también decodifica todo; con claves por
  dibujo se puede cargar bajo demanda.

**Cómo comprobarlo**
Llenar la galería a 30 dibujos con puntos y medir “Guardar”. Verificar que la
animación de la galería no se congela.

**Riesgo** medio: migración de la clave actual; conservar la lectura del
formato viejo una versión.

---

## PERF-JUE-03 · Cada ficha de memoria busca su picto recorriendo la lista (P2)

**Dónde** `memoria_screen.dart:173` (`_Ficha` observa `pictosProvider`) y
`memoria_screen.dart:287` (`_pictoPorId` recorre la lista).

Cada ficha levantada recorre hasta 234 pictos. Con 14–24 fichas y un rebuild
por toque, son unos miles de comparaciones por jugada. No es grave, pero es
gratis de arreglar.

**Arreglo pequeño**
Un provider `pictosPorIdJuegosProvider` que construya
`Map<String, Pictogram>` una vez (o reutilizar `pictosPorIdProvider` de
rutinas, que ya existe y hace lo mismo). `_Ficha` lee el mapa por id.

**Riesgo** bajo.

---

## PERF-JUE-04 · `pictosProvider` vuelve a parsear el catálogo (P1, ver núcleo)

`juegos_catalog.dart` llama a `repo.pictogramsOf` una vez por categoría. Con
el caché de PERF-CORE-03 desaparece. No cambiar la API del provider.

---

## PERF-JUE-05 · Cuentos: claves de pictos por página en cada build (P2)

**Dónde** `cuentos_lector.dart` llama a `pictosClaveDePagina(texto, pictos)`
en cada reconstrucción.

El texto de una página es corto y el número de claves pequeño; el coste es
bajo. Solo se anota: si se añaden cuentos largos, calcular las claves una vez
al abrir la página (`initState`/provider) y no en cada build.

---

## PERF-JUE-06 · Registrar inicio/fin de juego escribe dos JSON (P0, ver núcleo)

`juegos_controller.dart` registra `juego_inicio` y `juego_fin` en cada
entrada/salida, y el artista registra `dibujo_guardado`. Son pocos eventos,
pero comparten el problema de PERF-CORE-01. El arreglo de agrupación beneficia
a los tres juegos.

## Lo que ya está bien en juegos

- El lienzo separa trazos terminados y activo en dos `CustomPaint` con
  `RepaintBoundary`: arrastrar no repinta la galería (`artista_lienzo.dart`).
- El pintor de trazos solo repinta si cambia la identidad de la lista
  (`artista_canvas.dart`), y el grosor se normaliza para que el dibujo se vea
  igual en cualquier pantalla.
- El trazo descarta puntos a menos de 1,5 px: no engorda el path sin aportar.
- La memoria baraja una vez al empezar el nivel y guarda ids, no objetos.
- Los cuentos y los pictos clave están en `FutureProvider` cacheados.
- El límite diario se calcula con eventos locales, sin timers ni servicios.

## Prueba manual sugerida

1. Artista: trazo largo de 10 s, deshacer, goma, guardar y abrir la galería.
2. Memoria: subir de nivel y comprobar que las fichas nuevas no tardan en
   voltearse.
3. Cuentos: avanzar páginas y completar la tarea; sin autoplay de voz.
