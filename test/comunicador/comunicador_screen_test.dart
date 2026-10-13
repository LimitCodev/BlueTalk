import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/comunicador/comunicador_prefs.dart';

import 'dobles.dart';
import 'harness.dart';

void main() {
  testWidgets('muestra las categorías y abre una con sus pictogramas',
      (tester) async {
    await pumpComunicador(tester);

    for (final name in const [
      'Emociones',
      'Comida',
      'Animales',
      'Acciones',
      'Familia y lugares',
      'Objetos',
      'Clima',
    ]) {
      expect(find.text(name), findsOneWidget);
    }

    await abrirCategoria(tester, 'Comida');

    expect(find.text('Manzana'), findsOneWidget);
    expect(find.text('Chocolate caliente'), findsOneWidget);
    expect(find.text('Volver'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Volver'));
    await tester.pumpAndSettle();

    expect(find.text('Manzana'), findsNothing);
    expect(find.text('Comida'), findsOneWidget);
  });

  testWidgets('tocar un picto lo agrega a la frase, habla y registra el uso',
      (tester) async {
    final tts = FakeTtsSpeaker();
    final container = await pumpComunicador(tester, tts: tts);

    await abrirCategoria(tester, 'Comida');
    await tester.tap(find.text('Manzana'));
    await tester.pumpAndSettle();

    expect(tts.spoken, ['Manzana'], reason: 'habla bajo el tap del niño');
    // El picto aparece en la rejilla y en la barra de frase.
    expect(find.text('Manzana'), findsNWidgets(2));

    final events = await container.read(usageRepoProvider).events();
    expect(events, hasLength(1));
    expect(events.single.type, 'picto_tap');
    expect(events.single.data['pictoId'], 'apple');
    expect(events.single.data['categoryId'], 'comida');
  });

  testWidgets('leer pronuncia la frase y borrar todo la vacía', (tester) async {
    final tts = FakeTtsSpeaker();
    await pumpComunicador(tester, tts: tts);

    await abrirCategoria(tester, 'Comida');
    await tester.tap(find.text('Manzana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pan'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Leer'));
    await tester.pumpAndSettle();

    expect(tts.spoken.last, 'Manzana Pan');

    await tester.tap(find.widgetWithText(OutlinedButton, 'Borrar todo'));
    await tester.pumpAndSettle();

    expect(
      find.text('Toca los pictogramas para crear un mensaje...'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Leer'))
          .onPressed,
      isNull,
      reason: 'con la frase vacía no se puede leer',
    );
  });

  testWidgets('la frase acumula pictos de varias categorías', (tester) async {
    final tts = FakeTtsSpeaker();
    await pumpComunicador(tester, tts: tts);

    await abrirCategoria(tester, 'Comida');
    await tester.tap(find.text('Manzana'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Volver'));
    await tester.pumpAndSettle();
    await abrirCategoria(tester, 'Animales');
    await tester.tap(find.text('Gato'));
    await tester.pumpAndSettle();

    expect(tts.spoken, ['Manzana', 'Gato']);
    await tester.tap(find.widgetWithText(FilledButton, 'Leer'));
    await tester.pumpAndSettle();
    expect(tts.spoken.last, 'Manzana Gato');
  });

  testWidgets('el altavoz silencia al tocar y la preferencia persiste',
      (tester) async {
    final tts = FakeTtsSpeaker();
    final container = await pumpComunicador(tester, tts: tts);

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.volume_off), findsOneWidget);

    await abrirCategoria(tester, 'Comida');
    await tester.tap(find.text('Manzana'));
    await tester.pumpAndSettle();

    expect(tts.spoken, isEmpty, reason: 'con silencio no habla al tocar');
    expect(
      find.text('Manzana'),
      findsNWidgets(2),
      reason: 'pero sí se agrega a la frase (rejilla + barra)',
    );
    expect(container.read(speakOnTapProvider), isFalse);
  });

  testWidgets('el buscador filtra pictos por palabra sin importar mayúsculas',
      (tester) async {
    await pumpComunicador(tester);

    await tester.enterText(find.byType(TextField), 'GATo');
    await tester.pumpAndSettle();

    expect(find.text('Gato'), findsOneWidget);
    expect(find.text('Perro'), findsNothing);
    expect(find.text('Manzana'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();

    expect(find.text('Gato'), findsNothing);
    expect(find.text('Comida'), findsOneWidget, reason: 'vuelve el inicio');
  });

  testWidgets('mantener presionado fija un favorito en el inicio y persiste',
      (tester) async {
    final container = await pumpComunicador(tester);

    await abrirCategoria(tester, 'Comida');
    await tester.longPress(find.text('Manzana'));
    await tester.pumpAndSettle();

    expect(find.text('Pictograma fijado en el inicio'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Volver'));
    await tester.pumpAndSettle();

    // Aparece en la sección de favoritos del inicio.
    expect(find.text('Manzana'), findsOneWidget);
    expect(container.read(favoritesProvider), contains('apple'));

    // Y persiste tras recrear la pantalla con las mismas preferencias.
    await tester.pumpWidget(const SizedBox());
    await pumpComunicador(tester, resetPrefs: false);
    expect(find.text('Manzana'), findsOneWidget);
  });

  testWidgets('mantener presionado de nuevo quita el favorito', (tester) async {
    final container = await pumpComunicador(tester);

    await abrirCategoria(tester, 'Comida');
    await tester.longPress(find.text('Manzana'));
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Manzana'));
    await tester.pumpAndSettle();

    expect(find.text('Pictograma quitado del inicio'), findsOneWidget);
    expect(container.read(favoritesProvider), isEmpty);
  });
}
