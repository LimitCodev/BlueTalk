import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Abstracción de voz (TTS) del comunicador.
///
/// La pantalla solo ve esta interfaz; los tests usan un doble falso y la voz
/// real del sistema (`flutter_tts`) entra por [ttsSpeakerProvider].
abstract interface class TtsSpeaker {
  /// Velocidad de habla (0–1).
  Future<void> setRate(double rate);

  /// Tono de voz.
  Future<void> setPitch(double pitch);

  /// Habla [text]. Solo se llama bajo taps del usuario (nunca autoplay).
  Future<void> speak(String text);

  /// Detiene la locución en curso.
  Future<void> stop();

  /// true si el sistema ofrece alguna voz en español (es-ES, es-MX, …).
  Future<bool> hasSpanishVoice();
}

/// Implementación real con la voz del sistema (`flutter_tts`, offline).
class FlutterTtsSpeaker implements TtsSpeaker {
  /// Idiomas en orden de preferencia; si no están, se usa el primer `es*`.
  static const _preferredLanguages = ['es-ES', 'es-MX'];

  FlutterTts? _tts;
  double _rate = 0.5;
  double _pitch = 1.0;
  List<String>? _spanishLanguages;

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    _tts = tts;
    await tts.setSpeechRate(_rate);
    await tts.setPitch(_pitch);
    return tts;
  }

  /// Idiomas `es*` que declara el sistema (consultado una sola vez).
  Future<List<String>> _spanishLanguagesOf(FlutterTts tts) async {
    final cached = _spanishLanguages;
    if (cached != null) return cached;
    final dynamic raw = await tts.getLanguages;
    final languages =
        raw is List ? raw.whereType<String>().toList() : const <String>[];
    _spanishLanguages =
        languages.where((lang) => lang.startsWith('es')).toList();
    return _spanishLanguages!;
  }

  Future<String?> _bestSpanish(FlutterTts tts) async {
    final spanish = await _spanishLanguagesOf(tts);
    for (final preferred in _preferredLanguages) {
      if (spanish.contains(preferred)) return preferred;
    }
    return spanish.isEmpty ? null : spanish.first;
  }

  @override
  Future<bool> hasSpanishVoice() async {
    try {
      final tts = await _engine();
      final language = await _bestSpanish(tts);
      if (language != null) await tts.setLanguage(language);
      return language != null;
    } on Exception {
      return false; // sin motor TTS instalado en el sistema
    }
  }

  @override
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final tts = await _engine();
      final language = await _bestSpanish(tts);
      if (language != null) await tts.setLanguage(language);
      // Corta la locución anterior: siempre manda el último toque del niño.
      await tts.stop();
      await tts.speak(text);
    } on Exception {
      return; // sin motor TTS; la pantalla ya avisa con hasSpanishVoice()
    }
  }

  @override
  Future<void> stop() async {
    try {
      await (await _engine()).stop();
    } on Exception {
      return;
    }
  }

  @override
  Future<void> setRate(double rate) async {
    _rate = rate;
    try {
      await (await _engine()).setSpeechRate(rate);
    } on Exception {
      return;
    }
  }

  @override
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    try {
      await (await _engine()).setPitch(pitch);
    } on Exception {
      return;
    }
  }
}

/// Instancia de voz; en tests se sobreescribe con un doble falso.
final ttsSpeakerProvider = Provider<TtsSpeaker>((ref) => FlutterTtsSpeaker());

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
