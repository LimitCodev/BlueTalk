import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/features/rutinas/editor_horario_view.dart';
import 'package:bluetalk/features/rutinas/estadisticas_view.dart';
import 'package:bluetalk/features/salud/salud_screen.dart';

import '../core/accessibility_helper.dart';
import 'harness.dart';

void main() {
  testWidgets('la sección de salud no tiene problemas de accesibilidad',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeRutinas(prefs),
      home: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: const Scaffold(body: SaludScreen()),
      ),
    );
  });

  testWidgets('el editor de horario no tiene problemas de accesibilidad',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeRutinas(prefs),
      home: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: const Scaffold(body: EditorHorarioView()),
      ),
    );
  });

  testWidgets('estadísticas sin datos no tiene problemas de accesibilidad',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeRutinas(prefs),
      home: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: const Scaffold(body: EstadisticasView()),
      ),
    );
  });
}
