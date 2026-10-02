import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/maps/app_map.dart';
import '../../../core/maps/location_picker_page.dart';
import '../../../core/ui/dialogs.dart';
import '../../../core/ui/sheets.dart';
import '../../auth/application/session_controller.dart';
import '../data/org_repository.dart';
import 'section_picker.dart' show breadcrumb;

String orgLevelLabel(AppLocalizations l10n, OrgLevel level) => switch (level) {
      OrgLevel.circle => l10n.orgCircle,
      OrgLevel.division => l10n.orgDivision,
      OrgLevel.subdivision => l10n.orgSubdivision,
      OrgLevel.section => l10n.orgSectionOffice,
    };

IconData orgLevelIcon(OrgLevel level) => switch (level) {
      OrgLevel.circle => Icons.public_rounded,
      OrgLevel.division => Icons.domain_rounded,
      OrgLevel.subdivision => Icons.apartment_rounded,
      OrgLevel.section => Icons.location_city_rounded,
    };

Color _levelTint(OrgLevel level) => switch (level) {
      OrgLevel.circle => AppColors.primaryDeep,
      OrgLevel.division => AppColors.info,
      OrgLevel.subdivision => AppColors.brandOrangeInk,
      OrgLevel.section => AppColors.success,
    };

/// KSEB hierarchy: Circle → Division → Sub-division → Section office.
///
/// A drill-down (not nested expanders) so it stays usable with hundreds of
/// sections: counts up top, search across every level, breadcrumbs, and a
/// section sheet with its geofence map. Everyone may browse; only the
/// COO/Director edit (enforced by RLS too).
class OrgPage extends ConsumerStatefulWidget {
  const OrgPage({super.key});

  @override
  ConsumerState<OrgPage> createState() => _OrgPageState();
}

class _OrgPageState extends ConsumerState<OrgPage> {
  final _search = TextEditingController();
  List<String> _pathIds = const [];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _edit(OrgLevel level, {OrgUnit? unit, String? parentId}) async {
    final saved = await showAppSheet<bool>(
      context,
      builder: (_) => _UnitForm(level: level, unit: unit, parentId: parentId),
    );
    if (saved == true) ref.invalidate(orgTreeProvider);
  }

  void _openSection(OrgTree tree, OrgUnit s, bool canEdit) {
    final l10n = context.l10n;
    final has = s.lat != null && s.lng != null;
    showAppSheet<void>(
      context,
      builder: (context) => SheetScaffold(
        title: s.name,
        subtitle: breadcrumb(tree, s),
        primaryLabel: canEdit ? l10n.staffEdit : null,
        onPrimary: () {
          Navigator.pop(context);
          _edit(OrgLevel.section, unit: s, parentId: s.parentId);
        },
        children: [
          if (has)
            LocationPreview(
              height: 180,
              title: s.name,
              fence: (LatLng(s.lat!, s.lng!), s.geofenceRadiusM ?? 300),
              points: [MapPoint(point: LatLng(s.lat!, s.lng!), color: AppColors.primary, icon: Icons.location_city_rounded)],
            )
          else
            NoteBanner(text: l10n.orgNoLocation, icon: Icons.location_off_rounded, tone: AppColors.warning),
          InfoGroup(rows: [
            InfoRow(l10n.orgCode, s.code, icon: Icons.tag_rounded, tabular: true),
            InfoRow(l10n.orgAddress, s.address, icon: Icons.place_rounded),
            InfoRow(l10n.orgGeofence, has ? l10n.mapMeters(s.geofenceRadiusM ?? 300) : null,
                icon: Icons.radar_rounded, tabular: true),
            InfoRow('${l10n.orgLatitude}, ${l10n.orgLongitude}',
                has ? '${s.lat!.toStringAsFixed(5)}, ${s.lng!.toStringAsFixed(5)}' : null,
                icon: Icons.my_location_rounded, tabular: true),
          ]),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canEdit = ref.watch(currentUserProvider)?.role.isExecutive ?? false;
    final tree = ref.watch(orgTreeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orgTitle)),
      body: switch (tree) {
        AsyncData(:final value) => _body(value, canEdit),
        AsyncError(:final error) => ErrorState(
            title: l10n.commonSomethingWrong,
            message: failureMessage(l10n, error),
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(orgTreeProvider),
          ),
        _ => const LoadingView(),
      },
    );
  }

  Widget _body(OrgTree tree, bool canEdit) {
    final l10n = context.l10n;
    // Drop path entries that no longer exist (e.g. after a refresh).
    final path = [for (final id in _pathIds) ?tree.byId(id)];
    final current = path.isEmpty ? null : path.last;
    final childLevel = current == null ? OrgLevel.circle : current.level.child;

    final byParent = <String?, List<OrgUnit>>{};
    for (final u in tree.units) {
      byParent.putIfAbsent(u.parentId, () => []).add(u);
    }
    final sectionCount = <String, int>{};
    int count(OrgUnit u) => sectionCount[u.id] ??= u.level == OrgLevel.section
        ? 1
        : (byParent[u.id] ?? const []).fold<int>(0, (n, c) => n + count(c));

    final query = _search.text.trim().toLowerCase();
    final searching = query.isNotEmpty;
    final rows = searching
        ? (tree.units
            .where((u) => u.name.toLowerCase().contains(query) || u.code.toLowerCase().contains(query))
            .toList()
          ..sort((a, b) => a.level.index.compareTo(b.level.index)))
        : ([...?byParent[current?.id]]..sort((a, b) => a.name.compareTo(b.name)));
    final unlocated = tree.sections.where((s) => s.lat == null).length;

    return Stack(children: [
      CustomScrollView(slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
          sliver: SliverList.list(children: [
            FadeSlideIn(
              child: StatStrip(items: [
                StatItem(label: l10n.orgCountCircles, value: '${tree.of(OrgLevel.circle).length}'),
                StatItem(label: l10n.orgCountDivisions, value: '${tree.of(OrgLevel.division).length}'),
                StatItem(label: l10n.orgCountSubdivisions, value: '${tree.of(OrgLevel.subdivision).length}'),
                StatItem(label: l10n.orgCountSections, value: '${tree.sections.length}', color: AppColors.success),
              ]),
            ),
            if (unlocated > 0) ...[
              const SizedBox(height: AppSpacing.md),
              NoteBanner(
                text: l10n.orgSectionsWithoutLocation(unlocated),
                icon: Icons.location_off_rounded,
                tone: AppColors.warning,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.orgSearchUnits,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searching
                    ? IconButton(
                        tooltip: l10n.commonClear,
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => setState(_search.clear),
                      )
                    : null,
              ),
            ),
            if (!searching)
              SizedBox(
                height: 48,
                // Reversed so the current level stays in view.
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  children: [
                    _Crumb(label: l10n.orgAllCircles, active: path.isEmpty, onTap: () => setState(() => _pathIds = const [])),
                    for (var i = 0; i < path.length; i++) ...[
                      const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkDisabled),
                      _Crumb(
                        label: path[i].name,
                        active: i == path.length - 1,
                        onTap: () => setState(() => _pathIds = [for (final u in path.sublist(0, i + 1)) u.id]),
                      ),
                    ],
                  ].reversed.toList(),
                ),
              )
            else
              const SizedBox(height: AppSpacing.md),
          ]),
        ),
        if (rows.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: searching ? Icons.search_off_rounded : Icons.account_tree_rounded,
              title: searching ? l10n.orgNoSectionsFound : l10n.orgEmpty,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, 112),
            sliver: SliverToBoxAdapter(
              child: AppCard(
                padding: EdgeInsets.zero,
                child: Column(children: [
                  for (final (i, u) in rows.indexed)
                    _UnitRow(
                      unit: u,
                      subtitle: [
                        if (searching) orgLevelLabel(l10n, u.level),
                        u.code,
                        if (u.level != OrgLevel.section) l10n.orgSectionsCount(count(u)),
                        if (searching && u.parentId != null) breadcrumb(tree, u),
                      ].join(' · '),
                      divider: i < rows.length - 1,
                      canEdit: canEdit,
                      onEdit: () => _edit(u.level, unit: u, parentId: u.parentId),
                      onTap: u.level == OrgLevel.section
                          ? () => _openSection(tree, u, canEdit)
                          : () => setState(() {
                                _search.clear();
                                final p = <String>[];
                                OrgUnit? x = u;
                                while (x != null) {
                                  p.insert(0, x.id);
                                  x = tree.byId(x.parentId);
                                }
                                _pathIds = p;
                              }),
                    ),
                ]),
              ),
            ),
          ),
      ]),
      if (canEdit && !searching && childLevel != null)
        Positioned(
          right: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: SafeArea(
            child: FloatingActionButton.extended(
              heroTag: null,
              onPressed: () => _edit(childLevel, parentId: current?.id),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.orgAdd(orgLevelLabel(l10n, childLevel))),
            ),
          ),
        ),
    ]);
  }
}

class _UnitRow extends StatelessWidget {
  const _UnitRow({
    required this.unit,
    required this.subtitle,
    required this.divider,
    required this.canEdit,
    required this.onEdit,
    required this.onTap,
  });

  final OrgUnit unit;
  final String subtitle;
  final bool divider;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isSection = unit.level == OrgLevel.section;
    return AppListRow(
      leading: IconTile(orgLevelIcon(unit.level), color: _levelTint(unit.level), size: 40),
      title: unit.name,
      subtitle: subtitle,
      showDivider: divider,
      onTap: onTap,
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (isSection)
          unit.lat == null
              ? StatusChip(label: l10n.orgNoLocation, tone: StatusTone.warning, icon: Icons.location_off_rounded, dense: true)
              : StatusChip(
                  label: l10n.mapMeters(unit.geofenceRadiusM ?? 300),
                  tone: StatusTone.success,
                  icon: Icons.radar_rounded,
                  dense: true,
                ),
        if (canEdit)
          IconButton(
            tooltip: l10n.staffEdit,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          )
        else if (!isSection)
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkDisabled),
      ]),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Center(
        child: TextButton(
          onPressed: active ? null : onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            disabledForegroundColor: AppColors.ink,
          ),
          child: Text(label, style: AppTypography.label.copyWith(fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
        ),
      );
}

class _UnitForm extends ConsumerStatefulWidget {
  const _UnitForm({required this.level, this.unit, this.parentId});

  final OrgLevel level;
  final OrgUnit? unit;
  final String? parentId;

  @override
  ConsumerState<_UnitForm> createState() => _UnitFormState();
}

class _UnitFormState extends ConsumerState<_UnitForm> {
  final _formKey = GlobalKey<FormState>();
  late final _code = TextEditingController(text: widget.unit?.code);
  late final _name = TextEditingController(text: widget.unit?.name);
  late final _address = TextEditingController(text: widget.unit?.address);
  late final _lat = TextEditingController(text: widget.unit?.lat?.toString());
  late final _lng = TextEditingController(text: widget.unit?.lng?.toString());
  late final _radius = TextEditingController(text: (widget.unit?.geofenceRadiusM ?? 300).toString());
  bool _busy = false;

  bool get _isSection => widget.level == OrgLevel.section;

  @override
  void dispose() {
    for (final c in [_code, _name, _address, _lat, _lng, _radius]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _coordError(AppLocalizations l10n) {
    final hasLat = _lat.text.trim().isNotEmpty, hasLng = _lng.text.trim().isNotEmpty;
    if (hasLat != hasLng) return l10n.orgCoordsInvalid;
    final lat = double.tryParse(_lat.text), lng = double.tryParse(_lng.text);
    if (hasLat && (lat == null || lat.abs() > 90 || lng == null || lng.abs() > 180)) {
      return l10n.orgCoordsInvalid;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await ref.read(orgRepositoryProvider).saveUnit(
            level: widget.level,
            id: widget.unit?.id,
            parentId: widget.parentId,
            code: _code.text,
            name: _name.text,
            address: _address.text,
            lat: double.tryParse(_lat.text.trim()),
            lng: double.tryParse(_lng.text.trim()),
            geofenceRadiusM: _isSection ? int.tryParse(_radius.text) : null,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final levelLabel = orgLevelLabel(l10n, widget.level);
    final decimal = [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))];

    return Form(
      key: _formKey,
      child: SheetScaffold(
        title: widget.unit?.name ?? l10n.orgAdd(levelLabel),
        subtitle: widget.unit == null ? null : levelLabel,
        primaryLabel: l10n.commonSave,
        busy: _busy,
        onPrimary: _save,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 120,
              child: AppTextField(
                label: l10n.orgCode,
                controller: _code,
                required: true,
                textCapitalization: TextCapitalization.characters,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: AppTextField(label: l10n.orgName, controller: _name, required: true)),
          ]),
          if (_isSection) ...[
            const SizedBox(height: AppSpacing.lg),
            AppTextField(label: l10n.orgAddress, controller: _address),
            const SizedBox(height: AppSpacing.lg),
            _SectionLocation(
              lat: double.tryParse(_lat.text.trim()),
              lng: double.tryParse(_lng.text.trim()),
              radiusM: int.tryParse(_radius.text) ?? 300,
              onPick: () async {
                final picked = await pickLocation(
                  context,
                  title: _name.text.trim().isEmpty ? l10n.orgSectionOffice : _name.text.trim(),
                  lat: double.tryParse(_lat.text.trim()),
                  lng: double.tryParse(_lng.text.trim()),
                  radiusM: int.tryParse(_radius.text) ?? 300,
                );
                if (picked == null) return;
                setState(() {
                  _lat.text = picked.lat.toStringAsFixed(6);
                  _lng.text = picked.lng.toStringAsFixed(6);
                  _radius.text = '${picked.radiusM ?? 300}';
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: AppTextField(
                  label: l10n.orgLatitude,
                  controller: _lat,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: decimal,
                  validator: (_) => _coordError(l10n),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  label: l10n.orgLongitude,
                  controller: _lng,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: decimal,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ]),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.orgGeofence,
              helper: l10n.orgGeofenceHelper,
              controller: _radius,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => setState(() {}),
              validator: (v) {
                final n = int.tryParse(v ?? '');
                return (n != null && n >= 25 && n <= 20000) ? null : '25 – 20000';
              },
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Map preview of a section's office and geofence, with "Set on map".
class _SectionLocation extends StatelessWidget {
  const _SectionLocation({required this.lat, required this.lng, required this.radiusM, required this.onPick});

  final double? lat;
  final double? lng;
  final int radiusM;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final has = lat != null && lng != null && lat!.abs() <= 90 && lng!.abs() <= 180;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l10n.orgOfficeLocation, style: AppTypography.label),
      const SizedBox(height: AppSpacing.xs + 2),
      if (has)
        LocationPreview(
          height: 160,
          title: l10n.orgSectionOffice,
          fence: (LatLng(lat!, lng!), radiusM),
          points: [MapPoint(point: LatLng(lat!, lng!), color: AppColors.primary, icon: Icons.location_city_rounded)],
        )
      else
        Container(
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.canvasSoft,
            borderRadius: AppRadius.lgAll,
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.location_off_rounded, color: AppColors.inkMute),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.mapNoLocation, style: AppTypography.caption),
          ]),
        ),
      const SizedBox(height: AppSpacing.sm),
      AppButton.secondary(
        label: has ? l10n.mapChangeOnMap : l10n.mapSetOnMap,
        icon: Icons.map_rounded,
        expand: true,
        onPressed: onPick,
      ),
    ]);
  }
}
