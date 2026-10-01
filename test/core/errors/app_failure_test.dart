import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/errors/app_failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('RPC business errors keep their server code and message', () {
    final f = AppFailure.from(const PostgrestException(
      message: 'You have already checked in today.',
      code: 'P0001',
      hint: 'already_checked_in',
    ));
    expect(f.code, 'already_checked_in');
    expect(f.message, 'You have already checked in today.');
    expect(f.isPermanent, isTrue);
  });

  test('privilege errors are permanent and generic', () {
    final f = AppFailure.from(const PostgrestException(message: 'permission denied', code: '42501'));
    expect(f.code, 'forbidden');
    expect(f.isPermanent, isTrue);
  });

  test('unknown server errors are retryable', () {
    expect(AppFailure.from(const PostgrestException(message: 'x', code: '57014')).retryable, isTrue);
  });

  test('admin-users function errors carry their code', () {
    final f = AppFailure.from(FunctionException(
      status: 403,
      details: {'code': 'forbidden_scope', 'message': 'You can only manage people in your own sections.'},
    ));
    expect(f.code, 'forbidden_scope');
    expect(f.isPermanent, isTrue);
  });

  test('bad credentials map to a friendly code', () {
    final f = AppFailure.from(const AuthException('Invalid login credentials', code: 'invalid_credentials'));
    expect(f.code, 'invalid_credentials');
  });

  test('network problems are retryable', () {
    expect(AppFailure.from(TimeoutException('x')).retryable, isTrue);
    expect(AppFailure.from(Exception('ClientException: Failed host lookup')).code, 'network');
  });
}
