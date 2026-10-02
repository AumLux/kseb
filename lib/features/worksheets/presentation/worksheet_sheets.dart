import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/domain/app_user.dart';
import '../../org/data/org_repository.dart';
import '../data/worksheet_repository.dart';
import 'worksheet_labels.dart';

Future<bool> _sheet(BuildContext context, Widget child) async =>
    await showModalBottomSheet<bool>(context: context, useRootNavigator: true, isScrollControlled: true, builder: (_) => child) ?? false;

EdgeInsets _sheetPadding(BuildContext context) => EdgeInsets.fromLTRB(
    AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom);

// ── Permit to work ──────────────────────────────────────────────────────

Future<bool> showPermitSheet(BuildContext context, String worksheetId, {Permit? existing}) =>
    _sheet(context, _PermitSheet(worksheetId: worksheetId, existing: existing));

class _PermitSheet extends ConsumerStatefulWidget {
  const _PermitSheet({required this.worksheetId, this.existing});

  final String worksheetId;
  final Permit? existing;

  @override
  ConsumerState<_PermitSheet> createState() => _PermitSheetState();
}

class _PermitSheetState extends ConsumerState<_PermitSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _lcRef = TextEditingController(text: widget.existing?.lineClearRef);
  late final _lcBy = TextEditingController(text: widget.existing?.lineClearIssuedBy);
  late final _isolation = TextEditingController(text: widget.existing?.isolationPoints);
  late bool _earthing = widget.existing?.earthingDone ?? false;
  late bool _testedDead = widget.existing?.testedDead ?? false;
  late bool _toolbox = widget.existing?.toolboxTalkDone ?? false;
  late final Set<String> _ppe = {...?widget.existing?.ppe};
  bool _busy = false;

  bool get _ready => _earthing && _testedDead && _toolbox && Permit.requiredPpe.every(_ppe.contains);

  @override
  void dispose() {
    for (final c in [_lcRef, _lcBy, _isolation]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || !_ready) return;
    setState(() => _busy = true);
    try {
      await ref.read(worksheetRepositoryProvider).signPermit(
            widget.worksheetId,
            Permit(
              lineClearRef: _lcRef.text.trim(),
              lineClearIssuedBy: _lcBy.text.trim(),
              isolationPoints: _isolation.text.trim(),
              earthingDone: _earthing,
              testedDead: _testedDead,
              toolboxTalkDone: _toolbox,
              ppe: _ppe.toList(),
              signedAt: DateTime.now(),
            ),
          );
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
    Widget check(String label, bool value, ValueChanged<bool> set) => CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(label, style: AppTypography.body),
          value: value,
          onChanged: (v) => setState(() => set(v ?? false)),
        );

    return Padding(
      padding: _sheetPadding(context),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.wsPermit, style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: l10n.wsPermitLcRef, controller: _lcRef, required: true),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: l10n.wsPermitLcBy, controller: _lcBy, required: true),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.wsPermitIsolation,
                hint: l10n.wsPermitIsolationHint,
                controller: _isolation,
                required: true,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              check(l10n.wsPermitEarthing, _earthing, (v) => _earthing = v),
              check(l10n.wsPermitTestedDead, _testedDead, (v) => _testedDead = v),
              check(l10n.wsPermitToolbox, _toolbox, (v) => _toolbox = v),
              const SizedBox(height: AppSpacing.sm),
              Text(l10n.wsPermitPpe, style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                for (final p in Permit.allPpe)
                  FilterChip(
                    label: Text(ppeLabel(l10n, p)),
                    selected: _ppe.contains(p),
                    onSelected: (v) => setState(() => v ? _ppe.add(p) : _ppe.remove(p)),
                  ),
              ]),
              if (!Permit.requiredPpe.every(_ppe.contains))
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Text(l10n.wsPermitPpeRequired, style: AppTypography.caption.copyWith(color: AppColors.danger)),
                ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: l10n.wsPermitSign,
                icon: Icons.draw_rounded,
                expand: true,
                loading: _busy,
                onPressed: _ready ? _save : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Crew ────────────────────────────────────────────────────────────────

Future<bool> showCrewSheet(BuildContext context, Worksheet ws, List<String> current) =>
    _sheet(context, _CrewSheet(ws: ws, current: current));

class _CrewSheet extends ConsumerStatefulWidget {
  const _CrewSheet({required this.ws, required this.current});

  final Worksheet ws;
  final List<String> current;

  @override
  ConsumerState<_CrewSheet> createState() => _CrewSheetState();
}

class _CrewSheetState extends ConsumerState<_CrewSheet> {
  late final Set<String> _selected = {...widget.current};
  bool _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref.read(worksheetRepositoryProvider).setCrew(widget.ws.id, _selected.toList());
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
    final people = (ref.watch(directoryProvider).value ?? const <Person>[])
        .where((p) => p.active && p.sectionId == widget.ws.sectionId && p.role.rank >= AppRole.supervisor.rank)
        .toList();
    return Padding(
      padding: _sheetPadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.wsCrewEdit, style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final p in people)
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.fullName),
                    subtitle: Text(p.employeeCode, style: AppTypography.caption),
                    value: _selected.contains(p.id),
                    onChanged: (v) => setState(() => (v ?? false) ? _selected.add(p.id) : _selected.remove(p.id)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(label: l10n.commonSave, expand: true, loading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

// ── Incident ────────────────────────────────────────────────────────────

Future<bool> showIncidentSheet(BuildContext context, {required String sectionId, String? worksheetId}) =>
    _sheet(context, _IncidentSheet(sectionId: sectionId, worksheetId: worksheetId));

class _IncidentSheet extends ConsumerStatefulWidget {
  const _IncidentSheet({required this.sectionId, this.worksheetId});

  final String sectionId;
  final String? worksheetId;

  @override
  ConsumerState<_IncidentSheet> createState() => _IncidentSheetState();
}

class _IncidentSheetState extends ConsumerState<_IncidentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  final _injured = TextEditingController();
  final _action = TextEditingController();
  IncidentSeverity _severity = IncidentSeverity.nearMiss;
  DateTime _when = DateTime.now();
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_description, _injured, _action]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final synced = await ref.read(worksheetRepositoryProvider).reportIncident(
            sectionId: widget.sectionId,
            worksheetId: widget.worksheetId,
            severity: _severity,
            occurredAt: _when,
            description: _description.text,
            injured: _injured.text,
            action: _action.text,
          );
      if (!mounted) return;
      showSnack(context, synced ? l10n.incReported : l10n.attQueued);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: _sheetPadding(context),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.incReport, style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.lg),
              Text(l10n.incSeverity, style: AppTypography.label),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                for (final s in IncidentSeverity.values)
                  ChoiceChip(
                    label: Text(severityLabel(l10n, s)),
                    selected: _severity == s,
                    onSelected: (_) => setState(() => _severity = s),
                  ),
              ]),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                key: ValueKey(_when),
                label: l10n.incOccurredAt,
                initialValue: Fmt.dateTime(_when),
                readOnly: true,
                suffix: const Icon(Icons.schedule_rounded),
                onTap: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: _when,
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now());
                  if (d == null || !context.mounted) return;
                  final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_when));
                  setState(() => _when = DateTime(d.year, d.month, d.day, t?.hour ?? _when.hour, t?.minute ?? _when.minute));
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.incDescription,
                controller: _description,
                required: true,
                maxLines: 3,
                validator: (v) => (v?.trim().length ?? 0) >= 10 ? null : l10n.fieldRequired(l10n.incDescription),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: l10n.incInjured, controller: _injured),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: l10n.incAction, controller: _action, maxLines: 2),
              const SizedBox(height: AppSpacing.xl),
              AppButton.danger(label: l10n.incReport, expand: true, loading: _busy, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
