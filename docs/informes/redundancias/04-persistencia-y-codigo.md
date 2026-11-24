# Redundancias — persistencia y código

La app guarda todo en `SharedPreferences` (decisión del MVP) con un patrón que
se repite en diez archivos. No es un botón duplicado, pero es la duplicación
que más mantenimiento cuesta: cada cambio de formato hay que hacerlo diez
veces y es fácil que una lectura quede más permisiva que otra.

## R-08 · El mismo “leer JSON → mapear → reescribir todo” en diez sitios (P2, M)

**Dónde y qué guarda cada uno**

| Archivo | Clave(s) | Forma | Cuándo escribe |
|---|---|---|---|
| `lib/data/local/repo_uso.dart` | `bluetalk_usage` | lista de eventos | cada evento |
| `lib/data/local/repo_bienestar.dart` | `bluetalk_moods`, `bluetalk_habits` | dos listas | cada check-in / hábito |
| `lib/data/local/repo_perfil.dart` | `bluetalk_profile` | objeto | al guardar el perfil |
| `lib/data/local/repo_ajustes.dart` | `bluetalk_settings` | objeto | cada cambio de ajuste |
| `lib/data/local/repo_horario.dart` | `bluetalk_schedule` | lista de entradas | cada actividad guardada |
| `lib/data/local/repo_progreso_juegos.dart` | `bluetalk_game_progress` | lista de avances | al terminar nivel |
| `lib/features/comunicador/saved_messages.dart` | `bluetalk_saved_messages` | lista de mensajes | guardar / borrar |
| `lib/features/juegos/artista/artista_dibujos.dart` | `bluetalk_artista_dibujos` | lista de dibujos | guardar / borrar |
| `lib/features/padre/informes/resumenes_repo.dart` | `bluetalk_resumen_AAAA-MM` | mapa día → resumen | cada evento (decorador) |
| `lib/features/padre/filtro_web/filtro_web_controller.dart` | 10 claves (`padre_filtro_web_*`) | 6 bool + 4 listas JSON | cada cambio del filtro |

Los seis primeros viven en `lib/data/local/` y usan `SharedPreferences`
directamente (permitido por `test/arquitectura/capas_test.dart`); los cuatro
restantes usan `AlmacenLocal`. Las dos puertas son correctas, pero el código
de alrededor no se comparte.

**Qué se repite**

1. **Caché en memoria**: `List<T>? _cache`, `Map<K,V>? _cache` o un `bool
   _loaded`; en las features el propio estado del `Notifier` hace de caché.
2. **Decodificación tolerante**: `tryDecodeList`/`tryDecodeObject` en
   `data/local`; a mano en `saved_messages` y `artista_dibujos`.
3. **Reescritura completa** de la colección en cada cambio.
4. **Claves como literales** repartidos; solo `FiltroWebPrefs` las agrupa.
5. **Política ante datos corruptos distinta**: `repo_perfil` y `repo_ajustes`
   borran la clave y vuelven a valores por defecto; `repo_uso` y los demás
   devuelven vacío sin borrar; `saved_messages` atrapa `FormatException` y
   `TypeError`; `artista_dibujos` atrapa todo.

Ninguna de esas diferencias es un fallo hoy, pero todas son decisiones
implícitas que nadie documentó y que se pueden perder en la siguiente copia.

### Fix pequeño: un ayudante `JsonPrefs`

Crear `lib/core/almacen/json_prefs.dart` (por debajo del tope de 100 líneas)
que envuelva `AlmacenLocal`, no `SharedPreferences`:

```dart
class JsonPrefs {
  const JsonPrefs(this._almacen);
  final AlmacenLocal _almacen;

  List<Map<String, dynamic>> leerLista(String clave) { ... }
  Map<String, dynamic>? leerObjeto(String clave) { ... }
  Future<void> guardarLista(String clave, Iterable<Map<String, dynamic>> filas) { ... }
  Future<void> guardarObjeto(String clave, Map<String, dynamic> objeto) { ... }
}
```

- Usa los mismos ayudantes tolerantes de `json_seguro.dart`. Ese archivo puede
  moverse a `lib/core/almacen/` para que las features no dependan de
  `data/local`; los repos de `data/local` solo cambian el import.
- No intenta conocer los modelos: recibe y devuelve mapas. Cada repo sigue
  haciendo su `fromMap`/`toMap`.
- No crear una clase base de repositorio: los contratos son distintos y el
  trinquete de 100 líneas lo impediría.

### Qué NO meter en el ayudante

- **Debounce** o agrupación de escrituras: eso es una decisión de cada flujo
  (ver PERF-CORE-01 y PERF-CORE-02). Si se mete aquí, todos los guardados
  heredan una pérdida de datos que quizá no quieren.
- **Migraciones**: cada clave conserva su formato; migrar es código del repo.
- **Cifrado**: hoy no hay; si llega, va en `AlmacenLocal`.

### Registro de claves (opcional, P2)

Un `lib/core/almacen/claves.dart` con las claves usadas permitiría:
- una pantalla futura de “borrar todos mis datos” que no olvide ninguna;
- comprobar en un test que no hay literales `'bluetalk_...'` fuera del
  registro (igual que el test de capas).

No es urgente y no debe hacerse a la vez que `JsonPrefs`: primero el ayudante,
luego el registro. Hay claves que no deben borrarse con “borrar todo” (por
ejemplo `padre_legal_aceptacion` o la huella del PIN), así que el registro
tendría que distinguir “datos del menor” de “configuración del adulto”.
**Decisión de producto pendiente** si se quiere esa pantalla.

## R-22 · Helpers que ya están centralizados (verificado, no tocar)

- `normalizarDominio` y `normalizarPalabra` viven solo en
  `lib/features/padre/filtro_web/filtro_web_model.dart:383` y `:428`. El
  controlador y el modelo las comparten; no hay copias.
- `claveDia` y los ayudantes de fecha están en
  `lib/features/padre/informes/dia.dart` y se usan desde los resúmenes.
- `SeedStore` cachea los JSON de `assets/seed/`; no hay dos lectores.
- `tryDecodeObject`/`tryDecodeList` ya existen; el problema es que solo los
  usan los repos de `data/local`, no las features (lo arregla R-08).
- `AlmacenLocal` es la única puerta para las features; el test de capas lo
  comprueba y no hay excepciones fuera de `data/local` y `di.dart`.

## R-23 · Cabeceras y controles repetidos (ya cubiertos)

Para no duplicar trabajo, esto vive en los otros documentos:

| Duplicado | Documento |
|---|---|
| Siete cabeceras “Volver” | `01-navegacion-y-cabeceras.md` (R-01) |
| Modo calma en cinco sitios | `02-ajustes-y-modos.md` (R-04) |
| Velocidad de voz en dos sliders | `02-ajustes-y-modos.md` (R-05) |
| Cuatro cargas del catálogo de pictos | `03-comunicador-y-juegos.md` (R-19) |
| `_pictoPorId` de Memoria recorre la lista | `03-comunicador-y-juegos.md` (R-19) |

## Orden recomendado para pagar esta deuda

1. **No hacer nada todavía** si solo se busca rendimiento: el coste real está
   en *cuándo* se escribe, no en *cómo* se codifica (PERF-CORE-01/02).
2. Cuando se toque el primer repo por otro motivo, extraer `JsonPrefs` y migrar
   ese repo como prueba. Si sale bien, migrar los demás de uno en uno.
3. El registro de claves, solo si se decide hacer “borrar mis datos”.

## Cómo comprobarlo

- Test de unidad de `JsonPrefs`: lista válida, JSON corrupto, fila que no es
  mapa, objeto vacío, escritura y relectura.
- Test de cada repo migrado: guardar, recargar con una instancia nueva y
  comparar; y leer el formato viejo para asegurar que no se pierden datos.
- `flutter test test/arquitectura/` debe seguir en verde: `JsonPrefs` no puede
  importar `shared_preferences`.

**Riesgo** bajo por repo, medio en la migración conjunta. Hacerlo en tandas
pequeñas, nunca en un solo commit con los diez archivos.
