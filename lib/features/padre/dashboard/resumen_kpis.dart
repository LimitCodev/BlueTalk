import 'package:flutter/material.dart';

import '../../../core/widgets/section_header.dart';
import '../graficos/tarjeta_kpi.dart';
import 'metricas.dart';

/// Cuatro números del día, sin comparación: «hoy» no tiene periodo anterior.
class KpisHoy extends StatelessWidget {
  const KpisHoy({super.key, required this.metricas});

  final Metricas metricas;

  @override
  Widget build(BuildContext context) {
    final kpis = [
      TarjetaKpi(
        titulo: 'Pictogramas tocados hoy',
        valor: '${metricas.pictosHoy}',
      ),
      TarjetaKpi(
        titulo: 'Palabras distintas',
        valor: '${metricas.pictosDistintosHoy}',
      ),
      TarjetaKpi(
        titulo: 'Minutos de juego',
        valor: '${metricas.minutosJuegoHoy}',
      ),
      TarjetaKpi(
        titulo: 'Sesiones de juego',
        valor: '${metricas.sesionesJuegoHoy}',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Hoy en números'),
        for (var i = 0; i < kpis.length; i += 2) ...[
          if (i > 0) const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: kpis[i]),
                  const SizedBox(width: 8),
                  Expanded(child: kpis[i + 1]),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
