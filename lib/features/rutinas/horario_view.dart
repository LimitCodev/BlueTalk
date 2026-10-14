import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/models.dart';
import 'actividad_tile.dart';
import 'rutinas_controller.dart';
import 'rutinas_providers.dart';

/// Vista del niño: "Actividades por día" con banner de la siguiente
/// actividad y lista con estado hecha/pendiente (plan 04 §1).
class HorarioView extends ConsumerWidget {
  const HorarioView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final horario = ref.watch(horarioProvider);

    return switch (horario) {
      AsyncData(:final value) => _HorarioLista(entradas: value),
      AsyncError() => const Center(
          child: Text('No se pudo cargar el horario.'),
        ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _HorarioLista extends ConsumerWidget {
  const _HorarioLista({required this.entradas});

  final List<ScheduleEntry> entradas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entradas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Todavía no hay actividades en tu horario.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        const _CabeceraHorario(),
        const BannerSiguienteActividad(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: entradas.length,
            itemBuilder: (context, index) {
              final entry = entradas[index];
              return _TileHoy(entry: entry);
            },
          ),
        ),
      ],
    );
  }
}

/// Fila que resuelve si la actividad está hecha hoy.
class _TileHoy extends ConsumerWidget {
  const _TileHoy({required this.entry});

  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hechas = ref.watch(hechasHoyProvider).value ?? const <String>{};
    return ActividadTile(entry: entry, hecha: hechas.contains(entry.id));
  }
}

/// Cabecera con "Volver" y el botón de edición para persona adulta.
class _CabeceraHorario extends ConsumerWidget {
  const _CabeceraHorario();

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
              'Mi horario',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          // Edición del horario: función de persona adulta; el gate PIN del
          // modo padre se cablea en la Ola 2b (ver informe).
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Editar horario (personas adultas)',
            onPressed: () =>
                ref.read(rutinasProvider.notifier).abrir(RutinaVista.editor),
          ),
        ],
      ),
    );
  }
}

/// Aviso in-app de la siguiente actividad (plan 04 §1, MVP sin
/// notificaciones del sistema). Se muestra en el inicio y en el horario.
class BannerSiguienteActividad extends ConsumerWidget {
  const BannerSiguienteActividad({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proxima = ref.watch(proximaActividadProvider).value;

    if (proxima == null) return const SizedBox.shrink();

    final t = Theme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              color: AppColors.primaryStrong),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Siguiente actividad: ${proxima.title} '
              'a las ${formatHora(proxima.timeMinutes)}',
              style: t.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección "Cómo va el día": hechas vs. total (plan 04 §4, resumen junto
/// al horario).
class DiaHoySection extends ConsumerWidget {
  const DiaHoySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumen = ref.watch(resumenUsoProvider).value;
    if (resumen == null || resumen.actividadesHoy == 0) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Mi día'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Actividades hechas hoy: ${resumen.hechasHoy} de '
            '${resumen.actividadesHoy}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: BarraDia(
            valor: resumen.actividadesHoy == 0
                ? 0
                : resumen.hechasHoy / resumen.actividadesHoy,
            etiqueta: '${resumen.hechasHoy} de ${resumen.actividadesHoy} '
                'actividades hechas hoy',
          ),
        ),
      ],
    );
  }
}

/// Barra de avance hecha en Flutter (sin librerías de gráficas), con
/// semántica para lectores de pantalla y sin animación (Modo calma).
class BarraDia extends StatelessWidget {
  const BarraDia({super.key, required this.valor, required this.etiqueta});

  final double valor;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      value: etiqueta,
      child: Container(
        height: 12,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFDCEEF7),
          borderRadius: BorderRadius.circular(6),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: valor.clamp(0.0, 1.0),
          child: const ColoredBox(color: AppColors.primaryStrong),
        ),
      ),
    );
  }
}
