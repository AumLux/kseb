import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/media/photo_strip.dart';
import '../../../core/ui/dialogs.dart';
import '../../approvals/approvals_page.dart' show approvalsProvider;
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../org/data/org_repository.dart';
import '../data/worksheet_repository.dart';
import 'worksheet_labels.dart';
import 'worksheet_sheets.dart';

class WorksheetDetailPage extends ConsumerStatefulWidget {
  const WorksheetDetailPage({super.key, required this.id});

  final String id;

  @override
  ConsumerState<WorksheetDetailPage> createState() => _WorksheetDetailPageState();
}

class _WorksheetDetailPageState extends ConsumerState<WorksheetDetailPage> {
  String? _busy;

  void _refresh() {
    ref
      ..invalidate(worksheetProvider(widget.id))
      ..invalidate(permitProvider(widget.id))
      ..invalidate(worksheetCrewProvider(widget.id))
      ..invalidate(worksheetIncidentsProvider(widget.id))
      ..invalidate(approvalsProvider);
  }

  Future<void> _transition(String action, {String? note}) async {
    setState(() => _busy = action);
    try {
      await ref.read(worksheetRepositoryProvider).transition(widget.id, action, note: note);
      _refresh();
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<String?> _ask(String title, String label, {bool required = true}) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final l10n = context.l10n;
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Form(
          key: formKey,
          child: AppTextField(
            label: label,
            controller: controller,
            required: required,
            maxLines: 3,
            validator: required ? (v) => (v?.trim().length ?? 0) >= 3 ? null : l10n.fieldRequired(label) : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) Navigator.pop(context, controller.text.trim());
            },
            child: Text(l10n.commonContinue),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ws = ref.watch(worksheetProvider(widget.id));
    return Scaffold(
      appBar: AppBar(title: Text(ws.value?.code ?? l10n.wsTitle)),
      body: switch (ws) {
        AsyncData(:final value) => RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: _body(context, value),
          ),
        AsyncError(:final error) => ErrorState(
            title: l10n.commonSomethingWrong,
            message: failureMessage(l10n, error),
            retryLabel: l10n.commonRetry,
            onRetry: _refresh,
          ),
        _ => const LoadingView(),
      },
    );
  }

  Widget _body(BuildContext context, Worksheet w) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider)!;
    final people = ref.watch(directoryProvider).value ?? const <Person>[];
    final requester = people.where((p) => p.id == w.requestedBy).firstOrNull;
    final isRequester = w.requestedBy == me.id;
    final isApprover = !isRequester && requester != null && me.role.outranks(requester.role);
    final canManage = isRequester || isApprover;
    final permit = ref.watch(permitProvider(w.id)).value;
    final crewIds = ref.watch(worksheetCrewProvider(w.id)).value ?? const <String>[];
    final incidents = ref.watch(worksheetIncidentsProvider(w.id)).value ?? const <Incident>[];

    final actions = <Widget>[
      if (isRequester && w.editable) ...[
        AppButton(
          label: l10n.wsActionSubmit,
          icon: Icons.send_rounded,
          expand: true,
          loading: _busy == 'submit',
          onPressed: _busy == null ? () => _transition('submit') : null,
        ),
        AppButton.secondary(
          label: l10n.wsEdit,
          expand: true,
          onPressed: () async {
            await context.push('/work/${w.id}/edit');
            _refresh();
          },
        ),
      ],
      if (isApprover && w.status == WorksheetStatus.submitted)
        Row(children: [
          Expanded(
            child: AppButton.secondary(
              label: l10n.wsActionReject,
              loading: _busy == 'reject',
              onPressed: _busy == null
                  ? () async {
                      final note = await _ask(l10n.wsActionReject, l10n.approvalsRejectReason);
                      if (note != null) await _transition('reject', note: note);
                    }
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              label: l10n.wsActionApprove,
              loading: _busy == 'approve',
              onPressed: _busy == null ? () => _transition('approve') : null,
            ),
          ),
        ]),
      if (canManage && w.status == WorksheetStatus.approved)
        AppButton(
          label: l10n.wsActionStart,
          icon: Icons.play_arrow_rounded,
          expand: true,
          loading: _busy == 'start',
          onPressed: _busy == null && (permit?.complete ?? false) ? () => _transition('start') : null,
        ),
      if (canManage && w.status == WorksheetStatus.inProgress)
        AppButton(
          label: l10n.wsActionComplete,
          icon: Icons.task_alt_rounded,
          expand: true,
          loading: _busy == 'complete',
          onPressed: _busy == null
              ? () async {
                  final note = await _ask(l10n.wsActionComplete, l10n.wsCompletionNote, required: false);
                  if (note != null) await _transition('complete', note: note);
                }
              : null,
        ),
      if (canManage && !w.closed && w.status != WorksheetStatus.inProgress)
        AppButton.tertiary(
          label: l10n.wsActionCancel,
          onPressed: _busy == null
              ? () async {
                  if (await confirmAction(context,
                      message: l10n.wsCancelConfirm, confirmLabel: l10n.wsActionCancel, destructive: true)) {
                    await _transition('cancel');
                  }
                }
              : null,
        ),
    ];

    Widget fact(String label, String? value) =>
        value == null || value.isEmpty ? const SizedBox.shrink() : AppListRow(title: value, subtitle: label);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        Container(
          color: AppColors.canvas,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              worksheetChip(l10n, w.status),
              StatusChip(label: workTypeLabel(l10n, w.workType), dense: true),
            ]),
            const SizedBox(height: AppSpacing.sm),
            Text(w.title, style: AppTypography.title),
            Text([?w.sectionName, w.locationText].join(' · '), style: AppTypography.caption),
            if (w.decisionNote != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text('${l10n.wsDecision}: ${w.decisionNote}', style: AppTypography.label),
            ],
          ]),
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [for (final a in actions) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: a)],
            ),
          ),
        fact(l10n.wsRequestedBy, requester?.fullName),
        fact(l10n.wsPlannedDate, w.plannedDate == null ? null : Fmt.date(w.plannedDate)),
        fact(l10n.wsPermitBook, w.permitBookNo),
        fact(l10n.wsDescription, w.description),
        fact(l10n.wsCompletionNote, w.completionNote),
        if (w.lat != null) fact('GPS', '${w.lat!.toStringAsFixed(5)}, ${w.lng!.toStringAsFixed(5)}'),

        // Permit to work
        SectionHeader(
          l10n.wsPermit,
          action: me.role.atLeast(AppRole.supervisor) &&
                  canManage &&
                  (w.status == WorksheetStatus.approved || w.status == WorksheetStatus.inProgress)
              ? AppButton.tertiary(
                  label: l10n.wsPermitSign,
                  icon: Icons.draw_rounded,
                  onPressed: () async {
                    if (await showPermitSheet(context, w.id, existing: permit)) _refresh();
                  },
                )
              : null,
        ),
        if (permit == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(l10n.wsPermitMissing, style: AppTypography.caption),
          )
        else
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('LC ${permit.lineClearRef} · ${permit.lineClearIssuedBy}', style: AppTypography.bodyStrong),
              Text(permit.isolationPoints, style: AppTypography.caption),
              const SizedBox(height: AppSpacing.sm),
              Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
                for (final (ok, label) in [
                  (permit.earthingDone, l10n.wsPermitEarthing),
                  (permit.testedDead, l10n.wsPermitTestedDead),
                  (permit.toolboxTalkDone, l10n.wsPermitToolbox),
                ])
                  StatusChip(label: label, tone: ok ? StatusTone.success : StatusTone.danger, dense: true),
                for (final p in permit.ppe) StatusChip(label: ppeLabel(l10n, p), tone: StatusTone.info, dense: true),
              ]),
              const SizedBox(height: AppSpacing.xs),
              Text(l10n.wsPermitSignedBy(Fmt.dateTime(permit.signedAt)), style: AppTypography.caption),
            ]),
          ),

        // Crew
        SectionHeader(
          l10n.wsCrew,
          action: canManage && !w.closed
              ? AppButton.tertiary(
                  label: l10n.wsCrewEdit,
                  icon: Icons.group_add_rounded,
                  onPressed: () async {
                    if (await showCrewSheet(context, w, crewIds)) _refresh();
                  },
                )
              : null,
        ),
        if (crewIds.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(l10n.wsCrewEmpty, style: AppTypography.caption),
          )
        else
          for (final p in people.where((p) => crewIds.contains(p.id)))
            AppListRow(
              leading: const Icon(Icons.engineering_rounded, color: AppColors.inkMute),
              title: p.fullName,
              subtitle: p.employeeCode,
            ),

        PhotoStrip(owner: (table: 'worksheets', id: w.id), canAdd: !w.closed),

        // Incidents
        SectionHeader(
          l10n.incTitle,
          action: AppButton.tertiary(
            label: l10n.incReport,
            icon: Icons.report_rounded,
            onPressed: () async {
              if (await showIncidentSheet(context, sectionId: w.sectionId, worksheetId: w.id)) _refresh();
            },
          ),
        ),
        if (incidents.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(l10n.incNone, style: AppTypography.caption),
          )
        else
          for (final i in incidents)
            AppListRow(
              leading: Icon(Icons.health_and_safety_rounded,
                  color: i.severity == IncidentSeverity.nearMiss ? AppColors.warning : AppColors.danger),
              title: severityLabel(l10n, i.severity),
              subtitle: '${i.code} · ${Fmt.dateTime(i.occurredAt)}\n${i.description}',
              trailing: StatusChip.fromDomain(
                i.status == 'closed' ? 'completed' : 'pending',
                label: switch (i.status) {
                  'closed' => l10n.incStatusClosed,
                  'investigating' => l10n.incStatusInvestigating,
                  _ => l10n.incStatusOpen,
                },
              ),
            ),
      ],
    );
  }
}
