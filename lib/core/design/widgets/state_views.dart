import 'package:flutter/material.dart';

import '../app_tokens.dart';
import '../motion/motion.dart';
import 'app_button.dart';

/// Empty list / no-data state (DESIGN.md › Components › empty-state).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => _StateView(
        icon: icon,
        iconColor: AppColors.primaryDeep,
        title: title,
        message: message,
        actionLabel: actionLabel,
        onAction: onAction,
      );
}

/// Error state with a plain-language cause and a retry action. Never pass
/// raw exception text as [message]; map it to user copy first.
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.title,
    this.message,
    this.retryLabel = 'Try again',
    this.onRetry,
  });

  final String title;
  final String? message;
  final String retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => _StateView(
        icon: Icons.error_outline_rounded,
        iconColor: AppColors.danger,
        title: title,
        message: message,
        actionLabel: onRetry == null ? null : retryLabel,
        onAction: onRetry,
      );
}

/// First-load placeholder. Without a [message] it shows skeleton rows in
/// the shape of a list (feels faster than a spinner); with one, a spinner
/// and the caption (for long operations the user should read about).
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 2.6)),
            const SizedBox(height: AppSpacing.lg),
            Text(message!, style: AppTypography.caption),
          ],
        ),
      );
    }
    return LayoutBuilder(builder: (context, constraints) {
      final rows = constraints.hasBoundedHeight ? (constraints.maxHeight / 72).floor().clamp(1, 8) : 4;
      return ClipRect(
        child: Skeleton(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  child: Row(children: [
                    const SkeletonBox(width: 40, height: 40, radius: 12),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        FractionallySizedBox(widthFactor: i.isEven ? 0.7 : 0.55, child: const SkeletonBox(height: 14)),
                        const SizedBox(height: AppSpacing.sm),
                        FractionallySizedBox(widthFactor: i.isEven ? 0.4 : 0.5, child: const SkeletonBox(height: 11)),
                      ]),
                    ),
                  ]),
                ),
            ],
          ),
        ),
      );
    });
  }
}

class _StateView extends StatelessWidget {
  const _StateView({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeSlideIn(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [
                      iconColor.withValues(alpha: 0.14),
                      iconColor.withValues(alpha: 0.04),
                    ]),
                  ),
                  child: Icon(icon, size: 40, color: iconColor),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, style: AppTypography.title, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  message!,
                  style: AppTypography.body.copyWith(color: AppColors.inkMute),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                AppButton.secondary(label: actionLabel!, onPressed: onAction),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
