import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/plataforma/edicion.dart';
import '../../../core/widgets/section_header.dart';
import '../../onboarding/profile_controller.dart';
import '../perfil_edad.dart';
import 'control_nombre_dialogo.dart';
import 'perfil_edad_dialogo.dart';

/// Datos del niño o niña en Control: apodo (plan 14A §A4) y perfil de edad.
class SeccionNino extends ConsumerWidget {
  const SeccionNino({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apodo = ref.watch(profileProvider)?.nickname.trim() ?? '';
    final perfilEdad = ref.watch(perfilEdadProvider);
    final directa = ref.watch(edicionDirectaProvider);
    return Column(
      children: [
        const SectionHeader('Perfil del niño'),
        ListTile(
          leading: const Icon(Icons.badge_outlined),
          title: const Text('Nombre del niño o niña'),
          subtitle: Text(apodo.isEmpty ? 'Sin apodo' : apodo),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const NombreDialogo(),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.child_care_outlined),
          title: const Text('Perfil de edad'),
          subtitle: Text(
            perfilEdad == PerfilEdad.ninguno
                ? 'Sin perfil: se ve todo. Elige la edad para ocultar '
                      'categorías del comunicador que no son de esa edad.'
                : '${perfilEdad.titulo}. Se ven las categorías de esa edad'
                      '${directa ? ' y el filtro de páginas usa los grupos que corresponden' : ''}.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const PerfilEdadDialogo(),
          ),
        ),
      ],
    );
  }
}
