import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/colores_gramatica.dart';
import 'comunicador_catalog.dart';
import 'comunicador_catalogo_error.dart';
import 'comunicador_picto_grid.dart';

/// Vista de una categoría: rejilla de sus pictogramas (lazy).
class CategoryView extends ConsumerWidget {
  const CategoryView({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return switch (catalog) {
      AsyncData(:final value) => PictoGrid(
        pictograms: value.pictogramsOf(categoryId),
        emptyText: 'Esta categoría todavía no tiene pictogramas.',
        // La web tiñe los pictogramas con el tono de su categoría
        // (docs/branding/WEB-EXTRACCION.md §2); la app hace lo mismo.
        categoria: coloresCategorias[categoryId],
        colorDe: (picto) => coloresDeClase(picto.clase),
      ),
      AsyncError() => const CatalogError(),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}
