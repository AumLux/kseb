import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/design.dart';
import '../../core/format/formatters.dart';
import '../../core/l10n/l10n.dart';
import '../../core/outbox/outbox.dart';
import '../../core/router/app_router.dart';
import '../auth/application/session_controller.dart';
import '../auth/domain/app_user.dart';
import '../notifications/notifications.dart';
import 'dashboard_repository.dart';

String roleLabel(AppLocalizations l10n, AppRole role) => switch (role) {
      AppRole.staff => l10n.roleStaff,
      AppRole.supervisor => l10n.roleSupervisor,
      AppRole.manager => l10n.roleManager,
      AppRole.coo => l10n.roleCoo,
      AppRole.director => l10n.roleDirector,
    };

/// Home: a gradient-mesh hero (greeting + today's attendance), role-aware
/// shortcuts and the KPI overview.
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
    final wide = context.isWide;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: RefreshIndicator(
          edgeOffset: MediaQuery.paddingOf(context).top,
          onRefresh: () async {
            ref
              ..invalidate(dashboardProvider)
              ..invalidate(notificationsProvider);
            await ref.read(sessionProvider.notifier).refreshProfile();
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: GradientMesh(
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            if (!wide) const BrandMark(size: 34),
                            const Spacer(),
                            SyncBadge(pending: pending, onTap: () => openFromHome(context, Routes.syncQueue)),
                            const NotificationBell(),
                          ]),
                          const SizedBox(height: AppSpacing.xl),
                          FadeSlideIn(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_greeting(l10n), style: AppTypography.label.copyWith(color: AppColors.inkSecondary)),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(user.firstName, style: AppTypography.display, maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
                                _GlassChip(roleLabel(l10n, user.role)),
                                _GlassChip(user.employeeCode, tabular: true),
                              ]),
                            ]),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.sm),
                            child: FadeSlideIn(
                              index: 1,
                              child: switch (dashboard) {
                                AsyncData(:final value) => _TodayCard(dashboard: value),
                                AsyncError() => const SizedBox.shrink(),
                                _ => const _TodaySkeleton(),
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _Shortcuts(user: user)),
              ...switch (dashboard) {
                AsyncData(:final value) => [_KpiGrid(dashboard: value)],
                AsyncError(:final error) => [
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 320,
                        child: ErrorState(
                          title: l10n.homeLoadFailed,
                          message: failureMessage(l10n, error),
                          retryLabel: l10n.commonRetry,
                          onRetry: () => ref.invalidate(dashboardProvider),
                        ),
                      ),
                    ),
                  ],
                _ => [const SliverToBoxAdapter(child: _KpiSkeleton())],
              },
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens a destination from Home so that Back returns to Home.
///
/// Tab roots (Attendance, Work, More) switch tabs; Back from another tab
/// then lands on Home (AppShell). Everything else is *pushed* above Home:
/// `go('/more/inventory/new')` would instead rebuild the whole More stack,
/// so Back walked up to Inventory and then the More menu.
@visibleForTesting
void openFromHome(BuildContext context, String route) {
  const tabRoots = {Routes.home, Routes.attendance, Routes.work, Routes.more};
  if (tabRoots.contains(route)) {
    context.go(route);
  } else {
    context.push(route);
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip(this.label, {this.tabular = false});

  final String label;
  final bool tabular;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
        decoration: BoxDecoration(
          color: const Color(0xB3FFFFFF),
          borderRadius: AppRadius.pillAll,
          border: Border.all(color: const Color(0x14000000)),
        ),
        child: Text(
          label,
          style: (tabular ? AppTypography.bodyTabular : AppTypography.label).copyWith(fontSize: 13, color: AppColors.inkSecondary),
        ),
      );
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.dashboard});

  final Dashboard dashboard;

  String _duration(Duration d) {
    final h = d.inHours, m = d.inMinutes.remainder(60);
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = dashboard.myAttendance;
    final checkIn = DateTime.tryParse(today?['check_in_at'] as String? ?? '');
    final checkOut = DateTime.tryParse(today?['check_out_at'] as String? ?? '');
    final onDuty = checkIn != null && checkOut == null;

    final (IconData icon, Color tint, String status, String? detail) = checkOut != null
        ? (Icons.task_alt_rounded, AppColors.success, l10n.homeCheckedOutAt(Fmt.time(checkOut)),
            l10n.homeWorked(_duration(checkOut.difference(checkIn ?? checkOut))))
        : onDuty
            ? (Icons.bolt_rounded, AppColors.success, l10n.homeOnDuty(_duration(DateTime.now().difference(checkIn))),
                l10n.homeCheckedInAt(Fmt.time(checkIn)))
            : (Icons.wb_twilight_rounded, AppColors.brandOrangeInk, l10n.homeNotCheckedIn, null);

    return AppCard(
      elevated: true,
      borderColor: null,
      onTap: () => context.go(Routes.attendance),
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
      child: Row(children: [
        IconTile(icon, color: tint, size: 48),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l10n.homeTodayTitle.toUpperCase(), style: AppTypography.overline),
            const SizedBox(height: AppSpacing.xs),
            Text(status, style: AppTypography.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(detail, style: AppTypography.caption),
            ],
          ]),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (checkIn == null)
          FilledButton(
            onPressed: () => context.go(Routes.attendance),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg)),
            child: Text(l10n.attCheckIn),
          )
        else
          const Icon(Icons.chevron_right_rounded, color: AppColors.inkDisabled),
      ]),
    );
  }
}

class _TodaySkeleton extends StatelessWidget {
  const _TodaySkeleton();

  @override
  Widget build(BuildContext context) => AppCard(
        elevated: true,
        borderColor: null,
        child: Skeleton(
          child: Row(children: [
            const SkeletonBox(width: 48, height: 48, radius: 14),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                SkeletonBox(width: 60, height: 10),
                SizedBox(height: AppSpacing.sm),
                SkeletonBox(width: 160, height: 16),
              ]),
            ),
          ]),
        ),
      );
}

class _Shortcuts extends StatelessWidget {
  const _Shortcuts({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = [
      (Icons.fingerprint_rounded, l10n.attCheckIn, AppColors.success, Routes.attendance),
      (Icons.handyman_rounded, l10n.wsNew, AppColors.brandOrangeInk, '${Routes.work}/new'),
      (Icons.inventory_2_rounded, l10n.invRequestForJob, AppColors.info, '${Routes.inventory}/new'),
      (Icons.beach_access_rounded, l10n.leaveTitle, AppColors.primaryDeep, Routes.leave),
      if (user.role.atLeast(AppRole.supervisor))
        (Icons.fact_check_rounded, l10n.approvalsTitle, AppColors.warning, Routes.approvals),
      (Icons.electrical_services_rounded, l10n.poleTitle, AppColors.ruby, Routes.poles),
      if (user.role.atLeast(AppRole.manager)) (Icons.groups_rounded, l10n.staffTitle, AppColors.primaryDeep, Routes.staff),
      if (user.role.atLeast(AppRole.coo)) (Icons.account_balance_rounded, l10n.comTitle, AppColors.success, Routes.commercial),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, AppSpacing.sm, AppSpacing.sm),
          child: Text(l10n.homeShortcuts, style: AppTypography.subtitle),
        ),
        LayoutBuilder(builder: (context, c) {
          final perRow = c.maxWidth >= Breakpoints.tablet ? 8 : 4;
          final w = c.maxWidth / perRow;
          return Wrap(children: [
            for (final (i, (icon, label, tint, route)) in actions.indexed)
              SizedBox(
                width: w,
                child: FadeSlideIn(
                  index: i,
                  child: QuickAction(icon: icon, label: label, tint: tint, onTap: () => openFromHome(context, route)),
                ),
              ),
          ]);
        }),
      ]),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.dashboard});

  final Dashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = dashboard;
    final kpis = <({String label, String value, IconData icon, Color tint, String? route})>[
      (label: l10n.kpiPresentThisMonth, value: Fmt.qty(d.number('my_month_present')), icon: Icons.event_available_rounded, tint: AppColors.success, route: Routes.attendance),
      (label: l10n.kpiPendingApprovals, value: Fmt.qty(d.number('pending_approvals')), icon: Icons.fact_check_rounded, tint: AppColors.warning, route: Routes.approvals),
      if (d.has('team_present_today'))
        (
          label: l10n.kpiTeamPresentToday,
          value: '${Fmt.qty(d.number('team_present_today'))}/${Fmt.qty(d.number('team_size'))}',
          icon: Icons.groups_rounded,
          tint: AppColors.primaryDeep,
          route: Routes.attendance,
        ),
      if (d.has('worksheets_in_progress'))
        (label: l10n.kpiWorkInProgress, value: Fmt.qty(d.number('worksheets_in_progress')), icon: Icons.engineering_rounded, tint: AppColors.brandOrangeInk, route: Routes.work),
      if (d.has('open_incidents'))
        (label: l10n.kpiOpenIncidents, value: Fmt.qty(d.number('open_incidents')), icon: Icons.health_and_safety_rounded, tint: AppColors.danger, route: null),
      if (d.has('low_stock_items'))
        (label: l10n.kpiLowStock, value: Fmt.qty(d.number('low_stock_items')), icon: Icons.inventory_2_rounded, tint: AppColors.warning, route: Routes.inventory),
      if (d.has('active_work_orders'))
        (label: l10n.kpiActiveWorkOrders, value: Fmt.qty(d.number('active_work_orders')), icon: Icons.description_rounded, tint: AppColors.primaryDeep, route: Routes.commercial),
      if (d.has('open_tenders'))
        (label: l10n.kpiOpenTenders, value: Fmt.qty(d.number('open_tenders')), icon: Icons.gavel_rounded, tint: AppColors.info, route: Routes.commercial),
      if (d.has('deposits_held'))
        (label: l10n.kpiDepositsHeld, value: Fmt.moneyCompact(d.number('deposits_held')), icon: Icons.account_balance_rounded, tint: AppColors.success, route: Routes.commercial),
      if (d.has('deposits_expiring_30d'))
        (label: l10n.kpiDepositsExpiring, value: Fmt.qty(d.number('deposits_expiring_30d')), icon: Icons.timer_rounded, tint: AppColors.warning, route: Routes.commercial),
      if (d.has('receivables_outstanding'))
        (label: l10n.kpiReceivables, value: Fmt.moneyCompact(d.number('receivables_outstanding')), icon: Icons.request_quote_rounded, tint: AppColors.info, route: Routes.commercial),
      if (d.has('receivables_over_90d'))
        (label: l10n.kpiReceivables90, value: Fmt.moneyCompact(d.number('receivables_over_90d')), icon: Icons.warning_amber_rounded, tint: AppColors.danger, route: Routes.commercial),
    ];

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverMainAxisGroup(slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xl, bottom: AppSpacing.md),
            child: Text(context.l10n.homeOverview, style: AppTypography.subtitle),
          ),
        ),
        SliverLayoutBuilder(builder: (context, c) {
          final columns = c.crossAxisExtent >= 900 ? 4 : c.crossAxisExtent >= Breakpoints.tablet ? 3 : 2;
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              mainAxisExtent: 148 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.4),
            ),
            itemCount: kpis.length,
            itemBuilder: (context, i) {
              final k = kpis[i];
              return FadeSlideIn(
                index: i,
                child: KpiCard(
                  label: k.label,
                  value: k.value,
                  icon: k.icon,
                  tint: k.tint,
                  onTap: k.route == null ? null : () => openFromHome(context, k.route!),
                ),
              );
            },
          );
        }),
      ]),
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, 0),
        child: Skeleton(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SkeletonBox(width: 90, height: 16),
            const SizedBox(height: AppSpacing.md),
            for (var r = 0; r < 2; r++) ...[
              Row(children: const [
                Expanded(child: SkeletonBox(height: 136, radius: AppRadius.lg)),
                SizedBox(width: AppSpacing.md),
                Expanded(child: SkeletonBox(height: 136, radius: AppRadius.lg)),
              ]),
              const SizedBox(height: AppSpacing.md),
            ],
          ]),
        ),
      );
}
