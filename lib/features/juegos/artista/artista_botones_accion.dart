import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'artista_galeria.dart';

/// «Borrar todo» con confirmación en el propio botón (plan 13 P2): el
/// primer toque lo cambia a «¿Seguro?»; el segundo borra.
class BotonBorrarTodo extends StatelessWidget {
  const BotonBorrarTodo({
    super.key,
    required this.confirmando,
    required this.onPressed,
  });

  final bool confirmando;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        backgroundColor: confirmando ? context.colores.primary : null,
        foregroundColor: confirmando ? context.colores.primaryInk : null,
      ),
      onPressed: onPressed,
      icon: Icon(
        confirmando ? Icons.warning_amber_outlined : Icons.delete_outline,
      ),
      label: Text(confirmando ? '¿Seguro?' : 'Borrar todo'),
    );
  }
}

/// Abre «Mis dibujos» en una hoja inferior: en pantalla solo queda el
/// lienzo, sin nada que desplazar (plan 13 P2). [antes]: cancela un
/// «¿Seguro?» pendiente.
class BotonMisDibujos extends StatelessWidget {
  const BotonMisDibujos({super.key, required this.antes});

  final VoidCallback antes;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
      onPressed: () {
        antes();
        showModalBottomSheet<void>(
          context: context,
          builder: (context) => const SafeArea(child: GaleriaLocal()),
        );
      },
      icon: const Icon(Icons.photo_library_outlined),
      label: const Text('Mis dibujos'),
    );
  }
}
