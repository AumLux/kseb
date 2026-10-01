import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/l10n.dart';
import '../../core/outbox/outbox.dart';

/// Everything captured offline that hasn't reached the server yet, with
/// retry/discard for items the server rejected.
class SyncQueuePage extends ConsumerWidget {
  const SyncQueuePage({super.key});

  Future<void> _discard(BuildContext context, WidgetRef ref, OutboxOp op) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l10n.syncDiscardConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.syncDiscard)),
        ],
      ),
    );
    if (ok == true) await ref.read(outboxProvider.notifier).discard(op.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(outboxProvider);
    final controller = ref.read(outboxProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncTitle),
        actions: [
          if (state.pending > 0)
            TextButton(
              onPressed: state.processing ? null : controller.process,
              child: Text(l10n.syncNow),
            ),
        ],
      ),
      body: state.ops.isEmpty
          ? EmptyState(icon: Icons.cloud_done_rounded, title: l10n.moreSyncQueueEmpty)
          : ListView(
              children: [
                if (state.processing) const LinearProgressIndicator(),
                for (final op in state.ops)
                  AppListRow(
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
                                icon: const Icon(Icons.refresh_rounded),
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
                  ),
              ],
            ),
    );
  }
}
