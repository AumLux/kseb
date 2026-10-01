import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/router/app_router.dart';
import 'package:kseb/features/auth/application/session_controller.dart';

import '../../helpers/fake_auth.dart';

void main() {
  group('resolveRedirect', () {
    test('while loading, everything waits on the splash', () {
      expect(resolveRedirect(const SessionLoading(), Routes.home), Routes.splash);
      expect(resolveRedirect(const SessionLoading(), Routes.splash), isNull);
    });

    test('signed-out users can only reach login', () {
      expect(resolveRedirect(const SessionSignedOut(), Routes.home), Routes.login);
      expect(resolveRedirect(const SessionSignedOut(), Routes.syncQueue), Routes.login);
      expect(resolveRedirect(const SessionSignedOut(), Routes.login), isNull);
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
