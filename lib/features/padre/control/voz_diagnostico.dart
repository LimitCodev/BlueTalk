import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bluetalk/core/plataforma/canal_nativo.dart';
import 'package:bluetalk/features/comunicador/tts_service.dart';

/// Diagnóstico de voz (plan 13 P6.1): el adulto comprueba que el teléfono
/// reproduce la voz de BlueTalk. Aquí nunca suena nada solo: la frase sale
/// únicamente bajo toque, y solo eso.
class VozDiagnosticoScreen extends ConsumerStatefulWidget {
  const VozDiagnosticoScreen({super.key});

  /// Frase de prueba; la misma que usa el niño al tocar un pictograma.
  static const String frase = 'Hola, soy BlueTalk';

  @override
  ConsumerState<VozDiagnosticoScreen> createState() =>
      _VozDiagnosticoScreenState();
}

class _VozDiagnosticoScreenState extends ConsumerState<VozDiagnosticoScreen> {
  static const _canal = CanalNativo('bluetalk/permisos');

  bool _sinVoz = false;

  Future<void> _probar() async {
    final voz = ref.read(ttsSpeakerProvider);
    final hayVoz = await voz.hasSpanishVoice();
    if (mounted) setState(() => _sinVoz = !hayVoz);
    await voz.speak(VozDiagnosticoScreen.frase);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Probar la voz')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                  onPressed: _probar,
                  icon: const Icon(Icons.volume_up_outlined),
                  label: const Text('¿No se oye? Toca aquí'),
                ),
                const SizedBox(height: 20),
                if (_sinVoz) ...[
                  const Text(
                    'Este teléfono no tiene voz en español. Abre los ajustes '
                    'de voz de Android e instala una voz en español.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(64, 48),
                    ),
                    onPressed: () => _canal.orden('abrirAjustesVoz'),
                    child: const Text('Abrir ajustes de voz'),
                  ),
                ] else
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
