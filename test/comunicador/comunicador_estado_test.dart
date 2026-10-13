import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/data/models/models.dart';
import 'package:bluetalk/features/comunicador/comunicador_controller.dart';
import 'package:bluetalk/features/comunicador/comunicador_prefs.dart';
import 'package:bluetalk/features/comunicador/phrase_controller.dart';
import 'package:bluetalk/features/comunicador/saved_messages.dart';

const _manzana = Pictogram(
  id: 'apple',
  categoryId: 'comida',
  label: 'Manzana',
  asset: 'assets/pictos/muestra/apple.svg',
);

const _pan = Pictogram(
  id: 'bread',
  categoryId: 'comida',
  label: 'Pan',
  asset: 'assets/pictos/muestra/bread.svg',
);

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('PhraseController', () {
    test('agrega, quita y limpia pictos manteniendo el orden', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final phrase = container.read(phraseProvider.notifier);

      phrase.add(_manzana);
      phrase.add(_pan);
      expect(container.read(phraseProvider), [_manzana, _pan]);

      phrase.removeAt(0);
      expect(container.read(phraseProvider), [_pan]);

      phrase.clear();
      expect(container.read(phraseProvider), isEmpty);
    });

    test('phraseText une las etiquetas con espacios', () {
      expect(phraseText(const [_manzana, _pan]), 'Manzana Pan');
      expect(phraseText(const []), isEmpty);
    });
  });

  group('SpeakOnTapController', () {
    test('por defecto habla al tocar y persiste el silencio', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);

      expect(container.read(speakOnTapProvider), isTrue);

      await container.read(speakOnTapProvider.notifier).set(false);
      expect(container.read(speakOnTapProvider), isFalse);

      // Un provider nuevo con las mismas preferencias ve el silencio.
      final other = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(other.dispose);
      expect(other.read(speakOnTapProvider), isFalse);
    });
  });

  group('FavoritesController', () {
    test('alterna favoritos y persiste los ids', () async {
      final container = await _container();
      final favorites = container.read(favoritesProvider.notifier);

      await favorites.toggle('apple');
      await favorites.toggle('bread');
      expect(container.read(favoritesProvider), {'apple', 'bread'});

      await favorites.toggle('apple');
      expect(container.read(favoritesProvider), {'bread'});
    });
  });

  group('ComunicadorController', () {
    test('abre categoría, vuelve al inicio y muestra mis mensajes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(comunicadorProvider.notifier);

      controller.openCategory('comida');
      expect(container.read(comunicadorProvider).categoryId, 'comida');
      expect(container.read(comunicadorProvider).onCategory, isTrue);

      controller.setQuery('gat');
      controller.goHome();
      final home = container.read(comunicadorProvider);
      expect(home.categoryId, isNull);
      expect(home.query, 'gat', reason: 'la búsqueda se conserva al volver');

      controller.showMessages();
      expect(container.read(comunicadorProvider).showMessages, isTrue);
    });
  });

  group('SavedMessagesController', () {
    test('guarda, recupera y borra mensajes', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(container.dispose);
      final controller = container.read(savedMessagesProvider.notifier);

      await controller.save(text: 'Quiero agua', pictoIds: const ['water']);
      await controller.save(text: 'A jugar', pictoIds: const ['play_,_to']);

      final messages = container.read(savedMessagesProvider);
      expect(messages.map((m) => m.text), ['A jugar', 'Quiero agua']);

      // Un provider nuevo con las mismas preferencias ve los mensajes.
      final other = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(other.dispose);
      expect(other.read(savedMessagesProvider), hasLength(2));

      await controller.remove(messages.last.id);
      expect(
        container.read(savedMessagesProvider).map((m) => m.text),
        ['A jugar'],
      );
    });
  });
}
