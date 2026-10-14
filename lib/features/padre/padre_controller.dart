import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'gate/gate_controller.dart';
import 'legal/legal_controller.dart';

/// Vistas de la zona de adultos: gate → resumen → control → salud → legal.
enum PadreVista { legal, gate, resumen, control, salud }

/// Navegación interna de la pantalla de padre.
///
/// El orden de entrada lo fija el plan 05: primero el gate de seguridad;
/// la aceptación legal (si falta) se cruza antes que el gate.
class PadreController extends Notifier<PadreVista> {
  @override
  PadreVista build() =>
      ref.watch(legalProvider) == null ? PadreVista.legal : PadreVista.gate;

  /// Cambia de pestaña. El gate solo se abandona desbloqueando.
  void irA(PadreVista vista) {
    if (vista == PadreVista.gate) return;
    if (ref.read(legalProvider) == null) return;
    state = vista;
  }

  /// Lo llama el gate tras validar el PIN o la huella.
  void entrar() => state = PadreVista.resumen;

  /// Cierra la sesión: vuelve al gate y obliga a escribir el PIN otra vez.
  void cerrarSesion() {
    ref.read(gateProvider.notifier).bloquear();
    state = PadreVista.gate;
  }
}

final padreProvider = NotifierProvider<PadreController, PadreVista>(
  PadreController.new,
);
