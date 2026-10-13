import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';

/// Frase actual: pictogramas en el orden en que se tocaron.
///
/// Estado de sesión (no persiste): si el niño cambia de pestaña y vuelve,
/// la frase sigue ahí. Vive en un provider global para sobrevivir a los
/// rebuilds del shell.
class PhraseController extends Notifier<List<Pictogram>> {
  @override
  List<Pictogram> build() => const [];

  void add(Pictogram picto) => state = [...state, picto];

  void removeAt(int index) => state = [...state]..removeAt(index);

  void clear() => state = const [];

  /// Carga una frase guardada (la reemplaza entera).
  void load(List<Pictogram> pictos) => state = [...pictos];
}

final phraseProvider = NotifierProvider<PhraseController, List<Pictogram>>(
  PhraseController.new,
);

/// Texto que se pronuncia con TTS: las etiquetas unidas por espacios.
String phraseText(List<Pictogram> pictos) =>
    pictos.map((p) => p.label).join(' ');
