import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/errors/app_failure.dart';
import 'package:kseb/features/auth/application/session_controller.dart';
import 'package:kseb/features/auth/data/auth_repository.dart';
import 'package:kseb/features/auth/domain/app_user.dart';

import '../../helpers/fake_auth.dart';

void main() {
  late FakeAuthRepository repo;

  ProviderContainer build() {
    final c = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      onlineProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(c.dispose);
    c.listen(sessionProvider, (_, __) {}); // the router listens in the app
    return c;
  }

  setUp(() => repo = FakeAuthRepository(profile: testUser()));
  tearDown(() => repo.dispose());

  test('no stored session → signed out', () {
    expect(build().read(sessionProvider), isA<SessionSignedOut>());
  });

  test('a stored session loads the profile on start', () async {
    repo.session = fakeSession('u1');
    final c = build();
    expect(c.read(sessionProvider), isA<SessionLoading>());
    await Future<void>.delayed(Duration.zero);
    final s = c.read(sessionProvider);
    expect(s, isA<SessionSignedIn>());
    expect((s as SessionSignedIn).user.employeeCode, 'AUM0101');
  });

  test('sign-in with an inactive profile signs out with a reason', () async {
    repo.profile = testUser(active: false);
    final c = build();
    await c.read(sessionProvider.notifier).signIn('AUM0101', 'abc12345');
    final s = c.read(sessionProvider);
    expect(s, isA<SessionSignedOut>());
    expect((s as SessionSignedOut).reason, 'not_active');
    expect(repo.signOutCalls, 1);
  });

  test('a login without a profile is rejected', () async {
    repo.profile = null;
    final c = build();
    await c.read(sessionProvider.notifier).signIn('AUM0101', 'abc12345');
    expect((c.read(sessionProvider) as SessionSignedOut).reason, 'no_profile');
  });

  test('offline restart uses the cached profile', () async {
    repo
      ..session = fakeSession('u1')
      ..profileError = AppFailure.network
      ..cached = testUser(role: AppRole.supervisor);
    final c = build();
    await Future<void>.delayed(Duration.zero);
    final s = c.read(sessionProvider) as SessionSignedIn;
    expect(s.offline, isTrue);
    expect(s.user.role, AppRole.supervisor);
  });

  test('offline restart without a cache asks to sign in when online', () async {
    repo
      ..session = fakeSession('u1')
      ..profileError = AppFailure.network;
    final c = build();
    await Future<void>.delayed(Duration.zero);
    expect((c.read(sessionProvider) as SessionSignedOut).reason, 'network');
  });

  test('changing the password clears the forced-change flag', () async {
    repo.profile = testUser(mustChangePassword: true);
    final c = build();
    await c.read(sessionProvider.notifier).signIn('AUM0101', 'Temp1234');
    expect((c.read(sessionProvider) as SessionSignedIn).user.mustChangePassword, isTrue);
    await c.read(sessionProvider.notifier).changePassword('Mine2026x');
    expect((c.read(sessionProvider) as SessionSignedIn).user.mustChangePassword, isFalse);
  });

  test('idle sign-out records the reason for the login screen', () async {
    final c = build();
    await c.read(sessionProvider.notifier).signIn('AUM0101', 'abc12345');
    await c.read(sessionProvider.notifier).signOut(reason: 'idle');
    expect((c.read(sessionProvider) as SessionSignedOut).reason, 'idle');
  });
}
