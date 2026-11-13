# Evidencia 14B — Guía de primera vez con la mascota (2026-11-12)

Rama `feat/menu-guia`. Emulador `bluetalk_gama_baja` (API 28, 720×1280,
280 dpi, 1 GB de RAM), build de depuración con `flutter drive`.

## Commits

| Commit | Qué entrega | Pasos del plan |
|---|---|---|
| `ee178a5` | Los 11 PNG en `assets/mascota/` con nombres sin espacios | 1 |
| `32c026b` | Capa, fondo con hueco, pasos, controlador, globo, anclas, arranque automático, «Ver la guía otra vez» y «Saltar» | 2, 3, 4 (sin la prueba en el emulador) y 5 |
| `32f95a0` | El borde del hueco «respira» fuera del modo calma | 2 (§1, faltaba) |
| `3a3aece` | Test de integración: recorrido completo en el emulador | 4 |
| `439270e` | Test del texto del paso 11 cuando el código ya existe | 5 |
| este commit | Evidencia y capturas | 6 |

Los pasos 2, 3 y 5 quedaron en un solo commit (`32c026b`), no en los tres que
pedía el plan. No se reescribe el historial para separarlos.

## Lo que faltaba y se completó hoy

1. **El borde que respira** (§1: opacidad de 0,6 a 1, 1,2 s, en bucle) no
   estaba implementado. Ahora lo pinta `GuiaFondoQueRespira`, en
   `guia_fondo.dart`. Con el modo calma o «Quitar animaciones» se queda fijo
   y no pide fotogramas. Test: «el borde respira y se queda quieto sin
   animaciones».
   - Efecto en los tests: un bucle infinito no deja terminar `pumpAndSettle`.
     Los tests que abren la app con la guía (`guia_test.dart` y
     `accessibility_test.dart`) apagan las animaciones del sistema con
     `FakeAccessibilityFeatures(disableAnimations: true)`. Lo que comprueban
     no cambia.
2. **La prueba en el emulador del paso 4** no existía. Ahora existe
   `integration_test/guia_recorrido_test.dart`.
3. **El texto alternativo del paso 11** («Aquí entras con tu código…») no
   tenía test.
4. La nota sobre «SECURE» del candado (§2) y la pregunta sobre la carpeta
   `mascota/` están en `decisiones-pendientes.md`.

## Recorrido en el emulador

`integration_test/guia_recorrido_test.dart`, con
`test_driver/capturas_driver.dart`. Las preferencias empiezan vacías, en
memoria, como en una instalación limpia:

1. Nombre «Sol» → «Comenzar» → menú, con la guía en el paso 1.
2. Los 11 pasos con «Siguiente»; en cada uno se comprueba «Paso n de 11».
3. «Ir al Modo padre» → `guia_vista = true` → condiciones.
4. Se aceptan las condiciones, se crea el código y se confirma → Resumen.
5. Segundo arranque con las mismas preferencias: menú sin guía.
6. Con el modo calma activo: los 11 pasos otra vez.

Resultado: **All tests passed**.

## Capturas

En `docs/informes/capturas/`:

- `14b-paso-01.png` … `14b-paso-11.png`: cada paso, en claro.
- `14b-calma-01.png` … `14b-calma-11.png`: cada paso, con el modo calma.
- `14b-condiciones.png` y `14b-resumen.png`: el final del recorrido.

Las capturas se tomaron con «Quitar animaciones» simulado, porque si no
`pumpAndSettle` no termina por el borde que respira. Una captura es una foto
fija, así que se ven igual que con las animaciones encendidas.

Revisadas a ojo: el hueco cae sobre el elemento de cada paso, la mascota
cambia de postura, ninguna imagen sale volteada y en calma todo pasa a grises.

## Aceptación

| Criterio | Estado |
|---|---|
| Instalación limpia: nombre → menú → 11 pasos → condiciones → código → Resumen | ✅ emulador |
| El hueco coincide con su elemento en vertical | ✅ emulador y `guia_test.dart` |
| El hueco en horizontal y en una pantalla de 320 dp | **NO VERIFICADO** (sin test ni captura) |
| El fondo no deja tocar nada | ✅ `guia_test.dart` |
| «Atrás» y el botón Atrás de Android retroceden un paso; en el paso 1 no hacen nada | ✅ `guia_test.dart` (`handlePopRoute`) |
| Con el modo calma nada se mueve | ✅ tests de la mascota y del borde |
| Ninguna imagen con «BlueTalk» aparece volteada | ✅ no hay volteo en el código; capturas |
| `flutter analyze` con 0 problemas y `flutter test` en verde | ✅ 429/429 |

## Diferencias con el plan

- **Tamaño de la mascota:** 108 dp (84 dp en pantallas de menos de 360 dp),
  no 120 y 96 dp. Así cabe junto al texto dentro del globo.
- **Paso 10:** se ilumina toda la barra superior, no solo los botones Inicio
  y modo calma. El borde del hueco queda fuera de la pantalla por arriba.
- **«Saltar»** pide confirmación dentro del mismo globo, con la postura del
  candado, en vez de abrir un diálogo aparte.

## NO VERIFICADO

- TalkBack real. El globo es `Semantics(liveRegion: true)`, pero que lea
  cada paso solo se puede comprobar en un teléfono.
- El hueco con el teléfono girado y en una pantalla de 320 dp.
- Matar la app a mitad de la guía y reabrirla (plan 14 §5.2). Por el código
  debería empezar en el paso 1, porque `guia_vista` solo se guarda al
  terminar o saltar, pero no se probó en el emulador.
