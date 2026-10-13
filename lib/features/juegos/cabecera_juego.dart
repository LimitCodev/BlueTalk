import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'juegos_controller.dart';

/// Cabecera de un juego con botón "Volver" (≥48dp) al inicio de juegos.
class CabeceraJuego extends ConsumerWidget {
  const CabeceraJuego(this.titulo, {super.key});

  final String titulo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed: () => ref.read(juegosProvider.notifier).irAlInicio(),
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
