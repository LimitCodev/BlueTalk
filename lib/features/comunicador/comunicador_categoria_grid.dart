import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';
import '../guia/guia_objetivos.dart';
import '../guia/guia_pasos.dart';
import 'comunicador_catalog.dart';
import 'comunicador_controller.dart';

/// Rejilla de categorías con su icono y nombre.
class CategoryGrid extends ConsumerWidget {
  const CategoryGrid({super.key, required this.catalog});

  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = catalog.categories;

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 128,
        // 112 desbordaba con etiquetas de 2 líneas (52 de icono + 6 +
        // 2×22 de texto = 102 > 100 útiles tras el padding). 120 deja
        // margen también con el textScaler del sistema.
        mainAxisExtent: 120,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final iconAsset = catalog.iconAssetOf(category);
        // Mismo lenguaje que la web (docs/branding/WEB-EXTRACCION.md §2):
        // pastel en claro y regla de alpha sobre el tono en oscuro.
        final paleta = context.colores;
        final colores = coloresCategorias[category.id];
        final fondo = colores?.relleno(paleta) ?? paleta.surface;
        final borde = colores?.bordeSobre(paleta) ?? paleta.primary;
        final tinta = colores?.texto(paleta) ?? paleta.primaryStrongText;

        final tarjeta = Material(
          color: fondo,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: borde, width: 1),
          ),
          child: InkWell(
            onTap: () => ref
                .read(comunicadorProvider.notifier)
                .openCategory(category.id),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: iconAsset == null
                        ? Icon(Icons.grid_view_rounded, size: 44, color: tinta)
                        : SvgPicture.asset(
                            iconAsset,
                            fit: BoxFit.contain,
                            placeholderBuilder: (context) =>
                                const SizedBox(width: 52, height: 52),
                          ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: tinta,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        // Palabras básicas: la guía de la mascota la señala (plan 14B).
        return category.nuclear
            ? GuiaAncla(objetivo: GuiaObjetivo.tableroNuclear, child: tarjeta)
            : tarjeta;
      },
    );
  }
}
