import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/format/ist.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/location/location_service.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/application/session_controller.dart';
import '../../org/data/org_repository.dart';
import '../../staff/presentation/staff_form_page.dart' show assignableSections;
import '../data/worksheet_repository.dart';
import 'worksheet_labels.dart';

class WorksheetFormPage extends ConsumerStatefulWidget {
  const WorksheetFormPage({super.key, this.worksheetId});

  /// Null to create.
  final String? worksheetId;

  @override
  ConsumerState<WorksheetFormPage> createState() => _WorksheetFormPageState();
}

class _WorksheetFormPageState extends ConsumerState<WorksheetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _location = TextEditingController();
  final _permitBook = TextEditingController();
  final _description = TextEditingController();
  WorkType _type = WorkType.maintenance;
  String? _sectionId;
  DateTime? _planned;
  CapturedLocation? _gps;
  double? _lat, _lng;
  bool _locating = false;
  String? _busy;
  bool _loaded = false;

  bool get _isEdit => widget.worksheetId != null;

  @override
  void dispose() {
    for (final c in [_title, _location, _permitBook, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Worksheet w) {
    if (_loaded) return;
    _loaded = true;
    _title.text = w.title;
    _location.text = w.locationText;
    _permitBook.text = w.permitBookNo ?? '';
    _description.text = w.description ?? '';
    _type = w.workType;
    _sectionId = w.sectionId;
    _planned = w.plannedDate;
    _lat = w.lat;
    _lng = w.lng;
  }

  Future<void> _useGps() async {
    setState(() => _locating = true);
    try {
      final loc = await ref.read(locationServiceProvider).current();
      setState(() {
        _gps = loc;
        _lat = loc.lat;
        _lng = loc.lng;
      });
    } on AppFailure catch (f) {
      if (mounted) showSnack(context, f.message);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  WorksheetDraft get _draft => WorksheetDraft(
        workType: _type,
        title: _title.text,
        sectionId: _sectionId!,
        locationText: _location.text,
        lat: _lat,
        lng: _lng,
        permitBookNo: _permitBook.text,
        description: _description.text,
        plannedDate: _planned,
      );

  Future<void> _save({required bool submit}) async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = submit ? 'submit' : 'draft');
    final repo = ref.read(worksheetRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.update(widget.worksheetId!, _draft);
        if (submit) await repo.transition(widget.worksheetId!, 'submit');
        if (mounted) showSnack(context, submit ? l10n.wsSubmitted : l10n.staffSaved);
      } else {
        final (_, synced) = await repo.create(_draft, submit: submit);
        if (mounted) showSnack(context, !synced ? l10n.wsSavedOffline : submit ? l10n.wsSubmitted : l10n.staffSaved);
      }
      if (mounted) Navigator.of(context).pop(true);
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
    if (_isEdit) {
      if (ref.watch(worksheetProvider(widget.worksheetId!)) case AsyncData(:final value)) _fill(value);
      if (!_loaded) return Scaffold(appBar: AppBar(title: Text(l10n.wsEdit)), body: const LoadingView());
    } else {
      _sectionId ??= sections.length == 1 ? sections.single.id : me.sectionId;
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? l10n.wsEdit : l10n.wsNew)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Text(l10n.wsType, style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(spacing: AppSpacing.sm, children: [
                    for (final t in WorkType.values)
                      ChoiceChip(
                        label: Text(workTypeLabel(l10n, t)),
                        selected: _type == t,
                        onSelected: (_) => setState(() => _type = t),
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.wsJobTitle,
                    hint: l10n.wsJobTitleHint,
                    controller: _title,
                    required: true,
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) => (v?.trim().length ?? 0) >= 3 ? null : l10n.fieldRequired(l10n.wsJobTitle),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppDropdownField<String>(
                    label: l10n.staffSection,
                    required: true,
                    items: sections.map((s) => s.id).toList(),
                    value: _sectionId,
                    itemLabel: (id) => sections.firstWhere((s) => s.id == id).name,
                    onChanged: (id) => setState(() => _sectionId = id),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.wsLocation,
                    controller: _location,
                    required: true,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _lat != null
                        ? StatusChip(
                            label: _gps == null
                                ? '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}'
                                : l10n.wsGpsSet(_gps!.accuracyM.round()),
                            tone: StatusTone.success,
                            icon: Icons.my_location_rounded,
                          )
                        : AppButton.tertiary(
                            label: l10n.wsUseGps,
                            icon: Icons.my_location_rounded,
                            loading: _locating,
                            onPressed: _useGps,
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(label: l10n.wsPermitBook, controller: _permitBook),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    key: ValueKey(_planned),
                    label: l10n.wsPlannedDate,
                    initialValue: _planned == null ? '' : MaterialLocalizations.of(context).formatMediumDate(_planned!),
                    readOnly: true,
                    suffix: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: _planned ?? Ist.today(),
                        firstDate: Ist.today().subtract(const Duration(days: 30)),
                        lastDate: Ist.today().add(const Duration(days: 365)),
                      );
                      if (d != null) setState(() => _planned = d);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.wsDescription,
                    controller: _description,
                    maxLines: 4,
                    minLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: l10n.wsSaveSubmit,
                    icon: Icons.send_rounded,
                    expand: true,
                    loading: _busy == 'submit',
                    onPressed: _busy == null ? () => _save(submit: true) : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton.secondary(
                    label: l10n.wsSaveDraft,
                    expand: true,
                    loading: _busy == 'draft',
                    onPressed: _busy == null ? () => _save(submit: false) : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
