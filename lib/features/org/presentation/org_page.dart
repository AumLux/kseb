import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/application/session_controller.dart';
import '../data/org_repository.dart';

String orgLevelLabel(AppLocalizations l10n, OrgLevel level) => switch (level) {
      OrgLevel.circle => l10n.orgCircle,
      OrgLevel.division => l10n.orgDivision,
      OrgLevel.subdivision => l10n.orgSubdivision,
      OrgLevel.section => l10n.orgSectionOffice,
    };

/// KSEB hierarchy: Circle → Division → Sub-division → Section office.
/// Everyone may browse; only COO/Director edit (enforced by RLS too).
class OrgPage extends ConsumerWidget {
  const OrgPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final canEdit = ref.watch(currentUserProvider)?.role.isExecutive ?? false;
    final tree = ref.watch(orgTreeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.orgTitle)),
      floatingActionButton: canEdit && tree.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _edit(context, ref, OrgLevel.circle),
              icon: const Icon(Icons.add_rounded),
              label: Text(l10n.orgAdd(l10n.orgCircle)),
            )
          : null,
      body: switch (tree) {
        AsyncData(:final value) => value.units.isEmpty
            ? EmptyState(icon: Icons.account_tree_rounded, title: l10n.orgEmpty)
            : ListView(
                padding: const EdgeInsets.only(bottom: 96),
                children: [
                  for (final c in value.of(OrgLevel.circle))
                    _Node(unit: c, tree: value, canEdit: canEdit, depth: 0),
                ],
              ),
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
}

Future<void> _edit(BuildContext context, WidgetRef ref, OrgLevel level,
    {OrgUnit? unit, String? parentId}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _UnitForm(level: level, unit: unit, parentId: parentId),
  );
  if (saved == true) ref.invalidate(orgTreeProvider);
}

class _Node extends ConsumerWidget {
  const _Node({required this.unit, required this.tree, required this.canEdit, required this.depth});

  final OrgUnit unit;
  final OrgTree tree;
  final bool canEdit;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final child = unit.level.child;
    final children = child == null ? const <OrgUnit>[] : tree.of(child, parentId: unit.id);
    final subtitle = [
      orgLevelLabel(l10n, unit.level),
      unit.code,
      if (unit.level == OrgLevel.section && unit.lat == null) l10n.orgNoLocation,
    ].join(' · ');

    final editButton = canEdit
        ? IconButton(
            tooltip: l10n.staffEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => _edit(context, ref, unit.level, unit: unit, parentId: unit.parentId),
          )
        : null;

    if (child == null) {
      return Padding(
        padding: EdgeInsets.only(left: AppSpacing.lg * depth),
        child: AppListRow(
          leading: const Icon(Icons.location_on_outlined, color: AppColors.inkMute),
          title: unit.name,
          subtitle: subtitle,
          trailing: editButton,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: AppSpacing.lg * depth),
      child: ExpansionTile(
        initiallyExpanded: depth < 1,
        backgroundColor: AppColors.canvas,
        collapsedBackgroundColor: AppColors.canvas,
        title: Text(unit.name, style: AppTypography.bodyStrong),
        subtitle: Text(subtitle, style: AppTypography.caption),
        trailing: editButton,
        children: [
          for (final c in children) _Node(unit: c, tree: tree, canEdit: canEdit, depth: depth + 1),
          if (canEdit)
            Padding(
              padding: EdgeInsets.only(left: AppSpacing.lg * (depth + 1)),
              child: Align(
                alignment: Alignment.centerLeft,
                child: AppButton.tertiary(
                  label: l10n.orgAdd(orgLevelLabel(l10n, child)),
                  icon: Icons.add_rounded,
                  onPressed: () => _edit(context, ref, child, parentId: unit.id),
                ),
              ),
            ),
        ],
      ),
    );
  }
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

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(widget.unit?.name ?? l10n.orgAdd(levelLabel), style: AppTypography.subtitle),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: l10n.orgCode,
                controller: _code,
                required: true,
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(label: l10n.orgName, controller: _name, required: true),
              if (_isSection) ...[
                const SizedBox(height: AppSpacing.lg),
                AppTextField(label: l10n.orgAddress, controller: _address),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: l10n.orgLatitude,
                        controller: _lat,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        inputFormatters: decimal,
                        validator: (_) => _coordError(l10n),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppTextField(
                        label: l10n.orgLongitude,
                        controller: _lng,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        inputFormatters: decimal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                AppTextField(
                  label: l10n.orgGeofence,
                  helper: l10n.orgGeofenceHelper,
                  controller: _radius,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return (n != null && n >= 25 && n <= 20000) ? null : '25 – 20000';
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              AppButton(label: l10n.commonSave, loading: _busy, expand: true, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
