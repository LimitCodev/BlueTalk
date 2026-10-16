import 'package:flutter/material.dart';

import '../theme/app_colors.dart' show Marca;

/// Logo oficial de BlueTalk (plan 13 P3.2 y P3.5): burbuja de chat azul
/// de marca con cara sonriente blanca y el corazón verde del cartel
/// debajo a la derecha.
///
/// Dibujado con [CustomPainter]: vector, sin dependencias nuevas ni
/// imágenes rasterizadas — nítido en cualquier densidad y reutilizable
/// para el ícono de la app.
class LogoBluetalk extends StatelessWidget {
  const LogoBluetalk({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    // El logo es decorativo: el texto del título ya lo nombra.
    return ExcludeSemantics(
      child: SizedBox(
        width: size,
        height: size,
        child: const CustomPaint(painter: _LogoPainter()),
      ),
    );
  }
}

/// Lienzo de 100×100 escalado al tamaño pedido.
class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 100;
    final burbuja = Paint()..color = Marca.azul;
    final cara = Paint()..color = const Color(0xFFFFFFFF);

    // Cola de la burbuja, abajo a la izquierda.
    final cola = Path()
      ..moveTo(31 * u, 64 * u)
      ..quadraticBezierTo(21 * u, 78 * u, 14 * u, 88 * u)
      ..quadraticBezierTo(30 * u, 83 * u, 40 * u, 71 * u)
      ..close();
    canvas.drawPath(cola, burbuja);

    // Anillo: círculo azul con interior blanco.
    final centro = Offset(46 * u, 43 * u);
    canvas.drawCircle(centro, 32 * u, burbuja);
    canvas.drawCircle(centro, 25 * u, cara);

    // Cara: dos ojos y una sonrisa (azul de marca).
    final ojo = Paint()..color = Marca.azul;
    canvas.drawCircle(Offset(37 * u, 37 * u), 3.4 * u, ojo);
    canvas.drawCircle(Offset(57 * u, 37 * u), 3.4 * u, ojo);
    final sonrisa = Paint()
      ..color = Marca.azul
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(36 * u, 49 * u)
        ..quadraticBezierTo(47 * u, 59 * u, 58 * u, 49 * u),
      sonrisa,
    );

    // Corazón verde del cartel, abajo a la derecha sobre el anillo:
    // dos círculos (lóbulos) + un triángulo (punta), mismo relleno.
    final verde = Paint()..color = Marca.verde;
    const hx = 62.0, hy = 54.0, hs = 32.0; // caja del corazón en u
    canvas.drawCircle(Offset((hx + 0.29 * hs) * u, (hy + 0.30 * hs) * u),
        0.235 * hs * u, verde);
    canvas.drawCircle(Offset((hx + 0.71 * hs) * u, (hy + 0.30 * hs) * u),
        0.235 * hs * u, verde);
    final punta = Path()
      ..moveTo((hx + 0.075 * hs) * u, (hy + 0.42 * hs) * u)
      ..lineTo((hx + 0.925 * hs) * u, (hy + 0.42 * hs) * u)
      ..lineTo((hx + 0.5 * hs) * u, (hy + 0.97 * hs) * u)
      ..close();
    canvas.drawPath(punta, verde);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => false;
}
