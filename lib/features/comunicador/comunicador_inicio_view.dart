import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../guia/guia_objetivos.dart';
import '../guia/guia_pasos.dart';
import 'comunicador_categoria_grid.dart';
import 'comunicador_resultados.dart';
import 'comunicador_catalog.dart';
import 'comunicador_controller.dart';
import 'comunicador_prefs.dart';
import 'comunicador_buscador.dart';
import 'comunicador_catalogo_error.dart';
import 'comunicador_favoritos.dart';

/// Inicio del comunicador: buscador, favoritos y rejilla de categorías.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider);

    return switch (catalog) {
      AsyncData(:final value) => HomeContent(catalog: value),
      AsyncError() => const CatalogError(),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class HomeContent extends ConsumerWidget {
  const HomeContent({super.key, required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(comunicadorProvider);

    if (view.query.isNotEmpty) {
      return Column(
        children: [
          const SearchField(),
          Expanded(
            child: SearchResults(catalog: catalog, query: view.query),
          ),
        ],
      );
    }

    final favorites = ref.watch(favoritesProvider);
    final favoritePictos = [
      for (final picto in catalog.pictograms)
        if (favorites.contains(picto.id)) picto,
    ];

    return Column(
      children: [
        const SearchField(),
        if (favoritePictos.isNotEmpty)
          FavoritesSection(pictos: favoritePictos)
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Mantén presionado un pictograma para fijarlo en el inicio.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: GuiaAncla(
            objetivo: GuiaObjetivo.categorias,
            child: CategoryGrid(catalog: catalog),
          ),
        ),
      ],
    );
  }
}
