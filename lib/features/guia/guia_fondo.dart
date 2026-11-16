import 'package:flutter/material.dart';

/// Fondo gris translúcido con un hueco iluminado (plan 14B §1).
class GuiaFondo extends CustomPainter {
  const GuiaFondo({required this.hueco, required this.borde, this.brillo})
    : super(repaint: brillo);

  /// Zona iluminada, ya con su margen; `null` = todo gris.
  final Rect? hueco;
  final Color borde;

  /// Opacidad del borde que «respira» (0,6–1); `null` = borde fijo.
  final Animation<double>? brillo;

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
          ..color = borde.withValues(alpha: brillo?.value ?? 1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  @override
  bool shouldRepaint(GuiaFondo old) =>
      old.hueco != hueco || old.borde != borde || old.brillo != brillo;
}

/// [GuiaFondo] con el borde que respira (1,2 s en bucle). Sin movimiento
/// con el modo calma o «Quitar animaciones» de Android.
class GuiaFondoQueRespira extends StatefulWidget {
  const GuiaFondoQueRespira({
    super.key,
    required this.hueco,
    required this.borde,
  });

  final Rect? hueco;
  final Color borde;

  @override
  State<GuiaFondoQueRespira> createState() => _GuiaFondoQueRespiraState();
}

class _GuiaFondoQueRespiraState extends State<GuiaFondoQueRespira>
    with SingleTickerProviderStateMixin {
  late final _reloj = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    lowerBound: 0.6,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _reloj.value = 1;
    } else if (!_reloj.isAnimating) {
      _reloj.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _reloj.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: GuiaFondo(
      hueco: widget.hueco,
      borde: widget.borde,
      brillo: _reloj,
    ),
  );
}
