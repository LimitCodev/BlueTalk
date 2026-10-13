import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/features/juegos/juegos_controller.dart';
import 'package:bluetalk/features/juegos/juegos_screen.dart';

import '../core/accessibility_helper.dart';
import 'harness.dart';

void main() {
  testWidgets('el home muestra los tres juegos y el avance', (tester) async {
    await pumpJuegos(tester);

    expect(find.text('Memoria'), findsOneWidget);
    expect(find.text('Cuentos interactivos'), findsOneWidget);
    expect(find.text('Artista'), findsOneWidget);
    expect(find.text('Avance en juegos'), findsOneWidget);
    expect(find.text('Memoria: 0 de 9 niveles superados'), findsOneWidget);
    expect(find.text('Cuentos: 0 de 3 cuentos completados'), findsOneWidget);
    expect(find.text('Artista: 0 dibujos guardados'), findsOneWidget);
  });

  testWidgets('tocar una tarjeta abre el juego y volver regresa', (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Memoria'));
    await tester.pumpAndSettle();
    expect(find.text('Volver'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('Avance en juegos'), findsOneWidget);
    expect(container.read(juegosProvider), JuegoVista.inicio);
  });

  testWidgets('el home no tiene problemas de accesibilidad', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeJuegos(prefs),
      home: const Scaffold(body: JuegosScreen()),
    );
  });
}
