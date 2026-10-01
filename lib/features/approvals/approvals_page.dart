import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design.dart';
import '../../core/errors/app_failure.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/l10n.dart';
import '../../core/supabase/providers.dart';
import '../../core/ui/dialogs.dart';
import '../home/dashboard_repository.dart';

/// One row of `my_approvals()`: something the caller can decide now.
class ApprovalItem {
  const ApprovalItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.requesterName,
    required this.requestedAt,
    this.code,
    this.priority,
    this.route,
  });

  final String kind;
  final String id;
  final String title;
  final String requesterName;
  final DateTime requestedAt;
  final String? code;
  final String? priority;
  final String? route;

  factory ApprovalItem.fromJson(Map<String, dynamic> j) => ApprovalItem(
        kind: j['kind'] as String,
        id: j['id'] as String,
        title: j['title'] as String,
        requesterName: j['requester_name'] as String,
        requestedAt: DateTime.parse(j['requested_at'] as String).toLocal(),
        code: j['code'] as String?,
        priority: j['priority'] as String?,
        route: j['route'] as String?,
      );
}

final approvalsProvider = FutureProvider.autoDispose<List<ApprovalItem>>((ref) async {
  try {
    final rows = await ref.watch(supabaseClientProvider).rpc('my_approvals') as List;
    return rows.map((r) => ApprovalItem.fromJson(Map<String, dynamic>.from(r as Map))).toList();
  } catch (e) {
    throw AppFailure.from(e);
  }
});

/// RPC deciding each inline-decidable kind. Other kinds open their screen.
const _inlineDecisions = {'leave': 'decide_leave', 'bonus': 'decide_bonus'};

class ApprovalsPage extends ConsumerWidget {
  const ApprovalsPage({super.key});

  String _kindLabel(AppLocalizations l10n, String kind) => switch (kind) {
        'leave' => l10n.approvalsKindLeave,
        'worksheet' => l10n.approvalsKindWorksheet,
        'material_request' => l10n.approvalsKindMaterial,
        'bonus' => l10n.approvalsKindBonus,
        _ => kind,
      };

  Future<void> _decide(BuildContext context, WidgetRef ref, ApprovalItem item, bool approve) async {
    final l10n = context.l10n;
    String? note;
    if (!approve) {
      note = await _askReason(context);
      if (note == null) return;
    }
    try {
      await ref.read(supabaseClientProvider).rpc(_inlineDecisions[item.kind]!, params: {
        'p_id': item.id,
        'p_approve': approve,
        'p_note': note,
      });
      if (context.mounted) showSnack(context, l10n.approvalsDone);
    } catch (e) {
      if (context.mounted) showSnack(context, failureMessage(l10n, e));
    }
    ref
      ..invalidate(approvalsProvider)
      ..invalidate(dashboardProvider);
  }

  Future<String?> _askReason(BuildContext context) {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.approvalsReject),
        content: Form(
          key: formKey,
          child: AppTextField(
            label: l10n.approvalsRejectReason,
            controller: controller,
            required: true,
            maxLines: 2,
            validator: (v) => (v?.trim().length ?? 0) >= 3 ? null : l10n.fieldRequired(l10n.approvalsRejectReason),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(context, controller.text.trim());
            },
            child: Text(l10n.approvalsReject),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final items = ref.watch(approvalsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.approvalsTitle)),
      body: switch (items) {
        AsyncData(:final value) => value.isEmpty
            ? EmptyState(icon: Icons.task_alt_rounded, title: l10n.approvalsEmpty, message: l10n.approvalsEmptyHint)
            : RefreshIndicator(
                onRefresh: () => ref.refresh(approvalsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: value.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, i) {
                    final item = value[i];
                    final inline = _inlineDecisions.containsKey(item.kind);
                    return AppCard(
                      onTap: inline || item.route == null ? null : () => context.push(item.route!),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            StatusChip(label: _kindLabel(l10n, item.kind), tone: StatusTone.brand, dense: true),
                            if (item.priority == 'high' || item.priority == 'critical') ...[
                              const SizedBox(width: AppSpacing.sm),
                              StatusChip(label: item.priority!, tone: StatusTone.danger, dense: true),
                            ],
                            const Spacer(),
                            Text(Fmt.dateTime(item.requestedAt), style: AppTypography.caption),
                          ]),
                          const SizedBox(height: AppSpacing.sm),
                          Text(item.title, style: AppTypography.bodyStrong),
                          Text([item.requesterName, ?item.code].join(' · '), style: AppTypography.caption),
                          if (inline) ...[
                            const SizedBox(height: AppSpacing.md),
                            Row(children: [
                              Expanded(
                                child: AppButton.secondary(
                                  label: l10n.approvalsReject,
                                  onPressed: () => _decide(context, ref, item, false),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: AppButton(
                                  label: l10n.approvalsApprove,
                                  onPressed: () => _decide(context, ref, item, true),
                                ),
                              ),
                            ]),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
        AsyncError(:final error) => ErrorState(
            title: l10n.commonSomethingWrong,
            message: failureMessage(l10n, error),
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(approvalsProvider),
          ),
        _ => const LoadingView(),
      },
    );
  }
}
