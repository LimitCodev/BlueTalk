import '../contracts/repos.dart';
import '../models/models.dart';
import 'json_seguro.dart';
import 'seed_store.dart';

/// Categorías y pictogramas desde `assets/seed/`.
///
/// El catálogo se convierte a objetos **una sola vez** y se indexa por
/// categoría e id: antes cada `pictogramsOf` recorría y reconstruía los
/// ~234 pictos (PERF-CORE-03 de la auditoría de rendimiento).
class SeedPictogramRepo implements PictogramRepo {
  SeedPictogramRepo(this._store);

  final SeedStore _store;
  Future<List<Category>>? _categorias;
  Future<List<Pictogram>>? _todos;
  Map<String, List<Pictogram>> _porCategoria = const {};
  Map<String, Pictogram> _porId = const {};

  @override
  Future<List<Category>> categories() => _categorias ??= _leerCategorias();

  Future<List<Category>> _leerCategorias() async {
    final cats = (await _store.list('categorias')).map(Category.fromMap);
    return cats.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  Future<List<Pictogram>> _leerTodos() async {
    final pictos = (await _store.list(
      'pictogramas',
    )).map(Pictogram.fromMap).toList(growable: false);
    _porId = {for (final picto in pictos) picto.id: picto};
    final porCategoria = <String, List<Pictogram>>{};
    for (final picto in pictos) {
      (porCategoria[picto.categoryId] ??= []).add(picto);
    }
    _porCategoria = porCategoria;
    return pictos;
  }

  @override
  Future<List<Pictogram>> pictogramsOf(String categoryId) async {
    await (_todos ??= _leerTodos());
    // Copia defensiva: el llamador puede ordenar su tablero sin alterar
    // el índice compartido.
    return List.of(_porCategoria[categoryId] ?? const []);
  }

  @override
  Future<Pictogram?> pictogram(String id) async {
    await (_todos ??= _leerTodos());
    return _porId[id];
  }
}

/// Cuentos desde `assets/seed/`.
class SeedStoryRepo implements StoryRepo {
  SeedStoryRepo(this._store);

  final SeedStore _store;
  Future<List<Story>>? _todos;

  @override
  Future<List<Story>> stories() => _todos ??= _leerTodos();

  Future<List<Story>> _leerTodos() async =>
      (await _store.list('cuentos')).map(Story.fromMap).toList();

  @override
  Future<Story?> story(String id) async =>
      (await stories()).firstWhereOrNull((s) => s.id == id);
}
