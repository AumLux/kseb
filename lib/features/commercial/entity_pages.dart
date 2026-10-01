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
                child: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
                  for (final r in filtered)
                    AppListRow(
                      title: _e.display(r).isEmpty
                          ? formatField(l10n, _e.fields.first, r[_e.fields.first.key])
                          : _e.display(r),
                      subtitle: _secondary(l10n, _e, r, refs),
                      trailing: _statusChip(l10n, _e, r),
                      onTap: () => context.push('/more/commercial/${_e.key}/${r['id']}'),
                    ),
                ]),
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
            Container(
              color: AppColors.canvas,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ?_statusChip(l10n, e, value),
                const SizedBox(height: AppSpacing.sm),
                Text(e.display(value), style: AppTypography.title),
              ]),
            ),
            for (final f in e.fields)
              if (value[f.key] != null && f.key != e.statusField)
                AppListRow(
                  title: formatField(l10n, f, value[f.key], refs: refs[f.refEntity] ?? const {}),
                  subtitle: f.label(l10n),
                  onTap: f.kind == FieldKind.ref && f.refEntity != 'sections'
                      ? () => context.push(
                          '/more/commercial/${f.refEntity == 'tenders' ? 'tenders' : 'work-orders'}/${value[f.key]}')
                      : null,
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
          leading: Icon(link.entity.icon, color: AppColors.inkMute),
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
                AppButton(label: l10n.commonSave, expand: true, loading: _busy, onPressed: _save),
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
class CommercialHomePage extends ConsumerStatefulWidget {
  const CommercialHomePage({super.key});

  @override
  ConsumerState<CommercialHomePage> createState() => _CommercialHomePageState();
}

class _CommercialHomePageState extends ConsumerState<CommercialHomePage> {
  String _q = '';
  Future<List<({EntityDef entity, DbRow row})>>? _search;

  void _runSearch(String q) {
    setState(() {
      _q = q;
      _search = q.trim().length < 2 ? null : ref.read(commercialRepositoryProvider).search(q);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final expiring = ref.watch(depositsExpiringProvider).value ?? const <DbRow>[];
    final ageing = ref.watch(billAgeingProvider).value ?? const <DbRow>[];
    final buckets = <String, num>{};
    for (final b in ageing.where((b) => b['bucket'] != 'settled')) {
      buckets.update(b['bucket'] as String, (v) => v + ((b['outstanding'] as num?) ?? 0),
          ifAbsent: () => (b['outstanding'] as num?) ?? 0);
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.comTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref
          ..invalidate(depositsExpiringProvider)
          ..invalidate(billAgeingProvider),
        child: ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
          TextField(
            decoration: InputDecoration(hintText: l10n.comSearch, prefixIcon: const Icon(Icons.search_rounded)),
            onChanged: _runSearch,
          ),
          if (_search != null)
            FutureBuilder(
              future: _search,
              builder: (context, snap) {
                if (!snap.hasData) return const Padding(padding: EdgeInsets.all(AppSpacing.xl), child: LoadingView());
                final hits = snap.data!;
                if (hits.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text('${l10n.comNoResults}: "$_q"', style: AppTypography.caption),
                  );
                }
                return Column(children: [
                  for (final h in hits)
                    AppListRow(
                      leading: Icon(h.entity.icon, color: AppColors.inkMute),
                      title: h.entity.display(h.row),
                      subtitle: h.entity.title(l10n),
                      onTap: () => context.push('/more/commercial/${h.entity.key}/${h.row['id']}'),
                    ),
                ]);
              },
            ),
          SectionHeader(l10n.comOverview),
          LayoutBuilder(builder: (context, c) {
            final cols = c.maxWidth >= 700 ? 3 : 2;
            final w = (c.maxWidth - AppSpacing.md * (cols - 1)) / cols;
            return Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
              for (final e in commercialEntities)
                SizedBox(
                  width: w,
                  child: AppCard(
                    onTap: () => context.push('/more/commercial/${e.key}'),
                    child: Row(children: [
                      Icon(e.icon, color: AppColors.primaryInk),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Text(e.title(l10n), style: AppTypography.bodyStrong)),
                    ]),
                  ),
                ),
            ]);
          }),
          SectionHeader(l10n.comExpiringSoon),
          if (expiring.isEmpty)
            Text(l10n.comNothingExpiring, style: AppTypography.caption)
          else
            for (final d in expiring)
              AppListRow(
                leading: const Icon(Icons.timer_rounded, color: AppColors.warning),
                title: '${depositsEntity.field('kind').labelFor(l10n, d['kind'] as String)} · ${Fmt.money(d['amount'] as num?)}',
                subtitle: [?d['instrument_no'] as String?, Fmt.date(DateTime.tryParse('${d['validity_date']}'))].join(' · '),
                trailing: StatusChip(
                  label: l10n.comDaysLeft((d['days_left'] as num?)?.toInt() ?? 0),
                  tone: ((d['days_left'] as num?) ?? 0) <= 7 ? StatusTone.danger : StatusTone.warning,
                  dense: true,
                ),
                onTap: () => context.push('/more/commercial/deposits/${d['id']}'),
              ),
          SectionHeader(l10n.comAgeing),
          Row(children: [
            for (final b in ['0-30', '31-60', '61-90', '90+']) ...[
              Expanded(child: KpiCard(label: '$b d', value: Fmt.moneyCompact(buckets[b] ?? 0))),
              if (b != '90+') const SizedBox(width: AppSpacing.sm),
            ],
          ]),
          const SizedBox(height: AppSpacing.xxl),
        ]),
      ),
    );
  }
}
