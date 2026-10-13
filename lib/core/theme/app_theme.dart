import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema Material 3 con la paleta celeste pastel.
///
/// Tipografía sans legible con base 16–18sp; el escalado por ajuste del
/// sistema (`textScaleFactor`) lo aplica Flutter automáticamente.
ThemeData buildBlueTalkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: AppColors.primaryInk,
    surface: AppColors.surface,
    onSurface: AppColors.text,
    error: AppColors.error,
    onError: AppColors.onError,
  );

  final base = ThemeData(useMaterial3: true);

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: base.textTheme.copyWith(
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        fontSize: 18,
        height: 1.4,
        color: AppColors.text,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        fontSize: 16,
        height: 1.4,
        color: AppColors.text,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.text,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
