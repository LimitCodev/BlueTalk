import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

import 'artista_dibujos.dart';

/// Pintor eficiente para gama baja (plan 03 §4):
///
/// - [TrazosPainter] pinta los trazos terminados y solo repinta si la
///   lista cambia de identidad (nunca durante un gesto).
/// - [TrazoActivoPainter] pinta solo el trazo en curso; repinta en cada
///   movimiento, pero solo dibuja un path.
///
/// Apilados en un [Stack] con [RepaintBoundary], arrastrar el dedo solo
/// repinta la capa del trazo activo: sin tirones en API 24.
class TrazosPainter extends CustomPainter {
  const TrazosPainter(this.trazos);

  final List<Trazo> trazos;

  @override
  void paint(Canvas canvas, Size size) {
    for (final trazo in trazos) {
      _pintarTrazo(canvas, size, trazo);
    }
  }

  @override
  bool shouldRepaint(TrazosPainter oldDelegate) =>
      oldDelegate.trazos != trazos;
}

/// Pintor de un solo trazo: el activo durante el gesto.
class TrazoActivoPainter extends CustomPainter {
  const TrazoActivoPainter(this.trazo);

  final Trazo? trazo;

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = this.trazo;
    if (trazo == null) return;
    _pintarTrazo(canvas, size, trazo);
  }

  @override
  bool shouldRepaint(TrazoActivoPainter oldDelegate) =>
      oldDelegate.trazo != trazo;
}

/// Dibuja un trazo: puntos normalizados (0–1) → píxeles del lienzo.
void _pintarTrazo(Canvas canvas, Size size, Trazo trazo) {
  if (trazo.puntos.isEmpty) return;

  final paint = Paint()
    ..color = Color(trazo.color)
    // El grosor se guarda en el espacio de referencia 1000 (ver Trazo).
    ..strokeWidth = trazo.grosor * size.width / 1000
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  final path = Path()
    ..moveTo(
      trazo.puntos.first.dx * size.width,
      trazo.puntos.first.dy * size.height,
    );
  if (trazo.puntos.length == 1) {
    // Un punto solo: lauchear un dot para que se vea al tocar.
    final p = trazo.puntos.first;
    canvas.drawPoints(
      PointMode.points,
      [Offset(p.dx * size.width, p.dy * size.height)],
      paint..strokeWidth = paint.strokeWidth * 1.5,
    );
    return;
  }
  for (final punto in trazo.puntos.skip(1)) {
    path.lineTo(punto.dx * size.width, punto.dy * size.height);
  }
  canvas.drawPath(path, paint);
}
