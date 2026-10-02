import 'package:flutter/material.dart';

import '../app_tokens.dart';
import '../../responsive/responsive.dart';
import '../motion/motion.dart';

/// White card with a hairline border (DESIGN.md › Cards). Tappable when
/// [onTap] is given, with press-scale feedback.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color = AppColors.canvas,
    this.elevated = false,
    this.borderColor = AppColors.hairline,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;

  /// Level-1 shadow; use when the card floats over a mesh or tinted band.
  final bool elevated;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.lgAll,
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: elevated ? AppShadows.level2 : AppShadows.none,
      ),
      child: Padding(padding: padding, child: child),
    );
    if (onTap == null) return card;
    return Pressable(onTap: onTap, borderRadius: AppRadius.lgAll, child: card);
  }
}

/// Rounded, tinted square holding an icon: the leading visual for list rows,
/// quick actions and KPI tiles (Notion / Groww style).
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.color = AppColors.primaryDeep, this.background, this.size = 40});

  final IconData icon;
  final Color color;
  final Color? background;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: background ?? color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: Icon(icon, color: color, size: size * 0.52),
      );
}

/// KPI tile: tinted icon, caption label and a large thin tabular value.
class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trailing,
    this.onTap,
    this.featured = false,
    this.tint = AppColors.primaryDeep,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Inverse brand-dark surface. At most one per dashboard.
  final bool featured;

  /// Accent for the icon tile (semantic colours for alerts).
  final Color tint;

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
        borderColor: featured ? null : AppColors.hairline,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null)
                  IconTile(
                    icon!,
                    size: 32,
                    color: featured ? AppColors.onDark : tint,
                    background: featured ? const Color(0x26FFFFFF) : null,
                  ),
                const Spacer(),
                if (onTap != null) Icon(Icons.arrow_outward_rounded, size: AppSizes.iconSm, color: muted),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: AppTypography.kpi.copyWith(color: fg)),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.caption.copyWith(color: muted),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Round quick-action shortcut: icon tile over a short label (Groww's
/// "Explore" row). Use 4 per row on phones.
class QuickAction extends StatelessWidget {
  const QuickAction({super.key, required this.icon, required this.label, required this.onTap, this.tint = AppColors.primaryDeep});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color tint;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: Pressable(
          onTap: onTap,
          scale: 0.93,
          borderRadius: AppRadius.mdAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTile(icon, size: 52, color: tint),
                const SizedBox(height: AppSpacing.sm),
                // Never breaks inside a word ("New wor / ksheet") on narrow tiles.
                FitLabel(
                  label,
                  style: AppTypography.label.copyWith(fontSize: 12.5, color: AppColors.inkSecondary),
                ),
              ],
            ),
          ),
        ),
      );
}
