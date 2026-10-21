import 'package:flutter/material.dart';

/// Colores de la app como extensión del tema (plan 13 P4).
///
/// El adulto elige un tema de color en Ajustes; la paleta activa llega a
/// toda la UI mediante `Theme.of(context)` — uso directo:
/// `context.colores.bg`. Las seis paletas tienen contraste AA verificado
/// por `test/core/tokens_test.dart` (texto ≥4.5:1, elementos de UI ≥3:1).
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.bg,
    required this.surface,
    required this.primary,
    required this.primaryInk,
    required this.primaryStrong,
    required this.primaryStrongText,
    required this.header,
    required this.onHeader,
    required this.text,
  });

  /// Fondo general. Nunca blanco puro en las paletas pastel.
  final Color bg;

  /// Tarjetas y superficies.
  final Color surface;

  /// Relleno pastel de botones y acentos. El texto encima va en [primaryInk].
  final Color primary;

  /// Texto sobre [primary] (≥4.5:1 en todas las paletas).
  final Color primaryInk;

  /// Borde, icono y foco interactivos: ≥3:1 vs [bg].
  final Color primaryStrong;

  /// Texto de acento sobre [bg]/[surface] — ≥4.5:1 (AA texto).
  final Color primaryStrongText;

  /// Fondo de la barra superior. En la paleta por defecto es el azul de la
  /// web de BlueTalk; el texto va en [onHeader] (≥3:1, título grande).
  final Color header;

  /// Texto e iconos sobre [header].
  final Color onHeader;

  /// Texto principal sobre [bg]/[surface] — ≥4.5:1 (AA texto).
  final Color text;

  /// Por defecto: la identidad de la web de BlueTalk (fondo azul muy claro,
  /// acción azul fuerte y acentos verdes). Mantiene AA en botones.
  static const celeste = AppColors(
    bg: Color(0xFFF4F7FA),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF1574C1),
    primaryInk: Color(0xFFFFFFFF),
    primaryStrong: Color(0xFF0F5E9C),
    primaryStrongText: Color(0xFF0F5E9C),
    header: Color(0xFF238EE7),
    onHeader: Color(0xFFFFFFFF),
    text: Color(0xFF263442),
  );

  static const verdeSuave = AppColors(
    bg: Color(0xFFE8F7F1),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF177053),
    primaryInk: Color(0xFFFFFFFF),
    primaryStrong: Color(0xFF177053),
    primaryStrongText: Color(0xFF177053),
    header: Color(0xFF177053),
    onHeader: Color(0xFFFFFFFF),
    text: Color(0xFF0A3B2E),
  );

  static const lila = AppColors(
    bg: Color(0xFFF1EFFA),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF5B44B8),
    primaryInk: Color(0xFFFFFFFF),
    primaryStrong: Color(0xFF5B44B8),
    primaryStrongText: Color(0xFF5B44B8),
    header: Color(0xFF5B44B8),
    onHeader: Color(0xFFFFFFFF),
    text: Color(0xFF26184F),
  );

  static const durazno = AppColors(
    bg: Color(0xFFFDF3ED),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFA54D22),
    primaryInk: Color(0xFFFFFFFF),
    primaryStrong: Color(0xFFA54D22),
    primaryStrongText: Color(0xFFA54D22),
    header: Color(0xFFA54D22),
    onHeader: Color(0xFFFFFFFF),
    text: Color(0xFF5A2A12),
  );

  static const gris = AppColors(
    bg: Color(0xFFF4F5F6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF4A5B69),
    primaryInk: Color(0xFFFFFFFF),
    primaryStrong: Color(0xFF4A5B69),
    primaryStrongText: Color(0xFF4A5B69),
    header: Color(0xFF4A5B69),
    onHeader: Color(0xFFFFFFFF),
    text: Color(0xFF222B33),
  );

  /// Sin color de fondo tintado y todo lo más oscuro posible.
  static const altoContraste = AppColors(
    bg: Color(0xFFE8E8E8),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF000000),
    primaryInk: Color(0xFFFFFFFF),
    primaryStrong: Color(0xFF000000),
    primaryStrongText: Color(0xFF000000),
    header: Color(0xFF000000),
    onHeader: Color(0xFFFFFFFF),
    text: Color(0xFF000000),
  );

  /// Temas predefinidos, en el orden del selector (plan 13 P4: un solo
  /// selector de color principal; nunca un selector libre de colores).
  static const temas = <String, AppColors>{
    'celeste': celeste,
    'verde': verdeSuave,
    'lila': lila,
    'durazno': durazno,
    'gris': gris,
    'contraste': altoContraste,
  };

  /// Nombres para el selector: literales, sin jerga.
  static const nombresTemas = <String, String>{
    'celeste': 'Azul BlueTalk (por defecto)',
    'verde': 'Verde suave',
    'lila': 'Lila suave',
    'durazno': 'Durazno',
    'gris': 'Gris calmado',
    'contraste': 'Alto contraste',
  };

  /// Borde neutro de tarjetas e inputs (web: hsl 210 20% 88%).
  static const borde = Color(0xFFDCE3EA);

  /// Estados. Semánticos, no de marca ni de tema: no cambian nunca
  /// (plan 00 §4). Relleno pastel + su tinta oscura.
  static const success = Color(0xFFDDF3E4);  static const onSuccess = Color(0xFF14522E);
  static const warning = Color(0xFFFBEBC8);
  static const onWarning = Color(0xFF5B4413);
  static const error = Color(0xFFFBE0E0);
  static const onError = Color(0xFF6E1F1F);

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? primary,
    Color? primaryInk,
    Color? primaryStrong,
    Color? primaryStrongText,
    Color? header,
    Color? onHeader,
    Color? text,
  }) =>
      AppColors(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        primary: primary ?? this.primary,
        primaryInk: primaryInk ?? this.primaryInk,
        primaryStrong: primaryStrong ?? this.primaryStrong,
        primaryStrongText: primaryStrongText ?? this.primaryStrongText,
        header: header ?? this.header,
        onHeader: onHeader ?? this.onHeader,
        text: text ?? this.text,
      );

  /// El cambio de tema es instantáneo: no se anima entre paletas.
  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) =>
      other is AppColors ? other : this;
}

/// Colores fijos de marca (logo e identidad). NO cambian con el tema ni
/// con el modo calma: el logo es identidad, igual en toda la app.
abstract final class Marca {
  /// Azul de la burbuja y del texto «BlueTalk» (web oficial).
  static const azul = Color(0xFF238EE7);

  /// Navy de titulares (web oficial).
  static const navy = Color(0xFF263442);

  /// Verde del corazón del logo (acento de la web).
  static const verde = Color(0xFF2FBFA3);

  /// Celeste de marca fuerte (fondo del ícono adaptive).
  static const celeste = Color(0xFF70D0F8);
}

/// Colores de una tarjeta de categoría del comunicador, tomados de la
/// paleta de categorías de la web de BlueTalk.
class ColoresCategoria {
  const ColoresCategoria({
    required this.fondo,
    required this.borde,
    required this.tinta,
  });

  /// Relleno pastel de la tarjeta.
  final Color fondo;

  /// Borde suave, del mismo tono.
  final Color borde;

  /// Texto de la categoría: ≥4.5:1 sobre [fondo].
  final Color tinta;
}

/// Categorías del comunicador con el mismo lenguaje de color de la web:
/// emociones rosa, comida naranja, animales amarillo, acciones verde,
/// familia/lugares lila, objetos verde azulado y clima azul.
const coloresCategorias = <String, ColoresCategoria>{
  'emociones': ColoresCategoria(
    fondo: Color(0xFFFBEAEF),
    borde: Color(0xFFE8B0C3),
    tinta: Color(0xFF7E1B3C),
  ),
  'comida': ColoresCategoria(
    fondo: Color(0xFFFCF2E8),
    borde: Color(0xFFEEC4A0),
    tinta: Color(0xFF81440E),
  ),
  'animales': ColoresCategoria(
    fondo: Color(0xFFFBF5E4),
    borde: Color(0xFFEAD186),
    tinta: Color(0xFF715709),
  ),
  'acciones': ColoresCategoria(
    fondo: Color(0xFFE8F7EE),
    borde: Color(0xFF97D8B2),
    tinta: Color(0xFF196639),
  ),
  'familia': ColoresCategoria(
    fondo: Color(0xFFF2ECF9),
    borde: Color(0xFFC7AEE0),
    tinta: Color(0xFF52297A),
  ),
  'lugares': ColoresCategoria(
    fondo: Color(0xFFF2ECF9),
    borde: Color(0xFFC7AEE0),
    tinta: Color(0xFF52297A),
  ),
  'objetos': ColoresCategoria(
    fondo: Color(0xFFE7F8F5),
    borde: Color(0xFF90D5C9),
    tinta: Color(0xFF126456),
  ),
  'clima': ColoresCategoria(
    fondo: Color(0xFFE5F3FA),
    borde: Color(0xFF90C5DF),
    tinta: Color(0xFF0D5477),
  ),
  'necesidades': ColoresCategoria(
    fondo: Color(0xFFE5F3FA),
    borde: Color(0xFF90C5DF),
    tinta: Color(0xFF0D5477),
  ),
  'personas': ColoresCategoria(
    fondo: Color(0xFFFDF0EC),
    borde: Color(0xFFEFB9A8),
    tinta: Color(0xFF8A2E12),
  ),
};

/// Paleta activa del tema elegido: `context.colores.bg`.
extension ColoresContext on BuildContext {
  AppColors get colores =>
      Theme.of(this).extension<AppColors>() ?? AppColors.celeste;
}
