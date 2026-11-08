import 'package:flutter/material.dart';

import '../../../core/widgets/section_header.dart';
import '../monitoreo/uso_telefono_model.dart';
import 'grafica_columnas.dart';
import 'informe_modelo.dart';
import 'lista_ranking.dart';

/// Uso de otras apps del teléfono (solo tiempos; nunca contenido).
class SeccionUsoTelefono extends StatelessWidget {
  const SeccionUsoTelefono({super.key, required this.informe});

  final Informe informe;

  @override
  Widget build(BuildContext context) {
    final i = informe;
    final minutos = [
      for (final p in i.serie)
        p.segundosPantalla == null ? null : p.segundosPantalla! ~/ 60,
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader('Uso del teléfono'),
        if (i.diasConApps == 0)
          const Text('Sin datos. Activa «Acceso al uso» en Control. Android '
              'guarda solo los últimos 10 días: BlueTalk los copia cada vez '
              'que abres los informes.')
        else ...[
          Text('Tiempo en otras apps: ${formatearDuracion(i.segundosPantalla)} '
              '(${i.diasConApps} de ${i.periodo.dias} días con datos).'),
          const SizedBox(height: 8),
          GraficaColumnas(
            valores: minutos,
            descripcion: 'Minutos de pantalla por día: '
                '${minutos.map((m) => m ?? 'sin datos').join(', ')}.',
          ),
          ListaRanking(
            titulo: 'Apps más usadas',
            ranking: i.apps,
            formato: formatearDuracion,
          ),
        ],
      ]),
    );
  }
}
