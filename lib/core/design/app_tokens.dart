import 'package:flutter/material.dart';

/// Design tokens from DESIGN.md (the single source of truth).
///
/// Every hex below is contrast-checked in DESIGN.md. If a value changes here,
/// update DESIGN.md in the same commit.
abstract final class AppColors {
  // ── Brand ─────────────────────────────────────────────────────────
  /// Fill only (buttons, active nav, progress). Never text on white.
  static const Color primary = Color(0xFFFF6B35);

  /// Text/icons on [primary] fills (5.49:1). White on orange fails AA.
  static const Color onPrimary = Color(0xFF0D253D);
  static const Color primaryPress = Color(0xFFE64A19);
  static const Color primarySoft = Color(0xFFFFE9DF);

  /// Orange used as text, icon, link or focus ring on white (5.62:1).
  static const Color primaryInk = Color(0xFFB93D10);
  static const Color brandDark = Color(0xFF1C1E54);

  // ── Ink ───────────────────────────────────────────────────────────
  static const Color ink = Color(0xFF0D253D);
  static const Color inkSecondary = Color(0xFF273951);
  static const Color inkMute = Color(0xFF5B6B84);
  static const Color inkDisabled = Color(0xFF9AA6B8);
  static const Color onDark = Color(0xFFFFFFFF);

  // ── Surfaces ──────────────────────────────────────────────────────
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color canvasSoft = Color(0xFFF6F9FC);
  static const Color canvasSunken = Color(0xFFEEF2F7);
  static const Color hairline = Color(0xFFE3E8EE);

  /// Interactive boundaries (inputs, checkboxes, secondary buttons) — 3.32:1.
  static const Color borderInput = Color(0xFF7F8EA6);
  static const Color focusRing = primaryInk;
  static const Color scrim = Color(0x990D253D);

  // ── Semantic (fg on bg pairs are all >= 4.5:1) ─────────────────────
  static const Color success = Color(0xFF137A3F);
  static const Color successBg = Color(0xFFE7F6ED);
  static const Color warning = Color(0xFF8A5300);
  static const Color warningBg = Color(0xFFFFF4DB);
  static const Color danger = Color(0xFFC4213F);
  static const Color dangerBg = Color(0xFFFDECEF);
  static const Color info = Color(0xFF1D5FD1);
  static const Color infoBg = Color(0xFFEAF1FD);
}

abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;

  /// Horizontal page gutter for phones; use [pageGutterWide] at >= 600dp.
  static const double pageGutter = lg;
  static const double pageGutterWide = xl;

  /// Max content widths (DESIGN.md › Layout).
  static const double formMaxWidth = 640;
  static const double contentMaxWidth = 1200;
}

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 9999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
  static const BorderRadius sheetTop =
      BorderRadius.vertical(top: Radius.circular(xl));
}

abstract final class AppShadows {
  static const List<BoxShadow> none = [];

  /// Cards sitting on canvas-soft.
  static const List<BoxShadow> level1 = [
    BoxShadow(color: Color(0x14003770), blurRadius: 3, offset: Offset(0, 1)),
  ];

  /// Floating layers only: sheets, dialogs, menus, bottom nav, snackbars.
  static const List<BoxShadow> level2 = [
    BoxShadow(color: Color(0x14003770), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A003770), blurRadius: 6, offset: Offset(0, 2)),
  ];
}

abstract final class AppSizes {
  static const double minTouchTarget = 48;
  static const double primaryActionHeight = 52;
  static const double inputHeight = 52;
  static const double listRowMinHeight = 56;
  static const double iconSm = 16;
  static const double iconMd = 20;
  static const double icon = 24;
  static const double iconEmpty = 48;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration slow = Duration(milliseconds: 280);
  static const Curve curve = Curves.easeOutCubic;
}

/// Typography from DESIGN.md. Weight 300 only at >= 28px; body never < 400.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  /// Malayalam glyphs fall through to Noto Sans Malayalam.
  static const List<String> fontFallback = ['Noto Sans Malayalam', 'Roboto'];

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFallback,
    color: AppColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static final TextStyle display = _base.copyWith(
      fontSize: 32, fontWeight: FontWeight.w300, height: 1.15,
      letterSpacing: -0.64);
  static final TextStyle headline = _base.copyWith(
      fontSize: 24, fontWeight: FontWeight.w400, height: 1.2,
      letterSpacing: -0.3);
  static final TextStyle title = _base.copyWith(
      fontSize: 20, fontWeight: FontWeight.w500, height: 1.3,
      letterSpacing: -0.2);
  static final TextStyle subtitle =
      _base.copyWith(fontSize: 17, fontWeight: FontWeight.w500, height: 1.35);
  static final TextStyle body =
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w400, height: 1.45);
  static final TextStyle bodyStrong =
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600, height: 1.45);
  static final TextStyle bodyTabular = _base.copyWith(
      fontSize: 15, fontWeight: FontWeight.w500, height: 1.4,
      letterSpacing: -0.2, fontFeatures: _tabular);
  static final TextStyle kpi = _base.copyWith(
      fontSize: 28, fontWeight: FontWeight.w400, height: 1.1,
      letterSpacing: -0.5, fontFeatures: _tabular);
  static final TextStyle label =
      _base.copyWith(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3);
  static final TextStyle button =
      _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600, height: 1.0);
  static final TextStyle caption = _base.copyWith(
      fontSize: 13, fontWeight: FontWeight.w400, height: 1.4,
      color: AppColors.inkMute);
  static final TextStyle overline = _base.copyWith(
      fontSize: 12, fontWeight: FontWeight.w600, height: 1.2,
      letterSpacing: 0.6, color: AppColors.inkMute);

  /// Malayalam breaks with negative tracking; force 0 spacing and >= 1.5 LH.
  static TextStyle forMalayalam(TextStyle style) => style.copyWith(
        letterSpacing: 0,
        height: (style.height ?? 1.0) < 1.5 ? 1.5 : style.height,
      );
}
