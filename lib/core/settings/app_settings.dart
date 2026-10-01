import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../features/auth/application/session_controller.dart';
import '../supabase/providers.dart';

/// Server-controlled settings (`app_settings`), read after sign-in.
class AppSettings {
  const AppSettings({this.minAppBuild = 0, this.idleTimeoutMinutes = 15});

  final int minAppBuild;
  final int idleTimeoutMinutes;

  factory AppSettings.fromRows(List<Map<String, dynamic>> rows) {
    int intOf(String key, int fallback) {
      final v = rows.where((r) => r['key'] == key).firstOrNull?['value'];
      return v is num ? v.toInt() : int.tryParse('$v') ?? fallback;
    }

    return AppSettings(
      minAppBuild: intOf('min_app_build', 0),
      idleTimeoutMinutes: intOf('idle_timeout_minutes', 15).clamp(5, 240),
    );
  }
}

final appSettingsProvider = FutureProvider<AppSettings>((ref) async {
  if (ref.watch(currentUserProvider) == null) return const AppSettings();
  try {
    final rows = await ref
        .watch(supabaseClientProvider)
        .from('app_settings')
        .select('key, value')
        .inFilter('key', ['min_app_build', 'idle_timeout_minutes']);
    return AppSettings.fromRows(List<Map<String, dynamic>>.from(rows));
  } catch (_) {
    return const AppSettings(); // offline: never block the app on settings
  }
});

final installedBuildProvider = FutureProvider<int>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return int.tryParse(info.buildNumber) ?? 0;
});

/// True when this Android build is older than the minimum the server
/// accepts (the web build is always current).
final updateRequiredProvider = Provider<bool>((ref) {
  if (kIsWeb) return false;
  final min = ref.watch(appSettingsProvider).value?.minAppBuild ?? 0;
  final installed = ref.watch(installedBuildProvider).value;
  return installed != null && min > 0 && installed < min;
});

/// Where crews download the latest Android build.
const latestApkUrl = 'https://aumlux.simplewebsite.in/downloads/aumlux.apk';
