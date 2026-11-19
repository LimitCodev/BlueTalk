# 15 — Mejores ajustes del padre: orden de pictogramas y voz propia

- **#4bluetalk cambio:** mejores ajustes del padre
- **Estado:** propuesta de diseño. **No implementada.**
- **Origen:** pedido del dueño, 2026-11-12.
- **Base:** plan 11 §2.1 (posiciones fijas del vocabulario nuclear) y §2.5
  («voz grabada de un familiar» está en el backlog y exige esta nota).
- **Regla:** no empezar a programar sin la aprobación explícita del dueño
  (plan 11 §2.5). Este documento es la nota de diseño que falta.

---

## 0. Resumen en una página

Dos mejoras para el **modo padre**, pensadas para que el comunicador se adapte
a cada niño sin romper las reglas de la comunicación aumentativa:

1. **Orden personalizado.** El adulto puede cambiar el orden en que aparecen
   las **categorías temáticas** y los **pictogramas dentro de cada categoría**.
   El **tablero nuclear no se reordena nunca**: sus posiciones son memoria
   motora y así lo exige el plan 11 §2.1; PECS también se apoya en un
   intercambio predecible.
2. **Voz propia por pictograma.** El adulto graba su voz (madre, padre, tutor
   o terapeuta) para las palabras que quiera, la guarda en el teléfono y el
   niño la escucha al tocar ese pictograma. Si no hay grabación, suena la voz
   del sistema (TTS) como hasta ahora.

Las dos funciones son **gratis para siempre** (comunicar nunca es premium),
**solo las usa el adulto** y **no salen del dispositivo**. El diseño es
**multiplataforma**: la lógica y la UI son Flutter; grabar y reproducir pasan
por adaptadores por plataforma, con una degradación clara (solo TTS) cuando
una plataforma no puede grabar. La voz propia **complementa** el selector de
voz del sistema del plan 11 §2.4; no lo sustituye: si no hay grabación, se
usa el TTS elegido.

---

## 1. Pedido literal del dueño

> «Que el modo padre pueda editar el orden de los elementos como aparecerán en
> el pictograma, incluso poner su propia voz a ciertos elementos, grabarlo y
> guardarlo para que sea de libre uso del niño.»

Interpretación de este plan:

- «los elementos» = categorías temáticas y pictogramas dentro de ellas, **no**
  el tablero nuclear ni la barra de frase.
- «su propia voz» = la voz de la persona adulta que configura la app, no la
  voz del niño.
- «de libre uso del niño» = el niño puede tocar esos pictogramas y oírlos
  cuando quiera, sin permisos, sin compras y sin conexión.

---

## 2. Reglas duras que no se pueden saltar

| Regla | Consecuencia en este diseño |
|---|---|
| **Comunicar nunca es premium** | Orden y voz propia no llevan `Funcion` ni `puedeUsarProvider`. Son parte del núcleo gratuito. |
| **El vocabulario nuclear no se mueve** | El adulto no puede reordenar el tablero nuclear. La UI lo explica con lenguaje literal y un candado. |
| **PECS y comunicación funcional** | El intercambio ocurre con una persona; la app no sustituye al compañero de comunicación ni al profesional. |
| **Solo el adulto configura** | Reordenar y grabar viven detrás del PIN del modo padre. El niño nunca abre el micrófono. |
| **100 % offline** | Las grabaciones se guardan en el almacenamiento privado de la app. No hay subida, sincronización ni cuenta. |
| **Multiplataforma** | Nada de `dart:io` ni `MethodChannel` en las pantallas. Se usan interfaces y adaptadores; si una plataforma no graba, se oculta la opción y se avisa. |
| **Sin dependencias nuevas sin aprobación** | Grabar/reproducir exige decidir entre plugins multiplataforma o canal nativo propio. La decisión está en §15. |
| **Accesibilidad** | Reordenar no puede depender solo de arrastrar; botones «Subir/Bajar», etiquetas y anuncios para TalkBack. |
| **Modo calma** | Sin animaciones ni pulsos al grabar u ordenar. La voz solo suena bajo toque. |
| **Sin datos personales en el repo** | Las grabaciones y el orden son datos locales del niño: nunca se commitean, ni se loguean, ni se exportan por defecto. |

---

## 3. Alcance

### 3.1 Dentro de esta mejora

- Reordenar **categorías temáticas** en el inicio del comunicador.
- Reordenar **pictogramas dentro de cada categoría temática**.
- Restablecer el orden original de los seeds.
- Vista previa «Ver como el niño» antes de guardar.
- Grabar, escuchar, repetir y borrar una **voz propia por pictograma**.
- Reproducir la voz propia al tocar el pictograma y al pulsar «Leer» en una
  frase, con **fallback a TTS** por palabra.
- Indicador en el panel del adulto de qué pictogramas tienen voz propia.
- Borrar todas las voces de una vez, con confirmación.
- Persistencia local, tolerante a corrupción y a actualizaciones del seed.

### 3.2 Fuera de esta mejora (por ahora)

- Reordenar el **tablero nuclear** o las palabras básicas.
- Reordenar la **barra de frase** mientras el niño la está usando.
- Grabar frases completas o conversaciones.
- Compartir, exportar o sincronizar voces entre teléfonos.
- Efectos de voz, filtros, música o reconocimiento de habla.
- Varios perfiles simultáneos (se deja `perfilId` preparado, pero no se
  implementa el cambio de perfil).
- Que el niño grabe su propia voz.
- Descargar voces o paquetes desde internet.

---

## 4. UX del orden personalizado

### 4.1 Dónde entra el adulto

```text
Ajustes → Modo padre (PIN) → Control → sección «Comunicador»
  → «Orden de los pictogramas»
       ├─ Categorías (lista reordenable)
       └─ Dentro de una categoría (lista reordenable)
  → «Voces de los pictogramas» (ver §5)
```

Hoy el panel del adulto tiene cuatro pestañas (Resumen, Control, Salud y
Legal). **No se añade una pestaña nueva**: las dos entradas viven en Control,
junto a las demás opciones del comunicador. Tampoco se añade un botón en el
flujo del niño.

### 4.2 Pantalla de categorías

- Lista vertical con el icono, el nombre y una **manija de arrastre**.
- Cada fila tiene además dos botones de 48 dp: **«Subir»** y **«Bajar»**.
  El arrastre es un atajo, no la única forma: hay niños y adultos con
  dificultades motoras.
- La categoría **nuclear** («Palabras básicas» o la que tenga `tipo: nuclear`)
  aparece **primera, bloqueada y con un candado**. Texto literal:
  «Las palabras básicas no se mueven: el niño las aprende siempre en el mismo
  sitio.»
- Las categorías ocultas por el perfil de edad no se muestran, pero conservan
  su orden si vuelven a aparecer.
- Botones: **Guardar**, **Cancelar** y **Restablecer orden original**.
- Al guardar: mensaje «Orden guardado» y vuelta a la lista del padre.

### 4.3 Pantalla dentro de una categoría

- Misma mecánica: manija, «Subir», «Bajar», guardar/cancelar/restablecer.
- Se muestra la imagen y la etiqueta; no se permite editar la etiqueta ni el
  asset desde aquí.
- Si la categoría está vacía (caso raro de seed roto), se muestra un texto
  literal y no se permite guardar un orden vacío.
- Al volver, se conserva el orden ya guardado; los cambios sin guardar se
  descartan con confirmación.

### 4.4 Reglas de combinación con los seeds

El orden del seed **nunca se modifica en disco**. El orden personalizado es
una capa encima:

1. Se parte del orden del seed.
2. Se aplican los ids guardados que **existen** en el seed actual.
3. Los ids que ya no existen se ignoran (no rompen la app).
4. Los ids nuevos del seed se añaden **al final** de su categoría.
5. La categoría nuclear y sus pictogramas se ordenan siempre por `order` del
   seed, ignorando cualquier orden personalizado.
6. Las categorías nucleares siguen primero; las temáticas se ordenan después.

Así una actualización del vocabulario no deja huecos ni pierde el orden del
adulto.

### 4.5 Accesibilidad y modo calma

- Objetivos táctiles ≥ 48 dp y texto escalable.
- Etiquetas `Semantics`: «Comida, posición 2 de 7. Subir. Bajar.»
- Anuncio al guardar: «Orden guardado.»
- No hay animaciones de reordenamiento en modo calma; el cambio es inmediato.
- El foco de TalkBack (o VoiceOver) sigue el orden visual y no se pierde al
  mover una fila.
- La vista previa es de solo lectura y no habla sola.

### 4.6 Persistencia

- Un único JSON versionado en `AlmacenLocal`, por ejemplo
  `bluetalk_orden_comunicador_v1`.
- Lectura tolerante a corrupción con `json_seguro.dart`; escritura en una
  sola clave de `AlmacenLocal`, no en varios archivos a medias.
- Si el JSON está roto, se usa el orden del seed y se avisa al adulto; la app
  nunca se queda sin tablero.
- Sin escrituras por cada arrastre: se guarda al pulsar «Guardar».

---

## 5. UX de la voz propia

### 5.1 Dónde entra el adulto

```text
Modo padre → Control → «Comunicador» → «Voces de los pictogramas»
  ├─ Buscador por palabra
  ├─ Filtro: todas / con voz propia / sin voz propia
  └─ Fila: pictograma · etiqueta · estado · Escuchar · Grabar · Borrar
```

También se puede llegar desde la ficha de un pictograma en el catálogo del
adulto, si existe esa vista; si no, la lista con buscador es suficiente.
«Escuchar» reproduce la voz propia si existe; si no, una muestra del TTS.
Solo suena bajo toque.

### 5.2 Flujo de grabación

1. El adulto toca **«Grabar»**.
2. Antes del diálogo del sistema, la app explica en lenguaje literal:
   «Vas a usar el micrófono. La voz se guarda solo en este teléfono.»
3. Android, iOS o el navegador piden el permiso del micrófono. Si se deniega,
   se explica cómo activarlo en los ajustes del sistema o del navegador y no
   se insiste en bucle.
4. La app muestra **«Grabando…»** y un botón **«Detener»**. Sin cuenta
   regresiva agresiva; el límite se avisa al empezar: «Máximo 5 segundos».
5. Al detener (o al llegar al límite), se muestra **«Escuchar»**,
   **«Guardar»**, **«Repetir»** y **«Descartar»**.
6. Al guardar: «Voz guardada.» El pictograma queda marcado en el panel del
   adulto.
7. Si ya había una voz, se pide confirmación para reemplazarla.

### 5.3 Cómo la usa el niño

- Tocar un pictograma con voz propia reproduce **esa grabación**.
- Tocar un pictograma sin voz propia usa el TTS del sistema, como hoy.
- «Leer» recorre la frase **en orden**: por cada pictograma, voz propia si
  existe; TTS si no. Mientras suena, el botón cambia a **«Detener»** (mismo
  objetivo de 48 dp); al terminar vuelve a «Leer». Un nuevo toque en un
  pictograma también cancela la reproducción anterior.
- Se respeta el ajuste **«Hablar al tocar»**: si el adulto lo apagó, el toque
  no reproduce ni voz propia ni TTS; «Leer» sigue sonando bajo toque.
- Si **ningún** pictograma de la frase tiene voz propia, se mantiene la
  llamada TTS única de hoy (prosodia natural). Si al menos uno tiene voz
  propia, se reproduce la secuencia por pictograma.
- El aviso de «no hay voz en español» solo aparece si se va a usar TTS; una
  grabación propia no depende del motor del sistema.
- **Sin autoplay**: nada suena al abrir la pantalla ni al cambiar de categoría.
- El tablero del niño **no** muestra un icono de «voz propia» que distraiga;
  el indicador vive solo en el panel del adulto.

### 5.4 Límites y formato

| Parámetro | Valor propuesto | Por qué |
|---|---|---|
| Duración máxima | **5 segundos** | Una palabra o frase corta; evita audios eternos y peso. |
| Formato | AAC-LC en `.m4a` o Opus en `.ogg`/`.webm` | Compatibilidad Android/iOS/web; pequeño y con buena voz. |
| Canal | Mono | La voz no necesita estéreo. |
| Frecuencia | 22.05 kHz o 24 kHz | Suficiente para voz; menos peso. |
| Bitrate | 48 kbps | ~30 KB por 5 s; 239 voces ≈ 7 MB. |
| Volumen | Normalizado al grabar | Evita voces casi inaudibles. |
| Tamaño máximo | 150 KB por archivo | Tope de seguridad. |

El formato final lo fija el adaptador de cada plataforma; el modelo guarda
`formato`, `duracionMs` y `bytes` para poder validar y mostrar el estado.

### 5.5 Errores y degradación

| Caso | Qué hace la app |
|---|---|
| Micrófono denegado | Explica cómo activarlo; el pictograma sigue con TTS. |
| No hay micrófono | Oculta «Grabar» y muestra «Este dispositivo no puede grabar». |
| Permiso revocado después de grabar | Las grabaciones existentes siguen sonando; grabar se desactiva. |
| Archivo borrado o corrupto | Fallback a TTS y aviso en el panel del adulto. |
| Disco lleno | No guarda; mensaje claro y conserva la voz anterior. |
| Llamada o app en segundo plano | Se detiene la grabación; no se guarda a medias. |
| El niño toca otro pictograma | Se corta la reproducción anterior y suena la nueva. |

---

## 6. Datos y arquitectura

### 6.1 Modelos

```dart
/// Orden elegido por el adulto. No modifica los seeds.
class OrdenComunicador {
  final int version; // 1
  final List<String> categorias; // ids en orden
  final Map<String, List<String>> pictogramas; // categoryId -> ids
}

/// Voz grabada por el adulto para un pictograma.
class VozPropia {
  final String pictogramId;
  final String perfilId; // preparado para multi-perfil; hoy un solo perfil
  final String archivo; // nombre relativo, nunca ruta absoluta
  final String formato; // m4a, ogg, webm…
  final int duracionMs;
  final int bytes;
  final DateTime creado;
}
```

No se añade un campo de orden de usuario al `Pictogram`: el `order` existente
sigue siendo **solo del tablero nuclear**. El orden personalizado es una capa
aparte; así el seed sigue siendo la fuente de verdad y el test de integridad
no cambia. En la v1 el orden es **del dispositivo** (un solo perfil); si se
aprueba multi-perfil, se añade `perfilId` y se migra el JSON con
`version: 2`.

### 6.2 Contratos y repositorios

```dart
abstract interface class OrdenComunicadorRepo {
  Future<OrdenComunicador?> load();
  Future<void> save(OrdenComunicador orden);
  Future<void> clear();
}

abstract interface class VocesPropiasRepo {
  Future<List<VozPropia>> all();
  Future<VozPropia?> of(String pictogramId);
  Future<void> save(VozPropia voz, List<int> bytes);
  Future<void> delete(String pictogramId);
  Future<void> deleteAll();
}
```

- Implementaciones en `lib/data/local/` (`repo_orden_comunicador.dart`,
  `repo_voces_propias.dart`).
- `VocesPropiasRepo` habla con `AlmacenVoces`; nunca con `dart:io` desde la UI.
- En `lib/app/di.dart` se eligen las implementaciones, como el resto.

### 6.3 Providers

- `ordenComunicadorProvider`: `AsyncNotifier<OrdenComunicador?>`.
- `vocesPropiasProvider`: `AsyncNotifier<Map<String, VozPropia>>`.
- `catalogProvider` (ya existe) pasa a escuchar el orden y aplica la
  combinación de §4.4 antes de entregar el `Catalog`.
- `puedeGrabarProvider`: capacidades de la plataforma + permiso.
- `vozDelPictogramaProvider(pictogramId)`: resuelve voz propia o `null`.

### 6.4 Servicio de voz

Hoy `speakText(context, ref, text)` recibe solo texto y `PhraseBar` le pasa
`phraseText(phrase)`. Para mezclar grabaciones y TTS hace falta un servicio
que reciba pictogramas:

```dart
abstract interface class VozComunicador {
  Future<void> speakPictograma(Pictogram picto);
  Future<void> speakFrase(List<Pictogram> frase);
  Future<void> stop();
}
```

- `speakPictograma`: si hay `VozPropia`, reproduce el archivo; si no, TTS.
- `speakFrase`: recorre la lista, espera a que termine cada elemento y corta
  si llega una nueva orden (token de generación). Agrupar los tramos
  consecutivos sin voz propia en una sola llamada TTS reduce el corte de
  prosodia; es una optimización de la fase 3.
- `TtsSpeaker` debe usar `awaitSpeakCompletion(true)` (o el callback de
  finalización) para que la secuencia no se solape.
- Los tests usan dobles falsos de `VozComunicador`, `ReproductorVoz` y
  `GrabadoraVoz`; no se prueba audio real en unit tests.

Puntos de integración:

| Archivo | Cambio |
|---|---|
| `comunicador_catalog.dart` | Aplicar el orden personalizado al construir el `Catalog`. |
| `comunicador_acciones.dart` / `picto_tile.dart` | Tocar pictograma → `speakPictograma` (solo si «Hablar al tocar» está activo). |
| `phrase_bar.dart` | «Leer» → `speakFrase(phrase)`, no `phraseText`. |
| `speak_action.dart` | Se conserva para textos sueltos o se refactoriza sobre el nuevo servicio. |
| `tts_service.dart` | `awaitSpeakCompletion` y `stop` coordinados con el reproductor de archivos. |

### 6.5 Almacenamiento de archivos

```text
<documentos-de-la-app>/
└── voces/
    └── <perfilId>/
        ├── <pictogramId>.m4a
        └── <pictogramId>.ogg
```

- El JSON guarda **solo el nombre relativo**; la ruta se resuelve al leer.
- El nombre sale del `id` estable del pictograma, nunca de la etiqueta.
- Si se borra un pictograma propio (plan 11 §2.3), se borra su voz y se
  limpian las referencias en frases y horarios.
- Limpieza de huérfanos al arrancar el modo padre: archivos sin metadato o
  metadatos sin archivo se marcan y se ofrece borrarlos.
- `allowBackup=false` ya está activo; las voces no viajan en backups del
  sistema.

---

## 7. Multiplataforma

### 7.1 Qué significa aquí

La app es Flutter, pero hoy solo se publica en Android. «Multiplataforma» en
este plan significa:

1. **La lógica y la UI no dependen de Android.** El orden es Flutter puro y
   funciona en cualquier plataforma.
2. **Grabar y reproducir** pasan por interfaces (`GrabadoraVoz`,
   `ReproductorVoz`, `AlmacenVoces`) con una implementación por plataforma.
3. **Si una plataforma no puede grabar**, la opción se oculta con un mensaje
   literal y el TTS sigue funcionando. Nunca se rompe el comunicador.
4. **No se promete** que iOS, web o escritorio estén publicados: este plan
   deja el diseño listo y marca qué falta verificar en cada uno.

### 7.2 Matriz de capacidades

Las celdas de iOS, web y escritorio describen el **diseño**, no una
implementación verificada. Solo Android existe hoy.

| Plataforma | Orden | Grabar | Reproducir | Estado |
|---|---|---|---|---|
| **Android** | Sí | Sí, con `RECORD_AUDIO` | Sí | Release actual; el permiso aún no está implementado. |
| **iOS** | Diseñado | Diseñado, con `NSMicrophoneUsageDescription` | Diseñado | No verificado. |
| **Web** | Diseñado | Diseñado, según `MediaRecorder` | Diseñado | No verificado; IndexedDB/OPFS, no `path_provider`. |
| **Windows/macOS/Linux** | Diseñado | Según adaptador | Diseñado | No verificado; si no hay micrófono o plugin, se oculta «Grabar». |

### 7.3 Adaptadores

| Interfaz | Responsabilidad | Android | iOS | Web | Escritorio |
|---|---|---|---|---|---|
| `AlmacenVoces` | Guardar/leer/borrar archivos y metadata. | Directorio de documentos. | Directorio de documentos. | IndexedDB/OPFS. | Directorio de documentos. |
| `GrabadoraVoz` | Permiso, empezar, detener, cancelar, formato. | `MediaRecorder`/plugin. | `AVAudioRecorder`/plugin. | `MediaRecorder`. | Plugin o nativo. |
| `ReproductorVoz` | Reproducir archivo y avisar el final. | `MediaPlayer`/plugin. | `AVAudioPlayer`/plugin. | `HTMLAudioElement`. | Plugin o nativo. |
| `CapacidadesVoz` | `puedeGrabar`, `puedeReproducir`, motivo. | Permiso + hardware. | Permiso + hardware. | Soporte del navegador. | Plugin/hardware. |

- Nada de `dart:io` en `lib/features/` ni en la lógica compartida. Si hace
  falta, se usa una interfaz y una implementación condicional.
- La UI decide con `CapacidadesVoz`, no con `Platform.isAndroid`.
- Los mensajes son literales: «Este dispositivo no puede grabar voces.»

### 7.4 Opciones técnicas (sin decidir aún)

| Opción | Ventajas | Costes |
|---|---|---|
| **A. Plugins multiplataforma** (`record` para grabar y `audioplayers` o `just_audio` para reproducir; `path_provider` solo en Android/iOS/escritorio, con adaptador web para IndexedDB/OPFS) | Menos código nativo; `record` y el reproductor cubren Android/iOS/web/escritorio; una sola API de audio. | Dependencias nuevas; permisos y formatos distintos por plataforma; el almacenamiento web necesita su propio adaptador; hay que justificarlas y fijar versiones. |
| **B. Canal nativo propio** (`CanalNativo` + Kotlin/Swift/JS) | Sin dependencias nuevas; control total; reutiliza la puerta existente. | Más código por plataforma; web y escritorio quedan para después; más pruebas manuales. |
| **C. Híbrido** | Plugin para grabar y canal nativo para reproducir (o al revés). | Dos mecanismos que mantener; solo si un spike demuestra que conviene. |

**Recomendación provisional:** hacer un spike corto con la opción A en Android
(y, si hay build, también en iOS), medir latencia, tamaño, permisos y
estabilidad; si el resultado no convence, volver a B. La decisión final es del
dueño porque añade dependencias (regla del plan 00 §5.5).

---

## 8. Privacidad, legal y Google Play

- **Solo el adulto graba.** El micrófono se abre únicamente desde el modo
  padre, después del PIN. El flujo del niño no tiene botón de grabación.
- **La voz se queda en el teléfono.** No se sube a AWS, Supabase, Firebase ni
  a ningún servidor. No hay cuentas ni analítica.
- **No se graba al niño para diagnóstico.** La función es la voz de un
  familiar o cuidador para acompañar la comunicación.
- **Borrado claro:** «Borrar esta voz» y «Borrar todas las voces», con
  confirmación y sin dejar archivos huérfanos.
- **Permiso `RECORD_AUDIO`:** hay que declararlo en el manifiesto de las
  ediciones que incluyan la función, explicarlo en `docs/play/permisos.md` y
  actualizar la política de privacidad y la sección Data safety de Play.
  Aunque el audio no salga del dispositivo, el permiso y la función se
  declaran.
- **Política de Familias:** la grabación debe quedar detrás del gate del
  adulto; no se puede pedir micrófono al arrancar ni en el flujo del niño.
- **Cifrado en reposo:** decisión abierta (§15). La app ya tiene
  `cryptography` y `flutter_secure_storage`; si se cifra, la clave vive en el
  keystore y la reproducción debe seguir siendo rápida. Si no se cifra, se
  documenta que el archivo está en el almacenamiento privado de la app.
- **Edición Play vs `directa`:** decidir si la grabación entra en la v1 de
  Play o solo en el APK directo. Si entra, preparar la declaración de
  micrófono y el texto de la ficha; si no, ocultarla en la edición Play.
- **PECS:** la app no está afiliada a Pyramid Educational Consultants ni
  cuenta con una certificación PECS. La voz propia es un apoyo, no un
  programa PECS completo.

---

## 9. Accesibilidad

- Reordenar con botones, no solo con arrastre; objetivos ≥ 48 dp.
- Etiquetas de posición («2 de 7») y anuncios al mover y guardar.
- La manija de arrastre tiene `Semantics` y una alternativa por botones.
- Grabar: estados claros («Grabando», «Listo para guardar», «Voz guardada»),
  sin temporizadores que metan prisa; el límite se avisa al empezar.
- La vista previa y «Escuchar» solo suenan bajo toque.
- En modo calma no hay animaciones de pulso, onda o transición.
- El texto escala sin cortar etiquetas; probar con `textScaler` 2.0.
- El tablero del niño mantiene posiciones estables y no añade iconos que
  compitan con el pictograma.

---

## 10. Rendimiento y tamaño

| Aspecto | Objetivo | Cómo |
|---|---|---|
| Peso de audio | ≤ 150 KB por voz; ~7 MB con 239 voces | 5 s, mono, 22–24 kHz, 48 kbps. |
| Latencia al tocar | < 150 ms percibidos | Reproductor único, archivo local, sin decodificar toda la biblioteca. |
| Cambio de frase | Corta la anterior sin solapar | Token de generación + `stop()` en TTS y reproductor. |
| Guardar orden | < 50 ms, sin jank | JSON pequeño y escritura atómica. |
| Memoria | No cargar todos los audios | Solo metadata en memoria; archivo bajo demanda. |
| Arranque | Sin cambio perceptible | La limpieza de huérfanos se hace al abrir el panel del adulto, no al inicio. |
| Archivos de 100 líneas | Se respeta el trinquete | Partir pantallas y controladores por responsabilidad. |

---

## 11. Pruebas

### 11.1 Unitarias

- Combinación de orden: seed + orden guardado + ids nuevos + ids borrados.
- El tablero nuclear ignora el orden personalizado.
- JSON corrupto → vuelve al seed sin lanzar.
- Guardar, borrar y restablecer orden.
- `VozPropia`: metadata, archivo ausente, archivo corrupto, borrado.
- Secuencia de frase: propia → TTS → propia; cancelación a mitad.
- Limpieza de huérfanos y borrado de un pictograma propio.

### 11.2 Widget

- Pantalla de categorías: subir/bajar, candado nuclear, guardar/cancelar.
- Pantalla de pictogramas: orden, restablecer, estado vacío.
- Modo calma: sin animaciones y con los mismos resultados.
- TalkBack/VoiceOver: etiquetas de posición y anuncios.
- Grabación con dobles: permiso denegado, grabando, guardar, repetir, borrar.
- Frase con voz propia y fallback; «Detener» corta.

### 11.3 Integración y manual

- Emulador Android con micrófono del anfitrión: grabar, guardar, reiniciar,
  reproducir en el tablero y en una frase.
- Teléfono físico de gama baja: latencia y tamaño.
- iOS (cuando exista build): permiso, grabación, reproducción, interrupciones.
- Web (si entra en el alcance): `MediaRecorder`, IndexedDB y gesto de usuario.
- Escritorio: solo si se decide; si no, verificar que la opción se oculta.

### 11.4 Arquitectura

- `test/arquitectura/capas_test.dart`: sin `SharedPreferences` ni
  `MethodChannel` nuevos fuera de las puertas.
- `test/arquitectura/tamano_test.dart`: archivos nuevos ≤ 100 líneas.
- `test/arquitectura/manifiesto_test.dart`: `RECORD_AUDIO` solo donde toca y
  con justificación.
- Test de que el flujo del niño no puede abrir el micrófono.

---

## 12. Fases de implementación

| Fase | Entrega | Depende de | Evidencia |
|---|---|---|---|
| **0** | Aprobar este plan, plataformas y decisiones de §15 | Dueño | Decisión escrita en `decisiones-pendientes.md` |
| **1** | Orden personalizado de categorías y pictogramas, sin dependencias | Fase 0 | Unit + widget + capturas + `analyze`/`test` |
| **2** | Spike de voz (grabar/reproducir) en Android; medir latencia, peso y permisos | Fase 0 | Informe del spike y decisión A/B |
| **3** | Voz propia completa en Android: panel, grabación, fallback, secuencia | Fase 1 + 2 | Unit + widget + prueba en emulador/teléfono |
| **4** | Adaptadores iOS/web/escritorio y matriz de capacidades | Fase 3 | Matriz manual y pruebas por plataforma |
| **5** | Play (si entra en esa edición): permiso, Data safety, privacidad, ficha y revisión | Fase 3 | Docs actualizados + build de prueba |

Cada fase cierra con `flutter analyze` en 0, tests en verde, un commit
coherente y su archivo de evidencia en `docs/informes/`.

---

## 13. Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| El adulto reordena el tablero nuclear y rompe la memoria motora | Candado explícito en la UI y prueba que verifica que el orden nuclear nunca cambia. |
| El orden guardado se rompe al actualizar el vocabulario | Combinación por ids, ids nuevos al final, test de migración. |
| El micrófono se abre en el flujo del niño | Toda la grabación vive detrás del PIN; test de que el niño no tiene acceso. |
| Play rechaza la app por el micrófono o por menores | Declaración clara, gate del adulto, sin nube, revisión legal antes de publicar. |
| Las grabaciones ocupan demasiado | Límite de 5 s/150 KB, borrado por pictograma y «borrar todo», limpieza de huérfanos. |
| El audio se solapa con el TTS | Cola con token de generación y `awaitSpeakCompletion`. |
| Un plugin no funciona en una plataforma | Adaptadores + `CapacidadesVoz` + fallback a TTS. |
| El archivo desaparece o está corrupto | Validación al leer y fallback a TTS con aviso en el panel. |
| Se promete PECS completo sin serlo | Texto explícito en README y en la app: herramienta de apoyo, no programa completo ni avalado. |
| Se filtran voces o datos del menor | Sin red, sin exportación por defecto, sin logs, `allowBackup=false`, borrado claro. |

---

## 14. Criterios de aceptación

- [ ] El adulto reordena categorías temáticas y pictogramas; el orden persiste
      tras cerrar y reabrir la app.
- [ ] El tablero nuclear y sus posiciones **no cambian** en ningún caso.
- [ ] «Restablecer orden original» vuelve al seed sin borrar voces.
- [ ] Una actualización del seed no rompe el orden guardado.
- [ ] El adulto graba, escucha, repite y borra una voz por pictograma.
- [ ] El niño oye la voz propia al tocar y al usar «Leer»; si no hay, oye TTS.
- [ ] «Detener» y un nuevo toque cortan la reproducción anterior.
- [ ] El niño no puede abrir el micrófono ni ver la pantalla de grabación.
- [ ] Todo funciona sin red y sin cuentas.
- [ ] Modo calma y TalkBack/VoiceOver funcionan en las pantallas nuevas.
- [ ] `flutter analyze` en 0 y tests en verde.
- [ ] README, privacidad, permisos y Play actualizados.
- [ ] La matriz multiplataforma declara qué funciona, qué falta y qué se oculta.

---

## 15. Decisiones que necesita el dueño

Ninguna de estas se decide en este documento. Se dejan escritas para que el
dueño las responda antes de la fase 1.

1. **Plataformas:** ¿solo Android ahora, o también iOS/web/escritorio en la
   primera entrega? La app publicada hoy es Android; el diseño ya es
   multiplataforma, pero cada plataforma exige build, permisos y pruebas.
2. **Tablero nuclear:** ¿confirmas que **no** se puede reordenar? La
   recomendación es que no, por PECS y por memoria motora.
3. **Qué se puede reordenar:** ¿categorías y pictogramas temáticos? ¿También
   los favoritos del inicio? Los favoritos hoy son un conjunto sin orden.
4. **Duración de la voz:** ¿3, 5 o 10 segundos por pictograma? La propuesta es
   5 s.
5. **Cifrado en reposo:** ¿las voces se cifran con una clave del keystore o
   basta el almacenamiento privado de la app? Cifrar añade complejidad y
   latencia; no cifrar deja el archivo legible en un dispositivo rooteado.
6. **Edición Play:** ¿la grabación entra en la edición Play o solo en el APK
   `directa`? Entrar en Play exige declarar micrófono y revisar la política
   de Familias.
7. **Exportar/importar:** ¿las voces viajan en la copia de seguridad del plan
   11 §2.4 o quedan fuera por privacidad?
8. **Varios perfiles:** ¿la voz y el orden son por niño o por dispositivo? El
   modelo deja `perfilId` para la voz, pero hoy hay un solo perfil y el orden
   se guarda por dispositivo.
9. **Dependencias:** ¿se aprueban `record` + `audioplayers`/`just_audio` +
   `path_provider`, o se prefiere el canal nativo propio? La decisión se toma
   después del spike de la fase 2.
10. **PECS:** confirmar el texto público: «inspirado en PECS, sin afiliación
    ni certificación», no «PECS certificado».

---

## 16. Referencias

- `docs/plan/11-fases-1-a-3-excelencia.md` §2.1 (vocabulario nuclear en
  posiciones fijas) y §2.5 (voz grabada de un familiar).
- `docs/plan/02-aac-comunicador.md` (comunicador, barra de frase y TTS).
- `docs/ARQUITECTURA.md` (capas, puertas del core y reglas).
- `docs/plan/09-stack-paquetes.md` (política de dependencias y TTS).
- `docs/legal/PRIVACIDAD.md` y `docs/play/permisos.md` (textos que habrá que
  actualizar).
- PECS: Bondy, A. y Frost, L., *Picture Exchange Communication System*;
  Pyramid Educational Consultants (método y marca de sus titulares).
- Google Play: políticas de Familias, permisos sensibles y Data safety.
- Flutter: `record`, `audioplayers`, `just_audio`, `path_provider` (versiones
  y soporte a verificar en pub.dev al aprobar la fase 2).
