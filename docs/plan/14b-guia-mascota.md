# Plan 14B — Guía de primera vez con la mascota de BlueTalk

**Parte de:** `docs/plan/14-menu-mascota-graficos.md` (lee antes su §1–§3).
**Requisito:** 14A cerrado (la guía señala tarjetas del menú y usa `/inicio`).
**Objetivo:** la primera vez que se abre la app, el ave de BlueTalk hace un recorrido guiado.
Habla en globos de texto, ilumina cada parte y oscurece el resto con un gris translúcido.
Cada paso tiene el botón «Siguiente». La guía se dirige al **adulto** y termina llevándolo
al **Modo padre** para crear su código.

## 1. Comportamiento

- **Cuándo aparece:** al llegar a `/inicio` con `guia_vista == false`, es decir, justo después del nombre
  en el primer arranque. No aparece en arranques siguientes.
- **Se marca como vista** solo al pulsar el botón del último paso o «Saltar». Si la app se cierra a mitad,
  la próxima vez empieza en el paso 1 (plan 14 §5.2).
- **Repetir:** en Ajustes, una entrada «Ver la guía otra vez» la inicia desde el paso 1, sin pedir código.
- **Fondo:** gris oscuro translúcido (`Colors.blueGrey.shade900` con opacidad 0,72) que cubre todo
  menos el **hueco** del elemento explicado.
- **Hueco:** rectángulo redondeado con 8 dp de margen alrededor del elemento y borde de 3 dp del color primario.
  Fuera del modo calma, el borde «respira» (opacidad entre 0,6 y 1, 1,2 s, en bucle).
- **Toques:** el fondo bloquea todos los toques. Solo responden los botones de la guía, para que el
  adulto no abra nada por error. El elemento iluminado tampoco responde durante la guía.
- **Globo:** tarjeta blanca (o `surface` del tema) con un piquito hacia el elemento. Texto de 18 sp o más
  y frases cortas y literales.
  - Botones del globo: «Atrás» (desde el paso 2), «Siguiente» y, en el último paso, «Ir al Modo padre».
  - Indicador «Paso 3 de 11».
- **Mascota:** al lado del globo, de unos 120 dp (96 dp en pantallas de menos de 360 dp de ancho).
  Fuera del modo calma, entra con un salto suave (escala de 0,8 a 1, 250 ms) en cada paso.
- **Posición:** si el elemento está en la mitad superior, el globo va debajo; si está en la inferior,
  va arriba. La mascota se pone del lado con más espacio.
- **Saltar** (decisión D3): botón de texto arriba a la derecha. Pregunta «¿Saltar la guía? Te llevamos
  al Modo padre para crear tu código.» Al confirmar, marca la guía como vista y abre `/padre`.
- **Atrás de Android** durante la guía: paso anterior. En el paso 1 no hace nada.
- **Sin voz.** La guía no habla. Solo texto, como exige `AGENTS.md`.
- **Modo calma:** sin «respirar», sin salto y sin transición. El gris y el hueco se mantienen.
- **TalkBack:** el globo es una región `Semantics(liveRegion: true)`. Al cambiar de paso, se lee su texto.

## 2. La mascota: imágenes disponibles y posturas

En `mascota/` hay **11 PNG** de 479×521 px con fondo transparente. El dueño entregó del 6 al 11
el 2026-11-12, para la guía:

| Archivo actual | Asset (`assets/mascota/`) | Postura | Uso en la guía |
|---|---|---|---|
| `perspectiva1.png` | `ave_saluda_tablero.png` | Saluda con un ala, de pie sobre un tablero de pictogramas | Comunicar |
| `perspectiva2.png` | `ave_brazos_abiertos.png` | Alas abiertas, de frente, sonriente | Bienvenida |
| `perspectiva3.png` | `ave_manos_juntas.png` | Alas juntas al pecho, atenta | Rutinas |
| `perspectiva 4.png` | `ave_volando.png` | Volando, de perfil | Aprender |
| `perspectiva5.png` | `ave_alas_abiertas.png` | Alas abiertas, cuerpo girado | Ajustes |
| `perspectiva6.png` | `ave_perfil.png` | De perfil, mirando a su izquierda, alas abajo | Tablero nuclear |
| `perspectiva7.png` | `ave_bandera.png` | Sostiene una bandera «BlueTalk» y señala arriba | El menú (carrusel) |
| `perspectiva8.png` | `ave_pulgar.png` | Sentada, con el pulgar arriba | Barra superior y modo calma |
| `perspectiva9.png` | `ave_pensando.png` | Pensativa, con el ala en el pico | Categorías |
| `perspectiva10.png` | `ave_candado.png` | Abraza un candado con llave | Saltar la guía (diálogo) |
| `perspectiva11.png` | `ave_candado_senala.png` | Candado con llave y señala arriba a su izquierda | Modo padre (último paso) |

**No se voltea ninguna imagen.** Todas muestran texto («BlueTalk» en la sudadera o en la bandera,
«SECURE» en el candado), y volteado se leería en espejo. Con 11 posturas ya no hace falta voltear:
quita el parámetro `voltear` del diseño. Si el globo queda del lado al que mira el ave, se acepta.

**Aviso:** el candado dice «SECURE», en inglés. No impide usarlo. Si el dueño quiere todo en español,
pide una versión con «SEGURO» o sin texto. Anótalo en `decisiones-pendientes.md`.

**Preparación de assets:**
1. Copia los 11 archivos a `assets/mascota/` con los nombres de la tabla, sin espacios. Decláralos en `pubspec.yaml`.
2. Usa `Image.asset(..., cacheWidth: 300)` para no decodificar 479 px en teléfonos de gama baja.
   Pesan unos 1,8 MB en total; el APK crece más o menos eso.
3. Hay mucho margen transparente. Recortarlo es opcional: no hay ImageMagick ni Pillow en la máquina,
   así que no instales nada. Ajusta el margen con `Alignment` y `fit` si hace falta.
4. Pon `excludeFromSemantics: true` en la imagen. El texto del globo ya lo dice todo.
5. Deja la carpeta `mascota/` de la raíz como está (es material del dueño). Pregunta si se borra.

## 3. Los 11 pasos

El texto va dirigido al adulto, con «tu hijo o hija». Va literal y sin metáforas. Ningún paso pasa de 2 frases cortas.

| # | Pantalla | Qué se ilumina (`GuiaObjetivo`) | Postura | Texto del globo |
|---|---|---|---|---|
| 1 | `/inicio` | Nada (fondo entero gris, globo centrado) | brazos abiertos | ¡Hola! Soy el ave de BlueTalk. Te enseño la app en 11 pasos cortos. |
| 2 | `/inicio` | `menuCarrusel` | bandera | Este es el menú. Desliza hacia arriba o abajo, o usa las flechas. Toca el botón del centro para entrar. |
| 3 | `/inicio` | `menuTarjeta(comunicar)` | saluda tablero | **Comunicar**: tu hijo o hija toca pictogramas para formar frases. La voz suena solo al tocar. |
| 4 | `/inicio` | `menuTarjeta(aprender)` | volando | **Aprender**: juegos de memoria, cuentos y dibujo. |
| 5 | `/inicio` | `menuTarjeta(rutinas)` | manos juntas | **Rutinas**: el horario del día y «primero y luego». Ayudan a saber qué viene después. |
| 6 | `/inicio` | `menuTarjeta(ajustes)` | alas abiertas | **Ajustes**: la voz, los colores y el tamaño. |
| 7 | `/home/comunicar` | `fraseBarra` | saluda tablero | Aquí se arma la frase. El botón de hablar la lee en voz alta. |
| 8 | `/home/comunicar` | `tableroNuclear` | perfil | Estas palabras básicas están siempre en el mismo lugar. Así se aprenden de memoria. |
| 9 | `/home/comunicar` | `categorias` | pensando | Las categorías tienen más palabras: comida, lugares, emociones y más. |
| 10 | `/home/comunicar` | `barraSuperior` (Inicio + modo calma) | pulgar | La casa vuelve al menú. El botón de contraste activa el modo calma: menos color y sin movimiento. |
| 11 | `/inicio` | `menuTarjeta(padre)` | candado señala | **Modo padre** es solo para ti. Primero acepta las condiciones y luego crea un código de 6 dígitos que solo tú sepas. |

El diálogo «¿Saltar la guía?» muestra la postura **candado**.

- El botón del paso 11 dice **«Ir al Modo padre»**. Marca `guia_vista = true` y hace `context.go('/padre')`.
  Ahí entra el flujo actual: condiciones (`LegalScreen`) → gate en fase `crear` → `confirmar` → Resumen.
  La guía termina en ese momento (decisión del dueño).
- Si ya existe un código (`pinStore.creado`), el texto del paso 11 cambia a:
  «**Modo padre** es solo para ti. Aquí entras con tu código para ver estadísticas y ajustes.».
- En los pasos 3–6 y 11, antes de medir el hueco, la guía llama a `centrar(opción)` del carrusel (14A §A2.9)
  y espera a que termine el desplazamiento.
- En los pasos 7 y 11 la guía cambia de pantalla con `context.go(...)` y espera un frame antes de medir.

## 4. Diseño técnico (sin dependencias)

Carpeta nueva: `lib/features/guia/`. Cada archivo tiene 100 líneas o menos.

| Archivo | Contenido |
|---|---|
| `guia_pasos.dart` | `enum GuiaObjetivo`, `enum PosturaAve` (una por asset), `class GuiaPaso {ruta, objetivo?, postura, texto}`, y la lista `const pasosGuia`. |
| `guia_controller.dart` | `Notifier<int?>`: `null` = sin guía. Tiene `iniciar()`, `siguiente()`, `anterior()`, `terminar()` y `saltar()`. Persiste `guia_vista` con `almacenLocalProvider`. |
| `guia_objetivos.dart` | `guiaObjetivosProvider`: un mapa de `GuiaObjetivo` a `GlobalKey`. El widget `GuiaAncla(objetivo:, child:)` registra la key. |
| `guia_capa.dart` | Widget que se monta **una vez** en `MaterialApp.router(builder:)`, encima del router. Mide el `RenderBox` del objetivo y vuelve a medir con `addPostFrameCallback` y al cambiar `MediaQuery.sizeOf` (por ejemplo, al girar). Incluye un `PopScope`. |
| `guia_fondo.dart` | `CustomPainter`: un `Path.combine(PathOperation.difference, pantalla, huecoRRect)` relleno de gris, más el borde del hueco. |
| `guia_globo.dart` | El globo con piquito, el texto, el indicador «Paso n de 11» y los botones. |
| `mascota.dart` | `Ave(postura:, tamano:)`. Sin volteo. Respeta el modo calma. |

Puntos a resolver al implementar:

1. **Objetivos:** envuelve con `GuiaAncla` el carrusel y cada tarjeta (14A), la `PhraseBar`, el tablero nuclear,
   la cuadrícula de categorías y el grupo de botones de la `AppBar` del shell. Cambia lo mínimo en cada
   archivo. `phrase_bar.dart` está en `_deuda`: si crece, compénsalo.
2. **Objetivo ausente:** si la key no tiene contexto (pantalla aún no construida), muestra el paso sin hueco
   y con el globo centrado. Nunca debe lanzar una excepción.
3. **Diálogos de primer arranque:** comprueba que ninguno se abra encima de la guía (`grep -rn showDialog lib`).
   Si alguno aparece al abrir Comunicar, pospónlo hasta que `guia_vista` sea verdadero.
4. **Lectura inicial:** carga `guia_vista` en `main()` junto al perfil (igual que `initialProfileProvider`),
   para no ver un parpadeo del menú sin guía.
5. **Ajustes:** añade «Ver la guía otra vez» a la sección de información (`ajustes_info.dart`). Al tocarlo:
   `context.go('/inicio')` y luego `iniciar()`.

## 5. Pasos y commits

1. `CHORE: assets de la mascota con nombres sin espacios`: assets, `pubspec.yaml` y `mascota.dart` con su test
   (cada `PosturaAve` carga su asset sin error).
2. `FEAT: capa de guia con fondo gris y hueco iluminado`: `guia_fondo`, `guia_capa`, `guia_objetivos`.
   Test: el hueco coincide con el rectángulo del objetivo y el fondo absorbe los toques.
3. `FEAT: pasos de la guia con la mascota y boton Siguiente`: `guia_pasos`, `guia_controller`, `guia_globo`.
   Tests: siguiente, anterior, el 1 no retrocede, el último marca la guía como vista y navega a `/padre`.
4. `FEAT: anclas de la guia en menu y comunicador`: los `GuiaAncla` y el arranque automático en `/inicio`.
   Test de integración en el emulador: el recorrido de 11 pasos en una instalación limpia.
5. `FEAT: repetir la guia desde Ajustes y saltarla`: incluye el texto alternativo del paso 11.
6. `DOCS: evidencia de la guia con la mascota`: `docs/informes/14b-evidencia.md`, con una captura de cada
   paso en `docs/informes/capturas/14b-paso-NN.png`, en claro y en calma.

## 6. Aceptación

- Instalación limpia: nombre → menú → 11 pasos → condiciones → crear código → Resumen.
- Cada hueco coincide con su elemento en vertical, en horizontal y en una pantalla de 320 dp.
- El fondo no deja tocar nada. «Atrás» y el botón de Android retroceden un paso.
- Con el modo calma nada se mueve. TalkBack lee cada paso (sin teléfono es **NO VERIFICADO**).
- Ninguna imagen con el texto «BlueTalk» aparece volteada.
- `flutter analyze` con 0 problemas y `flutter test` en verde.
