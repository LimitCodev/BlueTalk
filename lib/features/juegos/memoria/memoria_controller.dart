import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../data/models/models.dart';
import '../avance_juegos.dart';
import '../juegos_catalog.dart';

/// Semilla del barajado; sobreescribible en tests para tableros
/// deterministas.
final memoriaRandomProvider = Provider<Random>((ref) => Random());

/// Estado del juego memoria (plan 03 §2).
class MemoriaViewState {
  const MemoriaViewState({
    this.nivel,
    this.desbloqueado = 1,
    this.tablero = const [],
    this.seleccion = const [],
    this.fallas = const {},
    this.descubiertas = const {},
    this.completado = false,
  });

  /// Nivel seleccionado; null = en el selector de niveles.
  final int? nivel;

  /// Nivel más alto desbloqueado (persistido en GameProgressRepo).
  final int desbloqueado;

  /// Ids de los pictos del tablero, 2 entradas por par (ya barajadas).
  final List<String> tablero;

  /// Índices levantados sin comprobar todavía (0–2).
  final List<int> seleccion;

  /// Índices de la pareja levantada que no coincidió (borde de error).
  final Set<int> fallas;

  /// Índices de parejas ya acertadas (borde de éxito, sin parpadeos).
  final Set<int> descubiertas;

  final bool completado;

  bool get enTablero => nivel != null;
  int get parejas => tablero.length ~/ 2;

  MemoriaViewState copyWith({
    int? nivel,
    int? desbloqueado,
    List<String>? tablero,
    List<int>? seleccion,
    Set<int>? fallas,
    Set<int>? descubiertas,
    bool? completado,
  }) =>
      MemoriaViewState(
        nivel: nivel ?? this.nivel,
        desbloqueado: desbloqueado ?? this.desbloqueado,
        tablero: tablero ?? this.tablero,
        seleccion: seleccion ?? this.seleccion,
        fallas: fallas ?? this.fallas,
        descubiertas: descubiertas ?? this.descubiertas,
        completado: completado ?? this.completado,
      );
}

/// Controlador del memoria: niveles desbloqueables y tablero de parejas.
///
/// El progreso se guarda con `gameId: 'memoria'` en `GameProgressRepo`
/// (nivel más alto desbloqueado) y sobrevive al reinicio de la app.
class MemoriaController extends AsyncNotifier<MemoriaViewState> {
  @override
  Future<MemoriaViewState> build() async {
    final progress =
        await ref.read(gameProgressRepoProvider).progress('memoria');
    return MemoriaViewState(desbloqueado: progress?.level ?? 1);
  }

  /// Abre el tablero del [nivel] si está desbloqueado.
  Future<void> empezarNivel(int nivel) async {
    final actual = state.requireValue;
    if (nivel > actual.desbloqueado || nivel > memoriaMaxNiveles) return;

    final pictos = await ref.read(pictosProvider.future);
    final pares = 2 * nivel + 2; // nivel 1 = 4 parejas; sube de 2 en 2.
    final barajados = [...pictos]..shuffle(ref.read(memoriaRandomProvider));

    state = AsyncData(
      actual.copyWith(
        nivel: nivel,
        tablero: [
          for (final picto in barajados.take(pares)) ...[picto.id, picto.id],
        ]..shuffle(ref.read(memoriaRandomProvider)),
        seleccion: const [],
        fallas: const {},
        descubiertas: const {},
        completado: false,
      ),
    );
  }

  /// Levanta la ficha [index]; dos iguales aciertan, dos distintas marcan
  /// error hasta el siguiente toque (feedback por estado, sin parpadeos).
  void tocarFicha(int index) {
    final actual = state.requireValue;
    if (actual.completado ||
        actual.descubiertas.contains(index) ||
        actual.seleccion.contains(index)) {
      return;
    }

    var seleccion = [...actual.seleccion];
    var fallas = {...actual.fallas};
    if (seleccion.length == 2) {
      // El toque anterior deja atrás la pareja fallida.
      fallas.removeAll(seleccion);
      seleccion = [];
    }
    seleccion.add(index);

    if (seleccion.length < 2) {
      state = AsyncData(
        actual.copyWith(seleccion: seleccion, fallas: fallas),
      );
      return;
    }

    final a = seleccion.first;
    final b = seleccion.last;
    if (actual.tablero[a] == actual.tablero[b]) {
      final descubiertas = {...actual.descubiertas, a, b};
      final completado = descubiertas.length == actual.tablero.length;
      state = AsyncData(
        actual.copyWith(
          seleccion: const [],
          fallas: const {},
          descubiertas: descubiertas,
          completado: completado,
        ),
      );
      if (completado) unawaited(_alCompletar(actual.nivel!, actual.desbloqueado));
    } else {
      state = AsyncData(
        actual.copyWith(seleccion: seleccion, fallas: {...fallas, a, b}),
      );
    }
  }

  Future<void> _alCompletar(int nivel, int desbloqueado) async {
    // El nivel N desbloquea el N+1 (tope: memoriaMaxNiveles).
    final nuevoDesbloqueado =
        nivel < memoriaMaxNiveles ? max(desbloqueado, nivel + 1) : desbloqueado;
    state = AsyncData(
      state.requireValue.copyWith(desbloqueado: nuevoDesbloqueado),
    );

    await ref.read(gameProgressRepoProvider).saveProgress(
          GameProgress(gameId: 'memoria', level: nuevoDesbloqueado),
        );
    // Refresca la sección de avance del home sin reiniciar la app.
    ref.invalidate(avanceJuegosProvider);
    // Alimenta el dashboard del modo padre (plan 03 §6).
    await ref.read(usageRepoProvider).record(
          UsageEvent(
            id: 'memoria_nivel_${nivel}_${DateTime.now().microsecondsSinceEpoch}',
            type: 'nivel_completado',
            createdAt: DateTime.now(),
            data: {'juego': 'memoria', 'nivel': nivel},
          ),
        );
  }

  /// Vuelve al selector de niveles.
  void volverAlSelector() {
    state = AsyncData(
      state.requireValue.copyWith(
        nivel: null,
        seleccion: const [],
        fallas: const {},
        descubiertas: const {},
        completado: false,
      ),
    );
  }
}

/// Controlador del juego memoria.
final memoriaProvider =
    AsyncNotifierProvider<MemoriaController, MemoriaViewState>(
  MemoriaController.new,
);
