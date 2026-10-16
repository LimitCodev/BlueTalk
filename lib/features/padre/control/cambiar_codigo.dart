import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../gate/gate_controller.dart';
import '../gate/pin_store.dart';
import '../reloj.dart';

/// Diálogo «Cambiar código» del Control del modo padre (plan 11 §1.2).
///
/// El código nuevo siempre tiene 6 dígitos, aunque el actual sea de 4 (los
/// PIN antiguos solo se validan; migrarlos a la fuerza cerraría la puerta a
/// quien no los recuerde). Se pide el código nuevo dos veces y la huella se
/// guarda con sal nueva y parámetros actuales, limpiando el bloqueo de
/// intentos. La sesión del modo padre ya está abierta: no se vuelve a pedir
/// el código actual.
class CambiarCodigoDialogo extends ConsumerStatefulWidget {
  const CambiarCodigoDialogo({super.key});

  @override
  ConsumerState<CambiarCodigoDialogo> createState() =>
      _CambiarCodigoDialogoState();
}

class _CambiarCodigoDialogoState extends ConsumerState<CambiarCodigoDialogo> {
  final TextEditingController _nuevo = TextEditingController();
  final TextEditingController _confirmar = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Reconstruye al teclear para habilitar «Guardar» con 6+6 dígitos.
    _nuevo.addListener(_alCambiar);
    _confirmar.addListener(_alCambiar);
  }

  void _alCambiar() => setState(() {});

  @override
  void dispose() {
    _nuevo.removeListener(_alCambiar);
    _confirmar.removeListener(_alCambiar);
    _nuevo.dispose();
    _confirmar.dispose();
    super.dispose();
  }

  bool get _completo =>
      _nuevo.text.length == PinStore.longitudNueva &&
      _confirmar.text.length == PinStore.longitudNueva;

  Future<void> _guardar() async {
    if (!_completo) return;
    if (_nuevo.text != _confirmar.text) {
      setState(() => _error = 'Los códigos no coinciden.');
      return;
    }
    final store = PinStore(
      ref.read(sharedPreferencesProvider),
      ahora: ref.read(relojProvider),
      derivador: ref.read(derivadorPinProvider),
    );
    try {
      await store.crear(_nuevo.text);
    } on FormatException {
      setState(() => _error = 'El código debe tener 6 dígitos.');
      return;
    }
    if (!mounted) return;
    final avisos = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    avisos.showSnackBar(const SnackBar(content: Text('Código nuevo guardado.')));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambia el código'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'El código nuevo siempre tiene 6 dígitos. La app guarda su '
              'huella, no el código.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nuevo,
              autofocus: true,
              obscureText: true,
              maxLength: PinStore.longitudNueva,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Código nuevo de 6 dígitos',
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmar,
              obscureText: true,
              maxLength: PinStore.longitudNueva,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Repite el código nuevo',
                counterText: '',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: _completo ? _guardar : null,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
