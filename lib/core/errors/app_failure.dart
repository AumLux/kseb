import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// A user-presentable failure with a stable [code].
///
/// Server RPCs raise `private.fail(code, message)` → Postgres error with
/// `hint = code`; the admin-users function returns `{code, message}`. Both
/// map here, so UI code never shows raw exceptions.
class AppFailure implements Exception {
  const AppFailure(this.code, this.message, {this.retryable = false});

  final String code;
  final String message;

  /// True for transient problems (network, timeouts) worth retrying.
  final bool retryable;

  static const network = AppFailure('network',
      'No connection. Check your mobile data or Wi-Fi and try again.',
      retryable: true);

  bool get isPermanent => !retryable;

  factory AppFailure.from(Object error) {
    if (error is AppFailure) return error;
    if (error is PostgrestException) {
      final hint = error.hint;
      if (error.code == 'P0001' && hint != null && hint.isNotEmpty) {
        return AppFailure(hint, error.message);
      }
      return switch (error.code) {
        '42501' => const AppFailure('forbidden', "You don't have permission to do that."),
        '23505' => const AppFailure('duplicate', 'This record already exists.'),
        '23503' => const AppFailure('in_use', 'This item is linked to other records.'),
        '23514' => const AppFailure('invalid', 'Some values are not allowed. Check and try again.'),
        'PGRST301' || 'PGRST303' => const AppFailure('session_expired', 'Your session expired. Sign in again.'),
        _ => AppFailure('server', 'Something went wrong (${error.code ?? 'unknown'}). Try again.',
            retryable: true),
      };
    }
    if (error is FunctionException) {
      final details = error.details;
      if (details is Map && details['code'] is String) {
        return AppFailure(details['code'] as String,
            (details['message'] as String?) ?? 'Request failed.',
            retryable: error.status >= 500);
      }
      return AppFailure('server', 'Request failed (${error.status}). Try again.',
          retryable: error.status >= 500);
    }
    if (error is AuthException) {
      final code = error.code ?? '';
      if (code == 'invalid_credentials' || error.message.contains('Invalid login')) {
        return const AppFailure('invalid_credentials', 'Wrong employee ID / email or password.');
      }
      if (code == 'user_banned') {
        return const AppFailure('not_active', 'Your account is not active. Contact your supervisor.');
      }
      if (code == 'weak_password') {
        return const AppFailure('weak_password',
            'Use at least 8 characters with letters and numbers.');
      }
      if (code == 'same_password') {
        return const AppFailure('same_password', 'Choose a password different from the current one.');
      }
      if (error is AuthRetryableFetchException) return network;
      return AppFailure('auth', error.message);
    }
    if (error is TimeoutException) return network;
    final text = error.toString();
    if (text.contains('SocketException') ||
        text.contains('Failed host lookup') ||
        text.contains('ClientException') ||
        text.contains('XMLHttpRequest')) {
      return network;
    }
    return const AppFailure('unknown', 'Something went wrong. Try again.', retryable: true);
  }

  @override
  String toString() => 'AppFailure($code): $message';
}
