import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design.dart';
import '../../core/errors/app_failure.dart';
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
import '../org/presentation/section_picker.dart';
import '../../core/maps/location_field.dart';
import 'package:latlong2/latlong.dart' show LatLng;
import '../../core/maps/app_map.dart';

class PolesPage extends ConsumerStatefulWidget {
  const PolesPage({super.key});

  @override
  ConsumerState<PolesPage> createState() => _PolesPageState();
}

class _PolesPageState extends ConsumerState<PolesPage> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final poles = ref.watch(polesProvider);
    final pending = ref.watch(pendingPolesProvider);
    final tree = ref.watch(orgTreeProvider).value;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.poleTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/more/poles/new');
          ref.invalidate(polesProvider);
        },
        icon: const Icon(Icons.add_location_alt_rounded),
        label: Text(l10n.poleNew),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: TextField(
            decoration: InputDecoration(hintText: l10n.poleSearch, prefixIcon: const Icon(Icons.search_rounded)),
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
        ),
        Expanded(
          child: switch (poles) {
            AsyncData(:final value) => () {
                final list = value
                    .where((p) => _q.isEmpty || p.poleNumber.toLowerCase().contains(_q) || p.feederName.toLowerCase().contains(_q))
                    .toList();
                if (list.isEmpty && pending.isEmpty) {
                  return EmptyState(icon: Icons.electrical_services_rounded, title: l10n.poleEmpty, message: l10n.poleEmptyHint);
                }
                return RefreshIndicator(
                  onRefresh: () => ref.refresh(polesProvider.future),
                  child: ListView(padding: const EdgeInsets.only(bottom: 96), children: [
                    for (final op in pending)
                      AppListRow(
                        leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.info),
                        title: op.label,
                        trailing: StatusChip.fromDomain('pending_sync', label: l10n.attPendingSync),
                      ),
                    for (final p in list)
                      AppListRow(
                        leading: const IconTile(Icons.electrical_services_rounded, color: AppColors.ruby),
                        title: p.poleNumber,
                        subtitle: [p.feederName, poleTypeLabel(l10n, p.poleType), ?tree?.byId(p.sectionId)?.name].join(' · '),
                        trailing: poleConditionChip(l10n, p.condition),
                        onTap: () => context.push('/more/poles/${p.id}'),
                      ),
                  ]),
                );
              }(),
            AsyncError(:final error) => ErrorState(
                title: l10n.commonSomethingWrong,
                message: failureMessage(l10n, error),
                retryLabel: l10n.commonRetry,
                onRetry: () => ref.invalidate(polesProvider),
              ),
            _ => const LoadingView(),
          },
        ),
      ]),
    );
  }
}

class PoleFormPage extends ConsumerStatefulWidget {
  const PoleFormPage({super.key, this.poleId});

  final String? poleId;

  @override
  ConsumerState<PoleFormPage> createState() => _PoleFormPageState();
}

class _PoleFormPageState extends ConsumerState<PoleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _number = TextEditingController();
  final _feeder = TextEditingController();
  final _transformer = TextEditingController();
  final _height = TextEditingController();
  final _landmark = TextEditingController();
  final _remarks = TextEditingController();
  String? _sectionId;
  String _type = 'psc';
  String _condition = 'good';
  double? _lat, _lng;
  bool _busy = false;
  bool _loaded = false;

  bool get _isEdit => widget.poleId != null;

  @override
  void dispose() {
    for (final c in [_number, _feeder, _transformer, _height, _landmark, _remarks]) {
      c.dispose();
    }
    super.dispose();
  }

  void _fill(PoleRecord p) {
    if (_loaded) return;
    _loaded = true;
    _number.text = p.poleNumber;
    _feeder.text = p.feederName;
    _transformer.text = p.transformerRef ?? '';
    _height.text = p.heightM?.toString() ?? '';
    _landmark.text = p.landmark ?? '';
    _remarks.text = p.remarks ?? '';
    _sectionId = p.sectionId;
    _type = p.poleType;
    _condition = p.condition;
    _lat = p.lat;
    _lng = p.lng;
  }

  Map<String, dynamic> get _fields {
    String? blank(String s) => s.trim().isEmpty ? null : s.trim();
    return {
      'pole_number': _number.text.trim().toUpperCase(),
      'feeder_name': _feeder.text.trim(),
      'transformer_ref': blank(_transformer.text),
      'pole_type': _type,
      'height_m': num.tryParse(_height.text),
      'lat': _lat,
      'lng': _lng,
      'landmark': blank(_landmark.text),
      'condition': _condition,
      'remarks': blank(_remarks.text),
      if (!_isEdit) 'section_id': _sectionId,
    };
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_lat == null && !_isEdit) {
      showSnack(context, l10n.poleGpsRequired);
      return;
    }
    setState(() => _busy = true);
    final repo = ref.read(registersRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updatePole(widget.poleId!, _fields);
        ref.invalidate(poleProvider(widget.poleId!));
        if (mounted) Navigator.of(context).pop(true);
      } else {
        final (id, synced) = await repo.recordPole(_fields);
        if (!mounted) return;
        showSnack(context, synced ? l10n.poleSaved : l10n.attQueued);
        // Straight to the record so photos can be added on the spot.
        if (synced) {
          context.pushReplacement('/more/poles/$id');
        } else {
          Navigator.of(context).pop(true);
        }
      }
    } on AppFailure catch (f) {
      if (mounted) showSnack(context, f.code == 'duplicate' || f.code == 'duplicate_key' ? l10n.poleDuplicate : failureMessage(l10n, f));
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
    final tree = ref.watch(orgTreeProvider).value;
    final sections = tree == null ? const <OrgUnit>[] : assignableSections(me, tree);
    if (_isEdit) {
      if (ref.watch(poleProvider(widget.poleId!)) case AsyncData(:final value)) _fill(value);
      if (!_loaded) return Scaffold(appBar: AppBar(), body: const LoadingView());
    } else {
      _sectionId ??= sections.length == 1 ? sections.single.id : me.sectionId;
    }

    return Scaffold(
      bottomNavigationBar: StickyActionBar(children: [
        AppButton(label: l10n.commonSave, expand: true, loading: _busy, onPressed: _save),
      ]),
      appBar: AppBar(title: Text(_isEdit ? _number.text : l10n.poleNew)),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppSpacing.formMaxWidth),
            child: Form(
              key: _formKey,
              child: ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
                LocationField(
                  label: l10n.poleMapLocation,
                  lat: _lat,
                  lng: _lng,
                  pinIcon: Icons.electrical_services_rounded,
                  onChanged: (lat, lng, _) => setState(() {
                    _lat = lat;
                    _lng = lng;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.poleNumber,
                  controller: _number,
                  required: true,
                  textCapitalization: TextCapitalization.characters,
                ),
                if (!_isEdit) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SectionPickerField(
                    label: l10n.staffSection,
                    required: true,
                    allowed: sections,
                    value: _sectionId,
                    onChanged: (v) => setState(() => _sectionId = v),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: l10n.poleFeeder, controller: _feeder, required: true),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: l10n.poleTransformer, controller: _transformer),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.poleType, style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                  for (final t in poleTypes)
                    ChoiceChip(label: Text(poleTypeLabel(l10n, t)), selected: _type == t, onSelected: (_) => setState(() => _type = t)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.poleHeight,
                  controller: _height,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(l10n.poleCondition, style: AppTypography.label),
                const SizedBox(height: AppSpacing.sm),
                Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                  for (final c in poleConditions)
                    ChoiceChip(
                        label: Text(poleConditionLabel(l10n, c)), selected: _condition == c, onSelected: (_) => setState(() => _condition = c)),
                ]),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: l10n.poleLandmark, controller: _landmark),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: l10n.poleRemarks, controller: _remarks, maxLines: 3),
]),
            ),
          ),
        ),
      ),
    );
  }
}

class PoleDetailPage extends ConsumerWidget {
  const PoleDetailPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final pole = ref.watch(poleProvider(id));
    final tree = ref.watch(orgTreeProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(pole.value?.poleNumber ?? l10n.poleTitle),
        actions: [
          // Mirrors the RLS update policy (an RLS-blocked update would
          // silently change nothing).
          if (pole.value != null && (pole.value!.surveyedBy == me.id || me.role.atLeast(AppRole.supervisor)))
            IconButton(
              tooltip: l10n.staffEdit,
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/more/poles/$id/edit'),
            ),
        ],
      ),
      body: switch (pole) {
        AsyncData(:final value) => ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                FadeSlideIn(
                  child: DetailHeader(
                    icon: Icons.electrical_services_rounded,
                    iconColor: AppColors.ruby,
                    title: value.poleNumber,
                    subtitle: [value.feederName, ?tree?.byId(value.sectionId)?.name].join(' · '),
                    status: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
                      poleConditionChip(l10n, value.condition),
                      StatusChip(label: poleTypeLabel(l10n, value.poleType), dense: true),
                    ]),
                  ),
                ),
                if (value.lat != null && value.lng != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  LocationPreview(
                    height: 160,
                    title: value.poleNumber,
                    points: [
                      MapPoint(
                        point: LatLng(value.lat!, value.lng!),
                        color: AppColors.ruby,
                        icon: Icons.electrical_services_rounded,
                        label: value.poleNumber,
                      ),
                    ],
                  ),
                ],
                InfoGroup(title: l10n.commonDetails, rows: [
                  InfoRow(l10n.poleTransformer, value.transformerRef, icon: Icons.electric_bolt_rounded),
                  InfoRow(l10n.poleHeight, value.heightM == null ? null : '${value.heightM} m',
                      icon: Icons.height_rounded, tabular: true),
                  InfoRow(l10n.poleLandmark, value.landmark, icon: Icons.signpost_rounded),
                  InfoRow(l10n.poleRemarks, value.remarks, icon: Icons.notes_rounded),
                  InfoRow(l10n.commonDate, Fmt.dateTime(value.surveyedAt), icon: Icons.event_rounded),
                ]),
              ]),
            ),
            PhotoStrip(owner: (table: 'pole_records', id: value.id)),
            const SizedBox(height: AppSpacing.xxl),
          ]),
        AsyncError(:final error) => ErrorState(title: failureMessage(l10n, error), onRetry: () => ref.invalidate(poleProvider(id))),
        _ => const LoadingView(),
      },
    );
  }
}
