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

    final actions = <Widget>[
      if (canDecide)
        Row(children: [
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
      else if (canCancel)
        AppButton.secondary(
          label: l10n.invCancelRequest,
          expand: true,
          loading: _busy == 'cancel',
          onPressed: _busy != null
              ? null
              : () async {
                  if (await confirmAction(context, message: l10n.invCancelConfirm, confirmLabel: l10n.invCancelRequest)) {
                    await _run('cancel', () => ref.read(inventoryRepositoryProvider).cancel(r.id));
                  }
                },
        ),
    ];

    final list = ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxxl),
      children: [
        FadeSlideIn(
          child: DetailHeader(
            icon: switch (r.type.name) {
              'receipt' => Icons.move_to_inbox_rounded,
              'issue' => Icons.outbox_rounded,
              _ => Icons.assignment_return_rounded,
            },
            iconColor: AppColors.info,
            title: r.materialName,
            subtitle: [r.code, requestTypeLabel(l10n, r.type)].join(' · '),
            status: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              requestChip(l10n, r.status),
              if (r.priority.index >= Priority.high.index)
                StatusChip(label: priorityLabel(l10n, r.priority), tone: StatusTone.danger, dense: true),
            ]),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        StatStrip(items: [
          StatItem(label: l10n.invQuantity, value: Fmt.qty(r.quantity, unit: r.unit)),
          if (r.unitPrice != null) StatItem(label: l10n.invUnitPrice, value: Fmt.money(r.unitPrice)),
          if (r.unitPrice != null) StatItem(label: l10n.invValue, value: Fmt.moneyCompact(r.unitPrice! * r.quantity)),
        ]),
        if (r.decisionNote != null && r.decisionNote!.trim().isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          NoteBanner(
            text: '${l10n.wsDecision}: ${r.decisionNote}',
            tone: r.status == 'rejected' ? AppColors.danger : AppColors.info,
            icon: r.status == 'rejected' ? Icons.report_rounded : Icons.info_rounded,
          ),
        ],
        InfoGroup(title: l10n.commonDetails, rows: [
          InfoRow(l10n.invStore, r.storeName, icon: Icons.warehouse_rounded),
          InfoRow(l10n.invPurpose, r.purpose, icon: Icons.notes_rounded),
          InfoRow(l10n.invRequestedBy, '${requester?.fullName ?? '—'} · ${Fmt.dateTime(r.createdAt)}',
              icon: Icons.person_rounded),
          InfoRow(l10n.invRequiredBy, r.requiredBy == null ? null : Fmt.date(r.requiredBy), icon: Icons.event_rounded),
          InfoRow(l10n.invSupplier, r.supplier, icon: Icons.local_shipping_rounded),
          InfoRow(l10n.invInvoice, r.invoiceRef, icon: Icons.receipt_long_rounded, tabular: true),
          if (r.decidedAt != null)
            InfoRow(l10n.invDecidedBy, '${decider?.fullName ?? '—'} · ${Fmt.dateTime(r.decidedAt)}',
                icon: Icons.how_to_reg_rounded),
          if (r.worksheetId != null)
            InfoRow(l10n.invWorksheet, l10n.commonOpen,
                icon: Icons.handyman_rounded, onTap: () => context.push('/work/${r.worksheetId}')),
        ]),
      ],
    );

    return Column(children: [
      Expanded(child: list),
      if (actions.isNotEmpty) StickyActionBar(children: actions),
    ]);
  }
}
