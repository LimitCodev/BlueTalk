import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/calm_mode.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/models.dart';
import 'settings_controller.dart';

/// Ajustes (plan 01 §8): modo calma, tamaño de texto, voz (placeholder del
/// agente AAC), enlaces legales (placeholder del agente padre) y créditos.
class AjustesScreen extends ConsumerWidget {
  const AjustesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const CalmModeToggle(),
        const Divider(),
        switch (settings) {
          AsyncData(:final value) => _TextScaleSection(settings: value),
          AsyncError() => const _SettingsError(),
          _ => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
        },
        const Divider(),
        const _TtsSection(),
        const Divider(),
        const _LegalSection(),
        const Divider(),
        const _CreditsSection(),
      ],
    );
  }
}

/// Tamaño de texto controlado por la app (se suma al del sistema).
class _TextScaleSection extends ConsumerWidget {
  const _TextScaleSection({required this.settings});

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

/// Sección de voz: guarda rate/pitch; el audio real lo añade el agente AAC.
class _TtsSection extends ConsumerWidget {
  const _TtsSection();

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

/// Enlaces legales: los abre el agente padre (Ola 2).
class _LegalSection extends StatelessWidget {
  const _LegalSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Legal'),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Términos y condiciones'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPlaceholder(context, 'Términos y condiciones'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Política de privacidad'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showPlaceholder(context, 'Política de privacidad'),
        ),
      ],
    );
  }

  void _showPlaceholder(BuildContext context, String title) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: const Text(
          'Este contenido estará disponible en una versión futura.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

/// Créditos de los pictogramas (licencia obligatoria).
class _CreditsSection extends StatelessWidget {
  const _CreditsSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader('Créditos'),
        ListTile(
          title: Text('Pictogramas: Mulberry Symbols'),
          subtitle: Text('© Mulberry Project — licencia CC BY-SA 4.0'),
        ),
      ],
    );
  }
}

class _SettingsError extends ConsumerWidget {
  const _SettingsError();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      title: const Text('No se pudieron cargar los ajustes'),
      trailing: TextButton(
        onPressed: () => ref.invalidate(settingsProvider),
        child: const Text('Reintentar'),
      ),
    );
  }
}
