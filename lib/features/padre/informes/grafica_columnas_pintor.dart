import 'package:flutter/material.dart';

/// Pinta las columnas por día con su avance de entrada.
class PintorColumnas extends CustomPainter {
  const PintorColumnas({
    required this.valores,
    required this.normal,
    required this.destacado,
    required this.base,
    required this.progreso,
    this.resaltado,
    this.seleccion,
  });

  final List<int?> valores;
  final Color normal;
  final Color destacado;
  final Color base;
  final double progreso;
  final int? resaltado;
  final int? seleccion;

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.isEmpty) return;
    var maximo = 1;
    for (final valor in valores) {
      if (valor != null && valor > maximo) maximo = valor;
    }
    final ancho = size.width / valores.length;
    for (var i = 0; i < valores.length; i++) {
      final valor = valores[i];
      if (valor == null || valor <= 0) continue;
      final altura = size.height * valor / maximo * progreso;
      final resaltada = i == resaltado || i == seleccion;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            i * ancho + ancho * 0.15,
            size.height - altura,
            ancho * 0.7,
            altura,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = resaltada ? destacado : normal,
      );
    }
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()..color = base,
    );
  }

  @override
  bool shouldRepaint(PintorColumnas viejo) =>
      viejo.progreso != progreso ||
      viejo.normal != normal ||
      viejo.destacado != destacado ||
      viejo.base != base ||
      viejo.resaltado != resaltado ||
      viejo.seleccion != seleccion ||
      !_mismosValores(viejo.valores, valores);

  static bool _mismosValores(List<int?> a, List<int?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
