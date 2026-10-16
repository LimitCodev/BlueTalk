# Plan 13 — Pulido tras la primera prueba en teléfono real

**Para:** el agente que ejecuta (OpenCode / mimo). **Léelo entero antes de tocar código.**
**Requisito previo:** `AGENTS.md` y el §0 de `docs/plan/11-fases-1-a-3-excelencia.md` (estándar, honestidad, evidencia). Todo lo del §0 aplica aquí.
**Cuándo:** después de cerrar la Fase 0 del plan 12. Puede ir **antes** de las Fases 1+ del plan 12 si el dueño quiere un APK de prueba mejor. Las fases de este plan se llaman **P1–P7**.

## Origen

El dueño instaló el APK en un móvil real y reportó:

1. El botón **Atrás** del teléfono cierra toda la app.
2. En **Artista** (dibujo), al dibujar con el dedo la pantalla a veces se desplaza en vez de dibujar.
3. Los colores y la imagen de la app no coinciden con el logo oficial.
4. Se quiere **personalizar los colores** de toda la app.
5. El panel del adulto es solo una lista de datos; debe ser **visual** (gráficos circulares, fáciles de entender).
6. Quedó pendiente cómo distribuir el APK sin que parezca sospechoso, y cómo cuidar los teléfonos de pocos recursos.

Cada fase termina con `flutter analyze` (0), `flutter test` (verde), un commit por paso (`TIPO: descripción`, ≤70 caracteres, sin texto de IA, sin `Co-Authored-By`) y una sección en `docs/informes/p-evidencia.md`. Lo que solo se ve en un teléfono físico se declara **NO VERIFICADO**.

---

## P1 — Botón Atrás dentro de la app (prioridad máxima)

**Causa (verifícala antes de arreglar):** `lib/app/router.dart` usa `StatefulShellRoute.indexedStack`. Con ese router, Atrás en cualquier pestaña saca la app. Las vistas internas de Aprender (juegos, cuentos, Artista) probablemente cambian por estado y no por ruta, así que Atrás tampoco las cierra. Esto responde la pregunta abierta de `docs/informes/decisiones-pendientes.md` («Botón Atrás en `/home/aprender`»): **el dueño decidió que Atrás debe moverse dentro de la app.**

**Comportamiento exigido (predecible, literal):**

| Dónde está el usuario | Atrás hace |
|---|---|
| Dentro de un juego o cuento | Vuelve a la lista de Aprender |
| En Aprender, Rutinas o Ajustes (lista principal) | Vuelve a **Comunicar** |
| En Comunicar | Sale de la app (comportamiento normal de Android) |
| En una pantalla del modo padre | Vuelve al panel del padre; desde el panel, a Ajustes |
| En un diálogo o PIN | Cierra el diálogo |

**Pasos:**

1. Mapea cómo se abren hoy las vistas internas (`juegos_screen.dart`, `artista_screen.dart`, cuentos, memoria, modo padre). Pásalas a **rutas de go_router** (`/home/aprender/artista`, etc.) para que Atrás funcione solo y por igual en todas. Si pasar una a ruta es muy grande, usa `PopScope` en esa vista, pero explica por qué en el informe.
2. Añade `PopScope(canPop: false, onPopInvokedWithResult: ...)` en `AppShell` que, si `shell.currentIndex != 0`, haga `shell.goBranch(0)`.
3. Con el **modo niño/kiosko** (plan 12), Atrás en Comunicar **no** debe sacar al niño de BlueTalk. Deja un gancho (`bool saleConAtras`) que el plan 12 active.
4. Test de widget por cada fila de la tabla (`tester.binding.handlePopRoute()`).

**Aceptación:** los cinco casos de la tabla tienen test verde. En el teléfono, NO VERIFICADO hasta que el dueño lo pruebe.

---

## P2 — Artista: dibujar no debe mover la pantalla

**Causa:** `artista_screen.dart` pone `_Lienzo` dentro de `SingleChildScrollView`. Un arrastre vertical compite con el desplazamiento. `onPanStart` además espera unos píxeles de «tolerancia» antes de empezar, así que el principio del trazo se pierde.

**Solución (en este orden de preferencia):**

1. **Pantalla sin desplazamiento mientras se dibuja.** El lienzo ocupa todo el alto libre (`Expanded`), la barra de herramientas va compacta arriba o abajo (colores, grosor, goma, deshacer, borrar todo; ≥48 dp), y la **galería pasa a una hoja inferior** (`showModalBottomSheet`) abierta con un botón «Mis dibujos». Ya no hay nada que desplazar.
2. Cambia `GestureDetector.onPan*` por **`Listener`** (`onPointerDown/Move/Up/Cancel`) con `behavior: HitTestBehavior.opaque`. `Listener` no espera tolerancia y empieza el trazo en el primer contacto, incluido el punto suelto.
3. Ignora el segundo dedo (guarda el `pointer` activo) para que la palma o un segundo toque no rompan el trazo.
4. Si por algún motivo la pantalla debe seguir desplazándose, usa `NeverScrollableScrollPhysics` mientras haya un puntero abajo.

**Mejoras de diseño del dibujo** (pensadas para niños pequeños y para motricidad fina):

- Pinceles grandes por defecto, 3 grosores con icono (no números).
- Colores de la paleta de marca (P3) más los básicos.
- Plantillas simples para colorear (contornos) como opción, solo si no suben mucho el tamaño del APK.
- Botón «Deshacer» grande. Al borrar todo, pide confirmación al adulto o un segundo toque, no un diálogo largo.

**Aceptación:** test de widget que simula un arrastre vertical largo sobre el lienzo y comprueba que (a) se crea un trazo y (b) el `ScrollController` de la pantalla no cambia. Prueba táctil en el teléfono: NO VERIFICADO.

---

## P3 — Identidad visual: logo y paleta oficiales

**Material:** `referencia_logo_y_colores_iniciales.jpeg` en la raíz del repo. Es un cartel del proyecto. El logo oficial es la **burbuja de chat celeste sonriente con un corazón verde** y el texto «BlueTalk». Lema del cartel: «Tu voz, siempre contigo».

**Pasos:**

1. **Extrae los colores reales del cartel** (burbuja, corazón verde, texto, fondo celeste, azul oscuro de titulares). Hazlo con un script de una sola vez (`python3 -I` con Pillow, o `flutter` con `dart:ui`) y anota los códigos hexadecimales en el informe. No los inventes.
2. **Recorta el logo** (solo burbuja + texto «BlueTalk»). **No uses** del cartel: el texto «Innovation», la insignia «TOP 100 JUMP CHILE», el logo de Jump ni la mano ni el teléfono. Se cumple la decisión D5 del plan 12 (sin logos de terceros).
3. Guarda el logo en `assets/brand/` (PNG con transparencia; mejor SVG si se puede recrear con `CustomPainter` sin dependencias nuevas). Declara el asset en `pubspec.yaml`.
4. Crea el **ícono de la app**: adaptive icon (primer plano = burbuja, fondo = celeste de marca) en `android/app/src/main/res/mipmap-*` y `mipmap-anydpi-v26`. Hazlo a mano, **sin** paquetes nuevos. Comprueba el recorte circular y cuadrado.
5. Sustituye `AppAvatar` y la pantalla de bienvenida (`onboarding_screen.dart`) por el logo oficial. La pantalla de inicio puede copiar el lema «Tu voz, siempre contigo» y pedir el nombre, como en el cartel.
6. Reemplaza los tokens de `lib/core/theme/app_colors.dart` por la paleta de marca. **Conserva** el contraste AA: `test/core/tokens_test.dart` debe seguir verde. Si un color de marca no llega a 4.5:1 como texto, úsalo solo como relleno y oscurece el texto; explícalo en el informe.
7. Revisa `values/styles.xml` y la pantalla de arranque de Android para que el primer fotograma ya sea celeste de marca (sin destello blanco).

**Aceptación:** capturas del emulador antes/después en `docs/informes/capturas/`. `tokens_test.dart` verde.

---

## P4 — Colores personalizables para toda la app

**Idea:** el adulto elige un tema de color en Ajustes; la app entera lo respeta. Muchos niños autistas tienen preferencias o sensibilidades de color fuertes.

**Diseño mínimo (sin dependencias):**

- 5–6 **temas predefinidos** con contraste AA verificado: Celeste (marca, por defecto), Verde suave, Lila suave, Durazno, Gris calmado, Alto contraste.
- Un solo selector de **color principal** entre esas opciones. **No** un selector libre de colores: un color libre puede romper el contraste y el vocabulario por colores (Fitzgerald).
- Se guarda en `SharedPreferences` junto a los ajustes (`settings_controller.dart`).
- `AppColors` pasa de constantes a un `ThemeExtension` o a un proveedor de Riverpod que genere `ColorScheme` desde el tema elegido. Migra los usos de `AppColors.*` de forma mecánica.
- Los **colores del vocabulario** (clases gramaticales del comunicador) **no cambian** con el tema: el plan 11 §2.1 exige posiciones y colores estables.
- El **modo calma** (grises) sigue mandando sobre cualquier tema.
- Vista previa en vivo al elegir. Todo literal y sin sonido.

**Aceptación:** test que recorre cada tema y verifica contraste AA de texto sobre superficie y de botón. Test de que el cambio de tema persiste tras reiniciar.

---

## P5 — Panel del adulto visual (gráficos fáciles de entender)

**Problema:** `lib/features/padre/dashboard/resumen_screen.dart` y `barras.dart` muestran listas y barras. Un padre sin formación técnica necesita ver de un vistazo **qué pasó y si va bien**.

**Reglas de diseño:**

- Cada gráfico responde **una pregunta en lenguaje humano**, escrita como título («¿En qué usó el tiempo hoy?»).
- Máximo **3–4 gráficos por pantalla**, tarjetas grandes, número grande + una frase («23 min en juegos»).
- Sin ejes con jerga. Etiquetas dentro o junto al gráfico, no en una leyenda lejana. Colores **más** texto/patrón, nunca solo color (daltonismo).
- Siempre con el aviso: «Información orientativa, no es un diagnóstico».
- Debe verse bien y fluir en gama baja: dibuja con `CustomPainter` (ya usado en Artista), **sin paquetes de gráficos**. Si el dueño aprueba una dependencia, anótalo en `decisiones-pendientes.md` antes.

**Gráficos propuestos:**

1. **Anillo (dona) «Tiempo de hoy»:** comunicar · juegos · rutinas · otras apps. Centro: minutos totales.
2. **Anillo de progreso «Rutinas de hoy»:** actividades hechas / planeadas (p. ej. 4 de 6).
3. **Barras de 7 días «Uso de esta semana»:** un grupo por día, con la barra de hoy resaltada.
4. **«Palabras más usadas»:** los 5 pictogramas con su icono y un número (no una tabla de texto).
5. **«¿Cómo se ha sentido?»:** una fila de caritas por día (datos del registro de emociones de P6.2), con la carita más frecuente de la semana destacada y una frase literal («Esta semana estuvo más veces tranquilo»). Es el gráfico que más valoran los usuarios de apps similares.
6. **Línea de rachas/avance:** «Días seguidos usando BlueTalk», como insignia simple, sin presión (nada de «perdiste la racha»).
7. **Tarjeta de recomendación:** una sola frase accionable, escrita por reglas locales (plan 12 D3), con enlace a «Ver por qué».

**Pasos:**

1. Crea `lib/features/padre/dashboard/graficos/` con `dona.dart`, `anillo_progreso.dart`, `barras_semana.dart`; cada uno es un `CustomPainter` pequeño con su `Semantics` (etiqueta que lee todo el dato, para TalkBack).
2. Un test por gráfico (golden o de valores: el ángulo del arco es proporcional al dato; suma 100 %; sin datos muestra «Aún no hay datos», no un círculo vacío).
3. Pantalla de resumen reorganizada: arriba el anillo del día, debajo las tarjetas. Mantén el banner de demostración si hay datos de ejemplo.
4. **Estado vacío amable**: primera vez, sin datos, explica qué verá cuando el niño use la app.
5. Prueba de rendimiento: abrir el panel con 30 días de datos no pasa de 16 ms por cuadro en el perfil de `integration_test` (si no hay dispositivo, NO VERIFICADO).

**Aceptación:** capturas en `docs/informes/capturas/`; tests verdes; el padre entiende cada gráfico sin leer documentación (lo valida el dueño).

---

## P6 — Mejoras sacadas de las reseñas reales y claridad para niño y adulto

**Léelo primero:** `docs/informes/resenas-apps-mejoras.md` (20 reseñas reales de AutistApp en la App Store de Chile, más Leeloo y Proloquo2Go, con fuentes y límites). AutistApp es para jóvenes y adultos; BlueTalk es para niños. Copia las **lecciones**, no el catálogo. No añadas nada que implique red, cuentas, foros, anuncios ni analítica.

### 6.1 Fallos que la gente sufrió y que BlueTalk debe probar a mano y con tests (prioridad alta)

1. **Escribir el nombre en el inicio** con el teclado abierto: la pantalla no se congela, el botón «Continuar» queda visible y se puede avanzar (test de widget con `viewInsets`). Se probó en el teléfono: NO VERIFICADO.
2. **Añadir una actividad en Rutinas**: se guarda, aparece en la lista y sobrevive a cerrar y abrir la app. Si falla, muestra un mensaje literal («No se pudo guardar. Prueba otra vez.»), nunca silencio.
3. **Volver atrás** en toda pantalla (es P1).
4. **La voz suena** al tocar un pictograma, y **nunca** sola al abrir la app. Pantalla de diagnóstico de voz en el modo padre («¿No se oye? Toca aquí»).

### 6.2 Funciones nuevas de coste bajo (una por commit; si es grande, nota de diseño de 1 página)

| Idea | Por qué (reseñas) | Cómo hacerlo fácil |
|---|---|---|
| **Registro de emociones en 1 toque** | La función más elogiada de AutistApp («me ayuda a vigilar cómo estoy y evitar crisis») | 5 caritas grandes con palabra debajo: Feliz, Tranquilo, Triste, Enojado, Asustado. Un toque, sin texto que escribir. Se guarda con la hora. Ver gráfico en P5.5. |
| **Botón «Necesito ayuda»** siempre en el mismo lugar de Comunicar | Seguridad del niño | Pictograma fijo; al tocarlo, la voz dice «Necesito ayuda». |
| **Tutorial corto para el adulto (3 pantallas)** al primer inicio | Reseñas de Proloquo2Go: «abrumador sin logopeda» | 1) Qué es BlueTalk. 2) Qué datos guarda (solo el teléfono). 3) Cómo entrar al panel (PIN). Se puede saltar y se reabre desde Ajustes. |
| **Consejos cortos offline** para el adulto (en lugar de foro o blog) | Pedidos de «blogs», «guías» y «trámites» | 10–15 tarjetas de 3 líneas, con fuente citada por texto. Sin red. |
| **Novedades** en Ajustes | «El desarrollador sigue añadiendo mejoras» | Lista de 3 líneas por versión, literal. |
| **FAQ y contacto** en el modo padre | Soporte amable fue elogiado en Leeloo | Pregunta, respuesta corta y un correo. El correo lo decide el dueño (no inventes uno). |
| **Tema sobrio sin personajes** | Una persona adulta autista criticó el diseño «cutesy» de Leeloo | Tema de P4 para niños mayores y adolescentes. |
| **Modo oscuro suave como tema** | Varias reseñas piden «versión oscura» | Tema de P4, no depende del sistema. |
| **Copia de seguridad local** | Piden «cuenta con correo» para no perder datos | Plan 11 §2.4. Sigue sin cuentas. |

**Descartado a propósito** (explícalo si el dueño pregunta): foro, bolsa de empleo, anuncios, cuentas con correo, cambio de idioma (queda como idea futura).

### 6.3 Reglas de claridad para el niño (todas las pantallas del modo niño)

- **Una acción principal por pantalla.** Botones ≥ 64 dp (más que el mínimo de 48 dp), con **icono + palabra**, nunca solo icono ni solo texto.
- **Texto literal y corto:** máximo 6–8 palabras por frase. Un verbo en imperativo claro («Toca para dibujar»). Sin metáforas, sin humor, sin ironía.
- **Siempre en el mismo lugar:** navegación inferior fija, botón Atrás arriba a la izquierda, vocabulario nuclear sin reordenar.
- **Respuesta visible a cada toque** (borde, hundimiento del botón) sin sonido ni animación larga; con modo calma, sin animación.
- **Pocos colores a la vez:** una paleta de marca suave (P3); nada de rojo intenso ni parpadeos; sin fondos recargados. (Una reseña dice que «muchos colores molestan».)
- **Sin castigos ni presión:** sin cronómetros visibles, sin «perdiste», sin puntuaciones negativas. Los errores se dicen en positivo («Prueba otra vez»).
- **Sin sorpresas:** ninguna ventana emergente, anuncio ni cambio de pantalla que el niño no haya pedido.
- **Pictogramas revisados:** antes de incluir cada uno, un adulto confirma que se entiende solo. Si dudas, usa una foto propia (plan 11 §2.3).

### 6.4 Reglas de claridad para el adulto (panel, ajustes, tutorial)

- **Respuesta primero:** cada pantalla empieza con un titular en frase completa («Hoy usó BlueTalk 23 minutos») y luego el detalle.
- **Lenguaje de familia, no de clínica:** nada de «ítems», «métricas» ni «sesiones». Di «veces», «minutos», «actividades».
- **Una pregunta por tarjeta** y un número grande. Los gráficos son los de P5.
- **Cada permiso o ajuste dice para qué sirve** en una frase y qué pasa si se desactiva.
- **Siempre una salida:** botón «Atrás» y «Cancelar» visibles; nada irreversible sin una confirmación de una línea.
- **Avisos honestos:** «Información orientativa, no es un diagnóstico» y los límites del modo niño (plan 12 §2).
- **Prueba de comprensión:** pide al dueño que le enseñe el panel a **una persona que no conozca la app** y anote qué no entendió. Ese resultado va a `docs/informes/p-evidencia.md`. Si no se hace, queda NO VERIFICADO.

### 6.5 Aceptación de P6

- Tests verdes para 6.1 (1–3) y para el registro de emociones (se guarda, aparece en el gráfico de P5.5).
- Revisión de todas las cadenas de texto visibles: ninguna supera 8 palabras en modo niño ni usa jerga en modo adulto. Deja la lista de cadenas revisadas en el informe.
- Lo que depende de un teléfono físico o de una familia real: NO VERIFICADO.

---

## P7 — Confianza del usuario y ahorro de recursos (instalación y rendimiento)

Esto recoge lo que el dueño preguntó sobre los avisos de WhatsApp y Play Protect, y sobre móviles de pocos recursos.

### 7.1 Instalar sin parecer sospechoso

- **Lo que no se puede evitar fuera de Play Store:** WhatsApp advierte con **todo** `.apk`; Play Protect avisa de «desarrollador desconocido» con cualquier certificado nuevo. No hay configuración en el código que lo quite. **No** intentes engañarlo (cambiar extensión, empaquetar raro, pedir desactivar Play Protect): genera más desconfianza.
- Lo que **sí** ayuda:
  1. Firmar con el keystore propio (ya hecho).
  2. Distribuir con un **enlace de descarga** (Drive u otro), no por WhatsApp.
  3. Un **texto corto de instalación** para quien prueba: «Toca **Instalar de todas formas** (el texto pequeño), no **Entendido**. La app no usa internet ni pide cuenta.» Guárdalo en `docs/play/instalar-apk.md`.
  4. Un **hash SHA-256** del APK publicado junto al enlace, para que se pueda comprobar que no cambió. Que `scripts/build-apk.sh` lo imprima.
  5. Mantener **pocos permisos** (cada uno justificado en `docs/play/permisos.md`) y **sin red** (`INTERNET` ausente del manifiesto de release). Eso es lo que hace creíble el mensaje «no sale nada del teléfono».
  6. A largo plazo: subir la app a **prueba cerrada de Play Console** cuando el dueño decida; es lo único que elimina el aviso. **No lo hagas tú:** es decisión del dueño (`decisiones-pendientes.md`).

### 7.2 Móviles de pocos recursos

- Genera **un APK por arquitectura** (`--split-per-abi`): `arm64-v8a` para casi todos y `armeabi-v7a` para móviles viejos. El APK actual pesa ≈20 MB por incluir varias.
- Activa reducción de código y de recursos (`minifyEnabled`, `shrinkResources`) si no rompe nada; comprueba el APK después.
- Imágenes y pictogramas en **WebP** y a la resolución que realmente se muestra.
- Fuentes: solo las que se usan; nada de fuentes de red.
- Listas con `ListView.builder`; evita `Opacity`/`ShaderMask` en listas largas; `const` donde se pueda.
- Spark/emulador de pruebas: no cambia nada aquí; en el emulador, perfil de 1–2 GB de RAM y Android 7 (API 24).
- Reporta en el informe: tamaño de cada APK, tiempo de arranque en frío y uso de memoria al abrir Artista y el panel. Si no hay dispositivo, **NO VERIFICADO**.

---

## Orden recomendado

Es el de la tabla de `AGENTS.md` (etapas A, B, E). Resumen: **A** = P1, P2, P6.1 y P7 (APK de prueba nuevo); **B** = P3 y P4 (juntos, porque P4 reemplaza la paleta que fija P3); **E** = P5 y el resto de P6, junto con las fases 4 a 6 del plan 12, porque el panel visual necesita los datos del registro de uso.

## Cierre

Al terminar, `docs/informes/p-evidencia.md` debe decir qué quedó hecho y verificado, qué es NO VERIFICADO (necesita teléfono físico), y qué decisiones esperan al dueño. Invoca al subagente `revisor` y corrige lo grave.
