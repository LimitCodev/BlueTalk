import 'package:flutter/widgets.dart';

/// Centra y limita el ancho del contenido en pantallas grandes.
///
/// En una tableta de 1280 dp una lista a todo lo ancho deja líneas
/// incómodas y tarjetas enormes. El límite no cambia la posición de los
/// controles en el teléfono (donde sobra ancho no hay recorte).
class AnchoLectura extends StatelessWidget {
  const AnchoLectura({super.key, required this.child, this.maxWidth = 720});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, caja) {
      final ancho = caja.maxWidth < maxWidth ? caja.maxWidth : maxWidth;
      // Altura explícita: da al hijo (una lista) un viewport acotado y
      // evita que `Center` lo mida por su contenido.
      final alto = caja.maxHeight.isFinite ? caja.maxHeight : null;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [SizedBox(width: ancho, height: alto, child: child)],
      );
    },
  );
}
