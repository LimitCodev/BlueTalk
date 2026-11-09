import 'package:flutter/material.dart';

import '../../core/widgets/section_header.dart';
import '../rutinas/actividad_tile.dart';
import '../rutinas/cabecera_vista.dart';

/// Sección «Mi colegio» (plan 04 §3): guía ilustrada de la llegada con pictos.
///
/// Prohibido usar nombres, teléfonos o datos reales aquí (plan 00 §5).
class EntornoScreen extends StatelessWidget {
  const EntornoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const CabeceraVista(titulo: 'Mi colegio'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: const [
              SectionHeader('Mi llegada al colegio'),
              _GuiaLlegada(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Guía ilustrada de la rutina de llegada con pictos (plan 04 §3):
/// llegar, saludar, despedida. Literal, sin metáforas.
class _GuiaLlegada extends StatelessWidget {
  const _GuiaLlegada();

  static const _pasos = <(String, String)>[
    ('Llego a la escuela', 'school_1'),
    ('Saludo a mi maestra', 'teacher_1b'),
    ('Es hora de volver a casa', 'house'),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Así es mi llegada al colegio:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            for (final (texto, pictoId) in _pasos)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    PictoMini(
                      pictoId,
                      size: 48,
                      semanticsLabel: texto,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        texto,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
