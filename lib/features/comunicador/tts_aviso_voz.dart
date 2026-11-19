import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Aviso de "falta la voz en español" ya mostrado (una sola vez por sesión).
class SpanishVoiceWarnedController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Marca el aviso como mostrado para no repetirlo en la sesión.
  void markShown() => state = true;
}

/// true tras mostrar el aviso de voz en español la primera vez.
final spanishVoiceWarnedProvider =
    NotifierProvider<SpanishVoiceWarnedController, bool>(
      SpanishVoiceWarnedController.new,
    );
