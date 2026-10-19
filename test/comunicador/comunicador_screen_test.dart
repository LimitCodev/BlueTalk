import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/comunicador/comunicador_prefs.dart';
import 'package:bluetalk/features/comunicador/phrase_controller.dart';
import 'package:bluetalk/features/comunicador/saved_messages.dart';
import 'package:bluetalk/features/comunicador/tts_service.dart';

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

  testWidgets('repetir el mismo picto lo agrega tantas veces',
      (tester) async {
    // Regresión de tacto (auditoría de reseñas: «no, no, NO» se rompió en
    // Proloquo2Go 2026): sin anti-repetición ni límite de toques.
    final tts = FakeTtsSpeaker();
    final container = await pumpComunicador(tester, tts: tts);

    await abrirCategoria(tester, 'Comida');
    final manzana = find.widgetWithText(InkWell, 'Manzana');
    for (var i = 0; i < 3; i++) {
      await tester.tap(manzana);
      await tester.pumpAndSettle();
    }

    final frase = container.read(phraseProvider);
    expect(frase, hasLength(3), reason: 'tres toques = tres pictos');
    expect(frase.map((p) => p.label), everyElement('Manzana'));
    expect(tts.spoken, ['Manzana', 'Manzana', 'Manzana']);
  });

  testWidgets('arrastrar el dedo sobre los pictos no los activa',
      (tester) async {
    // Regresión de tacto (reseñas: activación al deslizar en Proloquo2Go).
    final tts = FakeTtsSpeaker();
    final container = await pumpComunicador(tester, tts: tts);

    await abrirCategoria(tester, 'Comida');
    await tester.drag(find.text('Manzana'), const Offset(0, -160));
    await tester.pumpAndSettle();

    expect(
      container.read(phraseProvider),
      isEmpty,
      reason: 'un arrastre no dice nada: solo el toque activa',
    );
    expect(tts.spoken, isEmpty);
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

  testWidgets('guardar la frase en mis mensajes y volver a usarla',
      (tester) async {
    final tts = FakeTtsSpeaker();
    await pumpComunicador(tester, tts: tts);

    await abrirCategoria(tester, 'Comida');
    await tester.tap(find.text('Manzana'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pan'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Guardar en mis mensajes'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Mensaje guardado'), findsOneWidget);

    // Se guarda con el texto de la frase y sus pictos.
    await tester.tap(find.widgetWithText(OutlinedButton, 'Volver'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();
    expect(find.text('Mis mensajes'), findsOneWidget);
    expect(find.text('Manzana Pan'), findsOneWidget);
    expect(find.text('2 pictogramas'), findsOneWidget);

    // Pasados unos segundos se va el aviso y el botón Leer queda libre.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Tocar el mensaje lo recarga en la barra y se puede leer.
    await tester.tap(find.text('Manzana Pan'));
    await tester.pumpAndSettle();
    expect(find.text('Manzana'), findsOneWidget, reason: 'en la barra');
    await tester.tap(find.widgetWithText(FilledButton, 'Leer'));
    await tester.pumpAndSettle();
    expect(tts.spoken.last, 'Manzana Pan');
  });

  testWidgets('mis mensajes vacío muestra el literal y se puede borrar',
      (tester) async {
    final container = await pumpComunicador(tester);
    await container.read(savedMessagesProvider.notifier).save(
          text: 'Quiero agua',
          pictoIds: const ['water'],
        );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();
    expect(find.text('Quiero agua'), findsOneWidget);

    await tester.tap(find.byTooltip('Borrar mensaje'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aún no has guardado mensajes. Crea una frase y pulsa "Guardar".',
      ),
      findsOneWidget,
    );
    expect(container.read(savedMessagesProvider), isEmpty);
  });

  testWidgets('sin voz en español avisa una vez y aún así intenta hablar',
      (tester) async {
    final tts = FakeTtsSpeaker(spanishAvailable: false);
    final container = await pumpComunicador(tester, tts: tts);

    await abrirCategoria(tester, 'Comida');
    await tester.tap(find.text('Manzana'));
    await tester.pumpAndSettle();

    expect(find.textContaining('no tiene voz en español'), findsOneWidget);
    expect(tts.spoken, ['Manzana'], reason: 'aun así se intenta hablar');

    // El aviso no se repite en el resto de la sesión.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pan'));
    await tester.pumpAndSettle();

    expect(find.textContaining('no tiene voz en español'), findsNothing);
    expect(tts.spoken, ['Manzana', 'Pan']);
    expect(container.read(spanishVoiceWarnedProvider), isTrue);
  });
}
