import 'package:flutter/material.dart';

import 'guia_fondo.dart';

/// Coloca el fondo gris con su hueco y el globo donde haya más sitio:
/// debajo del hueco si está arriba y encima si está abajo (plan 14B §1).
class GuiaPosicion extends StatelessWidget {
  const GuiaPosicion({
    super.key,
    required this.hueco,
    required this.borde,
    required this.globo,
  });

  final Rect? hueco;
  final Color borde;
  final Widget globo;

  /// Alto mínimo para que el globo quepa fuera del hueco.
  static const _altoGlobo = 230.0;

  @override
  Widget build(BuildContext context) {
    final tam = MediaQuery.sizeOf(context);
    final pad = MediaQuery.paddingOf(context);
    final ancho = tam.width - 32 > 460 ? 460.0 : tam.width - 32;
    final izquierda = (tam.width - ancho) / 2;
    final h = hueco;
    final abajo = h == null ? 0.0 : tam.height - pad.bottom - h.bottom;
    final arriba = h == null ? 0.0 : h.top - pad.top;
    Widget colocar({double? top, double? bottom}) => Positioned(
      left: izquierda,
      width: ancho,
      top: top,
      bottom: bottom,
      child: globo,
    );
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // El fondo absorbe todos los toques: solo responde el globo.
          Positioned.fill(
            child: AbsorbPointer(
              child: CustomPaint(
                painter: GuiaFondo(hueco: h, borde: borde),
              ),
            ),
          ),
          if (h == null)
            Positioned.fill(
              child: Center(
                child: SizedBox(width: ancho, child: globo),
              ),
            )
          else if (abajo >= _altoGlobo && abajo >= arriba)
            colocar(top: h.bottom + 12)
          else if (arriba >= _altoGlobo)
            colocar(bottom: tam.height - h.top + 12)
          else
            // Hueco muy grande: el globo va abajo, encima del hueco.
            colocar(bottom: pad.bottom + 16),
        ],
      ),
    );
  }
}
