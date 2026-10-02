import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/core/ui/dialogs.dart';
import 'package:kseb/core/ui/sheets.dart';

Future<bool?> _open(WidgetTester tester, {required String message, String? title}) async {
  bool? result;
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () async => result = await confirmAction(context, message: message, title: title, confirmLabel: 'Go'),
          child: const Text('open'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('a "Question? Explanation." message splits into title and body', (tester) async {
    await _open(tester, message: 'Suspend Anil? They are signed out immediately.');
    expect(find.byType(SheetScaffold), findsOneWidget);
    expect(find.text('Suspend Anil?'), findsOneWidget);
    expect(find.text('They are signed out immediately.'), findsOneWidget);
  });

  testWidgets('confirm returns true, cancel returns false', (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await confirmAction(context, message: 'Remove?', confirmLabel: 'Go'),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(result, isTrue);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });
}
