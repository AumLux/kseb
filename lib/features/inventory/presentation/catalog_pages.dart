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

/// Icon and tint for a material category (free text, so match loosely).
(IconData, Color) categoryStyle(String category) {
  final c = category.toLowerCase();
  if (c.contains('pole')) return (Icons.vertical_align_top_rounded, AppColors.primaryDeep);
  if (c.contains('cable') || c.contains('conductor') || c.contains('wire')) return (Icons.cable_rounded, AppColors.info);
  if (c.contains('meter')) return (Icons.speed_rounded, AppColors.success);
  if (c.contains('insulat')) return (Icons.blur_circular_rounded, AppColors.brandOrangeInk);
  if (c.contains('protect') || c.contains('arrest') || c.contains('fuse')) return (Icons.shield_rounded, AppColors.ruby);
  if (c.contains('transformer')) return (Icons.electrical_services_rounded, AppColors.warning);
  if (c.contains('hardware') || c.contains('fitting')) return (Icons.hardware_rounded, AppColors.inkSecondary);
  return (Icons.category_rounded, AppColors.inkSecondary);
}

/// Material catalogue (managers+). Codes are permanent once created.
class CatalogPage extends ConsumerStatefulWidget {
  const CatalogPage({super.key});

  @override
  ConsumerState<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends ConsumerState<CatalogPage> {
  String _q = '';
  String? _category;

  Future<void> _edit([CatalogItem? item]) async {
    final saved = await showAppSheet<bool>(context, builder: (_) => _MaterialForm(item: item));
    if (saved == true) ref.invalidate(catalogProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = ref.watch(catalogProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invCatalog)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.invAddMaterial),
      ),
      body: switch (catalog) {
        AsyncData(:final value) => _list(context, value),
        AsyncError(:final error) => ErrorState(title: failureMessage(l10n, error), onRetry: () => ref.invalidate(catalogProvider)),
        _ => const LoadingView(),
      },
    );
  }

  Widget _list(BuildContext context, List<CatalogItem> all) {
    final l10n = context.l10n;
    final categories = {for (final m in all) m.category}.toList()..sort();
    final q = _q.toLowerCase();
    final shown = all
        .where((m) => _category == null || m.category == _category)
        .where((m) => q.isEmpty || m.name.toLowerCase().contains(q) || m.code.toLowerCase().contains(q))
        .toList();
    final groups = <String, List<CatalogItem>>{};
    for (final m in shown) {
      groups.putIfAbsent(m.category, () => []).add(m);
    }
    final keys = groups.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () => ref.refresh(catalogProvider.future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
        children: [
          StatStrip(items: [
            StatItem(label: l10n.invCountMaterials, value: '${all.length}'),
            StatItem(label: l10n.invCountCategories, value: '${categories.length}'),
          ]),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: l10n.invSearch),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              for (final c in [null, ...categories])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(c ?? l10n.invAllFilter),
                    selected: _category == c,
                    onSelected: (_) => setState(() => _category = c),
                  ),
                ),
            ]),
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: EmptyState(icon: Icons.search_off_rounded, title: l10n.invNoMatches),
            ),
          for (final (i, k) in keys.indexed)
            FadeSlideIn(
              index: i,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.sm),
                  child: Text('${k.toUpperCase()} · ${groups[k]!.length}', style: AppTypography.overline),
                ),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(children: [
                    for (final (j, m) in groups[k]!.indexed)
                      AppListRow(
                        leading: IconTile(categoryStyle(m.category).$1, color: categoryStyle(m.category).$2),
                        title: m.name,
                        subtitle: '${m.code} · ${l10n.invReorderAt(Fmt.qty(m.reorderLevel, unit: m.unit))}',
                        showDivider: j < groups[k]!.length - 1,
                        dividerIndent: AppSpacing.lg + 40 + AppSpacing.md,
                        onTap: () => _edit(m),
                      ),
                  ]),
                ),
              ]),
            ),
        ],
      ),
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
    final (icon, tint) = categoryStyle(_category.text);
    return Form(
      key: _formKey,
      child: SheetScaffold(
        title: widget.item?.name ?? l10n.invAddMaterial,
        subtitle: widget.item?.code,
        leading: IconTile(icon, color: tint, size: 48),
        primaryLabel: l10n.commonSave,
        busy: _busy,
        onPrimary: _save,
        children: [
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
          AppTextField(
            label: l10n.invCategory,
            controller: _category,
            required: true,
            onChanged: (_) => setState(() {}),
          ),
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
          const SizedBox(height: AppSpacing.lg),
        ],
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
    final stock = ref.watch(stockProvider).value ?? const <StockLine>[];
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
        AsyncData(:final value) when value.isEmpty =>
          EmptyState(icon: Icons.warehouse_rounded, title: l10n.invNoStores),
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () {
              ref.invalidate(stockProvider);
              return ref.refresh(storesProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 96),
              children: [
                FadeSlideIn(
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      for (final (i, s) in value.indexed)
                        Builder(builder: (context) {
                          final lines = stock.where((l) => l.storeId == s.id);
                          final low = lines.where((l) => l.lowStock).length;
                          return AppListRow(
                            leading: IconTile(Icons.warehouse_rounded, color: s.active ? AppColors.info : AppColors.inkMute),
                            title: s.name,
                            subtitle: [
                              tree?.byId(s.sectionId)?.name ?? '—',
                              l10n.invStoreMaterials(lines.length),
                            ].join(' · '),
                            trailing: low > 0
                                ? StatusChip(label: l10n.invStoreLow(low), tone: StatusTone.warning, dense: true)
                                : null,
                            showDivider: i < value.length - 1,
                            dividerIndent: AppSpacing.lg + 40 + AppSpacing.md,
                          );
                        }),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        AsyncError(:final error) => ErrorState(title: failureMessage(l10n, error), onRetry: () => ref.invalidate(storesProvider)),
        _ => const LoadingView(),
      },
    );
  }
}
