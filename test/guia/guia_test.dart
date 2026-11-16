import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/app.dart';
import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/app/router.dart';
import 'package:bluetalk/data/local/seed_store.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/comunicador/comunicador_screen.dart';
import 'package:bluetalk/features/comunicador/tts_service.dart';
import 'package:bluetalk/features/guia/guia_controller.dart';
import 'package:bluetalk/features/guia/guia_fondo.dart';
import 'package:bluetalk/features/guia/guia_lista.dart';
import 'package:bluetalk/features/guia/guia_objetivos.dart';
import 'package:bluetalk/features/guia/guia_pasos.dart';
import 'package:bluetalk/features/guia/mascota.dart';
import 'package:bluetalk/features/inicio/inicio_screen.dart';
import 'package:bluetalk/features/onboarding/profile_controller.dart';
import 'package:bluetalk/features/padre/gate/gate_controller.dart';
import 'package:bluetalk/features/padre/legal/legal_screen.dart';

import '../comunicador/dobles.dart';
import '../padre/harness.dart';

/// Guía de primera vez con la mascota (plan 14B), sobre la app real.
Future<(ProviderContainer, SharedPreferences)> _pump(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final p = await SharedPreferences.getInstance();
  // El borde del hueco respira en bucle: sin esto `pumpAndSettle` no acaba.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(p),
        initialProfileProvider.overrideWithValue(
          const ChildProfile(id: 'local', nickname: 'Sol'),
        ),
        ttsSpeakerProvider.overrideWithValue(FakeTtsSpeaker()),
        seedStoreProvider.overrideWithValue(
          SeedStore(
            (path) => SynchronousFuture<String>(File(path).readAsStringSync()),
          ),
        ),
        derivadorPinProvider.overrideWithValue(const DerivadorPinPrueba()),
      ],
      child: const BlueTalkApp(),
    ),
  );
  await tester.pumpAndSettle();
  final c = ProviderScope.containerOf(tester.element(find.byType(BlueTalkApp)));
  return (c, p);
}

Future<void> _siguiente(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Siguiente'));
  await tester.pumpAndSettle();
}

/// El hueco iluminado coincide con el objetivo del paso.
void _huecoSobre(GuiaObjetivo objetivo, Finder widget, WidgetTester tester) {
  final rect = rectDe(objetivo);
  expect(rect, isNotNull, reason: '$objetivo está en pantalla');
  expect(rect, tester.getRect(widget));
}

void main() {
  test('cada postura tiene su imagen en assets/mascota', () {
    for (final p in PosturaAve.values) {
      expect(File(p.asset).existsSync(), isTrue, reason: p.asset);
    }
    expect(pasosGuia, hasLength(11));
  });

  testWidgets(
    'recorrido completo: menú, Comunicar y termina en el Modo padre',
    (tester) async {
      final (c, prefs) = await _pump(tester);
      expect(find.byType(InicioScreen), findsOneWidget);
      expect(find.text('Paso 1 de 11'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Atrás'), findsNothing);

      await _siguiente(tester); // 2: carrusel
      expect(rectDe(GuiaObjetivo.menuCarrusel), isNotNull);
      for (var i = 0; i < 4; i++) {
        await _siguiente(tester); // 3–6: tarjetas, cada una centrada
      }
      expect(find.text('Paso 6 de 11'), findsOneWidget);
      _huecoSobre(
        GuiaObjetivo.tarjetaAjustes,
        find.byKey(guiaClaves[GuiaObjetivo.tarjetaAjustes]!),
        tester,
      );

      await _siguiente(tester); // 7: Comunicar
      expect(find.byType(ComunicadorScreen), findsOneWidget);
      expect(rectDe(GuiaObjetivo.fraseBarra), isNotNull);
      await _siguiente(tester); // 8
      expect(rectDe(GuiaObjetivo.tableroNuclear), isNotNull);
      await _siguiente(tester); // 9
      await _siguiente(tester); // 10
      expect(rectDe(GuiaObjetivo.barraSuperior), isNotNull);

      await _siguiente(tester); // 11: vuelve al menú
      expect(find.byType(InicioScreen), findsOneWidget);
      expect(
        find.textContaining('crea un código de 6 dígitos'),
        findsOneWidget,
      );
      await tester.tap(find.text('Ir al Modo padre'));
      await tester.pumpAndSettle();

      expect(find.byType(LegalScreen), findsOneWidget);
      expect(c.read(guiaProvider), isNull);
      expect(prefs.getBool(GuiaController.claveVista), isTrue);
    },
  );

  testWidgets('Atrás de la guía y del teléfono retroceden un paso', (
    tester,
  ) async {
    final (c, _) = await _pump(tester);
    await _siguiente(tester);
    await _siguiente(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Atrás'));
    await tester.pumpAndSettle();
    expect(c.read(guiaProvider), 1);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(c.read(guiaProvider), 0);
    // En el paso 1, Atrás no hace nada (ni sale de la app).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(c.read(guiaProvider), 0);
  });

  testWidgets('el fondo gris no deja tocar la app', (tester) async {
    final (c, _) = await _pump(tester);
    await _siguiente(tester);
    await _siguiente(tester); // 3: Comunicar centrada e iluminada
    await tester.tap(find.text('Comunicar').first, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(c.read(guiaProvider), 2);
  });

  testWidgets('Saltar pide confirmación y lleva al Modo padre', (tester) async {
    final (c, prefs) = await _pump(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Saltar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('¿Saltar la guía?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Seguir'));
    await tester.pumpAndSettle();
    expect(c.read(guiaProvider), 0);

    await tester.tap(find.widgetWithText(TextButton, 'Saltar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Saltar'));
    await tester.pumpAndSettle();
    expect(find.byType(LegalScreen), findsOneWidget);
    expect(prefs.getBool(GuiaController.claveVista), isTrue);
  });

  testWidgets('vista una vez, no vuelve a salir sola', (tester) async {
    final (c, _) = await _pump(
      tester,
      prefs: {GuiaController.claveVista: true},
    );
    expect(find.byType(InicioScreen), findsOneWidget);
    expect(c.read(guiaProvider), isNull);
    expect(find.textContaining('Paso 1'), findsNothing);
  });

  testWidgets('modo calma: la mascota aparece sin animación', (tester) async {
    await _pump(tester, prefs: {'bluetalk_calm_mode': true});
    expect(find.byType(Ave), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(Ave),
        matching: find.byType(TweenAnimationBuilder<double>),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'Ver la guía otra vez desde Ajustes vuelve al menú en el paso 1',
    (tester) async {
      final (c, _) = await _pump(
        tester,
        prefs: {GuiaController.claveVista: true},
      );
      c.read(routerProvider).go('/home/ajustes');
      await tester.pumpAndSettle();
      final tile = find.text('Ver la guía otra vez');
      await tester.scrollUntilVisible(tile, 300);
      // La fila queda tras la barra inferior en la pantalla de prueba.
      final fila = find.ancestor(of: tile, matching: find.byType(ListTile));
      tester.widget<ListTile>(fila).onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(InicioScreen), findsOneWidget);
      expect(find.text('Paso 1 de 11'), findsOneWidget);
    },
  );

  testWidgets('el borde respira y se queda quieto sin animaciones', (
    tester,
  ) async {
    Animation<double> brillo() =>
        (tester.widget<CustomPaint>(find.byType(CustomPaint).last).painter!
                as GuiaFondo)
            .brillo!;
    Widget fondo({required bool quieto}) => MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: quieto),
        child: const GuiaFondoQueRespira(
          hueco: Rect.fromLTWH(10, 10, 100, 50),
          borde: Colors.blue,
        ),
      ),
    );

    await tester.pumpWidget(fondo(quieto: false));
    final antes = brillo().value;
    await tester.pump(const Duration(milliseconds: 300));
    expect(brillo().value, isNot(antes));
    expect(brillo().value, inInclusiveRange(0.6, 1));

    await tester.pumpWidget(fondo(quieto: true));
    await tester.pump(const Duration(milliseconds: 300));
    expect(brillo().value, 1);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('con el código ya creado, el paso 11 dice que entras con él', (
    tester,
  ) async {
    final (c, p) = await _pump(
      tester,
      prefs: {GuiaController.claveVista: true},
    );
    await crearPinDePrueba(p);
    final guia = c.read(guiaProvider.notifier)..iniciar();
    for (var i = 0; i < 10; i++) {
      guia.siguiente();
      await tester.pumpAndSettle();
    }
    expect(find.text('Paso 11 de 11'), findsOneWidget);
    expect(find.textContaining('Aquí entras con tu código'), findsOneWidget);
    expect(find.textContaining('crea un código'), findsNothing);
  });
}
