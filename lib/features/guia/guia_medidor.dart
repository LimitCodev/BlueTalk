import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'guia_controller.dart';
import 'guia_lista.dart';
import 'guia_objetivos.dart';

/// Mide en pantalla el objetivo del paso actual de la guía (plan 14B §4).
mixin MedidorGuia<T extends ConsumerStatefulWidget>
    on ConsumerState<T>, TickerProvider, WidgetsBindingObserver {
  Ticker? _reloj;
  Rect? rect;
  var _estables = 0;

  @override
  void dispose() {
    _reloj?.dispose();
    super.dispose();
  }

  // Al girar el teléfono, el elemento se mueve: se vuelve a medir.
  @override
  void didChangeMetrics() => volverAMedir();

  void volverAMedir() {
    _estables = 0;
    final reloj = _reloj ??= createTicker(_medir);
    if (!reloj.isActive && ref.read(guiaProvider) != null) reloj.start();
  }

  /// Mide el objetivo en cada cuadro hasta que se queda quieto ~0,5 s
  /// (carrusel deslizando, cambio de pantalla); luego para el reloj.
  void _medir(Duration _) {
    final i = ref.read(guiaProvider);
    final objetivo = i == null ? null : pasosGuia[i].objetivo;
    final nuevo = objetivo == null ? null : rectDe(objetivo);
    if (nuevo != rect) {
      setState(() => rect = nuevo);
      _estables = 0;
    } else if (++_estables > 30) {
      _reloj?.stop();
    }
  }
}
