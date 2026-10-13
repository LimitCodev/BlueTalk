import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';

/// Habla al tocar un pictograma (default ON, plan 02 §3).
///
/// El niño puede silenciarlo con el icono de altavoz de la barra de frase.
class SpeakOnTapController extends Notifier<bool> {
  static const prefKey = 'bluetalk_speak_on_tap';

  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(prefKey) ?? true;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPreferencesProvider).setBool(prefKey, value);
  }
}

/// Preferencia "hablar al tocar" persistente.
final speakOnTapProvider = NotifierProvider<SpeakOnTapController, bool>(
  SpeakOnTapController.new,
);

/// Pictogramas fijados en el inicio del comunicador (mantener presionado).
class FavoritesController extends Notifier<Set<String>> {
  static const prefKey = 'bluetalk_fav_pictos';

  @override
  Set<String> build() {
    final raw = ref.read(sharedPreferencesProvider).getStringList(prefKey);
    return raw?.toSet() ?? const <String>{};
  }

  bool contains(String pictoId) => state.contains(pictoId);

  Future<void> toggle(String pictoId) async {
    final next = {...state};
    if (!next.remove(pictoId)) next.add(pictoId);
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(prefKey, next.toList());
  }
}

/// Ids de los pictogramas fijados en el inicio.
final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);
