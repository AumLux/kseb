import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../data/worksheet_repository.dart';
import 'worksheet_labels.dart';

/// The Work tab: my worksheets, or every worksheet in my sections for
/// supervisors and above.
class WorksheetsPage extends ConsumerStatefulWidget {
  const WorksheetsPage({super.key});

  @override
  ConsumerState<WorksheetsPage> createState() => _WorksheetsPageState();
}

class _WorksheetsPageState extends ConsumerState<WorksheetsPage> {
  WorksheetScope? _scope;
  WorksheetStatus? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final isLead = me.role.atLeast(AppRole.supervisor);
    final scope = _scope ?? (isLead ? WorksheetScope.section : WorksheetScope.mine);
    final list = ref.watch(worksheetsProvider(scope));
    final pending = ref.watch(pendingWorksheetsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.wsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/work/new');
          ref.invalidate(worksheetsProvider(scope));
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.wsNew),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
            child: Row(children: [
              if (isLead) ...[
                for (final s in WorksheetScope.values)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(s == WorksheetScope.mine ? l10n.wsMine : l10n.wsSection),
                      selected: scope == s,
                      onSelected: (_) => setState(() => _scope = s),
                    ),
                  ),
                const SizedBox(width: AppSpacing.sm),
              ],
              for (final s in [null, WorksheetStatus.submitted, WorksheetStatus.approved, WorksheetStatus.inProgress, WorksheetStatus.draft])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: FilterChip(
                    label: Text(s == null ? l10n.wsAllStatuses : worksheetStatusLabel(l10n, s)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                ),
            ]),
          ),
          Expanded(
            child: switch (list) {
              AsyncData(:final value) => _List(
                  worksheets: value.where((w) => _status == null || w.status == _status).toList(),
                  pendingTitles: [for (final op in pending) op.label],
                  onRefresh: () => ref.refresh(worksheetsProvider(scope).future),
                ),
              AsyncError(:final error) => ErrorState(
                  title: l10n.commonSomethingWrong,
                  message: failureMessage(l10n, error),
                  retryLabel: l10n.commonRetry,
                  onRetry: () => ref.invalidate(worksheetsProvider(scope)),
                ),
              _ => const LoadingView(),
            },
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({required this.worksheets, required this.pendingTitles, required this.onRefresh});

  final List<Worksheet> worksheets;
  final List<String> pendingTitles;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (worksheets.isEmpty && pendingTitles.isEmpty) {
      return EmptyState(icon: Icons.assignment_outlined, title: l10n.wsEmpty, message: l10n.wsEmptyHint);
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LazyListView(
        padding: const EdgeInsets.only(bottom: 96),
        header: [
          for (final t in pendingTitles)
            AppListRow(
              leading: const IconTile(Icons.cloud_upload_outlined, color: AppColors.info),
              title: t,
              trailing: StatusChip.fromDomain('pending_sync', label: l10n.attPendingSync),
            ),
        ],
        itemCount: worksheets.length,
        itemBuilder: (context, i) {
          final w = worksheets[i];
          return AppListRow(
            leading: IconTile(workTypeIcon(w.workType), color: AppColors.brandOrangeInk),
            title: w.title,
            subtitle: [
              w.code,
              workTypeLabel(l10n, w.workType),
              ?w.sectionName,
              Fmt.date(w.plannedDate ?? w.createdAt),
            ].join(' · '),
            trailing: worksheetChip(l10n, w.status),
            onTap: () => context.push('/work/${w.id}'),
          );
        },
      ),
    );
  }
}
