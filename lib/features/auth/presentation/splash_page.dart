import 'package:flutter/material.dart';

import '../../../core/design/design.dart';

/// Shown only while the session restores (usually a single frame after the
/// native splash). The mark draws itself, continuing the native animation.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (_c.value == 0) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Semantics(
            label: 'AumLux',
            child: AnimatedBuilder(
              animation: CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
              builder: (context, _) => CustomPaint(
                size: const Size.square(88),
                painter: BrandMarkPainter(progress: Curves.easeOutCubic.transform(_c.value)),
              ),
            ),
          ),
        ),
      );
}
