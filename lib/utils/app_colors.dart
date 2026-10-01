import 'package:flutter/material.dart';

import '../core/design/app_tokens.dart' as t;

/// LEGACY palette — aliases onto the DESIGN.md tokens in
/// `lib/core/design/app_tokens.dart` so screens not yet rewritten adopt the
/// new design. Do not use in new code; import `core/design/design.dart`.
abstract final class AppColors {
  // ── Primary Palette ───────────────────────────────────────────────
  static const Color primary = t.AppColors.primary;
  static const Color primaryLight = Color(0xFFFF8A5C);
  static const Color primaryDark = t.AppColors.primaryPress;

  // ── Secondary & Accent ────────────────────────────────────────────
  static const Color secondary = t.AppColors.brandDark;
  static const Color accent = t.AppColors.info;
  static const Color purple = t.AppColors.brandDark;

  // ── Status Colors ─────────────────────────────────────────────────
  static const Color success = t.AppColors.success;
  static const Color warning = t.AppColors.warning;
  static const Color error = t.AppColors.danger;
  static const Color info = t.AppColors.info;

  // ── Neutral Scale ─────────────────────────────────────────────────
  static const Color white = t.AppColors.canvas;
  static const Color black = t.AppColors.ink;
  static const Color grey50 = t.AppColors.canvasSoft;
  static const Color grey100 = t.AppColors.canvasSunken;
  static const Color grey200 = t.AppColors.hairline;
  static const Color grey300 = Color(0xFFD5DDE7);
  static const Color grey400 = t.AppColors.inkDisabled;
  static const Color grey500 = t.AppColors.inkMute;
  static const Color grey600 = t.AppColors.inkSecondary;
  static const Color grey700 = Color(0xFF1C2F47);
  static const Color grey800 = t.AppColors.ink;
  static const Color grey900 = t.AppColors.ink;

  // ── Semantic Aliases ──────────────────────────────────────────────
  static const Color background = t.AppColors.canvasSoft;
  static const Color surface = t.AppColors.canvas;
  static const Color surfaceVariant = grey50;
  static const Color cardShadow = Color(0x14003770);

  // ── Text Colors ───────────────────────────────────────────────────
  static const Color textPrimary = grey800;
  static const Color textSecondary = grey500;
  static const Color textTertiary = grey400;
  /// Navy on orange (5.49:1); white on orange fails WCAG AA.
  static const Color textOnPrimary = t.AppColors.onPrimary;
  static const Color textOnDark = white;
  static const Color textPlaceholder = grey500;

  // ── Opacity Variants (computed) ───────────────────────────────────
  static Color get primaryWithLowOpacity => primary.withValues(alpha: 0.08);
  static Color get primaryWithMediumOpacity => primary.withValues(alpha: 0.12);
  static Color get primaryWithHighOpacity => primary.withValues(alpha: 0.16);

  static Color get whiteWithLowOpacity => white.withValues(alpha: 0.1);
  static Color get greyWithLowOpacity => grey200.withValues(alpha: 0.5);
  static Color get shadowLight => black.withValues(alpha: 0.04);
  static Color get shadowMedium => black.withValues(alpha: 0.08);
  static Color get shadowDark => black.withValues(alpha: 0.12);

  // ── Dashboard Card Colors (ordered list) ──────────────────────────
  static const List<Color> dashboardCardColors = [
    t.AppColors.brandDark,
    t.AppColors.info,
    t.AppColors.success,
    t.AppColors.primaryInk,
  ];

  // ── Status Colors for Stats ───────────────────────────────────────
  static const List<Color> statColors = [
    info,
    success,
  ];

  // ── Gradients ─────────────────────────────────────────────────────
  static LinearGradient get primaryGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primary, primaryLight],
      );

  static LinearGradient get surfaceGradient => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [white, grey50],
      );

  static LinearGradient cardGradient(Color color) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.08),
          color.withValues(alpha: 0.04),
        ],
      );

  // ── Backward-compatibility aliases ────────────────────────────────
  // These delegate to AppTypography / AppSpacing / AppDecorations.
  // Existing code will still compile. Remove once migration is complete.

  @Deprecated('Use AppTypography.fontSizeXS')
  static const double fontSizeXS = 11.0;
  @Deprecated('Use AppTypography.fontSizeSM')
  static const double fontSizeSM = 12.0;
  @Deprecated('Use AppTypography.fontSizeBase')
  static const double fontSizeBase = 14.0;
  @Deprecated('Use AppTypography.fontSizeLG')
  static const double fontSizeLG = 16.0;
  @Deprecated('Use AppTypography.fontSizeXL')
  static const double fontSizeXL = 18.0;
  @Deprecated('Use AppTypography.fontSize2XL')
  static const double fontSize2XL = 20.0;
  @Deprecated('Use AppTypography.fontSize3XL')
  static const double fontSize3XL = 24.0;
  @Deprecated('Use AppTypography.fontSize4XL')
  static const double fontSize4XL = 28.0;

  @Deprecated('Use AppTypography.captionStyle')
  static TextStyle get captionStyle => TextStyle(
        fontSize: fontSizeSM,
        color: textSecondary,
        fontWeight: FontWeight.w400,
      );

  @Deprecated('Use AppTypography.bodyStyle')
  static TextStyle get bodyStyle => TextStyle(
        fontSize: fontSizeBase,
        color: textPrimary,
        fontWeight: FontWeight.w400,
      );

  @Deprecated('Use AppTypography.bodyMediumStyle')
  static TextStyle get bodyMediumStyle => TextStyle(
        fontSize: fontSizeBase,
        color: textPrimary,
        fontWeight: FontWeight.w500,
      );

  @Deprecated('Use AppTypography.subheadingStyle')
  static TextStyle get subheadingStyle => TextStyle(
        fontSize: fontSizeLG,
        color: textPrimary,
        fontWeight: FontWeight.w600,
      );

  @Deprecated('Use AppTypography.headingStyle')
  static TextStyle get headingStyle => TextStyle(
        fontSize: fontSizeXL,
        color: textPrimary,
        fontWeight: FontWeight.w600,
      );

  @Deprecated('Use AppTypography.titleStyle')
  static TextStyle get titleStyle => TextStyle(
        fontSize: fontSize2XL,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      );

  @Deprecated('Use AppTypography.displayStyle')
  static TextStyle get displayStyle => TextStyle(
        fontSize: fontSize3XL,
        color: textPrimary,
        fontWeight: FontWeight.w700,
      );

  @Deprecated('Use AppTypography.displayLargeStyle')
  static TextStyle get displayLargeStyle => TextStyle(
        fontSize: fontSize4XL,
        color: textPrimary,
        fontWeight: FontWeight.w800,
      );

  @Deprecated('Use context.responsiveHeight()')
  static double getResponsiveHeight(BuildContext context, double baseHeight) {
    final screenHeight = MediaQuery.of(context).size.height;
    return baseHeight * (screenHeight / 844.0);
  }

  @Deprecated('Use context.responsiveWidth()')
  static double getResponsiveWidth(BuildContext context, double baseWidth) {
    final screenWidth = MediaQuery.of(context).size.width;
    return baseWidth * (screenWidth / 390.0);
  }

  @Deprecated('Use context.responsivePadding()')
  static double getResponsivePadding(BuildContext context, double basePadding) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) return basePadding * 0.6;
    if (screenHeight < 800) return basePadding * 0.8;
    return basePadding;
  }

  @Deprecated('Use context.responsiveSpacing()')
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) return baseSpacing * 0.5;
    if (screenHeight < 800) return baseSpacing * 0.75;
    return baseSpacing;
  }

  @Deprecated('Use context.responsiveFontSize()')
  static double getResponsiveFontSize(
      BuildContext context, double baseFontSize) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 700) return baseFontSize * 0.85;
    if (screenHeight < 800) return baseFontSize * 0.92;
    return baseFontSize;
  }

  @Deprecated('Use context.responsiveTextStyle()')
  static TextStyle getResponsiveTextStyle(
      BuildContext context, TextStyle baseStyle) {
    return baseStyle.copyWith(
      fontSize:
          getResponsiveFontSize(context, baseStyle.fontSize ?? fontSizeBase),
    );
  }

  @Deprecated('Use AppDecorations.modernCardDecoration')
  static BoxDecoration get modernCardDecoration => BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: shadowMedium,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      );

  @Deprecated('Use AppDecorations.modernCardDecorationWithColor()')
  static BoxDecoration modernCardDecorationWithColor(Color color) =>
      BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
}
