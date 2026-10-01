import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/supabase/providers.dart';
import '../auth/application/session_controller.dart';

/// Role-scoped KPIs from `dashboard_kpis()`. The last good result is cached
/// per user so the home screen still renders offline.
class Dashboard {
  const Dashboard(this.data, {this.fromCache = false});

  final Map<String, dynamic> data;
  final bool fromCache;

  num number(String key) => (data[key] as num?) ?? 0;
  bool has(String key) => data.containsKey(key);

  Map<String, dynamic>? get myAttendance =>
      data['my_attendance'] == null ? null : Map<String, dynamic>.from(data['my_attendance'] as Map);
}

final dashboardProvider = FutureProvider.autoDispose<Dashboard>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw const AppFailure('session_expired', 'Sign in again.');
  final client = ref.watch(supabaseClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  final cacheKey = 'aumlux.dashboard.${user.id}';
  try {
    final data = Map<String, dynamic>.from(await client.rpc('dashboard_kpis') as Map);
    await prefs.setString(cacheKey, jsonEncode(data));
    return Dashboard(data);
  } catch (e) {
    final failure = AppFailure.from(e);
    final cached = prefs.getString(cacheKey);
    if (failure.retryable && cached != null) {
      return Dashboard(Map<String, dynamic>.from(jsonDecode(cached) as Map), fromCache: true);
    }
    throw failure;
  }
});
