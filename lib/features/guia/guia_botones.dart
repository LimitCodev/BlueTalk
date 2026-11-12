import 'package:flutter/material.dart';

import 'guia_lista.dart';

/// Botones del globo: Atrás, Siguiente (o «Ir al Modo padre») y la
/// confirmación de «Saltar».
class GuiaBotones extends StatelessWidget {
  const GuiaBotones({
    super.key,
    required this.ultimo,
    required this.confirmarSalto,
    required this.onAtras,
    required this.onSiguiente,
    required this.onSaltar,
    required this.onCancelarSalto,
  });

  final bool ultimo;
  final bool confirmarSalto;
  final VoidCallback? onAtras;
  final VoidCallback onSiguiente;
  final VoidCallback onSaltar;
  final VoidCallback? onCancelarSalto;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: 8,
      children: [
        if (confirmarSalto) ...[
          TextButton(onPressed: onCancelarSalto, child: const Text('Seguir')),
          FilledButton(onPressed: onSaltar, child: const Text('Saltar')),
        ] else ...[
          if (onAtras != null)
            OutlinedButton(onPressed: onAtras, child: const Text('Atrás')),
          FilledButton(
            onPressed: onSiguiente,
            child: Text(ultimo ? 'Ir al Modo padre' : 'Siguiente'),
          ),
        ],
      ],
    );
  }
}

/// «Paso n de 11» y el botón «Saltar».
class GuiaCabecera extends StatelessWidget {
  const GuiaCabecera({
    super.key,
    required this.numero,
    required this.conSaltar,
    required this.onSaltar,
  });

  final int numero;
  final bool conSaltar;
  final VoidCallback onSaltar;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Paso $numero de ${pasosGuia.length}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const Spacer(),
        if (conSaltar)
          TextButton(onPressed: onSaltar, child: const Text('Saltar')),
      ],
    );
  }
}
