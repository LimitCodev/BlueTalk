# Etapa B — evidencia (EN CURSO)

Plan 13: P3 (marca y logo) y P4 (colores personalizables). Cada paso
cierra con `flutter analyze` (0), `flutter test` verde, un commit y una
sección aquí. Lo que solo se ve en un teléfono real se declara
**NO VERIFICADO**.

## Estado por paso

| Paso | Estado |
|---|---|
| P3.1 — extraer colores reales del cartel (script) | HECHO (abajo) |
| P3.2–3 — logo (burbuja + texto «BlueTalk») en `assets/brand/` o `CustomPainter` | PENDIENTE |
| P3.4 — ícono adaptive en `mipmap-*` (a mano, sin paquetes) | PENDIENTE |
| P3.5 — logo en `AppAvatar`/shell y onboarding | PENDIENTE |
| P3.6 — tokens de marca con AA | HECHO (abajo) |
| P3.7 — primer fotograma celeste (styles/launch) | HECHO (abajo) |
| P4 — 6 temas con contraste AA + selector + persistencia | PENDIENTE |
| Cierre + revisor | PENDIENTE |

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
| Anillo burbuja y texto «BlueTalk» | `#2E6492` (más oscuro `#306A98`, cuantizado `#2E6492`) | `primaryStrong` / `primaryStrongText` |
| Titulares navy («¡ESTAMOS…!», «Tu voz, siempre contigo») | `#002848` (dominante; más oscuro `#001635`) | `text` / `primaryInk` |
| Corazón verde | `#20A078` (dominantes `#20A078`/`#28A078`; más saturado `#24A97C`) | `verdeCorazon` (relleno/decoración) |
| Fondo celeste superior | `#70D0F8` (dominante) | `primary` (relleno) |
| Fondo celeste medio izquierda | `#88D0F0` | reserva / futuros acentos |
| Banda inferior pale | `#B4E0F8` | reserva |
| Azul vivo de formas (derecha) | `#0088D8` (dominante) | reserva / acentos P4 |
| Pantalla del móvil del cartel | blanco → degradado a `#B8D8F0` | `surface` (blanco) |

Se descarta «Innovation», la insignia «TOP 100 JUMP CHILE», el logo de
Jump, la mano y el teléfono (decisión D5 del plan 12: sin terceros).

## P3.6 — tokens con la paleta del cartel (commit 1)

`lib/core/theme/app_colors.dart` migrado con los hex de arriba. Ajuste
necesario y documentado: el `bg` es **tinte al 12 %** del celeste de
marca (`#70D0F8` diluido en blanco → `#EDF9FE`): el celeste fuerte del
cartel como fondo de pantalla entera deslumbraría (plan 00 §4). El
verde del corazón (`#20A078`, ~3.4:1 vs blanco) **no llega a AA como
texto**: queda como token `verdeCorazon` para relleno/decoración y el
texto sigue en navy/azul de marca. Colores semánticos (éxito/aviso/
error) no cambian: no son de marca.

Contrastes nuevos (mismos umbrales que `tokens_test.dart`):
`text`/`bg` 14.0:1 · `text`/`surface` 15.0:1 · `primaryInk`/`primary`
8.7:1 · `primaryStrong(Text)`/`bg` 5.8:1 · `primaryStrong(Text)`/
`surface` 6.3:1. **`tokens_test.dart` en verde sin tocar el test.**

## P3.7 — primer fotagrama sin destello blanco

`drawable/launch_background.xml` dejó de usar `@android:color/white` y
apunta a `@color/launch_background` (`#EDF9FE`, el `bg` de la app) en
`values/colors.xml`; `styles.xml` (LaunchTheme) coge ese drawable, así
que también `values-night` queda cubierto con el mismo celeste.

## NO VERIFICADO (hasta humo en emulador / teléfono real)

- Aspecto del ícono adaptive (recorte circular y cuadrado) — se verificará
  con captura de launcher en el cierre de la etapa.
- Primer fotograma real en dispositivo.
