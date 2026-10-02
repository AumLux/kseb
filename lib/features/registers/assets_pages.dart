import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/l10n.dart';
import '../../core/media/photo_strip.dart';
import '../../core/ui/dialogs.dart';
import '../auth/application/session_controller.dart';
import '../auth/domain/app_user.dart';
import '../org/data/org_repository.dart';
import '../staff/presentation/staff_form_page.dart' show assignableSections;
import 'registers_labels.dart';
import 'registers_repository.dart';
import '../../core/ui/sheets.dart';
import '../org/presentation/section_picker.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../../core/maps/app_map.dart';

class AssetsPage extends ConsumerStatefulWidget {
  const AssetsPage({super.key});

  @override
  ConsumerState<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends ConsumerState<AssetsPage> {
  String _q = '';
  String? _category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final assets = ref.watch(assetsProvider);
    final people = ref.watch(directoryProvider).value ?? const <Person>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.assetTitle)),
      floatingActionButton: me.role.atLeast(AppRole.manager)
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/more/assets/new');
                ref.invalidate(assetsProvider);
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.assetNew),
            )
          : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: TextField(
            decoration: InputDecoration(hintText: l10n.assetSearch, prefixIcon: const Icon(Icons.search_rounded)),
            onChanged: (v) => setState(() => _q = v.trim()),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(children: [
            for (final c in [null, ...assetCategories])
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ChoiceChip(
                  label: Text(c == null ? l10n.staffFilterAll : assetCategoryLabel(l10n, c)),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c),
                ),
              ),
          ]),
        ),
        Expanded(
          child: switch (assets) {
            AsyncData(:final value) => () {
                final list = value.where((a) => (_category == null || a.category == _category) && a.matches(_q)).toList();
                if (list.isEmpty) return EmptyState(icon: Icons.devices_other_rounded, title: l10n.assetEmpty);
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(assetsProvider.future),
                  child: LazyListView(padding: const EdgeInsets.only(bottom: 96), itemCount: list.length,
                    itemBuilder: (context, i) {
                      final a = list[i];
                      return AppListRow(
                        leading: const IconTile(Icons.devices_other_rounded, color: AppColors.info),
                        title: '${a.tag} · ${a.name}',
                        subtitle: [
                          assetCategoryLabel(l10n, a.category),
                          ?a.rating,
                          ?people.where((p) => p.id == a.assignedTo).firstOrNull?.fullName,
                        ].join(' · '),
                        trailing: assetStatusChip(l10n, a.status),
                        onTap: () => context.push('/more/assets/${a.id}'),
                      );
                    }),
                );
              }(),
            AsyncError(:final error) => ErrorState(
                title: l10n.commonSomethingWrong,
                message: failureMessage(l10n, error),
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(assetsProvider),
              ),
            _ => const LoadingView(),
          },
        ),
      ]),
    );
  }
}

class AssetFormPage extends ConsumerStatefulWidget {
  const AssetFormPage({super.key, this.assetId});

  final String? assetId;

  @override
  ConsumerState<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends ConsumerState<AssetFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tag = TextEditingController();
  final _name = TextEditingController();
  final _serial = TextEditingController();
  final _make = TextEditingController();
  final _rating = TextEditingController();
  final _location = TextEditingController();
  final _value = TextEditingController();
  final _notes = TextEditingController();
  String _category = 'transformer';
  String _condition = 'new';
  String _status = 'in_store';
  String? _sectionId;
  DateTime? _purchased;
  bool _busy = false;
  bool _loaded = false;

  bool get _isEdit => widget.assetId != null;

  @override
  void dispose() {
    for (final c in [_tag, _name, _serial, _make, _rating, _location, _value, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(Asset a) {
    if (_loaded) return;
    _loaded = true;
    _tag.text = a.tag;
    _name.text = a.name;
    _serial.text = a.serialNo ?? '';
    _make.text = a.make ?? '';
    _rating.text = a.rating ?? '';
    _location.text = a.locationText ?? '';
    _value.text = a.purchaseValue?.toString() ?? '';
    _notes.text = a.notes ?? '';
    _category = a.category;
    _condition = a.condition;
    _status = a.status;
    _sectionId = a.sectionId;
    _purchased = a.purchaseDate;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    String? blank(String s) => s.trim().isEmpty ? null : s.trim();
    final common = {
      'name': _name.text.trim(),
      'serial_no': blank(_serial.text),
      'make': blank(_make.text),
      'rating': blank(_rating.text),
      'location_text': blank(_location.text),
      'purchase_date': RegistersRepository.isoOrNull(_purchased),
      'purchase_value': num.tryParse(_value.text),
      'notes': blank(_notes.text),
    };
    final repo = ref.read(registersRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateAsset(widget.assetId!, common);
        ref
          ..invalidate(assetProvider(widget.assetId!))
          ..invalidate(assetsProvider);
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final id = await repo.registerAsset({
          ...common,
          'asset_tag': _tag.text.trim().toUpperCase(),
          'category': _category,
          'section_id': _sectionId,
          'condition': _condition,
          'status': _status,
        });
        if (!mounted) return;
        // The list's `await push` never returns past pushReplacement.
        ref.invalidate(assetsProvider);
        context.pushReplacement('/more/assets/$id');
      }
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
    final tree = ref.watch(orgTreeProvider).value;
    final sections = tree == null ? const <OrgUnit>[] : assignableSections(me, tree);
    if (_isEdit) {
      if (ref.watch(assetProvider(widget.assetId!)) case AsyncData(:final value)) _fill(value);
      if (!_loaded) return Scaffold(appBar: AppBar(), body: const LoadingView());
    } else {
      _sectionId ??= sections.length == 1 ? sections.single.id : me.sectionId;
    }

    Widget chips(String label, List<String> values, String selected, String Function(String) text, ValueChanged<String> set) =>
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTypography.label),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
            for (final v in values) ChoiceChip(label: Text(text(v)), selected: selected == v, onSelected: (_) => setState(() => set(v))),
          ]),
          const SizedBox(height: AppSpacing.lg),
        ]);

    return Scaffold(
      bottomNavigationBar: StickyActionBar(children: [
        AppButton(label: l10n.commonSave, expand: true, loading: _busy, onPressed: _save),
      ]),
      appBar: AppBar(title: Text(_isEdit ? _tag.text : l10n.assetNew)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
            child: Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
                AppTextField(
                  label: l10n.assetTag,
                  controller: _tag,
                  required: true,
                  enabled: !_isEdit,
                  textCapitalization: TextCapitalization.characters,
                ),
                const SizedBox(height: AppSpacing.lg),
                if (!_isEdit) ...[
                  chips(l10n.assetCategory, assetCategories, _category, (v) => assetCategoryLabel(l10n, v), (v) => _category = v),
                  SectionPickerField(
                    label: l10n.staffSection,
                    required: true,
                    allowed: sections,
                    value: _sectionId,
                    onChanged: (v) => setState(() => _sectionId = v),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                AppTextField(label: l10n.assetName, controller: _name, required: true),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: l10n.assetSerial, controller: _serial),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Expanded(child: AppTextField(label: l10n.assetMake, controller: _make)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: AppTextField(label: l10n.assetRating, controller: _rating)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: l10n.assetLocation, controller: _location),
                const SizedBox(height: AppSpacing.lg),
                Row(children: [
                  Expanded(
                    child: AppTextField(
                      key: ValueKey(_purchased),
                      label: l10n.assetPurchaseDate,
                      initialValue: _purchased == null ? '' : Fmt.date(_purchased),
                      readOnly: true,
                      onTap: () async {
                        final d = await showDatePicker(
                            context: context, initialDate: _purchased ?? DateTime.now(), firstDate: DateTime(1980), lastDate: DateTime.now());
                        if (d != null) setState(() => _purchased = d);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppTextField(
                      label: l10n.assetPurchaseValue,
                      controller: _value,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    ),
                  ),
                ]),
                const SizedBox(height: AppSpacing.lg),
                if (!_isEdit) ...[
                  chips(l10n.assetCondition, assetConditions, _condition, (v) => assetConditionLabel(l10n, v), (v) => _condition = v),
                  chips(l10n.assetStatus, const ['in_store', 'deployed', 'under_repair'], _status, (v) => assetStatusLabel(l10n, v),
                      (v) => _status = v),
                ],
                AppTextField(label: l10n.assetNotes, controller: _notes, maxLines: 3),
]),
            ),
          ),
        ),
      ),
    );
  }
}

class AssetDetailPage extends ConsumerStatefulWidget {
  const AssetDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AssetDetailPage> createState() => _AssetDetailPageState();
}

class _AssetDetailPageState extends ConsumerState<AssetDetailPage> {
  bool _busy = false;

  Future<void> _event(Asset a, String type) async {
    final l10n = context.l10n;
    final me = ref.read(currentUserProvider)!;
    final people = ref.read(directoryProvider).value ?? const <Person>[];
    final tree = ref.read(orgTreeProvider).value;
    final sections = tree == null ? const <OrgUnit>[] : assignableSections(me, tree);
    final note = TextEditingController();
    String? pick = type == 'assigned' ? a.assignedTo : null;
    String? status = a.status, condition = a.condition;

    if (type == 'scrapped') {
      note.dispose(); // no sheet is shown for scrapping
      if (!await confirmAction(context, message: l10n.assetScrapConfirm, confirmLabel: l10n.assetEvScrap, destructive: true)) {
        return;
      }
    }
    if (!mounted) return;
    final ok = type == 'scrapped' ||
        (await showAppSheet<bool>(
              context,
              builder: (context) => DisposeWith(
                controllers: [note],
                child: StatefulBuilder(
                builder: (context, setLocal) => SheetScaffold(
                  title: switch (type) {
                    'assigned' => l10n.assetEvAssign,
                    'moved' => l10n.assetEvMove,
                    'inspected' => l10n.assetEvInspect,
                    'repaired' => l10n.assetEvRepair,
                    _ => l10n.assetEvStatus,
                  },
                  primaryLabel: l10n.commonSave,
                  onPrimary: () => Navigator.pop(context, true),
                  secondaryLabel: l10n.commonCancel,
                  onSecondary: () => Navigator.pop(context, false),
                  children: [
                      if (type == 'assigned')
                        AppDropdownField<String?>(
                          label: l10n.assetAssignedTo,
                          items: [null, ...people.where((p) => p.active && p.sectionId == a.sectionId).map((p) => p.id)],
                          value: pick,
                          itemLabel: (id) => id == null ? l10n.assetUnassigned : people.firstWhere((p) => p.id == id).fullName,
                          onChanged: (v) => setLocal(() => pick = v),
                        ),
                      if (type == 'moved')
                        SectionPickerField(
                          label: l10n.staffSection,
                          allowed: sections.where((s) => s.id != a.sectionId).toList(),
                          value: pick,
                          onChanged: (v) => setLocal(() => pick = v),
                        ),
                      if (type == 'status_changed')
                        AppDropdownField<String>(
                          label: l10n.assetStatus,
                          items: const ['in_store', 'deployed', 'under_repair', 'lost'],
                          value: status,
                          itemLabel: (v) => assetStatusLabel(l10n, v),
                          onChanged: (v) => setLocal(() => status = v),
                        ),
                      if (type == 'inspected' || type == 'repaired')
                        AppDropdownField<String>(
                          label: l10n.assetCondition,
                          items: assetConditions,
                          value: condition,
                          itemLabel: (v) => assetConditionLabel(l10n, v),
                          onChanged: (v) => setLocal(() => condition = v),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(label: l10n.assetNote, controller: note, maxLines: 2),
                  ],
                ),
              ),
              ),
            ) ??
            false);
    // Read now: the sheet disposes `note` once it has closed.
    final noteText = type == 'scrapped' ? '' : note.text.trim();
    if (!ok || (type == 'moved' && pick == null)) return;
    setState(() => _busy = true);
    try {
      await ref.read(registersRepositoryProvider).recordEvent(
            a.id,
            type,
            note: noteText.isEmpty ? null : noteText,
            toSectionId: type == 'moved' ? pick : null,
            assignedTo: type == 'assigned' ? pick : null,
            status: type == 'status_changed' ? status : null,
            condition: (type == 'inspected' || type == 'repaired') ? condition : null,
          );
      ref
        ..invalidate(assetProvider(a.id))
        ..invalidate(assetEventsProvider(a.id))
        ..invalidate(assetsProvider);
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
    final asset = ref.watch(assetProvider(widget.id));
    final events = ref.watch(assetEventsProvider(widget.id)).value ?? const <AssetEvent>[];
    final people = ref.watch(directoryProvider).value ?? const <Person>[];
    final tree = ref.watch(orgTreeProvider).value;
    String name(String? id) => people.where((p) => p.id == id).firstOrNull?.fullName ?? '—';

    return Scaffold(
      appBar: AppBar(
        title: Text(asset.value?.tag ?? l10n.assetTitle),
        actions: [
          if (asset.value != null && me.role.atLeast(AppRole.manager) && !asset.value!.scrapped)
            IconButton(
              tooltip: l10n.staffEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/more/assets/${widget.id}/edit'),
            ),
        ],
      ),
      body: switch (asset) {
        AsyncData(:final value) => ListView(padding: const EdgeInsets.only(bottom: AppSpacing.xxxl), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                FadeSlideIn(
                  child: DetailHeader(
                    icon: Icons.devices_other_rounded,
                    iconColor: AppColors.info,
                    title: value.name,
                    subtitle: [value.tag, ?tree?.byId(value.sectionId)?.name].join(' · '),
                    status: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
                      assetStatusChip(l10n, value.status),
                      StatusChip(label: assetConditionLabel(l10n, value.condition), dense: true),
                      StatusChip(label: assetCategoryLabel(l10n, value.category), tone: StatusTone.brand, dense: true),
                    ]),
                  ),
                ),
                if (me.role.atLeast(AppRole.supervisor) && !value.scrapped) ...[
                  const SizedBox(height: AppSpacing.lg),
                  // Round action tiles (Groww "Buy / Sell" row).
                  LayoutBuilder(builder: (context, c) {
                    final tiles = <(IconData, String, Color, String)>[
                      (Icons.person_add_alt_rounded, l10n.assetEvAssign, AppColors.primaryDeep, 'assigned'),
                      (Icons.fact_check_rounded, l10n.assetEvInspect, AppColors.info, 'inspected'),
                      (Icons.build_rounded, l10n.assetEvRepair, AppColors.brandOrangeInk, 'repaired'),
                      (Icons.swap_vert_rounded, l10n.assetEvStatus, AppColors.inkSecondary, 'status_changed'),
                      if (me.role.atLeast(AppRole.manager)) ...[
                        (Icons.local_shipping_rounded, l10n.assetEvMove, AppColors.success, 'moved'),
                        (Icons.delete_outline_rounded, l10n.assetEvScrap, AppColors.danger, 'scrapped'),
                      ],
                    ];
                    final w = c.maxWidth / (c.maxWidth >= Breakpoints.tablet ? 6 : 4);
                    return Wrap(children: [
                      for (final (icon, label, tint, type) in tiles)
                        SizedBox(
                          width: w,
                          child: QuickAction(
                            icon: icon,
                            label: label,
                            tint: tint,
                            onTap: _busy ? () {} : () => _event(value, type),
                          ),
                        ),
                    ]);
                  }),
                ],
                InfoGroup(title: l10n.commonDetails, rows: [
                  InfoRow(l10n.assetAssignedTo,
                      value.assignedTo == null ? l10n.assetUnassigned : name(value.assignedTo),
                      icon: Icons.person_rounded),
                  InfoRow(l10n.assetSerial, value.serialNo, icon: Icons.qr_code_2_rounded, tabular: true),
                  InfoRow('${l10n.assetMake} / ${l10n.assetRating}',
                      (value.make == null && value.rating == null) ? null : [?value.make, ?value.rating].join(' · '),
                      icon: Icons.precision_manufacturing_rounded),
                  InfoRow(l10n.assetLocation, value.locationText, icon: Icons.place_rounded),
                  InfoRow(
                    l10n.assetPurchaseDate,
                    (value.purchaseDate == null && value.purchaseValue == null)
                        ? null
                        : [
                            if (value.purchaseDate != null) Fmt.date(value.purchaseDate),
                            if (value.purchaseValue != null) Fmt.money(value.purchaseValue),
                          ].join(' · '),
                    icon: Icons.receipt_long_rounded,
                    tabular: true,
                  ),
                ]),
                if (value.lat != null && value.lng != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  LocationPreview(
                    height: 150,
                    title: value.name,
                    points: [
                      MapPoint(
                        point: LatLng(value.lat!, value.lng!),
                        color: AppColors.info,
                        icon: Icons.devices_other_rounded,
                        label: value.name,
                      ),
                    ],
                  ),
                ],
              ]),
            ),
            PhotoStrip(owner: (table: 'assets', id: value.id), canAdd: !value.scrapped),
            SectionHeader(l10n.assetHistory),
            for (final e in events)
              AppListRow(
                leading: const IconTile(Icons.history_rounded, color: AppColors.inkSecondary, size: 36),
                title: assetEventLabel(l10n, e.type),
                subtitle: [
                  Fmt.dateTime(e.at),
                  name(e.actor),
                  if (e.assignedTo != null) '→ ${name(e.assignedTo)}',
                  if (e.toSectionId != null) '→ ${tree?.byId(e.toSectionId)?.name ?? ''}',
                  if (e.status != null) assetStatusLabel(l10n, e.status!),
                  if (e.condition != null) assetConditionLabel(l10n, e.condition!),
                  ?e.note,
                ].join(' · '),
              ),
          ]),
        AsyncError(:final error) => ErrorState(title: failureMessage(l10n, error), onRetry: () => ref.invalidate(assetProvider(widget.id))),
        _ => const LoadingView(),
      },
    );
  }
}
