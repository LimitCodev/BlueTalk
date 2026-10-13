import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/app.dart';
import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/app/router.dart';
import 'package:bluetalk/app/shell.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';

Future<SharedPreferences> _givenPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester,
  SharedPreferences prefs,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BlueTalkApp(),
    ),
  );
  return ProviderScope.containerOf(tester.element(find.byType(BlueTalkApp)));
}

void main() {
  testWidgets('arranca en onboarding y entra al shell', (tester) async {
    final prefs = await _givenPrefs();
    await _pumpApp(tester, prefs);

    expect(find.text('Comenzar'), findsOneWidget);

    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(find.byType(AppShell), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Comunicar'), findsWidgets); // AppBar + pestaña
    expect(find.text('Comenzar'), findsNothing);
  });

  testWidgets('las pestañas navegan y el botón del shell activa el modo calma',
      (tester) async {
    final prefs = await _givenPrefs();
    await _pumpApp(tester, prefs);

    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    expect(find.byType(CalmModeToggle), findsOneWidget);

    await tester.tap(find.byIcon(Icons.contrast));
    await tester.pumpAndSettle();
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(prefs.getBool(CalmModeController.prefKey), isTrue);
  });

  testWidgets('ruta /padre muestra el placeholder del gate', (tester) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(tester, prefs);

    container.read(routerProvider).go('/padre');
    await tester.pumpAndSettle();

    expect(find.text('Modo padre'), findsOneWidget);
    expect(find.text('Se activará con tu PIN'), findsOneWidget);
  });

  testWidgets('modo calma: las rutas cambian con duración cero',
      (tester) async {
    final prefs = await _givenPrefs();
    final container = await _pumpApp(tester, prefs);

    await container.read(calmModeProvider.notifier).set(true);
    await tester.pump();

    container.read(routerProvider).go('/home/aprender');
    await tester.pumpAndSettle();

    final calmRoute = ModalRoute.of(
      tester.element(find.text('Juegos y cuentos — próximamente')),
    );
    expect(calmRoute, isNotNull);
    expect(calmRoute!.transitionDuration, Duration.zero);

    // Sin modo calma la transición normal sí existe.
    await container.read(calmModeProvider.notifier).set(false);
    await tester.pump();
    container.read(routerProvider).go('/home/rutinas');
    await tester.pumpAndSettle();

    final normalRoute = ModalRoute.of(
      tester.element(find.text('Horario del día — próximamente')),
    );
    expect(normalRoute!.transitionDuration, isNot(Duration.zero));
  });
}
