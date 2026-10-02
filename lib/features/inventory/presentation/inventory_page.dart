import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../org/data/org_repository.dart';
import '../data/inventory_repository.dart';
import 'inventory_labels.dart';
import 'stock_register_export.dart';
import '../../../core/ui/sheets.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final isManager = me.role.atLeast(AppRole.manager);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.invTitle),
          actions: [
            if (isManager)
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'catalog':
                      context.push('/more/inventory/catalog');
                    case 'stores':
                      context.push('/more/inventory/stores');
                    case 'register':
                      exportStockRegister(context, ref);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'catalog', child: Text(l10n.invCatalog)),
                  PopupMenuItem(value: 'stores', child: Text(l10n.invStores)),
                  PopupMenuItem(value: 'register', child: Text(l10n.invExportRegister)),
                ],
              ),
          ],
          bottom: TabBar(tabs: [Tab(text: l10n.invStock), Tab(text: l10n.invRequests)]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/more/inventory/new');
            ref
              ..invalidate(materialRequestsProvider)
              ..invalidate(stockProvider);
          },
          icon: const Icon(Icons.add_rounded),
          label: Text(l10n.invNewRequest),
        ),
        body: const TabBarView(children: [_StockTab(), _RequestsTab()]),
      ),
    );
  }
}

class _StockTab extends ConsumerStatefulWidget {
  const _StockTab();

  @override
  ConsumerState<_StockTab> createState() => _StockTabState();
}

class _StockTabState extends ConsumerState<_StockTab> {
  String _query = '';
  String? _storeId;
  bool _lowOnly = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stock = ref.watch(stockProvider);
    final stores = ref.watch(storesProvider).value ?? const <Store>[];

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
        child: TextField(
          decoration: InputDecoration(hintText: l10n.invSearch, prefixIcon: const Icon(Icons.search_rounded)),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
      ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(children: [
          if (stores.length > 1)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: DropdownButton<String?>(
                value: _storeId,
                underline: const SizedBox.shrink(),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.invAllStores)),
                  for (final s in stores) DropdownMenuItem(value: s.id, child: Text(s.name)),
                ],
                onChanged: (v) => setState(() => _storeId = v),
              ),
            ),
          FilterChip(
            label: Text(l10n.invLowOnly),
            selected: _lowOnly,
            onSelected: (v) => setState(() => _lowOnly = v),
          ),
        ]),
      ),
      Expanded(
        child: switch (stock) {
          AsyncData(:final value) => _list(context, value
              .where((s) => _storeId == null || s.storeId == _storeId)
              .where((s) => !_lowOnly || s.lowStock)
              .where((s) =>
                  _query.isEmpty ||
                  s.materialName.toLowerCase().contains(_query) ||
                  s.materialCode.toLowerCase().contains(_query))
              .toList()),
          AsyncError(:final error) => ErrorState(
              title: l10n.commonSomethingWrong,
              message: failureMessage(l10n, error),
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(stockProvider),
            ),
          _ => const LoadingView(),
        },
      ),
    ]);
  }

  Widget _list(BuildContext context, List<StockLine> lines) {
    final l10n = context.l10n;
    if (lines.isEmpty) {
      return EmptyState(icon: Icons.inventory_2_outlined, title: l10n.invNoStock, message: l10n.invNoStockHint);
    }
    return RefreshIndicator(
      onRefresh: () => ref.refresh(stockProvider.future),
      child: LazyListView(
        padding: const EdgeInsets.only(bottom: 96),
        itemCount: lines.length,
          itemBuilder: (context, i) {
            final s = lines[i];
            return AppListRow(
              leading: IconTile(Icons.inventory_2_rounded, color: s.lowStock ? AppColors.warning : AppColors.info),
              title: s.materialName,
              subtitle: '${s.materialCode} · ${s.storeName}',
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(Fmt.qty(s.onHand, unit: s.unit), style: AppTypography.bodyTabular),
                  if (s.lowStock) StatusChip(label: l10n.invLow, tone: StatusTone.warning, dense: true),
                ],
              ),
              onTap: () => showModalBottomSheet<void>(
                context: context,
                useRootNavigator: true,
                isScrollControlled: true,
                builder: (_) => _StockLineSheet(line: s),
              ),
            );
          },
      ),
    );
  }
}

/// Movement history for one material in one store, with manager tools.
class _StockLineSheet extends ConsumerStatefulWidget {
  const _StockLineSheet({required this.line});

  final StockLine line;

  @override
  ConsumerState<_StockLineSheet> createState() => _StockLineSheetState();
}

class _StockLineSheetState extends ConsumerState<_StockLineSheet> {
  bool _busy = false;

  Future<void> _adjust({required bool scrap}) async {
    final l10n = context.l10n;
    final result = await showAppSheet<(num, String)>(
      context,
      builder: (_) => _QtyReasonDialog(
        title: scrap ? l10n.invScrap : l10n.invAdjust,
        help: scrap ? null : l10n.invAdjustHelp,
        allowNegative: !scrap,
      ),
    );
    if (result == null) return;
    await _run(() => ref.read(inventoryRepositoryProvider).adjust(
        widget.line.materialId, widget.line.storeId, scrap ? -result.$1.abs() : result.$1, result.$2,
        scrap: scrap));
  }

  Future<void> _transfer() async {
    final l10n = context.l10n;
    final stores = (ref.read(storesProvider).value ?? const <Store>[])
        .where((s) => s.id != widget.line.storeId && s.active)
        .toList();
    String? to = stores.isEmpty ? null : stores.first.id;
    final qty = TextEditingController();
    final ok = await showAppSheet<bool>(
      context,
      builder: (context) => DisposeWith(
        controllers: [qty],
        child: StatefulBuilder(
        builder: (context, setLocal) => SheetScaffold(
          title: l10n.invTransfer,
          primaryLabel: l10n.invTransfer,
          onPrimary: () => Navigator.pop(context, true),
          secondaryLabel: l10n.commonCancel,
          onSecondary: () => Navigator.pop(context, false),
          children: [
            AppDropdownField<String>(
              label: l10n.invToStore,
              items: stores.map((s) => s.id).toList(),
              value: to,
              itemLabel: (id) => stores.firstWhere((s) => s.id == id).name,
              onChanged: (v) => setLocal(() => to = v),
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              label: l10n.invQuantity,
              controller: qty,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      ),
    );
    final n = num.tryParse(qty.text); // read now: the sheet disposes `qty`
    if (ok != true || to == null || n == null || n <= 0) return;
    await _run(() => ref.read(inventoryRepositoryProvider).transfer(widget.line.materialId, widget.line.storeId, to!, n));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref
        ..invalidate(stockProvider)
        ..invalidate(ledgerProvider((materialId: widget.line.materialId, storeId: widget.line.storeId)));
      if (mounted) showSnack(context, context.l10n.staffSaved);
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
    final l = widget.line;
    final ledger = ref.watch(ledgerProvider((materialId: l.materialId, storeId: l.storeId)));
    final stockNow = ref.watch(stockProvider).value;
    final onHand = stockNow == null ? l.onHand : onHandFor(stockNow, l.materialId, l.storeId);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.materialName, style: AppTypography.subtitle),
                Text('${l.materialCode} · ${l.storeName}', style: AppTypography.caption),
                const SizedBox(height: AppSpacing.md),
                Row(children: [
                  Expanded(child: KpiCard(label: l10n.invOnHand, value: Fmt.qty(onHand, unit: l.unit))),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: KpiCard(label: l10n.invReorderLevel, value: Fmt.qty(l.reorderLevel, unit: l.unit)),
                  ),
                ]),
                if (me.role.atLeast(AppRole.manager)) ...[
                  const SizedBox(height: AppSpacing.md),
                  Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                    AppButton.secondary(
                        label: l10n.invAdjust, icon: Icons.tune_rounded, onPressed: _busy ? null : () => _adjust(scrap: false)),
                    AppButton.secondary(
                        label: l10n.invTransfer, icon: Icons.swap_horiz_rounded, onPressed: _busy ? null : _transfer),
                    AppButton.tertiary(label: l10n.invScrap, onPressed: _busy ? null : () => _adjust(scrap: true)),
                  ]),
                ],
              ]),
            ),
            SectionHeader(l10n.invLedger),
            Expanded(
              child: switch (ledger) {
                AsyncData(:final value) when value.isEmpty =>
                  Center(child: Text(l10n.invLedgerEmpty, style: AppTypography.caption)),
                AsyncData(:final value) => LazyListView(itemCount: value.length,
                    itemBuilder: (context, i) {
                      final e = value[i];
                      return AppListRow(
                        leading: IconTile(e.qtyDelta > 0 ? Icons.south_west_rounded : Icons.north_east_rounded,
                            color: e.qtyDelta > 0 ? AppColors.success : AppColors.danger),
                        title: txnLabel(l10n, e.txnType),
                        subtitle: [Fmt.dateTime(e.createdAt), ?e.note].join(' · '),
                        trailing: Text(
                          signedQty(e.qtyDelta, l.unit),
                          style: AppTypography.bodyTabular
                              .copyWith(color: e.qtyDelta > 0 ? AppColors.success : AppColors.danger),
                        ),
                      );
                    }),
                AsyncError(:final error) => ErrorState(title: failureMessage(l10n, error)),
                _ => const LoadingView(),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _QtyReasonDialog extends StatefulWidget {
  const _QtyReasonDialog({required this.title, this.help, required this.allowNegative});

  final String title;
  final String? help;
  final bool allowNegative;

  @override
  State<_QtyReasonDialog> createState() => _QtyReasonDialogState();
}

class _QtyReasonDialogState extends State<_QtyReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _qty.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: SheetScaffold(
        title: widget.title,
        subtitle: widget.help,
        primaryLabel: l10n.commonSave,
        onPrimary: () {
          if (_formKey.currentState?.validate() ?? false) {
            Navigator.pop(context, (num.parse(_qty.text), _reason.text.trim()));
          }
        },
        secondaryLabel: l10n.commonCancel,
        onSecondary: () => Navigator.pop(context),
        children: [
          AppTextField(
            label: l10n.invQuantity,
            controller: _qty,
            required: true,
            keyboardType: TextInputType.numberWithOptions(decimal: true, signed: widget.allowNegative),
            validator: (v) {
              final n = num.tryParse(v ?? '');
              return (n == null || n == 0) ? l10n.invQtyInvalid : null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: l10n.attReason,
            controller: _reason,
            required: true,
            validator: (v) => (v?.trim().length ?? 0) >= 5 ? null : l10n.attReasonTooShort,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

enum _ReqFilter { mine, toDecide, all }

class _RequestsTab extends ConsumerStatefulWidget {
  const _RequestsTab();

  @override
  ConsumerState<_RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<_RequestsTab> {
  _ReqFilter? _filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final isLead = me.role.atLeast(AppRole.supervisor);
    final filter = _filter ?? (isLead ? _ReqFilter.toDecide : _ReqFilter.mine);
    final requests = ref.watch(materialRequestsProvider);
    final people = ref.watch(directoryProvider).value ?? const <Person>[];

    bool canDecide(MaterialRequest r) {
      final requester = people.where((p) => p.id == r.requestedBy).firstOrNull;
      return r.status == 'pending' && r.requestedBy != me.id && requester != null && me.role.outranks(requester.role);
    }

    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
        child: Row(children: [
          for (final f in isLead ? _ReqFilter.values : [_ReqFilter.mine])
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: ChoiceChip(
                label: Text(switch (f) {
                  _ReqFilter.mine => l10n.invMineFilter,
                  _ReqFilter.toDecide => l10n.invToDecide,
                  _ReqFilter.all => l10n.invAllFilter,
                }),
                selected: filter == f,
                onSelected: (_) => setState(() => _filter = f),
              ),
            ),
        ]),
      ),
      Expanded(
        child: switch (requests) {
          AsyncData(:final value) => () {
              final list = value
                  .where((r) => switch (filter) {
                        _ReqFilter.mine => r.requestedBy == me.id,
                        _ReqFilter.toDecide => canDecide(r),
                        _ReqFilter.all => true,
                      })
                  .toList();
              if (list.isEmpty) return EmptyState(icon: Icons.receipt_long_outlined, title: l10n.invRequestsEmpty);
              return RefreshIndicator(
                onRefresh: () => ref.refresh(materialRequestsProvider.future),
                child: LazyListView(padding: const EdgeInsets.only(bottom: 96), itemCount: list.length,
                  itemBuilder: (context, i) {
                    final r = list[i];
                    return AppListRow(
                      leading: IconTile(switch (r.type.name) {
                        'receipt' => Icons.move_to_inbox_rounded,
                        'issue' => Icons.outbox_rounded,
                        _ => Icons.assignment_return_rounded,
                      }, color: AppColors.info),
                      title: '${requestTypeLabel(l10n, r.type)} · ${r.materialName}',
                      subtitle: [r.code, Fmt.qty(r.quantity, unit: r.unit), r.storeName].join(' · '),
                      trailing: requestChip(l10n, r.status),
                      onTap: () => context.push('/more/inventory/requests/${r.id}'),
                    );
                  }),
              );
            }(),
          AsyncError(:final error) => ErrorState(
              title: l10n.commonSomethingWrong,
              message: failureMessage(l10n, error),
              retryLabel: l10n.commonRetry,
              onRetry: () => ref.invalidate(materialRequestsProvider),
            ),
          _ => const LoadingView(),
        },
      ),
    ]);
  }
}
