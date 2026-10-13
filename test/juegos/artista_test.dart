import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

    // La miniatura se puede tocar para seguir editando el dibujo.
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

  testWidgets('el artista no tiene problemas de accesibilidad', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await prefsDePrueba();
    await expectSinProblemasDeAccesibilidad(
      tester,
      overrides: overridesDeJuegos(prefs),
      home: const Scaffold(body: ArtistaScreen()),
    );
  });
}
