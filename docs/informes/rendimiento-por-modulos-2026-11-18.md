# Rendimiento por módulos — revisión del 18 de noviembre de 2026

**Base:** `5dc52c0` + árbol de trabajo sin commitear.  
**Método:** lectura del código actual, contraste con la auditoría del 16-nov (`docs/informes/rendimiento/`) y revisión de los arreglos que ya están en el árbol.  
**Límite honesto:** aquí no hay mediciones nuevas en teléfono físico. Lo que se afirma como “corregido” está en el código y pasa la suite; lo que depende de un dispositivo queda como **NO VERIFICADO**.

> Este documento no dice que la app “vaya lenta”. Dice **dónde puede perder fluidez, memoria o disco**, cuánto importa y cómo comprobarlo. La app no envía datos ni tiene analítica: todo el coste es local.

---

## 1. Resumen ejecutivo

- La auditoría del 16-nov encontró **10 arreglos de alto rendimiento**. A fecha de hoy, **5 están corregidos en el árbol de trabajo pero sin commitear** (el P0 de almacenamiento, el P0 de ajustes mitigado, el catálogo, el TTS y la guía). Además, el reparseo del catálogo en Informes quedó resuelto como efecto secundario del caché.
- **Siguen abiertos 5 de los 10:** el trazo del artista (O(n²)), el `Path` de la guía por fotograma, la captura de 9 días de Android al abrir Informes, las métricas viejas del panel y el guardado de la galería en el hilo de UI (P2).
- El riesgo más importante para el niño ya está mitigado: **tocar pictogramas varias veces por segundo** ya no escribe dos JSON completos por toque. Queda un caso de pérdida máxima de **2 segundos de métricas** si el proceso muere sin pasar por pausa; es un intercambio deliberado, no un fallo oculto.
- El riesgo más importante para el adulto es **abrir Informes en un equipo lento**: en el primer uso puede encadenar hasta 9 consultas nativas de uso de apps antes de pintar. No se ha medido.
- El rendimiento en **gama baja sigue sin medirse**. El dato de 39,4 ms/fotograma del informe mensual es de un emulador con SwiftShader y **no representa** al teléfono objetivo.

### Estado por módulo

| Módulo | Entradas | P0 | P1 | P2 | Estado global |
|---|---:|---:|---:|---:|---|
| Núcleo, arranque y almacenamiento | 7 | 2 | 2 | 3 | 2 P0 corregidos o mitigados y 2 P1 corregidos en árbol; 3 P2 pendientes |
| Comunicador | 6 | 1 | 1 | 4 | P0 corregido; P1 parcial; 4 P2 pendientes |
| Juegos | 6 | 1 | 2 | 3 | 1 P1 y 3 P2 pendientes; 1 P1 y 1 P0 compartidos corregidos |
| Rutinas, salud y entorno | 6 | 0 | 3 | 3 | 2 P1 pendientes; 3 P2 pendientes; 1 P1 compartido corregido |
| Modo padre | 6 | 0 | 4 | 2 | 1 P1 parcial; 3 P1 y 2 P2 pendientes |
| Inicio y guía | 6 | 0 | 2 | 2 | 1 P1 corregido; 1 P1 y 2 P2 pendientes |
| Android y release | 4 | 0 | 0 | 3 | Sin cambios; assets y Baseline Profile pendientes |

Las entradas incluyen cruces: `PERF-AAC-02`, `PERF-JUE-06`, `PERF-JUE-04`, `PERF-RUT-02` y `PERF-PAD-03` remiten al núcleo. **No son 41 causas distintas.** Ajustes y onboarding no tienen documento propio: sus costes caen en núcleo (arranque y sliders) e inicio (primer frame).

---

## 2. Núcleo, arranque y almacenamiento

Archivos principales: `lib/main.dart`, `lib/app/`, `lib/data/local/`, `lib/core/`.

### PERF-CORE-01 · Dos JSON completos por cada evento de uso — P0

| Campo | Detalle |
|---|---|
| Dónde | `lib/data/local/repo_uso.dart:27,64-81`; `lib/features/padre/informes/resumenes_repo.dart` (lote de 100) |
| Estado | **Corregido en árbol, sin commit** |
| Qué se notaba | Cada picto tocado escribía la lista completa de hasta 300 eventos y, además, el resumen del mes. En una ráfaga infantil eran decenas de escrituras por minuto. |
| Arreglo aplicado | `PrefsUsageRepo` agrupa escrituras cada 2 s y vuelca con `flush()` al pasar a segundo plano o al leer. `ResumenesRepo.sumar` acumula y escribe cada 100 eventos. |
| Verificación | `test/padre/informes/resumenes_test.dart:135` comprueba que un lote escribe el mes una vez, no por toque. `test/data/usage_repo_test.dart` conserva la retención. |
| Riesgo residual | Si Android mata el proceso sin `onPause`, se pierden hasta 2 s de métricas. No afecta a configuración, frases ni dibujos. |

### PERF-CORE-02 · Los sliders guardan y reconstruyen toda la app en cada tick — P0

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/ajustes/settings_controller.dart:9-51`; `lib/app/app.dart:57-68` |
| Estado | **Corregido en lo esencial:** ya no escribe en disco por tick; la voz tampoco reconstruye la raíz. El tamaño de letra sigue reconstruyendo la raíz para la vista previa en vivo, que es el precio de verlo mientras se mueve el dedo. |
| Qué se notaba | Mover el tamaño de letra o la voz guardaba el JSON en cada píxel y reconstruía `MaterialApp.router` entero. |
| Arreglo aplicado | `previewTextScale` / `previewTtsRate` cambian solo el estado en memoria; `onChangeEnd` llama a `guardarCambios()`. La raíz usa `select` para escala y tema, y cachea el `ThemeData` por paleta. |
| Verificación | No hay test específico de “una escritura por gesto”; la suite funcional de Ajustes pasa. Conviene añadir un contador de escrituras como el de `resumenes_test.dart`. |

### PERF-CORE-03 · El catálogo reparsea los 234 pictos una vez por categoría — P1

| Campo | Detalle |
|---|---|
| Dónde | `lib/data/local/repo_contenido_seed.dart:14-53`; `lib/features/comunicador/comunicador_catalog.dart:14-45` |
| Estado | **Corregido en árbol** |
| Qué se notaba | `pictogramsOf` leía y convertía los 234 pictos en cada categoría; el catálogo hacía lo mismo otra vez. |
| Arreglo aplicado | `SeedPictogramRepo` convierte una sola vez y guarda índices por categoría e id. `Catalog` construye su propio índice categoría → lista. |
| Verificación | El grid y el buscador siguen pasando; no hay test que cuente `Pictogram.fromMap`. Se puede añadir con un repo contador. |

### PERF-CORE-04 · Cada picto reaplica velocidad y tono al TTS — P1

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/comunicador/tts_service.dart:21-23,106-121` |
| Estado | **Corregido en árbol** |
| Qué se notaba | Dos llamadas nativas (`setSpeechRate`, `setPitch`) por cada picto, aunque el valor no hubiera cambiado. |
| Arreglo aplicado | Se cachean `_rateAplicada`, `_pitchAplicado` y `_idiomaAplicado`; solo se llama al canal si el valor cambió. |
| Verificación | `test/comunicador/tts_service_test.dart` cubre el contrato, no el número de llamadas. Añadir un doble que cuente llamadas es barato. |

### PERF-CORE-05 · Arranque: preferencias, perfil y PIN antes del primer frame — P2

| Campo | Detalle |
|---|---|
| Dónde | `lib/main.dart:32-53` |
| Estado | **Pendiente** |
| Qué se notaba | `main()` espera a `SharedPreferences`, al perfil y al almacén del PIN antes de `runApp`. En un equipo lento se alarga la pantalla nativa de lanzamiento. |
| Arreglo posible | Pintar la app con un estado de carga y resolver perfil/PIN en segundo plano; o cachear el perfil en memoria. No urgente: no hay medición de arranque en frío. |
| Cómo comprobar | `flutter run --profile` en gama baja; medir tiempo hasta el primer frame con 0 y con 300 eventos. |

### PERF-CORE-06 · Filtro de calma a pantalla completa — P2

| Campo | Detalle |
|---|---|
| Dónde | `lib/app/app.dart:88-91`; `lib/core/theme/calm_mode.dart:7` |
| Estado | **Pendiente** |
| Qué se notaba | `ColorFiltered` envuelve todo el árbol; en modo calma cada fotograma pasa por un filtro de saturación. Es el modo que se usa para reducir estímulos, no el flujo rápido. |
| Arreglo posible | Aplicar colores grises desde la paleta (`AppColors`) en vez de filtrar la pantalla completa. Requiere revisar todos los widgets y assets. |
| Cómo comprobar | Perfilar con modo calma encendido y apagado en la misma pantalla; comparar “raster” y “paint”. |

### PERF-CORE-07 · Persistencia JSON repetida en siete sitios — P2 (deuda)

| Campo | Detalle |
|---|---|
| Dónde | `repo_bienestar.dart:51,65`; `repo_horario.dart:49`; `repo_progreso_juegos.dart:42`; `repo_ajustes.dart:32`; `repo_perfil.dart:32`; `artista_dibujos.dart:126` |
| Estado | **Pendiente** |
| Qué se notaba | Cada cambio reescribe la lista completa. El volumen es pequeño (un check-in al día, pocos hábitos, un perfil), así que hoy no duele. |
| Arreglo posible | Una clave por elemento o una base de datos (Drift) cuando el plan 02 lo justifique. No hacerlo solo por rendimiento. |

---

## 3. Comunicador

Archivos: `lib/features/comunicador/`. Es el flujo que más usa el niño: tocar pictos y oír la frase.

### PERF-AAC-01 · El catálogo se recorre entero en cada búsqueda — P1

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/comunicador/comunicador_resultados.dart:16-26` |
| Estado | **Parcial:** el índice por categoría y el caché del repo ya están; la búsqueda sigue bajando a minúsculas 234 etiquetas y palabras clave por cada tecla |
| Qué se notaba | Al escribir en el buscador, cada letra asigna cientos de strings y filtra todo el catálogo. Con 234 pictos no es dramático, pero en gama baja se nota un pequeño retraso. |
| Arreglo posible | Guardar en `Catalog` una lista paralela de texto ya normalizado (`etiqueta + palabras clave`) y filtrar sobre ella. |
| Cómo comprobar | Test de widget con un repo contador: escribir 5 letras no debe volver a llamar a `Pictogram.fromMap`; medir el tiempo de cada pulsación en perfil. |

### PERF-AAC-02 · Guardado de uso en cada toque — P0 (cubierto por CORE-01)

- **Estado:** corregido por el agrupado de `PrefsUsageRepo`.
- No conviene quitar el registro: de él dependen “pictos distintos en 24 h”, el panel y las observaciones.

### PERF-AAC-03 · La barra de frase reconstruye toda la fila por picto — P2

- **Dónde:** `phrase_bar.dart`.
- **Estado:** pendiente, aceptable.
- La frase suele tener menos de 10 pictos. Si crece: `ListView.builder` horizontal y `select` para que el botón de voz no dependa de la lista.

### PERF-AAC-04 · Favoritos: un cambio reconstruye la rejilla visible — P2

- **Dónde:** `comunicador_picto_grid.dart`.
- **Estado:** pendiente, aceptable.
- Se reconstruyen 12–15 tarjetas visibles, no las 234. Si se quiere afinar: `ref.watch(favoritesProvider.select((s) => s.contains(id)))` por tarjeta.

### PERF-AAC-05 · SVG: 234 archivos parseados bajo demanda — P2

- **Dónde:** `assets/pictos/` (234 SVG, 2,1 MB).
- **Estado:** pendiente. `flutter_svg` cachea y la rejilla es perezosa, pero el primer desplazamiento por una categoría nueva parsea cada SVG visible.
- **Arreglo posible:** precompilar con `vector_graphics_compiler` o rasterizar a WebP. **Medir antes** el parseo en el equipo objetivo; no se propone para el próximo APK.

### PERF-AAC-06 · “Mis mensajes” reescribe toda la lista al borrar — P2

- **Dónde:** `saved_messages.dart`.
- **Estado:** pendiente, aceptable. El número de mensajes guardados es pequeño; desaparece si se migra a Drift.

---

## 4. Juegos

Archivos: `lib/features/juegos/`. Tres perfiles: memoria (estado pequeño), cuentos (texto + pictos) y artista (canvas en vivo).

### PERF-JUE-01 · El trazo del artista hace trabajo O(n) por cada punto — P1

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/juegos/artista/artista_controller.dart:94-113,168-177` |
| Estado | **Pendiente** |
| Qué se notaba | En cada `PointerMove`, `_puntosDelDibujo()` recorre todos los trazos y `[...activo.puntos, nuevo]` copia la lista entera. Con 3.000 puntos, el último movimiento copia 2.999 offsets y cuenta otros 3.000. El coste crece al cuadrado con la duración del trazo. |
| Arreglo posible | Llevar un contador `_puntosTotales` en O(1) y una lista mutable para el trazo activo, notificando una instancia nueva solo al terminar. Alternativa intermedia: copiar cada N puntos. |
| Cómo comprobar | Test de unidad: `continuarTrazo` 3.000 veces debe cortar exactamente en el tope y no superar un presupuesto de tiempo. En perfil, dibujar 10 s y mirar el tiempo de UI por frame. |
| Riesgo | Medio: toca el estado que pinta el lienzo; probar deshacer, goma, cargar dibujo y guardar. |

### PERF-JUE-02 · Guardar un dibujo codifica la galería entera en el hilo de UI — P2

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/juegos/artista/artista_dibujos.dart:125-129` |
| Estado | **Pendiente** |
| Qué se notaba | `jsonEncode` de hasta 30 dibujos × 3.000 puntos en el isolate principal. El string puede superar varios MB y congelar la UI un instante al guardar. |
| Arreglo posible | Mover el `jsonEncode` a `Isolate.run`; mejor aún, una clave por dibujo (`bluetalk_dibujo_<id>`) para no reescribir los otros 29. |
| Cómo comprobar | Llenar la galería al máximo y medir “Guardar”; la animación de la galería no debe congelarse. |

### PERF-JUE-03 · Cada ficha de memoria busca su picto recorriendo la lista — P2

- **Dónde:** `memoria_screen.dart:179,287-290`.
- **Estado:** pendiente. Cada ficha levantada recorre hasta 234 pictos; con 14–24 fichas son miles de comparaciones por jugada.
- **Arreglo posible:** reutilizar un `Map<String, Pictogram>` cacheado (el de rutinas ya existe) o crear uno propio del juego.

### PERF-JUE-04 · `pictosProvider` vuelve a parsear el catálogo — P1 (cubierto por CORE-03)

- **Estado:** corregido por el caché del repo. No cambiar la API del provider.

### PERF-JUE-05 · Cuentos: claves de pictos por página en cada build — P2

- **Dónde:** `cuentos_lector.dart:26`; `cuentos_controller.dart:247`.
- **Estado:** pendiente, aceptable. Calcular las claves una vez al abrir la página si se añaden cuentos largos.

### PERF-JUE-06 · Registrar inicio/fin de juego escribe dos JSON — P0 (cubierto por CORE-01)

- **Estado:** corregido por el agrupado. Son pocos eventos, pero compartían el problema.

---

## 5. Rutinas, salud y entorno

Archivos: `lib/features/rutinas/`, `lib/features/salud/`, `lib/features/entorno/`.

### PERF-RUT-01 · Los resúmenes leen todos los eventos y se quedan viejos — P1

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/rutinas/rutinas_providers.dart:48-64,153-190` |
| Estado | **Pendiente** |
| Qué se notaba | `hechasHoyProvider` y `resumenUsoProvider` recorren la lista completa de eventos y usan `DateTime.now()` sin depender de un proveedor de día. Si la app queda abierta de un día para otro, “hoy” sigue apuntando a ayer hasta que algo invalide. |
| Arreglo posible | Un `hoyProvider` que emita la clave del día y se refresque al volver de segundo plano o al entrar en Rutinas; que los resúmenes dependan de él. No hace falta un timer cada minuto. |
| Cómo comprobar | Test con reloj inyectado: dos consultas con fechas distintas devuelven conjuntos distintos sin reiniciar la app. |

### PERF-RUT-02 · `pictosPorIdProvider` reparsea el catálogo — P1 (cubierto por CORE-03)

- **Estado:** corregido por el caché del repo.

### PERF-RUT-03 · El editor de horario ordena los 234 pictos en cada build — P2

- **Dónde:** `lib/features/rutinas/editor_horario_view.dart:197`.
- **Estado:** pendiente, aceptable. Solo ocurre con el diálogo abierto. Se puede calcular una vez en un provider o en `initState`.

### PERF-RUT-04 · “Velocidad de la voz” duplicada escribe en cada tick — P1

- **Dónde:** `lib/features/salud/salud_screen.dart:261-263`.
- **Estado:** **Pendiente.** El slider de Ajustes ya usa vista previa, pero el duplicado de Salud sigue llamando a `setTtsRate` en cada `onChanged`.
- **Arreglo:** unificar la UI en Ajustes (recomendación de producto de `docs/informes/redundancias/02-ajustes-y-modos.md`) o aplicar `previewTtsRate` + `guardarCambios` también aquí.

### PERF-RUT-05 · Recordatorios: reprogramación completa al cambiar el modo calma — P2

- **Dónde:** `lib/features/rutinas/recordatorios/recordatorios_controller.dart:108-118`.
- **Estado:** pendiente, aceptable. Con 5–15 actividades son 5–15 llamadas al plugin y solo al tocar el interruptor.

### PERF-RUT-06 · Check-in y hábitos reescriben su lista completa — P2

- **Dónde:** `lib/data/local/repo_bienestar.dart:51,65`.
- **Estado:** pendiente, aceptable. Un check-in al día y pocos hábitos: el volumen es mínimo.

---

## 6. Modo padre

Archivos: `lib/features/padre/`. El adulto entra poco, pero quiere datos frescos y gráficos fluidos.

### PERF-PAD-01 · El panel puede enseñar métricas de antes — P1 (correctitud)

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/padre/dashboard/metricas.dart:59`; `lib/features/padre/diagnostico/observaciones.dart:176` |
| Estado | **Pendiente** |
| Qué se notaba | `metricasProvider` y `observacionesProvider` son `FutureProvider` sin `autoDispose`. Nadie los invalida al entrar: si el adulto sale, el niño usa la app y el adulto vuelve, los números siguen siendo los de la primera entrada. |
| Arreglo posible | Hacer ambos `autoDispose` o invalidarlos al entrar en el panel. Añadir un test: registrar un evento entre dos montajes y comprobar que el segundo resumen lo refleja. |
| Riesgo | Bajo. `autoDispose` no cambia el contrato. |

### PERF-PAD-02 · Abrir Informes vuelve a consultar hasta 9 días de Android — P1

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/padre/informes/captura_apps.dart:11,26-56`; `informes_providers.dart:16-25` |
| Estado | **Pendiente** |
| Qué se notaba | `informeProvider` es `autoDispose`; cada vez que se abre Semanal o Mensual se ejecuta `capturarUsoApps`. Hoy y ayer se releen siempre; los 7 días anteriores solo si no tenían datos. En el primer uso pueden ser 9 consultas nativas seguidas antes de pintar. |
| Arreglo posible | Guardar la marca de la última captura y no repetirla si pasaron menos de 5–10 minutos; ejecutar la captura después del primer frame y refrescar al terminar. |
| Cómo comprobar | Abrir/cerrar Informes dos veces y contar llamadas al gateway con un doble; la segunda debe ser 0. |

### PERF-PAD-03 · El informe reparsea el catálogo y espera en serie — P1 (parcial)

- **Dónde:** `lib/features/padre/informes/informes_providers.dart:27-34`.
- **Estado:** **Parcial.** El caché de CORE-03 elimina el reparseo, pero el mapa de nombres sigue haciendo `await pictos.pictogramsOf(c.id)` en serie para cada categoría.
- **Arreglo:** usar `Future.wait` o una sola lectura de todos los pictos. El coste actual es pequeño gracias al caché; no es bloqueante.

### PERF-PAD-04 · Los gráficos animan 600 ms todos a la vez — P1, a confirmar

- **Dónde:** `lib/features/padre/graficos/animacion.dart:4`; `grafica_columnas.dart:76`.
- **Estado:** **Pendiente / NO VERIFICADO.** La animación de entrada de 600 ms sigue existiendo y el modo calma la desactiva. La hipótesis de que varias gráficas arranquen a la vez explique los 39,4 ms del emulador **no está confirmada**.
- **Qué hacer antes de tocar:** perfilar el informe mensual y mirar si el pico está en la entrada o se mantiene al hacer scroll.
- **Arreglos candidatos:** escalonar la entrada, bajar a 300 ms o añadir `RepaintBoundary` por tarjeta. No cambiar a ciegas.

### PERF-PAD-05 · Guardar el filtro web escribe 10 claves en serie — P2

- **Dónde:** `lib/features/padre/filtro_web/filtro_web_controller.dart:85-101`.
- **Estado:** pendiente. Cada cambio guarda 6 booleanos + 4 JSON con `await` uno detrás de otro. Tocar tres interruptores encadena 30 escrituras.
- **Arreglo:** `Future.wait` para las claves independientes o una sola clave JSON con migración del formato viejo.

### PERF-PAD-06 · `metricasProvider` recorre los eventos 8 veces — P2

- **Dónde:** `lib/features/padre/dashboard/metricas.dart:107-111`.
- **Estado:** pendiente, irrelevante hoy (≤ 500 eventos). Si se quiere dejar limpio, contar en un `Map<String,int>` por día en la misma pasada.

---

## 7. Inicio y guía

Archivos: `lib/features/inicio/`, `lib/features/guia/`. Es la primera pantalla y la que más se ve.

### PERF-INI-01 · La guía se agenda en cada rebuild del inicio — P1

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/inicio/inicio_screen.dart:78`; `lib/features/guia/guia_arranque.dart:19-26` |
| Estado | **Corregido en árbol** |
| Qué se notaba | El `addPostFrameCallback` estaba en `build`; cada reconstrucción (calma, perfil, rotación) agendaba otro callback. |
| Arreglo aplicado | `GuiaArranque` es un `ConsumerStatefulWidget` y llama a `iniciarSiFalta()` una sola vez en `initState`. |
| Verificación | `test/guia/guia_test.dart` sigue pasando; no hay test que cuente callbacks, pero el código lo garantiza por construcción. |

### PERF-INI-02 · La guía recompone un path de pantalla completa por frame — P1

| Campo | Detalle |
|---|---|
| Dónde | `lib/features/guia/guia_fondo.dart:22-31` |
| Estado | **Pendiente** |
| Qué se notaba | `GuiaFondo` recibe `repaint: brillo`, una animación en bucle. En cada tick, `paint` hace `Path.combine(PathOperation.difference, pantalla, hueco)` sobre toda la pantalla, aunque el hueco no cambie. |
| Arreglo posible | Usar relleno par-impar (`PathFillType.evenOdd` + rect + rrect), sin combinar paths, o cachear el path y recalcularlo solo si cambia `hueco`. |
| Cómo comprobar | Abrir la guía en perfil y comparar “raster” mientras respira el borde, antes y después. |

### PERF-INI-03 · `Opacity` por tarjeta en cada tick del carrusel — P2

- **Dónde:** `lib/features/inicio/menu_tarjeta.dart:37-39`.
- **Estado:** pendiente, no tocar sin medir. Con 3–5 tarjetas visibles no debería doler; en gama baja el carrusel es la primera impresión.
- **Arreglo posible:** pintar con alfa en los colores o `FadeTransition` sobre un `RepaintBoundary` por tarjeta.

### PERF-INI-04 · El carrusel reconstruye cada página en cada scroll — P2

- **Dónde:** `lib/features/inicio/menu_pagina.dart:36-39`.
- **Estado:** pendiente, aceptable. `AnimatedBuilder` vuelve a construir `FittedBox` + `LayoutBuilder` en cada tick. Afinar solo si se mide jank.

### PERF-INI-05 y PERF-INI-06 · Geometría adaptativa y medidor — correctos

- `menu_geometria.dart` recrea el `PageController` al girar y libera el anterior; ocurre pocas veces y es deliberado.
- El medidor de la guía usa un ticker de 0,5 s por paso; no es un bucle continuo.

---

## 8. Android y release

Archivos: `android/`, `scripts/`, `assets/`.

### AND-01 · La mascota en PNG ocupa 1,8 MB — P2

- **Dónde:** `assets/mascota/` (11 PNG, 1,8 MB).
- **Estado:** pendiente. `cacheWidth: 300` controla la RAM, pero el APK paga el peso.
- **Arreglo:** convertir a WebP con pérdida ligera (calidad 85) o PNG optimizado; suele bajar 60–70 % sin diferencia visible a 120–300 px.
- **Cómo comprobar:** comparar el APK release antes/después y abrir la guía para ver halos.

### AND-02 · Los SVG de pictos se parsean en tiempo de ejecución — P2

- **Dónde:** 234 SVG, 2,1 MB.
- **Estado:** pendiente. La alternativa es precompilar con `vector_graphics_compiler` o rasterizar a WebP. **Medir antes** en gama baja; no se recomienda para el próximo APK.

### AND-03 · No hay Baseline Profile — P2, evaluar

- **Estado:** pendiente. Flutter puede generar uno con Macrobenchmark; requiere módulo de benchmark y teléfono físico. Solo si el arranque medido supera ~2 s en el equipo objetivo.

### AND-04 · Verificación de release — obligatoria, no es un hallazgo de rendimiento

- Cada cambio de `build.gradle.kts`, plugin o asset exige APK/AAB release y humo en dispositivo. R8 y `--obfuscate` pueden romper plugins por reflexión.
- Ver `docs/informes/rendimiento/07-android-release.md`.

---

## 9. Lo que ya está corregido en el árbol (y no está commiteado)

Estos cambios están en el árbol de trabajo, pero **no en `HEAD`**. Un AAB construido desde el commit actual no los incluye.

| Arreglo | Archivos | Evidencia |
|---|---|---|
| Escrituras de uso agrupadas | `lib/data/local/repo_uso.dart` | lote de 2 s + `flush()`; `resumenes_test.dart:135` |
| Resúmenes por lote | `lib/features/padre/informes/resumenes_repo.dart` | lote de 100 + `flush()` |
| Sliders con vista previa | `settings_controller.dart`, `ajustes_texto.dart`, `ajustes_voz.dart` | `preview*` + `guardarCambios` |
| Raíz aislada | `lib/app/app.dart` | `select` + `_temaProvider` + `AppLifecycleListener` |
| Catálogo cacheado | `repo_contenido_seed.dart`, `comunicador_catalog.dart` | índices por categoría e id |
| TTS sin llamadas repetidas | `tts_service.dart`, `tts_contrato.dart` | caché de rate/pitch/idioma |
| Guía una sola vez | `inicio_screen.dart`, `guia_arranque.dart` | `initState` |
| Informes sin reparseo | `informes_providers.dart` | usa el caché del catálogo |
| Formato y tests | `test/padre/...`, `test/...` | suite 456/456 según la revisión del 18-nov |

---

## 10. Qué sigue abierto y en qué orden

1. **Commitear los arreglos P0/P1 ya verdes.** Sin commit no llegan al AAB de release. Es el paso más barato y el de mayor efecto.
2. **Artista (JUE-01):** el único P1 que puede notarse justo cuando el niño más dibuja. Contador O(1) + lista mutable del trazo activo.
3. **Guía (INI-02):** cambio pequeño y aislado; elimina `Path.combine` por fotograma.
4. **Panel (PAD-01) e Informes (PAD-02):** correctitud y primera apertura. Hacerlos antes de la prueba cerrada para que los testers vean datos frescos.
5. **Búsqueda del comunicador (AAC-01):** texto normalizado en `Catalog`; barato y sin cambio visual.
6. **P2:** solo al tocar cada archivo o si el perfilado en gama baja los justifica.

---

## 11. Cómo medir en un teléfono de gama baja

No se ha hecho todavía. Esta es la lista mínima para no confundir “compila” con “funciona”:

```bash
flutter run --profile
# DevTools > Performance, CPU profiler y memoria
```

Escenarios, en este orden:

1. **Arranque en frío** con 0 eventos y con 300 eventos: tiempo hasta el primer frame.
2. **Comunicador:** tocar 10 pictos seguidos y escribir “ca” en el buscador; mirar UI/Raster por frame.
3. **Artista:** trazo de 10 s y guardar con la galería llena (30 dibujos).
4. **Informes:** primera apertura y cambio Semanal ↔ Mensual; mirar el pico de los 600 ms y el scroll.
5. **Guía:** abrirla y dejarla respirar 5 s; comparar con el modo calma.
6. **Modo calma:** misma pantalla encendido/apagado.
7. **Memoria:** catálogo completo y galería al límite; comprobar que no crece sin fin.

Criterio orientativo: **16,7 ms por fotograma** a 60 Hz; en gama baja, aceptar picos aislados de entrada, no jank sostenido al tocar o hacer scroll. Cualquier cifra de emulador con SwiftShader es solo una pista.

---

## 12. NO VERIFICADO

- El rendimiento real en un teléfono de gama baja.
- El tiempo de arranque en frío con 0 y 300 eventos.
- La memoria del catálogo SVG y de la galería de dibujos al límite.
- Si los 39,4 ms/fotograma del informe mensual se deben a las animaciones de 600 ms o al scroll.
- El efecto real del filtro de calma a pantalla completa.
- El comportamiento del AAB ofuscado y con R8 en dispositivo.

---

## 13. Referencias

- Auditoría original: `docs/informes/rendimiento/00-resumen.md` y documentos 01–07.
- Pendientes de Play: `docs/informes/pendientes-play-2026-11-18.md`.
- Decisiones del dueño: `docs/informes/decisiones-pendientes.md`.
- Evidencia de la fase 1: `docs/informes/fase1-evidencia.md`.
