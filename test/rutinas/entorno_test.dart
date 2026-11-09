import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/features/entorno/entorno_screen.dart';

import '../core/accessibility_helper.dart';
import 'harness.dart';

Future<void> abrirEntorno(WidgetTester tester) async {
  await tester.tap(find.text('Mi colegio'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('no enseña colegio, coordinadora ni correo inventados',
      (tester) async {
    await pumpRutinas(tester);
    await abrirEntorno(tester);

    expect(find.textContaining('Demostración'), findsNothing);
    expect(find.textContaining('demostración'), findsNothing);
    expect(find.textContaining('Ejemplo'), findsNothing);
    expect(find.text('demo@bluetalk.app'), findsNothing);
  });

  testWidgets('la guía de llegada muestra sus pasos', (tester) async {
    await pumpRutinas(tester);
    await abrirEntorno(tester);

    expect(find.text('Así es mi llegada al colegio:'), findsOneWidget);
    expect(find.text('Llego a la escuela'), findsOneWidget);
    expect(find.text('Saludo a mi maestra'), findsOneWidget);
    expect(find.text('Es hora de volver a casa'), findsOneWidget);
  });

  testWidgets('la pantalla de entorno no tiene problemas de accesibilidad',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeRutinas(prefs),
      home: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: const Scaffold(body: EntornoScreen()),
      ),
    );
  });
}
