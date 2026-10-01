import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/supabase/providers.dart';
import '../domain/app_user.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(supabaseClientProvider), ref.watch(sharedPreferencesProvider)),
);

/// The only place that talks to Supabase Auth.
class AuthRepository {
  AuthRepository(this._client, this._prefs);

  final SupabaseClient _client;
  final SharedPreferences _prefs;

  static const _profileCacheKey = 'aumlux.profile.v1';

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Session? get currentSession => _client.auth.currentSession;

  Future<void> signIn({required String identifier, required String password}) async {
    try {
      await _client.auth.signInWithPassword(
        email: loginEmailFor(identifier),
        password: password,
      );
    } catch (e) {
      throw AppFailure.from(e);
    }
    // One active session per user: sign out other devices (best effort).
    try {
      await _client.auth.signOut(scope: SignOutScope.others);
    } catch (_) {}
  }

  /// Loads the profile; caches it so the app works offline after a restart.
  /// Returns null when the account has no profile.
  Future<AppUser?> fetchProfile() async {
    try {
      final data = await _client.rpc('me');
      if (data == null) return null;
      final user = AppUser.fromJson(Map<String, dynamic>.from(data as Map));
      await _prefs.setString(_profileCacheKey, jsonEncode(user.toJson()));
      return user;
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  /// Last known profile for [userId] (offline cold start).
  AppUser? cachedProfile(String userId) {
    final raw = _prefs.getString(_profileCacheKey);
    if (raw == null) return null;
    try {
      final user = AppUser.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      return user.id == userId ? user : null;
    } on Object {
      return null;
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
      await _client.rpc('mark_password_changed');
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<void> signOut() async {
    // Stop push to this phone for the signed-out user (best effort).
    final fcm = _prefs.getString('aumlux.fcm_token');
    if (fcm != null) {
      try {
        await _client.rpc('unregister_device', params: {'p_token': fcm});
      } catch (_) {}
      await _prefs.remove('aumlux.fcm_token');
    }
    await _prefs.remove(_profileCacheKey);
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Local sign-out always clears the session even if the network fails.
    }
  }
}
