import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/calm_mode.dart';
import '../../../core/widgets/section_header.dart';
import '../../rutinas/editor_horario_view.dart';
import 'voz_diagnostico.dart';

/// Secciones «Horario» y «Pantalla y voz» de Control.
class SeccionesRutinaYVoz extends StatelessWidget {
  const SeccionesRutinaYVoz({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Horario'),
        ListTile(
          leading: const Icon(Icons.edit_calendar_outlined),
          title: const Text('Editar horario'),
          subtitle: const Text('Crea, cambia o quita las actividades del día.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: SafeArea(child: EditorHorarioView()),
              ),
            ),
          ),
        ),
        const SectionHeader('Pantalla y voz'),
        const CalmModeToggle(),
        ListTile(
          leading: const Icon(Icons.text_fields_outlined),
          title: const Text('Tamaño de texto y velocidad de voz'),
          subtitle: const Text('Se cambian en la pestaña Ajustes.'),
          trailing: const Icon(Icons.chevron_right),
          // Enlace real a Ajustes: la app no duplica esa lógica aquí.
          onTap: () => GoRouter.maybeOf(context)?.go('/home/ajustes'),
        ),
        ListTile(
          leading: const Icon(Icons.record_voice_over_outlined),
          title: const Text('Probar la voz'),
          subtitle: const Text('¿No se oye? Comprueba el sonido aquí.'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const VozDiagnosticoScreen()),
          ),
        ),
      ],
    );
  }
}
