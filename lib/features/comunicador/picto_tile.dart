import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/models.dart';

/// Celda de pictograma: imagen SVG + palabra, targets ≥48dp.
///
/// El SVG es vectorial: no necesita `cacheWidth` (eso aplica a raster);
/// su tamaño queda acotado por el `SizedBox` para no gastar memoria.
class PictoTile extends StatelessWidget {
  const PictoTile({
    super.key,
    required this.pictogram,
    required this.onTap,
    this.onLongPress,
    this.favorited = false,
  });

  final Pictogram pictogram;
  final VoidCallback onTap;

  /// Mantener presionado (fijar en Inicio); null si no está disponible.
  final VoidCallback? onLongPress;
  final bool favorited;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    pictogram.asset,
                    width: 52,
                    height: 52,
                    fit: BoxFit.contain,
                    // Sin spinner animado: solo un espacio neutro al cargar.
                    placeholderBuilder: (context) => const SizedBox(
                      width: 52,
                      height: 52,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pictogram.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            if (favorited)
              const Positioned(
                top: 2,
                right: 2,
                child: Icon(
                  Icons.star,
                  size: 18,
                  color: AppColors.primaryStrong,
                  semanticLabel: 'Fijado en Inicio',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
