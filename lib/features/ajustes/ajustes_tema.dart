import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/section_header.dart';
import 'settings_controller.dart';
import 'ajustes_tema_opcion.dart';

/// Selector del tema de color (plan 13 P4): seis opciones predefinidas,
/// nunca un selector libre (un color libre rompería el contraste AA).
/// Al tocar una opción el tema cambia en toda la app al instante
/// (vista previa en vivo) y se guarda en preferencias locales.
class TemaSection extends ConsumerWidget {
  const TemaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temaActual = ref.watch(settingsProvider).value?.tema ?? 'celeste';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader('Color de la pantalla'),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                for (final entrada in AppColors.temas.entries)
                  OpcionTema(
                    id: entrada.key,
                    paleta: entrada.value,
                    seleccionado: entrada.key == temaActual,
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .setTema(entrada.key),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
