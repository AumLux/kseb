import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/sheets.dart';
import '../data/org_repository.dart';

/// Section field that follows the KSEB hierarchy (Circle → Division →
/// Sub-division → Section) instead of one long dropdown, so it stays usable
/// with hundreds of sections. Only [allowed] sections can be picked; branches
/// without any allowed section are hidden.
class SectionPickerField extends ConsumerWidget {
  const SectionPickerField({
    super.key,
    required this.label,
    required this.allowed,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.enabled = true,
  });

  final String label;
  final List<OrgUnit> allowed;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool required;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final tree = ref.watch(orgTreeProvider).value;
    final selected = tree?.byId(value);
    return FormField<String>(
      key: ValueKey(value),
      initialValue: value,
      validator: required ? (v) => v == null ? l10n.fieldRequired(label) : null : null,
      builder: (field) {
        final error = field.errorText;
        Future<void> open() async {
          if (tree == null) return;
          final picked = await showSectionPicker(context, tree: tree, allowed: allowed, selectedId: value, title: label);
          if (picked != null) {
            field.didChange(picked);
            onChanged(picked);
          }
        }

        return Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text.rich(
            TextSpan(text: label, children: [
              if (required) const TextSpan(text: ' *', style: TextStyle(color: AppColors.danger)),
            ]),
            style: AppTypography.label,
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Semantics(
            button: true,
            label: '$label: ${selected?.name ?? l10n.orgChooseSection}',
            excludeSemantics: true,
            child: Pressable(
              onTap: enabled && tree != null ? open : null,
              borderRadius: AppRadius.smAll,
              scale: 0.99,
              child: Container(
                constraints: const BoxConstraints(minHeight: AppSizes.inputHeight),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: enabled ? AppColors.canvas : AppColors.canvasSoft,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: error != null ? AppColors.danger : AppColors.borderInput, width: error != null ? 2 : 1),
                ),
                child: Row(children: [
                  const Icon(Icons.account_tree_rounded, size: AppSizes.iconMd, color: AppColors.inkMute),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: selected == null
                        ? Text(l10n.orgChooseSection, style: AppTypography.body.copyWith(color: AppColors.inkMute))
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                            Text(selected.name, style: AppTypography.bodyStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text(breadcrumb(tree!, selected), style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                          ]),
                  ),
                  const Icon(Icons.unfold_more_rounded, color: AppColors.inkMute),
                ]),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs, left: AppSpacing.md),
              child: Text(error, style: AppTypography.caption.copyWith(color: AppColors.danger)),
            ),
        ]);
      },
    );
  }
}

/// "Circle › Division › Sub-division" for a section (or any unit's ancestors).
String breadcrumb(OrgTree tree, OrgUnit unit) {
  final parts = <String>[];
  var parent = tree.byId(unit.parentId);
  while (parent != null) {
    parts.insert(0, parent.name);
    parent = tree.byId(parent.parentId);
  }
  return parts.join(' › ');
}

/// Drill-down picker. Returns the chosen section id, or null if dismissed.
Future<String?> showSectionPicker(
  BuildContext context, {
  required OrgTree tree,
  required List<OrgUnit> allowed,
  String? selectedId,
  String? title,
}) =>
    showAppSheet<String>(
      context,
      builder: (_) => _SectionPicker(tree: tree, allowed: allowed, selectedId: selectedId, title: title),
    );

class _SectionPicker extends StatefulWidget {
  const _SectionPicker({required this.tree, required this.allowed, this.selectedId, this.title});

  final OrgTree tree;
  final List<OrgUnit> allowed;
  final String? selectedId;
  final String? title;

  @override
  State<_SectionPicker> createState() => _SectionPickerState();
}

class _SectionPickerState extends State<_SectionPicker> {
  final _search = TextEditingController();
  late final Set<String> _allowedIds = {for (final s in widget.allowed) s.id};

  /// Ids of every unit on the path to an allowed section (prunes empty branches).
  late final Set<String> _visible = () {
    final ids = <String>{};
    for (final s in widget.allowed) {
      OrgUnit? u = s;
      while (u != null && ids.add(u.id)) {
        u = widget.tree.byId(u.parentId);
      }
    }
    return ids;
  }();

  /// Current drill-down path (empty = circles).
  late List<OrgUnit> _path = _initialPath();

  List<OrgUnit> _initialPath() {
    // Open where the current choice lives; otherwise skip single-choice levels.
    final selected = widget.tree.byId(widget.selectedId);
    if (selected != null) {
      final path = <OrgUnit>[];
      var p = widget.tree.byId(selected.parentId);
      while (p != null) {
        path.insert(0, p);
        p = widget.tree.byId(p.parentId);
      }
      return path;
    }
    final path = <OrgUnit>[];
    while (true) {
      final kids = _childrenOf(path.isEmpty ? null : path.last);
      if (kids.length != 1 || kids.single.level == OrgLevel.section) return path;
      path.add(kids.single);
    }
  }

  /// Visible children of [parent]; at the top, every visible unit whose parent
  /// isn't loaded (normally the circles; robust to partial org data).
  List<OrgUnit> _childrenOf(OrgUnit? parent) => widget.tree.units
      .where((u) =>
          _visible.contains(u.id) &&
          (parent == null ? widget.tree.byId(u.parentId) == null : u.parentId == parent.id))
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  int _sectionCount(OrgUnit unit) => widget.allowed.where((s) {
        OrgUnit? u = s;
        while (u != null) {
          if (u.id == unit.id) return true;
          u = widget.tree.byId(u.parentId);
        }
        return false;
      }).length;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  IconData _icon(OrgLevel level) => switch (level) {
        OrgLevel.circle => Icons.public_rounded,
        OrgLevel.division => Icons.domain_rounded,
        OrgLevel.subdivision => Icons.apartment_rounded,
        OrgLevel.section => Icons.location_city_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final query = _search.text.trim().toLowerCase();
    final searching = query.isNotEmpty;
    final rows = searching
        ? widget.allowed
            .where((s) =>
                s.name.toLowerCase().contains(query) ||
                s.code.toLowerCase().contains(query) ||
                breadcrumb(widget.tree, s).toLowerCase().contains(query))
            .toList()
        : _childrenOf(_path.isEmpty ? null : _path.last);

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.md),
            child: Text(widget.title ?? l10n.orgChooseSection, style: AppTypography.title),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.orgSearchSections,
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
          ),
          if (!searching)
            SizedBox(
              height: 48,
              // Reversed so the row starts scrolled to its end: the current
              // level is always visible, earlier levels scroll in from the left.
              child: ListView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                children: [
                  _Crumb(label: l10n.orgAllCircles, active: _path.isEmpty, onTap: () => setState(() => _path = [])),
                  for (var i = 0; i < _path.length; i++) ...[
                    const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.inkDisabled),
                    _Crumb(
                      label: _path[i].name,
                      active: i == _path.length - 1,
                      onTap: () => setState(() => _path = _path.sublist(0, i + 1)),
                    ),
                  ],
                ].reversed.toList(),
              ),
            ),
          const Divider(),
          Expanded(
            child: rows.isEmpty
                ? EmptyState(icon: Icons.search_off_rounded, title: l10n.orgNoSectionsFound)
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, i) {
                      final u = rows[i];
                      final isSection = u.level == OrgLevel.section;
                      final chosen = u.id == widget.selectedId;
                      return AppListRow(
                        selected: chosen,
                        leading: IconTile(_icon(u.level), size: 36, color: isSection ? AppColors.primaryDeep : AppColors.inkSecondary),
                        title: u.name,
                        subtitle: isSection
                            ? [u.code, if (searching) breadcrumb(widget.tree, u)].join(' · ')
                            : '${u.code} · ${l10n.orgSectionsCount(_sectionCount(u))}',
                        trailing: isSection
                            ? Icon(chosen ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: chosen ? AppColors.primary : AppColors.borderInput)
                            : null,
                        onTap: isSection
                            ? (_allowedIds.contains(u.id) ? () => Navigator.pop(context, u.id) : null)
                            : () => setState(() => _path = [..._path, u]),
                      );
                    },
                  ),
          ),
        ]),
      ),
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
