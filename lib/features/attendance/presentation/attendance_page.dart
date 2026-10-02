import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/export/file_export.dart';
import '../../../core/format/ist.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../org/data/org_repository.dart';
import '../../staff/presentation/staff_form_page.dart' show assignableSections;
import '../application/muster_export.dart';
import '../data/attendance_repository.dart';
import 'my_attendance_view.dart';
import 'team_attendance_view.dart';
import '../../org/presentation/section_picker.dart';

class AttendancePage extends ConsumerStatefulWidget {
  const AttendancePage({super.key});

  @override
  ConsumerState<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends ConsumerState<AttendancePage> {
  bool _team = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider);
    final isLead = me?.role.atLeast(AppRole.supervisor) ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navAttendance),
        actions: [
          if (isLead)
            IconButton(
              tooltip: l10n.attExportMuster,
              icon: const Icon(Icons.table_view_rounded),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (_) => const _MusterSheet(),
              ),
            ),
        ],
        bottom: isLead
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: false, label: Text(l10n.attMe), icon: const Icon(Icons.person_rounded)),
                      ButtonSegment(value: true, label: Text(l10n.attTeam), icon: const Icon(Icons.groups_rounded)),
                    ],
                    selected: {_team},
                    onSelectionChanged: (s) => setState(() => _team = s.first),
                  ),
                ),
              )
            : null,
      ),
      body: _team && isLead ? const TeamAttendanceView() : const MyAttendanceView(),
    );
  }
}

class _MusterSheet extends ConsumerStatefulWidget {
  const _MusterSheet();

  @override
  ConsumerState<_MusterSheet> createState() => _MusterSheetState();
}

class _MusterSheetState extends ConsumerState<_MusterSheet> {
  DateTime _month = Ist.monthStart(Ist.today());
  String? _sectionId;
  ExportKind? _busy;

  Future<void> _export(ExportKind kind) async {
    final l10n = context.l10n;
    final me = ref.read(currentUserProvider)!;
    final monthLabel = MaterialLocalizations.of(context).formatMonthYear(_month);
    setState(() => _busy = kind);
    try {
      final cells = await ref.read(attendanceRepositoryProvider).muster(_month, sectionId: _sectionId);
      final sectionName = ref.read(orgTreeProvider).value?.byId(_sectionId)?.name;
      final title = 'Muster roll — $monthLabel${sectionName == null ? '' : ' — $sectionName'}';
      final bytes = kind == ExportKind.pdf
          ? await buildMusterPdf(cells: cells, month: _month, title: title, generatedBy: me.fullName)
          : buildMusterXlsx(cells: cells, month: _month, title: title);
      if (!mounted) return;
      await exportFile(context,
          bytes: bytes,
          baseName: 'muster_${_month.year}_${_month.month.toString().padLeft(2, '0')}${sectionName == null ? '' : '_$sectionName'}',
          kind: kind);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final tree = ref.watch(orgTreeProvider).value;
    final sections = tree == null ? const <OrgUnit>[] : assignableSections(me, tree);
    final thisMonth = Ist.monthStart(Ist.today());
    final months = [for (var i = 0; i < 6; i++) DateTime(thisMonth.year, thisMonth.month - i)];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.attExportMuster, style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.lg),
            AppDropdownField<DateTime>(
              label: l10n.commonDate,
              items: months,
              value: _month,
              itemLabel: (m) => MaterialLocalizations.of(context).formatMonthYear(m),
              onChanged: (m) => setState(() => _month = m ?? _month),
            ),
            if (sections.length > 1) ...[
              const SizedBox(height: AppSpacing.lg),
              SectionPickerField(
                label: l10n.staffSection,
                allowed: sections,
                value: _sectionId,
                onChanged: (id) => setState(() => _sectionId = id),
              ),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.attExportPdf,
              icon: Icons.picture_as_pdf_rounded,
              expand: true,
              loading: _busy == ExportKind.pdf,
              onPressed: _busy == null ? () => _export(ExportKind.pdf) : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.secondary(
              label: l10n.attExportXlsx,
              icon: Icons.grid_on_rounded,
              expand: true,
              loading: _busy == ExportKind.xlsx,
              onPressed: _busy == null ? () => _export(ExportKind.xlsx) : null,
            ),
          ],
        ),
      ),
    );
  }
}
