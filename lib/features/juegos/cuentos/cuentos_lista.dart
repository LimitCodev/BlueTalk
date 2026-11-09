import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../juegos_catalog.dart';
import 'cuentos_controller.dart';
import 'cuentos_pictos.dart';

/// Lista de los 3 cuentos seed; los completados muestran una estrella.
class ListaCuentos extends ConsumerWidget {
  const ListaCuentos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentos = ref.watch(cuentosSeedProvider);
    final pictos = ref.watch(pictosProvider).value ?? const [];
    final completados =
        ref.watch(cuentosProvider).value?.completados ?? const {};

    return switch (cuentos) {
      AsyncData(:final value) => ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: value.length,
        itemBuilder: (context, index) {
          final cuento = value[index];
          final completado = completados.contains(cuento.id);
          return Card(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () =>
                  ref.read(cuentosProvider.notifier).abrirCuento(cuento.id),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      PictoChico(
                        asset: pictoAssetDe(pictos, cuento.coverPictoId),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cuento.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      if (completado)
                        Icon(
                          Icons.star,
                          color: context.colores.primaryStrong,
                          semanticLabel: 'Cuento completado',
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      AsyncError() => const Center(
        child: Text('No se pudieron cargar los cuentos.'),
      ),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
