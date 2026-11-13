import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'dona_geometria.dart';

/// Pinta los segmentos de una dona con su avance de entrada.
class PintorDona extends CustomPainter {
  const PintorDona({
    required this.angulos,
    required this.colores,
    required this.base,
    required this.progreso,
    this.seleccion,
  });

  final List<AnguloDona> angulos;
  final List<Color> colores;
  final Color base;
  final double progreso;
  final int? seleccion;

  @override
  void paint(Canvas canvas, Size size) {
    final centro = size.center(Offset.zero);
    final radio = math.min(size.width, size.height) / 2 - 16;
    if (radio <= 0) return;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final pincel = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22;
    canvas.drawArc(rect, 0, 2 * math.pi, false, pincel..color = base);
    for (var i = 0; i < angulos.length; i++) {
      final barrido = angulos[i].barrido * progreso;
      if (barrido <= 0.001) continue;
      pincel
        ..color = i < colores.length ? colores[i] : base
        ..strokeWidth = i == seleccion ? 28 : 22
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        rect,
        -math.pi / 2 + angulos[i].inicio + 0.006,
        math.max(0, barrido - 0.012),
        false,
        pincel,
      );
    }
  }

  @override
  bool shouldRepaint(PintorDona viejo) =>
      viejo.base != base ||
      viejo.progreso != progreso ||
      viejo.seleccion != seleccion ||
      !_mismosColores(viejo.colores, colores) ||
      !_mismosAngulos(viejo.angulos, angulos);

  static bool _mismosColores(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _mismosAngulos(List<AnguloDona> a, List<AnguloDona> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].inicio != b[i].inicio || a[i].barrido != b[i].barrido) {
        return false;
      }
    }
    return true;
  }
}
