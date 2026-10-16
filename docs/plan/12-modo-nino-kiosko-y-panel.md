# Plan 12 — Modo niño (teléfono restringido), registro de uso y panel del adulto

**Para:** el agente que ejecuta (OpenCode). **Léelo entero antes de tocar código.**
**Requisito previo:** `AGENTS.md`, `docs/informes/auditoria-general.md` y el §0 de `docs/plan/11-fases-1-a-3-excelencia.md` (estándar de ingeniería y reglas de honestidad). Todo lo que dice el §0 de ese plan aplica aquí sin excepción.
**Producto:** BlueTalk es **esta app móvil** (Flutter, Android). Es gratuita, offline y debe ir fluida en teléfonos viejos (Android 7+, 1–2 GB de RAM).

## Idea del producto (palabras del dueño)

1. El niño abre el teléfono y entra **directamente** a BlueTalk. Le pide su nombre y accede a juegos, comunicador y rutinas.
2. El teléfono queda **restringido para niños**: solo se ven las apps que el adulto permite (por ejemplo TikTok, si decide permitirlo) y se bloquea lo demás.
3. La app **registra el uso**: tiempo por app (TikTok u otra), ejercicios y juegos hechos, pictogramas usados.
4. Cuando el adulto vuelve, pulsa un botón, **mete su credencial** y ve un **panel** con todo el detalle y **recomendaciones** basadas en los datos del niño.
5. En la **primera instalación**, el adulto lee y acepta unos términos que explican, con detalle y en lenguaje claro, a qué se compromete y qué permisos concede.

## 1. Decisiones ya tomadas (el dueño puede vetarlas; si lo hace, actualiza este archivo)

| # | Decisión | Por qué |
|---|---|---|
| D1 | **Datos solo en el teléfono** (local-first). Sin Supabase en el piloto. | El flujo pedido (el adulto mira el panel en el mismo teléfono) no necesita nube. La nube obliga a consentimiento verificable de menores y a una revisión más dura de Play. Supabase queda como Fase 9 **opcional y opt-in**. |
| D2 | **Restricción en capas:** (a) BlueTalk como **launcher** (pantalla de inicio), (b) **fijar pantalla** (`startLockTask`) cuando el adulto lo active, (c) **Acceso de uso** (`UsageStatsManager`) para medir tiempo. **Sin** `AccessibilityService` ni Device Owner en el piloto. | (a)–(c) no exigen root, ni borrar el teléfono, ni permisos que Play trata como sensibles. `AccessibilityService` y Device Owner se evalúan en la Fase 9 si el piloto muestra que hace falta. |
| D3 | **Recomendaciones sin LLM en la nube:** motor local de reglas + base de conocimiento curada con recuperación por palabras clave (RAG-lite, 100 % offline y gratis). | Cero coste, cero datos de menores saliendo del teléfono, funciona en gama baja. |
| D4 | **Credencial del adulto:** PIN de **6 dígitos** + **código de recuperación** de 12 caracteres que se muestra una sola vez. Huella opcional. | Es lo que hacen Family Link, Kids Place y similares. El código de recuperación evita perder el acceso. |
| D5 | **Sin logos** de universidades, partidos políticos ni marcas de terceros en ninguna pantalla, ícono, texto legal ni capturas. Sí se citan fuentes académicas **por texto** (autores, año, DOI). | Pedido del dueño. |

## 2. Límites técnicos que debes respetar y declarar en la UI (honestidad)

- Un launcher **no puede** impedir al 100 % que el niño salga: notificaciones, el Asistente de Google o la tecla de apps recientes pueden abrir otras apps. **Fijar pantalla** lo reduce mucho pero el niño puede salir con el gesto del sistema si lo conoce. La pantalla de términos y la de ajustes del modo niño lo dicen con esas palabras. No prometas "bloqueo total".
- Medir tiempo en otras apps solo se puede si el adulto concede **Acceso de uso** en los ajustes de Android (pantalla del sistema, no un diálogo). Sin ese permiso, la app mide solo el tiempo **dentro de BlueTalk** y lo dice en el panel.
- Los fabricantes (Xiaomi, Huawei, Samsung) matan servicios en segundo plano. **No dependas de un servicio en segundo plano**: consulta `UsageStatsManager` al abrir el panel y cada vez que BlueTalk vuelve a primer plano.
- Todo esto **no se puede verificar sin un teléfono físico**. Declara cada punto como NO VERIFICADO hasta que el dueño lo pruebe con el checklist de la Fase 8.

## 3. Reglas para este plan

- Sigue el §0 del plan 11 (definición de hecho, honestidad, evidencia por fase, revisor).
- **Un paso = un commit** (`TIPO: descripción en español`, ≤70 caracteres, sin texto de IA ni `Co-Authored-By`). Antes de cada commit: `flutter analyze` con 0 problemas y `flutter test` en verde.
- Ejecuta las fases **en orden**. No empieces una sin cerrar la anterior.
- Dependencias nuevas permitidas: **ninguna** salvo las que este plan nombra. El código nativo es Kotlin dentro de `android/app/src/main/kotlin/`.
- Cada permiso nuevo de Android se justifica en `docs/play/permisos.md` (crea el archivo en la Fase 2).
- Todo texto visible para el niño: literal, corto, sin metáforas, sin sonido automático, objetivos ≥48 dp, modo calma respetado.
- Si algo del código contradice este plan: detente, anótalo en `docs/informes/fase-N-notas.md` y propón el cambio mínimo.

---

# FASE 0 — Estabilizar lo que ya existe (obligatoria, antes de todo)

Hoy `flutter test` **no termina**: `test/padre/gate_test.dart` y `test/padre/padre_screen_test.dart` se cuelgan; `control_test.dart` y `salud_test.dart` fallan; y `test/padre/diagnostico_test.dart` (archivo de depuración sin commitear) rompe `flutter analyze`.

**0.1** Borra `test/padre/diagnostico_test.dart` (es un resto de depuración con `print`).
**0.2** Diagnostica el cuelgue de `gate_test.dart`. Hipótesis a comprobar, en este orden: (a) `PinStore` calcula PBKDF2 con `cryptography` (asíncrono real) dentro de `testWidgets`, que usa reloj falso (`FakeAsync`) y nunca avanza; (b) un `Timer` del bloqueo de 60 s. Arregla **la causa**: en los tests usa `tester.runAsync(() => ...)` para el cálculo del hash, o inyecta un `PinStore` de prueba con pocas iteraciones. **Prohibido** borrar o saltar el test.
**0.3** Arregla `control_test.dart` y `salud_test.dart` (lee el mensaje de fallo; si el defecto está en la app, arréglalo en la app).
**0.4** Añade a `analysis_options.yaml` las reglas `avoid_print` y `prefer_const_constructors` y deja el análisis en 0.
**0.5** Elimina de `pubspec.yaml` las dependencias que nada importa: `supabase_flutter`, `connectivity_plus`, `http`, `drift`, `drift_flutter`, `sqlite3_flutter_libs`, `drift_dev`, `build_runner` (comprueba con `grep -r "package:<nombre>" lib test` antes de quitar cada una; si algo la usa, déjala). `flutter_secure_storage`: déjala solo si el paso 1.4 la usa.
**0.6** `AndroidManifest.xml`: `android:label="BlueTalk"` y `android:allowBackup="false"`.
**0.7** Crea `scripts/build-apk.sh` que ejecute `flutter analyze && flutter test && flutter build apk --release --split-per-abi` y muestre el tamaño de cada APK.

**Aceptación:** `flutter analyze` → 0; `flutter test` termina y pasa (pega el conteo real); `scripts/build-apk.sh` produce los APK.

---

# FASE 1 — Primera instalación: adulto primero, niño después

**Flujo nuevo** (reemplaza el onboarding actual; reutiliza `lib/features/onboarding/` y `lib/features/padre/`):

```
Primer arranque
 └─ A. Pantalla "Configuración para el adulto"
      1. Aviso: "Esta parte es para un adulto responsable."
      2. Términos de uso y compromisos del adulto (§1.2), con casilla de aceptación por bloque
      3. Crear PIN de 6 dígitos (pedir dos veces)
      4. Mostrar código de recuperación UNA vez ("Anótalo en papel")
      5. Explicación de permisos y botón para concederlos (§2.1), cada uno opcional
      6. Elegir apps permitidas para el niño (§3.2)
      7. Botón "Entregar el teléfono al niño"
 └─ B. Modo niño: "¿Cómo te llamas?" → Inicio del niño
Arranques siguientes → directamente B (si hay niño creado) sin pasar por A
```

**1.1** `lib/features/onboarding/` — crea `adulto_setup_screen.dart` y `adulto_setup_controller.dart` (Riverpod) con los 7 pasos. Guarda `adulto_setup_completo` en preferencias. El router redirige a A mientras no esté completo y a B si falta el nombre del niño. Prueba el redirect en `test/core/router_test.dart`.

**1.2** `docs/legal/` y `lib/features/padre/legal/textos_legales.dart` — reescribe los **Términos del adulto** con estos bloques (cada uno con su casilla, en lenguaje claro, frases cortas):
1. **Quién soy:** declaro ser madre, padre o tutor legal del niño o niña que usará el teléfono.
2. **Qué hace BlueTalk:** convierte este teléfono en un teléfono para niños; muestra solo las apps que yo permita.
3. **Qué NO garantiza:** no es un bloqueo infalible (notificaciones, Asistente de Google, gestos del sistema); no es un dispositivo médico ni da diagnóstico; las recomendaciones son orientativas.
4. **Permisos que concedo y para qué** (lista literal del §2.1; cada permiso explicado con "qué se ve", "qué no se ve").
5. **Qué datos se guardan:** tiempo por app, juegos y ejercicios hechos, pictogramas usados. **Todo se queda en este teléfono.** No hay cuenta, no hay anuncios, no hay envío a internet.
6. **Mi responsabilidad:** guardar mi PIN y el código de recuperación; supervisar a mi hijo; poder desactivar el modo niño cuando quiera.
7. **Cómo desinstalar o salir:** pasos exactos (PIN → Modo padre → "Salir del modo niño"; o Ajustes de Android → Apps → BlueTalk).
8. **Licencias:** pictogramas Mulberry (CC BY-SA 4.0), con atribución. Sin logos de terceros.
Incluye la línea: «Estos textos no son asesoría legal». **No decidas** el modelo de negocio ni publiques la política: si falta algo, escríbelo en `docs/informes/decisiones-pendientes.md`. Corrige además la frase "licencia no comercial" para que coincida con "gratuita" (pregunta al dueño si habrá versión de pago en el futuro).

**1.3** Subir el PIN de 4 a **6 dígitos** y las iteraciones PBKDF2 de 10 000 a **120 000**. Mueve el cálculo a `Isolate.run` para no congelar teléfonos lentos (mide en el emulador; si tarda >1,5 s, baja a 60 000 y anótalo). Migración: si existe un PIN antiguo de 4 dígitos, pide crear uno nuevo.

**1.4** **Código de recuperación:** 12 caracteres (alfabeto sin `0 O 1 I l`), generado con `Random.secure()`. Se guarda **solo su hash** (mismo esquema que el PIN). Pantalla "Olvidé mi PIN" en el gate: pide el código, y si coincide permite crear un PIN nuevo. 5 fallos → bloqueo creciente (reutiliza el bloqueo existente). Tests: código válido, inválido, bloqueo, el código no se guarda en claro.

**1.5** Tests de las pantallas A y B (patrón `accessibility_tools` de `test/rutinas/accesibilidad_test.dart`).

**Aceptación:** una instalación limpia en emulador pasa A → B sin saltarse pasos; segundo arranque va directo a B; el PIN antiguo de 4 dígitos ya no se acepta; tests verdes.

---

# FASE 2 — Canal nativo Android (Kotlin)

Crea un único `MethodChannel` llamado `bluetalk/kiosco` con estas llamadas. Código en `android/app/src/main/kotlin/com/limitcodev/bluetalk/KioscoPlugin.kt`, registrado desde `MainActivity.kt`.

| Método Dart | Qué hace en Android |
|---|---|
| `appsLanzables()` | `PackageManager.queryIntentActivities` con `Intent.ACTION_MAIN` + `CATEGORY_LAUNCHER`. Devuelve `[{package, label, iconPng(base64, 96 px)}]`. Excluye BlueTalk. Calcula los iconos en un hilo aparte y con caché. |
| `abrirApp(package)` | `startActivity` con el intent de lanzamiento. Solo si el paquete está en la lista permitida (valida en Kotlin, no solo en Dart). |
| `tieneAccesoDeUso()` | `AppOpsManager.checkOpNoThrow(OPSTR_GET_USAGE_STATS, ...)`. |
| `abrirAjustesAccesoDeUso()` | `Settings.ACTION_USAGE_ACCESS_SETTINGS`. |
| `usoPorApp(desdeMs, hastaMs)` | `UsageStatsManager.queryEvents` (suma los pares `ACTIVITY_RESUMED`/`ACTIVITY_PAUSED` por paquete). Devuelve `{package: milisegundos}`. Si no hay permiso, devuelve vacío y un indicador. |
| `esLauncherPredeterminado()` | `PackageManager.resolveActivity(HOME)` compara con el paquete propio. |
| `abrirAjustesLauncher()` | `Settings.ACTION_HOME_SETTINGS`. |
| `fijarPantalla(bool)` | `activity.startLockTask()` / `stopLockTask()`. |

**2.1 Permisos y manifest** (`AndroidManifest.xml`): añade `<uses-permission android:name="android.permission.PACKAGE_USAGE_STATS" tools:ignore="ProtectedPermissions"/>`. Añade a la `MainActivity` un `<intent-filter>` con `android.intent.action.MAIN` + `android.intent.category.HOME` + `android.intent.category.DEFAULT` (esto permite elegir BlueTalk como pantalla de inicio). Añade `<queries>` con el intent `MAIN/LAUNCHER` para listar apps **sin** `QUERY_ALL_PACKAGES` (Play restringe ese permiso). Escribe `docs/play/permisos.md` con cada permiso, para qué, qué ve y qué no ve BlueTalk.

**2.2** Capa Dart: `lib/data/native/kiosco_channel.dart` con una interfaz `KioscoApi` y una implementación real; en tests usa un `FakeKioscoApi`. Registra el proveedor en `lib/app/di.dart`.

**2.3** Tests: Dart con el fake (lista de apps, permiso sí/no). Kotlin: lo que no se pueda probar sin dispositivo va a **NO VERIFICADO — requiere teléfono físico**.

**Aceptación:** `flutter build apk --debug` compila con el código Kotlin; en el emulador, `appsLanzables()` devuelve apps y `abrirApp` abre una.

---

# FASE 3 — Inicio del niño y salida protegida

**3.1** `lib/features/nino_home/` (nueva): pantalla de inicio del niño con **posiciones fijas**: 1) Comunicar, 2) Juegos, 3) Rutinas, 4) rejilla de **apps permitidas** (iconos grandes con nombre, ≥48 dp). Nunca reordenar. Sin sonido automático.

**3.2** Selector de apps permitidas (en Modo padre → Control): lista de `appsLanzables()` con interruptor por app, **todas apagadas por defecto**. Guarda `appsPermitidas` (conjunto de paquetes) en preferencias. Límite de tiempo diario **por app** (opcional, minutos).

**3.3** Al abrir una app permitida, BlueTalk registra el inicio. Al volver a BlueTalk (`AppLifecycleState.resumed`), consulta `usoPorApp` y actualiza los contadores (Fase 4). Si la app superó su límite diario, la tarjeta se muestra apagada con el texto literal «Hoy ya usaste esta app» y no se abre.

**3.4** **Salida protegida:** un botón discreto (esquina, ≥48 dp, texto «Adulto») abre el gate de PIN existente. Dentro de Modo padre: «Salir del modo niño» (llama `fijarPantalla(false)` y abre `abrirAjustesLauncher()`), «Fijar pantalla» (`fijarPantalla(true)`) y «Elegir BlueTalk como inicio» (`abrirAjustesLauncher()`).

**3.5** Gestión del botón atrás: en el inicio del niño, atrás **no** cierra la app (`PopScope(canPop: false)`); solo sale con el gate.

**3.6** Tests de widget: orden fijo de las tarjetas, apps apagadas por defecto, límite agotado bloquea, atrás no sale, el botón «Adulto» abre el gate.

**Aceptación:** con el fake, el flujo completo funciona; accesibilidad sin errores. Declara NO VERIFICADO el comportamiento como launcher real hasta la prueba en teléfono.

---

# FASE 4 — Registro de uso (agregado, ligero)

**Problema que resuelve:** hoy los eventos son una lista con tope; en gama baja y a largo plazo no sirve. Usa **contadores agregados por día** (claves `AAAA-MM-DD`) en `SharedPreferences`, un JSON por mes para no leer todo cada vez.

**4.1** Modelo `UsoDia`: `{fecha, msEnBlueTalk, msPorApp{paquete:ms}, juegos{id:{sesiones, aciertos, intentos, ms}}, pictogramas{id:toques}, rutinasHechas, rutinasPlaneadas}`.
**4.2** `UsoRepo` (contrato en `lib/data/contracts/repos.dart`) con `sumar...()` y `rango(desde, hasta)`. Purga automática de meses de más de 13.
**4.3** Conecta: toques de pictogramas, fin de juego, actividad de rutina hecha, tiempo en primer plano de BlueTalk (cronómetro con `WidgetsBindingObserver`), `usoPorApp` (Fase 2).
**4.4** Migra el `PrefsUsageRepo` actual sin perder datos (si hay eventos viejos, conviértelos al agregado una vez).
**4.5** Tests: suma, cambio de día, cambio de reloj hacia atrás, purga, migración, JSON corrupto (no debe impedir arrancar).

**Aceptación:** los contadores sobreviven reinicios; 10 000 toques no hacen crecer el almacenamiento más allá de unos KB; tests verdes.

---

# FASE 5 — Panel del adulto

Reutiliza `lib/features/padre/dashboard/`. **Sin dependencias de gráficos nuevas:** usa `CustomPainter` (ya existe `barras.dart`).

**5.1** Pestañas: **Hoy · Semana · Apps · Juegos · Comunicación · Recomendaciones**.
**5.2** Contenido:
- *Hoy / Semana:* tiempo total, tiempo en BlueTalk, tiempo en apps de terceros, comparación con el día/semana anterior (texto literal «+12 min respecto a ayer»).
- *Apps:* ranking por tiempo con barra, límite diario y botón para cambiarlo.
- *Juegos:* sesiones, % de aciertos, nivel alcanzado, tendencia.
- *Comunicación:* pictogramas más usados, categorías, frases creadas, vocabulario nuevo esta semana.
- Si falta el Acceso de uso: banner «No se puede medir el tiempo en otras apps» con botón para concederlo.
**5.3** Estados completos (carga, vacío «Aún no hay datos», error con reintento).
**5.4** Botón **«Exportar resumen»** (texto/PDF simple para terapeuta) con `Share` del sistema **solo si el adulto lo pulsa** (no añadas dependencia: usa un `MethodChannel` mínimo a `Intent.ACTION_SEND` o declara el paso como pendiente de decisión).
**5.5** Tests de widget por pestaña con datos de ejemplo y accesibilidad.

---

# FASE 6 — Recomendaciones (RAG-lite local, gratis)

**Objetivo:** consejos útiles y prudentes basados en los datos del niño, sin LLM ni red.

**6.1 Base de conocimiento** `assets/kb/recomendaciones.json` (lista de fichas):
```json
{
  "id": "rec-tiempo-pantalla-alto",
  "tema": "tiempo_pantalla",
  "condiciones": [{"metrica": "ms_apps_terceros_diario_promedio", "op": ">", "valor": 7200000}],
  "titulo": "Mucho tiempo en apps de entretenimiento",
  "texto": "…frase literal, sin diagnóstico…",
  "acciones": ["Proponer una pausa con una actividad de la rutina", "Bajar el límite diario en 15 minutos"],
  "fuente": "Autor, año, título corto, DOI o URL",
  "palabras_clave": ["pantalla", "tiempo", "tiktok"]
}
```
Escribe **entre 30 y 60 fichas** originales (no copies párrafos de los papers; parafrasea y cita). Temas: tiempo de pantalla, transiciones y rutinas, uso de pictogramas, vocabulario nuclear, juego y motivación, emociones, sueño, comunicación funcional (PECS por fases), señales de frustración. Usa como apoyo, **sin seguirlos al pie de la letra**, los documentos de `research_notes/` y los trabajos de BlueTalk que el dueño aportó (ver §9). Cada ficha lleva `fuente`; sin fuente no entra.

**6.2 Motor** `lib/features/padre/recomendaciones/motor.dart`:
1. Calcula métricas desde `UsoRepo` (promedios de 7 y 14 días, tendencias).
2. **Filtra** fichas cuyas `condiciones` se cumplen (determinista y testeable).
3. **Ordena** por relevancia: prioridad de la ficha + coincidencia de `palabras_clave` con la consulta opcional del adulto (TF-IDF simple, implementado a mano, sin paquetes).
4. Devuelve máx. 5 con su `fuente` visible y el disclaimer **«Orientativa, no es diagnóstico»** (reutiliza `disclaimerObservaciones`).
5. Si no hay datos suficientes (menos de 3 días), no emite nada y lo dice.
**6.3** Cuadro de búsqueda opcional: «¿Qué quieres mejorar?» (texto libre → mismas palabras clave). Todo local.
**6.4** Tests: cada ficha del JSON es válida (esquema, fuente no vacía, `op` conocido); casos de borde (sin datos, un solo día, valores en el umbral); orden estable; **ninguna ficha usa lenguaje diagnóstico** (test que busca palabras como «diagnóstico de», «padece», «tiene autismo grave»).

**Aceptación:** con datos de ejemplo, el panel muestra recomendaciones coherentes con fuente; sin datos, no muestra nada.

> Variante futura (no hacer ahora): LLM gratuito en la nube solo con métricas agregadas y anónimas, con opt-in explícito. Necesita decisión del dueño y política de privacidad pública.

---

# FASE 7 — Vocabulario y pictogramas (que no se olvide ninguno)

Hoy hay **42 pictogramas** frente a las **218 palabras** de Soto & Cooper (2021), ya transcritas en `research_notes/datos-publicos/soto-cooper-2021-lista-218-palabras.md`.

**7.1** Crea `docs/plan/vocabulario.md`: una tabla con `palabra | clase | categoría | id Mulberry | estado (hecho/falta/sin símbolo)`. **Es la fuente de verdad**: nadie decide por memoria.
**7.2** Busca cada palabra en `research_notes/datos-publicos/mulberry-symbol-info.csv` y `mulberry-symbols.zip`; copia **solo los SVG usados** a `assets/pictos/` (no todo el zip). Las palabras sin símbolo quedan marcadas «sin símbolo», **sin inventar** dibujos ni usar ARASAAC.
**7.3** Actualiza `assets/seed/pictogramas.json` y `categorias.json`. El vocabulario nuclear va **siempre en la misma posición**.
**7.4** Test `test/data/vocabulario_test.dart`: lee `vocabulario.md` y falla si una palabra «hecha» no tiene SVG existente, si un SVG no está en el JSON, o si hay ids duplicados.
**7.5** Atribución Mulberry (CC BY-SA 4.0) en la pantalla de créditos. Sin logos de terceros.
**7.6** Rendimiento: `cacheWidth` en los SVG o precarga de la categoría visible; mide en el emulador de gama baja (RAM <150 MB).

---

# FASE 8 — APK para el teléfono del dueño y checklist

**8.1** `scripts/build-apk.sh` (Fase 0.7) debe seguir verde. Genera `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.
**8.2** Para instalar en el teléfono propio basta la firma de debug actual (no crees claves ni keystore: es decisión del dueño, anótala en `decisiones-pendientes.md`).
**8.3** `docs/play/checklist-telefono.md` — pasos que el dueño ejecuta y marca (cada uno con "esperado" y casilla):
1. Instalar y abrir; completar la configuración del adulto; anotar el código de recuperación.
2. Conceder Acceso de uso. Elegir BlueTalk como inicio. Fijar pantalla.
3. Permitir una app (p. ej. TikTok) con límite de 5 min; abrirla; comprobar que el límite se aplica.
4. Tocar pictogramas; comprobar que la voz suena **solo** al tocar.
5. Jugar un juego; abrir el panel con el PIN; comprobar que los números coinciden con lo hecho.
6. Reiniciar el teléfono; comprobar que vuelve al modo niño.
7. «Olvidé mi PIN» con el código de recuperación.
8. Intentar salir: notificaciones, recientes, Asistente. Anotar qué escapa (esperable) y cómo se comporta.
9. Modo calma y texto al 200 %.
**8.4** Escribe `docs/informes/faseN-evidencia.md` por fase y `docs/informes/cierre.md` (lo hecho y verificado, lo NO VERIFICADO, decisiones pendientes).
**8.5** Invoca al subagente `revisor` y corrige lo grave.

---

# FASE 9 — Opcional (solo con decisión del dueño)

- **Supabase** (plan `docs/plan/06-backend-supabase.md`) para ver el panel desde otro teléfono: solo con opt-in del adulto, datos agregados (sin nombres reales ni fotos), RLS por cuenta del adulto, política de privacidad pública, y revisión de la política de Familias de Google Play. Plan gratuito de Supabase es suficiente para un piloto; ten en cuenta que pausa proyectos inactivos.
- **AccessibilityService / Device Owner** para un bloqueo más fuerte: solo si el piloto lo exige; Play lo restringe.
- **Play Store:** keystore de subida, AAB, icono adaptativo, formulario de Seguridad de los datos, declaración de Acceso de uso, política de privacidad en URL pública, pruebas cerradas.

---

## 9. Material de apoyo (referencia, no manual)

- `research_notes/` — apps AAC, opiniones de familias, datos públicos, lista Soto & Cooper (2021).
- Trabajos de BlueTalk del dueño (fuera del repositorio): tesis «Desarrollo de un Sistema de Comunicación Alternativa y Aumentativa mediante Arduino con salida de voz…» (2025) y el póster/artículo del sistema. Úsalos para el marco teórico, el método PECS y las escalas de valoración. **Si copias contenido, quita nombres de universidades y logos (D5).** El dueño debe copiar los PDF a `research_notes/trabajos-bluetalk/` si quiere que queden en el repositorio.
- Referencia web de BlueTalk (`bluetalk.lovable.app`): hoy solo muestra «¿Cómo te llamas?» y «¡Vamos!»; confirma el primer paso del flujo del niño.
