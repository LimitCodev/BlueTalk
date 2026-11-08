import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/calm_mode.dart';
import 'settings_controller.dart';
import 'ajustes_avatar.dart';
import 'ajustes_info.dart';
import 'ajustes_recordatorios.dart';
import 'ajustes_tema.dart';
import 'ajustes_texto.dart';
import 'ajustes_voz.dart';

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
        const TemaSection(),
        const Divider(),
        switch (settings) {
          AsyncData(:final value) => TextScaleSection(settings: value),
          AsyncError() => const SettingsError(),
          _ => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        },
        const Divider(),
        const TtsSection(),
        const Divider(),
        const RecordatoriosSection(),
        const AvatarSection(),
        const Divider(),
        const ZonaAdultosSection(),
        const Divider(),
        const LegalSection(),
        const Divider(),
        const CreditsSection(),
      ],
    );
  }
}

class SettingsError extends ConsumerWidget {
  const SettingsError({super.key});

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
