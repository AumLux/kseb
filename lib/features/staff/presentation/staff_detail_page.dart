import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/design.dart';
import '../../../core/format/formatters.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../home/home_page.dart' show roleLabel;
import '../data/staff_repository.dart';
import 'credentials_sheet.dart';
import 'staff_list_page.dart' show staffStatusLabel;

class StaffDetailPage extends ConsumerStatefulWidget {
  const StaffDetailPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<StaffDetailPage> createState() => _StaffDetailPageState();
}

class _StaffDetailPageState extends ConsumerState<StaffDetailPage> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      ref
        ..invalidate(staffMemberProvider(widget.userId))
        ..invalidate(staffListProvider);
    } catch (e) {
      if (mounted) showSnack(context, failureMessage(context.l10n, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset(StaffMember m) async {
    final l10n = context.l10n;
    if (!await confirmAction(context,
        message: l10n.staffResetConfirm(m.fullName), confirmLabel: l10n.staffResetPassword)) {
      return;
    }
    IssuedCredentials? creds;
    await _run(() async => creds = await ref.read(staffRepositoryProvider).resetPassword(m));
    if (creds != null && mounted) await showCredentialsSheet(context, m.fullName, creds!);
  }

  Future<void> _setStatus(StaffMember m, StaffStatus status) async {
    final l10n = context.l10n;
    final (message, label, destructive) = switch (status) {
      StaffStatus.suspended => (l10n.staffSuspendConfirm(m.fullName), l10n.staffSuspend, true),
      StaffStatus.exited => (l10n.staffExitConfirm(m.fullName), l10n.staffMarkExited, true),
      StaffStatus.active => (null, l10n.staffReactivate, false),
    };
    if (message != null &&
        !await confirmAction(context, message: message, confirmLabel: label, destructive: destructive)) {
      return;
    }
    await _run(() async {
      await ref.read(staffRepositoryProvider).setStatus(m.id, status);
      if (mounted) showSnack(context, l10n.staffSaved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final me = ref.watch(currentUserProvider);
    final member = ref.watch(staffMemberProvider(widget.userId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.staffDetails)),
      body: switch (member) {
        AsyncData(:final value) => _body(context, me!, value),
        AsyncError(:final error) => ErrorState(
            title: l10n.commonSomethingWrong,
            message: failureMessage(l10n, error),
            retryLabel: l10n.commonRetry,
            onRetry: () => ref.invalidate(staffMemberProvider(widget.userId)),
          ),
        _ => const LoadingView(),
      },
    );
  }

  Widget _body(BuildContext context, AppUser me, StaffMember m) {
    final l10n = context.l10n;
    final canManage = me.role.atLeast(AppRole.manager) && me.role.outranks(m.role) && m.id != me.id;
    final canReset = canManage ||
        (me.role == AppRole.supervisor &&
            m.role == AppRole.staff &&
            m.teamId != null &&
            me.teamIds.contains(m.teamId));

    Widget fact(String label, String value) => AppListRow(title: value, subtitle: label);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Container(
          color: AppColors.canvas,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primarySoft,
                child: Text(m.fullName[0].toUpperCase(),
                    style: AppTypography.title.copyWith(color: AppColors.primaryInk)),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.fullName, style: AppTypography.subtitle),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
                      StatusChip(label: roleLabel(l10n, m.role), tone: StatusTone.brand, dense: true),
                      StatusChip.fromDomain(m.status.name, label: staffStatusLabel(l10n, m.status)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        fact(l10n.staffEmployeeCode, m.employeeCode),
        fact(l10n.staffSection, m.sectionName ?? '—'),
        fact(l10n.staffTeam, m.teamName ?? l10n.staffNoTeam),
        if (m.phone != null) fact(l10n.staffPhone, m.phone!),
        if (m.email != null) fact(l10n.staffEmail, m.email!),
        if (m.dob != null) fact(l10n.staffDob, Fmt.date(m.dob)),
        fact(l10n.staffJoined, Fmt.date(m.joinedOn)),
        if (canManage || canReset) ...[
          const SizedBox(height: AppSpacing.xl),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                if (canManage && m.status != StaffStatus.exited)
                  AppButton.secondary(
                    label: l10n.staffEdit,
                    icon: Icons.edit_rounded,
                    onPressed: _busy
                        ? null
                        : () async {
                            await context.push('/more/staff/${m.id}/edit');
                            ref.invalidate(staffMemberProvider(widget.userId));
                          },
                  ),
                if (canReset && m.status == StaffStatus.active)
                  AppButton.secondary(
                    label: l10n.staffResetPassword,
                    icon: Icons.key_rounded,
                    loading: _busy,
                    onPressed: () => _reset(m),
                  ),
                if (canManage && m.status == StaffStatus.active)
                  AppButton.tertiary(
                    label: l10n.staffSuspend,
                    onPressed: _busy ? null : () => _setStatus(m, StaffStatus.suspended),
                  ),
                if (canManage && m.status != StaffStatus.active)
                  AppButton.secondary(
                    label: l10n.staffReactivate,
                    onPressed: _busy ? null : () => _setStatus(m, StaffStatus.active),
                  ),
                if (canManage && m.status != StaffStatus.exited)
                  AppButton.tertiary(
                    label: l10n.staffMarkExited,
                    onPressed: _busy ? null : () => _setStatus(m, StaffStatus.exited),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
