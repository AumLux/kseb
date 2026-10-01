import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/application/session_controller.dart';
import '../../org/data/org_repository.dart';
import '../../staff/presentation/staff_form_page.dart' show assignableSections;
import '../data/inventory_repository.dart';
import '../../../core/ui/sheets.dart';
import '../../org/presentation/section_picker.dart';

/// Material catalogue (managers+). Codes are permanent once created.
class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final catalog = ref.watch(catalogProvider);
    Future<void> edit([CatalogItem? item]) async {
      final saved = await showModalBottomSheet<bool>(
          context: context, isScrollControlled: true, builder: (_) => _MaterialForm(item: item));
      if (saved == true) ref.invalidate(catalogProvider);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invCatalog)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => edit(),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.invAddMaterial),
      ),
      body: switch (catalog) {
        AsyncData(:final value) => LazyListView(padding: const EdgeInsets.only(bottom: 96), itemCount: value.length,
            itemBuilder: (context, i) {
              final m = value[i];
              return AppListRow(
                title: m.name,
                subtitle: '${m.code} · ${m.category} · ${l10n.invReorderAt(Fmt.qty(m.reorderLevel, unit: m.unit))}',
                onTap: () => edit(m),
              );
            }),
        AsyncError(:final error) => ErrorState(title: failureMessage(l10n, error), onRetry: () => ref.invalidate(catalogProvider)),
        _ => const LoadingView(),
      },
    );
  }
}

class _MaterialForm extends ConsumerStatefulWidget {
  const _MaterialForm({this.item});

  final CatalogItem? item;

  @override
  ConsumerState<_MaterialForm> createState() => _MaterialFormState();
}

class _MaterialFormState extends ConsumerState<_MaterialForm> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.item?.code);
  late final _name = TextEditingController(text: widget.item?.name);
  late final _category = TextEditingController(text: widget.item?.category);
  late final _hsn = TextEditingController(text: widget.item?.hsnCode);
  late final _reorder = TextEditingController(text: widget.item == null ? '0' : Fmt.qty(widget.item!.reorderLevel).replaceAll(',', ''));
  late String _unit = widget.item?.unit ?? 'nos';
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_code, _name, _category, _hsn, _reorder]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref.read(inventoryRepositoryProvider).saveMaterial(
            id: widget.item?.id,
            code: _code.text,
            name: _name.text,
            category: _category.text,
            unit: _unit,
            reorderLevel: num.tryParse(_reorder.text) ?? 0,
            hsn: _hsn.text,
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.item?.name ?? l10n.invAddMaterial, style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.invCode,
              controller: _code,
              required: true,
              enabled: widget.item == null,
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: l10n.invName, controller: _name, required: true),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: l10n.invCategory, controller: _category, required: true),
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              Expanded(
                child: AppDropdownField<String>(
                  label: l10n.invUnit,
                  items: CatalogItem.units,
                  value: _unit,
                  itemLabel: (u) => u,
                  onChanged: (u) => setState(() => _unit = u ?? _unit),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  label: l10n.invReorderLevel,
                  controller: _reorder,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.md),
            AppTextField(label: l10n.invHsn, controller: _hsn, keyboardType: TextInputType.number),
            const SizedBox(height: AppSpacing.xl),
            AppButton(label: l10n.commonSave, expand: true, loading: _busy, onPressed: _save),
          ]),
        ),
      ),
    );
  }
}

/// Stores per section (managers+).
class StoresPage extends ConsumerWidget {
  const StoresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final stores = ref.watch(storesProvider);
    final tree = ref.watch(orgTreeProvider).value;
    final sections = tree == null ? const <OrgUnit>[] : assignableSections(me, tree);

    Future<void> add() async {
      final name = TextEditingController();
      String? sectionId = sections.length == 1 ? sections.single.id : null;
      final ok = await showAppSheet<bool>(
        context,
        builder: (context) => DisposeWith(
          controllers: [name],
          child: StatefulBuilder(
          builder: (context, setLocal) => SheetScaffold(
            title: l10n.invAddStore,
            primaryLabel: l10n.commonSave,
            onPrimary: () => Navigator.pop(context, true),
            secondaryLabel: l10n.commonCancel,
            onSecondary: () => Navigator.pop(context, false),
            children: [
              SectionPickerField(
                label: l10n.staffSection,
                allowed: sections,
                value: sectionId,
                onChanged: (v) => setLocal(() => sectionId = v),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(label: l10n.invStoreName, controller: name),
            ],
          ),
        ),
        ),
      );
      final storeName = name.text.trim(); // read now: the sheet disposes `name`
      if (ok == true && sectionId != null && storeName.length > 1) {
        try {
          await ref.read(inventoryRepositoryProvider).addStore(sectionId!, storeName);
          ref.invalidate(storesProvider);
        } catch (e) {
          if (context.mounted) showSnack(context, failureMessage(l10n, e));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invStores)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.add_business_rounded),
        label: Text(l10n.invAddStore),
      ),
      body: switch (stores) {
        AsyncData(:final value) => LazyListView(itemCount: value.length,
            itemBuilder: (context, i) {
              final s = value[i];
              return AppListRow(
                leading: const Icon(Icons.warehouse_rounded, color: AppColors.inkMute),
                title: s.name,
                subtitle: tree?.byId(s.sectionId)?.name,
              );
            }),
        AsyncError(:final error) => ErrorState(title: failureMessage(l10n, error), onRetry: () => ref.invalidate(storesProvider)),
        _ => const LoadingView(),
      },
    );
  }
}
