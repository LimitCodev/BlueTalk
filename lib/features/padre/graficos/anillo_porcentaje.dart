import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'animacion.dart';
import 'anillo_pintor.dart';

/// Fracción 0–1 de [hechas] sobre [total]; con total 0 devuelve 0.
double fraccion(int hechas, int total) {
  if (total <= 0) return 0;
  return (hechas / total).clamp(0.0, 1.0);
}

/// Anillo de progreso con el porcentaje en el centro.
class AnilloPorcentaje extends StatelessWidget {
  const AnilloPorcentaje({
    super.key,
    required this.hechas,
    required this.total,
    required this.descripcion,
    this.alto = 150,
  });

  final int hechas;
  final int total;
  final String descripcion;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final avance = fraccion(hechas, total);
    return Semantics(
      container: true,
      label: descripcion,
      excludeSemantics: true,
      child: SizedBox(
        height: alto,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimacionGrafico(
                  builder: (context, t) => CustomPaint(
                    painter: PintorAnillo(
                      avance: avance,
                      progreso: t,
                      color: context.colores.primaryStrong,
                      base: context.colores.borde,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              '${(avance * 100).round()} %',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colores.primaryStrongText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
