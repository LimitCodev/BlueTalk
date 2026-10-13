import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/contracts/repos.dart';
import '../../data/models/models.dart';

/// Catálogo completo del comunicador: categorías + todos sus pictogramas.
///
/// Cabe entero en memoria (muestra actual: 42 pictos) y se cachea en un
/// único FutureProvider, así el grid, el buscador y los favoritos leen de
/// aquí sin repetir cargas de assets.
class Catalog {
  Catalog({required this.categories, required this.pictograms})
      : _byId = {for (final picto in pictograms) picto.id: picto};

  final List<Category> categories;
  final List<Pictogram> pictograms;
  final Map<String, Pictogram> _byId;

  static Future<Catalog> load(PictogramRepo repo) async {
    final categories = await repo.categories();
    final lists = await Future.wait([
      for (final category in categories) repo.pictogramsOf(category.id),
    ]);
    return Catalog(
      categories: categories,
      pictograms: [for (final list in lists) ...list],
    );
  }

  List<Pictogram> pictogramsOf(String categoryId) => [
        for (final picto in pictograms)
          if (picto.categoryId == categoryId) picto,
      ];

  Pictogram? pictogramById(String id) => _byId[id];

  /// Asset del icono de la categoría; null si el picto no existe.
  String? iconAssetOf(Category category) => _byId[category.icon]?.asset;
}

/// Categorías y pictogramas desde los seeds (offline, con caché).
final catalogProvider = FutureProvider<Catalog>(
  (ref) => Catalog.load(ref.watch(pictogramRepoProvider)),
);
