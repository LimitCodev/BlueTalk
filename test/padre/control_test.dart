import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/comunicador/tts_service.dart';
import 'package:bluetalk/features/padre/control/control_parental.dart';
import 'package:bluetalk/features/padre/control/control_screen.dart';
import 'package:bluetalk/features/padre/control/juegos_gate.dart';
import 'package:bluetalk/features/padre/gate/pin_store.dart';

import '../comunicador/dobles.dart';
import 'harness.dart';

/// Juegos usados hoy, repartidos en dos sesiones de [minutos] cada una.
Future<void> _sembrarJuegoHoy(SharedPreferences prefs, int minutos) =>
    sembrarEventos(prefs, [
      for (var i = 0; i < 2; i++)
        UsageEvent(
          id: 'j$i',
          type: 'juego_fin',
          createdAt: ahoraFija,
          data: {'juego': 'memoria', 'segundos': minutos * 60 ~/ 2},
        ),
    ]);

void main() {
  testWidgets('el control muestra el límite activo y sus secciones',
      (tester) async {
    final prefs = await prefsDePrueba();
    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: ControlScreen()),
      overrides: overridesDePadre(prefs),
    );

    expect(find.text('Tiempo de juegos'), findsOneWidget);
    expect(find.text('Límite diario de juegos'), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('Juegos'), findsOneWidget);
    expect(find.text('Mi entorno'), findsOneWidget);

    // Apagar el límite no pierde el valor anterior (30 min).
    await tester.tap(find.widgetWithText(SwitchListTile, 'Límite diario de juegos'));
    await tester.pumpAndSettle();
    expect(container.read(limiteJuegosProvider).requireValue.sinLimite, isTrue);
    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Límite diario de juegos'));
    await tester.pumpAndSettle();
    expect(
      container.read(limiteJuegosProvider).requireValue.minutosPorDia,
      30,
    );

    // Bloquear la sección Juegos persiste en preferencias.
    await tester.tap(find.widgetWithText(SwitchListTile, 'Juegos'));
    await tester.pumpAndSettle();
    expect(container.read(bloqueosProvider).juegos, isTrue);
    expect(prefs.getBool('padre_bloqueo_juegos'), isTrue);

    // La fila legal queda bajo el pliegue del ListView: se busca desplazando
    // al final, para no sacar los switches de arriba del árbol perezoso.
    await tester.scrollUntilVisible(
      find.text('Términos y privacidad'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Términos y privacidad'), findsOneWidget);
  });

  testWidgets('con tiempo disponible JuegosGate deja pasar a los juegos',
      (tester) async {
    final prefs = await prefsDePrueba();
    await _sembrarJuegoHoy(prefs, 10);

    await pumpPadre(
      tester,
      home: const Scaffold(
        body: JuegosGate(juegos: Text('PANTALLA DE JUEGOS')),
      ),
      overrides: overridesDePadre(prefs),
    );

    expect(find.text('PANTALLA DE JUEGOS'), findsOneWidget);
    expect(find.text('El tiempo de juegos de hoy terminó.'), findsNothing);
  });

  testWidgets(
      'el tiempo agotado muestra el aviso suave y admite 5 minutos más',
      (tester) async {
    final prefs = await prefsDePrueba();
    await _sembrarJuegoHoy(prefs, 31);

    final container = await pumpPadre(
      tester,
      home: const Scaffold(
        body: JuegosGate(juegos: Text('PANTALLA DE JUEGOS')),
      ),
      overrides: overridesDePadre(prefs),
    );

    expect(find.text('PANTALLA DE JUEGOS'), findsNothing);
    expect(
      find.text('El tiempo de juegos de hoy terminó.'),
      findsOneWidget,
    );
    expect(
      find.text('Has jugado 31 de 30 minutos de hoy.'),
      findsOneWidget,
    );
    // Corte suave: nada de pantalla roja, y se puede salir.
    expect(find.widgetWithText(OutlinedButton, 'Salir'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Jugar 5 minutos más'));
    await tester.pumpAndSettle();

    expect(find.text('PANTALLA DE JUEGOS'), findsOneWidget);
    expect(prefs.getInt('padre_limite_extension'), 5);
    expect(container.read(limiteJuegosProvider).requireValue.extensionMinutos, 5);
  });

  testWidgets('la ampliación del día sigue activa al reabrir', (tester) async {
    final prefs = await prefsDePrueba();
    await _sembrarJuegoHoy(prefs, 31);
    await prefs.setInt('padre_limite_extension', 5);
    await prefs.setString(
      'padre_limite_extension_dia',
      '${ahoraFija.year}-${ahoraFija.month}-${ahoraFija.day}',
    );

    await pumpPadre(
      tester,
      home: const Scaffold(
        body: JuegosGate(juegos: Text('PANTALLA DE JUEGOS')),
      ),
      overrides: overridesDePadre(prefs),
    );

    expect(find.text('PANTALLA DE JUEGOS'), findsOneWidget);
  });

  testWidgets('el bloqueo de la sección corta la entrada aunque haya tiempo',
      (tester) async {
    final prefs = await prefsDePrueba();
    await _sembrarJuegoHoy(prefs, 5);
    await prefs.setBool('padre_bloqueo_juegos', true);

    await pumpPadre(
      tester,
      home: const Scaffold(
        body: JuegosGate(juegos: Text('PANTALLA DE JUEGOS')),
      ),
      overrides: overridesDePadre(prefs),
    );

    expect(find.text('PANTALLA DE JUEGOS'), findsNothing);
    expect(
      find.text('Los juegos están bloqueados por un adulto.'),
      findsOneWidget,
    );
    expect(find.text('Jugar 5 minutos más'), findsNothing);
  });

  testWidgets('con el límite apagado no se corta nunca', (tester) async {
    final prefs = await prefsDePrueba();
    await prefs.setInt('padre_limite_juegos_min', 0);
    await _sembrarJuegoHoy(prefs, 120);

    final container = await pumpPadre(
      tester,
      home: const Scaffold(
        body: JuegosGate(juegos: Text('PANTALLA DE JUEGOS')),
      ),
      overrides: overridesDePadre(prefs),
    );

    expect(find.text('PANTALLA DE JUEGOS'), findsOneWidget);
    expect(await container.read(juegosPermitidosProvider.future), isTrue);
  });

  testWidgets('cambiar código exige 6 dígitos y guarda la nueva huella',
      (tester) async {
    final prefs = await prefsDePrueba();
    await crearPinDePrueba(prefs); // PIN sembrado de 4 dígitos (esquema viejo).
    final huellaVieja = prefs.getString(PinStore.claveHash);

    await pumpPadre(
      tester,
      home: const Scaffold(body: ControlScreen()),
      overrides: overridesDePadre(prefs),
    );

    await tester.scrollUntilVisible(
      find.text('Cambiar código'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Cambiar código'));
    await tester.pumpAndSettle();
    expect(find.text('Cambia el código'), findsOneWidget);

    final guardar = find.widgetWithText(FilledButton, 'Guardar');
    expect(
      tester.widget<FilledButton>(guardar).onPressed,
      isNull,
      reason: 'sin 6+6 dígitos no se puede guardar',
    );

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), '111111');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(guardar).onPressed,
      isNull,
      reason: 'falta repetir el código',
    );

    // Confirmación distinta: aviso literal y la huella no cambia.
    await tester.enterText(campos.at(1), '111112');
    await tester.pump();
    await tester.tap(guardar);
    await tester.pumpAndSettle();
    expect(find.text('Los códigos no coinciden.'), findsOneWidget);
    expect(prefs.getString(PinStore.claveHash), huellaVieja);
    expect(find.text('Cambia el código'), findsOneWidget);

    // Ahora coinciden: se guarda la huella nueva con 6 dígitos.
    await tester.enterText(campos.at(1), '111111');
    await tester.pump();
    await tester.tap(guardar);
    await tester.pumpAndSettle();

    expect(find.text('Cambia el código'), findsNothing);
    expect(prefs.getInt(PinStore.claveLongitud), 6);
    expect(prefs.getString(PinStore.claveHash), isNot(huellaVieja));

    // Verificación real con el derivador por defecto (isolate): fuera del
    // FakeAsync de testWidgets, vía `runAsync` (plan 12 §0.2).
    final resultado = await tester.runAsync(
      () => PinStore(prefs, ahora: () => ahoraFija).verificar('111111'),
    );
    expect(resultado, VerificacionPin.correcto);

    // El aviso del SnackBar se consume para no dejar timers pendientes.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets(
      'diagnóstico de voz: solo habla bajo toque y Atrás vuelve (P6.1)',
      (tester) async {
    final prefs = await prefsDePrueba();
    final container = await pumpPadre(
      tester,
      home: const Scaffold(body: ControlScreen()),
      overrides: [
        ttsSpeakerProvider.overrideWithValue(FakeTtsSpeaker()),
        ...overridesDePadre(prefs),
      ],
    );

    // La lista del control es perezosa: hay que desplazarse hasta la
    // entrada nueva para que exista en el árbol (plan 13 P6.1).
    final probarVoz = find.widgetWithText(ListTile, 'Probar la voz');
    await tester.scrollUntilVisible(
      probarVoz,
      240,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    await tester.tap(probarVoz);
    await tester.pumpAndSettle();
    expect(find.text('¿No se oye? Toca aquí'), findsOneWidget);

    final tts = container.read(ttsSpeakerProvider) as FakeTtsSpeaker;
    expect(tts.spoken, isEmpty, reason: 'la pantalla de prueba no habla sola');

    await tester.tap(
      find.widgetWithText(FilledButton, '¿No se oye? Toca aquí'),
    );
    await tester.pump();
    expect(tts.spoken, ['Hola, soy BlueTalk'], reason: 'habla bajo toque');

    // Atrás de subpantalla empujada: vuelve al control (plan 13 P1).
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('¿No se oye? Toca aquí'), findsNothing);
    expect(
      find.text('Desbloqueo'),
      findsOneWidget,
      reason: 'vuelve al control parental',
    );
  });
}
