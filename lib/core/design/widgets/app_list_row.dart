import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_tokens.dart';

/// Operational list row (DESIGN.md › Lists): 56dp min, strong primary line,
/// muted secondary line, trailing status chip or tabular value.
class AppListRow extends StatelessWidget {
  const AppListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.showDivider = true,
    this.selected = false,
    this.dividerIndent,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;
  final bool selected;

  /// Where the divider starts. Defaults to the text column (after a ~40dp
  /// leading visual), so rows read as one group, Groww/iOS style.
  final double? dividerIndent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : AppColors.canvas,
      child: InkWell(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        highlightColor: AppColors.ink.withValues(alpha: 0.04),
        splashColor: AppColors.primary.withValues(alpha: 0.06),
        child: CustomPaint(
          foregroundPainter: showDivider
              ? _InsetDivider(dividerIndent ?? (leading != null ? AppSpacing.lg + 40 + AppSpacing.md : AppSpacing.lg))
              : null,
          child: Container(
          constraints:
              const BoxConstraints(minHeight: AppSizes.listRowMinHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyStrong,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: AppTypography.caption,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.md),
                trailing!,
              ] else if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.inkDisabled),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _InsetDivider extends CustomPainter {
  const _InsetDivider(this.indent);

  final double indent;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawLine(
        Offset(indent, size.height - 0.5),
        Offset(size.width, size.height - 0.5),
        Paint()
          ..color = const Color(0xFFEAEEF3)
          ..strokeWidth = 1,
      );

  @override
  bool shouldRepaint(_InsetDivider old) => old.indent != indent;
}

/// Group label above a list or form section.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.sm, AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: AppTypography.subtitle),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
