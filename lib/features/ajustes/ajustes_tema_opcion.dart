import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Una opción del selector: muestra la paleta (fondo + relleno) y su
/// nombre literal. Toda la opción es táctil (≥48dp de sobra).
class OpcionTema extends StatelessWidget {
  const OpcionTema({
    super.key,
    required this.id,
    required this.paleta,
    required this.seleccionado,
    required this.onTap,
  });

  final String id;
  final AppColors paleta;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final nombre = AppColors.nombresTemas[id] ?? id;

    return Semantics(
      button: true,
      selected: seleccionado,
      label: 'Color $nombre',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: paleta.bg,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: seleccionado ? paleta.primaryStrong : paleta.primary,
                    width: seleccionado ? 3 : 1,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: paleta.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: 88,
                child: Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 13,
                    fontWeight: seleccionado
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ),
              if (seleccionado)
                const Icon(Icons.check_circle, size: 18)
              else
                const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}
