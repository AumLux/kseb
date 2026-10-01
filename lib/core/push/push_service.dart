import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/session_controller.dart';
import '../../firebase_options.dart';
import '../router/app_router.dart';
import '../supabase/providers.dart';

/// Key under which the current device's FCM token is remembered, so sign-out
/// can unregister it (see AuthRepository.signOut).
const fcmTokenPrefsKey = 'aumlux.fcm_token';

bool get pushSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Firebase is used only for FCM push on Android. Failure here never blocks
/// the app; in-app notifications keep working without it.
Future<bool> initFirebaseForPush() async {
  if (!pushSupported) return false;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    return true;
  } catch (e) {
    debugPrint('Push disabled: Firebase init failed: $e');
    return false;
  }
}

/// Registers this phone for push while someone is signed in, and opens the
/// linked screen when a notification is tapped.
final pushControllerProvider = Provider<void>((ref) {
  if (!pushSupported || Firebase.apps.isEmpty) return;
  final messaging = FirebaseMessaging.instance;
  final subs = <StreamSubscription<dynamic>>[];

  Future<void> register(String token) async {
    try {
      await ref.read(supabaseClientProvider).rpc('register_device', params: {'p_token': token, 'p_platform': 'android'});
      await ref.read(sharedPreferencesProvider).setString(fcmTokenPrefsKey, token);
    } catch (e) {
      debugPrint('Push registration failed: $e');
    }
  }

  void openRoute(RemoteMessage m) {
    final route = m.data['route'];
    if (route is String && route.startsWith('/')) ref.read(routerProvider).push(route);
  }

  ref.listen(currentUserProvider, (previous, user) async {
    if (user == null || previous?.id == user.id) return;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    final token = await messaging.getToken();
    if (token != null) await register(token);
  }, fireImmediately: true);

  subs
    ..add(messaging.onTokenRefresh.listen((t) {
      if (ref.read(currentUserProvider) != null) unawaited(register(t));
    }))
    ..add(FirebaseMessaging.onMessageOpenedApp.listen(openRoute));
  unawaited(messaging.getInitialMessage().then((m) {
    if (m != null) openRoute(m);
  }));
  ref.onDispose(() {
    for (final s in subs) {
      unawaited(s.cancel());
    }
  });
});
