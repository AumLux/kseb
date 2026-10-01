import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/core/l10n/locale_controller.dart';
import 'package:kseb/core/outbox/outbox.dart';
import 'package:kseb/core/supabase/providers.dart';
import 'package:kseb/features/auth/application/session_controller.dart';
import 'package:kseb/features/auth/data/auth_repository.dart';
import 'package:kseb/features/more/more_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth.dart';

class _NoopExecutor implements OutboxExecutor {
  @override
  Future<void> execute(OutboxOp op) async {}
}

class _EmptyStore implements OutboxStore {
  @override
  Future<List<OutboxOp>> load() async => [];
  @override
  Future<void> save(List<OutboxOp> ops) async {}
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
        theme: AppTheme.light(),
        locale: ref.watch(localeProvider),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const MorePage(),
      );
}

void main() {
  testWidgets('switching language re-renders in Malayalam and persists', (tester) async {
    SharedPreferences.setMockInitialValues({'aumlux.locale': 'en'});
    final prefs = await SharedPreferences.getInstance();
    final repo = FakeAuthRepository(profile: testUser());
    addTearDown(repo.dispose);

    final container = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(repo),
      outboxStoreProvider.overrideWithValue(_EmptyStore()),
      outboxExecutorProvider.overrideWithValue(_NoopExecutor()),
      onlineProvider.overrideWith((ref) => Stream.value(true)),
    ]);
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).signIn('AUM0101', 'abc12345');

    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const _App()));
    await tester.pumpAndSettle();
    expect(find.text('Language'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('മലയാളം').last);
    await tester.pumpAndSettle();

    expect(find.text('ഭാഷ'), findsOneWidget, reason: 'the "Language" row is now Malayalam');
    expect(find.text('സൈൻ ഔട്ട്'), findsOneWidget);
    expect(prefs.getString('aumlux.locale'), 'ml');
  });
}
