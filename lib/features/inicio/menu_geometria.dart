import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Cálculos del carrusel del menú (plan 14A §A2).
///
/// Vive aparte de la vista para que `menu_carrusel.dart` no pase del
/// trinquete de 100 líneas y para poder probar la separación sin montar
/// la pantalla entera.
abstract final class MenuGeometria {
  /// Hueco visible entre la tarjeta central y sus vecinas.
  static const separacion = 28.0;

  static const _fraccionMinima = 0.12;
  static const _fraccionMaxima = 0.6;

  /// Alto aproximado de una tarjeta con el tamaño de texto del sistema.
  ///
  /// Son 20 dp de relleno arriba y abajo, y la fila más alta entre el icono
  /// (64) y la columna de texto (título + descripción de hasta dos líneas).
  static double altoTarjeta(BuildContext context) {
    final escala = MediaQuery.textScalerOf(context);
    final texto = Theme.of(context).textTheme;
    final titulo = escala.scale(texto.titleLarge?.fontSize ?? 22) * 1.3;
    final cuerpo = escala.scale(texto.bodyMedium?.fontSize ?? 14) * 1.4 * 2;
    final columna = titulo + 4 + cuerpo;
    return 40 + math.max(64, columna);
  }

  /// Fracción de página que deja [separacion] dp entre tarjetas.
  ///
  /// Antes era fija (0,38): en un teléfono de 640 dp el hueco pasaba de
  /// 80 dp. Ahora la página mide «tarjeta + separación» y las pantallas
  /// bajas (horizontal) conservan tarjetas grandes sin desbordar.
  static double fraccion(BuildContext context, double altoDisponible) {
    if (altoDisponible <= 0) return _fraccionMaxima;
    final altoPagina = altoTarjeta(context) + separacion;
    return (altoPagina / altoDisponible).clamp(
      _fraccionMinima,
      _fraccionMaxima,
    );
  }
}

/// Mantiene el [PageController] del carrusel con la fracción que toca.
///
/// Al girar el teléfono o cambiar el tamaño de texto se crea otro
/// controlador sin perder la tarjeta centrada. El anterior se libera al
/// terminar el fotograma para no usarlo después de descartado.
class MenuPaginaController {
  PageController? _pagina;
  double? _fraccion;

  PageController? get paginaOpcional => _pagina;

  PageController sincronizar(double fraccion, int inicial) {
    final actual = _pagina;
    if (actual != null && (_fraccion! - fraccion).abs() < 0.005) {
      return actual;
    }
    _fraccion = fraccion;
    _pagina = PageController(viewportFraction: fraccion, initialPage: inicial);
    if (actual != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => actual.dispose());
    }
    return _pagina!;
  }

  void dispose() {
    _pagina?.dispose();
    _pagina = null;
  }
}
