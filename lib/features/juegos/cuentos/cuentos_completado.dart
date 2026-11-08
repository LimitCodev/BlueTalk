import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cuentos_controller.dart';

/// "¡Cuento completado! 🎉" con la salida al lector o a la lista.
class CuentoCompletado extends ConsumerWidget {
  const CuentoCompletado({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Cuento completado! 🎉',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: () => ref.read(cuentosProvider.notifier).reiniciar(),
              child: const Text('Leer el cuento otra vez'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size(64, 48)),
              onPressed: () => ref.read(cuentosProvider.notifier).irALista(),
              child: const Text('Volver a los cuentos'),
            ),
          ],
        ),
      ),
    );
  }
}
