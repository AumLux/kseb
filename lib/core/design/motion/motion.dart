import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';

/// True when the OS asks for reduced motion; every animation here honours it.
bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Page transition: the incoming page rises 3% and fades in over the
/// outgoing one, which stays still. Only one layer animates and nothing is
/// scaled, so it stays at 60/120 fps on low-end phones.
class AppPageTransitions extends PageTransitionsBuilder {
  const AppPageTransitions();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 260);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  static final _slide = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion(context)) return child;
    final curved = CurvedAnimation(parent: animation, curve: AppMotion.curve, reverseCurve: Curves.easeInCubic);
    return SlideTransition(
      position: _slide.animate(curved),
      child: FadeTransition(opacity: curved, child: child),
    );
  }
}

/// Shrinks its child to [scale] while a finger is down and springs back on
/// release. Purely visual (no gestures, no semantics), so it can wrap any
/// button without changing how it behaves or reads to TalkBack.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true, this.scale = 0.97});

  final Widget child;
  final bool enabled;
  final double scale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: AppMotion.press, reverseDuration: AppMotion.base);
  late final _scale = Tween<double>(begin: 1, end: widget.scale)
      .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut, reverseCurve: Curves.easeOutBack));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _up([_]) => _c.reverse();

  @override
  Widget build(BuildContext context) => Listener(
        onPointerDown: (_) {
          if (widget.enabled && !reduceMotion(context)) _c.forward();
        },
        onPointerUp: _up,
        onPointerCancel: _up,
        child: ScaleTransition(scale: _scale, child: widget.child),
      );
}

/// A tappable surface with [PressScale] feedback, a soft highlight (visible
/// press/focus state) and a selection haptic.
class Pressable extends StatelessWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.scale = 0.97,
    this.haptic = true,
    this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => PressScale(
        enabled: onTap != null,
        scale: scale,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: borderRadius,
            splashFactory: NoSplash.splashFactory,
            highlightColor: AppColors.ink.withValues(alpha: 0.05),
            onTap: onTap == null
                ? null
                : () {
                    if (haptic) HapticFeedback.selectionClick();
                    onTap!();
                  },
            onLongPress: onLongPress,
            child: child,
          ),
        ),
      );
}

/// One-shot entrance: fades in while rising [offset] px. Pass [index] to
/// stagger siblings (capped, so long lists never wait).
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 12});

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  // The stagger delay is folded into the curve (Interval), so there are no
  // timers: one ticker-driven controller per item, started on first build.
  static const _stepMs = 40;
  late final int _delayMs = _stepMs * widget.index.clamp(0, 6);
  late final _c = AnimationController(vsync: this, duration: AppMotion.slow + Duration(milliseconds: _delayMs));
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Interval(_delayMs / (_c.duration!.inMilliseconds), 1, curve: AppMotion.curve),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 1;
    } else if (_c.isDismissed) {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _t,
        child: AnimatedBuilder(
          animation: _t,
          child: widget.child,
          builder: (context, child) =>
              Transform.translate(offset: Offset(0, (1 - _t.value) * widget.offset), child: child),
        ),
      );
}

/// Loading placeholder that mirrors the final layout (perceived speed).
/// One controller pulses the whole group, so it costs a single layer.
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, required this.child});

  /// Build the shape with [SkeletonBox]es.
  final Widget child;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.value = 0.5;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
        label: MaterialLocalizations.of(context).refreshIndicatorSemanticLabel,
        child: ExcludeSemantics(
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.45, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
            child: widget.child,
          ),
        ),
      );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 14, this.radius = AppRadius.sm});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AppColors.canvasSunken, borderRadius: BorderRadius.circular(radius)),
      );
}
