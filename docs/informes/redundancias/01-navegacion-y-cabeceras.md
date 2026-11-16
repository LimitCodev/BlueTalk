# Redundancias — navegación y cabeceras

## R-01 · Siete copias de la cabecera “Volver” (P1, S)

**Dónde**
1. `lib/features/rutinas/cabecera_vista.dart` — `CabeceraVista`
   (la usan horario, colegio y editor; es la más completa).
2. `lib/features/comunicador/comunicador_encabezados.dart` — `CategoryHeader`.
3. El mismo archivo — `MessagesHeader`.
4. `lib/features/rutinas/estadisticas_view.dart:36` — cabecera inline.
5. `lib/features/salud/salud_screen.dart:55` — `_CabeceraSalud`.
6. `lib/features/juegos/cabecera_juego.dart` — `CabeceraJuego`.
7. `lib/features/juegos/cuentos/cuentos_cabecera.dart` — `CabeceraCuentos`.

Las siete son el mismo `Row`: `OutlinedButton.icon` de 48 dp con
`chevron_left`, “Volver”, un `SizedBox(width: 12)` y un `Text` con
`titleMedium`, `maxLines: 1` y ellipsis.

**Por qué importa**
No es solo duplicación: cualquier cambio de tamaño táctil, contraste o texto
hay que hacerlo siete veces y es fácil que una quede distinta. Ya pasa: el
título de `_CabeceraSalud` está escrito a mano y las demás lo reciben.

**Fix pequeño**
Crear `lib/core/widgets/cabecera_volver.dart`:

```dart
class CabeceraVolver extends StatelessWidget {
  const CabeceraVolver({super.key, required this.titulo, this.onVolver});
  final String titulo;
  final VoidCallback? onVolver;
  // ... el Row actual, con el botón de 48 dp.
}
```

Sustituir las siete. En `CabeceraVista` se puede conservar el nombre como
alias o reemplazar los usos. `onVolver` nulo significa volver al inicio de
Rutinas; cada pantalla pasa su acción.

**Riesgo** bajo. Test de widget: una pantalla con la cabecera sigue teniendo
un botón de al menos 48×48 y el título visible.

---

## R-02 · “Salir del modo padre” aparece dos veces en Legal (P1, S)

**Dónde**
- `lib/features/padre/padre_screen.dart:138`: `IconButton` con X en el
  `AppBar`, tooltip “Salir del modo padre”, siempre visible.
- `lib/features/padre/legal/legal_screen.dart:153`: `TextButton` “Salir del
  modo padre” al final de la pantalla.

**Qué pasa**
La pantalla Legal se muestra como cuerpo dentro del `Scaffold` del padre, así
que el adulto ve la X y el botón de texto a la vez. Ambos llaman a `_salir`.
Antes existía además un candado en la cabecera que solo volvía al PIN; se
quitó por confuso (comentario en `padre_screen.dart:132`). Este es el mismo
tipo de duplicado.

**Fix pequeño**
Dejar una sola salida:
- Recomendado: quitar el `TextButton` de Legal y confiar en la X (siempre
  visible, con tooltip y semántica).
- Si se quiere mantener el botón como acción principal al final del
  documento, ocultar la X solo en la pestaña Legal.

No dejar ambos.

**Riesgo** bajo. Comprobar que se puede salir antes de aceptar la legal
(“No acepto” sigue estando) y después (X).

---

## R-03 · El Atrás del sistema y el “Volver” del cuento no hacen lo mismo (P1, S)

**Dónde**
- `lib/app/atras_shell.dart:31`:

```dart
if (index == 1 && ref.read(juegosProvider) != JuegoVista.inicio) {
  ref.read(juegosProvider.notifier).irAlInicio();
  return;
}
```

- `lib/features/juegos/cuentos/cuentos_cabecera.dart:27`:
  `cuentosProvider.notifier.irALista()`.

**Qué pasa**
Si el niño está leyendo un cuento:
- toca “Volver” → vuelve a la **lista de cuentos**;
- pulsa Atrás del sistema → vuelve al **inicio de Aprender**, saltándose la
  lista.

Dos controles para “atrás” con resultados distintos. Es el hallazgo más
importante de esta auditoría porque puede desorientar y porque el plan 13 P1
pide un Atrás predecible.

**Fix pequeño**
En `manejarAtras`, antes de `irAlInicio()`:

```dart
if (index == 1 && ref.read(juegosProvider) == JuegoVista.cuentos) {
  final cuentos = ref.read(cuentosProvider);
  if (cuentos.storyId != null) {
    ref.read(cuentosProvider.notifier).irALista();
    return;
  }
}
```

Añadir el import de `cuentos_controller.dart`. Es una excepción concreta; si
aparecen más subvistas de juego, conviene una interfaz `JuegoConAtras` o un
provider `juegoAtrasProvider` que cada juego registre.

**Test**
Widget test: abrir un cuento, pulsar Atrás y comprobar que se ve la lista
(`find.text('Cuentos')` o el título de la lista), no el inicio de juegos.

**Riesgo** bajo.

---

## R-11 · Inicio del shell + Atrás del sistema (verificado, no tocar)

`AppBar` del shell tiene una casita que va a `/inicio`; el Atrás del sistema
también va a `/inicio` desde cualquier pestaña. Son dos controles para lo
mismo, pero el plan 14 §2 los pide: la casita es visible y el Atrás es una
tabla fija. No es una redundancia accidental. Se conserva.

Lo que sí conviene vigilar: desde una categoría del comunicador, la casita va
al menú y “Volver” va al inicio del comunicador. Son destinos distintos y
correctos; no unificarlos.

---

## R-12 · X del padre + Atrás del sistema (verificado, no tocar)

`padre_screen.dart:111` intercepta Atrás y llama a `_salir` desde el panel.
La X hace lo mismo. Es deliberado: el adulto puede salir con el gesto del
sistema o con el botón visible. El código ya documenta que el candado
anterior se quitó por confuso. No volver a añadir un tercer control.

---

## R-13 · Guía: “Saltar” y “Ver la guía otra vez” (verificado, no tocar)

- `GuiaCabecera` muestra “Saltar” y `GuiaBotones` muestra “Seguir/Saltar” en
  la confirmación. Nunca se ven dos “Saltar” a la vez: al confirmar, la
  cabecera oculta el suyo (`conSaltar: !confirmarSalto`).
- `RepetirGuiaTile` es la única entrada para repetir la guía; el inicio solo
  la arranca una vez (`iniciarSiFalta`). No hay duplicado.

---

## R-14 · Cabecera del editor y del colegio (correcto)

`EditorHorarioView` y `EntornoScreen` reutilizan `CabeceraVista` con
`onVolver` distinto (pop del diálogo vs inicio de rutinas). Es el uso
correcto de una cabecera compartida; cuando se extraiga R-01, conservar esa
posibilidad.

---

## Resumen de acciones

| Acción | Archivos | Riesgo |
|---|---|---|
| Extraer `CabeceraVolver` y reemplazar 7 copias | `core/widgets/`, 6 archivos | bajo |
| Quitar el botón de salir de Legal (o la X en Legal) | `legal_screen.dart` / `padre_screen.dart` | bajo |
| Hacer que Atrás cierre el cuento antes de salir de juegos | `atras_shell.dart` (+ import) | bajo |
| No tocar casita/Atrás, X/Atrás, guía | — | — |
