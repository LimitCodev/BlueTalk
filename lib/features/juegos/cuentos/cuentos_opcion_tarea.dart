import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';

/// Opción táctil de la tarea; la incorrecta tocada queda con borde de
/// error hasta acertar (feedback por estado, sin parpadeos).
class OpcionTarea extends StatelessWidget {
  const OpcionTarea({
    super.key,
    required this.picto,
    required this.incorrecta,
    required this.onTap,
  });

  final Pictogram picto;
  final bool incorrecta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: picto.label,
      child: InkWell(
        key: ValueKey('opcion_${picto.id}'),
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 96,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: incorrecta ? AppColors.error : context.colores.surface,
            border: Border.all(
              color: incorrecta
                  ? AppColors.onError
                  : context.colores.primaryStrong,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                picto.asset,
                width: 52,
                height: 52,
                fit: BoxFit.contain,
                // Sin spinner animado: solo un espacio neutro al cargar.
                placeholderBuilder: (context) =>
                    const SizedBox(width: 52, height: 52),
              ),
              const SizedBox(height: 4),
              Text(
                picto.label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
