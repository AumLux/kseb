import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/format/ist.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../data/attendance_repository.dart';
import 'attendance_labels.dart';

class TeamAttendanceView extends ConsumerStatefulWidget {
  const TeamAttendanceView({super.key});

  @override
  ConsumerState<TeamAttendanceView> createState() => _TeamAttendanceViewState();
}

class _TeamAttendanceViewState extends ConsumerState<TeamAttendanceView> {
  DateTime _date = Ist.today();
  final Set<String> _selected = {};
  bool _verifying = false;

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
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MarkSheet(row: row, date: _date),
    );
    if (saved == true) ref.invalidate(teamDayProvider(_date));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = ref.watch(teamDayProvider(_date));
    final isToday = _date == Ist.today();

    return Column(
      children: [
        Material(
          color: AppColors.canvas,
          child: Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).previousPageTooltip,
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: _date.isAfter(Ist.today().subtract(const Duration(days: 31))) ? () => _shift(-1) : null,
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_rounded, size: AppSizes.iconSm),
                  label: Text(MaterialLocalizations.of(context).formatMediumDate(_date)),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: isToday ? null : () => _shift(1),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: switch (rows) {
            AsyncData(:final value) => value.isEmpty
                ? EmptyState(icon: Icons.groups_rounded, title: l10n.attTeamEmpty)
                : _list(context, value),
            AsyncError(:final error) => ErrorState(
                title: l10n.commonSomethingWrong,
                message: failureMessage(l10n, error),
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(teamDayProvider(_date)),
              ),
            _ => const LoadingView(),
          },
        ),
        if (_selected.isNotEmpty)
          SafeArea(
            top: false,
            child: Padding(
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
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l10n.attSummaryLine(present, absent, unmarked), style: AppTypography.label),
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
            onTap: () => _edit(r),
          );
        },
        footer: const [SizedBox(height: AppSpacing.xxl)],
      ),
    );
  }
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
          constraints: const BoxConstraints(minHeight: AppSizes.listRowMinHeight),
          padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.hairline))),
          child: Row(
            children: [
              Checkbox(value: selected, onChanged: onSelected == null ? null : (v) => onSelected!(v ?? false)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.member.fullName, style: AppTypography.bodyStrong),
                    Text([row.member.employeeCode, ?times].join(' · '), style: AppTypography.caption),
                    if (flags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: flags),
                    ],
                  ],
                ),
              ),
              attendanceChip(l10n, d?.status),
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isCorrection ? l10n.attCorrect : l10n.attMark, style: AppTypography.subtitle),
              Text('${widget.row.member.fullName} · ${MaterialLocalizations.of(context).formatMediumDate(widget.date)}',
                  style: AppTypography.caption),
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.xl),
              AppButton(label: l10n.commonSave, loading: _busy, expand: true, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
