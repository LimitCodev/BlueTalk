# Etapa C — evidencia (plan 11 §2.1, 2026-11-08)

Rama `feat/modular-freemium-aws`. Solo se cerró §2.1 (vocabulario y tablero
nuclear). Primero–Luego (§2.2), fotos propias (§2.3) y copia de seguridad
(§2.4) siguen sin hacer.

## Qué cambió

- De 42 a **239 pictogramas**: 71 en el tablero «Palabras básicas» y 126 nuevos
  en las 7 categorías temáticas. Los ids anteriores no cambian, así que
  favoritos y frases guardadas siguen funcionando.
- `Pictogram.order` y `clase`; `Category.tipo` y `nuclear`, con valores por
  defecto que no rompen seeds anteriores.
- El tablero se ordena solo por `order`. Colores por clase gramatical con tonos
  ya validados en AA (`lib/core/theme/colores_gramatica.dart`).
- El perfil de edad nunca oculta el tablero nuclear.
- Memoria y Cuentos no usan el tablero nuclear.
- El buscador enseña una sola vez las palabras repetidas en dos categorías.
- Créditos corregidos: la licencia de Mulberry nombra a Steve Lee como titular.

## Origen de los símbolos

- Mulberry 3.6.1 (`research_notes/datos-publicos/mulberry-symbols.zip`, CC BY-SA
  4.0), solo símbolos con `rated=0`.
- Cambios técnicos, declarados en Créditos: los bloques `<style>` pasan a
  atributos porque `flutter_svg` ignora el CSS, y siete archivos grandes se
  redondean a un decimal.
- **14 iconos propios** (`propio_*.svg`) para palabras que Mulberry no tiene: Sí,
  No, Yo, Tú, Él, Ella, Nosotros, Me gusta, Parar, Por favor, Gracias, Adiós,
  Aquí y Allí.
- Revisión visual en hoja de contacto. Se corrigieron tres errores de traducción
  del inglés: Avión era un cepillo de carpintero (`plane`), Luz una balanza
  (`light`) y Maestra un hombre.

## Verificado

- `flutter analyze`: sin problemas.
- `flutter test`: 388 pasan, 1 falla. La falla es `tamano_test`, por
  `memoria_screen.dart` y `salud_screen.dart`, cambios sin commit de P0-6 que no
  forman parte de esta etapa.
- `test/data/seed_integrity_test.dart`: ids, assets, presupuesto, lectura de
  todos los SVG con `flutter_svg`, orden nuclear sin huecos y posiciones fijas.
- `assets/pictos`: 2,1 MB (límite 3 MB).

## Desviación del plan

El plan pide SVG de 20 KB como máximo. El test permite 32 KB porque `eat`,
`play`, `family` (ya existentes), abuelos, tíos, `salad` y `drive` no bajan sin
perder detalle.

## NO VERIFICADO

- Tablero en emulador o teléfono: no se compiló porque había otro Gradle activo
  en la máquina compartida. Tampoco se midió el desplazamiento.
- Los iconos propios y las etiquetas no los ha revisado un terapeuta ni una
  familia.
- Revisión del `revisor` de esta etapa: pendiente.
