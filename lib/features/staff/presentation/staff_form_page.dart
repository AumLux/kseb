import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../home/home_page.dart' show roleLabel;
import '../../org/data/org_repository.dart';
import '../data/staff_repository.dart';
import 'credentials_sheet.dart';
import '../../org/presentation/section_picker.dart';

/// Roles the signed-in user may assign (strictly below them; a Director may
/// create Directors). Mirrors the admin-users function.
List<AppRole> assignableRoles(AppRole me) =>
    AppRole.values.where((r) => me.outranks(r)).toList();

/// Sections the user may place people in.
List<OrgUnit> assignableSections(AppUser me, OrgTree tree) => me.role.isExecutive
    ? tree.sections
    : tree.sections.where((s) => me.sectionIds.contains(s.id)).toList();

class StaffFormPage extends ConsumerStatefulWidget {
  const StaffFormPage({super.key, this.userId});

  /// Null to create a new account.
  final String? userId;

  @override
  ConsumerState<StaffFormPage> createState() => _StaffFormPageState();
}

class _StaffFormPageState extends ConsumerState<StaffFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  AppRole? _role;
  String? _sectionId;
  String? _teamId;
  DateTime? _dob;
  bool _busy = false;
  bool _loaded = false;

  /// New accounts get the next free code unless the user opts out.
  bool _autoCode = true;
  String? _error;

  bool get _isEdit => widget.userId != null;

  @override
  void dispose() {
    for (final c in [_code, _name, _phone, _email]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(StaffMember m) {
    if (_loaded) return;
    _loaded = true;
    _code.text = m.employeeCode;
    _name.text = m.fullName;
    _phone.text = m.phone ?? '';
    _email.text = m.email ?? '';
    _role = m.role;
    _sectionId = m.sectionId;
    _teamId = m.teamId;
    _dob = m.dob;
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(1941),
      lastDate: DateTime(now.year - 17, now.month, now.day),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final draft = StaffDraft(
      employeeCode: _code.text,
      fullName: _name.text,
      role: _role!,
      sectionId: _sectionId,
      teamId: _teamId,
      email: _email.text,
      phone: _phone.text,
      dob: _dob,
    );
    final repo = ref.read(staffRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.update(widget.userId!, draft);
      } else {
        final creds = await repo.create(draft, autoCode: _autoCode);
        if (!mounted) return;
        setState(() => _busy = false);
        await showCredentialsSheet(context, draft.fullName, creds);
      }
      ref.invalidate(staffListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = failureMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final tree = ref.watch(orgTreeProvider);
    final teams = ref.watch(teamsProvider);
    if (_isEdit) {
      final member = ref.watch(staffMemberProvider(widget.userId!));
      if (member case AsyncData(:final value)) _fill(value);
      if (!_loaded) {
        return Scaffold(appBar: AppBar(title: Text(l10n.staffEditTitle)), body: const LoadingView());
      }
    }

    final roles = assignableRoles(me.role);
    final sections = tree.value == null ? <OrgUnit>[] : assignableSections(me, tree.value!);
    final sectionTeams =
        (teams.value ?? const <Team>[]).where((t) => t.sectionId == _sectionId && t.active).toList();
    final needsSection = _role != null && !_role!.isExecutive;

    return Scaffold(
      bottomNavigationBar: StickyActionBar(children: [
        AppButton(label: l10n.commonSave, loading: _busy, expand: true, onPressed: _save),
      ]),
      appBar: AppBar(title: Text(_isEdit ? l10n.staffEditTitle : l10n.staffNewTitle)),
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
                  if (_error != null) ...[
                    Text(_error!, style: AppTypography.label.copyWith(color: AppColors.danger)),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  if (!_isEdit && _autoCode)
                    _AutoCodeField(
                      onCustom: () => setState(() {
                        _autoCode = false;
                        _code.text = ref.read(nextEmployeeCodeProvider).value ?? '';
                      }),
                    )
                  else ...[
                  AppTextField(
                    label: l10n.staffEmployeeCode,
                    controller: _code,
                    required: true,
                    enabled: !_isEdit,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_-]'))],
                    validator: (v) => RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]{1,31}$').hasMatch(v ?? '')
                        ? null
                        : l10n.staffCodeInvalid,
                  ),
                  if (!_isEdit)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton.tertiary(
                        label: l10n.staffCodeUseAuto,
                        icon: Icons.auto_awesome_rounded,
                        onPressed: () => setState(() => _autoCode = true),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.staffFullName,
                    controller: _name,
                    required: true,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v?.trim().length ?? 0) >= 2
                        ? null
                        : l10n.fieldRequired(l10n.staffFullName),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppDropdownField<AppRole>(
                    label: l10n.staffRole,
                    required: true,
                    items: roles,
                    value: _role,
                    itemLabel: (r) => roleLabel(l10n, r),
                    onChanged: (r) => setState(() => _role = r),
                  ),
                  if (needsSection) ...[
                    const SizedBox(height: AppSpacing.lg),
                    SectionPickerField(
                      label: l10n.staffSection,
                      required: true,
                      allowed: sections,
                      value: _sectionId,
                      onChanged: (id) => setState(() {
                        _sectionId = id;
                        _teamId = null;
                      }),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppDropdownField<String?>(
                      label: l10n.staffTeam,
                      items: [null, ...sectionTeams.map((t) => t.id)],
                      value: _teamId,
                      itemLabel: (id) =>
                          id == null ? l10n.staffNoTeam : sectionTeams.firstWhere((t) => t.id == id).name,
                      onChanged: (id) => setState(() => _teamId = id),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.staffPhone,
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                    validator: (v) => (v == null || v.isEmpty || RegExp(r'^\+?[0-9]{10,15}$').hasMatch(v))
                        ? null
                        : l10n.staffPhoneInvalid,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.staffEmail,
                    helper: l10n.staffEmailHelper,
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isEdit || _email.text.isNotEmpty,
                    validator: (v) => (v == null || v.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v))
                        ? null
                        : l10n.staffEmailInvalid,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    key: ValueKey(_dob),
                    label: l10n.staffDob,
                    initialValue: _dob == null ? '' : Fmt.date(_dob),
                    readOnly: true,
                    onTap: _pickDob,
                    suffix: const Icon(Icons.calendar_today_rounded),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only display of the generated employee code with an opt-out.
class _AutoCodeField extends ConsumerWidget {
  const _AutoCodeField({required this.onCustom});

  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final next = ref.watch(nextEmployeeCodeProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l10n.staffEmployeeCode, style: AppTypography.label),
      const SizedBox(height: AppSpacing.xs + 2),
      Container(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: AppRadius.smAll,
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          const Icon(Icons.badge_rounded, color: AppColors.primaryDeep),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              switch (next) {
                AsyncData(:final value) => Text(value, style: AppTypography.title.copyWith(
                    color: AppColors.primaryDeep, fontFeatures: const [FontFeature.tabularFigures()])),
                AsyncError() => Text('—', style: AppTypography.title),
                _ => const Skeleton(child: SkeletonBox(width: 96, height: 20)),
              },
              const SizedBox(height: AppSpacing.xxs),
              Text(l10n.staffCodeAutoHelper, style: AppTypography.caption),
              // Below, not beside: the Malayalam label is long.
              TextButton(
                onPressed: onCustom,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 40),
                  tapTargetSize: MaterialTapTargetSize.padded,
                  alignment: Alignment.centerLeft,
                ),
                child: Text(l10n.staffCodeUseCustom),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
