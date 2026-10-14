import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/calm_mode.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/models.dart';
import '../ajustes/settings_controller.dart';
import '../rutinas/actividad_tile.dart';
import '../rutinas/rutinas_controller.dart';
import 'salud_providers.dart';

/// Disclaimer de salud (plan 04 §2): visible en la cabecera de la sección.
const String disclaimerSalud =
    'Esta app no reemplaza evaluación profesional. Consulta a tu especialista.';

/// Sección de bienestar del niño (plan 04 §2): check-in emocional, hábitos
/// del día y modo sensorial.
///
/// Se muestra dentro de la vista "bienestar" de la pestaña Rutinas; los
/// componentes también son exportables por si el coordinador quiere una
/// ruta propia.
class SaludScreen extends ConsumerWidget {
  const SaludScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context);

    return Column(
      children: [
        const _CabeceraSalud(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              _DisclaimerBanner(textStyle: t.textTheme.bodySmall),
              const SectionHeader('¿Cómo te sientes hoy?'),
              const _CheckInEmocional(),
              const SectionHeader('Mis hábitos de hoy'),
              const _HabitosDelDia(),
              const SectionHeader('Modo sensorial'),
              const CalmModeToggle(),
              const _VozRapida(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cabecera con "Volver" al inicio de Rutinas.
class _CabeceraSalud extends ConsumerWidget {
  const _CabeceraSalud();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => ref.read(rutinasProvider.notifier).irAlInicio(),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Volver'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Mi día',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Banda de disclaimer siempre visible sobre el contenido de salud.
class DisclaimerSaludBanner extends StatelessWidget {
  const DisclaimerSaludBanner({super.key, this.textStyle});

  final TextStyle? textStyle;

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
          const Icon(Icons.health_and_safety_outlined,
              color: AppColors.onWarning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              disclaimerSalud,
              style: textStyle?.copyWith(color: AppColors.onWarning),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisclaimerBanner extends StatelessWidget {
  const _DisclaimerBanner({required this.textStyle});

  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) =>
      DisclaimerSaludBanner(textStyle: textStyle);
}

/// Rejilla de emociones: tocar registra el check-in del día.
class _CheckInEmocional extends ConsumerWidget {
  const _CheckInEmocional();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hoy = ref.watch(emocionDeHoyProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hoy != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Hoy te sientes: ${_labelDeMood(hoy.mood)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final opcion in opcionesEmocion)
                _EmocionTile(
                  opcion: opcion,
                  seleccionada: hoy?.mood == opcion.mood,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _labelDeMood(int mood) {
    for (final opcion in opcionesEmocion) {
      if (opcion.mood == mood) return opcion.label;
    }
    return '';
  }
}

/// Opción de emoción: círculo táctil de 56dp (≥48) con picto y etiqueta.
class _EmocionTile extends ConsumerWidget {
  const _EmocionTile({required this.opcion, required this.seleccionada});

  final OpcionEmocion opcion;
  final bool seleccionada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      button: true,
      selected: seleccionada,
      label: 'Me siento ${opcion.label}',
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => registrarEmocion(ref, opcion),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: seleccionada
                ? AppColors.primary.withValues(alpha: 0.35)
                : Colors.transparent,
            border: Border.all(
              color:
                  seleccionada ? AppColors.primaryStrong : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PictoMini(opcion.pictoId, size: 44),
              const SizedBox(height: 4),
              Text(
                opcion.label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Checklist diaria de hábitos con pictos (plan 04 §2).
class _HabitosDelDia extends ConsumerWidget {
  const _HabitosDelDia();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final marcados = ref.watch(habitosHoyProvider).value ?? const <String>{};

    return Column(
      children: [
        for (final habito in semillaHabitos)
          ListTile(
            leading: PictoMini(habito.pictoId),
            title: Text(habito.title),
            trailing: Checkbox(
              value: marcados.contains(habito.id),
              onChanged: (_) => alternarHabito(ref, habito),
            ),
            onTap: () => alternarHabito(ref, habito),
          ),
      ],
    );
  }
}

/// Acceso rápido a la velocidad de la voz (reutiliza `settingsProvider`;
/// no duplica la lógica de Ajustes, solo la muestra aquí).
class _VozRapida extends ConsumerWidget {
  const _VozRapida();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(settingsProvider);
    final settings = asyncSettings.value ?? const AppSettings();
    final enabled = asyncSettings.hasValue;

    return ListTile(
      title: const Text('Velocidad de la voz'),
      subtitle: Slider(
        value: settings.ttsRate,
        min: 0.2,
        max: 0.9,
        divisions: 7,
        label: 'Velocidad ${settings.ttsRate.toStringAsFixed(1)}',
        onChanged: enabled
            ? (value) => ref.read(settingsProvider.notifier).setTtsRate(value)
            : null,
      ),
    );
  }
}
