# Rendimiento — inicio y guía

Archivos: `lib/features/inicio/`, `lib/features/guia/`. Es la primera
pantalla y la que más se ve; también donde la guía anima sobre toda la app.

## PERF-INI-01 · La guía se agenda en cada rebuild del inicio (P1)

**Dónde** `lib/features/inicio/inicio_screen.dart:27`.

```dart
WidgetsBinding.instance.addPostFrameCallback(
  (_) => ref.read(guiaProvider.notifier).iniciarSiFalta(),
);
```

Está en `build`, así que cada reconstrucción de `InicioScreen` (cambio de
modo calma, de perfil, cierre de la guía, rotación) agenda un callback extra.
`iniciarSiFalta` es idempotente, pero el callback y la lectura del provider
se repiten sin necesidad.

**Arreglo pequeño**
Convertir `InicioScreen` en `ConsumerStatefulWidget` y llamar a
`iniciarSiFalta()` una sola vez en `initState` (o en un provider que se
ejecute al construir el router). También vale un `bool _agendado` en el
estado.

**Riesgo** bajo.

---

## PERF-INI-02 · La guía recompone un path de pantalla completa por frame (P1)

**Dónde** `lib/features/guia/guia_fondo.dart:27`.

`GuiaFondo` recibe `repaint: brillo`, una animación que respira en bucle. En
cada tick, `paint` hace:

```dart
Path.combine(PathOperation.difference, pantalla, hueco)
```

sobre el rectángulo de toda la pantalla. `Path.combine` es una operación
geométrica costosa y se repite aunque el hueco no cambie; el brillo solo
afecta al borde.

**Arreglo pequeño**
Construir el fondo con **relleno par-impar**, sin combinar paths:

```dart
final fondo = Path()
  ..fillType = PathFillType.evenOdd
  ..addRect(Offset.zero & size)
  ..addRRect(_forma!);
canvas.drawPath(fondo, Paint()..color = gris);
```

O cachear el path y recalcularlo solo si cambia `hueco`. Cualquiera de las dos
elimina la operación cara de cada fotograma.

**Cómo comprobarlo**
Abrir la guía en perfil y mirar el coste de “raster” mientras respira el
borde; comparar antes/después.

**Riesgo** bajo: mismo dibujo, otra forma de construirlo.

---

## PERF-INI-03 · `Opacity` por tarjeta en cada tick del carrusel (P2)

**Dónde** `menu_tarjeta.dart`.

Cada tarjeta aplica `Transform.scale` + `Opacity` con un valor entre 0 y 1.
`Opacity` crea una capa de composición por tarjeta y frame. Con 3–5 tarjetas
visibles no debería doler, pero en gama baja el carrusel es la primera
impresión.

**Arreglo posible (solo si se mide jank)**
- Pintar el fondo y los textos con el alfa ya aplicado en el color, en vez de
  envolver todo en `Opacity`. Los SVG necesitan su propio tratamiento.
- O usar `FadeTransition` sobre un `RepaintBoundary` por tarjeta.

No tocar sin perfil: la animación actual cumple el plan 14A y el usuario la
quiere conservar.

---

## PERF-INI-04 · El carrusel reconstruye cada página en cada scroll (P2)

**Dónde** `menu_pagina.dart`: `AnimatedBuilder(animation: pagina)` envuelve
cada tarjeta y vuelve a construir `FittedBox` + `LayoutBuilder` en cada tick.

Con 5 opciones el coste es bajo y el resultado es suave en el emulador. Si se
quisiera afinar: mover el cálculo de `distancia` a un `ValueListenable` y
aplicar solo `Transform`/`Opacity`, sin reconstruir el subárbol de texto.

**Riesgo** medio; no hacerlo sin necesidad.

---

## PERF-INI-05 · Geometría adaptativa: recrea el `PageController` al girar (correcto)

`menu_geometria.dart` crea un controlador nuevo cuando cambia la fracción
(rotación o tamaño de texto) y libera el anterior al terminar el frame. Es
deliberado y ocurre pocas veces; no es un problema de rendimiento. El hueco
medido en el emulador quedó en ~34 dp (antes ~66 dp), con las animaciones de
escala, fundido y arrastre intactas.

La captura está en `docs/informes/capturas/14a-menu-espaciado.png` y la
horizontal en `...-horizontal.png`.

---

## PERF-INI-06 · Medidor de la guía: ticker de 0,5 s por paso (correcto)

`guia_medidor.dart` corre un `Ticker` mientras el objetivo se mueve y lo para
tras 30 frames estables. `rectDe` usa un `GlobalKey`, no recorre el árbol.
Solo hay que vigilar que no se reinicie en bucle al cambiar de paso; hoy
`volverAMedir` se llama al cambiar de paso y al girar.

---

## Lo que ya está bien

- La guía se monta una vez en `MaterialApp.router(builder:)` y no reconstruye
  el router al abrirse/cerrarse (`guia_capa.dart`).
- El fondo absorbe los toques y deja interactuar solo con el globo; no hay
  `ModalBarrier` que repinte toda la app.
- Con modo calma o “quitar animaciones”, el borde no respira y las tarjetas
  no escalan.
- El menú conserva la posición central en un provider `autoDispose`, así que
  volver al inicio no reconstruye el carrusel desde cero.
- `InicioLista` da una alternativa accesible sin animaciones para TalkBack.

## Prueba manual sugerida

1. Abrir y cerrar la guía dos veces; no debe quedar un callback pendiente ni
   sonar/animarse nada de más.
2. Con la guía abierta, mirar el perfil: el coste de raster no debe crecer
   con el tamaño de la pantalla tras el arreglo del path.
3. Deslizar el menú de arriba abajo y comprobar que las tarjetas lejanas se
   apagan y el centro escala sin saltos.
