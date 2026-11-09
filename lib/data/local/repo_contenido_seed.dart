import '../contracts/repos.dart';
import '../models/models.dart';
import 'json_seguro.dart';
import 'seed_store.dart';

/// Categorías y pictogramas desde `assets/seed/`.
class SeedPictogramRepo implements PictogramRepo {
  SeedPictogramRepo(this._store);

  final SeedStore _store;

  @override
  Future<List<Category>> categories() async {
    final cats = (await _store.list('categorias')).map(Category.fromMap);
    return cats.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<List<Pictogram>> pictogramsOf(String categoryId) async {
    final pictos = (await _store.list('pictogramas')).map(Pictogram.fromMap);
    return pictos.where((p) => p.categoryId == categoryId).toList();
  }

  @override
  Future<Pictogram?> pictogram(String id) async {
    final pictos = (await _store.list('pictogramas')).map(Pictogram.fromMap);
    return pictos.firstWhereOrNull((p) => p.id == id);
  }
}

/// Cuentos desde `assets/seed/`.
class SeedStoryRepo implements StoryRepo {
  SeedStoryRepo(this._store);

  final SeedStore _store;

  @override
  Future<List<Story>> stories() async =>
      (await _store.list('cuentos')).map(Story.fromMap).toList();

  @override
  Future<Story?> story(String id) async =>
      (await stories()).firstWhereOrNull((s) => s.id == id);
}
