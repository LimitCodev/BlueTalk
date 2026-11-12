import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'calendario_geometria.dart';

/// Cuadrícula de días de un periodo, con cuatro intensidades de uso.
class RejillaCalor extends StatelessWidget {
  const RejillaCalor({
    super.key,
    required this.dias,
    required this.valores,
    required this.maximo,
    required this.progreso,
  });

  final List<DateTime> dias;
  final List<int> valores;
  final int maximo;
  final double progreso;

  @override
  Widget build(BuildContext context) {
    if (dias.isEmpty) return const SizedBox.shrink();
    final celdas = <Widget>[
      for (var i = 0; i < dias.first.weekday - 1; i++) const SizedBox(),
      for (var i = 0; i < dias.length; i++)
        _Celda(
          dia: dias[i],
          nivel: nivelCalor(i < valores.length ? valores[i] : 0, maximo),
          progreso: progreso,
        ),
    ];
    final filas = <Widget>[];
    for (var i = 0; i < celdas.length; i += 7) {
      final fila = celdas.sublist(i, math.min(i + 7, celdas.length));
      while (fila.length < 7) {
        fila.add(const SizedBox());
      }
      filas.add(Row(children: [for (final celda in fila) Expanded(child: celda)]));
    }
    return Column(children: filas);
  }
}

class _Celda extends StatelessWidget {
  const _Celda({
    required this.dia,
    required this.nivel,
    required this.progreso,
  });

  final DateTime dia;
  final int nivel;
  final double progreso;

  @override
  Widget build(BuildContext context) {
    final paleta = context.colores;
    final color = Color.lerp(
      paleta.surface,
      paleta.primaryStrong,
      (0.06 + nivel * 0.11) * progreso,
    );
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: paleta.borde),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${dia.day}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
