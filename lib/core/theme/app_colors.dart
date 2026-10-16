import 'package:flutter/material.dart';

/// Tokens de color — paleta de marca extraída del cartel oficial
/// (`referencia_logo_y_colores_iniciales.jpeg`, plan 13 P3.1).
///
/// Los códigos hexadecimales salen del cartel con script de una sola vez
/// (djpeg + Python sobre el PPM; método y muestras en
/// `docs/informes/etapa-b-evidencia.md`); no están inventados.
///
/// Todos los contrastes están verificados por `test/core/tokens_test.dart`
/// contra WCAG 2.2 AA (texto ≥4.5:1, elementos de UI ≥3:1).
abstract final class AppColors {
  /// Fondo general: tinte claro (12 %) del celeste de marca #70D0F8; el
  /// celeste fuerte del cartel como fondo de pantalla entera deslumbraría
  /// (plan 00 §4: pastel, sin deslumbrar). Nunca blanco puro.
  static const bg = Color(0xFFEDF9FE);

  /// Tarjetas y superficies (la pantalla del móvil del cartel es blanca).
  static const surface = Color(0xFFFFFFFF);

  /// Relleno celeste de marca (fondo superior del cartel) para botones y
  /// acentos. El texto encima va en [primaryInk].
  static const primary = Color(0xFF70D0F8);

  /// Texto sobre [primary] — 8.7:1 (navy de titulares del cartel).
  static const primaryInk = Color(0xFF002848);

  /// Borde, icono y foco interactivos: azul de marca del cartel (el
  /// anillo de la burbuja y el texto «BlueTalk») — 5.8:1 vs [bg].
  static const primaryStrong = Color(0xFF2E6492);

  /// Texto de acento sobre [bg]/[surface] — 5.8:1 (AA texto ≥4.5:1).
  /// Mismo azul de marca que [primaryStrong]: los dos nombres se
  /// conservan porque expresan usos distintos (borde/icono vs texto).
  static const primaryStrongText = Color(0xFF2E6492);

  /// Texto principal: navy de los titulares del cartel — 14:1 sobre [bg].
  static const text = Color(0xFF002848);

  /// Verde del corazón del logo. Solo relleno y decoración (iconos,
  /// pictogramas de marca): ~3.4:1 contra blanco, NO llega a AA para
  /// texto — para texto usar [text] o [primaryStrongText].
  static const verdeCorazon = Color(0xFF20A078);

  /// Estados. Colores semánticos, no de marca: no cambian con la paleta
  /// ni con el tema (plan 00 §4). Relleno pastel + su tinta oscura.
  static const success = Color(0xFFDDF3E4);
  static const onSuccess = Color(0xFF14522E);
  static const warning = Color(0xFFFBEBC8);
  static const onWarning = Color(0xFF5B4413);
  static const error = Color(0xFFFBE0E0);
  static const onError = Color(0xFF6E1F1F);
}
