import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/settings/app_settings.dart';

Future<bool> _updateRequired({required int min, required int installed}) async {
  final c = ProviderContainer(overrides: [
    appSettingsProvider.overrideWith((ref) async => AppSettings(minAppBuild: min)),
    installedBuildProvider.overrideWith((ref) async => installed),
  ]);
  addTearDown(c.dispose);
  await c.read(appSettingsProvider.future);
  await c.read(installedBuildProvider.future);
  return c.read(updateRequiredProvider);
}

void main() {
  test('settings parse from jsonb rows and clamp the idle timeout', () {
    final s = AppSettings.fromRows([
      {'key': 'min_app_build', 'value': 1042},
      {'key': 'idle_timeout_minutes', 'value': 1},
    ]);
    expect(s.minAppBuild, 1042);
    expect(s.idleTimeoutMinutes, 5);
    expect(AppSettings.fromRows(const []).idleTimeoutMinutes, 15);
  });

  test('an older build is blocked, the same or newer is not', () async {
    expect(await _updateRequired(min: 1042, installed: 1041), isTrue);
    expect(await _updateRequired(min: 1042, installed: 1042), isFalse);
    expect(await _updateRequired(min: 0, installed: 20), isFalse);
  });
}
