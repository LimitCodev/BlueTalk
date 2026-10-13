# Datasets (Kaggle/UCI/repositorios) sobre autismo, AAC, símbolos y educación especial — qué serviría para BlueTalk

Investigación basada en búsqueda web (Kaggle, UCI, TalkBank, HuggingFace, artículos revisados por pares, prensa). Nota importante: **las páginas de Kaggle no se pudieron leer directamente** (son JavaScript y el fetch devuelve vacío); los datos de Kaggle provienen de snippets de búsqueda y papers que los citan — verificado = leído en fuente primaria; no verificado = marcado explícitamente como gap.

---

## Pregunta 1 — Datasets de "autism" en Kaggle/UCI: cuáles son fiables y cuáles se descartan por ética/calidad

### Takeaway
Los datasets de screening clínico de autismo (UCI/Kaggle) son **fiables como CSV tabular pero inútiles y peligrosos para BlueTalk**: etiquetas de screening (no diagnóstico), basados en cuestionarios AQ-10/CHAT pensados para clínicos, y su uso en una app de comunicación violaría el diseño "no diagnóstico" de BlueTalk. Los datasets de **fotos faciales de niños autistas en Kaggle son una estafa ética confirmada** — causaron 38 retractaciones en 2026 — y deben descartarse categóricamente.

### Cited Findings
- **UCI "Autistic Spectrum Disorder Screening Data for Children"** (id 419, Thabtah 2017, DOI 10.24432/C5659W): datos de screening por clasificación, niños. Los datasets UCI se publican con licencia **CC BY 4.0** (así figura en las fichas de UCI, ej. la página del dataset 458 que sí pudimos leer muestra CC BY 4.0). — [UCI dataset 419](https://archive.ics.uci.edu/dataset/419/autistic+spectrum+disorder+screening+data+for+children); [UCI](https://archive.ics.uci.edu/datasets)
- **Kaggle "Autism screening data for toddlers" (autor "Fadi")**: 1050 registros de niños 18–36 meses, 18 atributos (puntuaciones AQ-10 + observaciones parentales), usabilidad 5.3, ~18.1K descargas, 41 notebooks. Es el dataset "toddler" usado por decenas de papers de ML. — [Kaggle (snippet)](https://www.kaggle.com/datasets?search=Autism); [paper 2025 que lo describe](https://www.sciencedirect.com/science/article/pii/S2772442524000819)
- **Kaggle "Early Autism Screening Dataset for Toddlers" (ajithdari)**: 1000 filas × 11 columnas descrito como "combinación de antecedentes médicos, historia familiar e indicadores conductuales" — por la descripción parece **sintético o recombuido**, no recolección clínica original. No verificado en detalle. — [Kaggle (snippet)](https://www.kaggle.com/datasets/ajithdari/early-autism-screening-dataset-for-toddlers/versions/1)
- **Kaggle "Autistic Spectrum Disorder Screening for Children" (ashishpawar511)**: espejo del dataset UCI de Thabtah. — [Kaggle](https://www.kaggle.com/datasets/ashishpawar511/autistic-spectrum-disorder-screening-for-children)
- **ESCÁNDALO DE LAS FOTOS FACIALES (marzo 2026)**: Springer Nature retractó **38 publicaciones** que usaron un dataset de Kaggle con >2.900 fotos de niños raspadas de webs de autismo (sin consentimiento, sin prueba de diagnóstico). IEEE puso "expressions of concern" en **25 artículos**; Elsevier y PLOS también retractaron. El dataset fue borrado de Kaggle por su autor en 2022 pero **sigue vivo en Google Drive y hay réplicas de otros usuarios en Kaggle**. — [MedPage Today, 19 mar 2026](https://www.medpagetoday.com/special-reports/features/120378); [The Transmitter](https://www.thetransmitter.org/retraction/exclusive-springer-nature-retracts-removes-nearly-40-publications-that-trained-neural-networks-on-bonkers-dataset/)
- **Q-CHAT como base**: el instrumento detrás del dataset toddler es el Q-CHAT (checklist de screening para 18–30 meses, Baron-Cohen). Existe también un dataset Mendeley con puntuaciones Q-CHAT de **252 toddlers polacos** (135 con sospecha/confirmación comunitaria). — [Autism Research Centre](https://www.autismresearchcentre.com/tests/quantitative-checklist-for-autism-in-toddlers-q-chat/); [Mendeley Data](https://data.mendeley.com/datasets/tmpkt2mfkg/1)
- Kaggle tiene muchos papers de ML sobre estos datasets, incluidos **retractados por calidad/ética** (ej. paper de deep learning sobre "autism facial dataset" retractado en Springer). — [Springer (retractado)](https://link.springer.com/article/10.1186/s12888-024-06116-0)

### Inferences (acción para BlueTalk)
- **DESCARTADO para el producto**: cualquier dataset de screening (toddlers/children/adults). BlueTalk no hace diagnóstico por diseño; usar sus features (AQ-10 items, "jaundice", "family member with ASD") como variables de app recrearía un screen no clínico, con problemas legales y de confianza. Etiqueta = "screening tool", no diagnóstico, y aun así no aporta nada a priorizar pictos ni juegos.
- **DESCARTADO categóricamente**: cualquier dataset de "caras de niños autistas" de Kaggle/Google Drive. Doble problema: imágenes de menores raspadas sin consentimiento + etiquetas inventadas. Es exactamente lo que BlueTalk debe evitar (uso no médico, sin datos personales).
- Los datasets UCI de screening **sí sirven** (CC BY 4.0, con atribución) como dataset de práctica si en el futuro se quiere un demo técnico de ML — nunca en el producto ni en marketing dirigido a familias.
- La única señal positiva: saber que el toddler dataset tiene 1050×18 y buen volumen de descargas explica por qué hay tanta literatura "basura" de ML sobre autismo — útil para no citar papers que lo usen como si fuera diagnóstico real.

### Gaps
- No se pudo leer la columna exacta ni la licencia declarada de cada dataset de Kaggle (fichas JS). Si BlueTalk quisiera usar alguno habría que verificar licencia (varía: CC0 vs "ODbL" vs unknown) descargándolo con la Kaggle API.
- "Autism Screening on Adults" (UCI 227) y la variante de adolescentes no se verificaron en detalle; mismo linaje Thabtah → mismo veredicto probable.

---

## Pregunta 2 — ¿Existen datasets de AAC / trazas de uso de apps de comunicación aumentativa?

### Takeaway
Existe muy poco dato AAC "abierto" real: el hallazgo más reciente es **PILAAD-312 en Kaggle** (logs de interacción AAC de 312 personas, 2024) y conversaciones AAC en HuggingFace, pero **no hay datos públicos agregados de uso de CoughDrop ni de apps comerciales**, y el sector mismo reconoce el problema (OpenAAC califica el estándar de datos con grado D).

### Cited Findings
- **PILAAD-312 — Kaggle "Personalized Interaction Logs for AAC Device Users" (ziya07)**: "structured interaction data collected from 312 individuals with movement, speech, and autism-related disabilities using AAC", recolección 2024. — [Kaggle](https://www.kaggle.com/datasets/ziya07/personalized-interaction-logs-for-aac-device-users). Columnas/tamaño/licencia: **no verificables** (página JS).
- **HuggingFace "willwade/AACConversations"**: conversaciones entre usuarios AAC y sus interlocutores en varios escenarios, con enunciados originales. — [HuggingFace](https://huggingface.co/datasets/willwade/AACConversations)
- **CoughDrop** registra opcionalmente cada pulsación de botón y genera reportes, pero son datos privados por usuario respaldados en la nube; **no existe dataset público agregado**. — [CoughDrop reports](https://coughdrop.zendesk.com/hc/en-us/articles/201366699-What-reports-are-available-in-CoughDrop); [mycoughdrop.com](https://www.mycoughdrop.com/)
- **OpenAAC.org** (consorcio de estándares): "AAC usage data should be available in a vendor-neutral format that can be safely collected and used for industry research. Current Grade: D" — o sea, el sector NO tiene aún ese dato disponible. — [OpenAAC](https://www.openaac.org/); [OpenAAC símbolos](https://www.openaac.org/symbols.html)
- **AssistiveWare** (Proloquo): política de no registrar *qué* dice el usuario, solo métricas de uso — el estándar ético del sector. — [assistiveware.com](https://www.assistiveware.com/blog/aac-data-collection-and-privacy)
- **LDBase — "AAC Narrative Intervention for Children with Autism"**: datos reales de puntuaciones de gramática de historia y número de símbolos distintos usados en una intervención AAC; acceso vía registro en LDBase (institucional, con términos de uso de investigación). — [LDBase project](http://ldbase.org/projects/ca7b071c-a3bb-4a4b-8278-7897bfaad8bb)
- Papers de referencia sobre data logging en AAC (para el diseño del modo padre): Hu et al. 2021 (speaker-aware info retrieval from AAC logs) y Cross (límites del data logging automático). — [JAIT](https://ojs.istp-press.com/jait/article/view/20/33); [Realize Language PDF](https://realizelanguage.com/info/assets/pdf/The_Value_and_Limits_of_Automated_Data_Logging_and_Analysis_in_AAC_Devices.pdf)

### Inferences (acción para BlueTalk)
- **PILAAD-312 → evaluar con ojo crítico antes de usar**: descubrir licencia y procedencia (¿logs sintéticos? ¿consentimiento?). Si es legítimo, serviría para **diseñar el esquema de telemetría anonimizada del modo padre** (qué campos registrar: id de picto, timestamp, sesión) y para prototipar detección de patrones de uso (vocabulario más tocado, horas, ritmo). NO cargar los datos de personas reales en la app.
- **AACConversations (HF) → candidato a servir** para el juego de cuentos/frases: ejemplos de turnos de comunicación adaptativa para generar frases modelo o entrenar el "predictor" del barra de frase (si algún día se añade). Verificar licencia del dataset antes.
- **Acción estratégica**: dado que no existe dataset abierto de uso AAC, BlueTalk puede **crear el suyo agregado y anónimo** (opt-in, sin datos personales, solo estadísticas locales sincronizables) siguiendo la política de AssistiveWare (no registrar contenido del mensaje, solo métricas). Eso además alimenta los "benchmarks agregados" del modo padre que pide el encargo.
- LDBase: solicitar acceso solo si se necesita investigar métricas de intervención; overhead institucional alto, prioridad baja.

### Gaps
- Columnas, tamaño exacto y licencia de PILAAD-312 no verificados (Kaggle JS). Verificar antes de citar internamente.
- No encontré dataset "CCSB" ni datos abiertos de Tobii Dynavox/Lingo/GoTalk (son propietarios). Confirmado por ausencia en búsquedas: no existe hoy un "ImageNet del AAC".

---

## Pregunta 3 — Frecuencia de símbolos/vocabulario (core words) para priorizar los pictos de BlueTalk

### Takeaway
**No existe un CSV canónico de frecuencia de pictogramas**, pero sí existen listas de vocabulario núcleo (core vocabulary) usadas clínicamente en inglés y recursos de vocabulario núcleo en español (ARASAAC tiene tableros core en castellano), más **bibliotecas de símbolos con licencia abierta** (OpenSymbols/Mulberry) que sí son utilizables directamente para ampliar los 42 pictos actuales. La vía práctica: cruzar top-100 core words (EN) con equivalentes ES de ARASAAC + tableros core de ARASAAC.

### Cited Findings
- **OpenSymbols** (opensymbols.org): colección de símbolos de comunicación con licencias abiertas, ~59.000–60.000 símbolos, incluye API, con licencias variables por repositorio origen. — [opensymbols.org](https://www.opensymbols.org/); [OpenAAC](https://www.openaac.org/symbols.html)
- **Mulberry Symbols**: 3.116 pictogramas SVG, licencia **CC BY-SA** (igual que compartir si modificas), repositorio GitHub público. — [mulberrysymbols.org](https://mulberrysymbols.org/); [github.com/mulberrysymbols/mulberry-symbols](https://github.com/mulberrysymbols/mulberry-symbols); [ficha OpenSymbols](https://www.opensymbols.org/repositories/mulberry)
- **Global Symbols**: set "Mulberry Plus" (42 símbolos extra para cuidados) sobre Mulberry; plataforma con más sets y licencias. — [globalsymbols.com](https://globalsymbols.com/symbolsets/?locale=en)
- **AAC Language Lab — "100 High Frequency Core Word List"** (lista de 100 palabras núcleo de alta frecuencia, gratuita) y un "Core Word Starter" basado en las **top 20 palabras**. — [aaclanguagelab.com](https://aaclanguagelab.com/resources/100-high-frequency-core-word-list); [core word starter](https://aaclanguagelab.com/resources/core-word-starter-data-collection--trial-plan)
- Afirmación de la industria: el vocabulario básico/core compone el **75–80% de la comunicación cotidiana**. — [AbleNet](https://support.ablenetinc.com/aac-education-and-resources/why-core-vocabulary-is-on-the-aac-home-page/)
- **Instituto ABAac — "AAC Performance Report"**: incluye medida de vocabulario núcleo general (GCV) como porcentaje de frecuencia de palabras core sobre el total de mensajes — el modelo de métrica que replica el modo padre de BlueTalk. — [aacinstitute.org](https://aacinstitute.org/core-vocabulary-and-the-aac-performance-report/)
- **Cooper et al. 2024** ("Is frequency enough?"): auditaron listas de core vocabulary; crearon lista de 156 "relational basic concepts"; conclusión implícita: las listas de frecuencia por sí solas no cubren todo lo que los usuarios necesitan comunicar. — [Tandfonline](https://www.tandfonline.com/doi/full/10.1080/07434618.2024.2332648); [PDF Berkeley](https://edrl.berkeley.edu/wp-content/uploads/2024/04/Published_The-prevalence-of-relational-basic-concepts-on-core-vocabulary-lists-for-AAC-is-frequency-enough-.pdf)
- **ESPAÑOL — ARASAAC**: publica "Tableros con Vocabulario Nuclear (Core Vocabulary)" **disponibles en castellano y francés**, descarga gratuita (ARASAAC = Centro Aragonés de Símbolos, licencia de uso libre con atribución; no verifiqué la página de licencia en esta pasada). — [ARASAAC (post oficial)](https://www.facebook.com/arasaac/posts/2525508800874375/)
- Otros recursos ES de vocabulario núcleo (no datasets, guías clínicas): Qinera, CIVAT, alfasaac, Assistiveware en español. — [blog.qinera.com](https://blog.qinera.com/que-es-el-vocabulario-nucleo/); [civat.es](https://civat.es/materialcaa/tablero-de-vocabulario-nucleo/); [alfasaac.com PDF](https://alfasaac.com/wp-content/uploads/2021/01/nivel-2-comunicacion-aumentativa-y-alternativa-y-lenguaje-natural-asistido-l5-y-l6-eleccion-del-saac-i-y-ii.pdf)

### Inferences (acción para BlueTalk)
- **Acción inmediata y de bajo riesgo**: tomar la **100 High Frequency Core Word List** (EN) + los **tableros Core Vocabulary de ARASAAC en castellano** → extraer ~30–50 palabras núcleo que falten entre los 42 pictos actuales (querer/más/no/ir/ayuda/abrir/parar/yo/tú… traducidos al ES de ARASAAC) y añadirlos en esa prioridad. Sin CSV de frecuencia pura, esta combinación es lo más cercano a evidencia.
- Para **priorizar dentro de la app**, implementar la métrica estilo ABAac: % de uso de palabras núcleo sobre mensajes totales (informe del modo padre) — sin salir del dispositivo.
- **Símbolos**: OpenSymbols (API) y **Mulberry (CC BY-SA) y ARASAAC** son las fuentes con licencia utilizable. OJO con CC BY-SA: si BlueTalk distribuye los SVGs de Mulberry modificados, debe ofrecerlos con la misma licencia (compatible si BlueTalk es gratuita, pero revisar con el modelo comercial). ARASAAC exige atribución.
- Cooper 2024 avisa: no priorizar SOLO por frecuencia — mezclar frecuencia + utilidad comunicativa (p.ej. incluir "relational" y emocionales, que BlueTalk ya tiene en el check-in).

### Gaps
- No existe (y no se encontró) un dataset machine-readable de frecuencia de *pictogramas* usados en CAA (EN o ES). La evidencia de frecuencia vive en papers y listas clínicas, no en datos abiertos.
- "Minspeak symbol frequency data": no se encontró dataset; las bases de símbolos de Minspeak/Unity son propietarias (Vantage/Prentke Romich) → descartado por licencia.

---

## Pregunta 4 — Datasets de emociones/expressiones faciales en niños (check-in emocional)

### Takeaway
**FER2013 y similares NO son adecuados ética ni técnicamente para BlueTalk**: reconocimiento facial de emociones con sesgo documentado y problemas éticos (privacidad, sesgo racial), imágenes de personas reales sin contexto de consentimiento infantil, y un modelo FER en gama baja offline es inviable y además choca con el diseño "sin datos personales". La alternativa correcta: **emojis/pictos de emociones (estilo ARASAAC)** — sin fotos biometricables.

### Cited Findings
- **FER2013**: 35.887 imágenes 48×48 en escala de grises, 7 emociones; estándar de facto en Kaggle. — [Emergent Mind](https://www.emergentmind.com/topics/fer2013-dataset); [Wolfram repository](https://datarepository.wolframcloud.com/resources/FER-2013)
- **Ética del reconocimiento facial de emociones**: revisión 2024 documenta sesgo racial, problemas de privacidad y de despliegue de los sistemas FER. — [MDPI "Not in My Face" 2024](https://www.mdpi.com/2504-4990/6/4/109)
- **Ethics Sheet for Automatic Emotion Recognition** (arXiv, hoja de ética formal del campo). — [arXiv:2109.08256](https://arxiv.org/html/2109.08256v3)
- Contexto 2026 del campo: aparecen datasets FER "novel" con 10 categorías y ~35K imágenes — el campo sigue creciendo en volumen (no en ética). — [PMC 2024](https://pmc.ncbi.nlm.nih.gov/articles/PMC11620061/)
- (Contexto de retracciones de la Pregunta 1): usar fotos de niños etiquetadas "autista/no autista" de Kaggle acabó en 38 retractaciones en 2026. — [MedPage Today](https://www.medpagetoday.com/special-reports/features/120378)

### Inferences (acción para BlueTalk)
- **Descartado**: FER2013, AffectNet, CK+, y cualquier FER infantil. Motivos acumulativos: (1) ética — biometría de menores, sesgos; (2) técnica — modelo de visión en gama baja offline no viable; (3) de producto — BlueTalk es sin datos personales y sin diagnóstico; clasificar emociones de la cara del niño roza el inferencial clínico; (4) terapéuticamente, en TEA las expresiones faciales pueden no correlacionar con la emoción interna (lo que hace el FER aún menos fiable para esta población — inferencia, no citada).
- **Alternativa recomendada (acción concreta)**: check-in emocional con **pictos/emojis** (ya alineado con ARASAAC): 4–6 emociones básicas (feliz, triste, enfadado, asustado, calmado, sorprendido) + escala visual simple. Si se quieren "emojis de niños", usar sets abiertos de emojis (Noto Emoji, Apache/Apache-licensed Twemoji — licencias verificables) en vez de fotos.
- El "check-in" puede además alimentar (opt-in, local) los reportes del modo padre con series temporales de ánimo — sin ningún dato personal saliendo del dispositivo.

### Gaps
- CK+ y AffectNet no se verificaron en detalle en esta pasada (licencias: CK+ requiere acuerdo de uso; AffectNet tiene términos de investigación). No cambia el veredicto de descarte para este caso de uso.

---

## Pregunta 5 — Datasets educativos/TEA de habla hispana (lenguaje infantil ES, errores fonológicos, PECS)

### Takeaway
Existe corpus de lenguaje infantil en español (CHILDES/TalkBank) útil para calibrar el registro de lenguaje de la app y los cuentos, pero **no encontré datasets abiertos de PECS ni de habla infantil TEA en español**; lo más cercano a dato TEA en español son cuestionarios de screening (que ya descartamos) y un corpus Q-CHAT polaco.

### Cited Findings
- **CHILDES/TalkBank**: repositorio de transcripciones de lenguaje infantil en 24 idiomas; los materiales requieren **login de TalkBank** (uso bajo sus términos; no es CC0). Corpus en español incluidos (ej. Romero: español L1 en contextos naturalistas; Hoff: interacción padre-hijo español-inglés). — [talkbank.org/childes](https://talkbank.org/childes/); [corpus Romero](https://talkbank.org/childes/access/Spanish/Romero.html); [Sketch Engine (24 idiomas)](https://www.sketchengine.eu/childes-corpora/)
- **PyChildes**: preprocesador Python de CHILDES (GitHub). — [github.com/Mars-tin/PyChildes](https://github.com/Mars-tin/PyChildes)
- Dataset Mendeley de **Q-CHAT de 252 toddlers polacos** (135 con sospecha TEA comunitaria) — único dataset "TEA +婴幼儿" pequeño y descargable encontrado; pero es screening, no lenguaje. — [Mendeley](https://data.mendeley.com/datasets/tmpkt2mfkg/1)
- TalkBank también alberga datos de trastornos del lenguaje/bilingüismo (relevante como fuente de registro lingüístico "real"). — [repository UAntwerpen (historia CHILDES)](https://repository.uantwerpen.be/docstore/d:irua:25363)

### Inferences (acción para BlueTalk)
- **CHILDES ES → sirve con moderación**: usar muestras de lenguaje de padres/niños en español para ajustar el **nivel de lectura del TTS y de las etiquetas de pictos** (palabras que un niño de 3–5 años realmente produce) y para generar frases modelo en el barra de frase y en el juego de cuentos. Requiere login y citación; verificar términos de TalkBank antes de empaquetar nada.
- **Descartado**: PECS data (no existe dataset abierto; los datos de ensayos PECS están en papers con datos no compartidos), datasets de errores fonológicos ES (no encontrados).
- Tortas dataset: **no se pudo verificar** que exista tal dataset (búsqueda ES no arrojó nada) — tratar como inexistente hasta nuevo aviso.

### Gaps
- No hay (no se encontró) corpus abierto de habla infantil TEA en español ni de lenguaje aumentado en español. Si BlueTalk algún día quiere "ensuciar" el lenguaje del cuento con disfluencias reales, CHILDES es la única base seria, y es EN/ES mixto.

---

## Pregunta 6 — Datasets para juegos cognitivos (memory game, adaptive learning, desempeño de niños TEA)

### Takeaway
**No existe un dataset público de desempeño en juegos cognitivos de niños TEA** con el cual calibrar dificultad adaptativa; la única fuente real encontrada es el dataset de intervención AAC narrativa en LDBase. La dificultad adaptativa debe derivarse del propio uso de BlueTalk (telemetría local agregada) y de parámetros clínicos publicados, no de un dataset externo.

### Cited Findings
- **LDBase "AAC Narrative Intervention for Children with Autism"**: puntuaciones de story grammar + nº de símbolos distintos usados (más cercano a "desempeño en juego de cuentos" que nada demás). — [LDBase](http://ldbase.org/projects/ca7b071c-a3bb-4a4b-8278-7897bfaad8bb)
- Contexto de calidad metodológica: la literatura de autismo tiene tamaños muestrales pequeñísimos y replicabilidad frágil ("particularly small participant numbers… within-group variance in autism is high") — razón por la que calibrar juegos con papers TEA es poco fiable. — [Gowen et al. 2019](https://pmc.ncbi.nlm.nih.gov/articles/PMC7099931/)

### Inferences (acción para BlueTalk)
- **Descartado**: buscar dataset externo de "game performance TEA". No existe usable.
- **Acción**: instrumentar los juegos de BlueTalk (memoria: aciertos, latencia, nivel completado; cuenta: símbolos usados) en stats **locales y anónimas**, opt-in para agregados. Con unos cientos de sesiones propias se obtiene una curva de dificultad adaptativa más válida que cualquier dataset ajeno — y es coherente con "offline-first, sin datos personales" (agregación solo con consentimiento explícito del padre).
- Diseño adaptativo inicial basado en literatura (no dataset): empezar en nivel bajo, subir tras 3 aciertos consecutivos — heurística estándar, sin afirmar que venga de un dataset.

### Gaps
- No se hizo búsqueda exhaustiva en OSF/Harvard Dataverse por presupuesto de llamadas. Es posible que existan datos de tareas ejecutivas/desempeño escolar TEA en OSF, pero serían datasets de investigación con consentimiento restringido, poco prácticos para una app.

---

## Pregunta 7 — Buenas prácticas éticas y compatibilidad de licencias con app comercial gratuita

### Takeaway
La guía ética de referencia para trabajar con la comunidad autista (Gowen et al. 2019) pide participación, transparencia y reciprocidad — aplicable a BlueTalk como diseño de producto; el escándalo de retractaciones de 2026 es el contraejemplo canónico. En licencias: **CC BY 4.0 (UCI), CC BY-SA (Mulberry), ARASAAC (uso libre con atribución) son compatibles con app gratuita**, verificando atribución y share-alike; los datos de screening siguen siendo incompatibles con el diseño "no diagnóstico" de BlueTalk.

### Cited Findings
- **Gowen et al. 2019** (guía basada en 22 adultos autistas + 8 padres, 4 bloques: pre-estudio, reclutamiento, visita, post-estudio): principios clave — nada de "research for research's sake" (reciprocidad); transparencia total ("fear about secret research"); involucrar a la comunidad autista como **socio** desde el inicio ("nothing about us, without us"); consentimiento informado accesible; devolver resultados a participantes. — [Gowen et al., PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC7099931/)
- **Autistic Self Advocacy Network (ASAN) — "Evidence, ethics, and effectiveness of autism intervencions"**: la comunidad autista critica prácticas que buscan "normalizar" a niños autistas; el marco ético debe ser de apoyo, no de "curar". — [autisticadvocacy.org PDF](https://autisticadvocacy.org/wp-content/uploads/2021/12/ACES-Ethics-of-Intervention.pdf)
- **Cascio, Weiss & Racine**: "person-oriented research ethics" para participantes autistas — respeto a la persona como guía. — [PDF](https://www.pragmatichealthethics.ca/wp-content/uploads/2020/09/2020_CascioWeissRacine.Person-oriented-research-ethics-to-address-the-needs-of-participants-on-the-autism-spectrum.pdf)
- **Consentimiento en autismo**: directrices de diseño de materiales de consentimiento para autistas (Autism & Adulthood). — [EurekAlert](https://www.eurekalert.org/news-releases/1075279); [Autistica toolkit](https://www.autistica.org.uk/our-research/research-toolkit/info-sheet)
- **Licencias verificadas**: UCI = CC BY 4.0 (atribución); Mulberry = CC BY-SA (atribución + compartir derivados igual); OpenSymbols = mezcla por repositorio origen (verificar por símbolo); OpenSymbols ~60K símbolos con API. — [UCI](https://archive.ics.uci.edu/dataset/419/autistic+spectrum+disorder+screening+data+for+children); [Mulberry](https://www.opensymbols.org/repositories/mulberry); [OpenAAC](https://www.openaac.org/symbols.html)
- **Escándalo 2026 como lección**: fotos de niños raspadas sin consentimiento → 38 retractaciones Springer + 25 expressions of concern IEEE + artículos **eliminados** por Springer por la sensibilidad del dato infantil. — [MedPage Today](https://www.medpagetoday.com/special-reports/features/120378)

### Inferences (acción para BlueTalk)
- **Regla de incorporación de datos en BlueTalk**: (1) nada de datos de identificación o biometría de menores; (2) nada que sugiera diagnóstico o screening (los datasets de screening quedan fuera del producto aunque su licencia lo permita); (3) si se usa telemetría, opt-in del padre, anónima, agregada, local-first — replicando la política de AssistiveWare; (4) copy del producto: enfoque de apoyo/comunicación, nunca "detección" ni "curación" (posicionamiento ASAN-compatible).
- **Licencias listas para usar hoy**: pictos de ARASAAC (atribución) y Mulberry (CC BY-SA → si empaquetas SVGs modificados, publicarlos con la misma licencia; compatible con app gratuita pero incompatible si algún día se cierra el código de los assets). UCI CC BY 4.0 solo relevante si se usan sus CSV en demos.
- Recomendaría añadir al disclaimer existente la frase "esta app no realiza screening ni evaluaciones" — coherente con el discurso de la comunidad (Gowen: transparencia) y blindaje ante la tendencia regulatoria que vio el escándalo de Kaggle.

### Gaps
- No se verificó la página oficial de licencia de ARASAAC (se cita su uso libre por reputación y el post oficial de descarga de tableros core); confirmar antes de empaquetar SVGs.
- Requisitos de licencia específicos de TalkBank no leídos en detalle (solo que requiere login).

---

## Resumen ejecutivo: tabla veredictos para BlueTalk

| Dataset | Veredicto | Uso concreto |
|---|---|---|
| Kaggle/UCI autism screening (toddlers, children, adults, adolescentes) | **Descartado producto**; usable solo como dataset de práctica (CC BY 4.0) | Ninguno en la app — viola "no diagnóstico" |
| Kaggle fotos faciales autistas (+ réplicas) | **Descartado categóricamente** | Nada. Escándalo 2026, 38 retractaciones |
| PILAAD-312 (Kaggle, logs AAC 312 usuarios) | **Evaluar** (verificar licencia/procedencia) | Modelo de esquema de telemetría del modo padre |
| willwade/AACConversations (HF) | **Candidato** | Frases modelo para cuentos/barra de frase (verificar licencia) |
| OpenSymbols + Mulberry (3.116 CC BY-SA) | **Usar** | Ampliar biblioteca de pictos (atribución + share-alike) |
| 100 Core Word List (AAC Language Lab) + tableros core ARASAAC ES | **Usar ya** | Priorizar ~30–50 pictos núcleo que faltan de los 42 |
| FER2013 / AffectNet / CK+ | **Descartado** | Usar pictos/emojis (ARASAAC/Noto/Twemoji) en check-in |
| CHILDES/TalkBank español | **Usar con moderación** (login, citación) | Ajustar registro lingüístico de TTS/cuentos |
| Desempeño juegos TEA | **No existe dataset** | Instrumentar telemetría local propia, opt-in |
| Guías éticas (Gowen 2019, ASAN, Cascio) | **Aplicar** | Diseño transparencia, enfoque apoyo, sin "curar" |
