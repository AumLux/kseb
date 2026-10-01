import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/app_tokens.dart';

/// WCAG 2.x contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double channel(double c) =>
      c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = lum(a), lb = lum(b);
  final hi = math.max(la, lb), lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  group('DESIGN.md contrast guarantees', () {
    final textPairs = <String, (Color, Color)>{
      'ink on canvas': (AppColors.ink, AppColors.canvas),
      'ink on canvas-soft': (AppColors.ink, AppColors.canvasSoft),
      'ink-secondary on canvas': (AppColors.inkSecondary, AppColors.canvas),
      'ink-mute on canvas': (AppColors.inkMute, AppColors.canvas),
      'ink-mute on canvas-soft': (AppColors.inkMute, AppColors.canvasSoft),
      'on-primary on primary': (AppColors.onPrimary, AppColors.primary),
      'primary-ink on canvas': (AppColors.primaryInk, AppColors.canvas),
      'primary-ink on primary-soft':
          (AppColors.primaryInk, AppColors.primarySoft),
      'success on success-bg': (AppColors.success, AppColors.successBg),
      'warning on warning-bg': (AppColors.warning, AppColors.warningBg),
      'danger on danger-bg': (AppColors.danger, AppColors.dangerBg),
      'info on info-bg': (AppColors.info, AppColors.infoBg),
      'success on canvas': (AppColors.success, AppColors.canvas),
      'warning on canvas': (AppColors.warning, AppColors.canvas),
      'danger on canvas': (AppColors.danger, AppColors.canvas),
      'info on canvas': (AppColors.info, AppColors.canvas),
      'on-dark on brand-dark': (AppColors.onDark, AppColors.brandDark),
      'on-dark on danger': (AppColors.onDark, AppColors.danger),
      'on-dark on ink (snackbar)': (AppColors.onDark, AppColors.ink),
      'on-primary on primary-press': (AppColors.onPrimary, AppColors.primaryPress),
      'primary-ink on canvas-soft': (AppColors.primaryInk, AppColors.canvasSoft),
      'brand-orange-ink on canvas': (AppColors.brandOrangeInk, AppColors.canvas),
      'ink on cream (mesh)': (AppColors.ink, AppColors.cream),
      'ink on lavender (mesh)': (AppColors.ink, AppColors.lavender),
    };

    textPairs.forEach((name, pair) {
      test('$name is >= 4.5:1 (text)', () {
        expect(contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
      });
    });

    test('input boundary is >= 3:1 (WCAG 1.4.11)', () {
      expect(contrast(AppColors.borderInput, AppColors.canvas),
          greaterThanOrEqualTo(3.0));
    });

    test('focus ring is >= 3:1 on canvas', () {
      expect(contrast(AppColors.focusRing, AppColors.canvas),
          greaterThanOrEqualTo(3.0));
    });

    test('white on brand orange fails, so orange is never a text background', () {
      expect(contrast(Colors.white, AppColors.brandOrange), lessThan(3.0));
      expect(AppColors.primary, isNot(AppColors.brandOrange));
    });
  });
}
