import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../approvals/approvals_page.dart' show approvalsProvider;
import '../../auth/application/session_controller.dart';
import '../../org/data/org_repository.dart';
import '../data/inventory_repository.dart';
import 'inventory_labels.dart';
import '../../../core/ui/sheets.dart';

class MaterialRequestDetailPage extends ConsumerStatefulWidget {
  const MaterialRequestDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<MaterialRequestDetailPage> createState() => _MaterialRequestDetailPageState();
}

class _MaterialRequestDetailPageState extends ConsumerState<MaterialRequestDetailPage> {
  String? _busy;

  Future<void> _run(String key, Future<void> Function() action) async {
    setState(() => _busy = key);
    try {
      await action();
      ref
        ..invalidate(materialRequestProvider(widget.id))
        ..invalidate(materialRequestsProvider)
        ..invalidate(stockProvider)
        ..invalidate(approvalsProvider);
      if (mounted) showSnack(context, context.l10n.approvalsDone);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<String?> _reason() => promptText(
        context,
        title: context.l10n.approvalsReject,
        label: context.l10n.approvalsRejectReason,
        confirmLabel: context.l10n.approvalsReject,
        minLength: 3,
        destructive: true,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final req = ref.watch(materialRequestProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: Text(req.value?.code ?? l10n.invRequestDetail)),
      body: switch (req) {
        AsyncData(:final value) => _body(context, value),
        AsyncError(:final error) => ErrorState(
            title: l10n.commonSomethingWrong,
            message: failureMessage(l10n, error),
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(materialRequestProvider(widget.id)),
          ),
        _ => const LoadingView(),
      },
    );
  }

  Widget _body(BuildContext context, MaterialRequest r) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final people = ref.watch(directoryProvider).value ?? const <Person>[];
    final requester = people.where((p) => p.id == r.requestedBy).firstOrNull;
    final decider = people.where((p) => p.id == r.decidedBy).firstOrNull;
    final pending = r.status == 'pending';
    final canDecide = pending && r.requestedBy != me.id && requester != null && me.role.outranks(requester.role);
    final canCancel = pending && r.requestedBy == me.id;

    Widget fact(String label, String? value) =>
        value == null || value.isEmpty ? const SizedBox.shrink() : AppListRow(title: value, subtitle: label);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        Container(
          color: AppColors.canvas,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: AppSpacing.sm, children: [
              requestChip(l10n, r.status),
              StatusChip(label: requestTypeLabel(l10n, r.type), tone: StatusTone.brand, dense: true),
              if (r.priority.index >= Priority.high.index)
                StatusChip(label: priorityLabel(l10n, r.priority), tone: StatusTone.danger, dense: true),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(r.materialName, style: AppTypography.title),
            Text(Fmt.qty(r.quantity, unit: r.unit), style: AppTypography.kpi),
          ]),
        ),
        if (canDecide || canCancel)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: canDecide
                ? Row(children: [
                    Expanded(
                      child: AppButton.secondary(
                        label: l10n.approvalsReject,
                        loading: _busy == 'reject',
                        onPressed: _busy != null
                            ? null
                            : () async {
                                final note = await _reason();
                                if (note != null) {
                                  await _run('reject', () => ref.read(inventoryRepositoryProvider).decide(r.id, false, note: note));
                                }
                              },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        label: l10n.approvalsApprove,
                        loading: _busy == 'approve',
                        onPressed: _busy != null
                            ? null
                            : () => _run('approve', () => ref.read(inventoryRepositoryProvider).decide(r.id, true)),
                      ),
                    ),
                  ])
                : AppButton.secondary(
                    label: l10n.invCancelRequest,
                    expand: true,
                    loading: _busy == 'cancel',
                    onPressed: _busy != null
                        ? null
                        : () async {
                            if (await confirmAction(context,
                                message: l10n.invCancelConfirm, confirmLabel: l10n.invCancelRequest)) {
                              await _run('cancel', () => ref.read(inventoryRepositoryProvider).cancel(r.id));
                            }
                          },
                  ),
          ),
        fact(l10n.invStore, r.storeName),
        fact(l10n.invPurpose, r.purpose),
        fact(l10n.invRequestedBy, '${requester?.fullName ?? '—'} · ${Fmt.dateTime(r.createdAt)}'),
        fact(l10n.invRequiredBy, r.requiredBy == null ? null : Fmt.date(r.requiredBy)),
        fact(l10n.invUnitPrice, r.unitPrice == null ? null : Fmt.money(r.unitPrice)),
        fact(l10n.invSupplier, r.supplier),
        fact(l10n.invInvoice, r.invoiceRef),
        if (r.decidedAt != null)
          fact(l10n.invDecidedBy, '${decider?.fullName ?? '—'} · ${Fmt.dateTime(r.decidedAt)}'),
        fact(l10n.wsDecision, r.decisionNote),
        if (r.worksheetId != null)
          AppListRow(
            leading: const Icon(Icons.assignment_rounded, color: AppColors.inkMute),
            title: l10n.invWorksheet,
            onTap: () => context.push('/work/${r.worksheetId}'),
          ),
      ],
    );
  }
}
