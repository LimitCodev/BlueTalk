import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_contrato.dart';

// Se reexportan para no cambiar los imports de quien ya los usaba.
export 'tts_aviso_voz.dart'
    show SpanishVoiceWarnedController, spanishVoiceWarnedProvider;
export 'tts_contrato.dart' show TtsSpeaker;

/// Implementación real con la voz del sistema (`flutter_tts`, offline).
class FlutterTtsSpeaker implements TtsSpeaker {
  /// Idiomas en orden de preferencia; si no están, se usa el primer `es*`.
  static const _preferredLanguages = ['es-ES', 'es-MX'];

  FlutterTts? _tts;
  double _rate = 0.5;
  double _pitch = 1.0;
  // Últimos valores que de verdad viajaron al canal nativo. Repetirlos en
  // cada picto era un viaje de plataforma por toque (PERF-CORE-04).
  double? _rateAplicada;
  double? _pitchAplicado;
  String? _idiomaAplicado;
  List<String>? _spanishLanguages;

  Future<FlutterTts> _engine() async {
    final existing = _tts;
    if (existing != null) return existing;
    final tts = FlutterTts();
    _tts = tts;
    await tts.setSpeechRate(_rate);
    _rateAplicada = _rate;
    await tts.setPitch(_pitch);
    _pitchAplicado = _pitch;
    return tts;
  }

  /// Idiomas `es*` que declara el sistema (consultado una sola vez).
  Future<List<String>> _spanishLanguagesOf(FlutterTts tts) async {
    final cached = _spanishLanguages;
    if (cached != null) return cached;
    final dynamic raw = await tts.getLanguages;
    final languages = raw is List
        ? raw.whereType<String>().toList()
        : const <String>[];
    final spanish = languages.where((lang) => lang.startsWith('es')).toList();
    if (spanish.isNotEmpty) _spanishLanguages = spanish; // sin voz, reintenta
    return spanish;
  }

  Future<String?> _bestSpanish(FlutterTts tts) async {
    final spanish = await _spanishLanguagesOf(tts);
    for (final preferred in _preferredLanguages) {
      if (spanish.contains(preferred)) return preferred;
    }
    return spanish.isEmpty ? null : spanish.first;
  }

  /// Cambia de idioma solo si de verdad cambió.
  Future<void> _aplicarIdioma(FlutterTts tts, String? language) async {
    if (language == null || language == _idiomaAplicado) return;
    await tts.setLanguage(language);
    _idiomaAplicado = language;
  }

  @override
  Future<bool> hasSpanishVoice() async {
    try {
      final tts = await _engine();
      final language = await _bestSpanish(tts);
      await _aplicarIdioma(tts, language);
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
      await _aplicarIdioma(tts, await _bestSpanish(tts));
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
      final tts = await _engine();
      if (_rateAplicada == rate) return;
      await tts.setSpeechRate(rate);
      _rateAplicada = rate;
    } on Exception {
      return;
    }
  }

  @override
  Future<void> setPitch(double pitch) async {
    _pitch = pitch;
    try {
      final tts = await _engine();
      if (_pitchAplicado == pitch) return;
      await tts.setPitch(pitch);
      _pitchAplicado = pitch;
    } on Exception {
      return;
    }
  }
}

/// Instancia de voz; en tests se sobreescribe con un doble falso.
final ttsSpeakerProvider = Provider<TtsSpeaker>((ref) => FlutterTtsSpeaker());
