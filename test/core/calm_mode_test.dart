import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/app.dart';
import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';

Future<SharedPreferences> _givenPrefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

ProviderScope _scope(SharedPreferences prefs, Widget child) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: child,
  );
}

void main() {
  testWidgets('modo calma desactivado: sin filtro gris', (tester) async {
    final prefs = await _givenPrefs();
    await tester.pumpWidget(_scope(prefs, const BlueTalkApp()));

    expect(find.byType(ColorFiltered), findsNothing);
  });

  testWidgets('activar modo calma: grises, animaciones apagadas y persistido',
      (tester) async {
    final prefs = await _givenPrefs();
    await tester.pumpWidget(_scope(prefs, const BlueTalkApp()));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BlueTalkApp)),
    );
    await container.read(calmModeProvider.notifier).set(true);
    await tester.pump();

    // Toda la UI pasa por el filtro de grises.
    expect(find.byType(ColorFiltered), findsOneWidget);

    // La señal de "sin animaciones" queda encendida en el MediaQuery raíz.
    final mediaWithNoAnim = tester.widgetList<MediaQuery>(
      find.byWidgetPredicate((w) => w is MediaQuery && w.data.disableAnimations),
    );
    expect(mediaWithNoAnim, isNotEmpty);

    // Y el flag quedó persistido.
    expect(prefs.getBool(CalmModeController.prefKey), isTrue);

    // Al apagarlo vuelve a la normalidad.
    await container.read(calmModeProvider.notifier).set(false);
    await tester.pump();
    expect(find.byType(ColorFiltered), findsNothing);
    expect(prefs.getBool(CalmModeController.prefKey), isFalse);
  });

  testWidgets('el interruptor alterna el modo calma', (tester) async {
    final prefs = await _givenPrefs();
    await tester.pumpWidget(
      _scope(prefs, const MaterialApp(home: Scaffold(body: CalmModeToggle()))),
    );

    expect(find.byType(Switch), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(prefs.getBool(CalmModeController.prefKey), isTrue);
  });
}
