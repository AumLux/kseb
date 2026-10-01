import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../home/home_page.dart' show roleLabel;
import '../data/staff_repository.dart';

String staffStatusLabel(AppLocalizations l10n, StaffStatus s) => switch (s) {
      StaffStatus.active => l10n.statusActive,
      StaffStatus.suspended => l10n.statusSuspended,
      StaffStatus.exited => l10n.statusExited,
    };

class StaffListPage extends ConsumerStatefulWidget {
  const StaffListPage({super.key});

  @override
  ConsumerState<StaffListPage> createState() => _StaffListPageState();
}

class _StaffListPageState extends ConsumerState<StaffListPage> {
  String _query = '';
  StaffStatus? _status = StaffStatus.active;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider);
    final staff = ref.watch(staffListProvider);
    final canAdd = me?.role.atLeast(AppRole.manager) ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(canAdd ? l10n.staffTitle : l10n.staffMyTeam)),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/more/staff/new'),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(l10n.staffAdd),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.staffSearch,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                for (final s in [null, ...StaffStatus.values])
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(s == null ? l10n.staffFilterAll : staffStatusLabel(l10n, s)),
                      selected: _status == s,
                      onSelected: (_) => setState(() => _status = s),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: switch (staff) {
              AsyncData(:final value) => _List(
                  members: value
                      .where((m) => m.id != me?.id)
                      .where((m) => _status == null || m.status == _status)
                      .where((m) => m.matches(_query))
                      .toList(),
                ),
              AsyncError(:final error) => ErrorState(
                  title: l10n.commonSomethingWrong,
                  message: failureMessage(l10n, error),
                  retryLabel: l10n.commonRetry,
                  onRetry: () => ref.invalidate(staffListProvider),
                ),
              _ => const LoadingView(),
            },
          ),
        ],
      ),
    );
  }
}

class _List extends ConsumerWidget {
  const _List({required this.members});

  final List<StaffMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    if (members.isEmpty) {
      return EmptyState(icon: Icons.groups_rounded, title: l10n.staffEmpty, message: l10n.staffEmptyHint);
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(staffListProvider.future),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: members.length,
        itemBuilder: (context, i) {
          final m = members[i];
          return AppListRow(
            leading: CircleAvatar(
              backgroundColor: AppColors.canvasSunken,
              child: Text(m.fullName[0].toUpperCase(), style: AppTypography.bodyStrong),
            ),
            title: m.fullName,
            subtitle: [m.employeeCode, roleLabel(l10n, m.role), ?m.sectionName].join(' · '),
            trailing: m.status == StaffStatus.active
                ? null
                : StatusChip.fromDomain(m.status.name, label: staffStatusLabel(l10n, m.status)),
            onTap: () => context.push('/more/staff/${m.id}'),
          );
        },
      ),
    );
  }
}
