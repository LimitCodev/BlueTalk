import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../data/models/models.dart';
import '../avance_juegos.dart';
import '../juegos_catalog.dart';

/// Semilla de las opciones del cuento; sobreescribible en tests.
final cuentosRandomProvider = Provider<Random>((ref) => Random());

/// Fase del cuento abierto (plan 03 §3).
enum CuentoFase {
  /// Leyendo las páginas una a una.
  leyendo,

  /// Tarea "¡Completar cuento!": tocar la imagen que falta.
  completar,

  /// "¡Cuento completado! 🎉"
  completado,
}

/// Estado del juego cuentos.
class CuentosViewState {
  const CuentosViewState({
    this.storyId,
    this.pagina = 0,
    this.fase = CuentoFase.leyendo,
    this.completados = const {},
    this.opcionIncorrecta,
    this.opciones = const [],
  });

  /// Cuento abierto; null = en la lista.
  final String? storyId;

  /// Página actual (0-based).
  final int pagina;

  final CuentoFase fase;

  /// Ids de cuentos ya completados (estrella guardada).
  final Set<String> completados;

  /// Picto tocado que no era el correcto (borde de error, sin parpadeos).
  final String? opcionIncorrecta;

  /// Ids de las opciones de la tarea "completar cuento"; se sortean una
  /// sola vez al entrar en la fase para que no salten tras cada toque.
  final List<String> opciones;

  bool get enLista => storyId == null;

  CuentosViewState copyWith({
    String? storyId,
    int? pagina,
    CuentoFase? fase,
    Set<String>? completados,
    String? opcionIncorrecta,
    bool limpiarIncorrecta = false,
    List<String>? opciones,
  }) =>
      CuentosViewState(
        storyId: storyId ?? this.storyId,
        pagina: pagina ?? this.pagina,
        fase: fase ?? this.fase,
        completados: completados ?? this.completados,
        opcionIncorrecta: limpiarIncorrecta
            ? null
            : opcionIncorrecta ?? this.opcionIncorrecta,
        opciones: opciones ?? this.opciones,
      );
}

/// Controlador del juego cuentos.
///
/// El avance se guarda por cuento en `GameProgressRepo` con
/// `gameId: 'cuentos:<id>'`: `level` = página más alta visitada (1) y
/// `stars: 1` cuando está completado. Sobrevive al reinicio de la app.
class CuentosController extends AsyncNotifier<CuentosViewState> {
  @override
  Future<CuentosViewState> build() async {
    final cuentos = await ref.read(cuentosSeedProvider.future);
    final repo = ref.read(gameProgressRepoProvider);
    final completados = <String>{};
    for (final cuento in cuentos) {
      final progress = await repo.progress('cuentos:${cuento.id}');
      if (progress != null && progress.stars > 0) completados.add(cuento.id);
    }
    return CuentosViewState(completados: completados);
  }

  /// Abre el cuento; si tiene avance, retoma en su página.
  Future<void> abrirCuento(String id) async {
    final cuentos = await ref.read(cuentosSeedProvider.future);
    Story? cuento;
    for (final c in cuentos) {
      if (c.id == id) cuento = c;
    }
    if (cuento == null || cuento.pages.isEmpty) return;

    final progress =
        await ref.read(gameProgressRepoProvider).progress('cuentos:$id');
    // level guarda la página más alta visitada (1-based); un cuento ya
    // completado se vuelve a leer desde el principio.
    final pagina = progress != null && progress.stars == 0
        ? (progress.level - 1).clamp(0, cuento.pages.length - 1)
        : 0;

    state = AsyncData(
      state.requireValue.copyWith(
        storyId: id,
        pagina: pagina,
        fase: CuentoFase.leyendo,
        limpiarIncorrecta: true,
      ),
    );
  }

  void irALista() {
    state = AsyncData(
      state.requireValue.copyWith(
        storyId: null,
        pagina: 0,
        fase: CuentoFase.leyendo,
        limpiarIncorrecta: true,
      ),
    );
  }

  /// Avanza una página; en la última pasa a la tarea "completar cuento".
  Future<void> siguiente() async {
    final actual = state.requireValue;
    final cuento = await _cuento(actual.storyId);
    if (cuento == null) return;

    if (actual.pagina + 1 < cuento.pages.length) {
      final pagina = actual.pagina + 1;
      state = AsyncData(actual.copyWith(pagina: pagina, limpiarIncorrecta: true));
      await _guardar(actual.storyId!, pagina: pagina + 1);
    } else {
      // Sortea las opciones una sola vez al entrar en la tarea.
      final pictos = await ref.read(pictosProvider.future);
      state = AsyncData(
        actual.copyWith(
          fase: CuentoFase.completar,
          limpiarIncorrecta: true,
          opciones: opcionesDeTarea(
            cuento.coverPictoId,
            pictos,
            ref.read(cuentosRandomProvider),
          ),
        ),
      );
    }
  }

  void anterior() {
    final actual = state.requireValue;
    if (actual.pagina == 0) return;
    state = AsyncData(
      actual.copyWith(pagina: actual.pagina - 1, limpiarIncorrecta: true),
    );
  }

  /// Toca una opción de la tarea: acierto completa el cuento; error marca
  /// la opción con borde hasta que toque la correcta (sin parpadeos).
  Future<void> tocarOpcion(String pictoId) async {
    final actual = state.requireValue;
    final cuento = await _cuento(actual.storyId);
    if (cuento == null || actual.fase != CuentoFase.completar) return;

    if (pictoId == cuento.coverPictoId) {
      state = AsyncData(
        actual.copyWith(
          fase: CuentoFase.completado,
          completados: {...actual.completados, cuento.id},
          limpiarIncorrecta: true,
        ),
      );
      await _guardar(cuento.id, pagina: cuento.pages.length, completado: true);
      // Alimenta el dashboard del modo padre (plan 03 §6).
      await ref.read(usageRepoProvider).record(
            UsageEvent(
              id: 'cuento_${cuento.id}_'
                  '${DateTime.now().microsecondsSinceEpoch}',
              type: 'cuento_completado',
              createdAt: DateTime.now(),
              data: {'juego': 'cuentos', 'cuento': cuento.id},
            ),
          );
      // Refresca la sección de avance del home sin reiniciar la app.
      ref.invalidate(avanceJuegosProvider);
    } else {
      state = AsyncData(actual.copyWith(opcionIncorrecta: pictoId));
    }
  }

  /// Vuelve a leer el cuento desde la primera página.
  void reiniciar() {
    state = AsyncData(
      state.requireValue.copyWith(pagina: 0, fase: CuentoFase.leyendo),
    );
  }

  Future<Story?> _cuento(String? id) async {
    if (id == null) return null;
    final cuentos = await ref.read(cuentosSeedProvider.future);
    for (final c in cuentos) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<void> _guardar(
    String id, {
    required int pagina,
    bool completado = false,
  }) async {
    final repo = ref.read(gameProgressRepoProvider);
    final previo = await repo.progress('cuentos:$id');
    // Re-leer un cuento ya completado no borra su estrella.
    final estrellas = completado || (previo?.stars ?? 0) > 0 ? 1 : 0;
    await repo.saveProgress(
      GameProgress(
        gameId: 'cuentos:$id',
        level: pagina,
        stars: estrellas,
      ),
    );
    if (completado) {
      final actual = state.requireValue;
      state = AsyncData(
        actual.copyWith(completados: {...actual.completados, id}),
      );
    }
  }
}

/// Controlador del juego cuentos.
final cuentosProvider = AsyncNotifierProvider<CuentosController, CuentosViewState>(
  CuentosController.new,
);

/// Pictos clave de una página: los cuya palabra aparece en el texto
/// (búsqueda literal, case-insensitive). Sin coincidencia → el picto
/// de portada del cuento.
List<Pictogram> pictosClaveDePagina(
  String texto,
  List<Pictogram> pictos, {
  String? coverPictoId,
}) {
  final minusculas = texto.toLowerCase();
  final clave = [
    for (final picto in pictos)
      if (minusculas.contains(picto.label.toLowerCase())) picto,
  ];
  if (clave.isNotEmpty) return clave.take(3).toList();
  if (coverPictoId != null) {
    for (final picto in pictos) {
      if (picto.id == coverPictoId) return [picto];
    }
  }
  return const [];
}

/// 3 ids de opción para la tarea "completar cuento": la correcta (picto
/// de portada) + 2 distractores al azar, barajados. Sin portada válida →
/// lista vacía (la tarea se sustituye por un literal).
List<String> opcionesDeTarea(
  String? coverPictoId,
  List<Pictogram> pictos,
  Random random,
) {
  Pictogram? correcta;
  for (final picto in pictos) {
    if (picto.id == coverPictoId) correcta = picto;
  }
  if (correcta == null) return const [];

  final resto = [...pictos]..remove(correcta)..shuffle(random);
  return [
    for (final picto in [correcta, ...resto.take(2)]) picto.id,
  ]..shuffle(random);
}
