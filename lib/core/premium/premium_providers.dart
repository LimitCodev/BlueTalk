import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'derechos.dart';
import 'plan.dart';
import 'tienda.dart';

/// Puerta única del freemium: las pantallas preguntan aquí, nunca a la
/// tienda ni a Play directamente. En tests se sobreescribe
/// [fuenteDerechosProvider] con `DerechosFijos(Plan.premium)`.
final fuenteDerechosProvider =
    Provider<FuenteDerechos>((ref) => const DerechosFijos());

final tiendaComprasProvider =
    Provider<TiendaCompras>((ref) => const TiendaNoDisponible());

final planProvider = FutureProvider<Plan>(
  (ref) => ref.watch(fuenteDerechosProvider).plan(),
);

/// `true` si el plan actual incluye [Funcion]. Mientras el plan se lee, o
/// si falla, se trata como gratis: nunca se regala un extra por error, y
/// lo gratis no depende de esto.
final puedeUsarProvider = Provider.family<bool, Funcion>((ref, funcion) {
  final plan = ref.watch(planProvider).value ?? Plan.gratis;
  return funcion.disponibleEn(plan);
});
