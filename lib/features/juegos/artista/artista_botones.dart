import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Casilla de color de la paleta pastel (target ≥48dp).
class BotonColor extends StatelessWidget {
  const BotonColor({
    super.key,
    required this.nombre,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  final String nombre;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: seleccionado,
      label: 'Color $nombre',
      child: InkWell(
        key: ValueKey('color_$nombre'),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: seleccionado
                    ? context.colores.primaryStrong
                    : context.colores.primary,
                width: seleccionado ? 4 : 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Selector de grosor con vista previa del trazo (target ≥48dp).
class BotonGrosor extends StatelessWidget {
  const BotonGrosor({
    super.key,
    required this.etiqueta,
    required this.grosor,
    required this.activo,
    required this.onTap,
  });

  final String etiqueta;
  final double grosor;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: activo
              ? context.colores.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          foregroundColor: context.colores.primaryInk,
        ),
        onPressed: onTap,
        icon: Icon(Icons.circle, size: grosor.clamp(8.0, 20.0)),
        label: Text(etiqueta),
      ),
    );
  }
}
