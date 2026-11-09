import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/contracts/repos.dart';
import '../../data/models/models.dart';
import '../padre/perfil_edad.dart';

/// Catálogo completo del comunicador: categorías + todos sus pictogramas.
///
/// Cabe entero en memoria (unos 240 pictos) y se cachea en un
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
    // El tablero nuclear es memoria motora: su orden sale solo de `order`.
    for (var i = 0; i < categories.length; i++) {
      if (categories[i].nuclear) {
        lists[i].sort((a, b) => a.order!.compareTo(b.order!));
      }
    }
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
///
/// Si la persona adulta eligió un perfil de edad (fase 3b), se ocultan las
/// categorías que no son de esa edad. Se **ocultan**, no se borran: los
/// pictogramas guardados en una frase o en favoritos siguen resolviéndose
/// con normalidad. El tablero nuclear nunca se oculta: comunicar no depende
/// de la edad.
final catalogProvider = FutureProvider<Catalog>((ref) async {
  final catalogo = await Catalog.load(ref.watch(pictogramRepoProvider));
  final perfil = ref.watch(perfilEdadProvider);
  if (perfil.categorias.isEmpty) return catalogo;
  return Catalog(
    categories: [
      for (final categoria in catalogo.categories)
        if (categoria.nuclear || perfil.seVe(categoria.id)) categoria,
    ],
    pictograms: catalogo.pictograms,
  );
});
