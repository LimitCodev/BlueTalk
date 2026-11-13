import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/comunicador/comunicador_controller.dart';
import '../features/juegos/juegos_controller.dart';
import '../features/rutinas/rutinas_controller.dart';

/// Si el botón Atrás puede salir de la app desde Comunicar (fila 3 del
/// plan 13 P1).
///
/// `true` por defecto. El plan 12 (modo niño/kiosko) lo pondrá en `false`
/// para que el niño no pueda salir de BlueTalk con el botón Atrás
/// (plan 13 P1, gancho «saleConAtras»).
final saleConAtrasProvider = Provider<bool>((ref) => true);

/// Botón Atrás del shell (plan 13 P1): siempre se mueve a un sitio de la
/// tabla del plan. El único punto de salida es el inicio de Comunicar.
void manejarAtras(WidgetRef ref, StatefulNavigationShell shell) {
  final index = shell.currentIndex;
  // Fila 1: dentro de un juego, el Atrás vuelve a la lista de Aprender
  // (y cierra la sesión de juego con su duración, plan 03 §6).
  if (index == 1 && ref.read(juegosProvider) != JuegoVista.inicio) {
    ref.read(juegosProvider.notifier).irAlInicio();
    return;
  }
  // Una vista de Rutinas (Mi horario, Mi día…) es interna: como el botón Volver.
  if (index == 2 && ref.read(rutinasProvider) != RutinaVista.inicio) {
    ref.read(rutinasProvider.notifier).irAlInicio();
    return;
  }
  // Fila 2: de Aprender, Rutinas o Ajustes, el Atrás va a Comunicar.
  if (index != 0) {
    shell.goBranch(0);
    return;
  }
  // Una categoría o Mis mensajes son vistas internas: como el botón Volver.
  final vista = ref.read(comunicadorProvider);
  if (vista.categoryId != null || vista.showMessages) {
    ref.read(comunicadorProvider.notifier).goHome();
    return;
  }
  // Fila 3: en Comunicar el Atrás sale de la app… salvo en kiosko.
  if (ref.read(saleConAtrasProvider)) {
    SystemNavigator.pop();
  }
}
