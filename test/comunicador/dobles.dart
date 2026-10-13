import 'package:bluetalk/features/comunicador/tts_service.dart';

/// Doble falso del TTS para tests: graba las llamadas.
class FakeTtsSpeaker implements TtsSpeaker {
  FakeTtsSpeaker({this.spanishAvailable = true});

  final bool spanishAvailable;
  final List<String> spoken = <String>[];
  final List<double> rates = <double>[];
  final List<double> pitches = <double>[];
  int stopCalls = 0;

  @override
  Future<void> setRate(double rate) async => rates.add(rate);

  @override
  Future<void> setPitch(double pitch) async => pitches.add(pitch);

  @override
  Future<void> speak(String text) async => spoken.add(text);

  @override
  Future<void> stop() async => stopCalls++;

  @override
  Future<bool> hasSpanishVoice() async => spanishAvailable;
}
