# Repos open source de AAC, pictogramas y educación especial — patrones para BlueTalk (Flutter)

Notas de investigación (subinvestigador). Fuentes citadas inline. Etiquetas de licencia usadas al final de cada repo: ✅ **reutilizable** (permisiva) vs ⚠️ **solo inspiración** (copyleft/NC).

---

## Apps AAC open source: arquitectura de vocabulario y qué aprender de CoughDrop, cboard y otros

### Takeaway
El estado del arte open source de AAC son apps web (CoughDrop/SweetSuite AGPL, cboard GPL): tableros = grids de filas×columnas con navegación entre páginas, sincronización en nube con caché offline, y un servicio de logs/reports para el equipo terapéutico. Todo es ⚠️ solo inspiración por licencia, pero los patrones de datos y features están bien documentados.

### Cited Findings
- **CoughDrop** — app AAC web open source, licencia **AGPL-3.0**, Ruby on Rails + Ember.js + Postgres, corre en navegador y se empaqueta con Cordova para iOS/Android/Kindle/Chromebook/Windows; usa Web Speech API para TTS — [github.com/bcarter/coughdrop](https://github.com/bcarter/coughdrop); [open-aac/sweet-suite-aac](https://github.com/open-aac/sweet-suite-aac) (continuación OpenAAC/CoughDrop, 8★, 6.111 commits, copyright 2014-2025, AGPLv3+, "boards use the Open Board Format", offline con IndexedDB + Application Cache, sync entre dispositivos).
- CoughDrop: los tableros son grids editables con "Grid +/-" para añadir/quirar filas y columnas, un "button stash" (botones guardados), símbolos por defecto de **Open Symbols**, y boards exportables/importables en Open Board Format — [guía rápida CoughDrop (PDF)](https://dd083827-0628-4290-9766-5b43ceca2ad9.filesusr.com/ugd/2b2e96_328ff6e0bd5c41369d3b6afdd4cbb581.pdf); [zendesk CoughDrop: editar boards](https://coughdrop.zendesk.com/hc/en-us/articles/201366809-How-do-I-edit-or-modify-the-contents-of-a-board-in-CoughDrop)
- CoughDrop sincroniza edits en la nube pero **almacena boards y logs en cada dispositivo para comunicar offline**; rol "supervisor" (terapeuta/parent) que edita boards y ve reportes desde su propio dispositivo sin ceder el dispositivo del usuario, con permisos siempre en manos del usuario — [mycoughdrop.com/about](https://www.mycoughdrop.com/about); [README bcarter/coughdrop](https://github.com/bcarter/coughdrop)
- CoughDrop en el roadmap describía: servicio de gramática para tiempos/medias palabras ("auto-tenses"), **"core word service"** que devuelve parte del habla común y variaciones/tensos de una palabra, y Dynamic Scene Displays (vía `CoughDrop/aac_shim`) — [open-aac/sweet-suite-aac README](https://github.com/open-aac/sweet-suite-aac)
- CoughDrop ofrece **vocabulary sets por niveles** ("start basic and grow over time", "vocabulary progression tools", páginasets Quick Core 60/112, CoreWord 6, Vocal Flair, 8+ idiomas) — [coughdrop.com](https://www.coughdrop.com/); [Mada AT portal](https://at.mada.org.qa/technology/coughdrop-aac)
- **cboard** — AAC con TTS para web, **GPL-3.0**, JavaScript, 743★ / 278 forks, creado 2017, commit reciente (~1 mes antes de la página), topics: aac, accessibility, assistive-technology, autism — [olud.ai (agregador con datos de GitHub)](https://olud.ai/project/cboard-org-cboard.html). GPL copyleft: distribuir una versión modificada obliga a abrirla → ⚠️ inspiración.
- **FreeVoice AAC** — MIT, React 19+TS+Vite, Zustand, **Dexie/IndexedDB offline**, PWA Workbox, Kokoro TTS on-device, 570+ symbols en 35 boards; 10★/251 commits (creado 2026-03). Nota: usa símbolos ARASAAC (CC BY-NC-SA) → ⚠️ su código es MIT ✅ pero sus assets no sirven para BlueTalk — [github.com/Chuea81/freevoice-aac](https://github.com/Chuea81/freevoice-aac)
- **Prism AAC** — AGPL-3.0, web+iOS, 25 idiomas, barra "type & speak" con **cinco prediction tiles**, modelo on-device, caregiver notes home/school/clinic; 3★/1.237 commits (creado 2026-04) — ⚠️ inspiración — [github.com/dcostenco/prism-aac](https://github.com/dcostenco/prism-aac)
- **OpenSpeak AAC** — dice MIT/8 idiomas/14.598 símbolos offline, pero **el código real está en repo privado**; el repo público solo tiene docs → nada reutilizable — [github.com/openspeakaac/openspeak-aac](https://github.com/openspeakaac/openspeak-aac)
- **joehunt/aac** — MIT ✅, prototipo (1★, Phase 0) de grid WordPower-60 con `aac-system-requirements.md` de diseño muy detallado: predicción unificada (búsqueda + predicción + temas en una sola tira), morphología in-situ en la barra de frase (plural/conjugación con irregulares), follow-on context pages al tocar verbos, press-and-hold preview, modo stub offline determinista — [github.com/joehunt/aac](https://github.com/joehunt/aac)
- **KylerD/open-speak** — MIT ✅, React Native/Expo, Zustand + MMKV, **fallback offline de predicción = lista estática de palabras por frecuencia**; 0★ — [github.com/KylerD/open-speak](https://github.com/KylerD/open-speak)
- **AugCom** (InterAACtionBox) — PWA open source para niños con múltiples discapacidades: grids editables, librerías de pictogramas integradas, paletas de color propias, impresión PDF, TTS del navegador, offline desde primera visita — [interaactiongroup.github.io/AugCom](https://interaactiongroup.github.io/AugCom). No verifiqué repo/stars/licencia (gap).
- **Asterics AAC (AAC-Cyberdeck)** — fork con 10.559 commits: **"Global grid"** = elementos que aparecen en todas las páginas (core vocabulary transversal), **"progressive language"** = comunicadores por niveles de desarrollo, teclados con word prediction y diccionarios auto-aprendices, mensajería interna vía Matrix, API de ARASAAC — [github.com/cps41/AAC-Cyberdeck](https://github.com/cps41/AAC-Cyberdeck) (licencia no capturada → gap).

### Inferences (traducción a BlueTalk)
- Modelo de datos replicable: `Board(grid rows×cols) → Button{row, col, label, message, image, link_to Board}` + "botones globales" fijos (core vocab) en todas las páginas = lo que Asterics llama global grid y CoughDrop implementa con Quick Core. BlueTalk puede implementarlo en Drift con validación tipo `grid.order == rows*cols`.
- El patrón "offline-first + sync opcional tras flag" de CoughDrop (boards+logs en device, sync al recuperar red) valida la arquitectura de BlueTalk; su rol **supervisor** es el modelo para el Modo Padre (editar boards y ver reportes desde otro dispositivo sin ceder el del niño).
- Publicar el vocabulario por niveles/progresión (básico→creciente) es feature estándar que BlueTalk aún puede diferenciar en español.

### Gaps
- No está claro cuál es el repo canónico upstream de CoughDrop en 2026 (existen `bcarter/coughdrop` 5★/956 commits, `open-aac/sweet-suite-aac` 8★/6.111 commits y `TheOkoNetwork/lozenge` 5.876 commits — este último parece un mirror; no verificado con el org CoughDrop original).
- No obtuve stats directas de GitHub de cboard (datos vía agregador olud.ai).
- `cps41/AAC-Cyberdeck` y `interaactiongroup/AugCom`: licencias no verificadas.

---

## Proyectos Flutter de AAC / pictogramas / autismo en GitHub

### Takeaway
El ecosistema Flutter- AAC es muy pobre: solo encontré dos repos Dart reales (OpenAAC en Apache-2.0 y OTTAA en GPLv3, este último moribundo). No hay ninguna app Flutter AAC madura y bien mantida → BlueTalk tendría el campo casi libre, y lo poco que hay sirve como inspiración o como referencia de arquitectura Supabase.

### Cited Findings
- **RonanOD/OpenAAC** — el único Flutter AAC con código visible: **Apache-2.0 ✅**, 34★/6 forks/119 commits (creado dic-2023). Usa **Flutter + Supabase (Postgres) + Redis Upstash + pgvector + Pinecone (deprecated) + LangChain + OpenAI embeddings** para traducir texto/habla de un "segundo usuario" a pictogramas AAC (match text→symbols). Carpeta `db/` con tools para convertir imágenes a vector embeddings; funciona con cualquier set de símbolos subiendo assets a mano — [github.com/RonanOD/OpenAAC](https://github.com/RonanOD/OpenAAC)
- OpenAAC es motivado explícitamente como alternativa open source a Speak4Yourself (solo iOS); demuestra el patrón **Flutter app + Supabase tras capa de servicios**, casi idéntico al stack de BlueTalk — [github.com/RonanOD/OpenAAC](https://github.com/RonanOD/OpenAAC)
- **OTTAA-Project** — org Argentina ("first predictive augmentative communication platform for speech-impaired children"), repo `ottaa_project_flutter` en **Dart, GPLv3, 13★/3 forks, última actualización ago-2023** (estancado), tags `aac flutter pictograms`; apps Android previas en Java GPLv3; repo `openai_client` con el algoritmo "realiser" (NLG) — [repositorios OTTAA-Project](http://45.136.13.115:8083/orgs/OTTAA-Project/repositories). OTTAA está orientado a español → patrones de pictogramas/NLG en español, pero GPLv3 = ⚠️ inspiración únicamente (copyleft incompatible con app comercial cerrada).
- Búsquedas "flutter AAC / flutter pictogram app / flutter autism" no devolvieron otros repos Flutter de AAC con tracción — [búsqueda general](https://github.com/topics/aac) no muestra apps Flutter destacadas en el topic.

### Inferences
- BlueTalk puede reutilizar código de OpenAAC (Apache-2.0) sin obligaciones más allá de atribución; su parte interesante (indexar assets de símbolos + búsqueda) es compatible con offline-first si se localiza el índice en Drift en vez de Pinecone.
- OTTAA confirma el interés del mercado hispano por "AAC predictivo", pero su código no es reutilizable comercialmente y está sin mantenimiento desde 2023.

### Gaps
- No encontré apps Flutter de "juegos educativos para autismo" open source; el landscape de juegos/rutinas vive en web (ver sección de herramientas).

---

## Formatos abiertos de tableros y datos de vocabulario (OBF/OBZ, OBL, AACProcessors)

### Takeaway
Existe un estándar abierto real para tableros AAC — Open Board Format (.obf JSON / .obz ZIP, MIT) — con librerías nuevas en TypeScript (feb-2026) y un formato hermano de logs anonimizados (.obl). Adoptar OBF/OBZ como formato de import/export da sharing de tableros sin inventar esquema, y es el "patrón de estructura de datos de vocabulario" más citable del ecosistema.

### Cited Findings
- **Open Board Format**: `.obf` = un tablero JSON; `.obz` = ZIP con `manifest.json`, `boards/*.obf`, `images/`, `sounds/`; boards se enlazan entre sí mediante botones de navegación; formato documentado y con atributos de licencia/attribution dentro del archivo — [openboardformat.org](https://www.openboardformat.org/); [docs](https://www.openboardformat.org/docs)
- Validaciones del spec (útiles para el esquema Drift): `grid.order` debe coincidir exactamente con filas×columnas declaradas; botones posicionados exigen `top,left,width,height` ∈ [0,1] (todos juntos o ninguno); un OBZ exige que `manifest.root` esté en `paths.boards` — [shayc/open-board-format README](https://github.com/shayc/open-board-format/blob/main/README.md)
- **shayc/open-board-format** — librería TypeScript con schemas Zod (`OBFBoardSchema`, `OBFButtonSchema`), parse/validate/create de .obf/.obz, spec mirror incluido offline, v1.0.1 jul-2026, **MIT ✅** — [github.com/shayc/open-board-format](https://github.com/shayc/open-board-format) (0★ pero activa, 108 commits desde feb-2026; el formato es el valioso aunque sea TS, no Dart).
- Spec y sitio: **open-aac/openboardformat** (Rails docs + validador .obf + conversor de formatos propietarios + previewer PDF, **MIT ✅**, 8★) — [github.com/open-aac/openboardformat](https://github.com/open-aac/openboardformat); parser Ruby `open-aac/obf` (gem `obf`, conversión .obf/.obz↔PDF/PNG y desde formatos propietarios) — [github.com/open-aac/obf](https://github.com/open-aac/obf/blob/master/README.md)
- **Open Board Logging Format (.obl)** — formato estándar para exportar logs de uso de usuarios, **con anonimización incorporada para compartir logs con fines de investigación** — [openboardformat.org](https://www.openboardformat.org/) (banner "New Board Logging Format Added!").
- Ejemplos reales descargables: `simple.obf`, `links.obz` (multi-board enlazados), `lots_of_stuff.obz` (todos los atributos: imágenes, sonidos, colores, símbolos propietarios, acciones, spelling, licencias, `ext_`), y **CommuniKate 20** (.obz CC BY-NC-SA, grid 5×4, ~1.200 palabras) — [openboardformat.org/examples](https://www.openboardformat.org/examples)
- **AACProcessors** (willwade) — librería Python (**AGPL-3.0 ⚠️**, 4★, 83 commits 2025) + versión Node con más cobertura; lee/convierte `.gridset` (Grid 3), `.obf/.obz` (CoughDrop), `.touchChat`, `.spb` (Snap Core First) a un árbol común `Page{grid, buttons[]{label,message,row,col}}`, con análisis de frecuencia de vocabulario y detección de dead-ends en navegación — [github.com/willwade/AACProcessors](https://github.com/willwade/AACProcessors)
- **LibreAAC** — player de tableros .obz en C++ pensado para trabajar con "Board Builder" — [github.com/LibreAAC/LibreAAC](https://github.com/LibreAAC/LibreAAC)

### Inferences
- BlueTalk debería modelar su tabla de tableros alineada a OBF (grid rows/cols + botones con posición normalizada + enlaces a otros tableros + campos de licencia por símbolo) para poder **importar/exportar OBF/OBZ** y así lograr sharing de tableros con el resto del ecosistema (CoughDrop, cboard, Grid…). El schema Zod de shayc es la referencia de validación más actual.
- El formato **.obl anonimizado** es un diferencial directo para "reporting para terapeutas/investigación": exportar métricas locales de BlueTalk sin datos personales.

### Gaps
- No pude leer el spec completo (fetch de openboardformat.org/docs devolvió vacío); los detalles provienen del mirror del spec incluido en shayc/open-board-format.
- No hay librería Dart/OBF conocida — BlueTalk la tendría que implementar (esfuerzo acotado: JSON + ZIP).

---

## Organización de símbolos: Mulberry, Twemoji, OpenSymbols, Global Symbols — estado, licencias y APIs

### Takeaway
El patrón ganador es un **metadato por símbolo con `locale`, `license`, `search_string` y skin tones** (como hace OpenSymbols), con búsqueda **por concepto** vía Global Symbols API (pública sin key) y agregación tipo OpenSymbols (50k+ símbolos, API con secret). Mulberry (CC BY-SA, 3.116 símbolos) está prácticamente sin mantener; Twemoji sigue vivo vía fork `jdecked` (MIT código / CC-BY 4.0 gráficos).

### Cited Findings
- **Mulberry Symbols** — `mulberrysymbols/mulberry-symbols`: **56★/13 forks, 268 commits, creado 2015**; licencia **CC BY-SA 4.0 ✅ para uso comercial** con atribución + compartir-igual sobre los símbolos ("You can use the symbols in any project or product, commercial or otherwise as long as any distribution gives us clear attribution and the symbols are shared under the same licence") — [github.com/mulberrysymbols/mulberry-symbols](https://github.com/mulberrysymbols/mulberry-symbols/blob/master)
- Estructura del set: SVG en carpeta `EN/`, metadatos en **`symbol-info.csv`**, script `npm run build` genera el ZIP y `categories-en.html`/`categories.pdf` con las **categorías** del set; versión actual en `package.json` — [README](https://github.com/mulberrysymbols/mulberry-symbols); [diff categorías](https://github.com/mulberrysymbols/mulberry-symbols/commit/eca952e952a1664ac040bda48f2ebbcd204a8e7a.diff)
- Org mulberrysymbols: `straight-street-api` está marcado **"Obsolete API"** y `straight-street` (web de descargas) también obsoletos → **no hay API viva de Mulberry**, hay que usar el repo GitHub directo o Global Symbols — [github.com/mulberrysymbols](https://github.com/mulberrysymbols)
- OpenAAC describe Mulberry como **"unmaintained symbol library (3,000 symbols, CC By-SA)"** — [openaac.org/symbols.html](https://www.openaac.org/symbols.html). OpenSymbols reporta **3.116 símbolos Mulberry** y que incluye "more unusual symbols, including many suitable for adult AAC users" — [opensymbols.org/repositories/mulberry](https://www.opensymbols.org/repositories/mulberry)
- **Etiquetas en español de Mulberry existen**: Global Symbols muestra Mulberry con ~20 locales incl. Spanish (p. ej. "Country South Korea / País Corea del Sur") — [globalsymbols.com/symbolsets/mulberry](https://globalsymbols.com/symbolsets/mulberry/symbols/3885?locale=en-GB)
- **Twemoji** — repo original `twitter/twemoji` (17.793★, v14/Unicode 14, sin actualizaciones recientes visibles); el fork mantenedor es **`jdecked/twemoji`** (1.858★, **v17.0/Unicode 17**, última release v17.0.3 ~105 días antes de sep-2026, verdict del tracker "partially maintained — slowing", 57 issues abiertos): **código MIT ✅ + gráficos CC-BY 4.0 ✅** (requiere atribución) — [github.com/jdecked/twemoji](https://github.com/jdecked/twemoji); [tracker.git.tools](https://tracker.git.tools/jdecked/twemoji); [LICENSE-GRAPHICS](https://github.com/twitter/twemoji/blob/master/LICENSE)
- **OpenSymbols** (opensymbols.org, de OpenAAC, Rails OSS en `open-aac/opensymbols`): agregador de **50.000+ símbolos** con licencias por repo: Noun Project 17.165 (mixed), ARASAAC 12.909 (CC BY-NC-SA), Sclera 11.443 (CC BY-NC), **Mulberry 3.116 (CC BY-SA)**, **Twitter Emoji 2.770 (CC BY)**, Tawasol 950 (CC BY-SA), IcoMoon 907, IconArchive 600, LanguageCraft 205 (CC BY-NC-SA), CoughDrop 21 (CC BY) — [opensymbols.org](https://www.opensymbols.org/)
- **OpenSymbols API** (`GET /api/v2/symbols`, requiere shared secret): params `q` (con `repo:`/`favor:`), **`locale` ("es")**, `safe`; la respuesta por símbolo incluye `name, locale, license, license_url, author, repo_key, hc (high-contrast), skins, image_url, unsafe_result` y patrones de skin tones (`varianted-skin.png` / `-varXXXUNI`) — [opensymbols.org/api](https://www.opensymbols.org/api). Es el esquema de metadatos ideal a replicar en el índice local de BlueTalk.
- **Global Symbols API** (`globalsymbols.com/api`, **endpoints públicos sin API key**): `GET /v1/concepts/suggest` (buscar por concepto), `GET /v1/labels/search`, `GET /v1/symbolsets`, `GET /v1/pictos` (símbolos de un set), `GET /v1/languages/active` → **búsqueda cross-idioma concepto→labels→pictos** — [globalsymbols.com/api/docs](https://globalsymbols.com/api/docs)
- Otras librerías abiertas listadas por OpenAAC: **Global Symbols/Tawasol (CC BY-SA, foco cultural, con herramientas de traducción)**, **Sclera (CC BY-NC ⚠️ alto contraste 11k)**, **OpenMoji (CC BY-SA ✅ ~3.000)** — [openaac.org/symbols.html](https://www.openaac.org/symbols.html)
- ARASAAC aparece en OpenSymbols como CC BY-NC-SA (confirmado por metadato por símbolo: `author: Sergio Palao`) — coherente con la decisión de BlueTalk de descartarlo — [opensymbols.org/symbols/arasaac/check-d2bedaac](https://www.opensymbols.org/symbols/arasaac/check-d2bedaac?id=44213)

### Inferences
- Para el buscador offline de pictogramas de BlueTalk: copiar el **esquema de respuesta de OpenSymbols** (name/locale/license/repo_key/search_string/skins/hc) como tabla Drift `symbols`, precargado desde `symbol-info.csv` de Mulberry + metadatos Twemoji; búsqueda `locale='es'` + safe search.
- Las APIs de Global Symbols/OpenSymbols sirven como **inspiración de diseño de query por concepto** (concepto → etiquetas multilingües → pictos), no necesariamente como dependencia online (BlueTalk es offline-first); se pueden usar en build-time para enriquecer el índice.
- Twemoji: verificar atribución CC-BY 4.0 en la app (requisito de licencia) y considerar el fork `jdecked` como fuente actual (Unicode 17).

### Gaps
- No verifiqué cuántos de los 3.116 Mulberry tienen traducción española completa en Global Symbols (vi ejemplos sueltos; las traducciones de terceros en Global Symbols pueden ser de calidad variable).
- No encontré busquedador "por concepto" offline-open con cobertura en español (ConceptNet se cita como fuente de conceptos en OpenSymbols pero sin API concreta verificada).

---

## Predicción de palabra/frase en AAC: qué es replicable offline

### Takeaway
Hay al menos cuatro enfoques offline y ligeros replicables en Dart: (1) lista de frecuencias (fallback de open-speak), (2) n-gramas entrenados (predict4all, Apache-2.0), (3) PPM letra-a-letra (`@willwade/ppmpredictor`), (4) "sem-grams" de co-occurrence para input desordenado de pictogramas (paper SLPAT con fórmula). La predicción LLM existe como capa opcional pero con stub offline obligatorio.

### Cited Findings
- **Predict4All** — librería Java **Apache-2.0 ✅**, 19★/26 commits: modelo n-grama + corrección fonológica/por distancia con reglas personalizables (dislexia/disortografía), **multilingüe en diseño pero solo modelo francés pre-entrenado** (20M palabras Wikipedia+subtítulos, ~112k vocab, `fr_ngrams.bin` + `fr_words.bin`); co-diseñada con terapeutas; integrada en AAC real (LifeCompanion, Sibylle, CiviKey) — [github.com/mthebaud/predict4all](https://github.com/mthebaud/predict4all). Licencia permisiva ✅; al ser Java habría que reimplementar el algoritmo en Dart (concepto: n-grama binario + corrección).
- **PPM letter-by-letter** — `willwade/letter-by-letter-AAC` (React, 101 commits nov-2025) usa **`@willwade/ppmpredictor`** (Prediction by Partial Matching, JS): predicción de siguiente letra + word completion, con **datos de entrenamiento embebidos para 35+ idiomas**, upload/export del vocabulario aprendido, y **juego de práctica incluido** — [github.com/willwade/letter-by-letter-AAC](https://github.com/willwade/letter-by-letter-AAC)
- **Paper "Non-Syntactic Word Prediction for AAC"** (Wiegand & Patel, SLPAT 2012, ACL): predicción a nivel de palabra para selección de **pictogramas en orden no sintáctico** mediante **"sem-grams"** (co-occurrence de palabras dentro de la frase); resultado: sem-grams precisos pero con poca cobertura → híbrido n-gram + sem-gram recomendado — [aclanthology.org/W12-2905](https://aclanthology.org/W12-2905) ([PDF](https://aclanthology.org/W12-2905.pdf))
- Fallback offline de frecuencia: "offline fallback uses a **static frequency-ranked word list** so the app is fully functional without a network connection" — [KylerD/open-speak README](https://github.com/KylerD/open-speak)
- Patrón híbrido LLM+offline: joehunt/aac corre con `claude-haiku` para predicción pero **sin API key cae a "deterministic heuristic predictions and rule-based expansion"**; la tira de predicción unifica búsqueda + predicción + sugerencias de tema — [github.com/joehunt/aac](https://github.com/joehunt/aac)
- CoughDrop tenía en roadmap un **"core word service"** (parte del habla + variaciones/tensos de cada palabra) — útil como servicio local de morfología — [sweet-suite-aac README](https://github.com/open-aac/sweet-suite-aac)
- Prism AAC muestra "five prediction tiles" en la toolbar como layout estándar de predicción — [dcostenco/prism-aac](https://github.com/dcostenco/prism-aac)

### Inferences
- Plan mínimo viable para BlueTalk: tabla `word_stats(word, freq, next_word_counts)` en Drift con frecuencias pre-cargadas en español + bigramas ligeros; tira de predicción unificada con búsqueda del set local (patrón joehunt); adaptar sem-grams (co-occurrence de lo que el niño ya tocó en la frase) es barato porque BlueTalk ya conoce la frase en curso y es exactamente el caso "unordered icon input" del paper.
- Predicción = feature diferenciador en apps AAC en español (las apps comerciales lo tienen; los free/open casi nunca en español).

### Gaps
- No encontré código abierto de predicción entrenado específicamente sobre corpus AAC en español; habría que entrenar bigramas con corpus abierto en español (no investigado aquí).
- No verifiqué si `@willwade/ppmpredictor` publica tamaños de modelo/latencia en gama baja.

---

## Vocabulario núcleo (core vocabulary) en español: recursos existentes

### Takeaway
Sí existen recursos académicos en español, y esta es un hueco real de mercado: la referencia es **Soto & Cooper (2021), "An early Spanish vocabulary for children who use AAC"** (PDF libre), y su adaptación curricular **"School Year of Core-Bilingüe" (SFSU)** da 4 palabras core/mes con materiales — pero **no existe ningún dataset machine-readable con licencia abierta** de core vocab en español; BlueTalk tendría que construirlo citando estas fuentes (diferencial legitimo y verificable).

### Cited Findings
- **Soto, G. & Cooper, B. (2021)** — *An early Spanish vocabulary for children who use AAC: developmental and linguistic considerations*, Augmentative and Alternative Communication 37(1):64-74, DOI 10.1080/07434618.2021.1881822. **Primera lista de léxico inicial en español** para niños que usan CAA, derivada de solapamiento entre listas validadas de desarrollo típico; incluye clases de palabras y categorías semánticas; explícitamente dirigida también a "**software developers**" — [PubMed](https://pubmed.ncbi.nlm.nih.gov/33576262); **PDF libre**: [edrl.berkeley.edu](https://edrl.berkeley.edu/wp-content/uploads/2021/03/Soto_Cooper_2021_pubilshed-Brittney-Cooper.pdf). Citada 32 veces.
- **School Year of Core-Bilingüe (SYOC-B)** — adaptación española de SYOC (SFSU): **4 palabras core por mes** con fichas de actividad en español (agosto: Yo, Soy, Nombre, Gustar; septiembre: El/La, Estoy, Adiós, Arriba/Abajo; octubre: Un/Una, Ver, Bien/Bueno, Más; … hasta mayo), basada en Soto & Cooper 2021; materiales en Padlet — [slhs.sfsu.edu/school-year-core-bilingue-guide](https://slhs.sfsu.edu/school-year-core-bilingue-guide)
- **WordPower en español** — quick reference pública: 4 archivos WP en español (25/48/60 botones) en NovaChat/TouchChat; vocabulario básico = ~80% de la conversación (Marvin, Beukelman & Bilyeu, AAC 1994); código de colores modificado de **Fitzgerald** por clases gramaticales; palabras clave en el centro y clases gramaticales/categorías en los bordes; "una versión con menos botones no es necesariamente más fácil" — [wordpoweraac.com PDF ES](https://wordpoweraac.com/wp-content/uploads/2026/06/WordPower-Vocab-QRGv100-es-us.pdf)
- Conceptos: core = palabras de alta frecuencia 75-80% de la comunicación; **las palabras clave deben mantener la misma posición en todas las páginas para construir plan motor** — [AbleNet SupportHub ES](https://support.ablenetinc.com/es/aac-education-and-resources/why-core-vocabulary-is-on-the-aac-home-page)
- ARASAAC publica tutorial de "cuaderno de comunicación con palabras esenciales" (low-tech): **vocabulario núcleo abajo + repertorios temáticos arriba**, con nota de que "las palabras esenciales varían según el idioma y el entorno" — [aulaabierta.arasaac.org](https://aulaabierta.arasaac.org/en/mini-tutorials-caa-building-communication-notebook-with-essential-words-core-vocabulary-with-pictogramas) (patrón/pedagogía ✅, assets NC ⚠️)
- **Cooper & Soto (2024)**, AAC 40(4): crearon lista de 156 *relational basic concepts* y hallaron que **la mayoría no aparece en ninguna de las 9 core vocabulary lists** examinadas → la frecuencia sola no basta para seleccionar vocabulario — [EDRL Berkeley](https://edrl.berkeley.edu/publications/cooper-b-soto-g-2024-the-prevalence-of-relational-basic-concepts-on-core-vocabulary-lists-for-aac-is-frequency-enough)
- Listas core en inglés para referencia (Toddlers/Preschool/School Age/100 most common) — [nnschools.org Core Vocabulary](https://nnschools.org/assistivetech/vocabulary.html)
- La escasez en español está reconocida en la literatura: "there is a pressing need to rapidly expand such resources for other languages" — [PubMed Soto & Cooper 2021](https://pubmed.ncbi.nlm.nih.gov/33576262)

### Inferences
- **Diferencial BlueTalk**: empaquetar (a) lista inicial de Soto & Cooper 2021 (transcribirla del PDF), (b) progresión SYOC-B de 48 palabras/año como "ruta de aprendizaje" en Modo Padre, (c) adaptación de fichas de frecuencia/funciones pragmáticas; citar fuentes en la app da credibilidad terapéutica que ninguna app comercial en español declara así.
- La advertencia de Cooper & Soto 2024 justifica añadir además "conceptos relacionales" (dentro/fuera/encima/antes/después) al set núcleo — contenido que las apps basadas solo en frecuencia ignoran.
- Nada de esto es "listas oficiales cerradas": el vocabulario core como concepto no está sujeto a copyright (frecuencias y selección factual), pero las **formulaciones exactas de las fichas SYOC-B** son de SFSU → usar como inspiración y reescribir.

### Gaps
- No existe, a mi knowledge, dataset CSV/JSON abierto con licencia de "palabras core en español" — gap confirmado por búsqueda; BlueTalk tendría que generarlo (con atribución a Soto & Cooper).
- No localicé frecuencias de ocurrencia cuantitativas en español para cada palabra de la lista (el paper las describe pero habría que extraerlas del PDF).

---

## Métricas de uso y reporting para terapeutas

### Takeaway
CoughDrop define el estándar de facto de métricas AAC: palabras usadas, core vs fringe, uso por hora del día, "¿quién se queda solo en sustantivos?", actividad por sesión/día, heatmap de pulsaciones, goals con progreso; más el estándar abierto .obl (logs anonimizados) de OpenAAC. Todo medible localmente y luego sincronizado — encaja con offline-first.

### Cited Findings
- CoughDrop tracking individual: "track **individual words used, speech by time of day, and core vs fringe words spoken**", "**heat map of screen presses**", estadísticas por ubicación geográfica — [blog.mycoughdrop.com/in-app-aac-reports-for-organizations](https://blog.mycoughdrop.com/in-app-aac-reports-for-organizations)
- CoughDrop reporting organizacional: goals + progreso, **session activity per day o per usuario**, "Who is communicating and who isn't?", "Who is using their device outside of school?", "**Which users are stuck using only nouns?**" → reports in-app en dashboard — [mismo blog](https://blog.mycoughdrop.com/in-app-aac-reports-for-organizations)
- CoughDrop logs: "**a full view of every word used** by the communicator over a period of time"; logs conectados a mensajería del equipo (padres/maestros/terapeutas) y a compartir mensajes del usuario (redes/email/link) — [blog.mycoughdrop.com/aac-feature-highlight-logs-and-messaging](https://blog.mycoughdrop.com/aac-feature-highlight-logs-and-messaging)
- CoughDrop org management: ver goals, logs, uso y reportes por communicator/supervisor/room, asignar board home a todos, seguimiento de licencias — [zendesk: org management](https://coughdrop.zendesk.com/hc/en-us/articles/360014641751-What-is-CoughDrop-s-org-management-feature)
- **Open Board Logging Format (.obl)**: formato abierto de exportación de logs con **anonimización incorporada para compartir con investigación** — [openboardformat.org](https://www.openboardformat.org/)
- Existe un instrumento formal: "**Core Vocabulary and the AAC Performance Report**" (Katya Hill, PhD & Barry Romich) que incluye **uso de vocabulario core como medida cuantitativa de comunicación** — [nnschools.org](https://nnschools.org/assistivetech/vocabulary.html)
- OpenAAC mantiene herramienta "**CARE Analysis**" en openboardformat.org (menú del sitio) — análisis de tableros; no profundicé en su metodología — [openboardformat.org](https://www.openboardformat.org/)

### Inferences
- Esquema de eventos mínimo para BlueTalk (todo local en Drift, sincronizable tras flag): `utterance_event{symbol_id, word, pos_on_board, timestamp, session_id, modality}` → derivar: mensajes/sesión, palabras únicas/día, ratio core/fringe, ratio sustantivos vs resto, tiempo medio entre toques, repetición de palabra, uso por franja horaria, mapa de calor por celda; export CSV/.obl para el terapeuta.
- El insight "stuck using only nouns" es una métrica concreta, simple y de alto valor clínico, replicable con POS-tagging ligero local.

### Gaps
- No encontré esquema de eventos open source completo (schema JSON) de apps AAC; los detalles de los reportes de CoughDrop están en páginas de marketing, no en specs técnicas.
- No revisé cómo Proloquo2Go/TouchChat (propietarios) miden éxito — fuera de alcance open source.

---

## Herramientas de terapeutas/escuelas, board builders, juegos y rutinas (patrones)

### Takeaway
Las herramientas de terapeutas open source son web (builder de OpenAAC + CoughDrop), y los "engines" de juegos/rutinas para autismo viven como colecciones de mini-apps (TEACCH, timers, reward charts, historias sociales) — el más completo es `yeager/autismapps` (42 apps, CC BY-NC-SA = solo inspiración). Picto-Selector es freeware no-open pero su "pictogram maker" (plural/flechas de tiempo sobre pictograma) es un patrón replicable.

### Cited Findings
- **yeager/autismapps** — SvelteKit PWA con **42 mini-apps AAC/TEACCH** (Talk Board con colores Fitzgerald, PECS Board, Phrase Builder, Social Stories, Visual Timer, Reward Chart, Board Builder, PECS Trainer, Talking Mat…); principios: "**LAMP positioning — buttons never change position across sessions**", targets de 48px, alto contraste, imagen+texto+TTS en cada interacción; stack: **Piper WASM TTS offline**, Web Speech API fallback, **Dexie/IndexedDB** offline, ARASAAC para search; **licencia CC BY-NC-SA 4.0 ⚠️** (no comercial, compartir-igual → inspiración únicamente); 1★/116 commits (creado feb-2026) — [github.com/yeager/autismapps](https://github.com/yeager/autismapps)
- **Picto-Selector** — app **Windows freeware (no open source)** con +30.000 pictogramas (incluye base ARASAAC), creadora de pictogramas combinables (texto, formas, cliparts OpenClipart, avatares Sclera), y añade **marcas de plural (+) y flechas de tiempo verbal (pasado/futuro) sobre el pictograma**, símbolos Sclera, QR, impresión de tableros/rutinas — [Softpedia](https://www.softpedia.com/get/Office-tools/Other-Office-Tools/Picto-Selector.shtml); [tutorial ARASAAC: pictogram maker](https://aulaabierta.arasaac.org/en/picto-selector-14-pictogram-maker); [mejoras: plural/tiempos](https://aulaabierta.arasaac.org/en/new-improvements-and-implements)
- CoughDrop incluye boards de juego/engagement compartidos por la comunidad: "Jokes, digital books, piano boards, choose own story, animal sounds" — patrón de "boards de actividades" integradas al sistema de comunicación — [blog.mycoughdrop.com AAC & Telepractice](https://blog.mycoughdrop.com/aac-telepractice-connecting-online-to-support-communication)
- **OpenAAC.org** — org 501(c)(3) que agrupa CoughDrop, Ace Centre, Global Symbols, SpeakBook, Dasher, cordova_face, webgazer.js (tracking ocular) etc.; sitio del proyecto es OSS (`open-aac/openaac.org`) — [advocacy page](https://github.com/open-aac/openaac.org/blob/master/advocates.html); [openaac.org/symbols.html](https://www.openaac.org/symbols.html)
- **OTTAA** (Esp/Ang): app "predictive" que genera frases desde pictogramas con algoritmo "realiser" (NLG) open source (repo `openai_client`, GPLv3 ⚠️) — patrón: predicción de **frases** completas, no solo palabras — [OTTAA org repos](http://45.136.13.115:8083/orgs/OTTAA-Project/repositories)
- Board builders mencionados por el ecosistema: LibreAAC espera "Board Builder" que exporte .obz — [LibreAAC](https://github.com/LibreAAC/LibreAAC); "Sequoia 15" es un board set open source importable en AsTeRICS Grid — [OMazing Kids comparison](https://omazingkidsllc.com/tag/compare-aac-apps)

### Inferences
- Para BlueTalk: el "modo juegos/rutinas" no tiene un engine open source reutilizable — pero sí un **checklist de mini-apps** que BlueTalk puede reimplementar en Flutter: timer visual con feedback, reward chart, historias sociales, phrase builder con pictogramas, y juegos que refuercen el core vocab mensual (SYOC-B). La regla LAMP (posiciones estables entre sesiones) debe ser una **invariante del layout** de BlueTalk.
- El "pictogram maker" de Picto-Selector (sobreponer +plural / flechas de tiempo sobre el símbolo) es barato de hacer en Flutter (overlay) y muy usado por terapeutas en español.

### Gaps
- No encontré un "board builder" open source moderno específico (la mayoría de builders son parte de apps completas: CoughDrop, AugCom, autismapps Board Builder).
- No investigué a fondo game engines/Flame para juegos educativos (fuera de los repos AAC encontrados).

---

## Mejoras concretas traducibles para BlueTalk (síntesis accionable)

### Takeaway
Todos los hallazgos anteriores se condensan en ~12 mejoras concretas, ordenadas por esfuerzo/valor, con licencia verificada.

### Cited Findings
1. **Import/export OBF/OBZ** (formato abierto MIT, spec + ejemplos + schemas Zod de referencia) → sharing de tableros con el ecosistema AAC y portabilidad sin vendor lock-in — [openboardformat.org](https://www.openboardformat.org/); [shayc/open-board-format](https://github.com/shayc/open-board-format)
2. **Esquema de tablero alineado a OBF** en Drift: `grid rows/cols` con validación `order == rows*cols`, botones con posición normalizada 0-1, enlaces a otros tableros, atributos de licencia por símbolo — [shayc README](https://github.com/shayc/open-board-format/blob/main/README.md)
3. **Índice local de símbolos con metadatos OpenSymbols-style** (`name, locale='es', license, repo_key, search_string, skins, hc`) precargado desde `symbol-info.csv` de Mulberry + Twemoji → búsqueda offline por concepto — [opensymbols.org/api](https://www.opensymbols.org/api); [mulberry repo](https://github.com/mulberrysymbols/mulberry-symbols)
4. **Core vocabulary en español como diferencial**: lista Soto & Cooper 2021 (PDF libre) + ruta anual SYOC-B (4 palabras/mes) + caveat de conceptos relacionales (Cooper & Soto 2024) — [edrl.berkeley.edu PDF](https://edrl.berkeley.edu/wp-content/uploads/2021/03/Soto_Cooper_2021_pubilshed-Brittney-Cooper.pdf); [SYOC-B](https://slhs.sfsu.edu/school-year-core-bilingue-guide)
5. **Colores Fitzgerald + posiciones estables (motor plan)** en todas las páginas y sesiones — [AbleNet ES](https://support.ablenetinc.com/es/aac-education-and-resources/why-core-vocabulary-is-on-the-aac-home-page); [autismapps](https://github.com/yeager/autismapps)
6. **Tira de predicción unificada** (búsqueda + predicción + sugerencias) con fallback offline de frecuencia y bigramas; capa futura de sem-grams co-occurrence para input desordenado de pictogramas — [joehunt/aac](https://github.com/joehunt/aac); [Wiegand & Patel 2012](https://aclanthology.org/W12-2905); [open-speak](https://github.com/KylerD/open-speak)
7. **Métricas estilo CoughDrop** locales: palabras usadas, core vs fringe, ratio de sustantivos, uso por hora del día, sesión/día, heatmap de celdas, goals — [blog CoughDrop reports](https://blog.mycoughdrop.com/in-app-aac-reports-for-organizations)
8. **Export .obl (anonimizado)** para que terapeutas/investigadores reciban logs sin datos personales — [openboardformat.org](https://www.openboardformat.org/)
9. **Modo Padre = rol supervisor CoughDrop**: editar boards y ver reportes desde otro dispositivo sin ceder el del niño, permisos siempre del usuario — [mycoughdrop.com/about](https://www.mycoughdrop.com/about)
10. **Morfología en la barra de frase** (plural/conjugar con irregulares al tocar una palabra ya añadida) + "core word service" local — [joehunt/aac](https://github.com/joehunt/aac); [sweet-suite-aac](https://github.com/open-aac/sweet-suite-aac)
11. **Niveles/progresión de vocabulario** (básico→avanzado, "progressive language") y "global grid" de palabras núcleo fijas en todas las páginas — [coughdrop.com](https://www.coughdrop.com/); [AAC-Cyberdeck](https://github.com/cps41/AAC-Cyberdeck)
12. **Mini-apps de apoyo** (timer visual, reward chart, historias sociales, pictograma con +plural/flechas de tiempo) como extensión del comunicador — [autismapps](https://github.com/yeager/autismapps); [Picto-Selector](https://aulaabierta.arasaac.org/en/picto-selector-14-pictogram-maker)

### Licencias — clasificación rápida
- ✅ **Reutilizable (permisiva)**: `RonanOD/OpenAAC` (Apache-2.0), `predict4all` (Apache-2.0), `shayc/open-board-format` (MIT), `open-aac/openboardformat` + `open-aac/obf` (MIT), `joehunt/aac`, `KylerD/open-speak`, `Chuea81/freevoice-aac` (MIT — código), Twemoji (código MIT + gráficos CC-BY 4.0 con atribución), Mulberry Symbols (CC BY-SA 4.0 con atribución + share-alike sobre los símbolos), OpenMoji (CC BY-SA), Tawasol/Global Symbols (CC BY-SA).
- ⚠️ **Solo inspiración (copyleft duro)**: CoughDrop/SweetSuite (AGPL-3.0), cboard (GPL-3.0), OTTAA (GPL-3.0), Prism AAC (AGPL-3.0), AACProcessors (AGPL-3.0).
- ⚠️ **Solo inspiración (NoComercial)**: ARASAAC (CC BY-NC-SA), Sclera (CC BY-NC), CommuniKate (CC BY-NC-SA), yeager/autismapps (CC BY-NC-SA), repos de symbols bajo NC en OpenSymbols (Noun Project mixed, LanguageCraft…).

### Gaps
- Verificar en build de BlueTalk el texto de atribución exacto que exigen CC BY-SA (Mulberry) y CC-BY (Twemoji graphics), y si el share-alike de Mulberry alcanza al "set derivado de tableros" — asunto legal a confirmar (no hay guía oficial que haya encontrado).
- No evalué riesgo legal de coincidencia de "posiciones de motor plan" con sistemas comerciales (LAMP/WordPower son marcas de vocabulario, no de layout genérico) — fuera del alcance de esta investigación.
