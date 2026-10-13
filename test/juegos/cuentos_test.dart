import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/juegos/cuentos/cuentos_controller.dart';
import 'package:bluetalk/features/juegos/juegos_catalog.dart';

import 'harness.dart';

/// Avanza por todas las páginas hasta la tarea "completar cuento".
Future<void> _llegarALaTarea(WidgetTester tester) async {
  // Páginas 1–4 con "Siguiente"; la 5ª entra a la tarea.
  for (var i = 0; i < 4; i++) {
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
  }
  expect(find.text('Página 5 de 5'), findsOneWidget);
  await tester.tap(find.text('¡Completar cuento!'));
  await tester.pump();
}

void main() {
  testWidgets('la lista muestra los 3 cuentos seed', (tester) async {
    await pumpJuegos(tester);

    await tester.tap(find.text('Cuentos interactivos'));
    await tester.pumpAndSettle();

    expect(find.text('El gato de Lola'), findsOneWidget);
    expect(find.text('Un día en la escuela'), findsOneWidget);
    expect(find.text('El día de lluvia'), findsOneWidget);
  });

  testWidgets('el lector muestra páginas con picto clave y la tarea al final',
      (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Cuentos interactivos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('El gato de Lola'));
    await tester.pumpAndSettle();

    expect(find.text('Lola tiene un gato.'), findsOneWidget);
    expect(find.text('Página 1 de 5'), findsOneWidget);
    // Picto clave de la página: la palabra "gato" está en el texto.
    expect(find.text('Gato'), findsOneWidget);

    await _llegarALaTarea(tester);
    expect(find.text('¡Completar cuento!'), findsOneWidget);
    expect(find.text('Toca la imagen que falta.'), findsOneWidget);

    // Las 3 opciones se sortearon al entrar en la tarea.
    expect(
      container.read(cuentosProvider).requireValue.opciones,
      hasLength(3),
    );
  });

  testWidgets('tocar mal marca la opción y tocar bien completa el cuento',
      (tester) async {
    final container = await pumpJuegos(tester);

    await tester.tap(find.text('Cuentos interactivos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('El gato de Lola'));
    await tester.pumpAndSettle();
    await _llegarALaTarea(tester);

    final estado = container.read(cuentosProvider).requireValue;
    final correcta = container
        .read(cuentosSeedProvider)
        .requireValue
        .first
        .coverPictoId!;
    final incorrecta = estado.opciones.firstWhere((id) => id != correcta);

    await tester.tap(find.byKey(ValueKey('opcion_$incorrecta')));
    await tester.pump();
    expect(
      container.read(cuentosProvider).requireValue.opcionIncorrecta,
      incorrecta,
    );

    await tester.tap(find.byKey(ValueKey('opcion_$correcta')));
    await tester.pump();
    expect(find.text('¡Cuento completado! 🎉'), findsOneWidget);

    // Progreso guardado: estrella del cuento completado.
    final progress = await container
        .read(gameProgressRepoProvider)
        .progress('cuentos:cuento_gato');
    expect(progress, isNotNull);
    expect(progress!.stars, 1);

    // Evento para el dashboard del modo padre.
    final eventos = await container.read(usageRepoProvider).events();
    expect(
      eventos.where((e) => e.type == 'cuento_completado').length,
      1,
    );
  });

  testWidgets('el avance del cuento completo persiste tras reiniciar',
      (tester) async {
    var container = await pumpJuegos(tester);

    await tester.tap(find.text('Cuentos interactivos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('El gato de Lola'));
    await tester.pumpAndSettle();
    await _llegarALaTarea(tester);

    final estado = container.read(cuentosProvider).requireValue;
    final correcta = container
        .read(cuentosSeedProvider)
        .requireValue
        .first
        .coverPictoId!;
    expect(estado.opciones, contains(correcta));

    await tester.tap(find.byKey(ValueKey('opcion_$correcta')));
    await tester.pump();

    // "Reiniciar": sin preferencias en memoria, el cuento sigue completo.
    container = await pumpJuegos(tester, resetPrefs: false);
    await tester.tap(find.text('Cuentos interactivos'));
    await tester.pumpAndSettle();

    expect(
      container.read(cuentosProvider).requireValue.completados,
      contains('cuento_gato'),
    );
    // La estrella se ve en la lista (icono con semántica).
    expect(
      find.byIcon(Icons.star),
      findsOneWidget,
    );
  });
}
