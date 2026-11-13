import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../salud/salud_providers.dart';
import '../graficos/barra_apilada.dart';
import '../graficos/colores_grafico.dart';
import '../graficos/tarjeta_grafico.dart';
import 'informe_modelo.dart';

IconData _icono(int mood) => switch (mood) {
      1 => Icons.sentiment_very_dissatisfied,
      2 => Icons.mood_bad,
      3 => Icons.sentiment_neutral,
      4 => Icons.sentiment_dissatisfied,
      _ => Icons.sentiment_very_satisfied,
    };

/// Barra apilada de check-ins de ánimo, con carita y etiqueta.
class SeccionAnimo extends StatelessWidget {
  const SeccionAnimo({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final paleta = context.colores;
    var total = 0;
    for (final veces in informe.animos.values) {
      total += veces;
    }
    final segmentos = <SegmentoApilado>[
      for (final opcion in opcionesEmocion)
        if ((informe.animos[opcion.mood] ?? 0) > 0)
          (
            etiqueta: opcion.label,
            valor: informe.animos[opcion.mood]!,
            icono: _icono(opcion.mood),
            color: colorPorIndice(opcion.mood - 1, paleta),
          ),
    ];
    final masFrecuente = [...opcionesEmocion]
      ..sort((a, b) => (informe.animos[b.mood] ?? 0)
          .compareTo(informe.animos[a.mood] ?? 0));
    final frase = total == 0
        ? 'sin check-ins en el periodo'
        : 'Más veces: ${masFrecuente.first.label.toLowerCase()}';
    final detalle = segmentos
        .map((segmento) => '${segmento.etiqueta} ${segmento.valor}')
        .join(', ');
    return TarjetaGrafico(
      pregunta: '¿Cómo se ha sentido?',
      numero: '$total',
      frase: frase,
      hayDatos: total > 0,
      semantica: 'Ánimo: $detalle. $frase.',
      grafico: BarraApilada(
        segmentos: segmentos,
        descripcion: 'Ánimo: $detalle.',
      ),
    );
  }
}
