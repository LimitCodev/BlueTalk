import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../data/models/models.dart';

/// Todos los pictogramas, cargados una sola vez para los juegos.
///
/// Memoria usa los pictos como contenido de las parejas y Cuentos como
/// picto clave de cada página; cabe entero en memoria (muestra: 42) y se
/// cachea en un único FutureProvider para no repetir cargas de assets.
final pictosProvider = FutureProvider<List<Pictogram>>((ref) async {
  final repo = ref.watch(pictogramRepoProvider);
  final categories = await repo.categories();
  final lists = await Future.wait([
    for (final category in categories) repo.pictogramsOf(category.id),
  ]);
  return [for (final list in lists) ...list];
});

/// Los 3 cuentos seed (offline, con caché).
final cuentosSeedProvider = FutureProvider<List<Story>>(
  (ref) => ref.watch(storyRepoProvider).stories(),
);
