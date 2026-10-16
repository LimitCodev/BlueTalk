import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/legal/legal_controller.dart';
import 'package:bluetalk/features/padre/padre_controller.dart';
import 'package:bluetalk/features/padre/padre_screen.dart';

import 'harness.dart';

/// Desplaza la lista hasta un widget (los documentos son largos).
Future<void> _hasta(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    800,
    scrollable: find.byType(Scrollable).first,
    maxScrolls: 200,
  );
}

void main() {
  testWidgets('muestra los dos documentos y exige el consentimiento',
      (tester) async {
    final prefs = await prefsDePrueba();
    final container = await pumpPadre(
      tester,
      home: PadreScreen(onSalir: () {}),
      overrides: overridesDePadre(prefs),
    );

    expect(container.read(padreProvider), PadreVista.legal);
    expect(find.text('Términos y condiciones'), findsOneWidget);
    expect(
      find.textContaining('BlueTalk es una aplicación móvil de comunicación'),
      findsOneWidget,
    );

    // La lista es perezosa: el segundo documento está fuera del primer
    // pantallazo, así que se lleva la lista hasta su encabezado.
    await _hasta(tester, find.text('Política de privacidad'));
    expect(find.text('Política de privacidad'), findsOneWidget);

    // El bloque de consentimiento está al final de los documentos largos.
    await _hasta(tester, find.widgetWithText(FilledButton, 'Aceptar y continuar'));

    // Sin marcar la casilla no se puede aceptar.
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Aceptar y continuar'),
          )
          .onPressed,
      isNull,
    );

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Aceptar y continuar'));
    await tester.pumpAndSettle();

    final aceptacion = container.read(legalProvider);
    expect(aceptacion, isNotNull);
    expect(aceptacion!.version, '1.0.0');
    expect(aceptacion.consentimientoPadre, isTrue);
    expect(aceptacion.fecha, ahoraFija);

    // Registrada en preferencias con su versión.
    final guardado = prefs.getString('padre_legal_aceptacion');
    expect(guardado, contains('"version":"1.0.0"'));

    // Al aceptar, el modo padre pasa al gate (no al resumen sin PIN).
    expect(container.read(padreProvider), PadreVista.gate);
  });

  testWidgets('el rechazo no deja entrar al modo padre', (tester) async {
    final prefs = await prefsDePrueba();
    var salidas = 0;
    final container = await pumpPadre(
      tester,
      home: PadreScreen(onSalir: () => salidas++),
      overrides: overridesDePadre(prefs),
    );

    await _hasta(tester, find.widgetWithText(OutlinedButton, 'No acepto'));
    await tester.tap(find.widgetWithText(OutlinedButton, 'No acepto'));
    await tester.pumpAndSettle();

    expect(container.read(legalProvider), isNull);
    expect(container.read(padreProvider), PadreVista.legal);

    // La lista quedó al fondo tras llegar al botón: se vuelve al inicio
    // para comprobar que los encabezados siguen en la pantalla legal.
    final lista = tester.state<ScrollableState>(find.byType(Scrollable).first);
    lista.position.jumpTo(0);
    await tester.pump();

    expect(find.text('Términos y condiciones'), findsOneWidget);
    expect(
      find.text('Sin aceptar los términos no puedes entrar al modo padre.'),
      findsOneWidget,
    );

    // Navegar al resumen por la fuerza tampoco pasa.
    container.read(padreProvider.notifier).irA(PadreVista.resumen);
    await tester.pump();
    expect(container.read(padreProvider), PadreVista.legal);

    // Y se puede salir del modo padre.
    await _hasta(tester, find.widgetWithText(TextButton, 'Salir del modo padre'));
    await tester.tap(find.widgetWithText(TextButton, 'Salir del modo padre'));
    await tester.pump();
    expect(salidas, 1);
  });

  testWidgets('la aceptación registrada se muestra con fecha y versión',
      (tester) async {
    final prefs = await prefsDePrueba(
      iniciales: {'padre_legal_aceptacion': aceptacionLegalDePrueba()},
    );
    final container = await pumpPadre(
      tester,
      home: PadreScreen(onSalir: () {}),
      overrides: overridesDePadre(prefs),
    );

    // Con los términos ya aceptados se va directo al gate.
    expect(container.read(padreProvider), PadreVista.gate);

    container.read(padreProvider.notifier).irA(PadreVista.legal);
    await tester.pumpAndSettle();

    expect(find.text('Aceptado el 13/10/2026 (versión 1.0.0).'),
        findsOneWidget);
    expect(find.text('Consentimiento parental registrado.'), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNothing);
  });
}
