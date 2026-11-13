import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/padre/dashboard/metricas.dart';
import 'package:bluetalk/features/padre/dashboard/resumen_screen.dart';
import 'package:bluetalk/features/padre/diagnostico/observaciones.dart';

import 'harness.dart';
import '../core/accessibility_helper.dart';

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
      'el resumen muestra sus métricas locales sin banner de demostración',
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

    expect(find.text('Datos de demostración'), findsNothing);
    expect(find.text('Pictogramas tocados hoy'), findsOneWidget);
    expect(find.text('Minutos de juego'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('¿Cuántas actividades hizo hoy?'), findsOneWidget);

    final metricas = await container.read(metricasProvider.future);
    expect(metricas.pictosHoy, 7);
    expect(metricas.pictosDistintosHoy, 7);
    expect(metricas.pictosPorCategoriaHoy, {'comida': 3, 'animales': 4});
    expect(metricas.nombresDeCategoria['comida'], 'Comida');
    expect(metricas.sesionesJuegoHoy, 1);
    expect(metricas.minutosJuegoHoy, 5);
    expect(metricas.dibujosGuardados, 1);
    expect(metricas.eventosPorDia.last, 9, reason: '7 pictos + juego + dibujo');
    expect(
      find.text(
        '${metricas.actividadesHechasHoy} de ${metricas.actividadesHorario}',
      ),
      findsOneWidget,
    );

    // Más abajo en la lista: gráfica semanal y tarjetas sin gráfico.
    await _hasta(tester, find.text('¿Cómo fue esta semana?'));
    expect(find.text('¿Cómo fue esta semana?'), findsOneWidget);
    await _hasta(tester, find.text('Más datos'));
    expect(find.text('Más datos'), findsOneWidget);
  });

  testWidgets('el resumen con gráficos no tiene problemas de accesibilidad',
      (tester) async {
    final prefs = await prefsDePrueba();
    await sembrarEventos(prefs, [
      UsageEvent(
        id: 'a1',
        type: 'picto_tap',
        createdAt: ahoraFija,
        data: {'pictoId': 'p1', 'categoryId': 'comida'},
      ),
      UsageEvent(
        id: 'a2',
        type: 'juego_fin',
        createdAt: ahoraFija,
        data: {'juego': 'memoria', 'segundos': 120},
      ),
    ]);
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDePadre(prefs, reloj: RelojPrueba()),
      home: const Scaffold(body: ResumenScreen()),
    );
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

    expect(find.text('Datos de demostración'), findsNothing);
    expect(find.text('¿Cuántas actividades hizo hoy?'), findsOneWidget);
    expect(find.textContaining('Aún no hay datos'), findsWidgets);
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

  test('desmarcar una actividad la quita de «hechas hoy»', () async {
    final prefs = await prefsDePrueba();
    UsageEvent marca(String id, String tipo) => UsageEvent(
          id: '$tipo$id',
          type: tipo,
          createdAt: ahoraFija,
          data: {'entradaId': id},
        );
    await sembrarEventos(prefs, [
      marca('a', 'actividad_hecha'),
      marca('b', 'actividad_hecha'),
      marca('a', 'actividad_pendiente'),
    ]);
    final container = ProviderContainer(
      overrides: overridesDePadre(prefs, reloj: RelojPrueba()).cast(),
    );
    addTearDown(container.dispose);
    final metricas = await container.read(metricasProvider.future);
    expect(metricas.actividadesHechasHoy, 1);
  });
}
