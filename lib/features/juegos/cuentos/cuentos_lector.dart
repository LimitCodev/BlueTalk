import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/models.dart';
import '../juegos_catalog.dart';
import 'cuentos_controller.dart';
import 'cuentos_pictos.dart';

/// Lector de páginas: texto literal + pictos clave de la página.
class LectorCuento extends ConsumerWidget {
  const LectorCuento({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cuentosProvider).requireValue;
    final cuentos = ref.watch(cuentosSeedProvider).value ?? const [];
    final pictos = ref.watch(pictosProvider).value ?? const [];

    Story? cuento;
    for (final c in cuentos) {
      if (c.id == estado.storyId) cuento = c;
    }
    if (cuento == null) return const SizedBox.shrink();

    final texto = cuento.pages[estado.pagina];
    final claves = pictosClaveDePagina(
      texto,
      pictos,
      coverPictoId: cuento.coverPictoId,
    );
    final ultima = estado.pagina + 1 == cuento.pages.length;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  texto,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final picto in claves) PictoGrande(picto: picto),
                  ],
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          child: Text(
            'Página ${estado.pagina + 1} de ${cuento.pages.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Row(
            children: [
              if (estado.pagina > 0)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(64, 48),
                  ),
                  onPressed: () =>
                      ref.read(cuentosProvider.notifier).anterior(),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Anterior'),
                ),
              const Spacer(),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
                onPressed: () => ref.read(cuentosProvider.notifier).siguiente(),
                icon: Icon(ultima ? Icons.check : Icons.chevron_right),
                label: Text(ultima ? '¡Completar cuento!' : 'Siguiente'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
