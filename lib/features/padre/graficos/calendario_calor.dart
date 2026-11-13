import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'animacion.dart';
import 'calendario_rejilla.dart';

export 'calendario_geometria.dart';

/// Calendario de calor: cada día del periodo con su intensidad de uso.
class CalendarioCalor extends StatelessWidget {
  const CalendarioCalor({
    super.key,
    required this.dias,
    required this.valores,
    required this.descripcion,
  });

  final List<DateTime> dias;
  final List<int> valores;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    if (dias.isEmpty) return const SizedBox.shrink();
    final maximo = valores.fold<int>(0, (m, v) => v > m ? v : m);
    return Semantics(
      container: true,
      label: descripcion,
      excludeSemantics: true,
      child: AnimacionGrafico(
        builder: (context, t) => Column(
          children: [
            Row(
              children: [
                for (final letra in const ['L', 'M', 'X', 'J', 'V', 'S', 'D'])
                  Expanded(
                    child: Text(
                      letra,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
            RejillaCalor(
              dias: dias,
              valores: valores,
              maximo: maximo,
              progreso: t,
            ),
            const SizedBox(height: 8),
            const _Leyenda(),
          ],
        ),
      ),
    );
  }
}

class _Leyenda extends StatelessWidget {
  const _Leyenda();

  @override
  Widget build(BuildContext context) {
    final paleta = context.colores;
    final estilo = Theme.of(context).textTheme.bodySmall;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('Sin uso', style: estilo),
        for (var nivel = 0; nivel <= 4; nivel++)
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Color.lerp(
                paleta.surface,
                paleta.primaryStrong,
                0.06 + nivel * 0.11,
              ),
              border: Border.all(color: paleta.borde),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        Text('Más uso', style: estilo),
      ],
    );
  }
}
