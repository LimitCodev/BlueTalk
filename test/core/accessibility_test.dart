import 'dart:io';

import 'package:accessibility_tools/accessibility_tools.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/app.dart';
import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/ajustes/ajustes_screen.dart';
import 'package:bluetalk/features/comunicador/tts_service.dart';
import 'package:bluetalk/features/onboarding/onboarding_screen.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';

import '../comunicador/dobles.dart';
import 'accessibility_helper.dart';

/// Auditoría de accesibilidad de la Ola 1 (regla dura plan 00 §5: targets
/// táctiles ≥48dp para app AAC infantil). Convierte los avisos de
/// `accessibility_tools` en gate: falla el test.
void main() {
  Future<SharedPreferences> givenPrefs() async {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance();
  }

  List<Object> overridesCon(SharedPreferences prefs) =>
      [sharedPreferencesProvider.overrideWithValue(prefs)];

  // El shell aloja el comunicador real: seeds de disco + TTS falso para
  // tests herméticos (el canal de assets de flutter test solo responde en
  // el primer testWidgets del archivo).
  List<Object> overridesDeShell(SharedPreferences prefs) => [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialProfileProvider.overrideWithValue(
          const ChildProfile(id: 'local', nickname: 'Sol'),
        ),
        ttsSpeakerProvider.overrideWithValue(FakeTtsSpeaker()),
        seedStoreProvider.overrideWithValue(
          SeedStore(
            (path) => SynchronousFuture<String>(File(path).readAsStringSync()),
          ),
        ),
      ];

  testWidgets('onboarding: sin problemas de accesibilidad', (tester) async {
    final prefs = await givenPrefs();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesCon(prefs),
      home: const OnboardingScreen(),
    );
  });

  testWidgets('ajustes: sin problemas de accesibilidad', (tester) async {
    final prefs = await givenPrefs();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesCon(prefs),
      home: const Scaffold(body: AjustesScreen()),
    );
  });

  testWidgets('shell completo: sin problemas de accesibilidad', (tester) async {
    final prefs = await givenPrefs();
    // El checker va por encima de la app completa: MediaQuery y Directionality
    // exteriores porque su overlay se construye por encima del WidgetsApp.
    final issues = await problemasDeAccesibilidad(
      tester,
      MediaQuery(
        data: const MediaQueryData(size: Size(800, 600)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AccessibilityTools(
            child: ProviderScope(
              // Riverpod 3 no exporta `Override` (solo se infiere): cast()
              // lo deduce del parámetro de ProviderScope.
              overrides: overridesDeShell(prefs).cast(),
              child: const BlueTalkApp(),
            ),
          ),
        ),
      ),
    );

    expect(
      issues,
      isEmpty,
      reason: 'Problemas de accesibilidad en el shell:\n${issues.join('\n')}',
    );
  });

  testWidgets('modo calma no rompe la auditoría del shell', (tester) async {
    final prefs = await givenPrefs();
    await tester.pumpWidget(
      ProviderScope(
        overrides: overridesDeShell(prefs).cast(),
        child: const BlueTalkApp(),
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(
      tester.element(find.byType(BlueTalkApp)),
    );
    await container.read(calmModeProvider.notifier).set(true);
    await tester.pumpAndSettle();

    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(find.text('Comunicar'), findsWidgets);
  });
}
