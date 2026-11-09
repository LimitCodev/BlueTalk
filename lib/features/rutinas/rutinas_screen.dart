import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../padre/control/control_parental.dart';
import '../padre/control/juegos_gate.dart';
import 'estadisticas_view.dart';
import 'horario_view.dart';
import 'primero_luego_view.dart';
import 'rutinas_controller.dart';
import 'seccion_card.dart';
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
      RutinaVista.primeroLuego => const PrimeroLuegoView(),
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
        SeccionCard(
          vista: RutinaVista.horario,
          icono: Icons.schedule,
          titulo: 'Mi horario',
          subtitulo: 'Mira tus actividades de hoy y márcalas como hechas.',
        ),
        SeccionCard(
          vista: RutinaVista.primeroLuego,
          icono: Icons.looks_two_outlined,
          titulo: 'Primero y luego',
          subtitulo: 'Mira qué haces ahora y qué haces después.',
        ),
        SeccionCard(
          vista: RutinaVista.bienestar,
          icono: Icons.favorite_outline,
          titulo: 'Mi día',
          subtitulo: 'Elige cómo te sientes y revisa tus hábitos.',
        ),
        SeccionCard(
          vista: RutinaVista.colegio,
          icono: Icons.school_outlined,
          titulo: 'Mi colegio',
          subtitulo: 'Mira cómo es mi llegada al colegio.',
        ),
        SeccionCard(
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
