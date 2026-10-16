import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/juegos/artista/artista_canvas.dart';
import 'package:bluetalk/features/juegos/artista/artista_controller.dart';
import 'package:bluetalk/features/juegos/artista/artista_dibujos.dart';
import 'package:bluetalk/features/juegos/artista/artista_screen.dart';
import 'package:bluetalk/features/juegos/avance_juegos.dart';

import '../core/accessibility_helper.dart';
import 'harness.dart';

/// Dibuja un trazo horizontal en el centro del lienzo.
Future<void> _dibujarTrazo(WidgetTester tester) async {
  final lienzo = find.byKey(const ValueKey('lienzo_artista'));
  await tester.drag(lienzo, const Offset(-60, 0));
  await tester.pump();
}

void main() {
  testWidgets('deshacer quita el último trazo dibujado', (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();

    await _dibujarTrazo(tester);
    expect(container.read(artistaProvider).trazos, hasLength(1));

    await tester.tap(find.text('Deshacer'));
    await tester.pump();
    expect(container.read(artistaProvider).trazos, isEmpty);
  });

  testWidgets('guardar el dibujo lo mete en la galería local', (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();

    await _dibujarTrazo(tester);
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    final dibujos = container.read(galeriaDibujosProvider);
    expect(dibujos, hasLength(1));
    expect(dibujos.first.trazos, isNotEmpty);

    // La galería vive en una hoja inferior (plan 13 P2).
    await tester.tap(find.text('Mis dibujos'));
    await tester.pumpAndSettle();

    // La miniatura se toca para seguir editando el dibujo y la hoja
    // se cierra al cargarlo.
    await tester.tap(find.byKey(ValueKey('dibujo_${dibujos.first.id}')));
    await tester.pump();
    expect(container.read(artistaProvider).trazos, hasLength(1));
  });

  testWidgets('el dibujo guardado persiste tras reiniciar', (tester) async {
    var container = await pumpJuegos(tester);

    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();
    await _dibujarTrazo(tester);
    await tester.tap(find.text('Guardar'));
    await tester.pump();

    // "Reiniciar": sin preferencias en memoria, la galería sigue ahí.
    container = await pumpJuegos(tester, resetPrefs: false);
    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();

    final dibujos = container.read(galeriaDibujosProvider);
    expect(dibujos, hasLength(1));

    // Y el avance del home lo refleja.
    container = await pumpJuegos(tester, resetPrefs: false);
    await tester.pump();
    expect(
      container.read(avanceJuegosProvider).requireValue.dibujosGuardados,
      1,
    );
  });

  testWidgets('la goma dibuja en blanco por encima', (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Goma'));
    await tester.pump();
    expect(container.read(artistaProvider).goma, isTrue);

    await _dibujarTrazo(tester);
    final trazo = container.read(artistaProvider).trazos.single;
    expect(trazo.color, 0xFFFFFFFF);
  });

  test('los pintores repintan solo cuando cambia su trazo', () {
    const trazo = Trazo(color: 0xFF000000, grosor: 10, puntos: [Offset.zero]);
    const trazo2 = Trazo(
      color: 0xFF000000,
      grosor: 10,
      puntos: [Offset.zero, Offset(0.1, 0.1)],
    );

    // Capa de trazos terminados: solo repinta si cambia la lista.
    expect(
      const TrazosPainter([trazo]).shouldRepaint(const TrazosPainter([trazo])),
      isFalse,
    );
    expect(
      const TrazosPainter([trazo, trazo])
          .shouldRepaint(const TrazosPainter([trazo])),
      isTrue,
    );

    // Capa activa: repinta si cambia el trazo (o aparece/desaparece).
    expect(
      const TrazoActivoPainter(trazo).shouldRepaint(
        const TrazoActivoPainter(trazo),
      ),
      isFalse,
    );
    expect(
      const TrazoActivoPainter(trazo2).shouldRepaint(
        const TrazoActivoPainter(trazo),
      ),
      isTrue,
    );
    expect(
      const TrazoActivoPainter(null).shouldRepaint(
        const TrazoActivoPainter(trazo),
      ),
      isTrue,
    );
  });

  test('la galería llena no guarda ni borra nada (plan 1.3.5)', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    final galeria = container.read(galeriaDibujosProvider.notifier);

    const trazo = Trazo(
      color: 0xFF000000,
      grosor: 10,
      puntos: [Offset(0.1, 0.1), Offset(0.2, 0.2)],
    );

    for (var i = 0; i < GaleriaController.maxDibujos; i++) {
      expect(await galeria.guardar([trazo]), isTrue,
          reason: 'el dibujo ${i + 1} debe caber');
    }
    expect(
      container.read(galeriaDibujosProvider),
      hasLength(GaleriaController.maxDibujos),
    );

    // La siguiente no cabe: se rechaza sin tocar lo ya guardado
    // (nunca se borra un dibujo a escondidas).
    expect(await galeria.guardar([trazo]), isFalse);
    expect(
      container.read(galeriaDibujosProvider),
      hasLength(GaleriaController.maxDibujos),
    );
  });

  testWidgets('con la galería llena, Guardar avisa en lenguaje literal',
      (tester) async {
    final relleno = jsonEncode([
      for (var i = 0; i < GaleriaController.maxDibujos; i++)
        {
          'id': 'd$i',
          'trazos': [
            {
              'color': 0,
              'grosor': 5.0,
              'puntos': [
                [0.1, 0.1],
                [0.2, 0.2],
              ],
            },
          ],
        },
    ]);
    SharedPreferences.setMockInitialValues({
      'bluetalk_artista_dibujos': relleno,
    });
    final container = await pumpJuegos(tester, resetPrefs: false);

    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();
    await _dibujarTrazo(tester);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Tu galería ya tiene ${GaleriaController.maxDibujos} dibujos. '
        'Borra uno de Mis dibujos para guardar este.',
      ),
      findsOneWidget,
    );
    expect(
      container.read(galeriaDibujosProvider),
      hasLength(GaleriaController.maxDibujos),
    );
    // El dibujo en curso no se pierde: se puede seguir editando.
    expect(container.read(artistaProvider).trazos, isNotEmpty);
    await tester.pump(const Duration(seconds: 5)); // cierra el SnackBar
  });

  test('los puntos por dibujo tienen tope (plan 1.3.5)', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final artista = container.read(artistaProvider.notifier);

    const lienzo = Size(100000, 1000);
    artista.empezarTrazo(const Offset(0, 0), lienzo);
    for (var i = 1; i <= GaleriaController.maxPuntosPorDibujo + 500; i++) {
      artista.continuarTrazo(Offset(i * 2.0, 0), lienzo);
    }
    artista.terminarTrazo();

    final total = container
        .read(artistaProvider)
        .trazos
        .fold<int>(0, (suma, t) => suma + t.puntos.length);
    expect(total, GaleriaController.maxPuntosPorDibujo);
  });

  test('una fila corrupta de la galería no rompe la carga (plan 1.3.5)',
      () async {
    SharedPreferences.setMockInitialValues({
      'bluetalk_artista_dibujos': '[{"trazos": "no soy una lista"}]',
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    expect(container.read(galeriaDibujosProvider), isEmpty);
  });

  testWidgets('el artista no tiene problemas de accesibilidad', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeJuegos(prefs),
      home: const Scaffold(body: ArtistaScreen()),
    );
  });

  // ── Plan 13 P2: dibujar no debe mover la pantalla ──────────────────────

  testWidgets(
      'P2: un arrastre vertical largo dibuja sin desplazar la pantalla',
      (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();

    // (b) La pantalla de Artista no tiene desplazamiento vertical: no
    // existe ningún ScrollController que un arrastre pueda mover. (La
    // fila de colores es horizontal a propósito: no compite con el dedo.)
    final verticales = tester
        .widgetList<Scrollable>(find.byType(Scrollable))
        .where((scrollable) => scrollable.axisDirection == AxisDirection.down);
    expect(verticales, isEmpty, reason: 'nada que desplazar al dibujar');

    // (a) Arrastre vertical largo sobre el lienzo: el trazo empieza en el
    // primer contacto (sin tolerancia) y queda guardado al soltar.
    final lienzo = find.byKey(const ValueKey('lienzo_artista'));
    final gesture = await tester.startGesture(tester.getCenter(lienzo));
    await gesture.moveBy(const Offset(0, 40));
    await gesture.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(
      container.read(artistaProvider).activo,
      isNotNull,
      reason: 'el trazo está activo mientras el dedo se mueve',
    );

    await gesture.up();
    await tester.pump();
    expect(container.read(artistaProvider).trazos, hasLength(1));
  });

  testWidgets('P2: Borrar todo exige un segundo toque', (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Artista'));
    await tester.pumpAndSettle();
    await _dibujarTrazo(tester);
    expect(container.read(artistaProvider).trazos, hasLength(1));

    // Primer toque: solo pide confirmación (sin diálogo largo).
    await tester.tap(find.text('Borrar todo'));
    await tester.pump();
    expect(
      container.read(artistaProvider).trazos,
      hasLength(1),
      reason: 'el primer toque no borra nada todavía',
    );

    // Segundo toque: borra.
    await tester.tap(find.text('¿Seguro?'));
    await tester.pump();
    expect(container.read(artistaProvider).trazos, isEmpty);
  });
}
