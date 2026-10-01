import 'package:flutter/material.dart';

import '../app_tokens.dart';

enum StatusTone { neutral, info, success, warning, danger, brand }

/// Status pill per DESIGN.md › Status chips: colour + text + icon, never
/// colour alone.
///
/// [StatusChip.fromDomain] is the ONLY place that maps domain status strings
/// to colours. Do not hand-pick tones for statuses elsewhere.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
    this.icon,
    this.dense = false,
  });

  /// Maps a domain status (`approved`, `pending`, `in_progress`…) to a chip.
  /// [label] overrides the displayed (localised) text.
  factory StatusChip.fromDomain(String status, {String? label, Key? key}) {
    final normalized = status.trim().toLowerCase().replaceAll(' ', '_');
    final tone = toneFor(normalized);
    return StatusChip(
      key: key,
      label: label ?? _humanize(normalized),
      tone: tone,
      icon: _iconFor(tone),
    );
  }

  final String label;
  final StatusTone tone;
  final IconData? icon;
  final bool dense;

  static const _toneByStatus = <String, StatusTone>{
    'draft': StatusTone.brand,
    'submitted': StatusTone.warning,
    'pending': StatusTone.warning,
    'awaiting_approval': StatusTone.warning,
    'expiring': StatusTone.warning,
    'low_stock': StatusTone.warning,
    'pending_sync': StatusTone.info,
    'approved': StatusTone.success,
    'present': StatusTone.success,
    'paid': StatusTone.success,
    'passed': StatusTone.success,
    'released': StatusTone.success,
    'completed': StatusTone.success,
    'active': StatusTone.success,
    'awarded': StatusTone.success,
    'held': StatusTone.info,
    'rejected': StatusTone.danger,
    'absent': StatusTone.danger,
    'forfeited': StatusTone.danger,
    'cancelled': StatusTone.danger,
    'overdue': StatusTone.danger,
    'lost': StatusTone.danger,
    'suspended': StatusTone.danger,
    'exited': StatusTone.neutral,
    'sync_failed': StatusTone.danger,
    'in_progress': StatusTone.info,
    'syncing': StatusTone.info,
    'opened': StatusTone.info,
    'leave': StatusTone.neutral,
    'holiday': StatusTone.neutral,
    'half_day': StatusTone.neutral,
  };

  static StatusTone toneFor(String status) =>
      _toneByStatus[status] ?? StatusTone.neutral;

  static (Color fg, Color bg) colorsFor(StatusTone tone) => switch (tone) {
        StatusTone.success => (AppColors.success, AppColors.successBg),
        StatusTone.warning => (AppColors.warning, AppColors.warningBg),
        StatusTone.danger => (AppColors.danger, AppColors.dangerBg),
        StatusTone.info => (AppColors.info, AppColors.infoBg),
        StatusTone.brand => (AppColors.primaryInk, AppColors.primarySoft),
        StatusTone.neutral => (AppColors.inkSecondary, AppColors.canvasSunken),
      };

  static IconData _iconFor(StatusTone tone) => switch (tone) {
        StatusTone.success => Icons.check_circle_rounded,
        StatusTone.warning => Icons.schedule_rounded,
        StatusTone.danger => Icons.cancel_rounded,
        StatusTone.info => Icons.info_rounded,
        StatusTone.brand => Icons.edit_rounded,
        StatusTone.neutral => Icons.circle_outlined,
      };

  static String _humanize(String s) {
    final words = s.split('_').where((w) => w.isNotEmpty);
    final text = words.join(' ');
    return text.isEmpty ? s : text[0].toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = colorsFor(tone);
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(color: fg);
    return Semantics(
      label: 'Status: $label',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? AppSpacing.sm : AppSpacing.sm + 2,
          vertical: dense ? 2 : AppSpacing.xs,
        ),
        decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizes.iconSm, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(label, style: style, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
