import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/features/commercial/commercial_export.dart';
import 'package:kseb/features/commercial/commercial_repository.dart';
import 'package:kseb/features/commercial/entities.dart';
import 'package:kseb/features/commercial/entity_pages.dart';
import 'package:kseb/features/commercial/field_format.dart';
import 'package:kseb/l10n/app_localizations_en.dart';

final l = AppLocalizationsEn();

void main() {
  group('register definitions are internally consistent', () {
    for (final e in commercialEntities) {
      test(e.key, () {
        final keys = e.fields.map((f) => f.key).toSet();
        expect(keys.length, e.fields.length, reason: 'duplicate field keys');
        for (final c in [...e.primary, ...e.secondary, ...e.searchColumns, ?e.statusField]) {
          expect(keys, contains(c), reason: '${e.key}: unknown column $c');
        }
        for (final f in e.fields.where((f) => f.kind == FieldKind.choice)) {
          expect(f.options, isNotEmpty, reason: '${f.key} has no options');
          for (final o in f.options) {
            expect(f.labelFor(l, o).trim(), isNotEmpty);
          }
        }
        for (final f in e.fields.where((f) => f.kind == FieldKind.ref)) {
          expect(['sections', 'tenders', 'work_orders'], contains(f.refEntity));
        }
      });
    }
  });

  test('values are formatted for Indian users', () {
    final amount = tendersEntity.field('estimate_amount');
    expect(formatField(l, amount, 2450000), '₹ 24,50,000.00');
    expect(formatField(l, tendersEntity.field('notice_date'), '2026-10-01'), '01 Oct 2026');
    // 09:30 UTC == 15:00 IST
    expect(formatField(l, tendersEntity.field('submission_deadline'), '2026-10-11T09:30:00Z'), '11 Oct 2026, 03:00 PM');
    expect(formatField(l, gstEntity.field('period'), '2026-09-01'), 'Sep 2026');
    expect(formatField(l, depositsEntity.field('payment_mode'), 'bg'), 'Bank guarantee');
    expect(formatField(l, depositsEntity.field('kind'), 'bg'), 'Bank guarantee');
    expect(formatField(l, billsEntity.field('status'), 'submitted'), 'Submitted');
    expect(formatField(l, workOrdersEntity.field('tender_id'), 't1', refs: {'t1': 'KSEB/41 · Line extension'}),
        'KSEB/41 · Line extension');
    expect(formatField(l, amount, null), '—');
  });

  test('Excel export keeps money numeric and labels readable', () {
    final bytes = buildEntityXlsx(l, billsEntity, [
      {'invoice_no': 'INV/26/014', 'bill_type': 'ra', 'work_order_id': 'w1', 'invoice_date': '2026-09-15', 'amount': 412500.5, 'tax_amount': 74250, 'status': 'passed', 'paid_amount': 0},
    ], {
      'work_orders': {'w1': 'WO/EKM/2026/7 · Kaloor feeder'},
    });
    final rows = Excel.decodeBytes(bytes).tables.values.first.rows;
    final header = rows.first.map((c) => c?.value.toString()).toList();
    expect(header, containsAll(['Invoice no.', 'Bill type', 'Work order', 'Amount']));
    final data = rows[1];
    expect(data[header.indexOf('Amount')]?.value, isA<DoubleCellValue>());
    expect(data[header.indexOf('Bill type')]?.value.toString(), 'Running account (RA)');
    expect(data[header.indexOf('Work order')]?.value.toString(), 'WO/EKM/2026/7 · Kaloor feeder');
  });

  Future<void> pumpForm(WidgetTester tester, String key) async {
    tester.view
      ..physicalSize = const Size(900, 4000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [refOptionsProvider.overrideWith((ref, entity) async => const <String, String>{})],
      child: MaterialApp(
        theme: AppTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: EntityFormPage(entityKey: key),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('the tender form enforces required fields', (tester) async {
    await pumpForm(tester, 'tenders');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Tender / work reference is required'), findsOneWidget);
    expect(find.text('Title is required'), findsOneWidget);
    expect(find.text('KSEB'), findsOneWidget, reason: 'department defaults to KSEB');
  });

  testWidgets('the GST form rejects a malformed GSTIN', (tester) async {
    await pumpForm(tester, 'gst');
    await tester.enterText(find.byType(TextFormField).first, '32ABCDE1234');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid 15-character GSTIN'), findsOneWidget);
  });
}
