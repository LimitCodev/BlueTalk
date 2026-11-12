import 'package:flutter/material.dart';

/// Fondo gris translúcido con un hueco iluminado (plan 14B §1).
class GuiaFondo extends CustomPainter {
  const GuiaFondo({required this.hueco, required this.borde});

  /// Zona iluminada, ya con su margen; `null` = todo gris.
  final Rect? hueco;
  final Color borde;

  static const gris = Color(0xB8263238); // blueGrey 900 al 72 %

  RRect? get _forma => hueco == null
      ? null
      : RRect.fromRectAndRadius(hueco!, const Radius.circular(16));

  @override
  void paint(Canvas canvas, Size size) {
    final pantalla = Path()..addRect(Offset.zero & size);
    final forma = _forma;
    final fondo = forma == null
        ? pantalla
        : Path.combine(
            PathOperation.difference,
            pantalla,
            Path()..addRRect(forma),
          );
    canvas.drawPath(fondo, Paint()..color = gris);
    if (forma != null) {
      canvas.drawRRect(
        forma,
        Paint()
          ..color = borde
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(GuiaFondo old) => old.hueco != hueco || old.borde != borde;
}
