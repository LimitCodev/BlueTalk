import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../padre/control/control_parental.dart';
import '../padre/control/juegos_gate.dart';
import 'editor_horario_view.dart';
import 'estadisticas_view.dart';
import 'horario_view.dart';
import 'rutinas_controller.dart';
import '../entorno/entorno_screen.dart';
import '../salud/salud_screen.dart';

/// Pestaña "Rutinas" del shell: horario del niño, bienestar, entorno y
/// estadísticas (plan 04).
///
/// Autocontenida como JuegosScreen/ComunicadorScreen: su navegación
/// (inicio, horario, editor, bienestar, colegio) es interna, sin rutas
/// propias. El shell pone el Scaffold, el AppBar y la NavigationBar.
class RutinasScreen extends ConsumerWidget {
  const RutinasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(rutinasProvider);

    return switch (vista) {
      RutinaVista.inicio => const _HomeView(),
      RutinaVista.horario => const HorarioView(),
      RutinaVista.editor => const EditorHorarioView(),
      RutinaVista.bienestar => const SaludScreen(),
      RutinaVista.colegio => const _VistaColegio(),
      RutinaVista.estadisticas => const EstadisticasView(),
    };
  }
}

/// Colegio: si un adulto lo bloqueó desde Control, muestra el panel suave
/// en vez de la pantalla (plan 05 §4).
class _VistaColegio extends ConsumerWidget {
  const _VistaColegio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(bloqueosProvider).entorno) return const EntornoScreen();

    return PanelSuave(
      icono: Icons.lock_outline,
      titulo: 'La sección Mi colegio está bloqueada por un adulto.',
      texto: 'Pide que te la desbloqueen desde la zona de adultos.',
      botones: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => ref.read(rutinasProvider.notifier).irAlInicio(),
          child: const Text('Volver'),
        ),
      ],
    );
  }
}

/// Inicio: banner de siguiente actividad, tarjetas de secciones y resumen
/// del día (plan 04 §1 y §4).
class _HomeView extends ConsumerWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: const [
        BannerSiguienteActividad(),
        _SeccionCard(
          vista: RutinaVista.horario,
          icono: Icons.schedule,
          titulo: 'Mi horario',
          subtitulo: 'Mira tus actividades de hoy y márcalas como hechas.',
        ),
        _SeccionCard(
          vista: RutinaVista.bienestar,
          icono: Icons.favorite_outline,
          titulo: 'Mi día',
          subtitulo: 'Elige cómo te sientes y revisa tus hábitos.',
        ),
        _SeccionCard(
          vista: RutinaVista.colegio,
          icono: Icons.school_outlined,
          titulo: 'Mi colegio',
          subtitulo: 'Datos de mi escuela (demostración) y mi llegada.',
        ),
        _SeccionCard(
          vista: RutinaVista.estadisticas,
          icono: Icons.bar_chart,
          titulo: 'Mis estadísticas',
          subtitulo: 'Lo que has usado estos días.',
        ),
        DiaHoySection(),
      ],
    );
  }
}

/// Tarjeta de una sección: targets ≥48dp, literal, sin metáforas.
class _SeccionCard extends ConsumerWidget {
  const _SeccionCard({
    required this.vista,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  final RutinaVista vista;
  final IconData icono;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => ref.read(rutinasProvider.notifier).abrir(vista),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 72),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colores.primary.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icono, color: context.colores.primaryStrong),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
