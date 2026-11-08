import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/section_header.dart';
import '../onboarding/profile_controller.dart';
import 'ajustes_avatar_opcion.dart';

/// Enlaces legales: los abre el agente padre (Ola 2).
/// Sección "Tu avatar": el niño elige un picto que le representa (plan 00
/// §5.2). Selección persistida en el perfil local, sin PII.
class AvatarSection extends ConsumerWidget {
  const AvatarSection({super.key});

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
                AvatarOption(
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
