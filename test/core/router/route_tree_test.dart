import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/router/app_router.dart';
import 'package:kseb/features/auth/data/auth_repository.dart';

import '../../helpers/fake_auth.dart';

/// Every route below a tab root, with its full path.
Iterable<(String, GoRoute)> _descendants(GoRoute route, String prefix) sync* {
  for (final child in route.routes.whereType<GoRoute>()) {
    final path = '$prefix/${child.path}';
    yield (path, child);
    yield* _descendants(child, path);
  }
}

void main() {
  // Hermetic: building the router starts the session controller, which
  // listens to connectivity (a platform channel). Without a binding and a
  // stub, that subscription could error asynchronously around dispose.
  TestWidgetsFlutterBinding.ensureInitialized();

  // Regression: sub-pages of sub-pages (Staff → Add staff / staff details,
  // Commercial → register → record, Assets/Polevar/Inventory → new/detail)
  // opened on the tab's navigator, i.e. *behind* the full-screen parent page,
  // so taps appeared to do nothing. go_router puts a route without
  // parentNavigatorKey on the nearest shell navigator, not its parent's.
  test('every route under a tab root opens full-screen on the root navigator', () {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      onlineProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    final router = container.read(routerProvider);

    final shell = router.configuration.routes.whereType<StatefulShellRoute>().single;
    final wrong = <String>[];
    var checked = 0;
    for (final branch in shell.branches) {
      for (final root in branch.routes.whereType<GoRoute>()) {
        for (final (path, route) in _descendants(root, root.path)) {
          checked++;
          if (route.parentNavigatorKey != rootNavigatorKey) wrong.add(path);
        }
      }
    }
    expect(checked, greaterThan(30), reason: 'walked the whole tree');
    expect(wrong, isEmpty, reason: 'these would open hidden behind their parent page');
  });
}
