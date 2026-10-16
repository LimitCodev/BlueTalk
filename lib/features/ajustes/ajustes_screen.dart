import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_avatar.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/calm_mode.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/models.dart';
import '../onboarding/profile_controller.dart';
import 'settings_controller.dart';
import '../rutinas/recordatorios/recordatorios_controller.dart';

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
        const _RecordatoriosSection(),
        const _AvatarSection(),
        const Divider(),
        const _ZonaAdultosSection(),
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

/// Explicación literal previa a pedir el permiso de notificaciones
/// (plan 1.1): nunca se pide al arrancar, solo desde Ajustes.
/// Devuelve `true` si el usuario quiere continuar al permiso del sistema.
Future<bool> _explicarPermisoRecordatorios(BuildContext context) async {
  final continuar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Activar recordatorios'),
      content: const Text(
        'BlueTalk avisará cada día de la próxima actividad del niño. '
        'Después Android te pedirá su permiso para mostrar los avisos.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Activar recordatorios'),
        ),
      ],
    ),
  );
  return continuar ?? false;
}

/// Recordatorios de rutina (plan 1.1): interruptor de `remindersEnabled`
/// y permiso de avisos pedido siempre con explicación literal previa.
class _RecordatoriosSection extends ConsumerWidget {
  const _RecordatoriosSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final ajustes = asyncSettings.value;
    final activos = ajustes?.remindersEnabled ?? false;
    final permitido = ref.watch(notificacionesPermitidasProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Recordatorios'),
        // Con los ajustes ilegibles el interruptor no puede funcionar:
        // se explica en su sitio en vez de dejar un muñón silencioso
        // (revisión fase 1, BAJA).
        if (asyncSettings.hasError)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No se pueden cambiar los recordatorios ahora.'),
          )
        else
          SwitchListTile(
            title: const Text('Recordatorios de rutina'),
            subtitle: const Text('Avisa cada día de la próxima actividad.'),
            value: activos,
            onChanged: ajustes == null
                ? null
                : (valor) async {
                    if (!valor) {
                      await ref
                          .read(settingsProvider.notifier)
                          .setRemindersEnabled(false);
                      return;
                    }
                    // Encender: primero la explicación literal y después el
                    // permiso del sistema; nunca al arrancar (plan 1.1).
                    final continuar = await _explicarPermisoRecordatorios(
                      context,
                    );
                    if (!continuar || !context.mounted) return;
                    final concedido = await ref
                        .read(recordatoriosProvider.notifier)
                        .pedirPermisoNotificaciones();
                    // El permiso puede haber cambiado fuera de la app.
                    ref.invalidate(notificacionesPermitidasProvider);
                    if (concedido) {
                      if (!context.mounted) return;
                      await ref
                          .read(settingsProvider.notifier)
                          .setRemindersEnabled(true);
                    } else if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se dio permiso. Los recordatorios no se activaron.',
                          ),
                        ),
                      );
                    }
                  },
          ),
        if (activos && permitido.value == false)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Android necesita tu permiso para mostrar los avisos.',
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  onPressed: () async {
                    final continuar = await _explicarPermisoRecordatorios(
                      context,
                    );
                    if (!continuar || !context.mounted) return;
                    final concedido = await ref
                        .read(recordatoriosProvider.notifier)
                        .pedirPermisoNotificaciones();
                    ref.invalidate(notificacionesPermitidasProvider);
                    if (!concedido && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'No se concedió. Actívalo en los ajustes de Android.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Activar recordatorios'),
                ),
              ],
            ),
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
/// Sección "Tu avatar": el niño elige un picto que le representa (plan 00
/// §5.2). Selección persistida en el perfil local, sin PII.
class _AvatarSection extends ConsumerWidget {
  const _AvatarSection();

  /// Candidatos curados de los seeds: gestos, familia y objetos amigables.
  static const _candidatos = <(String, String)>[
    ('happy_man', 'Feliz'),
    ('baby', 'Bebé'),
    ('cat', 'Gato'),
    ('dog', 'Perro'),
    ('bird', 'Pájaro'),
    ('fish', 'Pez'),
    ('sun', 'Sol'),
    ('ball', 'Pelota'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seleccion = ref.watch(profileProvider)?.avatarPicto ?? 'happy_man';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Tu avatar'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final (id, label) in _candidatos)
                _AvatarOption(
                  pictoId: id,
                  label: label,
                  selected: id == seleccion,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Opción de avatar: círculo táctil de 56dp (≥48 del plan 00 §5) con
/// borde fuerte cuando está seleccionada.
class _AvatarOption extends ConsumerWidget {
  const _AvatarOption({
    required this.pictoId,
    required this.label,
    required this.selected,
  });

  final String pictoId;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(avatarAssetProvider(pictoId)).value;

    return Tooltip(
      message: label,
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Avatar $label',
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () => ref.read(profileProvider.notifier).updateAvatar(pictoId),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
              border: Border.all(
                color: selected ? AppColors.primaryStrong : Colors.transparent,
                width: 3,
              ),
            ),
            child: asset == null
                ? const Icon(
                    Icons.child_care,
                    size: 30,
                    color: AppColors.primaryStrong,
                  )
                : SvgPicture.asset(asset, width: 40, height: 40),
          ),
        ),
      ),
    );
  }
}

/// Acceso discreto a la zona de adultos: el PIN lo pide el gate, no aquí.
class _ZonaAdultosSection extends StatelessWidget {
  const _ZonaAdultosSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Zona de adultos'),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Modo padre'),
          subtitle: const Text('Resumen, control y legal. Pide tu código.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/padre'),
        ),
      ],
    );
  }
}

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
