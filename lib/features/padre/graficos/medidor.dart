import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'animacion.dart';
import 'medidor_pintor.dart';

/// Ángulo de la aguja: 0 es «igual que antes», −π/2 «menos» y π/2 «más».
double anguloMedidor(int actual, int anterior) {
  final razon = anterior <= 0 ? (actual > 0 ? 2.0 : 1.0) : actual / anterior;
  return (razon.clamp(0.0, 2.0) / 2 - 0.5) * math.pi;
}

/// Semicírculo con aguja para comparar con el periodo anterior.
class Medidor extends StatelessWidget {
  const Medidor({
    super.key,
    required this.actual,
    required this.anterior,
    required this.descripcion,
    this.alto = 170,
  });

  final int actual;
  final int anterior;
  final String descripcion;
  final double alto;

  @override
  Widget build(BuildContext context) {
    final angulo = anguloMedidor(actual, anterior);
    return Semantics(
      container: true,
      label: descripcion,
      excludeSemantics: true,
      child: SizedBox(
        height: alto,
        child: Column(
          children: [
            Expanded(
              child: RepaintBoundary(
                child: AnimacionGrafico(
                  builder: (context, t) => CustomPaint(
                    painter: PintorMedidor(
                      angulo: angulo,
                      progreso: t,
                      color: context.colores.primaryStrong,
                      base: context.colores.borde,
                    ),
                  ),
                ),
              ),
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Menos'), Text('Igual'), Text('Más')],
            ),
          ],
        ),
      ),
    );
  }
}
