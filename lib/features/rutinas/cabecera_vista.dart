import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rutinas_controller.dart';

/// Cabecera de las vistas de Rutinas: «Volver» y título, siempre iguales.
class CabeceraVista extends ConsumerWidget {
  const CabeceraVista({super.key, required this.titulo, this.onVolver});

  final String titulo;

  /// Por defecto vuelve al inicio de Rutinas.
  final VoidCallback? onVolver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
            onPressed:
                onVolver ?? ref.read(rutinasProvider.notifier).irAlInicio,
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
