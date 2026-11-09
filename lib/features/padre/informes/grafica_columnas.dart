import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Columnas por día, dibujadas en Flutter (sin librería de gráficas).
///
/// Sin animación (Modo calma). Un valor `null` es «sin datos» y no se
/// dibuja como cero. El lector de pantalla recibe [descripcion].
class GraficaColumnas extends StatelessWidget {
  const GraficaColumnas({
    super.key,
    required this.valores,
    required this.descripcion,
    this.alto = 120,
  });

  final List<int?> valores;
  final String descripcion;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      container: true, // nodo propio: el lector la anuncia sola
      label: descripcion,
      excludeSemantics: true,
      child: SizedBox(
        height: alto,
        width: double.infinity,
        // Capa propia: repintar la gráfica no repinta la lista entera.
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _Pintor(valores, c.primaryStrong, c.borde),
          ),
        ),
      ),
    );
  }
}

class _Pintor extends CustomPainter {
  _Pintor(this.valores, this.relleno, this.base);

  final List<int?> valores;
  final Color relleno;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    if (valores.isEmpty) return;
    final maximo = valores.fold<int>(1, (m, v) => v != null && v > m ? v : m);
    final ancho = size.width / valores.length;
    final pincel = Paint()..color = relleno;
    for (var i = 0; i < valores.length; i++) {
      final v = valores[i];
      if (v == null || v == 0) continue;
      final h = size.height * v / maximo;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(i * ancho + ancho * 0.15, size.height - h, ancho * 0.7, h),
          const Radius.circular(3),
        ),
        pincel,
      );
    }
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height),
        Paint()..color = base);
  }

  @override
  bool shouldRepaint(_Pintor viejo) =>
      viejo.relleno != relleno || !_iguales(viejo.valores, valores);

  static bool _iguales(List<int?> a, List<int?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
