import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comunicador_catalog.dart';

/// Error de carga de assets (plan 02 §8): aviso literal + reintento.
class CatalogError extends ConsumerWidget {
  const CatalogError({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('No se pudieron cargar los pictogramas.'),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref.invalidate(catalogProvider),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
