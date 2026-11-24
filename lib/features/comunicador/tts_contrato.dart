/// Abstracción de voz (TTS) del comunicador.
///
/// La pantalla solo ve esta interfaz; los tests usan un doble falso y la voz
/// real del sistema (`flutter_tts`) entra por `ttsSpeakerProvider`.
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
