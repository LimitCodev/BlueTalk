import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

const _orden = ['familia', 'acciones', 'comida', 'clima', 'emociones'];

/// Color de una categoría del comunicador según la paleta activa.
Color colorCategoria(String id, AppColors paleta) {
  final categoria = coloresCategorias[id];
  if (categoria == null) return colorOtras(paleta);
  return paleta.brillo == Brightness.light
      ? categoria.tinta
      : categoria.fondo;
}

/// Color de un segmento cuando no hay categoría propia (apps, ánimo).
Color colorPorIndice(int indice, AppColors paleta) =>
    colorCategoria(_orden[indice % _orden.length], paleta);

/// Color del segmento «Otras».
Color colorOtras(AppColors paleta) =>
    paleta.brillo == Brightness.light ? paleta.primaryStrong : paleta.primary;
