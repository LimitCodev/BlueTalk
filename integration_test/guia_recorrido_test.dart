import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/app.dart';
import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/guia/guia_controller.dart';
import 'package:bluetalk/features/inicio/inicio_screen.dart';
import 'package:bluetalk/features/onboarding/onboarding_screen.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';
import 'package:bluetalk/features/padre/legal/legal_screen.dart';

/// Recorrido de la guía en el emulador (plan 14B §5 pasos 4 y 6):
/// instalación limpia → nombre → 11 pasos → condiciones → código → Resumen,
/// y luego los 11 pasos otra vez con el modo calma. Guarda una captura por
/// paso con `test_driver/capturas_driver.dart`.
///
/// ```
/// flutter drive --driver=test_driver/capturas_driver.dart \
///   --target=integration_test/guia_recorrido_test.dart
/// ```
Future<SharedPreferences> _prefs(Map<String, Object> valores) async {
  // Preferencias en memoria: el estado de una instalación limpia sin
  // tocar los datos reales del teléfono.
  SharedPreferences.setMockInitialValues(valores);
  return SharedPreferences.getInstance();
}

Future<void> _app(
  WidgetTester tester,
  SharedPreferences prefs, {
  ChildProfile? perfil,
}) async {
  await tester.pumpWidget(const SizedBox.shrink()); // nuevo ProviderScope
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialProfileProvider.overrideWithValue(perfil),
      ],
      child: const BlueTalkApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Espera a que aparezca [finder]: el código se deriva con PBKDF2 en el
/// teléfono y tarda más que un frame.
Future<void> _esperar(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

Future<void> _recorrer(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String prefijo,
) async {
  for (var n = 1; n <= 11; n++) {
    expect(find.text('Paso $n de 11'), findsOneWidget);
    await binding.takeScreenshot('$prefijo-${'$n'.padLeft(2, '0')}');
    if (n < 11) {
      await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
      await tester.pumpAndSettle();
    }
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guía completa en claro y en calma', (tester) async {
    // El borde respira en bucle y `pumpAndSettle` no acabaría; las
    // capturas son fotos fijas, así que el resultado visual es el mismo.
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    final prefs = await _prefs({});
    await _app(tester, prefs);
    await binding.convertFlutterSurfaceToImage();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Sol');
    await tester.pump(); // «Comenzar» se habilita tras onChanged
    await tester.tap(find.widgetWithText(FilledButton, 'Comenzar'));
    await _esperar(tester, find.byType(InicioScreen));
    await tester.pumpAndSettle();

    await _recorrer(tester, binding, '14b-paso');
    await tester.tap(find.text('Ir al Modo padre'));
    await tester.pumpAndSettle();
    expect(prefs.getBool(GuiaController.claveVista), isTrue);

    expect(find.byType(LegalScreen), findsOneWidget);
    await binding.takeScreenshot('14b-condiciones');
    final casilla = find.byType(CheckboxListTile);
    await tester.ensureVisible(casilla);
    await tester.tap(casilla);
    await tester.pumpAndSettle();
    final aceptar = find.widgetWithText(FilledButton, 'Aceptar y continuar');
    await tester.ensureVisible(aceptar);
    await tester.tap(aceptar);
    await tester.pumpAndSettle();

    // Código de prueba; cada botón se habilita tras onChanged.
    await tester.enterText(find.byType(TextField), '246810');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '246810');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await _esperar(tester, find.text('Resumen'));
    await tester.pumpAndSettle();
    await binding.takeScreenshot('14b-resumen');

    // Segundo arranque: el menú sale sin guía.
    await _app(
      tester,
      prefs,
      perfil: const ChildProfile(id: 'local', nickname: 'Sol'),
    );
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.textContaining('de 11'), findsNothing);

    // Con el modo calma: la misma guía, en grises y sin movimiento.
    final calma = await _prefs({CalmModeController.prefKey: true});
    await _app(
      tester,
      calma,
      perfil: const ChildProfile(id: 'local', nickname: 'Sol'),
    );
    await _recorrer(tester, binding, '14b-calma');
  });
}
