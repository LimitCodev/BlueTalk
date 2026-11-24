# Rendimiento — comunicador

Archivos: `lib/features/comunicador/`. El flujo crítico es tocar pictogramas
y ver la frase al instante; todo lo demás es secundario.

## PERF-AAC-01 · El catálogo se recorre entero en cada búsqueda y en cada categoría (P1)

**Dónde**
`lib/features/comunicador/comunicador_catalog.dart:38`: `pictogramsOf` hace
un `for` sobre los 234 pictos cada vez que se pinta una categoría.
`comunicador_resultados.dart` recorre los 234 y hace `toLowerCase()` de
etiqueta y palabras clave **en cada pulsación** del buscador.

**Qué se nota**
Al escribir en el buscador, cada letra reconstruye `HomeContent` (que observa
`comunicadorProvider`) y vuelve a filtrar todo el catálogo. Con 234 pictos no
es dramático, pero asigna cientos de strings por tecla y en gama baja se nota
como un pequeño retraso al teclear.

**Arreglo pequeño**
- En `Catalog`, crear en el constructor:
  `Map<String, List<Pictogram>> _porCategoria` y una lista paralela de
  `_textoBuscable` (etiqueta + keywords ya en minúsculas).
- `pictogramsOf` devuelve `_porCategoria[categoryId] ?? const []`.
- `SearchResults` filtra sobre `_textoBuscable` sin volver a convertir.
- Separar `query` en un provider propio para que `HomeContent` no se
  reconstruya mientras se escribe si no hace falta.

**Cómo comprobarlo**
Test de widget: escribir 5 letras y comprobar que `Pictogram.fromMap` no se
vuelve a llamar (se puede inyectar un repo contador).

**Riesgo** bajo.

---

## PERF-AAC-02 · Guardado de uso en cada toque (P0, ver núcleo)

`onPictoTap` (`comunicador_acciones.dart:27`) registra un `UsageEvent` por
cada picto. Es correcto para el panel del adulto, pero hoy implica dos JSON
completos por toque. El arreglo vive en `01-nucleo...` (PERF-CORE-01); aquí
solo se recuerda que el comunicador es el flujo que más lo sufre.

**No** conviene quitar el registro: de él dependen “pictos distintos en 24 h”,
el panel y las observaciones. Hay que hacerlo barato, no eliminarlo.

---

## PERF-AAC-03 · La barra de frase reconstruye toda la fila por picto (P2)

**Dónde** `phrase_bar.dart` observa `phraseProvider` (lista completa).

Cada picto añadido o quitado reconstruye la barra entera, incluidos los
botones de voz, guardar y borrar. La lista visible es corta (la frase suele
tener < 10 pictos), así que el coste es bajo. Se anota para no convertirlo en
un problema si algún día la frase crece:

- `ListView.builder` horizontal en vez de `Row` con `for`.
- `Selector`/`select` para que el botón de voz no dependa de la lista.

**Riesgo** bajo. No hacerlo ahora.

---

## PERF-AAC-04 · Favoritos: un cambio reconstruye la rejilla visible (P2)

**Dónde** `comunicador_picto_grid.dart:37` observa `favoritesProvider`
(`Set<String>`) y pasa `favorited` a cada tarjeta.

Al fijar o quitar un picto se reconstruyen las tarjetas visibles (unas 12–15),
no las 234. Es aceptable. Si se quiere afinar, cada `PictoTile` puede escuchar
solo su id con `ref.watch(favoritesProvider.select((s) => s.contains(id)))`.

**Riesgo** bajo.

---

## PERF-AAC-05 · SVG: 234 archivos parseados bajo demanda (P2)

**Dónde** `assets/pictos/` (2,1 MB, 234 SVG) y `PictoTile`.

`flutter_svg` cachea el árbol vectorial por ruta, y la rejilla es perezosa,
así que no se cargan los 234 de golpe. Aun así, el primer desplazamiento por
una categoría nueva parsea cada SVG visible. En un equipo de gama baja el
primer frame de cada fila puede notarse.

**Arreglo posible (no urgente)**
- Precompilar los SVG con `vector_graphics_compiler` y usar
  `VectorGraphic`/`svg.cache`. Es una dependencia de desarrollo y un paso de
  build; no cambia la UI.
- O convertir los pictos a PNG/WebP a 2–3 tamaños. Aumenta el APK.

Antes de elegir, medir el tiempo de parseo de un SVG en el equipo objetivo.
No se propone para el próximo APK.

---

## PERF-AAC-06 · “Mis mensajes” reescribe toda la lista al borrar (P2)

**Dónde** `saved_messages.dart:87`.

Guardar o borrar un mensaje serializa todos los mensajes guardados. El número
es pequeño (los que el adulto haya creado), así que no urge. Si se migra a una
base de datos (Drift, plan 02 §6), desaparece.

---

## Lo que ya está bien en el comunicador

- `catalogProvider` carga una vez y mantiene los pictos en memoria; el grid,
  el buscador y los favoritos leen de ahí.
- El tablero nuclear conserva el orden de `order` (memoria motora) sin
  reordenar en cada build.
- La búsqueda muestra una sola vez las palabras repetidas entre categorías.
- La voz solo suena bajo toque; no hay autoplay ni `Timer`.
- El aviso de “sin voz en español” se muestra una vez por sesión
  (`spanishVoiceWarnedProvider`), no en cada picto.
- Las tarjetas usan un `Semantics` claro y un tamaño táctil ≥ 48 dp.

## Prueba manual sugerida

1. Abrir Comunicar y tocar 10 pictos seguidos; la frase debe aparecer sin
   esperar al guardado.
2. Escribir “ca” en el buscador y borrar; no debe parpadear el teclado ni
   perderse el foco.
3. Fijar un picto (mantener pulsado) y comprobar que la fila de favoritos se
   actualiza sin saltos.
