import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      appBar: AppBar(
        title: Text(l10n.holidaysTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(() => _year--),
          ),
          Center(child: Text('$_year', style: AppTypography.bodyTabular)),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => setState(() => _year++),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.holidaysAdd),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 96),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(l10n.holidaysNote, style: AppTypography.caption),
          ),
          switch (holidays) {
            AsyncData(:final value) when value.isEmpty =>
              EmptyState(icon: Icons.event_busy_rounded, title: l10n.holidaysEmpty(_year)),
            AsyncData(:final value) => Column(children: [
                for (final h in value)
                  AppListRow(
                    leading: DateBlock(h.date, color: AppColors.ruby),
                    title: h.name,
                    subtitle: MaterialLocalizations.of(context).formatFullDate(h.date),
                    trailing: (me.role.isExecutive || h.sectionId != null)
                        ? IconButton(
                            tooltip: l10n.commonDelete,
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _delete(h),
                          )
                        : null,
                  ),
              ]),
            AsyncError(:final error) => ErrorState(
                title: l10n.commonSomethingWrong,
                message: failureMessage(l10n, error),
                onRetry: () => ref.invalidate(holidaysProvider(_year)),
              ),
            _ => const Padding(padding: EdgeInsets.all(AppSpacing.xxl), child: LoadingView()),
          },
        ],
      ),
    );
  }
}
