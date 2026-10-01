import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// The brand's atmospheric backdrop (DESIGN.md › Gradient mesh): soft blobs
/// of cream, orange, lavender, indigo and ruby washed over white. Painted
/// once and cached (RepaintBoundary), so it costs nothing while scrolling.
///
/// Blob alphas are kept low enough that ink text on top stays >= 7:1.
class GradientMesh extends StatelessWidget {
  const GradientMesh({super.key, this.child, this.intensity = 1});

  final Widget? child;

  /// 0..1 scales every blob's opacity (lower for busy screens).
  final double intensity;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: CustomPaint(painter: _MeshPainter(intensity), child: child),
      );
}

class _MeshPainter extends CustomPainter {
  const _MeshPainter(this.intensity);

  final double intensity;

  // (center as fraction of size, radius as fraction of width, color, alpha)
  static const _blobs = [
    (Offset(0.05, 0.10), 0.85, AppColors.cream, 0.95),
    (Offset(0.30, -0.05), 0.70, AppColors.brandOrange, 0.30),
    (Offset(0.70, 0.05), 0.75, AppColors.lavender, 0.55),
    (Offset(1.05, 0.30), 0.65, AppColors.primary, 0.22),
    (Offset(0.85, -0.10), 0.45, AppColors.ruby, 0.18),
    (Offset(0.45, 0.45), 0.55, AppColors.magenta, 0.10),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.canvas);
    for (final (center, radius, color, alpha) in _blobs) {
      final c = Offset(center.dx * size.width, center.dy * size.height);
      final r = radius * size.width;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [color.withValues(alpha: alpha * intensity), color.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }
    // Fade into the page so content below sits on clean white.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00FFFFFF), Color(0x00FFFFFF), AppColors.canvas],
          stops: [0, 0.55, 1],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.intensity != intensity;
}
