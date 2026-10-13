import 'package:flutter/material.dart';

/// Tokens de color — paleta celeste pastel (plan 00 §4).
///
/// Todos los contrastes están verificados por `test/core/tokens_test.dart`
/// contra WCAG 2.2 AA (texto ≥4.5:1, elementos de UI ≥3:1).
abstract final class AppColors {
  /// Fondo general. Nunca blanco puro (deslumbra en pantallas baratas).
  static const bg = Color(0xFFF3FAFF);

  /// Tarjetas y superficies.
  static const surface = Color(0xFFFFFFFF);

  /// Relleno pastel de botones y acentos. El texto encima va en [primaryInk].
  static const primary = Color(0xFF7FC9EA);

  /// Texto sobre [primary] — 7.3:1.
  static const primaryInk = Color(0xFF12333B);

  /// Borde, icono y foco interactivos: el único celeste con ≥3:1 vs fondo
  /// (4.2:1). El relleno pastel [primary] queda para superficies grandes.
  /// NO usar para texto: 4.2:1 no llega a AA (usa [primaryStrongText]).
  static const primaryStrong = Color(0xFF2F7FA8);

  /// Texto de acento sobre [bg]/[surface] — 4.8:1 (AA texto ≥4.5:1).
  /// Un tono más oscuro que [primaryStrong] porque los encabezados
  /// de sección son texto y exigen 4.5:1.
  static const primaryStrongText = Color(0xFF2A7699);

  /// Texto principal sobre bg — 11.4:1.
  static const text = Color(0xFF1F3A44);

  /// Estados. Relleno pastel + su tinta oscura (≥7.8:1 entre sí).
  static const success = Color(0xFFDDF3E4);
  static const onSuccess = Color(0xFF14522E);
  static const warning = Color(0xFFFBEBC8);
  static const onWarning = Color(0xFF5B4413);
  static const error = Color(0xFFFBE0E0);
  static const onError = Color(0xFF6E1F1F);
}
