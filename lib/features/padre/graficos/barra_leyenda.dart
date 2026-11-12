import 'package:flutter/material.dart';

/// Un segmento de la barra 100 % apilada.
typedef SegmentoApilado = ({
  String etiqueta,
  int valor,
  IconData icono,
  Color color,
});

/// Leyenda de la barra apilada: icono y porcentaje por segmento.
class LeyendaApilada extends StatelessWidget {
  const LeyendaApilada({
    super.key,
    required this.segmentos,
    required this.partes,
  });

  final List<SegmentoApilado> segmentos;
  final List<int> partes;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        for (var i = 0; i < segmentos.length; i++)
          if (partes[i] > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  segmentos[i].icono,
                  size: 16,
                  color: segmentos[i].color,
                ),
                const SizedBox(width: 4),
                Text('${segmentos[i].etiqueta} ${partes[i]} %'),
              ],
            ),
      ],
    );
  }
}
