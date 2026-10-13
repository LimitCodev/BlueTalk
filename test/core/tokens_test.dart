import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bluetalk/core/theme/app_colors.dart';

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
  group('tokens de color — contraste AA (plan 00 §4)', () {
    test('texto sobre bg y surface >= 4.5:1', () {
      expect(_contrast(AppColors.text, AppColors.bg), greaterThanOrEqualTo(4.5));
      expect(_contrast(AppColors.text, AppColors.surface), greaterThanOrEqualTo(4.5));
    });

    test('primaryInk sobre primary >= 4.5:1', () {
      expect(_contrast(AppColors.primaryInk, AppColors.primary), greaterThanOrEqualTo(4.5));
    });

    test('elementos de UI (primaryStrong) sobre bg y surface >= 3:1', () {
      expect(_contrast(AppColors.primaryStrong, AppColors.bg), greaterThanOrEqualTo(3.0));
      expect(_contrast(AppColors.primaryStrong, AppColors.surface), greaterThanOrEqualTo(3.0));
    });

    test('ink de estados sobre su relleno >= 4.5:1', () {
      expect(_contrast(AppColors.onSuccess, AppColors.success), greaterThanOrEqualTo(4.5));
      expect(_contrast(AppColors.onWarning, AppColors.warning), greaterThanOrEqualTo(4.5));
      expect(_contrast(AppColors.onError, AppColors.error), greaterThanOrEqualTo(4.5));
    });
  });
}
