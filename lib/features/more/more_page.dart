import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/feature_flags.dart';
import '../../core/design/design.dart';
import '../../core/l10n/l10n.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/outbox/outbox.dart';
import '../../core/router/app_router.dart';
import '../auth/application/session_controller.dart';
import '../auth/domain/app_user.dart';
import '../auth/presentation/change_password_page.dart';
import '../home/home_page.dart' show roleLabel;

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref, int pending) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.moreSignOutConfirmTitle),
        content: Text(pending > 0 ? l10n.moreSignOutPendingBody(pending) : l10n.moreSignOutConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.moreSignOut)),
        ],
      ),
    );
    if (ok == true) await ref.read(sessionProvider.notifier).signOut();
  }

  Future<void> _pickLanguage(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final current = ref.read(localeProvider).languageCode;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<String>(
          groupValue: current,
          onChanged: (v) => Navigator.pop(context, v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(value: 'en', title: Text(l10n.languageEnglish)),
              RadioListTile<String>(value: 'ml', title: Text(l10n.languageMalayalam)),
            ],
          ),
        ),
      ),
    );
    if (picked != null) await ref.read(localeProvider.notifier).set(Locale(picked));
  }

  Future<void> _about(BuildContext context) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;
    showLicensePage(
      context: context,
      applicationName: context.l10n.appName,
      applicationVersion: '${info.version} (${info.buildNumber})',
      applicationIcon: const Padding(padding: EdgeInsets.all(AppSpacing.lg), child: BrandMark()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final outbox = ref.watch(outboxProvider);
    final locale = ref.watch(localeProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        children: [
          Container(
            color: AppColors.canvas,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: AppTypography.title.copyWith(color: AppColors.primaryInk),
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: AppTypography.subtitle),
                      const SizedBox(height: AppSpacing.xxs),
                      Text('${user.employeeCode} · ${roleLabel(l10n, user.role)}',
                          style: AppTypography.caption),
                      if (user.email != null || user.phone != null)
                        Text(user.email ?? user.phone!, style: AppTypography.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          if (user.role.atLeast(AppRole.supervisor)) ...[
            SectionHeader(l10n.adminSection),
            AppListRow(
              leading: const Icon(Icons.groups_rounded, color: AppColors.inkMute),
              title: user.role.atLeast(AppRole.manager) ? l10n.staffTitle : l10n.staffMyTeam,
              onTap: () => context.go(Routes.staff),
            ),
            if (user.role.atLeast(AppRole.manager))
              AppListRow(
                leading: const Icon(Icons.groups_2_rounded, color: AppColors.inkMute),
                title: l10n.teamsTitle,
                onTap: () => context.go(Routes.teams),
              ),
            if (user.role.atLeast(AppRole.manager))
              AppListRow(
                leading: const Icon(Icons.event_rounded, color: AppColors.inkMute),
                title: l10n.holidaysTitle,
                onTap: () => context.go(Routes.holidays),
              ),
            if (user.role.isExecutive)
              AppListRow(
                leading: const Icon(Icons.account_tree_rounded, color: AppColors.inkMute),
                title: l10n.orgTitle,
                onTap: () => context.go(Routes.org),
              ),
          ],
          if (user.role.atLeast(AppRole.manager))
            AppListRow(
              leading: const Icon(Icons.gavel_rounded, color: AppColors.inkMute),
              title: l10n.comTitle,
              onTap: () => context.go(Routes.commercial),
            ),
          SectionHeader(l10n.regSection),
          AppListRow(
            leading: const Icon(Icons.inventory_2_rounded, color: AppColors.inkMute),
            title: l10n.invTitle,
            onTap: () => context.go(Routes.inventory),
          ),
          AppListRow(
            leading: const Icon(Icons.electrical_services_rounded, color: AppColors.inkMute),
            title: l10n.poleTitle,
            onTap: () => context.go(Routes.poles),
          ),
          AppListRow(
            leading: const Icon(Icons.devices_other_rounded, color: AppColors.inkMute),
            title: l10n.assetTitle,
            onTap: () => context.go(Routes.assets),
          ),
          SectionHeader(l10n.moreTitle),
          if (FeatureFlags.enableBonusModule)
            AppListRow(
              leading: const Icon(Icons.card_giftcard_rounded, color: AppColors.inkMute),
              title: l10n.bonusTitle,
              onTap: () => context.go(Routes.bonus),
            ),
          AppListRow(
            leading: const Icon(Icons.sync_rounded, color: AppColors.inkMute),
            title: l10n.moreSyncQueue,
            subtitle: outbox.ops.isEmpty
                ? l10n.moreSyncQueueEmpty
                : l10n.pendingSync(outbox.ops.length),
            trailing: outbox.failed > 0
                ? StatusChip(label: l10n.syncFailed, tone: StatusTone.danger, dense: true)
                : null,
            onTap: () => context.go(Routes.syncQueue),
          ),
          AppListRow(
            leading: const Icon(Icons.translate_rounded, color: AppColors.inkMute),
            title: l10n.moreLanguage,
            subtitle: locale.languageCode == 'ml' ? l10n.languageMalayalam : l10n.languageEnglish,
            onTap: () => _pickLanguage(context, ref),
          ),
          AppListRow(
            leading: const Icon(Icons.password_rounded, color: AppColors.inkMute),
            title: l10n.moreChangePassword,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage(voluntary: true)),
            ),
          ),
          AppListRow(
            leading: const Icon(Icons.info_outline_rounded, color: AppColors.inkMute),
            title: l10n.moreAbout,
            onTap: () => _about(context),
          ),
          AppListRow(
            leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
            title: l10n.moreSignOut,
            showDivider: false,
            onTap: () => _confirmSignOut(context, ref, outbox.ops.length),
          ),
        ],
      ),
    );
  }
}
