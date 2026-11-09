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
            onChanged: (value) =>
                ref.read(settingsProvider.notifier).setTextScale(value),
          ),
          trailing: Text('${(settings.textScale * 100).round()}%'),
        ),
      ],
    );
  }
}
