import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/models/models.dart';

/// Vista activa de la pestaña Rutinas.
///
/// La navegación entre vistas es interna (sin rutas propias), igual que en
/// JuegosScreen: el router raíz pertenece al shell y así no hay acoplamiento
/// entre features.
enum RutinaVista { inicio, horario, editor, bienestar, colegio, estadisticas }

/// Controlador de la vista activa de la pestaña Rutinas.
class RutinasController extends Notifier<RutinaVista> {
  @override
  RutinaVista build() => RutinaVista.inicio;

  void abrir(RutinaVista vista) {
    if (state == vista) return;
    state = vista;
    // Fire-and-forget: alimenta las estadísticas sin bloquear la navegación.
    ref.read(usageRepoProvider).record(
          UsageEvent(
            id: 'rutina_${vista.name}_${DateTime.now().microsecondsSinceEpoch}',
            type: 'rutina_vista',
            createdAt: DateTime.now(),
            data: {'vista': vista.name},
          ),
        );
  }

  void irAlInicio() {
    if (state == RutinaVista.inicio) return;
    state = RutinaVista.inicio;
  }
}

/// Vista activa de la pestaña Rutinas.
final rutinasProvider = NotifierProvider<RutinasController, RutinaVista>(
  RutinasController.new,
);
