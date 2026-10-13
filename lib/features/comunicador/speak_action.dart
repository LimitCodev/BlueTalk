import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/models.dart';
import '../ajustes/settings_controller.dart';
import 'tts_service.dart';

/// Habla [text] con los ajustes actuales de voz (plan 02 §5).
///
/// Solo se llama bajo taps del usuario (nunca autoplay). Si el sistema no
/// tiene voz en español, avisa con un SnackBar claro la primera vez
/// (plan 00 §11) y aún así intenta hablar: el motor puede tener voz por
/// defecto.
Future<void> speakText(
  BuildContext context,
  WidgetRef ref,
  String text,
) async {
  final speaker = ref.read(ttsSpeakerProvider);

  if (!ref.read(spanishVoiceWarnedProvider)) {
    final hasVoice = await speaker.hasSpanishVoice();
    if (!hasVoice) {
      ref.read(spanishVoiceWarnedProvider.notifier).markShown();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este teléfono no tiene voz en español. '
              'Puedes instalar una voz en español en Ajustes del sistema.',
            ),
          ),
        );
      }
    }
  }

  final settings = ref.read(settingsProvider).value ?? const AppSettings();
  await speaker.setRate(settings.ttsRate);
  await speaker.setPitch(settings.ttsPitch);
  await speaker.speak(text);
}
