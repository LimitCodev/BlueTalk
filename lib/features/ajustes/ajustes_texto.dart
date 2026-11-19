import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../../data/models/models.dart';
import 'settings_controller.dart';

/// Tamaño de texto controlado por la app (se suma al del sistema).
class TextScaleSection extends ConsumerWidget {
  const TextScaleSection({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(settingsProvider.notifier);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Tamaño del texto'),
        ListTile(
          title: const Text('Letra más grande'),
          subtitle: Slider(
            value: settings.textScale,
            min: 0.9,
            max: 1.6,
            divisions: 7,
            label: '${(settings.textScale * 100).round()}%',
            // Vista previa en vivo; el archivo se escribe al soltar.
            onChanged: notifier.previewTextScale,
            onChangeEnd: (_) => notifier.guardarCambios(),
          ),
          trailing: Text('${(settings.textScale * 100).round()}%'),
        ),
      ],
    );
  }
}
