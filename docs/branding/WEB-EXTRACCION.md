# Extracción del diseño oficial — https://bluetalk.lovable.app/

Fecha: 2026-10-21. Descarga **una sola vez** con `curl -s -L`. Todo lo de esta
carpeta salió del sitio; no se ha inventado ningún valor.

| Archivo | Origen | HTTP |
|---|---|---|
| `index.html` | `https://bluetalk.lovable.app/` | 200 · 12 014 B |
| `index.css` | `https://bluetalk.lovable.app/assets/index-7L25lExW.css` | 200 · 74 174 B |
| `og-preview.png` | `og:image` (R2 de Lovable) | 200 · 95 007 B · 1920×1080 |

## 1. Qué NO se pudo extraer (no inventado)

- **No hay favicon, ni `<link rel="icon">`, ni `apple-touch-icon`.**
- **No hay ningún `<img>` ni `<svg>` en el HTML.** El `<head>` solo lleva
  `og:type`, `og:image`, `og:title`, `twitter:*` y `author: Lovable`.
- **No hay archivo de logo.** El único original disponible es el logo
  circular de ~40 px de diámetro **dentro** de la captura `og-preview.png`
  (arriba a la izquierda, sobre la barra azul). A esa resolución no se puede
  regenerar un ícono adaptativo fiel: se pixela al escalar.
- **La web no carga la tipografía que declara.** El CSS pone
  `font-family: Nunito, sans-serif`, pero **no hay `@font-face` (0 en el
  archivo) ni enlace a Google Fonts**. Nunito es la intención de diseño; el
  sitio la dibuja solo si el visitante la tiene instalada. La app sí
  empaqueta Nunito (`assets/fonts/Nunito-Variable.ttf`), así que es más fiel
  al diseño que el propio sitio.
- **El sitio no tiene barra lateral** en la captura publicada; las variables
  `--sidebar-*` existen en el CSS por la plantilla base, pero no se usan en
  la página capturada. No se copian.
- **No hay modo oscuro visible en la captura**, pero **sí en el CSS**
  (`.dark{...}` completo). Ver §2.

## 2. Paleta exacta (variables CSS del sitio)

Valores tal cual aparecen en `index.css` y su conversión HSL→HEX, que es lo
que usa la app.

### Modo claro (`:root`)

| Variable CSS | Valor del sitio | HEX |
|---|---|---|
| `--background` | `210 30% 97%` | `#F5F7FA` |
| `--foreground` | `215 25% 20%` | `#263140` |
| `--card` | `0 0% 100%` | `#FFFFFF` |
| `--primary` | `207 80% 52%` | `#238EE7` |
| `--primary-foreground` | `0 0% 100%` | `#FFFFFF` |
| `--secondary` | `210 30% 93%` | `#E8EDF3` |
| `--muted` | `210 20% 94%` | `#EDF0F3` |
| `--muted-foreground` | `215 15% 50%` | `#6C7C93` |
| `--accent` | `170 55% 48%` | `#37BEA7` |
| `--destructive` | `0 72% 58%` | `#E14747` |
| `--border` | `210 20% 88%` | `#DAE0E7` |
| `--input` | `210 20% 88%` | `#DAE0E7` |
| `--ring` | `207 80% 52%` | `#238EE7` |
| `--message-bar` | `207 60% 96%` | `#EFF5FB` |
| `--message-bar-foreground` | `215 25% 20%` | `#263140` |

La barra de mensaje de la web no es un color plano: es
`linear-gradient(135deg, hsl(var(--message-bar)), hsl(var(--card)))`.

### Modo oscuro (`.dark`)

El sitio **sí** tiene modo oscuro, así que la app debe tenerlo (§2.3 del
encargo).

| Variable CSS | Valor del sitio | HEX |
|---|---|---|
| `--background` | `215 25% 12%` | `#171D26` |
| `--foreground` | `210 20% 92%` | `#E7EBEF` |
| `--card` | `215 25% 16%` | `#1F2733` |
| `--primary` | `207 80% 55%` | `#3095E8` |
| `--secondary` | `215 20% 22%` | `#2D3643` |
| `--muted` | `215 20% 20%` | `#29313D` |
| `--muted-foreground` | `215 15% 60%` | `#8A96A8` |
| `--accent` | `170 55% 48%` | `#37BEA7` |
| `--destructive` | `0 62.8% 30.6%` | `#7F1D1D` |
| `--border` | `215 20% 22%` | `#2D3643` |
| `--message-bar` | `215 25% 18%` | `#242C39` |

### Categorías del comunicador (`--cat-*`)

| Variable CSS | HEX | Categoría en la web | Categoría en la app |
|---|---|---|---|
| `--cat-emotions` | `#DB5783` | Emociones | `emociones` |
| `--cat-food` | `#E88630` | Comida | `comida` |
| `--cat-activities` | `#39AC69` | Actividades | `acciones` |
| `--cat-needs` | `#238EE7` | Necesidades | `necesidades`, `objetos`* |
| `--cat-places` | `#9966CC` | Lugares | `lugares` |
| `--cat-people` | `#DD643C` | Personas | `personas`, `familia`* |
| `--cat-animals` | `#DFAF20` | Animales | `animales` |

\* `objetos` y `familia` no existen en la web con ese nombre; se les asigna la
categoría más próxima (`Necesidades` y `Personas`). `clima` **no tiene
equivalente en la web**: conserva su color propio y se documenta como
decisión, no como extracción.

La web pinta el icono y el borde con el color saturado de la categoría y el
relleno con ese mismo color en alpha bajo. Regla exacta del CSS:

```css
border-color:      hsl(var(--cat-emotions) / .3);
background-color:  hsl(var(--cat-emotions) / .1);
color:             hsl(var(--cat-emotions));
```

La app hace lo mismo, pero oscurece la **tinta** del texto hasta pasar AA
(≥4,5:1): `#DB5783` sobre blanco da 3,5:1 y no sirve para texto.

## 3. Tipografía

| Aspecto | Valor del sitio |
|---|---|
| Familia | `Nunito, sans-serif` (declarada; el archivo no se sirve) |
| Pesos usados en el CSS | 400, 500, 600, 700, 800, 900 |
| Monoespaciada (código) | `ui-monospace, SFMono-Regular, Menlo, …` |

La app empaqueta `Nunito-Variable.ttf` y declara 400/600/700/800. Faltan 500
y 900: no se usan en la captura publicada, así que no se declaran.

## 4. Radios, sombras y espaciado

| Aspecto | Valor del sitio |
|---|---|
| `--radius` | `1rem` (16 px) |
| Radio de botón | `calc(var(--radius) - 4px)` = 12 px |
| Radio de input | `calc(var(--radius) - 2px)` = 14 px |
| Píldoras (categorías) | `border-radius: 9999px` |
| Tarjetas de pictograma | `1rem` con borde fino del color de categoría |
| Sombras | La app usa `elevation: 0` + borde; la web también: en la captura las tarjetas se separan por **borde**, no por sombra |

## 5. Correspondencia con la app (estado 2026-10-21)

| Elemento de la web | En la app | Estado |
|---|---|---|
| `--background` claro | `AppColors.celeste.bg = 0xFFF4F7FA` | Casi idéntico (`#F5F7FA`; difiere en 1/255 por redondeo) |
| `--primary` `#238EE7` | `AppColors.celeste.header = 0xFF238EE7` | Idéntico, pero usado como **barra superior** |
| `--primary` como botón | `AppColors.celeste.primary = 0xFF1574C1` | **Desviación deliberada y documentada**: `#238EE7` con texto blanco da 2,9:1 y **no pasa AA**. Se oscurece para el relleno de acción. |
| `--border` `#DAE0E7` | `AppColors.borde = 0xFFDCE3EA` | Casi idéntico (2/255) |
| `--foreground` `#263140` | `AppColors.navy = 0xFF263442` | Casi idéntico (4/255) |
| `--accent` `#37BEA7` | `Marca.verde = 0xFF2FBFA3` | Difiere: es el verde del corazón del **logo**, no el teal de la web. No se cambia sin confirmación. |
| Modo oscuro `.dark` | — | **No existía**. Se añade en esta fase. |
| Píldoras de categoría redondas | pastillas de la rejilla | Hecho |
| Tarjeta de pictograma con borde de categoría | `picto_tile.dart` | Hecho |
