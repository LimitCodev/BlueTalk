import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';
import 'comunicador_prefs.dart';
import 'picto_tile.dart';
import 'comunicador_acciones.dart';

/// Rejilla de pictogramas; tocar agrega a la frase y habla (bajo tap),
/// mantener presionado fija o desfija el picto en el inicio.
class PictoGrid extends ConsumerWidget {
  const PictoGrid({
    super.key,
    required this.pictograms,
    required this.emptyText,
    this.categoria,
    this.colorDe,
  });

  final List<Pictogram> pictograms;
  final String emptyText;

  /// Tono de la categoría cuando toda la rejilla es de una sola; en
  /// Inicio o en la búsqueda las tarjetas quedan neutras.
  final ColoresCategoria? categoria;

  /// Tono por pictograma (clase gramatical); manda sobre [categoria].
  final ColoresCategoria? Function(Pictogram)? colorDe;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pictograms.isEmpty) {
      return Center(child: Text(emptyText));
    }

    final favorites = ref.watch(favoritesProvider);

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 128,
        // 112 desbordaba con etiquetas de 2 líneas (52 de icono + 6 +
        // 2×22 de texto = 102 > 100 útiles tras el padding). 120 deja
        // margen también con el textScaler del sistema.
        mainAxisExtent: 120,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: pictograms.length,
      itemBuilder: (context, index) {
        final picto = pictograms[index];
        return PictoTile(
          pictogram: picto,
          categoria: colorDe?.call(picto) ?? categoria,
          favorited: favorites.contains(picto.id),
          onTap: () => onPictoTap(context, ref, picto),
          onLongPress: () => onPictoLongPress(context, ref, picto),
        );
      },
    );
  }
}
