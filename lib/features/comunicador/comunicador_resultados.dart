import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'comunicador_catalog.dart';
import 'comunicador_picto_grid.dart';

/// Resultados del buscador sobre el catálogo completo.
class SearchResults extends ConsumerWidget {
  const SearchResults({super.key, required this.catalog, required this.query});

  final Catalog catalog;
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final needle = query.toLowerCase();
    final results = [
      for (final picto in catalog.pictograms)
        if (picto.label.toLowerCase().contains(needle) ||
            picto.keywords.any((word) => word.toLowerCase().contains(needle)))
          picto,
    ];

    if (results.isEmpty) {
      return Center(child: Text('No hay pictogramas para "$query".'));
    }

    return PictoGrid(
      pictograms: results,
      emptyText: 'No hay pictogramas para "$query".',
    );
  }
}
