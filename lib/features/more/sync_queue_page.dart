import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/l10n.dart';
import '../../core/outbox/outbox.dart';
import '../../core/ui/dialogs.dart';

/// Everything captured offline that hasn't reached the server yet, with
/// retry/discard for items the server rejected.
class SyncQueuePage extends ConsumerWidget {
  const SyncQueuePage({super.key});

  Future<void> _discard(BuildContext context, WidgetRef ref, OutboxOp op) async {
    final l10n = context.l10n;
    final ok = await confirmAction(
      context,
      message: l10n.syncDiscardConfirm,
      confirmLabel: l10n.syncDiscard,
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (ok) await ref.read(outboxProvider.notifier).discard(op.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(outboxProvider);
    final controller = ref.read(outboxProvider.notifier);
    final failed = state.failed > 0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.syncTitle)),
      body: state.ops.isEmpty
          ? EmptyState(icon: Icons.cloud_done_rounded, title: l10n.moreSyncQueueEmpty, message: l10n.syncAllDoneHint)
          : ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
              children: [
                FadeSlideIn(
                  child: AppCard(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Row(children: [
                        IconTile(
                          failed ? Icons.cloud_off_rounded : Icons.cloud_upload_rounded,
                          color: failed ? AppColors.danger : AppColors.info,
                          size: 48,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(l10n.pendingSync(state.ops.length), style: AppTypography.subtitle),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(failed ? l10n.syncFailedHint : l10n.syncPendingHint, style: AppTypography.caption),
                          ]),
                        ),
                      ]),
                      if (state.pending > 0) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: l10n.syncNow,
                          icon: Icons.sync_rounded,
                          expand: true,
                          loading: state.processing,
                          onPressed: controller.process,
                        ),
                      ],
                    ]),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeSlideIn(
                  index: 1,
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      for (final (i, op) in state.ops.indexed)
                        AppListRow(
                          leading: IconTile(op.failed ? Icons.error_rounded : Icons.schedule_rounded,
                              color: op.failed ? AppColors.danger : AppColors.info, size: 36),
                          title: op.label,
                          subtitle: [
                            Fmt.dateTime(op.createdAt),
                            if (op.lastError != null) op.lastError!,
                          ].join(' · '),
                          trailing: op.failed
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: l10n.syncRetry,
                                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                                      onPressed: () => controller.retry(op.id),
                                    ),
                                    IconButton(
                                      tooltip: l10n.syncDiscard,
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
                                      onPressed: () => _discard(context, ref, op),
                                    ),
                                  ],
                                )
                              : StatusChip.fromDomain('pending_sync', label: l10n.syncPending),
                          showDivider: i < state.ops.length - 1,
                          dividerIndent: AppSpacing.lg + 36 + AppSpacing.md,
                        ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}
