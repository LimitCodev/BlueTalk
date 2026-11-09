# Ficha de Google Play — BlueTalk

Estado: **textos y assets de marca listos**; capturas pendientes. No se puede
publicar hasta resolver P0-1 (AAB firmado), P0-5 (identidad, correo y URL
pública) y P0-8 (cuenta y testers).

Los textos están en español, sin claims médicos y describen la edición Play
(ruta A: sin filtro web ni monitoreo de uso). Se pueden pegar tal cual en Play
Console cuando el dueño confirme el correo y la URL de privacidad.

## Campos de la ficha

| Campo | Límite | Estado |
|---|---|---|
| Nombre | 30 caracteres | Listo: `BlueTalk` (8) |
| Descripción corta | 80 caracteres | Lista (74) |
| Descripción completa | 4.000 caracteres | Lista (2.175) |
| Novedades | 500 caracteres | Listas (268) |
| Icono | 512×512 PNG | Listo |
| Gráfico destacado | 1.024×500 PNG | Listo |
| Capturas de teléfono | 2–8, 16:9 o 9:16 | Pendientes |
| Capturas de tablet | 2–4 recomendadas | Pendientes |
| Vídeo | 30–120 s, opcional | No se hará por ahora |

Categoría sugerida: **Educación**. Público objetivo y clasificación se
declaran en P0-7, no en la ficha.

## Descripción corta (74/80)

```text
Comunicador AAC sin conexión: pictogramas, frases, rutinas y voz al tocar.
```

## Descripción completa

```text
BlueTalk es un comunicador aumentativo y alternativo (CAA) en español, pensado para niñas y niños que necesitan apoyo para comunicarse, y para las familias, docentes y terapeutas que los acompañan.

Funciona sin conexión, sin cuentas y sin anuncios. El apodo, los favoritos y el progreso se guardan solo en este teléfono.

QUÉ PUEDES HACER
• Comunicar con pictogramas organizados por categorías.
• Construir frases en la barra inferior y oírlas solo al tocar.
• Guardar mensajes y favoritos para usarlos cuando hagan falta.
• Seguir rutinas y un horario visual, con recordatorios opcionales.
• Jugar a memoria, leer cuentos cortos y dibujar.
• Registrar cómo se siente el niño o la niña con un check-in sencillo.
• Activar el modo calma: colores suaves y sin animaciones.
• Ajustar el tamaño del texto, la voz y el tema.
• Abrir el panel del adulto con PIN para configurar la app.

QUÉ NO ES
BlueTalk no diagnostica, no trata y no sustituye a un logopeda, terapeuta ocupacional, docente o profesional sanitario. Las observaciones y los informes son orientativos y se calculan con reglas sobre datos locales; no son un diagnóstico clínico.

PRIVACIDAD
• Sin cuentas, sin anuncios y sin analítica.
• Sin conexión a internet para usar el comunicador.
• Los datos del menor se quedan en el dispositivo.
• La voz es la del sistema Android y solo suena cuando se toca un pictograma o una frase.
Puedes leer la política de privacidad completa en [URL pendiente].

ACCESIBILIDAD
• Objetivos táctiles grandes (mínimo 48 dp).
• Contraste AA y modo calma.
• Vocabulario nuclear siempre en la misma posición.
• Navegación fija y predecible, sin sonidos automáticos.

REQUISITOS
Android 7.0 o superior. Funciona en teléfono y tablet. Para la voz hace falta que el sistema tenga instalada una voz en español; si no, la app avisa y el comunicador sigue funcionando sin sonido.

CÓMO EMPEZAR
1. Instala la app y escribe un apodo (o entra sin apodo).
2. Elige una categoría y toca los pictogramas para formar una frase.
3. Toca la frase para oírla.
4. El adulto puede abrir el panel con su PIN para configurar rutinas, permisos y ajustes.

BlueTalk no pide cuentas ni conexión para comunicar.
```

## Novedades (primera versión)

```text
Primera versión de prueba: comunicador con pictogramas y barra de frase, voz en español al tocar, rutinas y horario visual, juegos, check-in emocional, modo calma y panel del adulto con PIN. Sin cuentas, sin anuncios y sin conexión; los datos se quedan en el teléfono.
```

## Assets de marca

| Archivo | Tamaño | Peso | Comprobación |
|---|---|---|---|
| `docs/play/assets/icono-512.png` | 512×512 | 21 KB | PNG RGBA (alfa opaco), fondo celeste de marca |
| `docs/play/assets/grafico-destacado-1024x500.png` | 1.024×500 | 40 KB | PNG RGB, símbolo, nombre y frase corta |

Las fuentes vectoriales están en `docs/play/assets/fuente/`. Se regeneran con:

```bash
rsvg-convert -w 512 -h 512 \
  -o /tmp/icono-512.png \
  docs/play/assets/fuente/icono-512.svg
# Play pide PNG de 32 bits: se añade alfa opaco.
ffmpeg -y -loglevel error -i /tmp/icono-512.png -pix_fmt rgba \
  -frames:v 1 docs/play/assets/icono-512.png
rsvg-convert -w 1024 -h 500 \
  -o docs/play/assets/grafico-destacado-1024x500.png \
  docs/play/assets/fuente/grafico-destacado-1024x500.svg
```

El icono usa el símbolo (burbuja, cara y corazón), no el wordmark, y tiene
fondo sólido. El gráfico destacado no tapa el texto con el botón de Play: el
contenido importante queda dentro del tercio central.

## Capturas que faltan

Orden recomendado para las 8 de teléfono (9:16, mínimo 320 px de lado,
máximo 3.840 px):

1. **Comunicador**: cuadrícula de categorías y pictogramas.
2. **Barra de frase**: una frase construida y el botón de oír.
3. **Rutinas**: horario visual del día.
4. **Aprender**: memoria o cuentos.
5. **Salud**: check-in emocional.
6. **Modo calma**: la misma pantalla en grises, sin animaciones.
7. **Ajustes**: tamaño de texto, voz y tema.
8. **Panel del adulto**: PIN o resumen, sin datos personales.

Para tablet (2–4, 16:9 o 9:16): comunicador, rutinas y panel del adulto.

Antes de subirlas:

- [ ] Ninguna captura muestra el apodo real, nombres, caras de niños ni
      notificaciones personales.
- [ ] La barra de estado no enseña números de teléfono, correo ni batería
      con datos identificables.
- [ ] El modo calma se ve realmente en grises.
- [ ] Las capturas son de la versión con P0-3 y P0-4 aplicados.
- [ ] No hay texto de prueba tipo «Lorem ipsum» ni datos de demo con nombres
      reales.

## Pendiente del dueño

- Correo de contacto público para la ficha (P0-5).
- URL pública de la política de privacidad (P0-5).
- Confirmar categoría «Educación» y si habrá vídeo.
