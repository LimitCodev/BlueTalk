import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../../data/models/models.dart';
import 'settings_controller.dart';

/// Sección de voz: guarda rate/pitch; el audio real lo añade el agente AAC.
class TtsSection extends ConsumerWidget {
  const TtsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final settings = asyncSettings.value ?? const AppSettings();
    // Si la carga falló, los sliders quedan inactivos: moverlos intentaría
    // escribir sobre un estado de error (StateError en requireValue).
    final enabled = asyncSettings.hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Voz'),
        ListTile(
          title: const Text('Velocidad de la voz'),
          subtitle: Slider(
            value: settings.ttsRate,
            min: 0.2,
            max: 0.9,
            divisions: 7,
            onChanged: enabled
                ? (value) =>
                      ref.read(settingsProvider.notifier).setTtsRate(value)
                : null,
          ),
        ),
        ListTile(
          title: const Text('Tono de la voz'),
          subtitle: Slider(
            value: settings.ttsPitch,
            min: 0.6,
            max: 1.4,
            divisions: 8,
            onChanged: enabled
                ? (value) =>
                      ref.read(settingsProvider.notifier).setTtsPitch(value)
                : null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'La voz se activará en una próxima versión.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
