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

    final admin = <_Item>[
      if (user.role.atLeast(AppRole.supervisor))
        _Item(Icons.groups_rounded, AppColors.primaryDeep,
            user.role.atLeast(AppRole.manager) ? l10n.staffTitle : l10n.staffMyTeam, () => context.go(Routes.staff)),
      if (user.role.atLeast(AppRole.manager))
        _Item(Icons.groups_2_rounded, AppColors.info, l10n.teamsTitle, () => context.go(Routes.teams)),
      if (user.role.atLeast(AppRole.manager))
        _Item(Icons.event_rounded, AppColors.ruby, l10n.holidaysTitle, () => context.go(Routes.holidays)),
      if (user.role.isExecutive)
        _Item(Icons.account_tree_rounded, AppColors.success, l10n.orgTitle, () => context.go(Routes.org)),
      if (user.role.atLeast(AppRole.manager))
        _Item(Icons.gavel_rounded, AppColors.brandOrangeInk, l10n.comTitle, () => context.go(Routes.commercial)),
    ];
    final registers = <_Item>[
      _Item(Icons.inventory_2_rounded, AppColors.info, l10n.invTitle, () => context.go(Routes.inventory)),
      _Item(Icons.electrical_services_rounded, AppColors.ruby, l10n.poleTitle, () => context.go(Routes.poles)),
      _Item(Icons.devices_other_rounded, AppColors.inkSecondary, l10n.assetTitle, () => context.go(Routes.assets)),
    ];
    final app = <_Item>[
      if (FeatureFlags.enableBonusModule)
        _Item(Icons.card_giftcard_rounded, AppColors.brandOrangeInk, l10n.bonusTitle, () => context.go(Routes.bonus)),
      _Item(
        Icons.sync_rounded,
        AppColors.info,
        l10n.moreSyncQueue,
        () => context.go(Routes.syncQueue),
        subtitle: outbox.ops.isEmpty ? l10n.moreSyncQueueEmpty : l10n.pendingSync(outbox.ops.length),
        trailing: outbox.failed > 0 ? StatusChip(label: l10n.syncFailed, tone: StatusTone.danger, dense: true) : null,
      ),
      _Item(Icons.translate_rounded, AppColors.primaryDeep, l10n.moreLanguage, () => _pickLanguage(context, ref),
          subtitle: locale.languageCode == 'ml' ? l10n.languageMalayalam : l10n.languageEnglish),
      _Item(Icons.password_rounded, AppColors.warning, l10n.moreChangePassword, () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const ChangePasswordPage(voluntary: true)),
          )),
      _Item(Icons.info_outline_rounded, AppColors.inkSecondary, l10n.moreAbout, () => _about(context)),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: [
          FadeSlideIn(
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(children: [
                Avatar(user.fullName, size: 56),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.fullName, style: AppTypography.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [
                      StatusChip(label: roleLabel(l10n, user.role), tone: StatusTone.brand, dense: true),
                      StatusChip(label: user.employeeCode, dense: true),
                    ]),
                    if (user.email != null || user.phone != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(user.email ?? user.phone!, style: AppTypography.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ]),
                ),
              ]),
            ),
          ),
          if (admin.isNotEmpty) _Group(title: l10n.adminSection, items: admin, index: 1),
          _Group(title: l10n.regSection, items: registers, index: 2),
          _Group(title: l10n.moreApp, items: app, index: 3),
          const SizedBox(height: AppSpacing.lg),
          FadeSlideIn(
            index: 4,
            child: AppCard(
              padding: EdgeInsets.zero,
              child: AppListRow(
                leading: const IconTile(Icons.logout_rounded, color: AppColors.danger, size: 36),
                title: l10n.moreSignOut,
                showDivider: false,
                onTap: () => _confirmSignOut(context, ref, outbox.ops.length),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item {
  const _Item(this.icon, this.tint, this.title, this.onTap, {this.subtitle, this.trailing});

  final IconData icon;
  final Color tint;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;
  final Widget? trailing;
}

/// A titled card of menu rows (Notion/Groww settings style).
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.items, required this.index});

  final String title;
  final List<_Item> items;
  final int index;

  @override
  Widget build(BuildContext context) => FadeSlideIn(
        index: index,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xl, AppSpacing.xs, AppSpacing.sm),
            child: Semantics(
              header: true,
              child: Text(title.toUpperCase(), style: AppTypography.overline),
            ),
          ),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final (i, it) in items.indexed)
                AppListRow(
                  leading: IconTile(it.icon, color: it.tint, size: 36),
                  title: it.title,
                  subtitle: it.subtitle,
                  trailing: it.trailing,
                  showDivider: i < items.length - 1,
                  dividerIndent: AppSpacing.lg + 36 + AppSpacing.md,
                  onTap: it.onTap,
                ),
            ]),
          ),
        ]),
      );
}
