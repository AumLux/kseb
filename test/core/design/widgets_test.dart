import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  group('StatusChip.fromDomain', () {
    test('maps lifecycle statuses to the documented tones', () {
      expect(StatusChip.toneFor('approved'), StatusTone.success);
      expect(StatusChip.toneFor('present'), StatusTone.success);
      expect(StatusChip.toneFor('pending'), StatusTone.warning);
      expect(StatusChip.toneFor('submitted'), StatusTone.warning);
      expect(StatusChip.toneFor('rejected'), StatusTone.danger);
      expect(StatusChip.toneFor('overdue'), StatusTone.danger);
      expect(StatusChip.toneFor('in_progress'), StatusTone.info);
      expect(StatusChip.toneFor('draft'), StatusTone.brand);
      expect(StatusChip.toneFor('leave'), StatusTone.neutral);
      expect(StatusChip.toneFor('something_unknown'), StatusTone.neutral);
    });

    testWidgets('always renders text, not colour alone', (tester) async {
      await tester
          .pumpWidget(_wrap(StatusChip.fromDomain('Awaiting Approval')));
      expect(find.text('Awaiting approval'), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
    });
  });

  group('AppButton', () {
    testWidgets('primary uses navy text on orange at 52dp', (tester) async {
      await tester
          .pumpWidget(_wrap(AppButton(label: 'Submit', onPressed: () {})));
      final style = DefaultTextStyle.of(tester.element(find.text('Submit')));
      expect(style.style.color, AppColors.onPrimary);
      expect(tester.getSize(find.byType(FilledButton)).height,
          greaterThanOrEqualTo(AppSizes.primaryActionHeight));
    });

    testWidgets('loading state ignores taps and shows a spinner',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
          AppButton(label: 'Save', loading: true, onPressed: () => taps++)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      expect(taps, 0);
    });

    testWidgets('secondary meets the 48dp touch target', (tester) async {
      await tester.pumpWidget(
          _wrap(AppButton.secondary(label: 'Cancel', onPressed: () {})));
      expect(tester.getSize(find.byType(OutlinedButton)).height,
          greaterThanOrEqualTo(AppSizes.minTouchTarget));
    });
  });

  group('AppTextField', () {
    testWidgets('shows a label above the field and validates required',
        (tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(_wrap(Form(
        key: formKey,
        child: const SizedBox(
          width: 320,
          child: AppTextField(label: 'Pole number', required: true),
        ),
      )));
      expect(find.text('Pole number *', findRichText: true), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Pole number is required'), findsOneWidget);
    });
  });

  group('State views', () {
    testWidgets('ErrorState shows retry only with a callback', (tester) async {
      await tester.pumpWidget(_wrap(const ErrorState(title: 'Could not load')));
      expect(find.text('Try again'), findsNothing);

      var retried = false;
      await tester.pumpWidget(_wrap(ErrorState(
          title: 'Could not load', onRetry: () => retried = true)));
      await tester.tap(find.text('Try again'));
      expect(retried, isTrue);
    });

    testWidgets('SyncBadge hides when nothing is pending', (tester) async {
      await tester.pumpWidget(_wrap(const SyncBadge(pending: 0)));
      expect(find.textContaining('pending'), findsNothing);
      await tester.pumpWidget(_wrap(const SyncBadge(pending: 3)));
      expect(find.text('3 pending'), findsOneWidget);
    });
  });

  group('KpiCard', () {
    testWidgets('exposes label and value to screen readers', (tester) async {
      await tester.pumpWidget(_wrap(const SizedBox(
          width: 200, child: KpiCard(label: 'Present today', value: '42'))));
      expect(find.bySemanticsLabel('Present today: 42'), findsOneWidget);
    });
  });
}
