import 'package:flutter/material.dart';

import '../app_tokens.dart';
import '../motion/motion.dart';

enum AppButtonVariant { primary, secondary, tertiary, danger }

/// Pill button per DESIGN.md › Buttons.
///
/// Use at most one [AppButtonVariant.primary] per screen. While [loading] the
/// button keeps its width, shows a spinner and ignores taps, which prevents
/// double submits.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.tertiary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.tertiary;

  const AppButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
  }) : variant = AppButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;

  /// Stretch to the available width (default for primary actions on phones).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    // While loading the button keeps its enabled colours (so the spinner is
    // visible) but swallows taps, which still prevents double submits.
    final effectiveOnPressed = loading ? (onPressed == null ? null : _ignore) : onPressed;
    final spinnerColor = switch (variant) {
      AppButtonVariant.primary => AppColors.onPrimary,
      AppButtonVariant.danger => AppColors.onDark,
      _ => AppColors.ink,
    };

    final Widget content = loading
        ? SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: spinnerColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: AppSizes.iconMd),
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: Text(label, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
    final child = AnimatedSwitcher(
      duration: AppMotion.fast,
      child: KeyedSubtree(key: ValueKey(loading), child: content),
    );

    final Widget button = switch (variant) {
      AppButtonVariant.primary =>
        FilledButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.secondary =>
        OutlinedButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.tertiary =>
        TextButton(onPressed: effectiveOnPressed, child: child),
      AppButtonVariant.danger => FilledButton(
          onPressed: effectiveOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.onDark,
            minimumSize: const Size(64, AppSizes.primaryActionHeight),
          ),
          child: child,
        ),
    };

    final animated = PressScale(
      enabled: !loading && onPressed != null,
      scale: variant == AppButtonVariant.tertiary ? 0.95 : 0.97,
      child: button,
    );

    return Semantics(
      button: true,
      enabled: !loading && onPressed != null,
      label: loading ? '$label, in progress' : null,
      excludeSemantics: loading,
      child: expand ? SizedBox(width: double.infinity, child: animated) : animated,
    );
  }
}

void _ignore() {}
