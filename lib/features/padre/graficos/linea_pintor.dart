import 'package:flutter/material.dart';

import 'linea_geometria.dart';

/// Pinta la línea suave, su área rellena y el punto seleccionado.
class PintorLinea extends CustomPainter {
  const PintorLinea({
    required this.valores,
    required this.progreso,
    required this.color,
    required this.relleno,
    required this.base,
    this.seleccion,
  });

  final List<num> valores;
  final double progreso;
  final Color color;
  final Color relleno;
  final Color base;
  final int? seleccion;

  @override
  void paint(Canvas canvas, Size size) {
    final puntos = puntosLinea(valores, size);
    if (puntos.isEmpty) return;
    final visibles = [
      for (final punto in puntos)
        Offset(punto.dx, size.height - (size.height - punto.dy) * progreso),
    ];
    final linea = caminoSuave(visibles);
    final area = Path.from(linea)
      ..lineTo(visibles.last.dx, size.height)
      ..lineTo(visibles.first.dx, size.height)
      ..close();
    canvas.drawPath(area, Paint()..color = relleno);
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()..color = base,
    );
    canvas.drawPath(
      linea,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
    final ultimo = visibles.last;
    canvas.drawCircle(ultimo, 5, Paint()..color = color);
    if (seleccion != null && seleccion! < visibles.length) {
      final punto = visibles[seleccion!];
      canvas.drawCircle(punto, 8, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color);
    }
  }

  @override
  bool shouldRepaint(PintorLinea viejo) =>
      viejo.progreso != progreso ||
      viejo.color != color ||
      viejo.relleno != relleno ||
      viejo.base != base ||
      viejo.seleccion != seleccion ||
      !_mismosValores(viejo.valores, valores);

  static bool _mismosValores(List<num> a, List<num> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
