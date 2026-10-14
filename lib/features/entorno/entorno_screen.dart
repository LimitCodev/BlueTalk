import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/section_header.dart';
import '../rutinas/actividad_tile.dart';
import '../rutinas/rutinas_controller.dart';

/// Sección "Mi entorno / Mi colegio" (plan 04 §3): datos 100% ficticios
/// marcados como demostración, más una guía ilustrada de la rutina de
/// llegada con pictos.
///
/// Prohibido usar nombres, teléfonos o datos reales aquí (plan 00 §5).
class EntornoScreen extends ConsumerWidget {
  const EntornoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
          child: Row(
            children: [
              OutlinedButton.icon(
                style:
                    OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: () =>
                    ref.read(rutinasProvider.notifier).irAlInicio(),
                icon: const Icon(Icons.chevron_left),
                label: const Text('Volver'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Mi colegio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: const [
              _DemoBadge(),
              SectionHeader('Mi colegio'),
              _DatosColegio(),
              SectionHeader('Contacto del colegio'),
              _ContactoColegio(),
              SectionHeader('Mi llegada al colegio'),
              _GuiaLlegada(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Banda "Datos de demostración": toda la pantalla es ficticia.
class _DemoBadge extends StatelessWidget {
  const _DemoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.science_outlined,
              color: AppColors.onWarning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Datos de demostración. Esta información no es real.',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.onWarning),
            ),
          ),
        ],
      ),
    );
  }
}

class _DatosColegio extends StatelessWidget {
  const _DatosColegio();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.school_outlined, color: AppColors.primaryStrong),
        title: Text('Colegio Demostración Norte'),
        subtitle: Text('Aula de ejemplo — grupo azul'),
      ),
    );
  }
}

class _ContactoColegio extends StatelessWidget {
  const _ContactoColegio();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(Icons.mail_outline, color: AppColors.primaryStrong),
        title: Text('Coordinadora: Sra. Ejemplo'),
        subtitle: Text('demo@bluetalk.app'),
      ),
    );
  }
}

/// Guía ilustrada de la rutina de llegada con pictos (plan 04 §3):
/// llegar, saludar, despedida. Literal, sin metáforas.
class _GuiaLlegada extends StatelessWidget {
  const _GuiaLlegada();

  static const _pasos = <(String, String)>[
    ('Llego a la escuela', 'house'),
    ('Saludo a mi maestra', 'happy_man'),
    ('Es hora de volver a casa', 'school_1'),
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
