import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/core/location/location_rationale.dart';
import 'package:kseb/core/location/location_service.dart';

class _Gps implements LocationService {
  _Gps(this.undecided);
  final bool undecided;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> permissionUndecided() async => undecided;
  @override
  Future<CapturedLocation> current() => throw UnimplementedError();
}

Future<List<bool>> _run(WidgetTester tester, {required bool undecided}) async {
  final results = <bool>[];
  await tester.pumpWidget(ProviderScope(
    overrides: [locationServiceProvider.overrideWithValue(_Gps(undecided))],
    child: MaterialApp(
      theme: AppTheme.light(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Consumer(
        builder: (context, ref, _) => Scaffold(
          body: TextButton(
            onPressed: () async => results.add(await explainLocationIfNeeded(context, ref)),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('go'));
  await tester.pumpAndSettle();
  return results;
}

void main() {
  testWidgets('no explanation once permission has been decided', (tester) async {
    final results = await _run(tester, undecided: false);
    expect(results, [true]);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets('explains before the OS prompt; cancelling skips it', (tester) async {
    final results = await _run(tester, undecided: true);
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(results, [false]);
  });

  testWidgets('continuing proceeds to the OS prompt', (tester) async {
    final results = await _run(tester, undecided: true);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(results, [true]);
  });
}
