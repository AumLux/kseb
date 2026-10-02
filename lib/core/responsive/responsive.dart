/// Device-aware layout rules shared by every screen (DESIGN.md › Layout).
///
/// Use these instead of ad-hoc `width >= 600` checks, so every screen agrees
/// on what a "small phone", "tablet" or "desktop" is:
///
/// ```dart
/// final columns = context.responsive(phone: 2, tablet: 3, desktop: 4);
/// if (context.isWide) …                       // rail instead of bottom bar
/// final gutter = context.pageGutter;          // 16 on phones, 24 wider
/// ```
///
/// [ResponsiveScope] (installed once in `app.dart`) also tightens type a
/// little on very narrow screens (< 360dp: small phones, split screen, the
/// website's phone-frame preview) so labels fit without breaking mid-word.
/// The user's own accessibility text size is always applied on top.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../design/app_tokens.dart';

/// Width classes, narrowest first.
enum DeviceClass {
  /// < 360dp: small or older phones, split screen, embedded previews.
  compact,

  /// 360–599dp: typical phones.
  phone,

  /// 600–1023dp: large phones in landscape, tablets, small windows.
  tablet,

  /// ≥ 1024dp: desktop browsers and large tablets in landscape.
  desktop,
}

abstract final class Breakpoints {
  static const double compact = 360;
  static const double tablet = 600;
  static const double desktop = 1024;

  /// The navigation rail needs some height too (landscape phones).
  static const double railMinHeight = 480;

  static DeviceClass classify(double width) => width < compact
      ? DeviceClass.compact
      : width < tablet
          ? DeviceClass.phone
          : width < desktop
              ? DeviceClass.tablet
              : DeviceClass.desktop;

  /// Type density per width: slightly smaller text below 360dp so short
  /// labels ("New worksheet") fit their tiles. 1.0 from 360dp up.
  static double textFactor(double width) => width < 320
      ? 0.88
      : width < compact
          ? 0.93
          : 1.0;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  DeviceClass get device => Breakpoints.classify(screenWidth);

  bool get isCompact => device == DeviceClass.compact;

  /// Tablet or desktop: rails, multi-column grids, side-by-side panes.
  bool get isWide => screenWidth >= Breakpoints.tablet;

  bool get isDesktop => device == DeviceClass.desktop;

  /// Picks a value for the current width; unspecified classes fall back to
  /// the next narrower one (desktop → tablet → phone; compact → phone).
  T responsive<T>({required T phone, T? compact, T? tablet, T? desktop}) => switch (device) {
        DeviceClass.compact => compact ?? phone,
        DeviceClass.phone => phone,
        DeviceClass.tablet => tablet ?? phone,
        DeviceClass.desktop => desktop ?? tablet ?? phone,
      };

  /// Horizontal page padding.
  double get pageGutter => isWide ? AppSpacing.pageGutterWide : AppSpacing.pageGutter;
}

/// Applies [Breakpoints.textFactor] for the current width on top of the
/// user's text-size setting. Install once, above the router.
class ResponsiveScope extends StatelessWidget {
  const ResponsiveScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final factor = Breakpoints.textFactor(MediaQuery.sizeOf(context).width);
    if (factor == 1.0) return child;
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: _FactorTextScaler(media.textScaler, factor)),
      child: child,
    );
  }
}

/// Multiplies another scaler (keeps Android's non-linear accessibility scaling).
class _FactorTextScaler extends TextScaler {
  const _FactorTextScaler(this.base, this.factor);

  final TextScaler base;
  final double factor;

  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor * factor;

  @override
  bool operator ==(Object other) => other is _FactorTextScaler && other.base == base && other.factor == factor;

  @override
  int get hashCode => Object.hash(base, factor);
}

/// A short label (tile captions, chips) that never breaks inside a word: if
/// its longest word is wider than the space, the font shrinks just enough
/// (down to [minScale]) instead of wrapping "worksheet" as "wor / ksheet".
class FitLabel extends StatelessWidget {
  const FitLabel(
    this.text, {
    super.key,
    required this.style,
    this.maxLines = 2,
    this.textAlign = TextAlign.center,
    this.minScale = 0.75,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final TextAlign textAlign;
  final double minScale;

  /// Font size that fits the longest word in [maxWidth] (pure; unit-tested).
  static double fittedFontSize({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required TextScaler textScaler,
    required TextDirection textDirection,
    double minScale = 0.75,
  }) {
    final size = style.fontSize ?? 14;
    if (!maxWidth.isFinite || maxWidth <= 0) return size;
    var widest = 0.0;
    for (final word in text.split(RegExp(r'\s+'))) {
      if (word.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: word, style: style),
        textDirection: textDirection,
        textScaler: textScaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    if (widest <= maxWidth) return size;
    return size * math.max(minScale, maxWidth / widest);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final fontSize = fittedFontSize(
            text: text,
            style: style,
            maxWidth: constraints.maxWidth,
            textScaler: MediaQuery.textScalerOf(context),
            textDirection: Directionality.of(context),
            minScale: minScale,
          );
          return Text(
            text,
            style: style.copyWith(fontSize: fontSize),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
          );
        },
      );
}
