import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/core/ui/sheets.dart';

Widget _app(Widget Function(BuildContext) body) => MaterialApp(
      theme: AppTheme.light(),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: Builder(builder: body)),
    );

void main() {
  // Regression: "Mark as completed" crashed with `_dependents.isEmpty` because
  // the note's controller was disposed while the dialog was still animating out.
  testWidgets('promptText returns the text and closes without errors', (tester) async {
    String? result = 'untouched';
    await tester.pumpWidget(_app((context) => TextButton(
          onPressed: () async => result = await promptText(context,
              title: 'Complete work', label: 'Completion note', confirmLabel: 'Continue'),
          child: const Text('open'),
        )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '  Fuse replaced  ');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle(); // runs the full exit animation
    expect(tester.takeException(), isNull);
    expect(result, 'Fuse replaced');
  });

  testWidgets('a required prompt blocks empty input; cancel returns null', (tester) async {
    String? result = 'untouched';
    await tester.pumpWidget(_app((context) => TextButton(
          onPressed: () async => result = await promptText(context,
              title: 'Reject', label: 'Reason', confirmLabel: 'Reject', minLength: 3),
          child: const Text('open'),
        )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Reject'));
    await tester.pumpAndSettle();
    expect(find.text('Reason is required'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(result, isNull);
  });

  testWidgets('DisposeWith keeps controllers alive until the sheet is gone', (tester) async {
    final controller = TextEditingController();
    var readAfterClose = '';
    await tester.pumpWidget(_app((context) => TextButton(
          onPressed: () async {
            await showAppSheet<void>(context,
                builder: (context) => DisposeWith(
                      controllers: [controller],
                      child: SheetScaffold(
                        title: 'Store',
                        primaryLabel: 'Save',
                        onPrimary: () => Navigator.pop(context),
                        children: [TextField(controller: controller)],
                      ),
                    ));
            readAfterClose = controller.text; // still valid right after close
          },
          child: const Text('open'),
        )));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Kaloor store');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(readAfterClose, 'Kaloor store');
    expect(() => controller.addListener(() {}), throwsFlutterError, reason: 'disposed once the sheet unmounted');
  });
}
