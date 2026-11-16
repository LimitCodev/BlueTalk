# Rendimiento — núcleo, arranque y almacén

Archivos clave: `lib/main.dart`, `lib/app/di.dart`, `lib/app/app.dart`,
`lib/core/almacen/`, `lib/data/local/`, `lib/core/plataforma/`.

## PERF-CORE-01 · Dos JSON completos por cada evento de uso (P0)

**Dónde**
`lib/features/comunicador/comunicador_acciones.dart:27` llama a
`usageRepoProvider.record`. Ese provider está decorado en
`lib/features/padre/informes/usage_repo_con_resumen.dart:15`:

1. `ResumenesRepo.sumar` reescribe el JSON del mes entero (~31 días) en
   `bluetalk_resumen_AAAA-MM` (`resumenes_repo.dart:54`).
2. `PrefsUsageRepo.record` reescribe toda la lista de eventos, hasta ~300
   toques + 14 días de otros eventos (`repo_uso.dart:48`).

Ambas codificaciones ocurren en el hilo de UI y terminan en dos llamadas
`SharedPreferences.setString` (canal de plataforma).

**Qué se nota**
En uso real de AAC el niño toca pictogramas en ráfaga. Cada toque añade dos
serializaciones de decenas de KB y dos escrituras. En un equipo de 2 GB el
retraso se acumula justo cuando la frase debe responder al instante. Es el
hallazgo más caro de toda la app porque multiplica por dos el coste de cada
evento, y hay eventos en casi todas las pantallas.

**Arreglo pequeño**
- Mantener los eventos en memoria y **agrupar el guardado**: un `Timer` de
  1–2 s tras el último `record`, más un volcado en
  `AppLifecycleState.paused` (o `detached`). Si la app muere de golpe se
  pierde como mucho la última ráfaga, aceptable para métricas.
- Alternativa sin timer: guardar los toques como contadores diarios por
  categoría y conservar solo una cola corta de ids distintos para las
  observaciones de 24 h. Requiere tocar `evaluarReglas`.
- Para el resumen mensual, acumular varios eventos y guardar una vez por
  lote; el `_cache` de `ResumenesRepo` ya evita releer, solo falta evitar
  reescribir.

**Cómo comprobarlo**
Perfilar 20 toques seguidos en el comunicador con DevTools > Performance y
comparar el tiempo de “UI” antes/después. También sirve un test de unidad
que cuente llamadas a `guardarTexto` en un almacén falso.

**Riesgo** medio: cambiar cuándo se persiste puede perder el último evento
si se cierra la app a la fuerza. Documentarlo en el código.

---

## PERF-CORE-02 · Los sliders guardan y reconstruyen toda la app en cada tick (P0)

**Dónde**
`lib/features/ajustes/settings_controller.dart:12` guarda en cada
`onChanged`; `lib/features/ajustes/ajustes_texto.dart:29` y
`ajustes_voz.dart:33` lo llaman mientras el dedo se mueve. `lib/app/app.dart`
observa `settingsProvider` para el `textScaler` y el tema.

**Qué se nota**
Arrastrar el slider de “Letra más grande” dispara decenas de escrituras JSON
y reconstruye `MaterialApp.router` completo (tema + `MediaQuery` + toda la
pantalla) por cada píxel. En gama baja el slider va a tirones. La velocidad y
el tono de voz hacen lo mismo aunque no cambian nada visual.

**Arreglo pequeño**
- Separar la **vista previa** del **guardado**: estado local en el widget
  mientras se arrastra y `onChangeEnd` para persistir. Para el tamaño de
  texto, si se quiere vista previa en vivo, aplicar el cambio al `MediaQuery`
  con un provider derivado y guardar solo al soltar.
- Evitar que los cambios de voz reconstruyan la app: en `app.dart` leer solo
  `textScale` y `tema` con `select`, no el objeto `AppSettings` entero.
- Cachear `buildBlueTalkTheme(paleta)` por paleta; hoy se reconstruye en cada
  cambio.

**Cómo comprobarlo**
En perfil, arrastrar el slider de texto de 0,9 a 1,6 y contar fotogramas
perdidos; comparar con `onChangeEnd`.

**Riesgo** bajo.

---

## PERF-CORE-03 · El catálogo reparsea los 234 pictos una vez por categoría (P1)

**Dónde**
`lib/data/local/repo_contenido_seed.dart:19`: `pictogramsOf` hace
`_store.list('pictogramas').map(Pictogram.fromMap)` y después filtra. Es
decir, convierte las 234 filas a objetos **en cada llamada** y descarta casi
todas.

Se llama 7 veces en:
- `Catalog.load` (`comunicador_catalog.dart:24`),
- `pictosProvider` de juegos (`juegos_catalog.dart`),
- `pictosPorIdProvider` de rutinas,
- `informes_providers.dart:27-30`.

En una sesión completa se pueden superar 6 000 objetos creados y tirados,
más el trabajo del recolector.

**Arreglo pequeño**
En `SeedPictogramRepo`: cachear una sola `List<Pictogram> _todos` y agrupar
por `categoryId` en un `Map<String, List<Pictogram>>` la primera vez.
`pictogramsOf` y `pictogram(id)` leen de ahí. No cambia el contrato.
En `Catalog`, construir también un índice `categoryId → lista` para que
`pictogramsOf` no recorra los 234 en cada build de una categoría.

**Cómo comprobarlo**
Test de unidad: dos llamadas a `pictogramsOf` no vuelven a llamar a
`SeedStore.list`; el test ya puede contar lecturas con un doble.

**Riesgo** bajo.

---

## PERF-CORE-04 · Cada picto reaplica velocidad y tono al TTS (P1)

**Dónde**
`lib/features/comunicador/speak_action.dart` hace `setRate` y `setPitch`
antes de cada `speak`. En `tts_service.dart`, la implementación real llama al
canal nativo cada vez, aunque el valor no haya cambiado.

**Qué se nota**
Dos viajes al canal de plataforma antes de cada palabra. En el uso normal
(el niño toca muchos pictos) se suma a la latencia de inicio de la voz y
gasta batería.

**Arreglo pequeño**
Guardar `_ultimaTasa` y `_ultimoTono` en `FlutterTtsSpeaker` y salir sin
llamar al canal si el valor es el mismo. El motor ya aplica los valores al
crearse (`_engine`). Además, `speakText` podría leer los ajustes una vez por
sesión o pasarlos desde el provider.

**Cómo comprobarlo**
Test con un doble de `TtsSpeaker` que cuente llamadas: dos toques seguidos
solo deben llamar a `speak`, no a `setRate`/`setPitch`.

**Riesgo** bajo.

---

## PERF-CORE-05 · Arranque: preferencias + perfil + keystore antes del primer frame (P2)

**Dónde** `lib/main.dart:38-52`.

Es deliberado: evita parpadeos de tema y permite que el gate consulte el PIN
de forma síncrona. `AlmacenPin.cargar` hace `readAll` del keystore y una
prueba de escritura/borrado (`almacen_pin.dart:85`).

**Qué se nota**
En frío se suman tres viajes de plataforma antes de `runApp`. En un equipo
lento puede ser ~100–300 ms de pantalla de lanzamiento. No es grave porque
es una sola vez y la pantalla nativa ya está visible.

**Arreglo pequeño**
No urgente. Si se mide y molesta: cargar el perfil y el PIN en paralelo con
`Future.wait`, manteniendo las preferencias primero. El PIN podría cargarse
en segundo plano si el gate muestra un estado “comprobando” en vez de asumir
que no hay huella.

**Riesgo** medio: el gate no debe decir “sin PIN” mientras carga.

---

## PERF-CORE-06 · Filtro de calma a pantalla completa (P2)

**Dónde** `lib/app/app.dart:45`, `ColorFiltered` con
`BlendMode.saturation` sobre todo el árbol.

**Qué se nota**
Es una operación de GPU sobre el fotograma completo. En equipos muy justos,
con el modo calma activo, puede costar unos milisegundos por fotograma. A
cambio, garantiza grises en todo, incluidos SVG y avatar.

**Arreglo pequeño**
No cambiar sin medir. Alternativa cara: una paleta gris explícita en
`AppColors` y no filtrar; obliga a revisar cada color y las imágenes. Se
deja como P2 y se decide con perfil en mano.

---

## PERF-CORE-07 · Persistencia JSON repetida en siete sitios (deuda, no jank)

Cada repo repite el mismo patrón: leer string, `tryDecode*`, mapear, y
reemplazar el JSON completo al guardar. Está en `repo_uso`, `repo_bienestar`,
`repo_perfil`, `repo_ajustes`, `repo_horario`, `repo_progreso_juegos`,
`saved_messages`, `artista_dibujos` y `FiltroWebPrefs`.

No es un problema de fotogramas por sí solo, pero multiplica los puntos donde
un guardado bloquea. Un helper `JsonPrefs` (leer lista/mapa, guardar con
debounce opcional) reduciría duplicación y haría más fácil aplicar
PERF-CORE-01. Ver `docs/informes/redundancias/04-persistencia-y-codigo.md`.

---

## Comprobaciones rápidas antes de tocar el núcleo

```bash
flutter analyze
flutter test test/arquitectura/ test/comunicador/ test/padre/
```

- El test de capas exige que nadie fuera de `lib/data/local/` y `di.dart`
  importe `shared_preferences`.
- El trinquete de 100 líneas se aplica a los archivos nuevos; si el arreglo
  crece, extraer a otro archivo en vez de subir el tope.
