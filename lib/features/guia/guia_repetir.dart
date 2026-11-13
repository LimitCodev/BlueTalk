import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'guia_controller.dart';

/// «Ver la guía otra vez» (plan 14B §4.5): sin código, empieza en el paso 1.
/// La capa de la guía lleva al menú.
class RepetirGuiaTile extends ConsumerWidget {
  const RepetirGuiaTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.tour_outlined),
      title: const Text('Ver la guía otra vez'),
      subtitle: const Text('El ave de BlueTalk enseña la app paso a paso.'),
      trailing: const Icon(Icons.chevron_right),
      onTap: ref.read(guiaProvider.notifier).iniciar,
    );
  }
}
