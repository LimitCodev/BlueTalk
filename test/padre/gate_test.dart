import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/features/padre/gate/gate_controller.dart';
import 'package:bluetalk/features/padre/gate/gate_screen.dart';
import 'package:bluetalk/features/padre/padre_controller.dart';

import 'harness.dart';

Future<void> _escribir(WidgetTester tester, String pin) async {
  await tester.enterText(find.byType(TextField), pin);
  await tester.pump();
}

void main() {
  testWidgets('la primera vez pide crear el código y confirmarlo',
      (tester) async {
    final prefs = await prefsDePrueba();
    final reloj = RelojPrueba();
    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: GateScreen()),
      overrides: overridesDePadre(prefs, reloj: reloj),
    );

    expect(find.text('Crea tu código de 4 dígitos'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuar'))
          .onPressed,
      isNull,
      reason: 'sin 4 dígitos el botón sigue apagado',
    );

    await _escribir(tester, '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Confirma tu código'), findsOneWidget);

    // Confirmación errónea: vuelve a empezar con aviso literal.
    await _escribir(tester, '9999');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();
    expect(
      find.text('Los códigos no coinciden. Intenta de nuevo.'),
      findsOneWidget,
    );
    expect(find.text('Crea tu código de 4 dígitos'), findsOneWidget);

    await _escribir(tester, '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Continuar'));
    await tester.pumpAndSettle();
    await _escribir(tester, '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(container.read(gateProvider).desbloqueado, isTrue);
    expect(container.read(padreProvider), PadreVista.resumen);

    // En preferencias solo está la huella, nunca el código.
    expect(prefs.getString('padre_pin_hash'), isNotNull);
    for (final clave in prefs.getKeys()) {
      expect(prefs.get(clave), isNot('1234'));
    }
  });

  testWidgets('un código incorrecto muestra el aviso del plan',
      (tester) async {
    final prefs = await prefsDePrueba();
    await crearPinDePrueba(prefs);
    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: GateScreen()),
      overrides: overridesDePadre(prefs),
    );

    await _escribir(tester, '9999');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Código incorrecto, inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(container.read(gateProvider).desbloqueado, isFalse);
    expect(container.read(gateProvider).bloqueo, Duration.zero);
  });

  testWidgets('cinco códigos incorrectos bloquean 60 segundos',
      (tester) async {
    final prefs = await prefsDePrueba();
    await crearPinDePrueba(prefs);
    final reloj = RelojPrueba();
    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: GateScreen()),
      overrides: overridesDePadre(prefs, reloj: reloj),
    );

    for (var intento = 1; intento <= 5; intento++) {
      await _escribir(tester, '0000');
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();
    }

    expect(
      find.text('Demasiados intentos. Espera 60 segundos.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Entrar'))
          .onPressed,
      isNull,
      reason: 'con la espera activa el botón queda apagado',
    );

    // Ni siquiera el código correcto desbloquea durante la espera.
    await container.read(gateProvider.notifier).intentar('1234');
    expect(container.read(gateProvider).desbloqueado, isFalse);

    // Pasan los 60 segundos: la cuenta atrás termina y se puede volver.
    reloj.avanzar(const Duration(seconds: 60));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Entrar'))
          .onPressed,
      isNotNull,
    );

    await _escribir(tester, '1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(container.read(gateProvider).desbloqueado, isTrue);
    expect(container.read(padreProvider), PadreVista.resumen);
  });

  testWidgets('el bloqueo persistido se ve al reabrir la app', (tester) async {
    final prefs = await prefsDePrueba();
    await crearPinDePrueba(prefs);
    final reloj = RelojPrueba();
    // Bloqueo guardado hace 10 segundos (quedan 50).
    await prefs.setInt(
      'padre_pin_bloqueo_hasta',
      reloj.ahora
          .add(const Duration(seconds: 60))
          .subtract(const Duration(seconds: 10))
          .millisecondsSinceEpoch,
    );

    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: GateScreen()),
      overrides: overridesDePadre(prefs, reloj: reloj),
    );

    expect(
      find.text('Demasiados intentos. Espera 50 segundos.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Entrar'))
          .onPressed,
      isNull,
    );
    expect(container.read(gateProvider).desbloqueado, isFalse);

    // Al terminar se completa la cuenta atrás: el timer de la cuenta atrás
    // se cancela solo y no queda ninguno huérfano al disposal del árbol.
    reloj.avanzar(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('la huella entra solo cuando el interruptor está activo',
      (tester) async {
    final prefs = await prefsDePrueba();
    await crearPinDePrueba(prefs);
    final biometria = BiometriaPrueba()..autenticarOk = true;

    await pumpPadre(
      tester,
      home: const Scaffold(body: GateScreen()),
      overrides: overridesDePadre(prefs, biometria: biometria),
    );
    expect(find.text('Usar huella o rostro'), findsNothing);

    // Activado desde el control parental: aparece el botón y desbloquea.
    await prefs.setBool('padre_biometria', true);
    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: GateScreen()),
      overrides: overridesDePadre(prefs, biometria: biometria),
    );

    expect(find.text('Usar huella o rostro'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Usar huella o rostro'));
    await tester.pumpAndSettle();

    expect(biometria.autenticaciones, 1);
    expect(container.read(gateProvider).desbloqueado, isTrue);
    expect(container.read(padreProvider), PadreVista.resumen);
  });

  testWidgets('un fallo de la huella avisa y deja el código disponible',
      (tester) async {
    final prefs = await prefsDePrueba();
    await crearPinDePrueba(prefs);
    await prefs.setBool('padre_biometria', true);
    final biometria = BiometriaPrueba()..autenticarOk = false;

    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: GateScreen()),
      overrides: overridesDePadre(prefs, biometria: biometria),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Usar huella o rostro'));
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudo comprobar. Escribe tu PIN.'),
      findsOneWidget,
    );
    expect(container.read(gateProvider).desbloqueado, isFalse);
  });
}
