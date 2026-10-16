import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/features/padre/padre_controller.dart';
import 'package:bluetalk/features/padre/padre_screen.dart';

import 'harness.dart';

/// Preferencias con los términos aceptados y un PIN «1234» ya creado.
Future<SharedPreferences> _prefsDeSesion() async {
  final prefs = await prefsDePrueba(
    iniciales: {'padre_legal_aceptacion': aceptacionLegalDePrueba()},
  );
  await crearPinDePrueba(prefs);
  return prefs;
}

/// Escribe el PIN en el gate y pasa al resumen.
Future<void> _entrar(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), '1234');
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
      'la barra inferior navega por las cuatro pestañas tras el gate',
      (tester) async {
    final prefs = await _prefsDeSesion();
    await pumpPadre(
      tester,
      home: PadreScreen(onSalir: () {}),
      overrides: overridesDePadre(prefs),
    );

    // Gate primero: sin escribir el PIN no hay pestañas.
    expect(find.text('Escribe tu código'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await _entrar(tester);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Uso del día'), findsOneWidget);

    await tester.tap(find.text('Control'));
    await tester.pumpAndSettle();
    expect(find.text('Límite diario de juegos'), findsOneWidget);

    await tester.tap(find.text('Salud'));
    await tester.pumpAndSettle();
    expect(find.text('Check-ins de los últimos 7 días'), findsOneWidget);

    await tester.tap(find.text('Legal'));
    await tester.pumpAndSettle();
    expect(find.text('Términos y condiciones'), findsOneWidget);

    await tester.tap(find.text('Resumen'));
    await tester.pumpAndSettle();
    expect(find.text('Uso del día'), findsOneWidget);
  });

  testWidgets('cerrar sesión vuelve al gate con el PIN', (tester) async {
    final prefs = await _prefsDeSesion();
    final container = await pumpPadre(
      tester,
      home: PadreScreen(onSalir: () {}),
      overrides: overridesDePadre(prefs),
    );
    await _entrar(tester);

    await tester.tap(find.byTooltip('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(container.read(padreProvider), PadreVista.gate);
    expect(find.text('Escribe tu código'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('sin código creado el gate ofrece crearlo', (tester) async {
    final prefs = await prefsDePrueba(
      iniciales: {'padre_legal_aceptacion': aceptacionLegalDePrueba()},
    );
    final container = await pumpPadre(
      tester,
      home: PadreScreen(onSalir: () {}),
      overrides: overridesDePadre(prefs),
    );

    expect(container.read(padreProvider), PadreVista.gate);
    expect(find.text('Crea tu código de 4 dígitos'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('el botón salir sale del modo padre', (tester) async {
    var salidas = 0;
    final prefs = await _prefsDeSesion();
    final container = await pumpPadre(
      tester,
      home: PadreScreen(onSalir: () => salidas++),
      overrides: overridesDePadre(prefs),
    );

    await tester.tap(find.byTooltip('Salir del modo padre'));
    await tester.pump();

    expect(salidas, 1);
    expect(container.read(padreProvider), PadreVista.gate,
        reason: 'al salir también se cierra la sesión');
  });
}
