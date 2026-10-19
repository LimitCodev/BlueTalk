import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('la bienvenida muestra la guía de modelado', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Guía de modelado (auditoría de reseñas: «señala y di la palabra
    // mientras el niño toca»), visible sin abrir ningún menú.
    expect(
      find.text(
        'Consejo para enseñar: señala y di la palabra mientras '
        'el niño toca el pictograma.',
      ),
      findsOneWidget,
    );
  });
}
