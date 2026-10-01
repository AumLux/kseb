import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sends uncaught errors to `client_errors` (self-hosted crash reporting).
/// Release builds only, signed-in users only, de-duplicated and capped per
/// session so a crash loop can't flood the free-tier database.
class ErrorReporter {
  ErrorReporter._();

  static const _maxPerSession = 20;
  static final _seen = <int>{};
  static String _version = '?';

  static Future<void> install() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version}+${info.buildNumber}';
    } catch (_) {}

    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      report(details.exception, details.stack, context: details.context?.toDescription());
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stack, context: 'platform');
      return true;
    };
  }

  static void report(Object error, StackTrace? stack, {String? context}) {
    if (kDebugMode) {
      debugPrint('Unhandled: $error\n$stack');
      return;
    }
    final message = error.toString();
    final fingerprint = Object.hash(message, stack?.toString().split('\n').take(3).join());
    if (_seen.length >= _maxPerSession || !_seen.add(fingerprint)) return;
    unawaited(() async {
      try {
        final client = Supabase.instance.client;
        if (client.auth.currentUser == null) return;
        await client.from('client_errors').insert({
          'app_version': _version,
          'platform': kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.android ? 'android' : 'other'),
          'message': message.length > 2000 ? message.substring(0, 2000) : message,
          'stack': stack == null ? null : (stack.toString().length > 8000 ? stack.toString().substring(0, 8000) : stack.toString()),
          'context': context == null ? null : (context.length > 500 ? context.substring(0, 500) : context),
        });
      } catch (_) {
        // Reporting must never throw.
      }
    }());
  }
}
