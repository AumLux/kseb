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

    // Account actions as a Notion-style list: icon, label, one tap.
    final actions = <(IconData, String, Color, VoidCallback?)>[
      if (canManage && m.status != StaffStatus.exited)
        (Icons.edit_rounded, l10n.staffEdit, AppColors.primaryDeep, () async {
          await context.push('/more/staff/${m.id}/edit');
          ref.invalidate(staffMemberProvider(widget.userId));
        }),
      if (canReset && m.status == StaffStatus.active)
        (Icons.key_rounded, l10n.staffResetPassword, AppColors.info, () => _reset(m)),
      if (canManage && m.status != StaffStatus.active)
        (Icons.restart_alt_rounded, l10n.staffReactivate, AppColors.success, () => _setStatus(m, StaffStatus.active)),
      if (canManage && m.status == StaffStatus.active)
        (Icons.pause_circle_rounded, l10n.staffSuspend, AppColors.warning, () => _setStatus(m, StaffStatus.suspended)),
      if (canManage && m.status != StaffStatus.exited)
        (Icons.logout_rounded, l10n.staffMarkExited, AppColors.danger, () => _setStatus(m, StaffStatus.exited)),
    ];

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
      children: [
        FadeSlideIn(
          child: DetailHeader(
            leading: Avatar(m.fullName, size: 56),
            title: m.fullName,
            subtitle: m.employeeCode,
            status: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
              StatusChip(label: roleLabel(l10n, m.role), tone: StatusTone.brand, dense: true),
              StatusChip.fromDomain(m.status.name, label: staffStatusLabel(l10n, m.status)),
            ]),
          ),
        ),
        InfoGroup(title: l10n.commonDetails, rows: [
          InfoRow(l10n.staffEmployeeCode, m.employeeCode, icon: Icons.badge_rounded, tabular: true),
          InfoRow(l10n.staffSection, m.sectionName ?? '—', icon: Icons.location_city_rounded),
          InfoRow(l10n.staffTeam, m.teamName ?? l10n.staffNoTeam, icon: Icons.groups_rounded),
          InfoRow(l10n.staffPhone, m.phone, icon: Icons.call_rounded, tabular: true),
          InfoRow(l10n.staffEmail, m.email, icon: Icons.mail_rounded),
          InfoRow(l10n.staffDob, m.dob == null ? null : Fmt.date(m.dob), icon: Icons.cake_rounded),
          InfoRow(l10n.staffJoined, Fmt.date(m.joinedOn), icon: Icons.event_available_rounded),
        ]),
        if (actions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final (i, (icon, label, tint, onTap)) in actions.indexed)
                AppListRow(
                  leading: IconTile(icon, color: tint, size: 36),
                  title: label,
                  showDivider: i < actions.length - 1,
                  onTap: _busy ? null : onTap,
                ),
            ]),
          ),
        ],
      ],
    );
  }
}
