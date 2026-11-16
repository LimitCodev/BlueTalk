import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../onboarding/profile_controller.dart';

/// Cambia el apodo del niño (plan 14A §A4): mismas reglas que el
/// onboarding (20 caracteres, vacío = sin apodo, solo en el teléfono).
class NombreDialogo extends ConsumerStatefulWidget {
  const NombreDialogo({super.key});

  @override
  ConsumerState<NombreDialogo> createState() => _NombreDialogoState();
}

class _NombreDialogoState extends ConsumerState<NombreDialogo> {
  late final _texto = TextEditingController(
    text: ref.read(profileProvider)?.nickname ?? '',
  );
  var _guardando = false;

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      await ref.read(profileProvider.notifier).renombrar(_texto.text);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _guardando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo guardar. Inténtalo otra vez.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nombre del niño o niña'),
      content: TextField(
        controller: _texto,
        autofocus: true,
        maxLength: 20,
        enabled: !_guardando,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _guardando ? null : _guardar(),
        decoration: const InputDecoration(
          labelText: 'Apodo',
          helperText: 'Un apodo basta. Se guarda solo en este teléfono.',
          counterText: '',
        ),
      ),
      actions: [
        TextButton(
          onPressed: _guardando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _guardando ? null : _guardar,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
