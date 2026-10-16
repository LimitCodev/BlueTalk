import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/diagnostico/observaciones.dart';

import 'harness.dart';

Observacion? _porId(List<Observacion> lista, String id) {
  for (final observacion in lista) {
    if (observacion.id == id) return observacion;
  }
  return null;
}

void main() {
  final ahora = ahoraFija;

  List<ObservationRule> reglas({bool todas = true}) => [
        const ObservationRule(id: 'r_pocos_pictos', label: 'Pocos pictos'),
        const ObservationRule(id: 'r_poco_tiempo', label: 'Poco tiempo'),
        const ObservationRule(id: 'r_cambio_humor', label: 'Cambio de humor'),
        const ObservationRule(
          id: 'r_habito_sin_completar',
          label: 'Hábito sin completar',
        ),
        const ObservationRule(id: 'r_mismo_picto', label: 'Mismo picto'),
        if (!todas)
          const ObservationRule(id: 'r_desconocida', label: 'Regla futura'),
      ];

  test('sin datos suficientes no se emite ninguna observación', () {
    final lista = evaluarReglas(
      reglas: reglas(),
      eventos: const [],
      moods: const [],
      habitos: const [],
      ahora: ahora,
    );
    expect(lista, isEmpty);
  });

  test('pocos pictos distintos en 24 h dispara la regla', () {
    final eventos = [
      for (var i = 0; i < 3; i++)
        UsageEvent(
          id: 'p$i',
          type: 'picto_tap',
          createdAt: ahora.subtract(Duration(hours: i)),
          data: {'pictoId': 'p$i', 'categoryId': 'comida'},
        ),
      // Viejo: fuera de la ventana de 24 h.
      UsageEvent(
        id: 'p_viejo',
        type: 'picto_tap',
        createdAt: ahora.subtract(const Duration(days: 3)),
        data: {'pictoId': 'p9', 'categoryId': 'comida'},
      ),
    ];

    final lista = evaluarReglas(
      reglas: reglas(),
      eventos: eventos,
      moods: const [],
      habitos: const [],
      ahora: ahora,
    );

    final observacion = _porId(lista, 'r_pocos_pictos');
    expect(observacion, isNotNull);
    expect(observacion!.severidad, SeveridadObservacion.info);
    expect(observacion.detalle, contains('3 pictogramas distintos'));
    expect(_porId(lista, 'r_mismo_picto'), isNull, reason: 'menos de 10 toques');
  });

  test('un pictograma repetido en la mayoría de toques dispara la regla', () {
    final eventos = [
      for (var i = 0; i < 10; i++)
        UsageEvent(
          id: 'p$i',
          type: 'picto_tap',
          createdAt: ahora,
          data: {'pictoId': i < 8 ? 'p_fijo' : 'p_otro', 'categoryId': 'comida'},
        ),
    ];

    final lista = evaluarReglas(
      reglas: reglas(),
      eventos: eventos,
      moods: const [],
      habitos: const [],
      ahora: ahora,
    );

    final observacion = _porId(lista, 'r_mismo_picto');
    expect(observacion, isNotNull);
    expect(observacion!.detalle, contains('80%'));
    // Con solo 2 pictos distintos en 10 toques, «pocos pictos» también
    // salta: ambas reglas son independientes y conviven.
    expect(_porId(lista, 'r_pocos_pictos'), isNotNull);
  });

  test('sesiones de juego muy cortas dispara la regla del tiempo', () {
    final eventos = [
      for (var i = 0; i < 3; i++)
        UsageEvent(
          id: 'j$i',
          type: 'juego_fin',
          createdAt: ahora,
          data: {'juego': 'memoria', 'segundos': 20},
        ),
    ];

    final lista = evaluarReglas(
      reglas: reglas(),
      eventos: eventos,
      moods: const [],
      habitos: const [],
      ahora: ahora,
    );

    final observacion = _porId(lista, 'r_poco_tiempo');
    expect(observacion, isNotNull);
    expect(observacion!.detalle, contains('20 segundos'));
  });

  test('un humor que oscila mucho en la semana es de atención', () {
    final moods = [
      MoodEntry(id: 'm1', date: ahora.subtract(const Duration(days: 5)), mood: 1),
      MoodEntry(id: 'm2', date: ahora.subtract(const Duration(days: 3)), mood: 4),
      MoodEntry(id: 'm3', date: ahora, mood: 5),
    ];

    final lista = evaluarReglas(
      reglas: reglas(),
      eventos: const [],
      moods: moods,
      habitos: const [],
      ahora: ahora,
    );

    final observacion = _porId(lista, 'r_cambio_humor');
    expect(observacion, isNotNull);
    expect(observacion!.severidad, SeveridadObservacion.atencion);
    expect(observacion.detalle, contains('del 1 al 5'));
  });

  test('un hábito sin marcar tres días seguidos es de atención', () {
    final habitos = [
      for (var i = 0; i < 3; i++)
        HabitEntry(
          id: 'h$i',
          date: DateTime(2026, 10, 11 + i, 9),
          title: 'Beber agua',
          done: false,
        ),
      HabitEntry(
        id: 'h_ok',
        date: DateTime(2026, 10, 11, 10),
        title: 'Descanso visual',
        done: true,
      ),
    ];

    final lista = evaluarReglas(
      reglas: reglas(),
      eventos: const [],
      moods: const [],
      habitos: habitos,
      ahora: ahora,
    );

    final observacion = _porId(lista, 'r_habito_sin_completar');
    expect(observacion, isNotNull);
    expect(observacion!.severidad, SeveridadObservacion.atencion);
    expect(observacion.detalle, contains('«Beber agua»'));
    expect(observacion.detalle, contains('3 de los últimos 7 días'));
  });

  test('una regla desactivada no emite nada', () {
    final lista = evaluarReglas(
      reglas: [
        const ObservationRule(
          id: 'r_pocos_pictos',
          label: 'Pocos pictos',
          enabled: false,
        ),
      ],
      eventos: [
        UsageEvent(
          id: 'p0',
          type: 'picto_tap',
          createdAt: ahora,
          data: {'pictoId': 'p0'},
        ),
      ],
      moods: const [],
      habitos: const [],
      ahora: ahora,
    );
    expect(lista, isEmpty);
  });

  test('una regla desconocida se ignora sin romper', () {
    final lista = evaluarReglas(
      reglas: reglas(todas: false),
      eventos: const [],
      moods: const [],
      habitos: const [],
      ahora: ahora,
    );
    expect(lista, isEmpty);
  });

  test('el disclaimer es exactamente el del plan 05', () {
    expect(
      disclaimerObservaciones,
      'Orientativa, no es diagnóstico clínico. No sustituye a un profesional.',
    );
  });
}
