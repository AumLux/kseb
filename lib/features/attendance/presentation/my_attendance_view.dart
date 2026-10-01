import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/design/design.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/format/formatters.dart';
import '../../../core/format/ist.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/location/location_rationale.dart';
import '../../../core/location/location_service.dart';
import '../../../core/ui/dialogs.dart';
import '../../../core/ui/sheets.dart';
import '../../auth/application/session_controller.dart';
import '../../org/data/org_repository.dart';
import '../application/capture_controller.dart';
import '../data/attendance_repository.dart';
import 'attendance_labels.dart';
import 'attendance_location.dart';

/// The crew-facing attendance screen: one big action, today's status and
/// where it was recorded, this month at a glance.
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
          await showAppSheet<void>(
            context,
            builder: (context) => SheetScaffold(
              title: l10n.commonSomethingWrong,
              primaryLabel: l10n.commonClose,
              onPrimary: () => Navigator.pop(context),
              children: [Text(result.message ?? l10n.commonSomethingWrong, style: AppTypography.body)],
            ),
          );
      }
      ref
        ..invalidate(myTodayProvider)
        ..invalidate(myMonthProvider(_month));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _askWithoutLocation(AppFailure f) async {
    final l10n = context.l10n;
    final canOpenSettings = f.code == 'location_denied_forever' || f.code == 'location_off';
    final choice = await showAppSheet<String>(
      context,
      builder: (context) => SheetScaffold(
        title: l10n.attNoLocationTitle,
        primaryLabel: l10n.attNoLocationContinue,
        onPrimary: () => Navigator.pop(context, 'continue'),
        secondaryLabel: canOpenSettings ? l10n.attOpenSettings : l10n.commonCancel,
        onSecondary: () => Navigator.pop(context, canOpenSettings ? 'settings' : null),
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const IconTile(Icons.location_off_rounded, color: AppColors.warning),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(f.message, style: AppTypography.body)),
          ]),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.attNoLocationNote, style: AppTypography.caption),
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
    final me = ref.watch(currentUserProvider);
    final fence = sectionFence(ref.watch(orgTreeProvider).value, me?.sectionId);

    return RefreshIndicator(
      onRefresh: () async {
        ref
          ..invalidate(myTodayProvider)
          ..invalidate(myMonthProvider(_month));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: [
          FadeSlideIn(
            child: _TodayCard(
              day: today.value,
              fence: fence,
              pending: pending,
              loading: today.isLoading && !today.hasValue,
              busy: _busy,
              locating: _locating,
              onCapture: _capture,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          FadeSlideIn(
            index: 1,
            child: AppCard(
              padding: EdgeInsets.zero,
              child: AppListRow(
                leading: const IconTile(Icons.beach_access_rounded, color: AppColors.info),
                title: l10n.leaveMine,
                showDivider: false,
                onTap: () => context.push('/attendance/leave'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            Expanded(child: Text(l10n.attThisMonth, style: AppTypography.subtitle)),
            _MonthSwitcher(
              month: _month,
              onChanged: (m) => setState(() => _month = m),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          switch (month) {
            AsyncData(:final value) => _MonthBody(days: value, fence: fence),
            AsyncError(:final error) => ErrorState(
                title: l10n.commonSomethingWrong,
                message: failureMessage(l10n, error),
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(myMonthProvider(_month)),
              ),
            _ => const SizedBox(height: 280, child: LoadingView()),
          },
        ],
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({required this.month, required this.onChanged});

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final canNext = month.isBefore(Ist.monthStart(Ist.today()));
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvasSoft,
        borderRadius: AppRadius.pillAll,
        border: Border.all(color: AppColors.hairline),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          tooltip: loc.previousMonthTooltip,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        ),
        Text(loc.formatMonthYear(month), style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
        IconButton(
          tooltip: loc.nextMonthTooltip,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: canNext ? () => onChanged(DateTime(month.year, month.month + 1)) : null,
        ),
      ]),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.day,
    required this.fence,
    required this.pending,
    required this.loading,
    required this.busy,
    required this.locating,
    required this.onCapture,
  });

  final AttendanceDay? day;
  final (LatLng, int)? fence;
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
    final onDuty = checkIn != null && checkOut == null;

    final (label, kind) = switch ((checkIn, checkOut)) {
      (null, _) => (l10n.attCheckIn, CaptureKind.checkIn),
      (_, null) => (l10n.attCheckOut, CaptureKind.checkOut),
      _ => (l10n.attDoneForDay, null),
    };

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg + 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l10n.homeTodayTitle.toUpperCase(), style: AppTypography.overline),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(MaterialLocalizations.of(context).formatFullDate(Ist.today()), style: AppTypography.subtitle),
                ]),
              ),
              if (hasPending)
                StatusChip.fromDomain('pending_sync', label: l10n.attPendingSync)
              else if (day != null)
                attendanceChip(l10n, day!.status),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          IntrinsicHeight(
            child: Row(children: [
              Expanded(
                child: _Stamp(icon: Icons.login_rounded, color: AppColors.success, label: l10n.attCheckedIn, time: checkIn),
              ),
              const VerticalDivider(width: AppSpacing.xl),
              Expanded(
                child: _Stamp(icon: Icons.logout_rounded, color: AppColors.primaryDeep, label: l10n.attCheckedOut, time: checkOut),
              ),
            ]),
          ),
          if (checkIn != null) ...[
            const SizedBox(height: AppSpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(
                label: onDuty
                    ? l10n.homeOnDuty(Fmt.duration(DateTime.now().difference(checkIn)))
                    : l10n.attWorked(Fmt.duration(checkOut!.difference(checkIn))),
                tone: onDuty ? StatusTone.success : StatusTone.neutral,
                icon: onDuty ? Icons.bolt_rounded : Icons.timelapse_rounded,
              ),
            ),
          ],
          if (day != null && day!.checkInLat != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AttendanceLocation(day: day!, fence: fence),
          ] else if (day != null && attendanceFlags(l10n, day!).isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: attendanceFlags(l10n, day!)),
          ],
          const SizedBox(height: AppSpacing.lg + 4),
          AnimatedSize(
            duration: AppMotion.base,
            child: locating
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.attLocating, style: AppTypography.caption),
                    ]),
                  )
                : const SizedBox(width: double.infinity),
          ),
          AppButton(
            label: label,
            icon: switch (kind) {
              CaptureKind.checkOut => Icons.logout_rounded,
              CaptureKind.checkIn => Icons.fingerprint_rounded,
              null => Icons.task_alt_rounded,
            },
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
  const _Stamp({required this.icon, required this.color, required this.label, required this.time});

  final IconData icon;
  final Color color;
  final String label;
  final DateTime? time;

  @override
  Widget build(BuildContext context) => Row(children: [
        IconTile(icon, color: color, size: 36),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(time == null ? '—' : Fmt.time(time), style: AppTypography.kpi.copyWith(fontSize: 24)),
            ),
          ]),
        ),
      ]);
}

class _MonthBody extends StatelessWidget {
  const _MonthBody({required this.days, required this.fence});

  final List<AttendanceDay> days;
  final (LatLng, int)? fence;

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
        StatStrip(items: [
          StatItem(label: l10n.attDaysPresent, value: Fmt.qty(present), color: AppColors.success),
          StatItem(label: l10n.attHoursWorked, value: Fmt.qty(worked.inHours)),
          StatItem(label: l10n.attLeaveDays, value: Fmt.qty(leave)),
        ]),
        const SizedBox(height: AppSpacing.xl),
        Text(l10n.attHistory, style: AppTypography.subtitle),
        const SizedBox(height: AppSpacing.md),
        if (days.isEmpty)
          SizedBox(height: 220, child: EmptyState(icon: Icons.event_note_rounded, title: l10n.attNoRecords))
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, d) in days.reversed.indexed)
                  AppListRow(
                    leading: DateBlock(d.workDate, highlight: Ist.iso(d.workDate) == Ist.iso(Ist.today())),
                    title: d.checkInAt == null
                        ? attendanceStatusLabel(l10n, d.status)
                        : '${Fmt.time(d.checkInAt)} – ${d.checkOutAt == null ? '…' : Fmt.time(d.checkOutAt)}',
                    subtitle: [
                      if (d.worked != null) Fmt.duration(d.worked),
                      if (d.checkInDistanceM != null) l10n.attDistanceFromSection(d.checkInDistanceM!),
                    ].join(' · ').nullIfEmpty,
                    trailing: attendanceChip(l10n, d.status, dense: true),
                    showDivider: i < days.length - 1,
                    onTap: () => showAttendanceDaySheet(context, d, fence: fence),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Details of one attendance day: times, flags and the check-in/out map.
///
/// [actionLabel] adds a primary action (e.g. "Correct record" for a
/// supervisor); it runs after the sheet closes.
Future<void> showAttendanceDaySheet(
  BuildContext context,
  AttendanceDay d, {
  (LatLng, int)? fence,
  String? title,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final l10n = context.l10n;
  return showAppSheet<void>(
    context,
    builder: (context) => SheetScaffold(
      primaryLabel: actionLabel,
      onPrimary: () {
        Navigator.pop(context);
        onAction?.call();
      },
      title: title ?? MaterialLocalizations.of(context).formatFullDate(d.workDate),
      subtitle: [
        attendanceStatusLabel(l10n, d.status),
        if (d.checkInAt != null) '${Fmt.time(d.checkInAt)} – ${d.checkOutAt == null ? '…' : Fmt.time(d.checkOutAt)}',
        if (d.worked != null) Fmt.duration(d.worked),
      ].join(' · '),
      children: [
        if (attendanceFlags(l10n, d).isNotEmpty) ...[
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: attendanceFlags(l10n, d)),
          const SizedBox(height: AppSpacing.lg),
        ],
        if (d.checkInLat != null || d.hasCheckOutLocation)
          AttendanceLocation(day: d, fence: fence, mapHeight: 200)
        else
          Row(children: [
            const IconTile(Icons.location_off_rounded, color: AppColors.inkMute, size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: Text(l10n.attNoGps, style: AppTypography.caption)),
          ]),
        if (d.note != null && d.note!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(d.note!, style: AppTypography.body),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    ),
  );
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
