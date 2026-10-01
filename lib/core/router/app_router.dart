import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/approvals/approvals_page.dart';
import '../../features/attendance/presentation/attendance_page.dart';
import '../../features/attendance/presentation/holidays_page.dart';
import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/change_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/bonus/bonus_page.dart';
import '../../features/commercial/entity_pages.dart';
import '../../features/home/home_page.dart';
import '../../features/inventory/presentation/catalog_pages.dart';
import '../../features/inventory/presentation/inventory_page.dart';
import '../../features/inventory/presentation/material_request_detail_page.dart';
import '../../features/inventory/presentation/material_request_form_page.dart';
import '../../features/leave/leave.dart';
import '../../features/more/more_page.dart';
import '../../features/more/sync_queue_page.dart';
import '../../features/notifications/notifications.dart';
import '../../features/org/presentation/org_page.dart';
import '../../features/org/presentation/teams_page.dart';
import '../../features/registers/assets_pages.dart';
import '../../features/registers/poles_pages.dart';
import '../../features/staff/presentation/staff_detail_page.dart';
import '../../features/staff/presentation/staff_form_page.dart';
import '../../features/staff/presentation/staff_list_page.dart';
import '../../features/worksheets/presentation/worksheet_detail_page.dart';
import '../../features/worksheets/presentation/worksheet_form_page.dart';
import '../../features/worksheets/presentation/worksheets_page.dart';
import '../../features/shell/app_shell.dart';
import '../design/design.dart';
import '../l10n/l10n.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const changePassword = '/change-password';
  static const home = '/home';
  static const attendance = '/attendance';
  static const work = '/work';
  static const more = '/more';
  static const syncQueue = '/more/sync';
  static const staff = '/more/staff';
  static const teams = '/more/teams';
  static const org = '/more/org';
  static const holidays = '/more/holidays';
  static const approvals = '/home/approvals';
  static const leave = '/attendance/leave';
  static const inventory = '/more/inventory';
  static const poles = '/more/poles';
  static const assets = '/more/assets';
  static const commercial = '/more/commercial';
  static const notifications = '/home/notifications';
  static const bonus = '/more/bonus';
}

const _publicRoutes = {Routes.splash, Routes.login};

/// Pure redirect policy (unit-tested): where should [location] go given the
/// session? Returns null to stay.
///
/// The intended destination survives the splash and login screens as
/// `?from=`: a cold start from a notification, or Android restoring the app
/// after killing it, lands back on that screen instead of Home.
@visibleForTesting
String? resolveRedirect(SessionState session, String location, {String? fullLocation, String? from}) {
  final target = fullLocation ?? location;
  String withFrom(String route, String? next) =>
      next == null ? route : Uri(path: route, queryParameters: {'from': next}).toString();
  final pending = _safeFrom(from);
  return switch (session) {
    SessionLoading() => location == Routes.splash ? null : withFrom(Routes.splash, _safeFrom(target)),
    SessionSignedOut() => location == Routes.login
        ? null
        : withFrom(Routes.login, location == Routes.splash ? pending : _safeFrom(target)),
    SessionSignedIn(:final user) when user.mustChangePassword =>
      location == Routes.changePassword ? null : Routes.changePassword,
    SessionSignedIn() =>
      (_publicRoutes.contains(location) || location == Routes.changePassword) ? (pending ?? Routes.home) : null,
  };
}

/// Only in-app, non-public paths are honoured (no open redirects).
String? _safeFrom(String? from) {
  if (from == null || !from.startsWith('/') || from.startsWith('//')) return null;
  final path = Uri.tryParse(from)?.path;
  if (path == null || _publicRoutes.contains(path) || path == Routes.changePassword) return null;
  return from;
}

/// Bridges Riverpod session changes to go_router's refresh.
class _SessionListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// The app-wide navigator. Sub-screens (details, forms, registers) open on
/// it, full-screen above the tab bar, so they get the whole screen and a
/// pinned primary action; tab roots stay in the shell.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable();
  ref.listen(sessionProvider, (_, __) => refresh.notify());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
          ref.read(sessionProvider),
          state.matchedLocation,
          fullLocation: state.uri.toString(),
          from: state.uri.queryParameters['from'],
        ),
    // With MaterialApp.restorationScopeId, Android brings the user back to
    // the same screen if it had to kill the app (e.g. while the camera was open).
    restorationScopeId: 'router',
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.explore_off_rounded,
        title: context.l10n.commonComingSoonTitle,
        message: context.l10n.commonComingSoonBody,
      ),
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: Routes.changePassword, builder: (_, __) => const ChangePasswordPage()),
      StatefulShellRoute.indexedStack(
        restorationScopeId: 'shell',
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(restorationScopeId: 'branch1', routes: [
            GoRoute(
              path: Routes.home,
              builder: (_, __) => const HomePage(),
              routes: [
                GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'approvals', builder: (_, __) => const ApprovalsPage()),
                GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'notifications', builder: (_, __) => const NotificationsPage()),
              ],
            ),
          ]),
          StatefulShellBranch(restorationScopeId: 'branch2', routes: [
            GoRoute(
              path: Routes.attendance,
              builder: (_, __) => const AttendancePage(),
              routes: [GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'leave', builder: (_, __) => const LeavePage())],
            ),
          ]),
          StatefulShellBranch(restorationScopeId: 'branch3', routes: [
            GoRoute(
              path: Routes.work,
              builder: (_, __) => const WorksheetsPage(),
              routes: [
                GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'new', builder: (_, __) => const WorksheetFormPage()),
                GoRoute(parentNavigatorKey: rootNavigatorKey, 
                  path: ':id',
                  builder: (_, s) => WorksheetDetailPage(id: s.pathParameters['id']!),
                  routes: [
                    GoRoute(path: 'edit', builder: (_, s) => WorksheetFormPage(worksheetId: s.pathParameters['id'])),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(restorationScopeId: 'branch4', routes: [
            GoRoute(
              path: Routes.more,
              builder: (_, __) => const MorePage(),
              routes: [
                GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'sync', builder: (_, __) => const SyncQueuePage()),
                GoRoute(parentNavigatorKey: rootNavigatorKey, 
                  path: 'staff',
                  builder: (_, __) => const StaffListPage(),
                  routes: [
                    GoRoute(path: 'new', builder: (_, __) => const StaffFormPage()),
                    GoRoute(
                      path: ':id',
                      builder: (_, s) => StaffDetailPage(userId: s.pathParameters['id']!),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (_, s) => StaffFormPage(userId: s.pathParameters['id']),
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'teams', builder: (_, __) => const TeamsPage()),
                GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'org', builder: (_, __) => const OrgPage()),
                GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'holidays', builder: (_, __) => const HolidaysPage()),
                GoRoute(parentNavigatorKey: rootNavigatorKey, path: 'bonus', builder: (_, __) => const BonusPage()),
                GoRoute(parentNavigatorKey: rootNavigatorKey, 
                  path: 'commercial',
                  builder: (_, __) => const CommercialHomePage(),
                  routes: [
                    GoRoute(
                      path: ':entity',
                      builder: (_, s) => EntityListPage(entityKey: s.pathParameters['entity']!),
                      routes: [
                        GoRoute(path: 'new', builder: (_, s) => EntityFormPage(entityKey: s.pathParameters['entity']!)),
                        GoRoute(
                          path: ':id',
                          builder: (_, s) => EntityDetailPage(entityKey: s.pathParameters['entity']!, id: s.pathParameters['id']!),
                          routes: [
                            GoRoute(
                              path: 'edit',
                              builder: (_, s) => EntityFormPage(entityKey: s.pathParameters['entity']!, id: s.pathParameters['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                GoRoute(parentNavigatorKey: rootNavigatorKey, 
                  path: 'poles',
                  builder: (_, __) => const PolesPage(),
                  routes: [
                    GoRoute(path: 'new', builder: (_, __) => const PoleFormPage()),
                    GoRoute(
                      path: ':id',
                      builder: (_, s) => PoleDetailPage(id: s.pathParameters['id']!),
                      routes: [GoRoute(path: 'edit', builder: (_, s) => PoleFormPage(poleId: s.pathParameters['id']))],
                    ),
                  ],
                ),
                GoRoute(parentNavigatorKey: rootNavigatorKey, 
                  path: 'assets',
                  builder: (_, __) => const AssetsPage(),
                  routes: [
                    GoRoute(path: 'new', builder: (_, __) => const AssetFormPage()),
                    GoRoute(
                      path: ':id',
                      builder: (_, s) => AssetDetailPage(id: s.pathParameters['id']!),
                      routes: [GoRoute(path: 'edit', builder: (_, s) => AssetFormPage(assetId: s.pathParameters['id']))],
                    ),
                  ],
                ),
                GoRoute(parentNavigatorKey: rootNavigatorKey, 
                  path: 'inventory',
                  builder: (_, __) => const InventoryPage(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (_, s) => MaterialRequestFormPage(worksheetId: s.uri.queryParameters['worksheet']),
                    ),
                    GoRoute(
                      path: 'requests/:id',
                      builder: (_, s) => MaterialRequestDetailPage(id: s.pathParameters['id']!),
                    ),
                    GoRoute(path: 'catalog', builder: (_, __) => const CatalogPage()),
                    GoRoute(path: 'stores', builder: (_, __) => const StoresPage()),
                  ],
                ),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
