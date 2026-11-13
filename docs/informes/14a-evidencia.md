# Evidencia 14A — Menú principal (2026-11-12)

Rama `feat/menu-guia`. Emulador `bluetalk_gama_baja` (API 28, 720×1280,
280 dpi, 1 GB de RAM), build de depuración con `flutter drive`.

## Commits

| Commit | Qué entrega | Pasos del plan |
|---|---|---|
| `2028288` | Ramas del shell en `router_ramas.dart` | A1.1 |
| `705092d` | Ruta `/inicio`, menú con carrusel animado y Atrás que vuelve al menú | A1.2–A1.6, A2 y A3 |
| `4d697a3` | Cambiar el nombre del niño o niña desde el Modo padre | A4 |
| `a12b665` | Los puntos del menú ya no se desbordan en horizontal | A2.8 |

A1, A2 y A3 quedaron en un solo commit (`705092d`), no en los tres que pedía
el plan. No se reescribe el historial para separarlos.

## Defecto encontrado en el emulador y corregido

**En horizontal, la columna de puntos se desbordaba 21 dp** («BOTTOM OVERFLOWED
BY 21 PIXELS»). Cinco puntos de 48 dp suman 240 dp, y girado el teléfono solo
quedan unos 219 dp entre las dos flechas. Encoger los puntos los dejaría por
debajo del objetivo táctil de 48 dp, así que ahora la columna se desplaza
cuando no cabe. En vertical se ve igual que antes.

- Test nuevo en `test/inicio/menu_test.dart` («en horizontal los puntos caben
  sin desbordar»): falla sin el arreglo y pasa con él.
- Comprobado de nuevo en el emulador girado: sin desbordes. El último punto
  queda medio cortado abajo, señal de que la columna se puede desplazar.

## Capturas

`integration_test/menu_capturas_test.dart`, con
`test_driver/capturas_driver.dart`:

| | Vertical | Horizontal |
|---|---|---|
| Claro | `capturas/14a-menu-claro.png` | `capturas/14a-menu-claro-horizontal.png` |
| Oscuro | `capturas/14a-menu-oscuro.png` | `capturas/14a-menu-oscuro-horizontal.png` |
| Calma | `capturas/14a-menu-calma.png` | `capturas/14a-menu-calma-horizontal.png` |

Para la versión horizontal se gira el emulador con
`adb shell settings put system user_rotation 1` y se pasa
`--dart-define=SUFIJO=-horizontal`.

## Tabla de Atrás (plan 14 §2)

En el emulador, el test llama a `handlePopRoute()`, que es lo mismo que
dispara el botón Atrás de Android.

| Dónde está | Esperado | Emulador | Test de widget |
|---|---|---|---|
| Lista de Aprender, Rutinas o Ajustes | Vuelve al menú | ✅ las tres | `router_test.dart` |
| Inicio de Comunicar | Vuelve al menú | ✅ | `router_test.dart` |
| Modo padre (condiciones o código) | Vuelve al menú | ✅ | `router_test.dart` |
| Dentro de un juego, una categoría o una vista de Rutinas | Vuelve a la lista | — | `router_test.dart` |
| Modo padre, en una pestaña distinta de Resumen | Vuelve a Resumen | — | tests de `test/padre/` |
| Menú | Sale de la app, salvo en el kiosko | — | `router_test.dart` |
| Durante la guía | Paso anterior | — | `test/guia/guia_test.dart` |

«Sale de la app» no se probó en el emulador porque cerraría el test.

## Aceptación

- Instalación limpia: nombre → menú. Segundo arranque: menú directo. ✅ en el
  emulador (`integration_test/guia_recorrido_test.dart`).
- Flechas, puntos y la tarjeta central que abre su sección: tests de widget
  en `test/inicio/menu_test.dart`.
- Cambiar el nombre se ve en el saludo: `test/padre/control_nombre_test.dart`.
- `flutter analyze` con 0 problemas y `flutter test` en verde (429/429).

## NO VERIFICADO

- Que el carrusel siga al dedo en un teléfono real. En el emulador sin ventana
  no se desliza con el dedo.
- TalkBack real. El menú en forma de lista solo está cubierto por un test de
  widget (`accessibleNavigation`).
- El botón Atrás físico del teléfono. En el emulador se usó `handlePopRoute()`.
