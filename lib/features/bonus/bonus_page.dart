import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design/design.dart';
import '../../core/errors/app_failure.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/l10n.dart';
import '../../core/supabase/providers.dart';
import '../../core/ui/dialogs.dart';
import '../auth/application/session_controller.dart';
import '../auth/domain/app_user.dart';
import '../leave/leave.dart' show requestStatusLabel;
import '../org/data/org_repository.dart';

/// Bonus ledger (shown only when built with --dart-define=ENABLE_BONUS_MODULE=true).
/// Totals are derived from approved ledger entries; nothing is stored on
/// the profile, and only the COO/Director approve (approvals inbox).
class BonusEntry {
  const BonusEntry({
    required this.id,
    required this.userId,
    required this.points,
    required this.amount,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int points;
  final num amount;
  final String reason;
  final String status;
  final DateTime createdAt;

  factory BonusEntry.fromJson(Map<String, dynamic> j) => BonusEntry(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        points: j['points'] as int? ?? 0,
        amount: (j['amount'] as num?) ?? 0,
        reason: j['reason'] as String,
        status: j['status'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}

final bonusEntriesProvider = FutureProvider.autoDispose<List<BonusEntry>>((ref) async {
  try {
    final rows = await ref.watch(supabaseClientProvider).from('bonus_ledger').select().order('created_at', ascending: false).limit(200);
    return rows.map(BonusEntry.fromJson).toList();
  } catch (e) {
    throw AppFailure.from(e);
  }
});

class BonusPage extends ConsumerWidget {
  const BonusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final entries = ref.watch(bonusEntriesProvider);
    final people = ref.watch(directoryProvider).value ?? const <Person>[];
    final mine = (entries.value ?? const <BonusEntry>[]).where((e) => e.userId == me.id && e.status == 'approved');
    final points = mine.fold<int>(0, (s, e) => s + e.points);
    final amount = mine.fold<num>(0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.bonusTitle)),
      floatingActionButton: me.role.atLeast(AppRole.supervisor)
          ? FloatingActionButton.extended(
              onPressed: () async {
                final ok = await showModalBottomSheet<bool>(
                    context: context, isScrollControlled: true, builder: (_) => const _ProposeSheet());
                if (ok == true) ref.invalidate(bonusEntriesProvider);
              },
              icon: const Icon(Icons.card_giftcard_rounded),
              label: Text(l10n.bonusPropose),
            )
          : null,
      body: switch (entries) {
        AsyncData(:final value) => ListView(padding: const EdgeInsets.only(bottom: 96), children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(children: [
                Expanded(child: KpiCard(label: l10n.bonusPoints, value: Fmt.qty(points), featured: true)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: KpiCard(label: l10n.bonusAmount, value: Fmt.money(amount))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(l10n.bonusPendingNote, style: AppTypography.caption),
            ),
            if (value.isEmpty)
              EmptyState(icon: Icons.card_giftcard_rounded, title: l10n.bonusEmpty)
            else
              for (final e in value)
                AppListRow(
                  title: e.reason,
                  subtitle: [
                    if (e.userId != me.id) people.where((p) => p.id == e.userId).firstOrNull?.fullName ?? '—',
                    if (e.points != 0) '${e.points} pts',
                    if (e.amount != 0) Fmt.money(e.amount),
                    Fmt.date(e.createdAt),
                  ].join(' · '),
                  trailing: StatusChip.fromDomain(e.status, label: requestStatusLabel(l10n, e.status)),
                ),
          ]),
        AsyncError(:final error) => ErrorState(title: failureMessage(l10n, error), onRetry: () => ref.invalidate(bonusEntriesProvider)),
        _ => const LoadingView(),
      },
    );
  }
}

class _ProposeSheet extends ConsumerStatefulWidget {
  const _ProposeSheet();

  @override
  ConsumerState<_ProposeSheet> createState() => _ProposeSheetState();
}

class _ProposeSheetState extends ConsumerState<_ProposeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _points = TextEditingController();
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  String? _userId;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_points, _amount, _reason]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final points = int.tryParse(_points.text) ?? 0;
    final amount = num.tryParse(_amount.text) ?? 0;
    if (points == 0 && amount == 0) {
      showSnack(context, l10n.bonusNeedValue);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(supabaseClientProvider).from('bonus_ledger').insert({
        'user_id': _userId,
        'points': points,
        'amount': amount,
        'reason': _reason.text.trim(),
      });
      if (!mounted) return;
      showSnack(context, l10n.bonusProposed);
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
    final people = (ref.watch(directoryProvider).value ?? const <Person>[])
        .where((p) => p.active && p.id != me.id && me.role.outranks(p.role) && me.sectionIds.contains(p.sectionId))
        .toList();
    final digits = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l10n.bonusPropose, style: AppTypography.subtitle),
          const SizedBox(height: AppSpacing.lg),
          AppDropdownField<String>(
            label: l10n.bonusFor,
            required: true,
            items: people.map((p) => p.id).toList(),
            value: _userId,
            itemLabel: (id) {
              final p = people.firstWhere((p) => p.id == id);
              return '${p.fullName} (${p.employeeCode})';
            },
            onChanged: (v) => setState(() => _userId = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            Expanded(child: AppTextField(label: l10n.bonusPoints, controller: _points, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: AppTextField(label: '${l10n.bonusAmount} (₹)', controller: _amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: digits)),
          ]),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: l10n.bonusReason,
            hint: l10n.bonusReasonHint,
            controller: _reason,
            required: true,
            maxLines: 2,
            validator: (v) => (v?.trim().length ?? 0) >= 5 ? null : l10n.attReasonTooShort,
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(label: l10n.bonusPropose, expand: true, loading: _busy, onPressed: _save),
        ]),
      ),
    );
  }
}
