import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/format/ist.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/maps/app_map.dart';
import '../../../core/ui/dialogs.dart';
import '../../../core/ui/sheets.dart';
import '../../org/data/org_repository.dart';
import '../data/attendance_repository.dart';
import 'attendance_labels.dart';
import 'attendance_location.dart';
import 'my_attendance_view.dart' show showAttendanceDaySheet;

/// Supervisor/manager view of a day: who is in, where they checked in (map),
/// what needs review, bulk verification.
class TeamAttendanceView extends ConsumerStatefulWidget {
  const TeamAttendanceView({super.key});

  @override
  ConsumerState<TeamAttendanceView> createState() => _TeamAttendanceViewState();
}

class _TeamAttendanceViewState extends ConsumerState<TeamAttendanceView> {
  DateTime _date = Ist.today();
  final Set<String> _selected = {};
  bool _verifying = false;
  bool _map = false;

  void _shift(int days) => setState(() {
        _date = _date.add(Duration(days: days));
        _selected.clear();
      });

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: Ist.today().subtract(const Duration(days: 31)),
      lastDate: Ist.today(),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _selected.clear();
      });
    }
  }

  Future<void> _verify() async {
    final l10n = context.l10n;
    setState(() => _verifying = true);
    try {
      final n = await ref.read(attendanceRepositoryProvider).verify(_selected.toList());
      if (!mounted) return;
      showSnack(context, l10n.attVerifiedCount(n));
      _selected.clear();
      ref.invalidate(teamDayProvider(_date));
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _edit(TeamDayRow row) async {
    final saved = await showAppSheet<bool>(context, builder: (_) => _MarkSheet(row: row, date: _date));
    if (saved == true) ref.invalidate(teamDayProvider(_date));
  }

  /// Person's day: map of check-in/out + an action to mark or correct it.
  void _open(TeamDayRow row) {
    final l10n = context.l10n;
    final d = row.day;
    if (d == null) {
      _edit(row);
      return;
    }
    showAttendanceDaySheet(
      context,
      d,
      fence: sectionFence(ref.read(orgTreeProvider).value, row.member.sectionId),
      title: row.member.fullName,
      actionLabel: l10n.attCorrect,
      onAction: () => _edit(row),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = ref.watch(teamDayProvider(_date));
    final isToday = _date == Ist.today();
    final loc = MaterialLocalizations.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
          child: Row(children: [
            // Date switcher pill.
            Container(
              decoration: BoxDecoration(
                color: AppColors.canvasSoft,
                borderRadius: AppRadius.pillAll,
                border: Border.all(color: AppColors.hairline),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  tooltip: loc.previousPageTooltip,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: _date.isAfter(Ist.today().subtract(const Duration(days: 31))) ? () => _shift(-1) : null,
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: AppRadius.pillAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Text(isToday ? l10n.homeTodayTitle : loc.formatMediumDate(_date),
                        style: AppTypography.label.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ),
                IconButton(
                  tooltip: loc.nextPageTooltip,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: isToday ? null : () => _shift(1),
                ),
              ]),
            ),
            const Spacer(),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: [
                ButtonSegment(value: false, icon: const Icon(Icons.view_list_rounded, size: 18), tooltip: l10n.attViewList),
                ButtonSegment(value: true, icon: const Icon(Icons.map_rounded, size: 18), tooltip: l10n.attViewMap),
              ],
              selected: {_map},
              onSelectionChanged: (s) => setState(() => _map = s.first),
            ),
          ]),
        ),
        Expanded(
          child: switch (rows) {
            AsyncData(:final value) => value.isEmpty
                ? EmptyState(icon: Icons.groups_rounded, title: l10n.attTeamEmpty)
                : (_map ? _TeamMap(rows: value, onOpen: _open) : _list(context, value)),
            AsyncError(:final error) => ErrorState(
                title: l10n.commonSomethingWrong,
                message: failureMessage(l10n, error),
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(teamDayProvider(_date)),
              ),
            _ => const LoadingView(),
          },
        ),
        AnimatedSize(
          duration: AppMotion.base,
          curve: AppMotion.curve,
          child: _selected.isEmpty
              ? const SizedBox(width: double.infinity)
              : SafeArea(
                  top: false,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.canvas,
                      border: Border(top: BorderSide(color: AppColors.hairline)),
                    ),
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: AppButton(
                      label: l10n.attVerifySelected(_selected.length),
                      icon: Icons.verified_rounded,
                      expand: true,
                      loading: _verifying,
                      onPressed: _verify,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _list(BuildContext context, List<TeamDayRow> rows) {
    final l10n = context.l10n;
    final present = rows.where((r) => r.day?.status == AttendanceStatus.present).length;
    final absent = rows.where((r) => r.day?.status == AttendanceStatus.absent).length;
    final unmarked = rows.where((r) => r.day == null).length;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(teamDayProvider(_date).future),
      child: LazyListView(
        header: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
            child: StatStrip(items: [
              StatItem(label: l10n.attStatusPresent, value: '$present', color: AppColors.success),
              StatItem(label: l10n.attStatusAbsent, value: '$absent', color: absent > 0 ? AppColors.danger : null),
              StatItem(label: l10n.attNotMarked, value: '$unmarked', color: unmarked > 0 ? AppColors.warning : null),
            ]),
          ),
        ],
        itemCount: rows.length,
        itemBuilder: (context, i) {
          final r = rows[i];
          return _TeamRow(
            row: r,
            selected: _selected.contains(r.day?.id),
            onSelected: r.day == null || r.day!.verified
                ? null
                : (v) => setState(() => v ? _selected.add(r.day!.id) : _selected.remove(r.day!.id)),
            onTap: () => _open(r),
          );
        },
        footer: const [SizedBox(height: AppSpacing.xxl)],
      ),
    );
  }
}

/// Everyone's check-in on one map, coloured by review state, with the
/// geofences of their sections.
class _TeamMap extends ConsumerWidget {
  const _TeamMap({required this.rows, required this.onOpen});

  final List<TeamDayRow> rows;
  final ValueChanged<TeamDayRow> onOpen;

  static Color _colorFor(AttendanceDay d) => (d.checkInMocked || d.checkOutMocked)
      ? AppColors.danger
      : (d.outsideGeofence == true || d.checkOutOutsideGeofence == true)
          ? AppColors.warning
          : AppColors.success;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tree = ref.watch(orgTreeProvider).value;
    final located = rows.where((r) => r.day?.checkInLat != null).toList();
    if (located.isEmpty) {
      return EmptyState(icon: Icons.location_searching_rounded, title: l10n.attMapEmpty);
    }
    final fences = {
      for (final r in located)
        if (sectionFence(tree, r.member.sectionId) case final f?) r.member.sectionId: f,
    }.values.toList();
    final points = [for (final r in located) LatLng(r.day!.checkInLat!, r.day!.checkInLng!)];

    return Stack(children: [
      AppMap(
        center: points.first,
        zoom: 15,
        fitPoints: [...points, for (final f in fences) f.$1],
        layers: [
          CircleLayer(circles: [for (final f in fences) geofenceCircle(f.$1, f.$2)]),
          MarkerLayer(markers: [
            for (final r in located)
              Marker(
                point: LatLng(r.day!.checkInLat!, r.day!.checkInLng!),
                width: 120,
                height: 64,
                alignment: Alignment.topCenter,
                child: GestureDetector(
                  onTap: () => onOpen(r),
                  child: _PersonPin(name: r.member.fullName, color: _colorFor(r.day!), time: Fmt.time(r.day!.checkInAt)),
                ),
              ),
          ]),
        ],
      ),
      Positioned(
        left: AppSpacing.md,
        top: AppSpacing.md,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.canvas,
            borderRadius: AppRadius.mdAll,
            boxShadow: AppShadows.level2,
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            _Legend(color: AppColors.success, label: l10n.attInsideGeofence),
            _Legend(color: AppColors.warning, label: l10n.attOutsideGeofence),
            _Legend(color: AppColors.danger, label: l10n.attMockedLocation),
          ]),
        ),
      ),
    ]);
  }
}

class _PersonPin extends StatelessWidget {
  const _PersonPin({required this.name, required this.color, required this.time});

  final String name;
  final Color color;
  final String time;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '$name $time',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: AppRadius.pillAll,
              border: Border.all(color: color, width: 2),
              boxShadow: AppShadows.level2,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Avatar(name, size: 24),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  name.split(' ').first,
                  style: AppTypography.caption.copyWith(color: AppColors.ink, fontWeight: FontWeight.w600, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
          ),
          CustomPaint(size: const Size(12, 8), painter: _Tail(color)),
        ]),
      );
}

class _Tail extends CustomPainter {
  const _Tail(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close(),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_Tail old) => old.color != color;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: AppSpacing.sm),
          Text(label, style: AppTypography.caption.copyWith(color: AppColors.inkSecondary, fontSize: 12)),
        ]),
      );
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.row, required this.selected, required this.onSelected, required this.onTap});

  final TeamDayRow row;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = row.day;
    final times = d?.checkInAt == null
        ? null
        : '${Fmt.time(d!.checkInAt)} – ${d.checkOutAt == null ? '…' : Fmt.time(d.checkOutAt)}';
    final flags = d == null ? const <StatusChip>[] : attendanceFlags(l10n, d);

    return Material(
      color: selected ? AppColors.primarySoft : AppColors.canvas,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.listRowMinHeight + 8),
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEF1F5)))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Avatar(row.member.fullName),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(row.member.fullName,
                            style: AppTypography.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      attendanceChip(l10n, d?.status, dense: true),
                    ]),
                    const SizedBox(height: AppSpacing.xxs),
                    Text([row.member.employeeCode, ?times].join(' · '), style: AppTypography.caption),
                    if (flags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs + 2),
                      Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: flags),
                    ],
                  ],
                ),
              ),
              if (onSelected != null || selected)
                Checkbox(value: selected, onChanged: onSelected == null ? null : (v) => onSelected!(v ?? false))
              else
                const SizedBox(width: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mark (no record yet) or correct (existing record) — reason is mandatory
/// and logged server-side with before/after values.
class _MarkSheet extends ConsumerStatefulWidget {
  const _MarkSheet({required this.row, required this.date});

  final TeamDayRow row;
  final DateTime date;

  @override
  ConsumerState<_MarkSheet> createState() => _MarkSheetState();
}

class _MarkSheetState extends ConsumerState<_MarkSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  late AttendanceStatus _status = widget.row.day?.status ?? AttendanceStatus.present;
  late TimeOfDay? _in = _tod(widget.row.day?.checkInAt);
  late TimeOfDay? _out = _tod(widget.row.day?.checkOutAt);
  bool _busy = false;

  /// Wall-clock time in IST (matches how [_at] writes it back).
  static TimeOfDay? _tod(DateTime? t) =>
      t == null ? null : TimeOfDay.fromDateTime(t.toUtc().add(Ist.offset));

  DateTime? _at(TimeOfDay? t) {
    if (t == null) return null;
    // Times are entered in IST for the work date.
    final d = widget.date;
    return DateTime.utc(d.year, d.month, d.day, t.hour, t.minute).subtract(Ist.offset);
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    final repo = ref.read(attendanceRepositoryProvider);
    try {
      final day = widget.row.day;
      if (day == null) {
        await repo.mark(widget.row.member.id, widget.date, _status, _reason.text);
      } else {
        await repo.correct(day, status: _status, checkIn: _at(_in), checkOut: _at(_out), reason: _reason.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isCorrection = widget.row.day != null;

    Widget timeField(String label, TimeOfDay? value, ValueChanged<TimeOfDay?> set) => Expanded(
          child: AppTextField(
            key: ValueKey('$label$value'),
            label: label,
            initialValue: value?.format(context) ?? '',
            readOnly: true,
            suffix: const Icon(Icons.schedule_rounded),
            onTap: () async {
              final t = await showTimePicker(context: context, initialTime: value ?? const TimeOfDay(hour: 9, minute: 0));
              if (t != null) set(t);
            },
          ),
        );

    return Form(
      key: _formKey,
      child: SheetScaffold(
        title: isCorrection ? l10n.attCorrect : l10n.attMark,
        subtitle: '${widget.row.member.fullName} · ${MaterialLocalizations.of(context).formatMediumDate(widget.date)}',
        primaryLabel: l10n.commonSave,
        busy: _busy,
        onPrimary: _save,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final s in AttendanceStatus.values.where((s) => s != AttendanceStatus.holiday))
                ChoiceChip(
                  label: Text(attendanceStatusLabel(l10n, s)),
                  selected: _status == s,
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          if (isCorrection && _status == AttendanceStatus.present) ...[
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              timeField(l10n.attCheckedIn, _in, (t) => setState(() => _in = t)),
              const SizedBox(width: AppSpacing.md),
              timeField(l10n.attCheckedOut, _out, (t) => setState(() => _out = t)),
            ]),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: l10n.attReason,
            hint: l10n.attReasonHint,
            controller: _reason,
            required: true,
            maxLines: 2,
            validator: (v) => (v?.trim().length ?? 0) >= 5 ? null : l10n.attReasonTooShort,
          ),
        ],
      ),
    );
  }
}
