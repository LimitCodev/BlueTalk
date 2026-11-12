import 'package:flutter/material.dart';

import '../graficos/anillo_porcentaje.dart';
import '../graficos/medidor.dart';
import '../graficos/tarjeta_grafico.dart';
import 'informe_modelo.dart';

/// Anillo de días con uso sobre los días del periodo.
class SeccionDiasUso extends StatelessWidget {
  const SeccionDiasUso({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final usados = informe.diasConDatos;
    final total = informe.periodo.dias;
    final descripcion = 'Días con uso: $usados de $total, '
        '${(fraccion(usados, total) * 100).round()} por ciento.';
    return TarjetaGrafico(
      pregunta: '¿Cuántos días usó BlueTalk?',
      numero: '$usados de $total',
      frase: 'días con uso en el periodo',
      hayDatos: total > 0,
      semantica: descripcion,
      grafico: AnilloPorcentaje(
        hechas: usados,
        total: total,
        descripcion: descripcion,
      ),
    );
  }
}

/// Medidor de comunicación frente al periodo anterior.
class SeccionMedidor extends StatelessWidget {
  const SeccionMedidor({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final actual = informe.actual.pictos;
    final anterior = informe.anterior.pictos;
    final descripcion =
        'Pictogramas: $actual en este periodo, $anterior en el anterior.';
    return TarjetaGrafico(
      pregunta: '¿Se comunica más o menos que antes?',
      numero: '$actual',
      frase: 'pictogramas frente a $anterior del periodo anterior',
      hayDatos: actual + anterior > 0,
      semantica: descripcion,
      grafico: Medidor(
        actual: actual,
        anterior: anterior,
        descripcion: descripcion,
      ),
    );
  }
}
