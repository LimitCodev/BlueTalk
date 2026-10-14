# Plan 11 — Fases 1 a 3: de "funcional" a "una joya" publicable

**Para:** el agente que ejecuta (OpenCode). **Requisito previo:** Fase 0 cerrada (`docs/plan/10-fase0-funcional.md`, criterios del Paso 9 cumplidos).
**Origen:** `docs/informes/auditoria-general.md` §4–§7.

> **Exigencia de este plan.** El objetivo no es "que compile". Es que una familia instale el APK, el niño se comunique, los padres confíen, y que Play lo acepte. Si un paso se puede hacer a medias o bien, se hace **bien**. Si algo no se puede verificar, **no se afirma que funciona**: se declara como no verificado.

---

## 0. Estándar de ingeniería (aplica a TODOS los pasos)

### 0.1 Definición de "hecho" (un paso no está hecho si falta algo)

1. **Funciona de verdad:** lo ejecutaste y lo viste funcionar (test, emulador o dispositivo). Compilar no es funcionar.
2. **Probado:** toda lógica con ramas (PIN, límites, recordatorios, migraciones, parsing) tiene tests unitarios que **fallan si la lógica se rompe**. Prueba el caso feliz, el borde y el error.
3. **Sin atajos visibles:** cero `TODO`, cero texto "próximamente", cero `print`, cero pantallas placeholder, cero datos reales o de prueba filtrados.
4. **Estados completos:** cada pantalla con datos remotos/asíncronos maneja carga, vacío y error con texto literal y acción de reintento.
5. **Accesible:** objetivos táctiles ≥48 dp, contraste AA (tokens de `AppColors`), `Semantics` literal en controles sin texto, funciona con texto al 200 % y con el modo calma. Añade el test `accessibility_tools` en toda pantalla nueva (copia el patrón de `test/rutinas/accesibilidad_test.dart`).
6. **Autismo-amigable:** lenguaje literal, sin metáforas; navegación fija y predecible; **ningún sonido ni voz automática** (solo bajo toque); sin parpadeos ni movimiento brusco; los cambios de pantalla son predecibles y reversibles.
7. **Privacidad por diseño:** ningún dato sale del dispositivo. Ninguna cuenta, ningún SDK de analítica, ningún anuncio. Cada permiso nuevo de Android se justifica por escrito en `docs/play/permisos.md`.
8. **Rendimiento (gama baja):** sin trabajo pesado en `build()`; listas con `ListView.builder`/`GridView.builder`; JSON grande o criptografía costosa fuera del hilo de UI (`Isolate.run`); imágenes con `cacheWidth`.
9. **Commit limpio:** un cambio coherente por commit, `TIPO: descripción` (≤70 caracteres), sin texto de IA, sin `Co-Authored-By`. `flutter analyze` (0 problemas) + `flutter test` (todo verde) **antes de cada commit**.
10. **Revisión propia antes de cerrar:** relee tu propio diff como si fueras un revisor hostil. Busca: caso vacío, doble toque, rotación, app en segundo plano, reinicio, reloj cambiado, sin red, sin voz instalada, almacenamiento corrupto.

### 0.2 Reglas de honestidad (obligatorias)

- Nunca escribas "verificado", "funciona" o "pasa" sin haber ejecutado el comando en esta sesión y leído la salida.
- Si no puedes ejecutar algo (sin dispositivo, sin red, falta una herramienta), escríbelo en `docs/informes/faseN-notas.md` como **NO VERIFICADO** con el motivo exacto. No lo rellenes con suposiciones.
- Si un paso contradice la realidad del código, **detente**, documenta la discrepancia y propone el cambio mínimo. No improvises arquitectura.
- Si un test falla, arregla la causa. Prohibido borrar el test, relajar la aserción o añadir `skip` para ponerlo en verde, salvo que el test esté demostrablemente mal (y lo justificas en el commit).

### 0.3 Evidencia por fase

Al cerrar cada fase crea `docs/informes/faseN-evidencia.md` con: salida resumida de `flutter analyze`, `flutter test` (conteo), `flutter build apk --release` (tamaño), lista de lo verificado en dispositivo/emulador, lista de **NO VERIFICADO**, y `git log --oneline` de la fase. Después invoca al subagente **`revisor`** (`.opencode/agents/revisor.md`) sobre la entrega y corrige sus hallazgos de severidad alta antes de continuar.

### 0.4 Dispositivo y emulador

El equipo tiene Android SDK 36. No hay teléfono conectado por defecto.

1. Comprueba: `flutter devices`, `flutter emulators`, `$ANDROID_HOME/emulator/emulator -list-avds`.
2. Si no hay AVD de gama baja, créalo: imagen del sistema API 24 o 28 `x86_64`, RAM 1024 MB, 2 núcleos, pantalla 5". Si faltan imágenes y no hay red, **detente en ese punto y pídelo al usuario**: no sigas fingiendo.
3. Toda verificación de "en dispositivo" se hace aquí. Lo que requiera un teléfono físico (biometría real, voz TTS real en español, notificaciones con la pantalla apagada) va a la lista **NO VERIFICADO — requiere teléfono físico** para que el usuario lo pruebe con el checklist de la Fase 3 (§3.9).

---

# FASE 1 — Que sea confiable (1 semana)

## 1.1 Recordatorios locales de rutina (valor central de las rutinas)

**Hoy:** `AppSettings.remindersEnabled` existe y el paquete `flutter_local_notifications` está declarado, pero **nada programa notificaciones**.

**Requisitos funcionales:**
- Cada actividad habilitada del horario dispara un recordatorio diario a su `timeMinutes`, con texto literal: `Es hora de: <título>.` (sin emojis, sin sonido estridente).
- El interruptor de Ajustes (`remindersEnabled`) activa/desactiva todos. Al desactivar se **cancelan** todos los programados.
- Al crear, editar, quitar o restaurar una actividad, se reprograma **solo esa** (id estable derivado de `entry.id`, por ejemplo `entry.id.hashCode & 0x7fffffff`).
- Sobrevive al reinicio del teléfono: configura el receptor de arranque del plugin.
- Respeta el modo calma (`silent`/sin vibración cuando está activo) y nunca usa audio automático.

**Decisiones técnicas (síguelas; si no encajan, documenta por qué):**
- Usa `zonedSchedule` con `matchDateTimeComponents: DateTimeComponents.time` y `androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle`.
- **No uses alarmas exactas** (`USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM`): Play las restringe a apps de alarma/calendario y rechaza otras. Un recordatorio con ±unos minutos de tolerancia es aceptable; documéntalo.
- Android 13+ exige el permiso `POST_NOTIFICATIONS`: pídelo **desde un botón explícito** en Ajustes ("Activar recordatorios"), con una explicación literal antes. Nunca al arrancar.
- Zona horaria: añade `flutter_timezone` (única dependencia nueva permitida aquí) para `tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()))` e inicializa `timezone` con `tzdata.initializeTimeZones()`.
- Arquitectura: interfaz `RecordatorioScheduler` (`programar(ScheduleEntry)`, `cancelar(String entryId)`, `cancelarTodos()`, `pedirPermiso()`) + implementación real + **doble falso para tests**. Un `Notifier` escucha cambios del horario y de `remindersEnabled`. No metas `flutter_local_notifications` en las pantallas.
- Manifiesto: `RECEIVE_BOOT_COMPLETED`, `POST_NOTIFICATIONS`, y los `receiver` que pide el README del plugin (versión 22.x). **Verifica en el README del plugin instalado** (`~/.pub-cache/hosted/pub.dev/flutter_local_notifications-*/README.md`), no de memoria.

**Tests obligatorios:** al programar una actividad se llama a `programar` con la hora correcta; quitar → `cancelar`; apagar el interruptor → `cancelarTodos`; encender → reprograma las habilitadas; sin permiso concedido no se rompe nada.
**Verificación en emulador:** programa una actividad a +2 min con la app cerrada y comprueba que llega la notificación (`adb shell dumpsys notification | grep BlueTalk`). Reinicia el emulador y comprueba que sigue programada (`adb shell dumpsys alarm | grep bluetalk`).
**Commits sugeridos:** `FEAT: servicio de recordatorios locales` · `FEAT: reprogramar recordatorios al editar el horario` · `FEAT: permiso de notificaciones desde ajustes`.

## 1.2 Seguridad del PIN y de los datos

Archivo: `lib/features/padre/gate/pin_store.dart` (+ `gate_screen.dart`).

1. **PIN de 6 dígitos para PIN nuevos** (`^\d{6}$`). Los PIN de 4 dígitos ya guardados **siguen funcionando** (migración sin pérdida de acceso): guarda `padre_pin_len` y valida con la longitud almacenada. Ofrece "Cambiar código" en Control del modo padre que obligue a 6.
2. **Iteraciones PBKDF2:** sube a 100 000 **solo si mides ≤ 500 ms** en el AVD de gama baja. Guarda las iteraciones usadas junto al hash (`padre_pin_iter`; ausente = 10 000 del esquema antiguo) y, tras un acceso correcto con un hash antiguo, **re-hashea con los parámetros nuevos**. Ejecuta la derivación en `Isolate.run` para no congelar la UI. Documenta la medición real en `docs/informes/fase1-evidencia.md`. Si no llega a 100 000, elige el máximo que cumpla y justifícalo.
3. **Bloqueo escalonado:** 5 fallos → 60 s; los ciclos siguientes duplican la espera (60, 120, 300, 900 s, tope 900 s). Persiste el nivel. Resetea al acertar.
4. **Reloj manipulado:** si `ahora()` es anterior al instante guardado de inicio del bloqueo (el usuario atrasó el reloj), **mantén el bloqueo** y no lo acortes. Guarda `padre_pin_bloqueo_desde` además de `..._hasta`. Test incluido.
5. **Recuperación de PIN olvidado:** pantalla literal en el gate: "¿Olvidaste el código?" → explica que se borrarán el progreso, el horario y los ajustes de este dispositivo, exige confirmar **escribiendo la palabra `BORRAR`**, y después limpia **todas** las claves de `SharedPreferences` (`prefs.clear()`) y vuelve a `/onboarding`. Test de widget del flujo completo.
6. **Copias de seguridad:** en `AndroidManifest.xml` añade `android:allowBackup="false"` y `android:fullBackupContent="false"` (y `android:dataExtractionRules` vacío para Android 12+) para que el PIN y los datos del niño no suban a la nube de Google.
7. `flutter_secure_storage` **no se usa** (no hay beneficio real con PIN de 6 dígitos que se guarda hasheado). No lo reintroduzcas.

**Tests obligatorios (ampliar `test/padre/pin_store_test.dart`):** migración 4→6 dígitos, re-hash tras login, bloqueo escalonado, reloj atrasado, formatos inválidos, almacenamiento corrupto.
**Commits:** `FEAT: pin de 6 digitos con migracion del anterior` · `FEAT: bloqueo escalonado y reloj manipulado` · `FEAT: recuperar el modo padre borrando datos` · `FIX: desactivar copias de seguridad en la nube`.

## 1.3 Calidad y rendimiento medidos

1. Añade en `analysis_options.yaml` reglas estrictas: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `avoid_print`, `unawaited_futures`, `use_build_context_synchronously`, `cancel_subscriptions`, `close_sinks`. Corrige lo que aparezca (no uses `// ignore` salvo caso justificado).
2. **Perfilado real:** `flutter run --profile` en el AVD de gama baja. Mide y anota en `docs/informes/fase1-evidencia.md`: arranque en frío (objetivo <3 s), RAM de pico (<150 MB, `adb shell dumpsys meminfo com.limitcodev.bluetalk`), y fotogramas lentos al desplazar la grilla del comunicador (DevTools o `flutter drive --profile` con `traceAction`).
3. **Grilla de SVG:** si hay tirones, aplica por orden: `cacheWidth` equivalente / `SvgPicture` con `RepaintBoundary` por celda → precarga del caché → rasterizar a PNG de 128 dp en tiempo de build (script en `scripts/`). Mide antes y después; commit con las cifras.
4. Tope de `ImageCache` (50 imágenes / 20 MB) al arrancar si la RAM es ≤3 GB (plan 00 §3.1).
5. La **galería del Artista** guarda los trazos como JSON en `SharedPreferences` (`artista_dibujos.dart`). Pon un **tope de dibujos** (p. ej. 30) y de puntos por dibujo; al llegar al tope, avisa en lenguaje literal y pide borrar uno. Sin esto, las preferencias crecen sin límite y ralentizan el arranque. Test incluido.

**Commits:** `CHORE: lints estrictos` · `PERF: ...` (con cifras reales en el mensaje) · `FIX: limitar la galeria del artista`.

## 1.4 Cierre de Fase 1
Escribe `docs/informes/fase1-evidencia.md` (§0.3), ejecuta al revisor y corrige lo grave.

---

# FASE 2 — Que sea una joya (el diferenciador)

> Orden de valor para una familia. **Cada elemento nuevo entra de uno en uno**, sobre la base ya probada (plan 00 §8: "base antes que gadgets"). No empieces el siguiente sin cerrar el anterior con tests y commit.

## 2.1 Vocabulario nuclear de 200+ palabras en posiciones fijas

**Por qué:** en comunicación aumentativa, el vocabulario nuclear (palabras frecuentes: *quiero, más, no, ayuda, ir, mío…*) debe estar **siempre en el mismo sitio** para que el niño desarrolle memoria motora. Es el criterio de calidad nº 1 de una app AAC.

**Insumos:** `research_notes/datos-publicos/soto-cooper-2021-lista-218-palabras.md` (lista de investigación) y `research_notes/Apps AAC autismo y mejoras BlueTalk/`. Léelos antes de diseñar.

**Pasos:**
1. **Fuente de pictogramas:** Mulberry Symbols (CC BY-SA 4.0, https://mulberrysymbols.org). Descarga el paquete SVG oficial **en un directorio nuevo y vacío fuera del repo**, comprueba el texto exacto de la licencia y su archivo de atribución, y copia al repo **solo los SVG que uses**. Nunca mezcles con ARASAAC (CC BY-NC-SA, no comercial: prohibido, plan 00 §3).
2. **Presupuesto de tamaño:** cada SVG ≤ 20 KB; si alguno es mayor, simplifícalo o descártalo. Total de `assets/pictos/` ≤ 3 MB. Mide y anota.
3. **Modelo:** añade a `Pictogram` el campo opcional `order` (int). Añade a `Category` un tipo `nuclear` frente a `tematica` **sin romper** los seeds actuales (valores por defecto). Actualiza `fromMap`/`toMap` y los tests de `test/core/models_test.dart`.
4. **Tablero nuclear:** una categoría "Palabras básicas" (primera en el inicio) con la grilla en orden **estricto por `order`**. **Nunca se reordena por uso, ni por favoritos, ni por búsqueda.** Colorea por clase gramatical con los tokens de `AppColors` (Fitzgerald modificado: verbos, descriptores, pronombres, etc.), manteniendo contraste AA y sin depender solo del color (la etiqueta siempre visible).
5. **Datos:** amplía `assets/seed/pictogramas.json` y `categorias.json`. Escribe etiquetas en español neutro latinoamericano, **una palabra o frase corta literal**, con `keywords` para búsqueda.
6. **Test de integridad del seed** (nuevo, `test/data/seed_integrity_test.dart`): todo `asset` referenciado existe en disco; ids únicos; todo `categoryId` existe; ninguna etiqueta vacía; `order` sin duplicados dentro de la categoría nuclear; tamaño máximo por SVG. Este test debe **fallar** si alguien rompe el seed.
7. **Créditos y licencia:** actualiza `ajustes_screen.dart` (sección Créditos) con atribución completa de Mulberry y, si se usa, Twemoji (verifica que realmente esté en uso; si no, retira la mención de `textos_legales.dart`). Cumple CC BY-SA 4.0: indica autoría, licencia, enlace y si se modificó el material.
8. **Buscador** simple por etiqueta y `keywords` (sin red). Debe responder instantáneamente con 300+ elementos.

**Verificación:** grilla de 200+ pictogramas desplaza sin tirones en el AVD (medido); orden idéntico tras reiniciar; test de integridad en verde.
**Commits:** `FEAT: modelo de pictogramas con orden fijo` · `FEAT: tablero de palabras basicas` · `FEAT: ampliar vocabulario con mulberry` · `TEST: integridad de los seeds` · `DOCS: creditos y licencias de pictogramas`.

## 2.2 "Primero–Luego" y avisos de transición

- En Rutinas, vista **Primero → Luego**: dos tarjetas grandes (la actividad actual y la siguiente, con pictograma). Tocar "Listo" marca la actual como hecha y avanza. Sin cuentas regresivas agresivas; opcional un temporizador visual **estático** (barra que se llena despacio, sin animación en modo calma).
- Reutiliza `proximaActividadProvider` y `marcarActividad`; **no dupliques lógica**.
- Aviso previo opcional (5 min antes) reutilizando el servicio de §1.1.
- Test de widget del flujo completo y de accesibilidad.
**Commits:** `FEAT: vista primero y luego en rutinas`.

## 2.3 Pictogramas y fotos propios (solo en el dispositivo)

**Por qué:** los niños aprenden más rápido con su propia mamá, casa o juguete.
- Añade `image_picker` y `path_provider` (justifica cada una en el commit). Usa los parámetros `maxWidth: 512, maxHeight: 512, imageQuality: 80` del propio `image_picker`, **sin añadir librería de imágenes**. No pidas permiso de cámara/galería propio: usa los selectores del sistema (sin `READ_MEDIA_*`).
- Guarda las imágenes en el directorio de documentos de la app. El catálogo mezcla seeds y personales (`origen: usuario`); metadatos en `SharedPreferences`.
- **Solo adultos:** crear/editar/borrar pictogramas propios exige la sesión del modo padre (PIN). El niño solo los usa.
- Límite de 100 pictogramas propios; manejo de error si falla la imagen, el disco está lleno o el archivo desapareció (muestra el icono de respaldo, nunca un hueco).
- **Privacidad:** las fotos nunca salen del dispositivo; declara esto en `PRIVACIDAD.md` y que son datos de un menor.
- Borrar un pictograma propio lo quita de frases guardadas y de horarios que lo usaban (prueba la limpieza referencial).
**Commits:** `FEAT: pictogramas propios con foto` · `FIX: limpiar referencias al borrar un pictograma propio`.

## 2.4 Voz y copia de seguridad

- **Voz:** en Ajustes, selector de voz del sistema en español (`flutter_tts.getVoices` filtrado `es`) + botón "Probar voz" (solo bajo toque) + velocidad y tono ya existentes. Si no hay voz en español: guía literal para instalarla desde los ajustes del sistema (intent de ajustes TTS), no solo un aviso.
- **Exportar/importar copia:** archivo JSON local (horario, perfil, favoritos, mensajes guardados, pictogramas propios en base64 o carpeta), **sin el PIN ni su hash**. Compartir con la hoja del sistema (`share_plus`, justificar la dependencia) e importar con el selector del sistema. Versiona el formato (`"version": 1`) y valida al importar (rechaza archivos corruptos sin tocar los datos actuales; todo-o-nada). Tests de ida y vuelta y de archivo malformado.
- Reporte de uso para terapeuta: PDF o texto resumido de la semana (frases, ánimo, hábitos) **con el disclaimer** "orientativo, no es diagnóstico". Solo desde el modo padre. Es opcional: hazlo solo si 2.1–2.4 están cerrados.
**Commits:** `FEAT: seleccion de voz en español` · `FEAT: exportar e importar copia de seguridad` · `FEAT: resumen semanal para terapeuta`.

## 2.5 Backlog (NO empezar sin una nota de diseño de 1 página en `docs/plan/` aprobada por el usuario)

- Varios perfiles (hermanos/aula): exige prefijar **todas** las claves de preferencias por perfil y migrar las actuales. Riesgo alto, valor alto: diseño primero.
- Historias sociales editables por el padre.
- Voz grabada de un familiar (exige `RECORD_AUDIO`; implicaciones de privacidad de un menor: diseño legal primero).

## 2.6 Cierre de Fase 2
`docs/informes/fase2-evidencia.md` + revisor + corrección de hallazgos graves.

---

# FASE 3 — Play Store

## 3.1 Identidad y manifiesto
- `android:label="BlueTalk"` (no `bluetalk`). Revisa `applicationId` `com.limitcodev.bluetalk` (el identificador **no se puede cambiar** tras publicar: confirma con el usuario antes).
- Revisa `minSdk` (Flutter da 24) y `targetSdk` (36); confirma que cumple el requisito de Play vigente (**verifícalo en la documentación oficial de Play Console en el momento, no de memoria**).
- Permisos: lista final en `docs/play/permisos.md` con la justificación de cada uno (`POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, biometría `USE_BIOMETRIC`). **Ningún permiso de `INTERNET`** salvo necesidad probada: sin él la promesa "100 % offline y sin datos" es verificable por el propio Android.

## 3.2 Icono y marca
Icono adaptativo (primer plano + fondo celeste `#7FC9EA`) y versión monocroma (Android 13). Usa `flutter_launcher_icons` como dev-dependency (justifícala). Diseño simple y legible a 48 px.

## 3.3 Firma de release (nunca subas claves)
1. Crea `android/key.properties` y un keystore de subida **fuera del repo** (ambos ya están en `.gitignore`: verifica con `git check-ignore`).
2. Lee `key.properties` en `android/app/build.gradle.kts` y define `signingConfigs.create("release")`; elimina `signingConfigs.getByName("debug")` del `release`.
3. **Pide al usuario** que genere el keystore y guarde copia de seguridad cifrada en dos lugares. Si lo pierde, no podrá actualizar la app. Documenta el comando exacto en `docs/play/firma.md` (`keytool -genkey -v -keystore ... -keyalg RSA -keysize 2048 -validity 10000 -alias upload`) pero **no lo ejecutes con contraseñas inventadas por ti**.
4. Activa Play App Signing (lo hace el usuario en Play Console).

## 3.4 Reducción y ofuscación
- `isMinifyEnabled = true` y `isShrinkResources = true` en `release`; añade reglas ProGuard solo si hacen falta.
- Construye con `flutter build appbundle --release --obfuscate --split-debug-info=build/symbols` y guarda los símbolos **fuera del repo**.
- **Verifica el build release en el AVD:** instala el APK release (`flutter build apk --release --split-per-abi`), recorre todas las pantallas, comprueba notificaciones y TTS. Un release minificado puede romper plugins que el debug no rompe.
- Objetivo de tamaño: APK por ABI ≤ 15 MB (plan 00 §10). Mide y reporta; si se pasa, identifica con `flutter build apk --analyze-size` qué pesa.

## 3.5 Política de privacidad pública
Play exige una **URL pública**. Genera una página estática desde `docs/legal/PRIVACIDAD.md` (carpeta `docs/site/` lista para GitHub Pages). **No publiques ni hagas push**: deja listo el contenido y pide al usuario que lo publique. Comprueba que el texto describe lo que la app realmente hace (sin red, sin cuentas, datos solo en el dispositivo, fotos propias solo locales, notificaciones locales) y que nombra un contacto **de demostración o el que indique el usuario**.

## 3.6 Formularios de Play (rellena borradores en `docs/play/`)
- `docs/play/seguridad-datos.md`: respuestas del formulario "Seguridad de los datos" (no se recopilan ni comparten datos; si se mantiene así, es verificable).
- `docs/play/familias.md`: política para Familias (público objetivo con menores: sin publicidad de terceros, sin SDK de analítica, contenido apto). Declara los públicos objetivo con el usuario.
- `docs/play/clasificacion.md`: cuestionario de clasificación de contenido.
- `docs/play/ficha.md`: título (≤30), descripción corta (≤80) y larga en español; **sin afirmaciones médicas** (nada de "trata", "cura", "diagnostica", "mejora el autismo"); pide a un profesional que valide el lenguaje. Lista de capturas necesarias (teléfono y tableta si aplica) y texto de cada una.
- `docs/play/lanzamiento.md`: checklist de publicación y calendario de pruebas. **Verifica en la documentación oficial vigente** si las cuentas personales nuevas requieren un periodo de prueba cerrada con un mínimo de testers antes de producción, y cuánto dura; anótalo con la fecha de consulta.

## 3.7 Legal
- Alinea los **Términos** (`textos_legales.dart` y `docs/legal/TERMINOS_Y_CONDICIONES.md`) con el modelo de negocio **que decida el usuario** (hoy dicen "uso personal y no comercial"; si habrá Premium o no, el texto debe coincidir). **No decidas tú: pregunta.**
- Marca que los textos **no son asesoría legal** y que se recomienda revisión profesional para las jurisdicciones de destino (Perú: Ley 29733 de datos personales, y las normas de las tiendas; si se distribuye en la UE/EE. UU., GDPR-K/COPPA).
- Revisión de licencias: `docs/play/licencias.md` con cada recurso de terceros (Mulberry, fuentes, paquetes de `pubspec.lock` relevantes) y su obligación.

## 3.8 CI mínimo
`.github/workflows/ci.yml`: `flutter pub get`, `flutter analyze`, `flutter test` en cada push/PR (versión de Flutter fijada). No incluyas firma ni secretos. **No hagas push**: deja el archivo listo.

## 3.9 Checklist para el usuario en teléfono físico (genéralo en `docs/play/prueba-en-telefono.md`)
Un documento corto, paso a paso, con casilla por prueba: instalar el APK release; onboarding sin apodo; hablar con 5 pictogramas **con voz real en español**; guardar un mensaje; crear actividad y recibir el recordatorio con la **pantalla apagada**; reiniciar el teléfono y verificar que el recordatorio sigue; crear PIN, cerrar sesión, huella/rostro; probar el bloqueo tras 5 fallos; recuperar PIN; límite de juegos; modo calma; rotación; texto al 200 %; modo avión (todo debe funcionar); desinstalar (los datos se borran). Con una columna "Resultado" y "Observaciones".

## 3.10 Cierre
`docs/informes/fase3-evidencia.md`, revisor, y un resumen final de **qué falta y qué decide el usuario** (keystore, dominio de la política de privacidad, modelo de negocio, públicos objetivo, cuenta de desarrollador de Play).

---

## Anexo — Cosas que NO debes hacer

- No añadas Supabase, Firebase, analítica, crash reporting con red, anuncios ni inicios de sesión.
- No añadas dependencias que no estén justificadas en este plan sin pedirlo al usuario.
- No uses ARASAAC ni imágenes sin licencia comprobada.
- No hagas `git push`, no publiques nada, no crees cuentas.
- No inventes contraseñas, datos de contacto, nombres de personas ni datos de menores.
- No des por buena una función que solo viste compilar.
