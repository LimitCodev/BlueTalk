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

  /// Texto principal sobre [bg]/[surface] — ≥4.5:1 (AA texto).
  final Color text;

  /// Por defecto: la paleta de marca extraída del cartel (plan 13 P3).
  static const celeste = AppColors(
    bg: Color(0xFFEDF9FE),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF70D0F8),
    primaryInk: Color(0xFF002848),
    primaryStrong: Color(0xFF2E6492),
    primaryStrongText: Color(0xFF2E6492),
    text: Color(0xFF002848),
  );

  static const verdeSuave = AppColors(
    bg: Color(0xFFE8F7F1),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFF7FD3AE),
    primaryInk: Color(0xFF06392B),
    primaryStrong: Color(0xFF177053),
    primaryStrongText: Color(0xFF177053),
    text: Color(0xFF0A3B2E),
  );

  static const lila = AppColors(
    bg: Color(0xFFF1EFFA),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFA99BE6),
    primaryInk: Color(0xFF1F1240),
    primaryStrong: Color(0xFF5B44B8),
    primaryStrongText: Color(0xFF5B44B8),
    text: Color(0xFF26184F),
  );

  static const durazno = AppColors(
    bg: Color(0xFFFDF3ED),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFF7A873),
    primaryInk: Color(0xFF4A2410),
    primaryStrong: Color(0xFFA54D22),
    primaryStrongText: Color(0xFFA54D22),
    text: Color(0xFF5A2A12),
  );

  static const gris = AppColors(
    bg: Color(0xFFF4F5F6),
    surface: Color(0xFFFFFFFF),
    primary: Color(0xFFB8C4CE),
    primaryInk: Color(0xFF17242E),
    primaryStrong: Color(0xFF4A5B69),
    primaryStrongText: Color(0xFF4A5B69),
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
    'celeste': 'Celeste (por defecto)',
    'verde': 'Verde suave',
    'lila': 'Lila suave',
    'durazno': 'Durazno',
    'gris': 'Gris calmado',
    'contraste': 'Alto contraste',
  };

  /// Estados. Semánticos, no de marca ni de tema: no cambian nunca
  /// (plan 00 §4). Relleno pastel + su tinta oscura.
  static const success = Color(0xFFDDF3E4);
  static const onSuccess = Color(0xFF14522E);
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
    Color? text,
  }) =>
      AppColors(
        bg: bg ?? this.bg,
        surface: surface ?? this.surface,
        primary: primary ?? this.primary,
        primaryInk: primaryInk ?? this.primaryInk,
        primaryStrong: primaryStrong ?? this.primaryStrong,
        primaryStrongText: primaryStrongText ?? this.primaryStrongText,
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
  /// Azul de la burbuja y del texto «BlueTalk» (cartel).
  static const azul = Color(0xFF2E6492);

  /// Navy de titulares (cartel).
  static const navy = Color(0xFF002848);

  /// Verde del corazón del logo (cartel). Solo relleno/decoración:
  /// ~3.4:1 vs blanco, NO AA para texto.
  static const verde = Color(0xFF20A078);

  /// Celeste de marca fuerte (fondo superior del cartel; ícono adaptive).
  static const celeste = Color(0xFF70D0F8);
}

/// Paleta activa del tema elegido: `context.colores.bg`.
extension ColoresContext on BuildContext {
  AppColors get colores =>
      Theme.of(this).extension<AppColors>() ?? AppColors.celeste;
}
