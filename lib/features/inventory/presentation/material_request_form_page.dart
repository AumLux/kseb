import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/format/ist.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../worksheets/data/worksheet_repository.dart';
import '../data/inventory_repository.dart';
import 'inventory_labels.dart';

class MaterialRequestFormPage extends ConsumerStatefulWidget {
  const MaterialRequestFormPage({super.key, this.worksheetId});

  /// Pre-links the request to a job (from the worksheet screen).
  final String? worksheetId;

  @override
  ConsumerState<MaterialRequestFormPage> createState() => _MaterialRequestFormPageState();
}

class _MaterialRequestFormPageState extends ConsumerState<MaterialRequestFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _qty = TextEditingController();
  final _price = TextEditingController();
  final _supplier = TextEditingController();
  final _invoice = TextEditingController();
  final _purpose = TextEditingController();
  MaterialRequestType _type = MaterialRequestType.issue;
  String? _storeId;
  CatalogItem? _material;
  late String? _worksheetId = widget.worksheetId;
  Priority _priority = Priority.medium;
  DateTime? _requiredBy;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_qty, _price, _supplier, _invoice, _purpose]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickMaterial(List<CatalogItem> items) async {
    final picked = await showModalBottomSheet<CatalogItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MaterialPicker(items: items),
    );
    if (picked != null) setState(() => _material = picked);
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false) || _material == null) return;
    setState(() => _busy = true);
    try {
      final synced = await ref.read(inventoryRepositoryProvider).submit(
            MaterialRequestDraft(
              type: _type,
              materialId: _material!.id,
              storeId: _storeId!,
              quantity: num.parse(_qty.text),
              purpose: _purpose.text,
              priority: _priority,
              unitPrice: num.tryParse(_price.text),
              supplier: _supplier.text,
              invoiceRef: _invoice.text,
              worksheetId: _worksheetId,
              requiredBy: _requiredBy,
            ),
            label: '${requestTypeLabel(l10n, _type)} · ${_material!.name}',
          );
      if (!mounted) return;
      showSnack(context, synced ? l10n.invRequestSent : l10n.attQueued);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final stores = (ref.watch(storesProvider).value ?? const <Store>[]).where((s) => s.active).toList();
    final catalog = (ref.watch(catalogProvider).value ?? const <CatalogItem>[]).where((m) => m.active).toList();
    final stock = ref.watch(stockProvider).value ?? const <StockLine>[];
    final worksheets = (ref.watch(worksheetsProvider(WorksheetScope.mine)).value ?? const <Worksheet>[])
        .where((w) => w.status == WorksheetStatus.approved || w.status == WorksheetStatus.inProgress || w.id == _worksheetId)
        .toList();
    _storeId ??= stores.length == 1 ? stores.single.id : null;
    final available = (_material != null && _storeId != null) ? onHandFor(stock, _material!.id, _storeId!) : null;
    final types = [
      MaterialRequestType.issue,
      MaterialRequestType.ret,
      if (me.role.atLeast(AppRole.supervisor)) MaterialRequestType.receipt,
    ];
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invNewRequest)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  RadioGroup<MaterialRequestType>(
                    groupValue: _type,
                    onChanged: (v) => setState(() => _type = v ?? _type),
                    child: Column(children: [
                      for (final t in types)
                        RadioListTile<MaterialRequestType>(
                          contentPadding: EdgeInsets.zero,
                          value: t,
                          title: Text(switch (t) {
                            MaterialRequestType.issue => l10n.invReqIssue,
                            MaterialRequestType.ret => l10n.invReqReturn,
                            MaterialRequestType.receipt => l10n.invReqReceipt,
                          }),
                        ),
                    ]),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdownField<String>(
                    label: l10n.invStore,
                    required: true,
                    items: stores.map((s) => s.id).toList(),
                    value: _storeId,
                    itemLabel: (id) => stores.firstWhere((s) => s.id == id).name,
                    onChanged: (v) => setState(() => _storeId = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    key: ValueKey(_material?.id),
                    label: l10n.invMaterial,
                    required: true,
                    initialValue: _material == null ? '' : '${_material!.name} (${_material!.code})',
                    readOnly: true,
                    onTap: () => _pickMaterial(catalog),
                    suffix: const Icon(Icons.search_rounded),
                    validator: (_) => _material == null ? l10n.fieldRequired(l10n.invMaterial) : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: _material == null ? l10n.invQuantity : '${l10n.invQuantity} (${_material!.unit})',
                    helper: available == null || _type == MaterialRequestType.receipt
                        ? null
                        : l10n.invAvailable(Fmt.qty(available, unit: _material!.unit)),
                    controller: _qty,
                    required: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: decimal,
                    validator: (v) {
                      final n = num.tryParse(v ?? '');
                      return (n == null || n <= 0) ? l10n.invQtyInvalid : null;
                    },
                  ),
                  if (_type == MaterialRequestType.receipt) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(
                      label: l10n.invUnitPrice,
                      controller: _price,
                      required: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: decimal,
                      validator: (v) => num.tryParse(v ?? '') == null ? l10n.fieldRequired(l10n.invUnitPrice) : null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(label: l10n.invSupplier, controller: _supplier, required: true),
                    const SizedBox(height: AppSpacing.lg),
                    AppTextField(label: l10n.invInvoice, controller: _invoice),
                  ] else ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppDropdownField<String?>(
                      label: l10n.invWorksheet,
                      items: [null, ...worksheets.map((w) => w.id)],
                      value: _worksheetId,
                      itemLabel: (id) {
                        if (id == null) return l10n.invNoWorksheet;
                        final w = worksheets.where((w) => w.id == id).firstOrNull;
                        return w == null ? id : '${w.code} · ${w.title}';
                      },
                      onChanged: (v) => setState(() => _worksheetId = v),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.invPurpose,
                    controller: _purpose,
                    required: true,
                    maxLines: 2,
                    validator: (v) => (v?.trim().length ?? 0) >= 3 ? null : l10n.fieldRequired(l10n.invPurpose),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(l10n.invPriority, style: AppTypography.label),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(spacing: AppSpacing.sm, children: [
                    for (final p in Priority.values)
                      ChoiceChip(
                        label: Text(priorityLabel(l10n, p)),
                        selected: _priority == p,
                        onSelected: (_) => setState(() => _priority = p),
                      ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    key: ValueKey(_requiredBy),
                    label: l10n.invRequiredBy,
                    initialValue: _requiredBy == null ? '' : Fmt.date(_requiredBy),
                    readOnly: true,
                    suffix: const Icon(Icons.calendar_today_rounded),
                    onTap: () async {
                      final d = await showDatePicker(
                          context: context,
                          initialDate: Ist.today(),
                          firstDate: Ist.today(),
                          lastDate: Ist.today().add(const Duration(days: 180)));
                      if (d != null) setState(() => _requiredBy = d);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(label: l10n.invSubmit, icon: Icons.send_rounded, expand: true, loading: _busy, onPressed: _submit),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MaterialPicker extends StatefulWidget {
  const _MaterialPicker({required this.items});

  final List<CatalogItem> items;

  @override
  State<_MaterialPicker> createState() => _MaterialPickerState();
}

class _MaterialPickerState extends State<_MaterialPicker> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final list = widget.items
        .where((m) => _q.isEmpty || m.name.toLowerCase().contains(_q) || m.code.toLowerCase().contains(_q))
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.invSearch, prefixIcon: const Icon(Icons.search_rounded)),
              onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: ListView(children: [
              for (final m in list)
                AppListRow(
                  title: m.name,
                  subtitle: '${m.code} · ${m.category} · ${m.unit}',
                  onTap: () => Navigator.pop(context, m),
                ),
            ]),
          ),
        ]),
      ),
    );
  }
}
