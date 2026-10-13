import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/features/juegos/cuentos/cuentos_screen.dart';
import 'package:bluetalk/features/juegos/juegos_controller.dart';
import 'package:bluetalk/features/juegos/memoria/memoria_screen.dart';

import '../core/accessibility_helper.dart';
import 'harness.dart';

void main() {
  testWidgets('el selector de niveles del memoria es accesible', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeJuegos(prefs),
      home: const Scaffold(body: MemoriaScreen()),
    );
  });

  testWidgets('la lista de cuentos es accesible', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeJuegos(prefs),
      home: const Scaffold(body: CuentosScreen()),
    );
  });

  testWidgets('los juegos recorren bien con las animaciones apagadas',
      (tester) async {
    // El Modo calma apaga animaciones vía MediaQuery.disableAnimations
    // (raíz de Ola 1); las pantallas de juegos no crean animaciones
    // propias, así que con disableAnimations todo es instantáneo.
    final container = await pumpJuegos(tester, modoCalma: true);

    await tester.tap(find.text('Memoria'));
    await tester.pumpAndSettle();
    expect(find.text('Cada nivel es más difícil 💙'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuentos interactivos'));
    await tester.pumpAndSettle();
    expect(find.text('El gato de Lola'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();
    expect(find.text('Dibuja aquí con el dedo.'), findsOneWidget);
    expect(container.read(juegosProvider), JuegoVista.artista);
  });
}
