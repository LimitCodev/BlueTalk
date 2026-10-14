import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/features/rutinas/horario_view.dart';
import 'package:bluetalk/features/rutinas/rutinas_controller.dart';
import 'package:bluetalk/features/rutinas/rutinas_screen.dart';

import '../core/accessibility_helper.dart';
import 'harness.dart';

void main() {
  testWidgets('el inicio muestra las cuatro secciones', (tester) async {
    await pumpRutinas(tester);

    expect(find.text('Mi horario'), findsOneWidget);
    expect(find.text('Mi día'), findsOneWidget);
    expect(find.text('Mi colegio'), findsOneWidget);
    expect(find.text('Mis estadísticas'), findsOneWidget);
    // Aviso in-app de la siguiente actividad (plan 04 §1).
    expect(find.textContaining('Siguiente actividad'), findsOneWidget);
  });

  testWidgets('las tarjetas abren su vista y Volver regresa', (tester) async {
    final container = await pumpRutinas(tester);

    await tester.tap(find.text('Mi horario'));
    await tester.pumpAndSettle();
    expect(find.text('Entrada'), findsWidgets);
    expect(container.read(rutinasProvider), RutinaVista.horario);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(container.read(rutinasProvider), RutinaVista.inicio);

    await tester.tap(find.text('Mi colegio'));
    await tester.pumpAndSettle();
    expect(find.text('Colegio Demostración Norte'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mis estadísticas'));
    await tester.pumpAndSettle();
    expect(find.text('Uso de la app (7 días)'), findsOneWidget);
  });

  testWidgets('el inicio no tiene problemas de accesibilidad', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeRutinas(prefs),
      home: const Scaffold(body: RutinasScreen()),
    );
  });

  testWidgets('el horario del niño no tiene problemas de accesibilidad',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeRutinas(prefs),
      home: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: const Scaffold(body: HorarioView()),
      ),
    );
  });
}
