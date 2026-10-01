import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../staff/presentation/staff_form_page.dart' show assignableSections;
import '../data/org_repository.dart';
import 'section_picker.dart';

class TeamsPage extends ConsumerWidget {
  const TeamsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final canEdit = me.role.atLeast(AppRole.manager);
    final tree = ref.watch(orgTreeProvider);
    final teams = ref.watch(teamsProvider);
    final people = ref.watch(directoryProvider);

    final ready = tree.hasValue && teams.hasValue && people.hasValue;
    final error = tree.error ?? teams.error ?? people.error;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teamsTitle)),
      floatingActionButton: canEdit && ready
          ? FloatingActionButton.extended(
              onPressed: () => _edit(context, ref, null),
              icon: const Icon(Icons.group_add_rounded),
              label: Text(l10n.teamsAdd),
            )
          : null,
      body: error != null
          ? ErrorState(
              title: l10n.commonSomethingWrong,
              message: failureMessage(l10n, error),
              retryLabel: l10n.commonRetry,
              onRetry: () => ref
                ..invalidate(orgTreeProvider)
                ..invalidate(teamsProvider)
                ..invalidate(directoryProvider),
            )
          : !ready
              ? const LoadingView()
              : _body(context, ref, tree.value!, teams.value!, people.value!, canEdit),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, OrgTree tree, List<Team> teams,
      List<Person> people, bool canEdit) {
    final l10n = context.l10n;
    if (teams.isEmpty) return EmptyState(icon: Icons.groups_2_rounded, title: l10n.teamsEmpty);
    final bySection = <String, List<Team>>{};
    for (final t in teams) {
      bySection.putIfAbsent(t.sectionId, () => []).add(t);
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        for (final entry in bySection.entries) ...[
          SectionHeader(tree.byId(entry.key)?.name ?? '—'),
          for (final t in entry.value)
            AppListRow(
              leading: const Icon(Icons.groups_rounded, color: AppColors.inkMute),
              title: t.name,
              subtitle: [
                people.where((p) => p.id == t.supervisorId).firstOrNull?.fullName ?? l10n.teamNoSupervisor,
                l10n.teamMembers(people.where((p) => p.teamId == t.id && p.active).length),
              ].join(' · '),
              trailing: t.active ? null : StatusChip(label: l10n.statusSuspended, dense: true),
              onTap: canEdit ? () => _edit(context, ref, t) : null,
            ),
        ],
      ],
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Team? team) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _TeamForm(team: team),
    );
    if (saved == true) {
      ref
        ..invalidate(teamsProvider)
        ..invalidate(directoryProvider);
    }
  }
}

class _TeamForm extends ConsumerStatefulWidget {
  const _TeamForm({this.team});

  final Team? team;

  @override
  ConsumerState<_TeamForm> createState() => _TeamFormState();
}

class _TeamFormState extends ConsumerState<_TeamForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.team?.name);
  late String? _sectionId = widget.team?.sectionId;
  late String? _supervisorId = widget.team?.supervisorId;
  late bool _active = widget.team?.active ?? true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref.read(orgRepositoryProvider).saveTeam(
            id: widget.team?.id,
            sectionId: _sectionId!,
            name: _name.text,
            supervisorId: _supervisorId,
            active: _active,
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
    final me = ref.watch(currentUserProvider)!;
    final sections = assignableSections(me, ref.watch(orgTreeProvider).value!);
    final supervisors = ref
        .watch(directoryProvider)
        .value!
        .where((p) => p.active && p.role == AppRole.supervisor && p.sectionId == _sectionId)
        .toList();

    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl,
          AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.team == null ? l10n.teamsAdd : widget.team!.name, style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: l10n.teamName, controller: _name, required: true),
            const SizedBox(height: AppSpacing.lg),
            SectionPickerField(
              label: l10n.staffSection,
              required: true,
              allowed: sections,
              value: _sectionId,
              enabled: widget.team == null,
              onChanged: (id) => setState(() {
                        _sectionId = id;
                        _supervisorId = null;
                      }),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppDropdownField<String?>(
              label: l10n.teamSupervisor,
              items: [null, ...supervisors.map((p) => p.id)],
              value: _supervisorId,
              itemLabel: (id) => id == null
                  ? l10n.teamNoSupervisor
                  : supervisors.firstWhere((p) => p.id == id).fullName,
              onChanged: (id) => setState(() => _supervisorId = id),
            ),
            if (widget.team != null)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.teamActive),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(label: l10n.commonSave, loading: _busy, expand: true, onPressed: _save),
          ],
        ),
      ),
    );
  }
}
