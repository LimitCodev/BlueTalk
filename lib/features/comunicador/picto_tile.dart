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
    this.categoria,
  });

  final Pictogram pictogram;
  final VoidCallback onTap;

  /// Mantener presionado (fijar en Inicio); null si no está disponible.
  final VoidCallback? onLongPress;
  final bool favorited;

  /// Color de la categoría a la que pertenece. La web tiñe la tarjeta del
  /// pictograma con el tono de su categoría (`--cat-*` / .1 de relleno y
  /// / .3 de borde); aquí se usa el mismo lenguaje. En modo oscuro el
  /// relleno pastel sería un bloque claro sobre la página, así que se
  /// aplica la regla de alpha de la web sobre el tono de la categoría.
  final ColoresCategoria? categoria;

  Color _relleno(AppColors colores) {
    final c = categoria;
    if (c == null) return colores.surface;
    if (colores.brillo == Brightness.light) return c.fondo;
    return c.tinta.withValues(alpha: 0.10);
  }

  Color _borde(AppColors colores) {
    final c = categoria;
    if (c == null) return colores.borde;
    if (colores.brillo == Brightness.light) return c.borde;
    return c.tinta.withValues(alpha: 0.30);
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.colores;
    return Material(
      color: _relleno(colores),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _borde(colores)),
      ),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
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
                Positioned(
                  top: 2,
                  right: 2,
                  child: Icon(
                    Icons.star,
                    size: 18,
                    color: context.colores.primaryStrong,
                    semanticLabel: 'Fijado en Inicio',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
