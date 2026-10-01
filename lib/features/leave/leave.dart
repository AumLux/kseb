import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/design/design.dart';
import '../../core/errors/app_failure.dart';
import '../../core/format/ist.dart';
import '../../core/l10n/l10n.dart';
import '../../core/outbox/outbox.dart';
import '../../core/supabase/providers.dart';
import '../../core/ui/dialogs.dart';
import '../auth/application/session_controller.dart';

enum LeaveType { casual, sick, earned, unpaid, other }

String leaveTypeLabel(AppLocalizations l10n, LeaveType t) => switch (t) {
      LeaveType.casual => l10n.leaveTypeCasual,
      LeaveType.sick => l10n.leaveTypeSick,
      LeaveType.earned => l10n.leaveTypeEarned,
      LeaveType.unpaid => l10n.leaveTypeUnpaid,
      LeaveType.other => l10n.leaveTypeOther,
    };

String requestStatusLabel(AppLocalizations l10n, String status) => switch (status) {
      'pending' => l10n.statusPending,
      'approved' => l10n.statusApproved,
      'rejected' => l10n.statusRejected,
      'cancelled' => l10n.statusCancelled,
      _ => status,
    };

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.from,
    required this.to,
    required this.type,
    required this.reason,
    required this.status,
    this.decisionNote,
  });

  final String id;
  final DateTime from;
  final DateTime to;
  final LeaveType type;
  final String reason;
  final String status;
  final String? decisionNote;

  int get days => to.difference(from).inDays + 1;

  factory LeaveRequest.fromJson(Map<String, dynamic> j) => LeaveRequest(
        id: j['id'] as String,
        from: DateTime.parse(j['from_date'] as String),
        to: DateTime.parse(j['to_date'] as String),
        type: LeaveType.values.byName(j['leave_type'] as String),
        reason: j['reason'] as String,
        status: j['status'] as String,
        decisionNote: j['decision_note'] as String?,
      );
}

final leaveRepositoryProvider =
    Provider<LeaveRepository>((ref) => LeaveRepository(ref.watch(supabaseClientProvider), ref));

final myLeaveProvider = FutureProvider.autoDispose<List<LeaveRequest>>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.watch(leaveRepositoryProvider).mine(me.id);
});

class LeaveRepository {
  LeaveRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<List<LeaveRequest>> mine(String userId) async {
    try {
      final rows = await _client
          .from('leave_requests')
          .select()
          .eq('user_id', userId)
          .order('from_date', ascending: false)
          .limit(50);
      return rows.map(LeaveRequest.fromJson).toList();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Queued through the outbox so a request made without signal is not lost.
  Future<bool> request({
    required DateTime from,
    required DateTime to,
    required LeaveType type,
    required String reason,
  }) async {
    final id = const Uuid().v4();
    final outbox = _ref.read(outboxProvider.notifier);
    await outbox.enqueue(OutboxOp(
      id: id,
      kind: OutboxKind.insert,
      name: 'leave_requests',
      label: 'Leave ${Ist.iso(from)} → ${Ist.iso(to)}',
      createdAt: DateTime.now().toUtc(),
      payload: {
        'id': id,
        'from_date': Ist.iso(from),
        'to_date': Ist.iso(to),
        'leave_type': type.name,
        'reason': reason.trim(),
      },
    ));
    await outbox.process();
    final op = _ref.read(outboxProvider).ops.where((o) => o.id == id).firstOrNull;
    if (op?.failed ?? false) {
      await outbox.discard(id);
      throw AppFailure('rejected', op!.lastError ?? 'Request was rejected.');
    }
    return op == null; // true = synced now; false = queued offline
  }

  Future<void> cancel(String id) async {
    try {
      await _client.rpc('cancel_leave', params: {'p_id': id});
    } catch (e) {
      throw AppFailure.from(e);
    }
  }
}

class LeavePage extends ConsumerWidget {
  const LeavePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final leave = ref.watch(myLeaveProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.leaveMine)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final sent = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            builder: (_) => const _LeaveForm(),
          );
          if (sent == true) ref.invalidate(myLeaveProvider);
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.leaveRequest),
      ),
      body: switch (leave) {
        AsyncData(:final value) => value.isEmpty
            ? EmptyState(icon: Icons.beach_access_rounded, title: l10n.leaveEmpty)
            : LazyListView(
                padding: const EdgeInsets.only(bottom: 96),
                itemCount: value.length,
                  itemBuilder: (context, i) {
                    final r = value[i];
                    return AppListRow(
                      title: '${leaveTypeLabel(l10n, r.type)} · ${l10n.leaveDays(r.days)}',
                      subtitle: [
                        '${MaterialLocalizations.of(context).formatMediumDate(r.from)} – '
                            '${MaterialLocalizations.of(context).formatMediumDate(r.to)}',
                        r.reason,
                        if (r.decisionNote != null) r.decisionNote!,
                      ].join('\n'),
                      trailing: r.status == 'pending'
                          ? Column(mainAxisSize: MainAxisSize.min, children: [
                              StatusChip.fromDomain(r.status, label: requestStatusLabel(l10n, r.status)),
                              TextButton(
                                onPressed: () async {
                                  if (!await confirmAction(context,
                                      message: '${l10n.leaveCancel}?', confirmLabel: l10n.leaveCancel)) {
                                    return;
                                  }
                                  try {
                                    await ref.read(leaveRepositoryProvider).cancel(r.id);
                                    ref.invalidate(myLeaveProvider);
                                  } catch (e) {
                                    if (context.mounted) showSnack(context, failureMessage(l10n, e));
                                  }
                                },
                                child: Text(l10n.commonCancel),
                              ),
                            ])
                          : StatusChip.fromDomain(r.status, label: requestStatusLabel(l10n, r.status)),
                    );
                  },
              ),
        AsyncError(:final error) => ErrorState(
            title: l10n.commonSomethingWrong,
            message: failureMessage(l10n, error),
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(myLeaveProvider),
          ),
        _ => const LoadingView(),
      },
    );
  }
}

class _LeaveForm extends ConsumerStatefulWidget {
  const _LeaveForm();

  @override
  ConsumerState<_LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends ConsumerState<_LeaveForm> {
  final _formKey = GlobalKey<FormState>();
  final _reason = TextEditingController();
  DateTime _from = Ist.today().add(const Duration(days: 1));
  DateTime _to = Ist.today().add(const Duration(days: 1));
  LeaveType _type = LeaveType.casual;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<DateTime?> _pick(DateTime initial) => showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: Ist.today().subtract(const Duration(days: 7)),
        lastDate: Ist.today().add(const Duration(days: 180)),
      );

  Future<void> _submit() async {
    final l10n = context.l10n;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final synced = await ref
          .read(leaveRepositoryProvider)
          .request(from: _from, to: _to, type: _type, reason: _reason.text);
      if (!mounted) return;
      showSnack(context, synced ? l10n.leaveSent : l10n.attQueued);
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
    final fmt = MaterialLocalizations.of(context).formatMediumDate;

    Widget dateField(String label, DateTime value, ValueChanged<DateTime> set) => Expanded(
          child: AppTextField(
            key: ValueKey('$label$value'),
            label: label,
            initialValue: fmt(value),
            readOnly: true,
            suffix: const Icon(Icons.calendar_today_rounded),
            onTap: () async {
              final d = await _pick(value);
              if (d != null) set(d);
            },
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl + MediaQuery.viewInsetsOf(context).bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.leaveRequest, style: AppTypography.subtitle),
            const SizedBox(height: AppSpacing.lg),
            Row(children: [
              dateField(l10n.leaveFrom, _from, (d) => setState(() {
                    _from = d;
                    if (_to.isBefore(d)) _to = d;
                  })),
              const SizedBox(width: AppSpacing.md),
              dateField(l10n.leaveTo, _to, (d) => setState(() => _to = d)),
            ]),
            if (_to.isBefore(_from))
              Text(l10n.leaveDateOrder, style: AppTypography.caption.copyWith(color: AppColors.danger)),
            const SizedBox(height: AppSpacing.lg),
            AppDropdownField<LeaveType>(
              label: l10n.leaveType,
              items: LeaveType.values,
              value: _type,
              itemLabel: (t) => leaveTypeLabel(l10n, t),
              onChanged: (t) => setState(() => _type = t ?? _type),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppTextField(
              label: l10n.leaveReason,
              controller: _reason,
              required: true,
              maxLines: 2,
              validator: (v) => (v?.trim().length ?? 0) >= 3 ? null : l10n.fieldRequired(l10n.leaveReason),
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: l10n.leaveSubmit,
              loading: _busy,
              expand: true,
              onPressed: _to.isBefore(_from) ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
