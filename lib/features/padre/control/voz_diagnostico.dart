import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bluetalk/features/comunicador/tts_service.dart';

/// Diagnóstico de voz (plan 13 P6.1): el adulto comprueba que el teléfono
/// reproduce la voz de BlueTalk. Aquí nunca suena nada solo: la frase sale
/// únicamente bajo toque, y solo eso.
class VozDiagnosticoScreen extends ConsumerWidget {
  const VozDiagnosticoScreen({super.key});

  /// Frase de prueba; la misma que usa el niño al tocar un pictograma.
  static const String frase = 'Hola, soy BlueTalk';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Probar la voz')),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Toca el botón y deberías oír una frase.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 64),
                  ),
                  onPressed: () => ref.read(ttsSpeakerProvider).speak(frase),
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('¿No se oye? Toca aquí'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Si no oyes nada, sube el volumen del teléfono y prueba '
                  'otra vez.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
