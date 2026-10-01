import 'package:flutter/material.dart';

import '../app_tokens.dart';
import 'app_card.dart';

/// One label/value line in an [InfoGroup]. Rows with a null/blank [value]
/// (and no [child]) are skipped, so callers can pass optional facts freely.
class InfoRow {
  const InfoRow(this.label, this.value, {this.icon, this.child, this.onTap, this.tabular = false});

  final String label;
  final String? value;
  final IconData? icon;

  /// Custom value widget (e.g. a status chip) instead of [value].
  final Widget? child;
  final VoidCallback? onTap;

  /// Numbers, money, codes: tabular figures so columns line up.
  final bool tabular;

  bool get isEmpty => child == null && (value == null || value!.trim().isEmpty);
}

/// A titled card of facts for detail pages (Groww's "Order details" block).
/// Short values sit on the right of their label; long ones stack below it.
class InfoGroup extends StatelessWidget {
  const InfoGroup({super.key, this.title, required this.rows, this.trailing});

  final String? title;
  final List<InfoRow> rows;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final visible = rows.where((r) => !r.isEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (title != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.sm),
          child: Row(children: [
            Expanded(child: Semantics(header: true, child: Text(title!, style: AppTypography.subtitle))),
            ?trailing,
          ]),
        ),
      AppCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          for (final (i, r) in visible.indexed) _InfoLine(row: r, divider: i < visible.length - 1),
        ]),
      ),
    ]);
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.row, required this.divider});

  final InfoRow row;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final r = row;
    final valueStyle = (r.tabular ? AppTypography.bodyTabular : AppTypography.bodyStrong)
        .copyWith(fontWeight: FontWeight.w600);
    final stacked = r.child == null && (r.value!.length > 28 || r.value!.contains('\n'));
    final label = Text(r.label, style: AppTypography.caption.copyWith(color: AppColors.inkMute));
    final value = r.child ??
        Text(r.value!, style: valueStyle, textAlign: stacked ? TextAlign.start : TextAlign.end);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md + 2),
      child: Row(crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
        if (r.icon != null) ...[
          Icon(r.icon, size: AppSizes.iconMd, color: AppColors.inkMute),
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: stacked
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  label,
                  const SizedBox(height: AppSpacing.xs),
                  value,
                ])
              : Row(children: [
                  Expanded(flex: 4, child: label),
                  const SizedBox(width: AppSpacing.md),
                  Flexible(flex: 6, child: Align(alignment: Alignment.centerRight, child: value)),
                ]),
        ),
        if (r.onTap != null) ...[
          const SizedBox(width: AppSpacing.xs),
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkDisabled, size: 20),
        ],
      ]),
    );
    return Semantics(
      label: '${r.label}: ${r.value ?? ''}',
      button: r.onTap != null,
      child: InkWell(
        onTap: r.onTap,
        child: DecoratedBox(
          decoration: divider
              ? const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEAEEF3))))
              : const BoxDecoration(),
          child: content,
        ),
      ),
    );
  }
}

/// Identity block at the top of a detail page: icon, title, code line and
/// status, on white (Groww's stock header).
class DetailHeader extends StatelessWidget {
  const DetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor = AppColors.primaryDeep,
    this.leading,
    this.status,
    this.below,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;

  /// Overrides [icon] (e.g. an Avatar).
  final Widget? leading;
  final Widget? status;

  /// Extra content under the title (chips, a stat strip…).
  final Widget? below;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (leading != null || icon != null) ...[
            leading ?? IconTile(icon!, color: iconColor, size: 52),
            const SizedBox(width: AppSpacing.lg),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: AppTypography.title.copyWith(fontSize: 21)),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle!, style: AppTypography.caption),
              ],
              if (status != null) ...[
                const SizedBox(height: AppSpacing.sm),
                status!,
              ],
            ]),
          ),
        ]),
        if (below != null) ...[
          const SizedBox(height: AppSpacing.lg),
          below!,
        ],
      ]);
}

/// Primary actions pinned to the bottom of a detail page, above the
/// keyboard and system bar, so the next step is always one tap away.
class StickyActionBar extends StatelessWidget {
  const StickyActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          border: Border(top: BorderSide(color: AppColors.hairline)),
          boxShadow: [BoxShadow(color: Color(0x0F0D253D), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              for (final (i, c) in children.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.sm),
                c,
              ],
            ]),
          ),
        ),
      );
}

/// A tinted callout for decisions, warnings and notes on detail pages.
class NoteBanner extends StatelessWidget {
  const NoteBanner({super.key, required this.text, this.icon = Icons.info_rounded, this.tone = AppColors.info});

  final String text;
  final IconData icon;
  final Color tone;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: tone.withValues(alpha: 0.08),
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: tone.withValues(alpha: 0.2)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: AppSizes.iconMd, color: tone),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: AppTypography.label.copyWith(color: AppColors.inkSecondary))),
        ]),
      );
}
