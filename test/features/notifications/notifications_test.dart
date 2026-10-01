import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/features/notifications/notifications.dart';

AppNotification _n(String id, {bool read = false}) => AppNotification.fromJson({
      'id': id,
      'title': 'Worksheet approved',
      'body': 'WS-2026-00042 · Replace DP fuse',
      'route': '/work/42',
      'created_at': '2026-10-01T04:30:00Z',
      'read_at': read ? '2026-10-01T05:00:00Z' : null,
    });

Future<void> _pump(WidgetTester tester, List<AppNotification> items) => tester.pumpWidget(ProviderScope(
      overrides: [notificationsProvider.overrideWith((ref) async => items)],
      child: MaterialApp(
        theme: AppTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: Center(child: NotificationBell())),
      ),
    ));

void main() {
  test('notifications parse with deep-link route and read state', () {
    final n = _n('1');
    expect(n.unread, isTrue);
    expect(n.route, '/work/42');
    expect(_n('2', read: true).unread, isFalse);
  });

  testWidgets('the bell shows the unread count', (tester) async {
    await _pump(tester, [_n('1'), _n('2'), _n('3', read: true)]);
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('no badge when everything is read', (tester) async {
    await _pump(tester, [_n('1', read: true)]);
    await tester.pumpAndSettle();
    final badge = tester.widget<Badge>(find.byType(Badge));
    expect(badge.isLabelVisible, isFalse);
  });
}
