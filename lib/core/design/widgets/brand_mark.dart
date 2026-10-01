import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// AumLux mark: an "A" drawn as a transmission pylon (crossarm, insulators,
/// lattice bar) on the orange → ruby → indigo brand tile.
///
/// Geometry lives in a 108-unit square, the Android adaptive-icon canvas, so
/// the launcher icon, splash and in-app mark share one drawing
/// (android/app/src/main/res/drawable/ic_launcher_foreground.xml mirrors it).
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 56, this.tile = true});

  final double size;

  /// False draws the glyph alone in [AppColors.ink] (e.g. on a gradient).
  final bool tile;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AumLux',
      image: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.square(size),
          painter: BrandMarkPainter(tile: tile),
        ),
      ),
    );
  }
}

class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({this.tile = true, this.cornerFraction = 0.24, this.fullBleed = false, this.progress = 1});

  final bool tile;
  final double cornerFraction;

  /// Fill the whole canvas with the gradient (maskable / adaptive icons).
  final bool fullBleed;

  /// 0..1 draw-on progress of the glyph strokes (splash animation).
  final double progress;

  static const gradient = [AppColors.brandOrange, AppColors.ruby, AppColors.primary];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 108;
    final rect = Offset.zero & size;
    if (tile) {
      final paint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
          stops: [0.0, 0.55, 1.0],
        ).createShader(rect);
      if (fullBleed) {
        canvas.drawRect(rect, paint);
      } else {
        canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(size.width * cornerFraction)), paint);
      }
    }

    // Without a tile the glyph (bounds ≈ 29..79 × 27..82) fills the box.
    canvas.save();
    if (!tile) {
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(108 / 56);
      canvas.translate(-54 * s, -54.5 * s);
    }
    final ink = tile ? Colors.white : AppColors.ink;
    final stroke = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void line(double x1, double y1, double x2, double y2, double w, double from, double to) {
      final t = ((progress - from) / (to - from)).clamp(0.0, 1.0);
      if (t == 0) return;
      stroke.strokeWidth = w * s;
      canvas.drawLine(Offset(x1 * s, y1 * s), Offset((x1 + (x2 - x1) * t) * s, (y1 + (y2 - y1) * t) * s), stroke);
    }

    // Legs rise from the ground to the apex, then the arms and bar appear.
    line(38, 78, 54, 31, 7.5, 0.0, 0.45);
    line(70, 78, 54, 31, 7.5, 0.0, 0.45);
    line(33, 45, 75, 45, 6, 0.40, 0.70);
    line(44.2, 62, 63.8, 62, 6, 0.55, 0.80);

    final dot = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);
    if (dot > 0) {
      final fill = Paint()..color = ink;
      canvas.drawCircle(Offset(33 * s, 53 * s), 3.6 * s * dot, fill);
      canvas.drawCircle(Offset(75 * s, 53 * s), 3.6 * s * dot, fill);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BrandMarkPainter old) =>
      old.progress != progress || old.tile != tile || old.fullBleed != fullBleed;
}
