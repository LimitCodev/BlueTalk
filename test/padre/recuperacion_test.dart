import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/features/padre/gate/gate_screen.dart';
import 'package:bluetalk/features/padre/gate/pin_store.dart';

import 'harness.dart';

/// Bombea el gate solo (ruta mínima al estilo de gate_test).
Future<ProviderContainer> _pumpGate(
  WidgetTester tester,
  SharedPreferences prefs,
) async {
  final rutas = GoRouter(
    initialLocation: '/gate',
    routes: [
      GoRoute(
        path: '/gate',
        builder: (context, state) => const Scaffold(body: GateScreen()),
      ),
    ],
  );
  addTearDown(rutas.dispose);

  final container = ProviderContainer(
    overrides: overridesDePadre(prefs).cast(),
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: DefaultAssetBundle(
        bundle: DiskAssetBundle(),
        child: MaterialApp.router(routerConfig: rutas),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('el código de recuperación recupera sin borrar los datos',
      (tester) async {
    final prefs = await prefsDePrueba(
      iniciales: {
        'padre_legal_aceptacion': aceptacionLegalDePrueba(),
        'comunicador_favoritos': '["ayuda"]',
      },
    );
    await crearPinDePrueba(prefs);
    await sembrarRecuperacionDePrueba(prefs);
    await _pumpGate(tester, prefs);

    expect(find.text('Escribe tu código'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, '¿Olvidaste el código?'));
    await tester.pumpAndSettle();

    // Las dos conviven: la no destructiva va primero.
    expect(find.text('Con tu código de recuperación'), findsOneWidget);

    final recuperar = find.widgetWithText(
      FilledButton,
      'Recuperar sin borrar nada',
    );
    expect(
      tester.widget<FilledButton>(recuperar).onPressed,
      isNull,
      reason: 'el botón está apagado hasta teclear algo',
    );

    final campoCodigo = find.widgetWithText(
      TextField,
      'Código de recuperación',
    );

    // Código de forma válida pero erróneo: aviso literal, sin salir.
    await tester.enterText(campoCodigo, 'WWWW-2222');
    await tester.pump();
    await tester.ensureVisible(recuperar);
    await tester.pumpAndSettle();
    await tester.tap(recuperar);
    await tester.pumpAndSettle();
    expect(find.text('Código de recuperación incorrecto.'), findsOneWidget);
    expect(prefs.getString('comunicador_favoritos'), '["ayuda"]');

    // Código correcto (acepta minúsculas y sin guion): vuelve al gate en
    // fase de creación y los datos siguen intactos.
    await tester.enterText(campoCodigo, 'abcd2345');
    await tester.pump();
    await tester.ensureVisible(recuperar);
    await tester.pumpAndSettle();
    await tester.tap(recuperar);
    await tester.pumpAndSettle();

    expect(find.text('Crea tu código de 6 dígitos'), findsOneWidget);
    expect(
      find.text('Código correcto. Crea un código nuevo.'),
      findsOneWidget,
    );
    expect(prefs.getString('comunicador_favoritos'), '["ayuda"]');
    expect(
      prefs.getString(PinStore.claveHash),
      isNull,
      reason: 'solo se borró el PIN',
    );
    expect(prefs.getString(PinStore.claveRecupHash), isNotNull);
  });

  testWidgets('sin código de recuperación solo queda la opción de borrar',
      (tester) async {
    final prefs = await prefsDePrueba(
      iniciales: {'padre_legal_aceptacion': aceptacionLegalDePrueba()},
    );
    await crearPinDePrueba(prefs);
    await _pumpGate(tester, prefs);

    await tester.tap(find.widgetWithText(TextButton, '¿Olvidaste el código?'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('no guardó ningún código de recuperación'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, 'Recuperar sin borrar nada'),
      findsNothing,
    );
    // Un solo campo de texto: el de BORRAR (los tests de gate_test lo
    // buscan por tipo, así que no pueden duplicarse).
    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Borrar todo y empezar de nuevo'),
      findsOneWidget,
    );
  });
}
