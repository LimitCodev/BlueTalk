import 'package:flutter/material.dart';

import '../graficos/calendario_calor.dart';
import '../graficos/tarjeta_grafico.dart';
import 'informe_modelo.dart';

/// Calendario de calor del mes con los días que tuvieron uso.
class SeccionCalendario extends StatelessWidget {
  const SeccionCalendario({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final dias = [for (final punto in informe.serie) punto.dia];
    final valores = [for (final punto in informe.serie) punto.pictos];
    final partes = <String>[
      for (var i = 0; i < dias.length; i++)
        '${dias[i].day}/${dias[i].month}: ${valores[i]}',
    ];
    final descripcion = 'Días usados: ${partes.join(', ')}.';
    return TarjetaGrafico(
      pregunta: '¿Qué días usó la app?',
      numero: '${informe.diasConDatos}',
      frase: 'días con uso en el mes',
      hayDatos: valores.any((valor) => valor > 0),
      semantica: descripcion,
      grafico: CalendarioCalor(
        dias: dias,
        valores: valores,
        descripcion: descripcion,
      ),
    );
  }
}
