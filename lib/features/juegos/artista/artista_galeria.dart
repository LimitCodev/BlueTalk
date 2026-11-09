import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/section_header.dart';
import 'artista_canvas.dart';
import 'artista_controller.dart';
import 'artista_dibujos.dart';

/// Galería local "Mis dibujos": miniaturas de los dibujos guardados.
class GaleriaLocal extends ConsumerWidget {
  const GaleriaLocal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dibujos = ref.watch(galeriaDibujosProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Mis dibujos'),
        if (dibujos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Todavía no has guardado dibujos. Dibuja y pulsa "Guardar".',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          SizedBox(
            height: 128,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: dibujos.length,
              itemBuilder: (context, index) {
                final dibujo = dibujos[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    children: [
                      InkWell(
                        key: ValueKey('dibujo_${dibujo.id}'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          ref
                              .read(artistaProvider.notifier)
                              .cargarDibujo(dibujo);
                          // La galería vive en una hoja inferior: al cargar
                          // el dibujo se cierra para volver a ver el lienzo.
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 96,
                          height: 72,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            border: Border.all(color: context.colores.primary),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: TrazosPainter(dibujo.trazos),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Borrar dibujo',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ref
                            .read(galeriaDibujosProvider.notifier)
                            .borrar(dibujo.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
