import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pinta el anillo de progreso con su avance de entrada.
class PintorAnillo extends CustomPainter {
  const PintorAnillo({
    required this.avance,
    required this.progreso,
    required this.color,
    required this.base,
  });

  final double avance;
  final double progreso;
  final Color color;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = math.min(size.width, size.height) / 2 - 12;
    if (radio <= 0) return;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..color = base;
    canvas.drawArc(rect, 0, 2 * math.pi, false, pincel);
    if (avance > 0 && progreso > 0) {
      pincel.color = color;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * avance * progreso,
        false,
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(PintorAnillo viejo) =>
      viejo.avance != avance ||
      viejo.progreso != progreso ||
      viejo.color != color ||
      viejo.base != base;
}
