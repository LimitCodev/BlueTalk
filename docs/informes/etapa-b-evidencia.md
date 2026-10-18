# Etapa B — evidencia

Plan 13: P3 (marca y logo) y P4 (colores personalizables). Cada paso
cerró con `flutter analyze` (0), `flutter test` verde, un commit y su
sección aquí. Lo que solo se ve en un teléfono real se declara
**NO VERIFICADO**. Verificado = ejecutado y visto.

## Estado por paso

| Paso | Estado | Commit |
|---|---|---|
| P3.1 — extraer colores reales del cartel (script) | HECHO (abajo) | `5ef1cd3` |
| P3.2 — logo (burbuja + corazón) con `CustomPainter` | HECHO (abajo) | `f9c73fb` |
| P3.4 — ícono adaptive + PNGs heredados a mano | HECHO (abajo) | `a641698` |
| P3.5 — logo en shell y onboarding | HECHO (abajo) | `f9c73fb` |
| P3.6 — tokens de marca con AA | HECHO (abajo; refactorizado en P4a) | `5ef1cd3` |
| P3.7 — primer fotograma celeste (styles/launch) | HECHO (abajo) | `5ef1cd3` |
| P4 — 6 temas AA + selector + persistencia | HECHO (abajo) | `88a4fbe` + `a251741` |
| Humo en emulador con capturas | HECHO (abajo) | — |
| Cierre + revisor | VER EN `etapa-b-revisor.md` | — |

## P3.1 — extracción de colores del cartel (script, sin inventar)

Material: `referencia_logo_y_colores_iniciales.jpeg` (1073×1378,
JPEG progresivo). Método reproducible:

1. `djpeg -outfile /tmp/opencode/referencia.ppm <cartel>` (libjpeg).
2. Script Python stdlib (`/tmp/opencode/colores.py`, una sola vez):
   analiza zonas concretas del cartel (anillo de la burbuja, corazón,
   texto, titulares, fondos) y cuenta colores cuantizados (pasos de 8)
   + píxel más oscuro y más saturado de cada zona.

Resultado (los dominantes cuantizados son múltiplos de 8):

| Elemento del cartel | Color extraído | Uso en la app |
|---|---|---|
| Anillo burbuja y texto «BlueTalk» | `#2E6492` | `primaryStrong` / `Marca.azul` |
| Titulares navy | `#002848` | `text` / `primaryInk` / `Marca.navy` |
| Corazón verde | `#20A078` | `Marca.verde` (relleno/decoración) |
| Fondo celeste superior | `#70D0F8` | `primary` / `Marca.celeste` |
| Fondo celeste medio izquierda | `#88D0F0` | reserva |
| Banda inferior pale | `#B4E0F8` | reserva |
| Azul vivo de formas (derecha) | `#0088D8` | reserva / acentos |
| Pantalla del móvil del cartel | blanco → `#B8D8F0` | `surface` (blanco) |

Se descarta «Innovation», la insignia «TOP 100 JUMP CHILE», el logo de
Jump, la mano y el teléfono (decisión D5 del plan 12: sin terceros).

## P3.6 + P4 — AppColors como ThemeExtension con 6 paletas AA

P3.6 migró los tokens a la paleta del cartel (`5ef1cd3`); P4a los
convirtió en **`ThemeExtension`** (`88a4fbe`):

- `AppColors` es ahora una extensión del tema con 6 paletas
  predefinidas y nombre literal: **Celeste (por defecto), Verde suave,
  Lila suave, Durazno, Gris calmado, Alto contraste**. Nunca un
  selector libre de colores (rompería el contraste y la estabilidad).
- `bg` de las paletas pastel = tinte al ~12 % de su color fuerte
  (misma lógica documentada en P3.6: el celeste fuerte como fondo
  entero deslumbraría). El verde del corazón (`#20A078`, ~3.4:1 vs
  blanco) no llega a AA como texto: queda en `Marca.verde`.
- Colores semánticos (éxito/aviso/error) y **colores de marca fijos**
  (`Marca.*`: logo) no cambian con el tema. Los colores de las
  clases gramaticales del vocabulario **aún no existen** (Etapa C);
  cuando se añadan serán constantes fijas fuera del tema (plan 11 §2.1).
- Modo calma: filtrado gris global por encima de cualquier tema (ya
  existía en `app.dart`; no depende de la paleta, así que «manda el
  modo calma» queda garantizado de fábrica).
- Migración mecánica de **108 usos** de `AppColors.*` a
  `context.colores.*` (28 archivos), guiada por el analyzer; los
  estados (`AppColors.error`…) quedaron como estáticos y el logo pasó
  a `Marca.*`. `buildBlueTalkTheme(paleta)` genera el `ColorScheme`
  desde la paleta elegida.

**Aceptación P4 (tests, en verde):**
- `test/core/tokens_test.dart`: bucle sobre las 6 paletas verificando
  AA con la fórmula WCAG 2.2 — texto ≥4.5:1 sobre `bg` y `surface`,
  tinta sobre relleno ≥4.5:1, borde/icono ≥3:1, acento ≥4.5:1; y que
  `celeste` es el tema por defecto y cada tema tiene nombre literal.
  (Las 6 paletas pasaron a la primera; la verificación de contraste
  de la paleta de marca ya existía desde P3.6.)
- `test/features/ajustes_test.dart`: `setTema` persiste en
  SharedPreferences y vuelve tras «recargar» (simula el reinicio).

## P4b — selector en Ajustes con vista previa en vivo

`a251741`. Sección «Color de la pantalla» justo debajo del modo calma:
6 opciones (muestra de la paleta: fondo + relleno + nombre literal),
toda la opción es táctil, la elegida lleva borde grueso, negrita y
check; `Semantics(button, selected, label)`. Al tocar, el tema cambia
en **toda** la app al instante (el `settingsProvider` es optimista y
`app.dart` lo observa) y se guarda en preferencias locales.

Efecto secundario en tests (arreglado en el mismo commit): al crecer
la lista, la sección de recordatorios quedó bajo el pliegue de la
lista perezosa; el test de error de ajustes y el helper `hacerVisible`
de recordatorios ahora hacen `scrollUntilVisible` antes de buscar.

## P3.2 + P3.5 — logo oficial con CustomPainter

`f9c73fb`. `LogoBluetalk` dibuja la burbuja azul de marca con cara
sonriente blanca y el corazón verde del cartel, con geometría medida
sobre el cartel (viewBox 100×100: anillo r32/hueco25, cola, ojos r3.4,
sonrisa, corazón de discos + triángulo). Sin assets nuevos ni
paquetes. En la cabecera del shell (28 dp) y en el onboarding (84 dp,
con lema «Tu voz, siempre contigo 💚»).

- `AppAvatar` **se conservó**: `ajustes_screen.dart` lo usa como
  selector de avatar en la zona de adulto (no es decoración sobrante;
  borrarlo rompe Ajustes). Solo dejó de usarse en el shell.
- `c466072` (fix, visto en el emulador): la `Column` con
  `crossAxisAlignment: stretch` del onboarding forzaba el ancho de la
  caja y el painter se desbordaba gigante. El widget ahora lleva una
  caja interior centrada + `clipRect` + unidad por lado corto. Test de
  regresión añadido («en una Column con stretch no se desborda»).

## P3.4 — ícono adaptive + PNGs heredados, a mano

`a641698`. Generador propio (`gen_icon.py`, stdlib, sin paquetes):

- `mipmap-anydpi-v26/ic_launcher.xml`: adaptivo con fondo
  `@color/ic_launcher_background` (`#70D0F8`) y primer plano
  `@drawable/ic_launcher_foreground`.
- `ic_launcher_foreground.xml`: VectorDrawable (108×108, escala 0.63,
  logo dentro de la zona segura r≤36 — comprobado: punto más lejano a
  35.0).
- PNGs legacy 48/72/96/144/192 (densidades mdpi…xxxhdpi) generados
  con el mismo script (supersampling 3×3) para API < 26.
- El manifiesto apunta solo a `@mipmap/ic_launcher` (sin
  `roundIcon`); el recorte circular/cuadrado lo decide el sistema.
- `android:label` corregido de «bluetalk» a **«BlueTalk»** (identidad).

## Humo en emulador (`bluetalk_gama_baja`, API 28, x86_64, release)

Capturas en `docs/informes/capturas/`:

| Captura | Qué demuestra |
|---|---|
| `etapa-b-01-onboarding-logo.png` | Logo 84 dp correcto, lema 💚, fondo celeste (tras el fix) |
| `etapa-b-02-shell-logo.png` | Logo 28 dp en la cabecera del shell |
| `etapa-b-03-selector-celeste.png` | Selector de 6 temas, Celeste marcado con check |
| `etapa-b-04-durazno-marcado.png` | Durazno marcado + toda Ajustes ya en durazno |
| `etapa-b-05-shell-durazno.png` | Shell entero en durazno tras tocar la opción (vista previa en vivo) |
| `etapa-b-06-icono-launcher.png` | Ícono adaptive enmascarado por el launcher + etiqueta «BlueTalk» |

Dos fallos reales encontrados y corregidos gracias a estas capturas:
logo gigante por stretch (`c466072`) y etiqueta en minúsculas
(corregido en este cierre).

## NO VERIFICADO (requiere teléfono real o no capturable así)

- Primer fotograma de arranque (fondo celeste sin destello blanco):
  corregido en código (`5ef1cd3` incluye `drawable-v21` y
  `values/colors.xml`), pero `screencap` llega tarde — demasiado
  rápido para capturarlo; se verá al instalar en el móvil del dueño.
- PNGs heredados del ícono (API < 26): generados e inspeccionados,
  pero ningún dispositivo/API de prueba los usa (API 28 ya es
  adaptivo).
- Tema elegido, logo y ícono en el teléfono físico del dueño.
- Siguen de la Etapa A: biometría, TTS, POST_NOTIFICATIONS, Doze,
  Atrás/dibujo con textura táctil, API 24.
