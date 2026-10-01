import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_tokens.dart';

/// One figure in a [StatStrip].
class StatItem {
  const StatItem({required this.label, required this.value, this.color, this.onTap});

  final String label;
  final String value;
  final Color? color;
  final VoidCallback? onTap;
}

/// A row of headline numbers in one card, split by hairlines (Groww's
/// "Invested · Current · Returns" pattern). Numbers are tabular and thin;
/// labels wrap to two lines rather than truncate (Malayalam is longer).
class StatStrip extends StatelessWidget {
  const StatStrip({super.key, required this.items});

  final List<StatItem> items;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: AppRadius.lgAll,
          border: Border.all(color: AppColors.hairline),
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            for (final (i, item) in items.indexed) ...[
              if (i > 0) const VerticalDivider(width: 1, indent: 14, endIndent: 14),
              Expanded(
                child: Semantics(
                  label: '${item.label}: ${item.value}',
                  excludeSemantics: true,
                  button: item.onTap != null,
                  child: InkWell(
                    onTap: item.onTap,
                    borderRadius: AppRadius.lgAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.lg),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(item.value,
                              style: AppTypography.kpi.copyWith(fontSize: 26, color: item.color ?? AppColors.ink)),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(item.label, style: AppTypography.caption, maxLines: 2),
                      ]),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ),
      );
}

/// Calendar-tile leading visual: big day number over a short weekday.
class DateBlock extends StatelessWidget {
  const DateBlock(this.date, {super.key, this.highlight = false, this.color});

  final DateTime date;
  final bool highlight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Locale-aware short weekday ("Thu", "വ്യാ"); date symbols are loaded by
    // GlobalMaterialLocalizations for every supported locale.
    final weekday = DateFormat.E(Localizations.localeOf(context).toString()).format(date);
    final tint = color ?? (highlight ? AppColors.primaryDeep : AppColors.inkSecondary);
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primarySoft : AppColors.canvasSoft,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: highlight ? AppColors.primary.withValues(alpha: 0.25) : AppColors.hairline),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('${date.day}',
            style: AppTypography.title.copyWith(fontSize: 18, height: 1.1, color: tint,
                fontFeatures: const [FontFeature.tabularFigures()])),
        Text(weekday,
            style: AppTypography.overline.copyWith(fontSize: 10, color: tint, letterSpacing: 0.2),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false),
      ]),
    );
  }
}
