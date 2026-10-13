import 'package:flutter_test/flutter_test.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterTtsSpeaker', () {
    test('sin motor TTS no lanza: reporta que falta la voz en español',
        () async {
      // En el entorno de tests no existe el canal de flutter_tts.
      final speaker = FlutterTtsSpeaker();

      expect(await speaker.hasSpanishVoice(), isFalse);

      // speak/stop/setRate tampoco deben lanzar excepción.
      await speaker.speak('Hola');
      await speaker.stop();
      await speaker.setRate(0.5);
      await speaker.setPitch(1.0);
    });

  });

  group('FakeTtsSpeaker', () {
    test('graba locuciones y ajustes', () async {
      final fake = FakeTtsSpeaker();

      await fake.setRate(0.6);
      await fake.setPitch(1.1);
      await fake.speak('Hola');
      await fake.stop();

      expect(fake.rates, [0.6]);
      expect(fake.pitches, [1.1]);
      expect(fake.spoken, ['Hola']);
      expect(fake.stopCalls, 1);
      expect(await fake.hasSpanishVoice(), isTrue);
    });
  });
}
