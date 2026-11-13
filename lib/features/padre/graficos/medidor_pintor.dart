import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pinta el semicírculo y la aguja del medidor.
class PintorMedidor extends CustomPainter {
  const PintorMedidor({
    required this.angulo,
    required this.progreso,
    required this.color,
    required this.base,
  });

  final double angulo;
  final double progreso;
  final Color color;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height);
    final radio = math.min(size.width / 2, size.height) - 12;
    if (radio <= 0) return;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = base;
    canvas.drawArc(rect, math.pi, math.pi, false, pincel);
    final avance = angulo * progreso;
    if (avance.abs() > 0.001) {
      pincel.color = color;
      canvas.drawArc(rect, math.pi, math.pi / 2 + avance, false, pincel);
    }
    canvas.drawCircle(
      Offset(centro.dx, centro.dy - radio),
      3,
      Paint()..color = color,
    );
    final direccion = 3 * math.pi / 2 + avance;
    final punta = Offset(
      centro.dx + math.cos(direccion) * radio * 0.82,
      centro.dy + math.sin(direccion) * radio * 0.82,
    );
    final aguja = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(centro, punta, aguja);
    canvas.drawCircle(centro, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(PintorMedidor viejo) =>
      viejo.angulo != angulo ||
      viejo.progreso != progreso ||
      viejo.color != color ||
      viejo.base != base;
}
