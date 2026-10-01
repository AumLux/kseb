import 'package:flutter/material.dart';

import '../app_tokens.dart';

/// White card with hairline border (DESIGN.md › Cards). Tappable when
/// [onTap] is given.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color = AppColors.canvas,
    this.elevated = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;

  /// Level-1 shadow; use when the card sits on canvas-soft and needs lift.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.hairline),
        boxShadow: elevated ? AppShadows.level1 : AppShadows.none,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// KPI tile: caption label + large tabular value + optional trailing widget
/// (e.g. a delta [StatusChip]).
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trailing,
    this.onTap,
    this.featured = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Inverse brand-dark surface. At most one per dashboard.
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final fg = featured ? AppColors.onDark : AppColors.ink;
    final muted = featured ? const Color(0xFFC9CCF0) : AppColors.inkMute;
    return Semantics(
      label: '$label: $value',
      excludeSemantics: true,
      button: onTap != null,
      child: AppCard(
        onTap: onTap,
        color: featured ? AppColors.brandDark : AppColors.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSizes.iconMd, color: muted),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.caption.copyWith(color: muted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value,
                        style: AppTypography.kpi.copyWith(color: fg)),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ],
        ),
      ),
    );
  }
}
