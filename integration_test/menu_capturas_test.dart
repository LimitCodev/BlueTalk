import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/app.dart';
import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/app/router.dart';
import 'package:bluetalk/core/theme/calm_mode.dart';
import 'package:bluetalk/features/ajustes/settings_controller.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/guia/guia_controller.dart';
import 'package:bluetalk/features/inicio/inicio_screen.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';

/// Evidencia del menú principal (plan 14A §A5) en el emulador: capturas en
/// claro, oscuro y calma, y la tabla de Atrás (plan 14 §2) con el mismo
/// `handlePopRoute` que llama el botón Atrás de Android.
///
/// En horizontal se gira el emulador antes y se pasa
/// `--dart-define=SUFIJO=-horizontal` para no pisar las capturas.
const _sufijo = String.fromEnvironment('SUFIJO');

Future<ProviderContainer> _app(
  WidgetTester tester,
  Map<String, Object> valores,
) async {
  SharedPreferences.setMockInitialValues({
    GuiaController.claveVista: true,
    ...valores,
  });
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(const SizedBox.shrink()); // nuevo ProviderScope
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialProfileProvider.overrideWithValue(
          const ChildProfile(id: 'local', nickname: 'Sol'),
        ),
      ],
      child: const BlueTalkApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(BlueTalkApp)));
}

String _ruta(ProviderContainer c) =>
    c.read(routerProvider).routerDelegate.currentConfiguration.uri.path;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menú en claro, oscuro y calma; Atrás vuelve al menú', (
    tester,
  ) async {
    var c = await _app(tester, {});
    await binding.convertFlutterSurfaceToImage();
    await tester.pump(); // la captura espera un frame nuevo
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(find.text('¡Hola, Sol! 👋'), findsOneWidget);
    await binding.takeScreenshot('14a-menu-claro$_sufijo');

    // Tabla de Atrás: lista de cada sección, Comunicar y el Modo padre.
    for (final ruta in [
      '/home/aprender',
      '/home/rutinas',
      '/home/ajustes',
      '/home/comunicar',
      '/padre',
    ]) {
      c.read(routerProvider).go(ruta);
      await tester.pumpAndSettle();
      expect(_ruta(c), ruta);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_ruta(c), '/inicio', reason: 'Atrás desde $ruta');
    }

    c = await _app(tester, {});
    await c.read(settingsProvider.notifier).setTema('oscuro');
    await tester.pumpAndSettle();
    await binding.takeScreenshot('14a-menu-oscuro$_sufijo');

    await _app(tester, {CalmModeController.prefKey: true});
    await binding.takeScreenshot('14a-menu-calma$_sufijo');
  });
}
