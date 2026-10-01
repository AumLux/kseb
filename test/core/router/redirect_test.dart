import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/router/app_router.dart';
import 'package:kseb/features/auth/application/session_controller.dart';

import '../../helpers/fake_auth.dart';

void main() {
  group('resolveRedirect', () {
    test('while loading, everything waits on the splash, remembering the destination', () {
      expect(resolveRedirect(const SessionLoading(), Routes.home), '/splash?from=%2Fhome');
      expect(resolveRedirect(const SessionLoading(), '/work/42'), '/splash?from=%2Fwork%2F42');
      expect(resolveRedirect(const SessionLoading(), Routes.splash), isNull);
    });

    test('signed-out users can only reach login (destination kept for after sign-in)', () {
      expect(resolveRedirect(const SessionSignedOut(), Routes.syncQueue), '/login?from=%2Fmore%2Fsync');
      expect(resolveRedirect(const SessionSignedOut(), Routes.splash, from: '/work/42'), '/login?from=%2Fwork%2F42');
      expect(resolveRedirect(const SessionSignedOut(), Routes.login), isNull);
    });

    test('after loading, the remembered screen is restored (Android restore, notification tap)', () {
      final s = SessionSignedIn(testUser());
      expect(resolveRedirect(s, Routes.splash, from: '/work/42'), '/work/42');
      expect(resolveRedirect(s, Routes.login, from: '/more/inventory/requests/7'), '/more/inventory/requests/7');
    });

    test('only in-app, non-public destinations are honoured', () {
      final s = SessionSignedIn(testUser());
      expect(resolveRedirect(s, Routes.splash, from: 'https://evil.example'), Routes.home);
      expect(resolveRedirect(s, Routes.splash, from: '//evil.example/x'), Routes.home);
      expect(resolveRedirect(s, Routes.splash, from: Routes.login), Routes.home);
    });

    test('a forced password change blocks every other screen', () {
      final s = SessionSignedIn(testUser(mustChangePassword: true));
      expect(resolveRedirect(s, Routes.home), Routes.changePassword);
      expect(resolveRedirect(s, Routes.more), Routes.changePassword);
      expect(resolveRedirect(s, Routes.changePassword), isNull);
    });

    test('signed-in users leave public routes for home and stay elsewhere', () {
      final s = SessionSignedIn(testUser());
      expect(resolveRedirect(s, Routes.login), Routes.home);
      expect(resolveRedirect(s, Routes.splash), Routes.home);
      expect(resolveRedirect(s, Routes.changePassword), Routes.home);
      expect(resolveRedirect(s, Routes.attendance), isNull);
    });
  });
}
