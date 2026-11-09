import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../juegos_catalog.dart';
import 'cuentos_controller.dart';

/// Cabecera del lector: "Volver" a la lista + título del cuento.
class CabeceraCuentos extends ConsumerWidget {
  const CabeceraCuentos({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentos = ref.watch(cuentosSeedProvider).value ?? const [];
    String titulo = storyId;
    for (final cuento in cuentos) {
      if (cuento.id == storyId) titulo = cuento.title;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => ref.read(cuentosProvider.notifier).irALista(),
            icon: const Icon(Icons.chevron_left),
            label: const Text('Volver'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              titulo,
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
