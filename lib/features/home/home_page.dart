import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/l10n.dart';
import '../../core/outbox/outbox.dart';
import '../../core/router/app_router.dart';
import '../auth/application/session_controller.dart';
import '../auth/domain/app_user.dart';
import 'dashboard_repository.dart';

String roleLabel(AppLocalizations l10n, AppRole role) => switch (role) {
      AppRole.staff => l10n.roleStaff,
      AppRole.supervisor => l10n.roleSupervisor,
      AppRole.manager => l10n.roleManager,
      AppRole.coo => l10n.roleCoo,
      AppRole.director => l10n.roleDirector,
    };

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.homeGreetingMorning;
    if (hour < 17) return l10n.homeGreetingAfternoon;
    return l10n.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final dashboard = ref.watch(dashboardProvider);
    final pending = ref.watch(outboxProvider.select((s) => s.pending));
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // The navigation rail already shows the mark on wider screens.
            if (MediaQuery.sizeOf(context).width < 600) ...[
              const BrandMark(size: 32),
              const SizedBox(width: AppSpacing.md),
            ],
            Text(l10n.appName),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.lg),
            child: SyncBadge(
              pending: pending,
              onTap: () => context.go(Routes.syncQueue),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          await ref.read(sessionProvider.notifier).refreshProfile();
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('${_greeting(l10n)}, ${user.firstName}', style: AppTypography.headline),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                StatusChip(label: roleLabel(l10n, user.role), tone: StatusTone.brand),
                StatusChip(label: user.employeeCode),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            switch (dashboard) {
              AsyncData(:final value) => _DashboardBody(user: user, dashboard: value),
              AsyncError(:final error) => SizedBox(
                  height: 320,
                  child: ErrorState(
                    title: l10n.homeLoadFailed,
                    message: failureMessage(l10n, error),
                    retryLabel: l10n.commonRetry,
                    onRetry: () => ref.invalidate(dashboardProvider),
                  ),
                ),
              _ => const SizedBox(height: 320, child: LoadingView()),
            },
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.user, required this.dashboard});

  final AppUser user;
  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = dashboard.myAttendance;
    final checkIn = DateTime.tryParse(today?['check_in_at'] as String? ?? '');
    final checkOut = DateTime.tryParse(today?['check_out_at'] as String? ?? '');

    final kpis = <({String label, String value, IconData icon, String? route})>[
      (label: l10n.kpiPresentThisMonth, value: Fmt.qty(dashboard.number('my_month_present')), icon: Icons.event_available_rounded, route: Routes.attendance),
      (label: l10n.kpiPendingApprovals, value: Fmt.qty(dashboard.number('pending_approvals')), icon: Icons.fact_check_rounded, route: Routes.approvals),
      if (dashboard.has('team_present_today'))
        (
          label: l10n.kpiTeamPresentToday,
          value: '${Fmt.qty(dashboard.number('team_present_today'))} / ${Fmt.qty(dashboard.number('team_size'))}',
          icon: Icons.groups_rounded,
          route: Routes.attendance,
        ),
      if (dashboard.has('worksheets_in_progress'))
        (label: l10n.kpiWorkInProgress, value: Fmt.qty(dashboard.number('worksheets_in_progress')), icon: Icons.engineering_rounded, route: null),
      if (dashboard.has('open_incidents'))
        (label: l10n.kpiOpenIncidents, value: Fmt.qty(dashboard.number('open_incidents')), icon: Icons.health_and_safety_rounded, route: null),
      if (dashboard.has('low_stock_items'))
        (label: l10n.kpiLowStock, value: Fmt.qty(dashboard.number('low_stock_items')), icon: Icons.inventory_2_rounded, route: null),
      if (dashboard.has('active_work_orders'))
        (label: l10n.kpiActiveWorkOrders, value: Fmt.qty(dashboard.number('active_work_orders')), icon: Icons.description_rounded, route: null),
      if (dashboard.has('open_tenders'))
        (label: l10n.kpiOpenTenders, value: Fmt.qty(dashboard.number('open_tenders')), icon: Icons.gavel_rounded, route: null),
      if (dashboard.has('deposits_held'))
        (label: l10n.kpiDepositsHeld, value: Fmt.moneyCompact(dashboard.number('deposits_held')), icon: Icons.account_balance_rounded, route: null),
      if (dashboard.has('deposits_expiring_30d'))
        (label: l10n.kpiDepositsExpiring, value: Fmt.qty(dashboard.number('deposits_expiring_30d')), icon: Icons.timer_rounded, route: null),
      if (dashboard.has('receivables_outstanding'))
        (label: l10n.kpiReceivables, value: Fmt.moneyCompact(dashboard.number('receivables_outstanding')), icon: Icons.request_quote_rounded, route: null),
      if (dashboard.has('receivables_over_90d'))
        (label: l10n.kpiReceivables90, value: Fmt.moneyCompact(dashboard.number('receivables_over_90d')), icon: Icons.warning_amber_rounded, route: null),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          onTap: () => context.go(Routes.attendance),
          child: Row(
            children: [
              Icon(
                checkIn == null ? Icons.login_rounded : Icons.check_circle_rounded,
                color: checkIn == null ? AppColors.warning : AppColors.success,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.homeTodayTitle, style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      checkOut != null
                          ? l10n.homeCheckedOutAt(Fmt.time(checkOut))
                          : checkIn != null
                              ? l10n.homeCheckedInAt(Fmt.time(checkIn))
                              : l10n.homeNotCheckedIn,
                      style: AppTypography.bodyStrong,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkMute),
            ],
          ),
        ),
        SectionHeader(l10n.homeOverview),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth >= 900 ? 4 : 2;
          const gap = AppSpacing.md;
          final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final k in kpis)
                SizedBox(
                  width: width,
                  child: KpiCard(
                    label: k.label,
                    value: k.value,
                    icon: k.icon,
                    onTap: k.route == null ? null : () => context.go(k.route!),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }
}
