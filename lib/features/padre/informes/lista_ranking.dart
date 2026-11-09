import 'package:flutter/material.dart';

import '../dashboard/barras.dart';
import 'informe_modelo.dart';

/// Lista «más usados» con barras proporcionales al primero.
class ListaRanking extends StatelessWidget {
  const ListaRanking({
    super.key,
    required this.titulo,
    required this.ranking,
    this.formato,
  });

  final String titulo;
  final Ranking ranking;
  final String Function(int)? formato;

  @override
  Widget build(BuildContext context) {
    if (ranking.isEmpty) return const SizedBox.shrink();
    final maximo = ranking.first.valor.clamp(1, 1 << 31);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(titulo, style: Theme.of(context).textTheme.titleSmall),
        ),
        for (final e in ranking)
          BarraDato(
            etiqueta: e.nombre,
            valor: e.valor / maximo,
            detalle: formato?.call(e.valor) ?? '${e.valor}',
          ),
      ],
    );
  }
}
