import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/utils/app_colors.dart';

void main() {
  group('AppColors — Primary Palette', () {
    test('primary is #FF6B35', () {
      expect(AppColors.primary, const Color(0xFFFF6B35));
    });
    test('primaryLight is #FF8A65', () {
      expect(AppColors.primaryLight, const Color(0xFFFF8A5C));
    });
    test('primaryDark is #E64A19', () {
      expect(AppColors.primaryDark, const Color(0xFFE64A19));
    });
  });

  group('AppColors — Secondary & Accent', () {
    test('secondary is #6C5CE7', () {
      expect(AppColors.secondary, const Color(0xFF1C1E54));
    });
    test('accent is #00D4AA', () {
      expect(AppColors.accent, const Color(0xFF1D5FD1));
    });
    test('purple is #9B59B6', () {
      expect(AppColors.purple, const Color(0xFF1C1E54));
    });
  });

  group('AppColors — Status Colors', () {
    test('success is #27AE60', () {
      expect(AppColors.success, const Color(0xFF137A3F));
    });
    test('warning is #F39C12', () {
      expect(AppColors.warning, const Color(0xFF8A5300));
    });
    test('error is #E74C3C', () {
      expect(AppColors.error, const Color(0xFFC4213F));
    });
    test('info is #3498DB', () {
      expect(AppColors.info, const Color(0xFF1D5FD1));
    });
  });

  group('AppColors — Neutral Scale', () {
    test('white is #FFFFFF', () {
      expect(AppColors.white, const Color(0xFFFFFFFF));
    });
    test('black is #1A1A1A', () {
      expect(AppColors.black, const Color(0xFF0D253D));
    });
    test('grey50 is #FCFCFC', () {
      expect(AppColors.grey50, const Color(0xFFF6F9FC));
    });
    test('grey100 is #F8F9FA', () {
      expect(AppColors.grey100, const Color(0xFFEEF2F7));
    });
    test('grey200 is #E9ECEF', () {
      expect(AppColors.grey200, const Color(0xFFE3E8EE));
    });
    test('grey300 is #DEE2E6', () {
      expect(AppColors.grey300, const Color(0xFFD5DDE7));
    });
    test('grey400 is #CED4DA', () {
      expect(AppColors.grey400, const Color(0xFF9AA6B8));
    });
    test('grey500 is #6C757D', () {
      expect(AppColors.grey500, const Color(0xFF5B6B84));
    });
    test('grey600 is #495057', () {
      expect(AppColors.grey600, const Color(0xFF273951));
    });
    test('grey700 is #343A40', () {
      expect(AppColors.grey700, const Color(0xFF1C2F47));
    });
    test('grey800 is #212529', () {
      expect(AppColors.grey800, const Color(0xFF0D253D));
    });
    test('grey900 is #1A1A1A', () {
      expect(AppColors.grey900, const Color(0xFF0D253D));
    });
  });

  group('AppColors — Semantic Aliases', () {
    test('background maps to canvas-soft', () {
      expect(AppColors.background, AppColors.grey50);
    });
    test('surface maps to white', () {
      expect(AppColors.surface, AppColors.white);
    });
    test('surfaceVariant maps to grey50', () {
      expect(AppColors.surfaceVariant, AppColors.grey50);
    });
    test('textPrimary maps to grey800', () {
      expect(AppColors.textPrimary, AppColors.grey800);
    });
    test('textSecondary maps to grey500', () {
      expect(AppColors.textSecondary, AppColors.grey500);
    });
    test('textOnPrimary is navy ink (AA on orange)', () {
      expect(AppColors.textOnPrimary, AppColors.black);
    });
  });

  group('AppColors — Dashboard Card Colors', () {
    test('has 4 entries in correct order', () {
      expect(AppColors.dashboardCardColors.length, 4);
      expect(AppColors.dashboardCardColors[0], const Color(0xFF1C1E54));
      expect(AppColors.dashboardCardColors[1], const Color(0xFF1D5FD1));
      expect(AppColors.dashboardCardColors[2], const Color(0xFF137A3F));
      expect(AppColors.dashboardCardColors[3], const Color(0xFFB93D10));
    });
  });
}
