import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/design.dart';
import '../../../core/format/ist.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/application/session_controller.dart';
import '../data/attendance_repository.dart';
import '../../../core/ui/sheets.dart';

/// Holiday calendar. COO/Director maintain state-wide holidays; managers
/// can add holidays for their own section (RLS enforces both).
class HolidaysPage extends ConsumerStatefulWidget {
  const HolidaysPage({super.key});

  @override
  ConsumerState<HolidaysPage> createState() => _HolidaysPageState();
}

class _HolidaysPageState extends ConsumerState<HolidaysPage> {
  int _year = Ist.today().year;

  Future<void> _add() async {
    final l10n = context.l10n;
    final me = ref.read(currentUserProvider)!;
    final name = TextEditingController();
    DateTime date = DateTime(_year, Ist.today().month, Ist.today().day);
    final formKey = GlobalKey<FormState>();
    final saved = await showAppSheet<bool>(
      context,
      builder: (context) => DisposeWith(
        controllers: [name],
        child: StatefulBuilder(
        builder: (context, setLocal) => Form(
          key: formKey,
          child: SheetScaffold(
            title: l10n.holidaysAdd,
            primaryLabel: l10n.commonSave,
            onPrimary: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(context, true);
            },
            secondaryLabel: l10n.commonCancel,
            onSecondary: () => Navigator.pop(context, false),
            children: [
              AppTextField(label: l10n.holidaysName, controller: name, required: true),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: ValueKey(date),
                label: l10n.holidaysDate,
                initialValue: MaterialLocalizations.of(context).formatMediumDate(date),
                readOnly: true,
                suffix: const Icon(Icons.calendar_today_rounded),
                onTap: () async {
                  final d = await showDatePicker(
                      context: context, initialDate: date, firstDate: DateTime(_year), lastDate: DateTime(_year, 12, 31));
                  if (d != null) setLocal(() => date = d);
                },
              ),
            ],
          ),
        ),
      ),
      ),
    );
    final holidayName = name.text; // read now: the sheet disposes `name` once it is gone
    if (saved == true) {
      try {
        await ref.read(attendanceRepositoryProvider).addHoliday(
              date,
              holidayName,
              sectionId: me.role.isExecutive ? null : me.sectionId,
            );
        ref.invalidate(holidaysProvider(_year));
      } catch (e) {
        if (mounted) showSnack(context, failureMessage(l10n, e));
      }
    }
  }

  Future<void> _delete(Holiday h) async {
    final l10n = context.l10n;
    if (!await confirmAction(context,
        message: l10n.holidaysDeleteConfirm(h.name), confirmLabel: l10n.commonDelete, destructive: true)) {
      return;
    }
    try {
      await ref.read(attendanceRepositoryProvider).deleteHoliday(h.id);
      ref.invalidate(holidaysProvider(_year));
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final holidays = ref.watch(holidaysProvider(_year));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.holidaysTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.holidaysAdd),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(holidaysProvider(_year).future),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
          children: [
            _YearSwitcher(
              year: _year,
              onPrev: () => setState(() => _year--),
              onNext: () => setState(() => _year++),
            ),
            const SizedBox(height: AppSpacing.lg),
            switch (holidays) {
              AsyncData(:final value) when value.isEmpty => Column(children: [
                  const SizedBox(height: AppSpacing.xxl),
                  EmptyState(icon: Icons.event_busy_rounded, title: l10n.holidaysEmpty(_year)),
                  NoteBanner(text: l10n.holidaysNote, icon: Icons.lightbulb_outline_rounded),
                ]),
              AsyncData(:final value) => _list(context, me.role.isExecutive, value),
              AsyncError(:final error) => ErrorState(
                  title: l10n.commonSomethingWrong,
                  message: failureMessage(l10n, error),
                  onRetry: () => ref.invalidate(holidaysProvider(_year)),
                ),
              _ => const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: LoadingView()),
            },
          ],
        ),
      ),
    );
  }

  Widget _list(BuildContext context, bool executive, List<Holiday> all) {
    final l10n = context.l10n;
    final today = Ist.today();
    final sorted = [...all]..sort((a, b) => a.date.compareTo(b.date));
    final next = sorted.where((h) => !h.date.isBefore(today)).firstOrNull;
    final upcoming = sorted.where((h) => !h.date.isBefore(today)).length;
    final byMonth = <int, List<Holiday>>{};
    for (final h in sorted) {
      byMonth.putIfAbsent(h.date.month, () => []).add(h);
    }
    final locale = Localizations.localeOf(context).toString();

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (next != null) FadeSlideIn(child: _NextHoliday(holiday: next, today: today)),
      const SizedBox(height: AppSpacing.md),
      StatStrip(items: [
        StatItem(label: l10n.holidaysCountTotal, value: '${sorted.length}'),
        StatItem(label: l10n.holidaysCountUpcoming, value: '$upcoming', color: AppColors.primaryDeep),
        StatItem(label: l10n.holidaysCountSection, value: '${sorted.where((h) => h.sectionId != null).length}'),
      ]),
      for (final (i, entry) in byMonth.entries.indexed)
        FadeSlideIn(
          index: i + 1,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.sm),
              child: Text(
                DateFormat.MMMM(locale).format(DateTime(_year, entry.key)).toUpperCase(),
                style: AppTypography.overline,
              ),
            ),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final (j, h) in entry.value.indexed)
                  Opacity(
                    opacity: h.date.isBefore(today) ? 0.55 : 1,
                    child: AppListRow(
                      leading: DateBlock(h.date, color: AppColors.ruby, highlight: h == next),
                      title: h.name,
                      subtitle: [
                        DateFormat.EEEE(locale).format(h.date),
                        h.sectionId == null ? l10n.holidaysStateWide : l10n.holidaysSectionOnly,
                      ].join(' · '),
                      trailing: (executive || h.sectionId != null)
                          ? IconButton(
                              tooltip: l10n.commonDelete,
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.inkMute, size: 20),
                              onPressed: () => _delete(h),
                            )
                          : null,
                      showDivider: j < entry.value.length - 1,
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      const SizedBox(height: AppSpacing.lg),
      NoteBanner(text: l10n.holidaysNote, icon: Icons.lightbulb_outline_rounded),
    ]);
  }
}

class _YearSwitcher extends StatelessWidget {
  const _YearSwitcher({required this.year, required this.onPrev, required this.onNext});

  final int year;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xxs),
        child: Row(children: [
          IconButton(
            tooltip: '${year - 1}',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrev,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: AppMotion.fast,
              child: Text(
                '$year',
                key: ValueKey(year),
                textAlign: TextAlign.center,
                style: AppTypography.subtitle.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ),
          ),
          IconButton(
            tooltip: '${year + 1}',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
          ),
        ]),
      );
}

/// The next holiday as a brand hero card ("in 5 days").
class _NextHoliday extends StatelessWidget {
  const _NextHoliday({required this.holiday, required this.today});

  final Holiday holiday;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final days = holiday.date.difference(today).inDays;
    final locale = Localizations.localeOf(context).toString();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lgAll,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brandDark, AppColors.primaryDeep],
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.holidaysNext.toUpperCase(),
                style: AppTypography.overline.copyWith(color: Colors.white.withValues(alpha: 0.7))),
            const SizedBox(height: AppSpacing.sm),
            Text(holiday.name, style: AppTypography.title.copyWith(color: Colors.white)),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              DateFormat.yMMMMEEEEd(locale).format(holiday.date),
              style: AppTypography.caption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ]),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: days == 0 ? AppColors.brandOrange : Colors.white.withValues(alpha: 0.14),
            borderRadius: AppRadius.mdAll,
          ),
          child: Text(
            days == 0 ? l10n.holidaysToday : l10n.holidaysInDays(days),
            style: AppTypography.label.copyWith(color: Colors.white),
          ),
        ),
      ]),
    );
  }
}
