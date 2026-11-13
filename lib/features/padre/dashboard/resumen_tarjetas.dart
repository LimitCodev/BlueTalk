import 'package:flutter/material.dart';

import '../../../core/widgets/section_header.dart';
import 'barras.dart';
import 'metricas.dart';

/// Datos del Resumen que no tienen gráfico, en tarjetas pequeñas.
class ResumenTarjetas extends StatelessWidget {
  const ResumenTarjetas({super.key, required this.metricas});

  final Metricas metricas;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Más datos'),
        Card(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            children: [
              FilaMetrica(
                titulo: 'Memoria: nivel alcanzado',
                valor:
                    metricas.nivelMemoria == null ? '—' : '${metricas.nivelMemoria}',
              ),
              FilaMetrica(
                titulo: 'Cuentos completados',
                valor: '${metricas.cuentosCompletados}',
              ),
              FilaMetrica(
                titulo: 'Dibujos guardados',
                valor: '${metricas.dibujosGuardados}',
              ),
              FilaMetrica(
                titulo: 'Check-ins de ánimo (7 días)',
                valor: '${metricas.checkInsSemana}',
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            'Los datos se guardan solo en este teléfono.',
            style: TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
