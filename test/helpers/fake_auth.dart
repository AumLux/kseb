import 'dart:async';

import 'package:kseb/core/errors/app_failure.dart';
import 'package:kseb/features/auth/data/auth_repository.dart';
import 'package:kseb/features/auth/domain/app_user.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Session fakeSession(String uid) => Session(
      accessToken: 'test-token',
      tokenType: 'bearer',
      user: User(
        id: uid,
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: '2026-01-01T00:00:00Z',
      ),
    );

AppUser testUser({
  String id = 'u1',
  AppRole role = AppRole.staff,
  bool active = true,
  bool mustChangePassword = false,
}) =>
    AppUser(
      id: id,
      employeeCode: 'AUM0101',
      fullName: 'Ravi Kumar',
      role: role,
      active: active,
      mustChangePassword: mustChangePassword,
    );

/// In-memory [AuthRepository] for controller and widget tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.profile, this.session});

  final _events = StreamController<AuthState>.broadcast();
  AppUser? profile;
  AppUser? cached;
  Session? session;
  Object? signInError;
  Object? profileError;
  int signOutCalls = 0;
  String? lastIdentifier;

  @override
  Stream<AuthState> get authStateChanges => _events.stream;

  @override
  Session? get currentSession => session;

  @override
  Future<void> signIn({required String identifier, required String password}) async {
    lastIdentifier = identifier;
    if (signInError != null) throw AppFailure.from(signInError!);
    session = fakeSession(profile?.id ?? 'u1');
    _events.add(AuthState(AuthChangeEvent.signedIn, session));
  }

  @override
  Future<AppUser?> fetchProfile() async {
    if (profileError != null) throw AppFailure.from(profileError!);
    return profile;
  }

  @override
  AppUser? cachedProfile(String userId) => cached?.id == userId ? cached : null;

  @override
  Future<void> changePassword(String newPassword) async {
    profile = profile?.copyWith(mustChangePassword: false);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    session = null;
    _events.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  Future<void> dispose() => _events.close();
}
