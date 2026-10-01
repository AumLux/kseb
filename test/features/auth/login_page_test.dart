import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/features/auth/data/auth_repository.dart';
import 'package:kseb/features/auth/presentation/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/fake_auth.dart';

void main() {
  late FakeAuthRepository repo;

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        onlineProvider.overrideWith((ref) => Stream.value(true)),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const LoginPage(),
      ),
    ));
    await tester.pumpAndSettle();
  }

  setUp(() => repo = FakeAuthRepository(profile: testUser()));
  tearDown(() => repo.dispose());

  testWidgets('validates empty fields before calling the server', (tester) async {
    await pump(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your employee ID or email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(repo.lastIdentifier, isNull);
  });

  testWidgets('shows a friendly message for wrong credentials', (tester) async {
    repo.signInError = const AuthException('Invalid login credentials', code: 'invalid_credentials');
    await pump(tester);
    await tester.enterText(find.byType(TextFormField).at(0), 'AUM0101');
    await tester.enterText(find.byType(TextFormField).at(1), 'wrongpass1');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong employee ID / email or password.'), findsOneWidget);
  });

  testWidgets('forgot password explains supervisor reset (no dead button)', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();
    expect(find.text('Reset your password'), findsOneWidget);
  });

  testWidgets('renders in Malayalam', (tester) async {
    await pump(tester, locale: const Locale('ml'));
    expect(find.text('എംപ്ലോയീ ഐഡി അല്ലെങ്കിൽ ഇമെയിൽ'), findsOneWidget);
  });
}
