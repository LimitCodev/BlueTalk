import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di.dart';
import '../../../core/theme/app_colors.dart';
import '../gate/gate_controller.dart';
import '../gate/pin_store.dart';
import '../reloj.dart';

/// Diálogo «Código de recuperación» del Control del modo padre (solicitud
/// del dueño, 2026-10-19).
///
/// Genera el código a petición y lo muestra **una sola vez**: como el PIN,
/// solo se persiste su huella PBKDF2, así que el código no se vuelve a ver
/// jamás. Si ya existe uno, la única opción es regenerarlo (el anterior
/// queda invalidado); no hay forma de recuperar el código ya mostrado.
class RecuperacionDialogo extends ConsumerStatefulWidget {
  const RecuperacionDialogo({super.key});

  @override
  ConsumerState<RecuperacionDialogo> createState() =>
      _RecuperacionDialogoState();
}

class _RecuperacionDialogoState extends ConsumerState<RecuperacionDialogo> {
  /// ¿Ya había un código antes de abrir este diálogo?
  late final bool _tenia;

  /// true mientras se deriva la huella (~PBKDF2); con los botones apagados.
  bool _generando = false;

  /// Código recién generado (formato `XXXX-XXXX`): al ser no nulo se
  /// muestra la vista de una sola lectura.
  String? _codigo;

  @override
  void initState() {
    super.initState();
    _tenia = _store().tieneRecuperacion;
  }

  PinStore _store() => PinStore(
        ref.read(sharedPreferencesProvider),
        ahora: ref.read(relojProvider),
        derivador: ref.read(derivadorPinProvider),
      );

  Future<void> _generar() async {
    if (_generando) return;
    setState(() => _generando = true);
    final codigo = await _store().generarRecuperacion();
    if (!mounted) return;
    setState(() {
      _generando = false;
      _codigo = codigo;
    });
  }

  @override
  Widget build(BuildContext context) {
    final codigo = _codigo;
    if (codigo != null) return _vistaCodigo(context, codigo);

    return AlertDialog(
      title: const Text('Código de recuperación'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _tenia
                  ? 'Ya tienes uno guardado, pero no se puede volver a ver: '
                      'solo está almacenada su huella. Si generas un código '
                      'nuevo, el anterior deja de valer.'
                  : 'Con este código recuperas el acceso si olvidas tu '
                      'código de 6 dígitos, sin borrar el progreso, el '
                      'horario ni los ajustes.',
            ),
            if (_generando) ...[
              const SizedBox(height: 12),
              // Sin spinner animado (norma de calma): solo el literal.
              const Text('Generando...', textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _generando ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: _generando ? null : _generar,
          child: Text(_tenia ? 'Generar uno nuevo' : 'Generar mi código'),
        ),
      ],
    );
  }

  /// Vista de una sola lectura: el código en claro, con su aviso.
  Widget _vistaCodigo(BuildContext context, String codigo) {
    final textTheme = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Guarda tu código de recuperación'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Úsalo en «¿Olvidaste el código?» si olvidas tu PIN: '
              'recupera el acceso sin borrar tus datos.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SelectableText(
              codigo,
              textAlign: TextAlign.center,
              semanticsLabel: 'Código de recuperación $codigo',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Se muestra una sola vez. Escríbelo en un papel o guárdalo en '
              'un lugar seguro: no se puede volver a ver.',
              textAlign: TextAlign.center,
            ),
            if (_tenia) ...[
              const SizedBox(height: 8),
              const Text(
                'Tu código anterior ya no vale.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ya lo guardé'),
        ),
      ],
    );
  }
}
