import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/format/formatters.dart';
import '../../../core/format/ist.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/location/location_rationale.dart';
import '../../../core/location/location_service.dart';
import '../../../core/ui/dialogs.dart';
import '../application/capture_controller.dart';
import '../data/attendance_repository.dart';
import 'attendance_labels.dart';

/// The crew-facing attendance screen: one big action, today's status,
/// this month at a glance.
class MyAttendanceView extends ConsumerStatefulWidget {
  const MyAttendanceView({super.key});

  @override
  ConsumerState<MyAttendanceView> createState() => _MyAttendanceViewState();
}

class _MyAttendanceViewState extends ConsumerState<MyAttendanceView> {
  DateTime _month = Ist.monthStart(Ist.today());
  bool _busy = false;
  bool _locating = false;

  Future<void> _capture(CaptureKind kind) async {
    final l10n = context.l10n;
    if (!await explainLocationIfNeeded(context, ref) || !mounted) return;
    setState(() {
      _busy = true;
      _locating = true;
    });
    CapturedLocation? location;
    var proceed = true;
    try {
      location = await ref.read(locationServiceProvider).current();
    } on AppFailure catch (f) {
      // Don't spin behind the question.
      if (mounted) setState(() => _busy = _locating = false);
      proceed = mounted && await _askWithoutLocation(f);
    }
    if (!mounted) return;
    if (!proceed) {
      setState(() => _busy = _locating = false);
      return;
    }
    setState(() {
      _busy = true;
      _locating = false;
    });
    try {
      final result = await ref.read(captureControllerProvider).capture(kind, location: location);
      if (!mounted) return;
      switch (result.outcome) {
        case CaptureOutcome.synced:
          showSnack(context, l10n.attSynced);
        case CaptureOutcome.queued:
          showSnack(context, l10n.attQueued);
        case CaptureOutcome.rejected:
          await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              content: Text(result.message ?? l10n.commonSomethingWrong),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonClose)),
              ],
            ),
          );
      }
      ref.invalidate(myMonthProvider(_month));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _askWithoutLocation(AppFailure f) async {
    final l10n = context.l10n;
    final canOpenSettings = f.code == 'location_denied_forever' || f.code == 'location_off';
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.attNoLocationTitle),
        content: Text('${f.message}\n\n${l10n.attNoLocationNote}'),
        actions: [
          if (canOpenSettings)
            TextButton(onPressed: () => Navigator.pop(context, 'settings'), child: Text(l10n.attOpenSettings)),
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, 'continue'),
            child: Text(l10n.attNoLocationContinue),
          ),
        ],
      ),
    );
    if (choice == 'settings') await openLocationSettings();
    return choice == 'continue';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = ref.watch(myTodayProvider);
    final pending = ref.watch(pendingCapturesProvider);
    final month = ref.watch(myMonthProvider(_month));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myTodayProvider);
        ref.invalidate(myMonthProvider(_month));
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _TodayCard(
            day: today.value,
            pending: pending,
            loading: today.isLoading && !today.hasValue,
            busy: _busy,
            locating: _locating,
            onCapture: _capture,
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppListRow(
              leading: const Icon(Icons.beach_access_rounded, color: AppColors.inkMute),
              title: l10n.leaveMine,
              showDivider: false,
              onTap: () => context.push('/attendance/leave'),
            ),
          ),
          SectionHeader(
            l10n.attThisMonth,
            action: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1)),
              ),
              Text(_monthLabel(context, _month), style: AppTypography.label),
              IconButton(
                tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _month.isBefore(Ist.monthStart(Ist.today()))
                    ? () => setState(() => _month = DateTime(_month.year, _month.month + 1))
                    : null,
              ),
            ]),
          ),
          switch (month) {
            AsyncData(:final value) => _MonthBody(days: value),
            AsyncError(:final error) => ErrorState(
                title: l10n.commonSomethingWrong,
                message: failureMessage(l10n, error),
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(myMonthProvider(_month)),
              ),
            _ => const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: LoadingView()),
          },
        ],
      ),
    );
  }
}

String _monthLabel(BuildContext context, DateTime month) =>
    MaterialLocalizations.of(context).formatMonthYear(month);

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.day,
    required this.pending,
    required this.loading,
    required this.busy,
    required this.locating,
    required this.onCapture,
  });

  final AttendanceDay? day;
  final List<PendingCapture> pending;
  final bool loading;
  final bool busy;
  final bool locating;
  final ValueChanged<CaptureKind> onCapture;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    DateTime? pendingAt(CaptureKind k) => pending.where((p) => p.kind == k).lastOrNull?.capturedAt;
    final checkIn = day?.checkInAt ?? pendingAt(CaptureKind.checkIn);
    final checkOut = day?.checkOutAt ?? pendingAt(CaptureKind.checkOut);
    final hasPending = pending.isNotEmpty;
    final onLeave = day?.status == AttendanceStatus.leave;

    final (label, kind) = switch ((checkIn, checkOut)) {
      (null, _) => (l10n.attCheckIn, CaptureKind.checkIn),
      (_, null) => (l10n.attCheckOut, CaptureKind.checkOut),
      _ => (l10n.attDoneForDay, null),
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  MaterialLocalizations.of(context).formatFullDate(Ist.today()),
                  style: AppTypography.subtitle,
                ),
              ),
              if (hasPending)
                StatusChip.fromDomain('pending_sync', label: l10n.attPendingSync)
              else if (day != null)
                attendanceChip(l10n, day!.status),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(child: _Stamp(label: l10n.attCheckedIn, time: checkIn)),
              Expanded(child: _Stamp(label: l10n.attCheckedOut, time: checkOut)),
            ],
          ),
          if (checkIn != null && checkOut != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(l10n.attWorked(Fmt.duration(checkOut.difference(checkIn))), style: AppTypography.caption),
          ],
          if (day != null && attendanceFlags(l10n, day!).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: attendanceFlags(l10n, day!)),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (locating)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(l10n.attLocating, textAlign: TextAlign.center, style: AppTypography.caption),
            ),
          AppButton(
            label: label,
            icon: kind == CaptureKind.checkOut ? Icons.logout_rounded : Icons.login_rounded,
            expand: true,
            loading: busy,
            onPressed: (loading || kind == null || onLeave) ? null : () => onCapture(kind),
          ),
        ],
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label, required this.time});

  final String label;
  final DateTime? time;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: AppSpacing.xxs),
          Text(time == null ? '—' : Fmt.time(time), style: AppTypography.kpi.copyWith(fontSize: 24)),
        ],
      );
}

class _MonthBody extends StatelessWidget {
  const _MonthBody({required this.days});

  final List<AttendanceDay> days;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final present = days.where((d) => d.status == AttendanceStatus.present).length +
        days.where((d) => d.status == AttendanceStatus.halfDay).length * 0.5;
    final leave = days.where((d) => d.status == AttendanceStatus.leave).length;
    final worked = days.fold<Duration>(Duration.zero, (sum, d) => sum + (d.worked ?? Duration.zero));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(child: KpiCard(label: l10n.attDaysPresent, value: Fmt.qty(present))),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: KpiCard(label: l10n.attHoursWorked, value: Fmt.qty(worked.inHours))),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: KpiCard(label: l10n.attLeaveDays, value: Fmt.qty(leave))),
        ]),
        SectionHeader(l10n.attHistory),
        if (days.isEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Text(l10n.attNoRecords, textAlign: TextAlign.center, style: AppTypography.caption),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, d) in days.reversed.indexed)
                  AppListRow(
                    title: MaterialLocalizations.of(context).formatMediumDate(d.workDate),
                    subtitle: d.checkInAt == null
                        ? null
                        : '${Fmt.time(d.checkInAt)} – ${d.checkOutAt == null ? '…' : Fmt.time(d.checkOutAt)}'
                            '${d.worked == null ? '' : ' · ${Fmt.duration(d.worked)}'}',
                    trailing: attendanceChip(l10n, d.status),
                    showDivider: i < days.length - 1,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
