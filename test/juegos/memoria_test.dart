import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/juegos/avance_juegos.dart';
import 'package:bluetalk/features/juegos/memoria/memoria_controller.dart';

import 'harness.dart';

/// Índices de las 2 fichas de cada pareja, agrupados por picto.
List<List<int>> parejasDe(List<String> tablero) {
  final porId = <String, List<int>>{};
  for (var i = 0; i < tablero.length; i++) {
    porId.putIfAbsent(tablero[i], () => []).add(i);
  }
  return porId.values.toList();
}

Future<void> _tocarFicha(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(ValueKey('memoria_ficha_$index')));
  await tester.pump();
}

void main() {
  testWidgets('el memoria abre el nivel 1 con 4 parejas', (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Memoria'));
    await tester.pumpAndSettle();
    expect(find.text('Cada nivel es más difícil 💙'), findsOneWidget);
    expect(find.text('Nivel 1'), findsOneWidget);

    await tester.tap(find.text('Nivel 1'));
    await tester.pumpAndSettle();

    expect(find.text('Parejas: 0 de 4'), findsOneWidget);
    for (var index = 0; index < 8; index++) {
      expect(find.byKey(ValueKey('memoria_ficha_$index')), findsOneWidget);
    }
    expect(
      container.read(memoriaProvider).requireValue.tablero,
      hasLength(8),
    );
  });

  testWidgets('acertar pareja suma y fallar marca error hasta el siguiente toque',
      (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Memoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nivel 1'));
    await tester.pumpAndSettle();

    final tablero =
        container.read(memoriaProvider).requireValue.tablero;
    final parejas = parejasDe(tablero);

    // Fallar: dos fichas distintas quedan marcadas con borde de error.
    final distintas = [parejas.first.first, parejas.last.first];
    await _tocarFicha(tester, distintas[0]);
    await _tocarFicha(tester, distintas[1]);
    final trasFallar = container.read(memoriaProvider).requireValue;
    expect(trasFallar.fallas, distintas.toSet());
    expect(trasFallar.seleccion, distintas);
    expect(find.text('Parejas: 0 de 4'), findsOneWidget);

    // El siguiente toque limpia el error y levanta solo la ficha nueva.
    await _tocarFicha(tester, parejas.first.last);
    final trasTocar = container.read(memoriaProvider).requireValue;
    expect(trasTocar.fallas, isEmpty);
    expect(trasTocar.seleccion, [parejas.first.last]);

    // Acertar la pareja suma la pareja.
    await _tocarFicha(tester, parejas.first.first);
    expect(find.text('Parejas: 1 de 4'), findsOneWidget);
  });

  testWidgets('completar el nivel desbloquea el nivel 2 y persiste al reiniciar',
      (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Memoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nivel 1'));
    await tester.pumpAndSettle();

    final tablero = container.read(memoriaProvider).requireValue.tablero;
    for (final pareja in parejasDe(tablero)) {
      await _tocarFicha(tester, pareja.first);
      await _tocarFicha(tester, pareja.last);
    }
    await tester.pump();

    expect(find.text('¡Nivel completado! 🎉'), findsOneWidget);
    expect(find.text('Jugar nivel 2'), findsOneWidget);

    // El progreso quedó guardado: nivel 2 desbloqueado.
    final progress = await container
        .read(gameProgressRepoProvider)
        .progress('memoria');
    expect(progress, isNotNull);
    expect(progress!.level, 2);

    // Evento para el dashboard del modo padre.
    final eventos = await container.read(usageRepoProvider).events();
    expect(
      eventos.where((e) => e.type == 'nivel_completado').length,
      1,
    );

    // "Reiniciar": sin preferencias en memoria, el nivel 2 sigue abierto.
    final trasReiniciar = await pumpJuegos(tester, resetPrefs: false);
    await tester.tap(find.text('Memoria'));
    await tester.pumpAndSettle();
    expect(
      trasReiniciar.read(memoriaProvider).requireValue.desbloqueado,
      2,
    );

    await tester.tap(find.text('Nivel 2'));
    await tester.pumpAndSettle();
    expect(find.text('Parejas: 0 de 6'), findsOneWidget);
    expect(
      trasReiniciar.read(avanceJuegosProvider).requireValue.memoriaSuperados,
      1,
    );
  });
}
