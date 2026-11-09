import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/contracts/repos.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/rutinas/primero_luego_view.dart';

import '../core/accessibility_helper.dart';
import 'harness.dart';

/// Todas a las 23:59: el orden no depende de la hora en que corre el test.
class _Horario implements ScheduleRepo {
  _Horario(this.titulos);

  final List<String> titulos;

  @override
  Future<List<ScheduleEntry>> schedule() async => [
        for (final titulo in titulos)
          ScheduleEntry(id: titulo, title: titulo, timeMinutes: 23 * 60 + 59),
      ];

  @override
  Future<void> saveEntry(ScheduleEntry entry) async {}
}

Future<void> _abrir(WidgetTester tester, List<String> titulos) async {
  await pumpRutinas(
    tester,
    extraOverrides: [scheduleRepoProvider.overrideWithValue(_Horario(titulos))],
  );
  await tester.ensureVisible(find.text('Primero y luego'));
  await tester.tap(find.text('Primero y luego'));
  await tester.pumpAndSettle();
}

Future<void> _listo(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Listo'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Listo avanza hasta terminar el día', (tester) async {
    await _abrir(tester, ['Comer', 'Jugar', 'Dormir']);
    expect(find.text('Comer'), findsOneWidget);
    expect(find.text('Jugar'), findsOneWidget);
    expect(find.text('Dormir'), findsNothing);

    await _listo(tester);
    expect(find.text('Comer'), findsNothing);
    expect(find.text('Jugar'), findsOneWidget);
    expect(find.text('Dormir'), findsOneWidget);

    await _listo(tester);
    expect(find.text('Dormir'), findsOneWidget);
    expect(find.text('Es la última actividad de hoy.'), findsOneWidget);

    await _listo(tester);
    expect(find.text('Ya hiciste todas las actividades de hoy.'), findsOneWidget);
  });

  testWidgets('un doble toque solo completa una actividad', (tester) async {
    await _abrir(tester, ['Comer', 'Jugar', 'Dormir']);

    final boton = find.widgetWithText(FilledButton, 'Listo');
    await tester.tap(boton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.widget<FilledButton>(boton).onPressed, isNull);
    await tester.tap(boton, warnIfMissed: false);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Jugar'), findsOneWidget);
    expect(find.text('Dormir'), findsOneWidget);
  });

  testWidgets('sin actividades lo dice y deja volver', (tester) async {
    await _abrir(tester, []);
    expect(find.text('Todavía no hay actividades en tu horario.'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);
  });

  testWidgets('no tiene problemas de accesibilidad', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: [
        ...overridesDeRutinas(prefs),
        scheduleRepoProvider.overrideWithValue(_Horario(['Comer', 'Jugar'])),
      ],
      home: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: const Scaffold(body: PrimeroLuegoView()),
      ),
    );
  });
}
