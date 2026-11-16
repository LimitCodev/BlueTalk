import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import 'guia_lista.dart';

/// Guía de primera vez (plan 14B). Estado: índice del paso, o `null` si
/// la guía no está en pantalla.
class GuiaController extends Notifier<int?> {
  /// Clave en el almacén: la guía ya se vio (o se saltó) una vez.
  static const claveVista = 'guia_vista';

  @override
  int? build() => null;

  bool get vista =>
      ref.read(almacenLocalProvider).booleano(claveVista) ?? false;

  /// Empieza desde el paso 1 (la primera vez o «Ver la guía otra vez»).
  void iniciar() => state = 0;

  /// Arranque automático: solo si nunca se terminó ni se saltó.
  void iniciarSiFalta() {
    if (state == null && !vista) iniciar();
  }

  void siguiente() {
    final i = state;
    if (i != null && i < pasosGuia.length - 1) state = i + 1;
  }

  /// Paso anterior. En el paso 1 no hace nada.
  void anterior() {
    final i = state;
    if (i != null && i > 0) state = i - 1;
  }

  /// Último paso o «Saltar»: se marca vista y se cierra.
  Future<void> terminar() async {
    state = null;
    await ref.read(almacenLocalProvider).guardarBooleano(claveVista, true);
  }
}

final guiaProvider = NotifierProvider<GuiaController, int?>(GuiaController.new);

/// El botón Atrás de Android durante la guía retrocede un paso.
/// Devuelve `true` si la guía lo atendió.
bool guiaAtras(WidgetRef ref) {
  if (ref.read(guiaProvider) == null) return false;
  ref.read(guiaProvider.notifier).anterior();
  return true;
}
