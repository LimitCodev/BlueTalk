import 'package:flutter/material.dart';

import '../graficos/tarjeta_kpi.dart';
import '../../../core/widgets/section_header.dart';
import 'informe_modelo.dart';

/// «La semana pasada» o «el mes pasado», según el informe.
String periodoAnterior(Periodo periodo) =>
    periodo == Periodo.semana ? 'la semana pasada' : 'el mes pasado';

/// Tres números con flecha frente al periodo anterior.
class SeccionComparacion extends StatelessWidget {
  const SeccionComparacion({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final actual = informe.actual;
    final anterior = informe.anterior;
    final periodo = periodoAnterior(informe.periodo);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('¿Cómo va comparado con antes?'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              TarjetaKpi(
                titulo: 'Pictogramas',
                valor: '${actual.pictos}',
                actual: actual.pictos,
                anterior: anterior.pictos,
                periodo: periodo,
              ),
              const SizedBox(height: 8),
              TarjetaKpi(
                titulo: 'Minutos de juego',
                valor: '${actual.segundosJuego ~/ 60}',
                actual: actual.segundosJuego ~/ 60,
                anterior: anterior.segundosJuego ~/ 60,
                periodo: periodo,
              ),
              const SizedBox(height: 8),
              TarjetaKpi(
                titulo: 'Actividades hechas',
                valor: '${actual.actividades}',
                actual: actual.actividades,
                anterior: anterior.actividades,
                periodo: periodo,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
