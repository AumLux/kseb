import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/session_controller.dart';
import '../../features/auth/presentation/change_password_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/home/home_page.dart';
import '../../features/more/more_page.dart';
import '../../features/more/sync_queue_page.dart';
import '../../features/shell/app_shell.dart';
import '../../features/shell/coming_soon_page.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const changePassword = '/change-password';
  static const home = '/home';
  static const attendance = '/attendance';
  static const work = '/work';
  static const more = '/more';
  static const syncQueue = '/more/sync';
}

const _publicRoutes = {Routes.splash, Routes.login};

/// Pure redirect policy (unit-tested): where should [location] go given the
/// session? Returns null to stay.
@visibleForTesting
String? resolveRedirect(SessionState session, String location) {
  return switch (session) {
    SessionLoading() => location == Routes.splash ? null : Routes.splash,
    SessionSignedOut() => location == Routes.login ? null : Routes.login,
    SessionSignedIn(:final user) when user.mustChangePassword =>
      location == Routes.changePassword ? null : Routes.changePassword,
    SessionSignedIn() =>
      (_publicRoutes.contains(location) || location == Routes.changePassword) ? Routes.home : null,
  };
}

/// Bridges Riverpod session changes to go_router's refresh.
class _SessionListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable();
  ref.listen(sessionProvider, (_, __) => refresh.notify());
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(ref.read(sessionProvider), state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashPage()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginPage()),
      GoRoute(path: Routes.changePassword, builder: (_, __) => const ChangePasswordPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.home, builder: (_, __) => const HomePage()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.attendance,
              builder: (_, __) => const ComingSoonPage(titleKey: ComingSoonTitle.attendance),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.work,
              builder: (_, __) => const ComingSoonPage(titleKey: ComingSoonTitle.work),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: Routes.more,
              builder: (_, __) => const MorePage(),
              routes: [
                GoRoute(path: 'sync', builder: (_, __) => const SyncQueuePage()),
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
