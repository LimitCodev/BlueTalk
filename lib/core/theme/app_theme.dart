import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema Material 3 generado desde la paleta elegida (plan 13 P4).
///
/// Tipografía sans legible con base 16–18sp; el escalado por ajuste del
/// sistema (`textScaleFactor`) lo aplica Flutter automáticamente.
ThemeData buildBlueTalkTheme(AppColors paleta) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: paleta.primary,
    brightness: Brightness.light,
  ).copyWith(
    // Todos los tonos que la UI real usa quedan atados a la paleta:
    // los derivados de `fromSeed` (contenedores, outline, secondary)
    // no estaban verificados AA y en «Alto contraste» salían grises
    // de croma cero (revisión Etapa B, MEDIO-1).
    primary: paleta.primary,
    onPrimary: paleta.primaryInk,
    surface: paleta.surface,
    surfaceContainerLowest: paleta.surface,
    surfaceContainerLow: paleta.surface,
    surfaceContainer: paleta.bg,
    surfaceContainerHigh: paleta.bg,
    surfaceContainerHighest: paleta.bg,
    onSurface: paleta.text,
    onSurfaceVariant: paleta.text,
    outline: paleta.primaryStrong,
    outlineVariant: paleta.primary,
    secondary: paleta.primaryStrong,
    onSecondary: paleta.surface,
    error: AppColors.error,
    onError: AppColors.onError,
  );

  final base = ThemeData(useMaterial3: true);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: paleta.bg,
    // Paleta accesible a toda la UI vía context.colores.
    extensions: <ThemeExtension<dynamic>>[paleta],
    textTheme: base.textTheme.copyWith(
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 18,
        height: 1.4,
        color: paleta.text,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.4,
        color: paleta.text,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: paleta.text,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
