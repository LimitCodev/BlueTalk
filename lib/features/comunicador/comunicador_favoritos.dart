import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import 'picto_tile.dart';
import 'comunicador_acciones.dart';

/// Pictogramas fijados en el inicio, en fila horizontal (lazy).
class FavoritesSection extends ConsumerWidget {
  const FavoritesSection({super.key, required this.pictos});

  final List<Pictogram> pictos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 116,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: pictos.length,
        itemBuilder: (context, index) {
          final picto = pictos[index];
          return SizedBox(
            width: 100,
            child: PictoTile(
              pictogram: picto,
              favorited: true,
              onTap: () => onPictoTap(context, ref, picto),
              onLongPress: () => onPictoLongPress(context, ref, picto),
            ),
          );
        },
      ),
    );
  }
}
