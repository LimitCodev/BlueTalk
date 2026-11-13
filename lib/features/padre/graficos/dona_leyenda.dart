import 'package:flutter/material.dart';

import 'dona.dart';

/// Dona con su leyenda de texto: ningún segmento queda solo con color.
class DonaConLeyenda extends StatelessWidget {
  const DonaConLeyenda({
    super.key,
    required this.porciones,
    required this.descripcion,
    this.tituloCentro = 'Total',
    this.formato,
  });

  final List<SegmentoDona> porciones;
  final String descripcion;
  final String tituloCentro;
  final String Function(int)? formato;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Dona(
          porciones: porciones,
          descripcion: descripcion,
          tituloCentro: tituloCentro,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: [
            for (final porcion in porciones)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: porcion.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${porcion.etiqueta} '
                    '${formato?.call(porcion.valor) ?? porcion.valor}',
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
