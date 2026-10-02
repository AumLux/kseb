import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design.dart';
import '../../core/export/file_export.dart';
import '../../core/format/formatters.dart';
import '../../core/format/ist.dart';
import '../../core/l10n/l10n.dart';
import '../../core/media/document_list.dart';
import '../../core/ui/dialogs.dart';
import '../auth/application/session_controller.dart';
import '../home/dashboard_repository.dart';
import 'commercial_export.dart';
import 'commercial_repository.dart';
import 'entities.dart';
import 'field_format.dart';

/// Loads the option maps for every reference column of [e].
Map<String, Map<String, String>> _refs(WidgetRef ref, EntityDef e) => {
      for (final f in e.fields.where((f) => f.kind == FieldKind.ref))
        f.refEntity!: ref.watch(refOptionsProvider(f.refEntity!)).value ?? const {},
    };

StatusChip? _statusChip(AppLocalizations l, EntityDef e, DbRow row) {
  final f = e.status;
  final v = f == null ? null : row[f.key] as String?;
  return v == null ? null : StatusChip.fromDomain(v, label: f!.labelFor(l, v));
}

String _secondary(AppLocalizations l, EntityDef e, DbRow row, Map<String, Map<String, String>> refs) => [
      for (final c in e.secondary)
        if (row[c] != null) formatField(l, e.field(c), row[c], refs: refs[e.field(c).refEntity] ?? const {}),
    ].join(' · ');

// ── List ────────────────────────────────────────────────────────────────

class EntityListPage extends ConsumerStatefulWidget {
  const EntityListPage({super.key, required this.entityKey});

  final String entityKey;

  @override
  ConsumerState<EntityListPage> createState() => _EntityListPageState();
}

class _EntityListPageState extends ConsumerState<EntityListPage> {
  String _q = '';
  String? _status;
  bool _exporting = false;

  EntityDef get _e => entityByKey(widget.entityKey);

  Future<void> _export(List<DbRow> rows, ExportKind kind) async {
    final l10n = context.l10n;
    final me = ref.read(currentUserProvider)!;
    final refs = _refs(ref, _e);
    setState(() => _exporting = true);
    try {
      final bytes = kind == ExportKind.xlsx
          ? buildEntityXlsx(l10n, _e, rows, refs)
          : await buildEntityPdf(l10n, _e, rows, refs, generatedBy: me.fullName);
      if (mounted) {
        await exportFile(context, bytes: bytes, baseName: '${_e.table}_${Ist.iso(Ist.today())}', kind: kind);
      }
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final rows = ref.watch(entityRowsProvider(_e.key));
    final refs = _refs(ref, _e);
    final status = _e.status;
    final filtered = (rows.value ?? const <DbRow>[])
        .where((r) => _status == null || r[status?.key] == _status)
        .where((r) =>
            _q.isEmpty || _e.searchColumns.any((c) => (r[c]?.toString().toLowerCase() ?? '').contains(_q)))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_e.title(l10n)),
        actions: [
          PopupMenuButton<ExportKind>(
            enabled: !_exporting && filtered.isNotEmpty,
            icon: _exporting
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download_rounded),
            onSelected: (k) => _export(filtered, k),
            itemBuilder: (_) => [
              PopupMenuItem(value: ExportKind.xlsx, child: Text(l10n.comExportXlsx)),
              PopupMenuItem(value: ExportKind.pdf, child: Text(l10n.comExportPdf)),
            ],
          ),
        ],
      ),
      floatingActionButton: me.role.isExecutive
          ? FloatingActionButton.extended(
              onPressed: () async {
                await context.push('/more/commercial/${_e.key}/new');
                ref.invalidate(entityRowsProvider(_e.key));
              },
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.comNew),
            )
          : null,
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
          child: TextField(
            decoration: InputDecoration(hintText: l10n.comSearch, prefixIcon: const Icon(Icons.search_rounded)),
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
        ),
        if (status != null)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(children: [
              for (final s in [null, ...status.options])
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: ChoiceChip(
                    label: Text(s == null ? l10n.comAll : status.labelFor(l10n, s)),
                    selected: _status == s,
                    onSelected: (_) => setState(() => _status = s),
                  ),
                ),
            ]),
          ),
        if (!me.role.isExecutive)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: Text(l10n.comReadOnly, style: AppTypography.caption),
          ),
        Expanded(
          child: switch (rows) {
            AsyncData() when filtered.isEmpty => EmptyState(icon: _e.icon, title: l10n.comEmpty),
            AsyncData() => RefreshIndicator(
                onRefresh: () => ref.refresh(entityRowsProvider(_e.key).future),
                child: LazyListView(padding: const EdgeInsets.only(bottom: 96), itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final r = filtered[i];
                    return AppListRow(
                      leading: IconTile(_e.icon, color: entityTint(_e)),
                      title: _e.display(r).isEmpty
                          ? formatField(l10n, _e.fields.first, r[_e.fields.first.key])
                          : _e.display(r),
                      subtitle: _secondary(l10n, _e, r, refs),
                      trailing: _statusChip(l10n, _e, r),
                      onTap: () => context.push('/more/commercial/${_e.key}/${r['id']}'),
                    );
                  }),
              ),
            AsyncError(:final error) => ErrorState(
                title: l10n.commonSomethingWrong,
                message: failureMessage(l10n, error),
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(entityRowsProvider(_e.key)),
              ),
            _ => const LoadingView(),
          },
        ),
      ]),
    );
  }
}

// ── Detail ──────────────────────────────────────────────────────────────

class EntityDetailPage extends ConsumerWidget {
  const EntityDetailPage({super.key, required this.entityKey, required this.id});

  final String entityKey;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final e = entityByKey(entityKey);
    final me = ref.watch(currentUserProvider)!;
    final row = ref.watch(entityRowProvider((key: entityKey, id: id)));
    final refs = _refs(ref, e);

    return Scaffold(
      appBar: AppBar(
        title: Text(e.title(l10n)),
        actions: [
          if (me.role.isExecutive && row.hasValue)
            IconButton(
              tooltip: l10n.staffEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await context.push('/more/commercial/$entityKey/$id/edit');
                ref
                  ..invalidate(entityRowProvider((key: entityKey, id: id)))
                  ..invalidate(entityRowsProvider(entityKey));
              },
            ),
        ],
      ),
      body: switch (row) {
        AsyncData(:final value) => ListView(padding: const EdgeInsets.only(bottom: AppSpacing.xxxl), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Builder(builder: (context) {
                final shown = [
                  for (final f in e.fields)
                    if (value[f.key] != null && f.key != e.statusField) f,
                ];
                // The register's amounts lead, as headline numbers.
                final money = shown.where((f) => f.kind == FieldKind.money).take(3).toList();
                return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  FadeSlideIn(
                    child: DetailHeader(
                      icon: e.icon,
                      iconColor: entityTint(e),
                      title: e.display(value).isEmpty ? e.title(l10n) : e.display(value),
                      subtitle: e.title(l10n),
                      status: _statusChip(l10n, e, value),
                    ),
                  ),
                  if (money.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    StatStrip(items: [
                      for (final f in money)
                        StatItem(label: f.label(l10n), value: formatField(l10n, f, value[f.key])),
                    ]),
                  ],
                  InfoGroup(title: l10n.commonDetails, rows: [
                    for (final f in shown)
                      if (!money.contains(f))
                        InfoRow(
                          f.label(l10n),
                          formatField(l10n, f, value[f.key], refs: refs[f.refEntity] ?? const {}),
                          tabular: f.kind == FieldKind.money || f.kind == FieldKind.gstin,
                          onTap: f.kind == FieldKind.ref && f.refEntity != 'sections'
                              ? () => context.push(
                                  '/more/commercial/${f.refEntity == 'tenders' ? 'tenders' : 'work-orders'}/${value[f.key]}')
                              : null,
                        ),
                  ]),
                ]);
              }),
            ),
            for (final link in linksFor(e)) _LinkedSection(link: link, id: id),
            DocumentList(owner: (table: e.table, id: id), canAdd: me.role.isExecutive),
          ]),
        AsyncError(:final error) => ErrorState(
            title: failureMessage(l10n, error),
            onRetry: () => ref.invalidate(entityRowProvider((key: entityKey, id: id))),
          ),
        _ => const LoadingView(),
      },
    );
  }
}

class _LinkedSection extends ConsumerWidget {
  const _LinkedSection({required this.link, required this.id});

  final LinkDef link;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final rows = ref.watch(linkedRowsProvider((entity: link.entity.key, column: link.column, id: id))).value ?? const <DbRow>[];
    if (rows.isEmpty) return const SizedBox.shrink();
    final refs = _refs(ref, link.entity);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SectionHeader(link.entity.title(l10n)),
      for (final r in rows)
        AppListRow(
          leading: IconTile(link.entity.icon, color: entityTint(link.entity), size: 36),
          title: link.entity.display(r),
          subtitle: _secondary(l10n, link.entity, r, refs),
          trailing: _statusChip(l10n, link.entity, r),
          onTap: () => context.push('/more/commercial/${link.entity.key}/${r['id']}'),
        ),
    ]);
  }
}

// ── Form ────────────────────────────────────────────────────────────────

class EntityFormPage extends ConsumerStatefulWidget {
  const EntityFormPage({super.key, required this.entityKey, this.id});

  final String entityKey;
  final String? id;

  @override
  ConsumerState<EntityFormPage> createState() => _EntityFormPageState();
}

class _EntityFormPageState extends ConsumerState<EntityFormPage> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _text = {};
  final Map<String, Object?> _values = {};
  bool _loaded = false;
  bool _busy = false;

  EntityDef get _e => entityByKey(widget.entityKey);

  static const _textKinds = {FieldKind.text, FieldKind.multiline, FieldKind.money, FieldKind.phone, FieldKind.gstin};

  @override
  void initState() {
    super.initState();
    for (final f in _e.fields) {
      if (_textKinds.contains(f.kind)) _text[f.key] = TextEditingController();
    }
    if (widget.id == null) _fill({for (final f in _e.fields) f.key: f.defaultValue});
  }

  @override
  void dispose() {
    for (final c in _text.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(DbRow row) {
    if (_loaded) return;
    _loaded = true;
    for (final f in _e.fields) {
      final v = row[f.key];
      if (_textKinds.contains(f.kind)) {
        _text[f.key]!.text = v == null ? '' : v.toString();
      } else {
        _values[f.key] = v;
      }
    }
  }

  DbRow _collect() {
    final out = <String, dynamic>{};
    for (final f in _e.fields) {
      if (_textKinds.contains(f.kind)) {
        final t = _text[f.key]!.text.trim();
        out[f.key] = switch (f.kind) {
          FieldKind.money => t.isEmpty ? (f.defaultValue) : num.parse(t),
          FieldKind.gstin => t.isEmpty ? null : t.toUpperCase(),
          _ => t.isEmpty ? null : t,
        };
      } else {
        out[f.key] = _values[f.key];
      }
    }
    return out;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final id = await ref.read(commercialRepositoryProvider).save(_e, _collect(), id: widget.id);
      if (!mounted) return;
      // Refresh here, not after the list's `await push`: pushReplacement
      // below drops that route's completer, so the await never returns.
      ref
        ..invalidate(entityRowsProvider(_e.key))
        ..invalidate(depositsExpiringProvider)
        ..invalidate(billAgeingProvider)
        ..invalidate(dashboardProvider);
      if (widget.id == null) {
        context.pushReplacement('/more/commercial/${_e.key}/$id');
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _field(AppLocalizations l10n, FieldDef f) {
    final label = f.label(l10n);
    String? req(String? v) => (f.required && (v == null || v.trim().isEmpty)) ? l10n.fieldRequired(label) : null;

    switch (f.kind) {
      case FieldKind.text:
      case FieldKind.multiline:
      case FieldKind.phone:
        return AppTextField(
          label: label,
          controller: _text[f.key],
          required: f.required,
          maxLines: f.kind == FieldKind.multiline ? 3 : 1,
          keyboardType: f.kind == FieldKind.phone ? TextInputType.phone : null,
          validator: req,
        );
      case FieldKind.money:
        return AppTextField(
          label: '$label (₹)',
          controller: _text[f.key],
          required: f.required,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
          validator: (v) {
            if (req(v) != null) return req(v);
            if (v != null && v.trim().isNotEmpty && num.tryParse(v.trim()) == null) return l10n.fAmountInvalid;
            return null;
          },
        );
      case FieldKind.gstin:
        return AppTextField(
          label: label,
          controller: _text[f.key],
          required: f.required,
          textCapitalization: TextCapitalization.characters,
          maxLength: 15,
          validator: (v) => RegExp(r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$').hasMatch((v ?? '').trim().toUpperCase())
              ? null
              : l10n.fGstinInvalid,
        );
      case FieldKind.choice:
        return AppDropdownField<String?>(
          label: label,
          required: f.required,
          items: [if (!f.required) null, ...f.options],
          value: _values[f.key] as String?,
          itemLabel: (v) => v == null ? l10n.optNone : f.labelFor(l10n, v),
          onChanged: (v) => setState(() => _values[f.key] = v),
          validator: (v) => f.required && v == null ? l10n.fieldRequired(label) : null,
        );
      case FieldKind.ref:
        final options = ref.watch(refOptionsProvider(f.refEntity!)).value ?? const <String, String>{};
        return AppDropdownField<String?>(
          label: label,
          required: f.required,
          items: [if (!f.required) null, ...options.keys],
          value: _values[f.key] as String?,
          itemLabel: (v) => v == null ? l10n.optNone : options[v] ?? v,
          onChanged: (v) => setState(() => _values[f.key] = v),
          validator: (v) => f.required && v == null ? l10n.fieldRequired(label) : null,
        );
      case FieldKind.date:
      case FieldKind.month:
      case FieldKind.datetime:
        final current = _values[f.key] == null ? null : DateTime.tryParse(_values[f.key].toString());
        return AppTextField(
          key: ValueKey('${f.key}${_values[f.key]}'),
          label: label,
          required: f.required,
          initialValue: current == null ? '' : formatField(l10n, f, _values[f.key]),
          readOnly: true,
          suffix: const Icon(Icons.calendar_today_rounded),
          validator: (_) => f.required && _values[f.key] == null ? l10n.fieldRequired(label) : null,
          onTap: () async {
            final base = current?.toLocal() ?? DateTime.now();
            final d = await showDatePicker(
              context: context,
              initialDate: base,
              firstDate: DateTime(2000),
              lastDate: DateTime(DateTime.now().year + 10),
              initialDatePickerMode: f.kind == FieldKind.month ? DatePickerMode.year : DatePickerMode.day,
            );
            if (d == null || !mounted) return;
            if (f.kind == FieldKind.datetime) {
              final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(base));
              final ist = DateTime.utc(d.year, d.month, d.day, t?.hour ?? 15, t?.minute ?? 0).subtract(Ist.offset);
              setState(() => _values[f.key] = ist.toIso8601String());
            } else if (f.kind == FieldKind.month) {
              setState(() => _values[f.key] = Ist.iso(DateTime(d.year, d.month)));
            } else {
              setState(() => _values[f.key] = Ist.iso(d));
            }
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (widget.id != null) {
      if (ref.watch(entityRowProvider((key: _e.key, id: widget.id!))) case AsyncData(:final value)) _fill(value);
      if (!_loaded) return Scaffold(appBar: AppBar(), body: const LoadingView());
    }
    return Scaffold(
      bottomNavigationBar: StickyActionBar(children: [
        AppButton(label: l10n.commonSave, expand: true, loading: _busy, onPressed: _save),
      ]),
      appBar: AppBar(title: Text(_e.title(l10n))),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
            child: Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
                for (final f in _e.fields) ...[_field(l10n, f), const SizedBox(height: AppSpacing.lg)],
]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hub ─────────────────────────────────────────────────────────────────

/// Commercial overview (managers+): expiring deposits, receivables ageing,
/// search across all registers, and the six registers.
/// One colour per register, used on its tile, list rows and detail header.
Color entityTint(EntityDef e) => switch (e.key) {
      'tenders' => AppColors.primaryDeep,
      'deposits' => AppColors.success,
      'work-orders' => AppColors.info,
      'bills' => AppColors.brandOrangeInk,
      'letters' => AppColors.inkSecondary,
      _ => AppColors.ruby,
    };

/// Commercial overview in the Groww portfolio style: receivables up front
/// with an ageing bar, headline numbers, the six registers, deposits about
/// to expire, and search across everything.
class CommercialHomePage extends ConsumerStatefulWidget {
  const CommercialHomePage({super.key});

  @override
  ConsumerState<CommercialHomePage> createState() => _CommercialHomePageState();
}

class _CommercialHomePageState extends ConsumerState<CommercialHomePage> {
  final _searchCtl = TextEditingController();
  String _q = '';
  Future<List<({EntityDef entity, DbRow row})>>? _search;

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  void _runSearch(String q) {
    setState(() {
      _q = q;
      _search = q.trim().length < 2 ? null : ref.read(commercialRepositoryProvider).search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expiring = ref.watch(depositsExpiringProvider);
    final ageing = ref.watch(billAgeingProvider);
    final kpis = ref.watch(dashboardProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.comTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref
          ..invalidate(depositsExpiringProvider)
          ..invalidate(billAgeingProvider)
          ..invalidate(dashboardProvider),
        child: ListView(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl), children: [
          FadeSlideIn(
            child: switch (ageing) {
              AsyncData(:final value) => _ReceivablesCard(rows: value),
              AsyncError() => const SizedBox.shrink(),
              _ => const Skeleton(child: SkeletonBox(height: 180, radius: AppRadius.lg)),
            },
          ),
          if (kpis != null) ...[
            const SizedBox(height: AppSpacing.md),
            FadeSlideIn(
              index: 1,
              child: StatStrip(items: [
                StatItem(
                  label: l10n.kpiOpenTenders,
                  value: Fmt.qty(kpis.number('open_tenders')),
                  onTap: () => context.push('/more/commercial/tenders'),
                ),
                StatItem(
                  label: l10n.kpiActiveWorkOrders,
                  value: Fmt.qty(kpis.number('active_work_orders')),
                  onTap: () => context.push('/more/commercial/work-orders'),
                ),
                StatItem(
                  label: l10n.kpiDepositsHeld,
                  value: Fmt.moneyCompact(kpis.number('deposits_held')),
                  color: AppColors.success,
                  onTap: () => context.push('/more/commercial/deposits'),
                ),
              ]),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _searchCtl,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.comSearch,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _q.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.commonClear,
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtl.clear();
                        _runSearch('');
                      },
                    ),
            ),
            onChanged: _runSearch,
          ),
          if (_search != null)
            FutureBuilder(
              future: _search,
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const SizedBox(height: 160, child: LoadingView());
                }
                final hits = snap.data!;
                if (hits.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                    child: Text('${l10n.comNoResults}: "$_q"', style: AppTypography.caption, textAlign: TextAlign.center),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(children: [
                      for (final (i, h) in hits.indexed)
                        AppListRow(
                          leading: IconTile(h.entity.icon, color: entityTint(h.entity), size: 36),
                          title: h.entity.display(h.row),
                          subtitle: h.entity.title(l10n),
                          showDivider: i < hits.length - 1,
                          onTap: () => context.push('/more/commercial/${h.entity.key}/${h.row['id']}'),
                        ),
                    ]),
                  ),
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.md),
            child: Text(l10n.comRegisters, style: AppTypography.subtitle),
          ),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 700 ? 3 : 2;
            final w = (c.maxWidth - AppSpacing.md * (cols - 1)) / cols;
            return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
              for (final (i, e) in commercialEntities.indexed)
                SizedBox(
                  width: w,
                  child: FadeSlideIn(
                    index: i,
                    child: AppCard(
                      onTap: () => context.push('/more/commercial/${e.key}'),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          IconTile(e.icon, color: entityTint(e), size: 40),
                          const Spacer(),
                          const Icon(Icons.arrow_outward_rounded, size: AppSizes.iconSm, color: AppColors.inkDisabled),
                        ]),
                        const SizedBox(height: AppSpacing.md),
                        Text(e.title(l10n), style: AppTypography.bodyStrong, maxLines: 2, overflow: TextOverflow.ellipsis),
                      ]),
                    ),
                  ),
                ),
            ]);
          }),
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.md),
            child: Text(l10n.comExpiringSoon, style: AppTypography.subtitle),
          ),
          switch (expiring) {
            AsyncData(:final value) when value.isEmpty => AppCard(
                child: Row(children: [
                  const IconTile(Icons.verified_rounded, color: AppColors.success, size: 36),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(l10n.comNothingExpiring, style: AppTypography.body)),
                ]),
              ),
            AsyncData(:final value) => AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (final (i, d) in value.indexed) _ExpiringRow(deposit: d, divider: i < value.length - 1),
                ]),
              ),
            AsyncError(:final error) => ErrorState(
                title: failureMessage(l10n, error),
                onRetry: () => ref.invalidate(depositsExpiringProvider),
              ),
            _ => const SizedBox(height: 140, child: LoadingView()),
          },
        ]),
      ),
    );
  }
}

class _ExpiringRow extends StatelessWidget {
  const _ExpiringRow({required this.deposit, required this.divider});

  final DbRow deposit;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = deposit;
    final days = (d['days_left'] as num?)?.toInt() ?? 0;
    final urgent = days <= 7;
    return AppListRow(
      leading: Container(
        width: 46,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          color: (urgent ? AppColors.danger : AppColors.warning).withValues(alpha: 0.10),
          borderRadius: AppRadius.mdAll,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('$days',
              style: AppTypography.title.copyWith(
                fontSize: 18,
                height: 1.1,
                color: urgent ? AppColors.danger : AppColors.warning,
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
          Text(l10n.comDaysShort,
              style: AppTypography.overline.copyWith(fontSize: 10, color: urgent ? AppColors.danger : AppColors.warning)),
        ]),
      ),
      title: '${depositsEntity.field('kind').labelFor(l10n, d['kind'] as String)} · ${Fmt.money(d['amount'] as num?)}',
      subtitle: [?d['instrument_no'] as String?, ?d['bank_name'] as String?, Fmt.date(DateTime.tryParse('${d['validity_date']}'))]
          .join(' · '),
      showDivider: divider,
      onTap: () => context.push('/more/commercial/deposits/${d['id']}'),
    );
  }
}

/// Dark hero: total outstanding, bill count, and a stacked ageing bar with
/// a legend (0–30 / 31–60 / 61–90 / 90+ days).
class _ReceivablesCard extends StatelessWidget {
  const _ReceivablesCard({required this.rows});

  final List<DbRow> rows;

  static const _buckets = ['0-30', '31-60', '61-90', '90+'];
  static const _colors = [Color(0xFF34D399), Color(0xFFFBBF24), Color(0xFFFB923C), Color(0xFFF87171)];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final open = rows.where((b) => b['bucket'] != 'settled').toList();
    final sums = {for (final b in _buckets) b: 0.0};
    for (final b in open) {
      final k = b['bucket'] as String;
      if (sums.containsKey(k)) sums[k] = sums[k]! + ((b['outstanding'] as num?) ?? 0).toDouble();
    }
    final total = sums.values.fold<double>(0, (a, b) => a + b);

    return Semantics(
      label: '${l10n.comOutstanding}: ${Fmt.money(total)}',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg + 4),
        decoration: BoxDecoration(
          borderRadius: AppRadius.lgAll,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandDark, Color(0xFF2A2477)],
          ),
          boxShadow: AppShadows.level2,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const IconTile(Icons.request_quote_rounded, color: Colors.white, background: Color(0x26FFFFFF), size: 36),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(l10n.comOutstanding,
                  style: AppTypography.label.copyWith(color: const Color(0xFFC9CCF0))),
            ),
          ]),
          const SizedBox(height: AppSpacing.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Fmt.money(total), style: AppTypography.display.copyWith(color: Colors.white)),
          ),
          Text(l10n.comUnpaidBills(open.length), style: AppTypography.caption.copyWith(color: const Color(0xFFC9CCF0))),
          const SizedBox(height: AppSpacing.lg),
          // Stacked ageing bar.
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: SizedBox(
              height: 10,
              child: total <= 0
                  ? const ColoredBox(color: Color(0x33FFFFFF))
                  : Row(children: [
                      for (final (i, b) in _buckets.indexed)
                        if (sums[b]! > 0)
                          Expanded(
                            flex: (sums[b]! / total * 1000).round().clamp(1, 1000),
                            child: ColoredBox(color: _colors[i]),
                          ),
                    ]),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Two-column legend: range over amount, so long (Malayalam) labels
          // wrap inside their cell instead of overflowing the card.
          LayoutBuilder(builder: (context, c) {
            final w = (c.maxWidth - AppSpacing.md) / 2;
            return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.sm, children: [
              for (final (i, b) in _buckets.indexed)
                SizedBox(
                  width: w,
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Container(
                          width: 8, height: 8, decoration: BoxDecoration(color: _colors[i], shape: BoxShape.circle)),
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l10n.comAgeingDays(b),
                            style: AppTypography.caption.copyWith(color: const Color(0xFFC9CCF0))),
                        Text(Fmt.moneyCompact(sums[b]!),
                            style: AppTypography.bodyTabular.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ]),
                ),
            ]);
          }),
        ]),
      ),
    );
  }
}
