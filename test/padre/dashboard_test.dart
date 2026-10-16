import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/dashboard/metricas.dart';
import 'package:bluetalk/features/padre/dashboard/resumen_screen.dart';
import 'package:bluetalk/features/padre/diagnostico/observaciones.dart';

import 'harness.dart';

/// Desplaza la lista hasta un widget que está más abajo del primer pantallazo.
Future<void> _hasta(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    800,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 200,
  );
}

void main() {
  testWidgets(
      'el resumen muestra el banner de demostración y sus métricas locales',
      (tester) async {
    final prefs = await prefsDePrueba();
    final reloj = RelojPrueba();
    await sembrarEventos(prefs, [
      for (var i = 0; i < 3; i++)
        UsageEvent(
          id: 't$i',
          type: 'picto_tap',
          createdAt: ahoraFija,
          data: {'pictoId': 'p$i', 'categoryId': 'comida'},
        ),
      for (var i = 0; i < 4; i++)
        UsageEvent(
          id: 'c$i',
          type: 'picto_tap',
          createdAt: ahoraFija,
          data: {'pictoId': 'q$i', 'categoryId': 'animales'},
        ),
      UsageEvent(
        id: 'j1',
        type: 'juego_fin',
        createdAt: ahoraFija,
        data: {'juego': 'memoria', 'segundos': 300},
      ),
      UsageEvent(
        id: 'd1',
        type: 'dibujo_guardado',
        createdAt: ahoraFija,
        data: {'juego': 'artista'},
      ),
      // Ayer: no cuenta para «hoy».
      UsageEvent(
        id: 't_ayer',
        type: 'picto_tap',
        createdAt: ahoraFija.subtract(const Duration(days: 1)),
        data: {'pictoId': 'viejo', 'categoryId': 'comida'},
      ),
    ]);

    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: ResumenScreen()),
      overrides: overridesDePadre(prefs, reloj: reloj),
    );

    expect(find.text('Datos de demostración'), findsOneWidget);
    expect(find.text('Pictogramas tocados hoy'), findsOneWidget);
    expect(find.text('Tiempo de juego hoy'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);

    final metricas = await container.read(metricasProvider.future);
    expect(metricas.pictosHoy, 7);
    expect(metricas.pictosDistintosHoy, 7);
    expect(metricas.pictosPorCategoriaHoy, {'comida': 3, 'animales': 4});
    expect(metricas.nombresDeCategoria['comida'], 'Comida');
    expect(metricas.sesionesJuegoHoy, 1);
    expect(metricas.minutosJuegoHoy, 5);
    expect(metricas.dibujosGuardados, 1);
    expect(metricas.eventosPorDia.last, 9, reason: '7 pictos + juego + dibujo');

    // Más abajo en la lista: horario y gráfica semanal.
    await _hasta(tester, find.text('Últimos 7 días'));
    expect(find.text('Actividades del horario'), findsOneWidget);
    expect(find.text('Últimos 7 días'), findsOneWidget);
  });

  testWidgets('las observaciones salen con su disclaimer obligatorio',
      (tester) async {
    final prefs = await prefsDePrueba();
    final reloj = RelojPrueba();
    await sembrarEventos(prefs, [
      for (var i = 0; i < 3; i++)
        UsageEvent(
          id: 't$i',
          type: 'picto_tap',
          createdAt: ahoraFija,
          data: {'pictoId': 'p$i', 'categoryId': 'comida'},
        ),
    ]);

    await pumpPadre(
      tester,
      home: const Scaffold(body: ObservacionesSection()),
      overrides: overridesDePadre(prefs, reloj: reloj),
    );

    expect(find.text(disclaimerObservaciones), findsOneWidget);
    expect(find.text('Observaciones'), findsOneWidget);
    expect(
      find.text('El niño usa muy pocos pictogramas al día.'),
      findsOneWidget,
    );
    expect(find.text('Información'), findsOneWidget);
  });

  testWidgets('sin datos el resumen está vacío pero conserva el disclaimer',
      (tester) async {
    final prefs = await prefsDePrueba();
    await pumpPadre(
      tester,
      home: const Scaffold(body: ResumenScreen()),
      overrides: overridesDePadre(prefs),
    );

    expect(find.text('Datos de demostración'), findsOneWidget);
    await _hasta(tester, find.text(disclaimerObservaciones));
    expect(
      find.text(
        'Todavía no hay observaciones. Aparecerán cuando haya datos de uso '
        'del niño.',
      ),
      findsOneWidget,
    );
    expect(find.text(disclaimerObservaciones), findsOneWidget);
  });
}
