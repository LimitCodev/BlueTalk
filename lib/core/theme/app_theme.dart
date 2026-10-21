import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema Material 3 generado desde la paleta elegida (plan 13 P4).
///
/// La paleta por defecto y las formas siguen la web oficial de BlueTalk:
/// fondo azul muy claro, barra superior azul, tarjetas blancas de esquinas
/// redondeadas y tipografía Nunito. La tipografía se empaqueta con la app
/// (sin red) y el escalado del sistema lo aplica Flutter automáticamente.
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
    surfaceContainer: paleta.surface,
    surfaceContainerHigh: paleta.surface,
    surfaceContainerHighest: paleta.bg,
    onSurface: paleta.text,
    onSurfaceVariant: paleta.text,
    outline: paleta.primaryStrong,
    outlineVariant: AppColors.borde,
    secondary: paleta.primaryStrong,
    onSecondary: paleta.surface,
    error: AppColors.error,
    onError: AppColors.onError,
  );

  final base = ThemeData(useMaterial3: true, fontFamily: 'Nunito');
  final radio = BorderRadius.circular(16);
  final radioBoton = BorderRadius.circular(14);
  final borde = AppColors.borde;

  final texto = base.textTheme.copyWith(
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
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      height: 1.35,
      color: paleta.text,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w800,
      color: paleta.text,
    ),
    titleMedium: base.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: paleta.text,
    ),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w800,
      color: paleta.text,
    ),
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w700,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: paleta.bg,
    fontFamily: 'Nunito',
    // Paleta accesible a toda la UI vía context.colores.
    extensions: <ThemeExtension<dynamic>>[paleta],
    textTheme: texto,
    appBarTheme: AppBarTheme(
      backgroundColor: paleta.header,
      foregroundColor: paleta.onHeader,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Nunito',
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: paleta.onHeader,
      ),
      iconTheme: IconThemeData(color: paleta.onHeader),
      actionsIconTheme: IconThemeData(color: paleta.onHeader),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: paleta.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 68,
      indicatorColor: paleta.primary.withValues(alpha: 0.16),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w800
              : FontWeight.w600,
          color: paleta.text,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? paleta.primaryStrongText
              : paleta.text,
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: paleta.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: radio,
        side: BorderSide(color: borde),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: paleta.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borde),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borde),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: paleta.primary, width: 2),
      ),
      labelStyle: TextStyle(color: paleta.text),
      hintStyle: TextStyle(
        color: paleta.text.withValues(alpha: 0.55),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: paleta.primary,
        foregroundColor: paleta.primaryInk,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: radioBoton),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: paleta.primaryStrongText,
        minimumSize: const Size(64, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        side: BorderSide(color: paleta.primaryStrong, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: radioBoton),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: paleta.primaryStrongText,
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
          fontFamily: 'Nunito',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Marca.navy,
      contentTextStyle: const TextStyle(
        fontFamily: 'Nunito',
        color: Colors.white,
        fontSize: 15,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: paleta.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: radio),
    ),
    dividerTheme: DividerThemeData(color: borde, thickness: 1, space: 1),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: paleta.primary),
    listTileTheme: ListTileThemeData(iconColor: paleta.primaryStrongText),
  );
}
