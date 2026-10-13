import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/models/models.dart';

/// Vista activa de la pestaña Juegos.
///
/// La navegación entre juegos es interna (sin rutas propias): el router
/// raíz pertenece al shell y así no hay acoplamiento entre features.
enum JuegoVista { inicio, memoria, cuentos, artista }

/// Controlador de la vista activa y de las sesiones de juego.
///
/// Cada entrada a un juego registra `juego_inicio` y cada vuelta al inicio
/// registra `juego_fin` con la duración en segundos (plan 03 §6): alimenta
/// el dashboard del modo padre con datos locales, sin timers agresivos.
class JuegosController extends Notifier<JuegoVista> {
  @override
  JuegoVista build() => JuegoVista.inicio;

  DateTime? _sessionStart;

  void abrir(JuegoVista vista) {
    if (state == vista) return;
    _sessionStart = DateTime.now();
    state = vista;
    _log('juego_inicio', vista);
  }

  void irAlInicio() {
    final actual = state;
    if (actual == JuegoVista.inicio) return;
    state = JuegoVista.inicio;
    _log('juego_fin', actual, conDuracion: true);
  }

  void _log(String tipo, JuegoVista vista, {bool conDuracion = false}) {
    final data = <String, dynamic>{'juego': vista.name};
    final start = _sessionStart;
    if (conDuracion && start != null) {
      data['segundos'] = DateTime.now().difference(start).inSeconds;
    }
    // Fire-and-forget: el registro nunca bloquea el juego del niño.
    ref.read(usageRepoProvider).record(
          UsageEvent(
            id: '${vista.name}_${tipo}_${DateTime.now().microsecondsSinceEpoch}',
            type: tipo,
            createdAt: DateTime.now(),
            data: data,
          ),
        );
  }
}

/// Vista activa de juegos.
final juegosProvider = NotifierProvider<JuegosController, JuegoVista>(
  JuegosController.new,
);
