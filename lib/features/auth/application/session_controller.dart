import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthChangeEvent, AuthState;

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/errors/app_failure.dart';
import '../data/auth_repository.dart';
import '../domain/app_user.dart';

sealed class SessionState {
  const SessionState();
}

class SessionLoading extends SessionState {
  const SessionLoading();
}

/// [reason]: why the user is signed out, shown on the login screen
/// (`not_active`, `no_profile`, `idle`, `network`) or null.
class SessionSignedOut extends SessionState {
  const SessionSignedOut({this.reason});
  final String? reason;
}

/// [offline]: profile came from the local cache because the server was
/// unreachable; it is refreshed automatically when connectivity returns.
class SessionSignedIn extends SessionState {
  const SessionSignedIn(this.user, {this.offline = false});
  final AppUser user;
  final bool offline;
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(SessionController.new);

/// Convenience: the signed-in user, or null.
final currentUserProvider = Provider<AppUser?>((ref) {
  final s = ref.watch(sessionProvider);
  return s is SessionSignedIn ? s.user : null;
});

class SessionController extends Notifier<SessionState> {
  late AuthRepository _repo;
  String? _pendingReason;
  String? _loadingFor;
  Future<void>? _inflight;

  @override
  SessionState build() {
    _repo = ref.watch(authRepositoryProvider);
    final sub = _repo.authStateChanges.listen(_onAuthChange);
    ref.onDispose(sub.cancel);

    // Refresh a cached (offline) profile as soon as we are back online.
    ref.listen<AsyncValue<bool>>(onlineProvider, (_, next) {
      final s = state;
      if (next.value == true && s is SessionSignedIn && s.offline) {
        unawaited(_load(s.user.id));
      }
    });

    final session = _repo.currentSession;
    if (session == null) return const SessionSignedOut();
    Future.microtask(() => _load(session.user.id));
    return const SessionLoading();
  }

  void _onAuthChange(AuthState auth) {
    switch (auth.event) {
      case AuthChangeEvent.signedIn:
        final uid = auth.session?.user.id;
        final s = state;
        if (uid != null && !(s is SessionSignedIn && s.user.id == uid)) {
          unawaited(_load(uid));
        }
      case AuthChangeEvent.signedOut:
        // _signOutWith() already set the state (with its reason); this event
        // only matters for sign-outs that happen elsewhere (token revoked).
        if (state is! SessionSignedOut) state = SessionSignedOut(reason: _pendingReason);
      default:
        break;
    }
  }

  Future<void> _load(String uid) {
    if (_loadingFor == uid && _inflight != null) return _inflight!;
    _loadingFor = uid;
    return _inflight = _doLoad(uid).whenComplete(() {
      _loadingFor = null;
      _inflight = null;
    });
  }

  Future<void> _doLoad(String uid) async {
    try {
      final user = await _repo.fetchProfile();
      if (!ref.mounted) return;
      if (user == null) {
        await _signOutWith('no_profile');
      } else if (!user.active) {
        await _signOutWith('not_active');
      } else {
        state = SessionSignedIn(user);
      }
    } on AppFailure catch (f) {
      if (!ref.mounted) return;
      if (f.retryable) {
        final cached = _repo.cachedProfile(uid);
        state = cached != null
            ? SessionSignedIn(cached, offline: true)
            : const SessionSignedOut(reason: 'network');
      } else {
        await _signOutWith(f.code == 'not_active' ? 'not_active' : null);
      }
    }
  }

  Future<void> _signOutWith(String? reason) async {
    _pendingReason = reason;
    state = SessionSignedOut(reason: reason);
    await _repo.signOut();
    _pendingReason = null;
  }

  /// Throws [AppFailure] for invalid credentials or network problems.
  Future<void> signIn(String identifier, String password) async {
    await _repo.signIn(identifier: identifier, password: password);
    final uid = _repo.currentSession?.user.id;
    if (uid != null) await _load(uid);
  }

  Future<void> changePassword(String newPassword) async {
    await _repo.changePassword(newPassword);
    final s = state;
    if (s is SessionSignedIn) {
      state = SessionSignedIn(s.user.copyWith(mustChangePassword: false), offline: s.offline);
    }
  }

  Future<void> refreshProfile() async {
    final s = state;
    if (s is SessionSignedIn) await _load(s.user.id);
  }

  Future<void> signOut({String? reason}) => _signOutWith(reason);
}
