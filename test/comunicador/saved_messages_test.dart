import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/comunicador/saved_messages.dart';

/// Container con «Mis mensajes» apuntando a un string crudo concreto.
Future<ProviderContainer> _containerCon(String raw) async {
  SharedPreferences.setMockInitialValues({
    SavedMessagesController.prefKey: raw,
  });
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

/// Preferencias corruptas o con esquema viejo no deben romper la vista
/// del niño: se empieza una lista limpia (hallazgo MAJOR del revisor de la
/// ola 2; el mismo patrón que `GaleriaController` en el artista).
void main() {
  group('SavedMessagesController con preferencias corruptas', () {
    test('JSON irreconocible empieza la lista vacía sin lanzar', () async {
      final container = await _containerCon('{esto no es json');
      expect(container.read(savedMessagesProvider), isEmpty);
    });

    test('JSON válido que no es una lista empieza vacío', () async {
      final container = await _containerCon('{"id": "x"}');
      expect(container.read(savedMessagesProvider), isEmpty);
    });

    test('fila con esquema viejo (id numérico) empieza vacía', () async {
      final container = await _containerCon(
        '[{"id": 7, "text": "hola", "pictoIds": [], "createdAt": 0}]',
      );
      expect(container.read(savedMessagesProvider), isEmpty);
    });

    test('una lista buena se sigue leyendo entera', () async {
      final container = await _containerCon(
        '[{"id": "1", "text": "hola", "pictoIds": ["apple"],'
        ' "createdAt": 0}]',
      );
      final mensajes = container.read(savedMessagesProvider);
      expect(mensajes, hasLength(1));
      expect(mensajes.single.text, 'hola');
      expect(mensajes.single.pictoIds, ['apple']);
    });
  });
}
