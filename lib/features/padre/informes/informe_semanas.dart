import 'package:flutter/material.dart';

import '../../../core/widgets/section_header.dart';
import '../monitoreo/uso_telefono_model.dart';
import 'informe_modelo.dart';
import 'semanas.dart';

/// Desglose por semanas del informe mensual (tabla de texto: se lee
/// igual con lector de pantalla y se compara de un vistazo).
class SeccionPorSemana extends StatelessWidget {
  const SeccionPorSemana({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelLarge;
    Widget celda(String t, [TextStyle? s]) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Text(t, style: s),
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader('Por semana'),
        Table(
          columnWidths: const {0: FlexColumnWidth(1.4)},
          children: [
            TableRow(children: [
              for (final t in ['Días', 'Pictos', 'Juego', 'Pantalla'])
                celda(t, estilo),
            ]),
            for (final s in porSemanas(informe.serie))
              TableRow(children: [
                celda('${s.desde.day}/${s.desde.month}–${s.hasta.day}/${s.hasta.month}'),
                celda('${s.pictos}'),
                celda(formatearDuracion(s.segundosJuego)),
                celda(s.segundosPantalla == null
                    ? 'sin datos'
                    : formatearDuracion(s.segundosPantalla!)),
              ]),
          ],
        ),
      ]),
    );
  }
}
