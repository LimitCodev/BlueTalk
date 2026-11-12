import 'package:flutter/widgets.dart';

import 'guia_pasos.dart';

/// Una clave por parte iluminable: la guía mide su rectángulo en pantalla.
final guiaClaves = {
  for (final o in GuiaObjetivo.values)
    o: GlobalKey(debugLabel: 'guia-${o.name}'),
};

/// Marca un widget como parte que la guía puede iluminar (plan 14B §4.1).
/// Cada objetivo debe estar montado una sola vez a la vez.
class GuiaAncla extends StatelessWidget {
  const GuiaAncla({super.key, required this.objetivo, required this.child});

  final GuiaObjetivo objetivo;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: guiaClaves[objetivo], child: child);
}

/// Rectángulo global del objetivo, o `null` si no está en pantalla.
Rect? rectDe(GuiaObjetivo objetivo) {
  final caja = guiaClaves[objetivo]?.currentContext?.findRenderObject();
  if (caja is! RenderBox || !caja.attached || !caja.hasSize) return null;
  return caja.localToGlobal(Offset.zero) & caja.size;
}
