# P0-6 — Ficha de Play y assets (2026-11-08)

Rama `feat/modular-freemium-aws`. Base `21c798c` (P0-3 cerrado).

## Qué se hizo

`requisitosPlayStore.md` marca como **P0-6** la falta de icono de Play,
gráfico destacado, capturas y textos. Este módulo deja listos los assets de
marca y los textos; las capturas se hacen en el emulador y se revisan una a
una.

## Assets de marca

| Archivo | Tamaño | Formato | Peso |
|---|---|---|---|
| `docs/play/assets/icono-512.png` | 512×512 | PNG RGBA (alfa opaco) | 21 KB |
| `docs/play/assets/grafico-destacado-1024x500.png` | 1.024×500 | PNG RGB | 40 KB |

- El icono usa el **símbolo** del logo (burbuja, cara y corazón), no el
  wordmark, sobre fondo celeste de marca `#70D0F8`.
- El gráfico destacado lleva el símbolo, «BlueTalk» y la frase «Comunicar,
  un toque a la vez.»; el contenido importante queda dentro del tercio
  central para que no lo tape el botón de Play.
- Las fuentes SVG están en `docs/play/assets/fuente/` y se regeneran con
  `rsvg-convert`; el icono se pasa a RGBA con `ffmpeg` porque Play pide PNG
  de 32 bits. Los comandos exactos están en `docs/play/ficha.md`.

## Textos

Están en `docs/play/ficha.md`, listos para pegar:

| Campo | Longitud | Límite |
|---|---|---|
| Nombre | 8 | 30 |
| Descripción corta | 74 | 80 |
| Descripción completa | 2.175 | 4.000 |
| Novedades | 268 | 500 |

La descripción no menciona filtro web, monitoreo de uso ni VPN: esas
funciones dependen de P0-2 y no se prometen hasta que el dueño elija ruta.
Tampoco hay claims médicos: dice explícitamente que no diagnostica ni
sustituye a un profesional.

## Defectos encontrados al preparar las capturas

1. **«Preocupado» se partía a mitad de palabra** en el check-in emocional a
   720 px de ancho (`salud_screen.dart`). Se cambió la etiqueta por un
   `FittedBox` de una línea y se añadió una prueba a 320 px.
2. **Ajustes decía «La voz se activará en una próxima versión»**, aunque la
   voz ya funciona en el comunicador. Se cambió por «La voz suena solo
   cuando tocas un pictograma o una frase.»

## Capturas

Pendiente de completar tras la sesión de emulador.

## Verificación

Pendiente de completar.

## Pendiente del dueño

- Correo de contacto público y URL de la política (P0-5).
- Confirmar categoría «Educación» y si habrá vídeo.
- Decidir P0-2 antes de prometer o quitar el filtro web.
