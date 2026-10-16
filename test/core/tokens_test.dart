import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/core/theme/app_colors.dart';
import 'package:bluetalk/data/models/models.dart';

/// Luminancia relativa según WCAG 2.2 (fórmula oficial).
double _luminance(Color color) {
  double linearize(double c) {
    return c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  }

  return 0.2126 * linearize(color.r) +
      0.7152 * linearize(color.g) +
      0.0722 * linearize(color.b);
}

/// Ratio de contraste entre dos colores (1 = mismo color, 21 = blanco/negro).
double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('tokens de color — contraste AA (plan 00 §4, paleta por defecto)', () {
    final p = AppColors.celeste;

    test('texto sobre bg y surface >= 4.5:1', () {
      expect(_contrast(p.text, p.bg), greaterThanOrEqualTo(4.5));
      expect(_contrast(p.text, p.surface), greaterThanOrEqualTo(4.5));
    });

    test('primaryInk sobre primary >= 4.5:1', () {
      expect(_contrast(p.primaryInk, p.primary), greaterThanOrEqualTo(4.5));
    });

    test('elementos de UI (primaryStrong) sobre bg y surface >= 3:1', () {
      expect(_contrast(p.primaryStrong, p.bg), greaterThanOrEqualTo(3.0));
      expect(_contrast(p.primaryStrong, p.surface), greaterThanOrEqualTo(3.0));
    });

    test('texto de acento (primaryStrongText) sobre bg y surface >= 4.5:1', () {
      expect(
        _contrast(p.primaryStrongText, p.bg),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(p.primaryStrongText, p.surface),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('ink de estados sobre su relleno >= 4.5:1', () {
      expect(_contrast(AppColors.onSuccess, AppColors.success), greaterThanOrEqualTo(4.5));
      expect(_contrast(AppColors.onWarning, AppColors.warning), greaterThanOrEqualTo(4.5));
      expect(_contrast(AppColors.onError, AppColors.error), greaterThanOrEqualTo(4.5));
    });
  });

  group('los 6 temas tienen contraste AA (plan 13 P4, aceptación)', () {
    for (final entry in AppColors.temas.entries) {
      test('tema «${entry.key}»: texto >= 4.5:1 e ink >= 4.5:1', () {
        final p = entry.value;
        expect(_contrast(p.text, p.bg), greaterThanOrEqualTo(4.5),
            reason: 'texto sobre bg');
        expect(_contrast(p.text, p.surface), greaterThanOrEqualTo(4.5),
            reason: 'texto sobre surface');
        expect(_contrast(p.primaryInk, p.primary), greaterThanOrEqualTo(4.5),
            reason: 'ink sobre el relleno del botón');
        expect(_contrast(p.primaryStrongText, p.bg), greaterThanOrEqualTo(4.5),
            reason: 'acento sobre bg');
        expect(_contrast(p.primaryStrongText, p.surface),
            greaterThanOrEqualTo(4.5),
            reason: 'acento sobre surface');
        expect(_contrast(p.primaryStrong, p.bg), greaterThanOrEqualTo(3.0),
            reason: 'borde/icono sobre bg');
        expect(_contrast(p.primaryStrong, p.surface),
            greaterThanOrEqualTo(3.0),
            reason: 'borde/icono sobre surface');
      });
    }

    test('celeste es el tema por defecto de los ajustes', () {
      expect(const AppSettings().tema, 'celeste');
      expect(AppColors.temas['celeste'], AppColors.celeste);
    });

    test('cada tema tiene nombre literal en el selector', () {
      expect(AppColors.nombresTemas.keys, containsAll(AppColors.temas.keys));
      for (final nombre in AppColors.nombresTemas.values) {
        expect(nombre, isNotEmpty);
      }
    });
  });
}
