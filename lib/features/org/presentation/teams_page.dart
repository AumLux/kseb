import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../../core/ui/sheets.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../home/home_page.dart' show roleLabel;
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
              : RefreshIndicator(
                  onRefresh: () async {
                    ref
                      ..invalidate(teamsProvider)
                      ..invalidate(directoryProvider);
                    await ref.read(teamsProvider.future);
                  },
                  child: _body(context, ref, tree.value!, teams.value!, people.value!, canEdit),
                ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, OrgTree tree, List<Team> teams,
      List<Person> people, bool canEdit) {
    final l10n = context.l10n;
    if (teams.isEmpty) return EmptyState(icon: Icons.groups_2_rounded, title: l10n.teamsEmpty);

    // The supervisor leads the team; they're shown separately, not counted as a member.
    List<Person> membersOf(Team t) =>
        people.where((p) => p.teamId == t.id && p.active && p.id != t.supervisorId).toList();
    final bySection = <String, List<Team>>{};
    for (final t in teams) {
      bySection.putIfAbsent(t.sectionId, () => []).add(t);
    }
    final teamSections = bySection.keys.toSet();
    final members = people.where((p) => p.active && p.teamId != null).length;
    final unassigned = people
        .where((p) => p.active && p.role == AppRole.staff && p.teamId == null && teamSections.contains(p.sectionId))
        .length;
    final noLead = teams.where((t) => t.active && t.supervisorId == null).length;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
      children: [
        FadeSlideIn(
          child: StatStrip(items: [
            StatItem(label: l10n.teamsTitle, value: '${teams.length}'),
            StatItem(label: l10n.teamsCountMembers, value: '$members'),
            StatItem(
              label: l10n.teamsCountUnassigned,
              value: '$unassigned',
              color: unassigned > 0 ? AppColors.warning : null,
            ),
          ]),
        ),
        if (noLead > 0) ...[
          const SizedBox(height: AppSpacing.md),
          NoteBanner(text: l10n.teamsWithoutSupervisor(noLead), icon: Icons.person_off_rounded, tone: AppColors.warning),
        ],
        for (final (i, entry) in bySection.entries.indexed)
          FadeSlideIn(
            index: i + 1,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.sm),
                child: Row(children: [
                  const Icon(Icons.location_city_rounded, size: 16, color: AppColors.inkMute),
                  const SizedBox(width: AppSpacing.xs + 2),
                  Expanded(
                    child: Text(
                      (tree.byId(entry.key)?.name ?? '—').toUpperCase(),
                      style: AppTypography.overline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ),
              AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (final (j, t) in entry.value.indexed)
                    _TeamRow(
                      team: t,
                      supervisor: people.where((p) => p.id == t.supervisorId).firstOrNull,
                      members: membersOf(t),
                      divider: j < entry.value.length - 1,
                      onTap: () => _open(context, ref, t, tree, people, canEdit),
                    ),
                ]),
              ),
            ]),
          ),
      ],
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref, Team t, OrgTree tree, List<Person> people, bool canEdit) async {
    final l10n = context.l10n;
    final supervisor = people.where((p) => p.id == t.supervisorId).firstOrNull;
    final members = people.where((p) => p.teamId == t.id && p.active && p.id != t.supervisorId).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));
    final edit = await showAppSheet<bool>(
      context,
      builder: (context) => SheetScaffold(
        title: t.name,
        subtitle: tree.byId(t.sectionId)?.name,
        leading: IconTile(Icons.groups_rounded, color: _teamTint(t), size: 48),
        primaryLabel: canEdit ? l10n.teamEdit : null,
        onPrimary: () => Navigator.pop(context, true),
        children: [
          if (!t.active) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: StatusChip(label: l10n.statusSuspended, tone: StatusTone.warning, dense: true),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(l10n.teamSupervisor.toUpperCase(), style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: supervisor == null
                ? AppListRow(
                    leading: const IconTile(Icons.person_off_rounded, color: AppColors.warning, size: 36),
                    title: l10n.teamNoSupervisor,
                    showDivider: false,
                  )
                : _PersonRow(person: supervisor, divider: false),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.teamMembers(members.length).toUpperCase(), style: AppTypography.overline),
          const SizedBox(height: AppSpacing.sm),
          if (members.isEmpty)
            Text(l10n.teamNoMembersHint, style: AppTypography.caption)
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                for (final (i, p) in members.indexed) _PersonRow(person: p, divider: i < members.length - 1),
              ]),
            ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
    if (edit == true && context.mounted) await _edit(context, ref, t);
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, Team? team) async {
    final saved = await showAppSheet<bool>(context, builder: (_) => _TeamForm(team: team));
    if (saved == true) {
      ref
        ..invalidate(teamsProvider)
        ..invalidate(directoryProvider);
    }
  }
}

const _tints = [AppColors.primaryDeep, AppColors.info, AppColors.success, AppColors.brandOrangeInk, AppColors.ruby];

/// A stable colour per team, so a team keeps its colour across screens.
Color _teamTint(Team t) => _tints[t.id.codeUnits.fold<int>(0, (a, c) => a + c) % _tints.length];

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.team,
    required this.supervisor,
    required this.members,
    required this.divider,
    required this.onTap,
  });

  final Team team;
  final Person? supervisor;
  final List<Person> members;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppListRow(
      leading: IconTile(Icons.groups_rounded, color: _teamTint(team), size: 40),
      title: team.name,
      subtitle: [
        supervisor?.fullName ?? l10n.teamNoSupervisor,
        l10n.teamMembers(members.length),
      ].join(' · '),
      trailing: !team.active
          ? StatusChip(label: l10n.statusSuspended, tone: StatusTone.warning, dense: true)
          : _AvatarStack(names: [for (final m in members) m.fullName]),
      showDivider: divider,
      dividerIndent: AppSpacing.lg + 40 + AppSpacing.md,
      onTap: onTap,
    );
  }
}

/// Up to three overlapping initials plus "+n" (Groww/Slack style).
class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    if (names.isEmpty) return const SizedBox.shrink();
    const size = 26.0;
    const step = 18.0;
    final shown = names.take(3).toList();
    final extra = names.length - shown.length;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return ExcludeSemantics(
      child: SizedBox(
        width: size + step * (count - 1),
        height: size,
        child: Stack(children: [
          for (final (i, n) in shown.indexed)
            Positioned(
              left: step * i,
              child: DecoratedBox(
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.canvas),
                child: Padding(padding: const EdgeInsets.all(1.5), child: Avatar(n, size: size - 3)),
              ),
            ),
          if (extra > 0)
            Positioned(
              left: step * shown.length,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.canvasSunken,
                  border: Border.all(color: AppColors.canvas, width: 1.5),
                ),
                child: Text('+$extra', style: AppTypography.caption.copyWith(fontSize: 10, color: AppColors.inkSecondary)),
              ),
            ),
        ]),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.divider});

  final Person person;
  final bool divider;

  @override
  Widget build(BuildContext context) => AppListRow(
        leading: Avatar(person.fullName, size: 36),
        title: person.fullName,
        subtitle: '${person.employeeCode} · ${roleLabel(context.l10n, person.role)}',
        showDivider: divider,
        dividerIndent: AppSpacing.lg + 36 + AppSpacing.md,
      );
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

    return Form(
      key: _formKey,
      child: SheetScaffold(
        title: widget.team == null ? l10n.teamsAdd : widget.team!.name,
        subtitle: widget.team == null ? null : l10n.teamEdit,
        primaryLabel: l10n.commonSave,
        busy: _busy,
        onPrimary: _save,
        children: [
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
            itemLabel: (id) => id == null ? l10n.teamNoSupervisor : supervisors.firstWhere((p) => p.id == id).fullName,
            onChanged: (id) => setState(() => _supervisorId = id),
          ),
          if (widget.team != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l10n.teamActive, style: AppTypography.subtitle),
                    Text(l10n.teamActiveHint, style: AppTypography.caption),
                  ]),
                ),
                Switch.adaptive(value: _active, onChanged: (v) => setState(() => _active = v)),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
