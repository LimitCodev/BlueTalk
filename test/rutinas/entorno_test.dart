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
  testWidgets('la pantalla muestra el colegio ficticio y el aviso de demo',
      (tester) async {
    await pumpRutinas(tester);
    await abrirEntorno(tester);

    expect(find.text('Colegio Demostración Norte'), findsOneWidget);
    expect(
      find.text('Datos de demostración. Esta información no es real.'),
      findsOneWidget,
    );
    expect(find.text('Aula de ejemplo — grupo azul'), findsOneWidget);
  });

  testWidgets('el contacto es el correo demo', (tester) async {
    await pumpRutinas(tester);
    await abrirEntorno(tester);

    expect(find.text('Coordinadora: Sra. Ejemplo'), findsOneWidget);
    expect(find.text('demo@bluetalk.app'), findsOneWidget);
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
