import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/errors/app_failure.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/core/outbox/outbox.dart';
import 'package:kseb/core/supabase/providers.dart';
import 'package:kseb/features/worksheets/data/worksheet_repository.dart';
import 'package:kseb/features/worksheets/presentation/worksheet_sheets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Store implements OutboxStore {
  List<OutboxOp> ops = [];
  @override
  Future<List<OutboxOp>> load() async => ops;
  @override
  Future<void> save(List<OutboxOp> o) async => ops = List.of(o);
}

class _Executor implements OutboxExecutor {
  final calls = <OutboxOp>[];
  Object? Function(OutboxOp op)? fail;
  @override
  Future<void> execute(OutboxOp op) async {
    final error = fail?.call(op);
    if (error != null) throw error;
    calls.add(op);
  }
}

ProviderContainer _container(_Executor exec) {
  final c = ProviderContainer(overrides: [
    supabaseClientProvider.overrideWithValue(SupabaseClient('http://localhost:54321', 'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false))),
    outboxStoreProvider.overrideWithValue(_Store()),
    outboxExecutorProvider.overrideWithValue(exec),
    onlineProvider.overrideWith((ref) => Stream.value(true)),
  ]);
  c.listen(outboxProvider, (_, __) {});
  return c;
}

const _draft = WorksheetDraft(
  workType: WorkType.maintenance,
  title: '  Replace DP fuse ',
  sectionId: 's1',
  locationText: 'Kaloor junction',
  permitBookNo: ' ',
);

void main() {
  test('draft serialises trimmed values and nulls blanks', () {
    final json = _draft.toJson();
    expect(json['title'], 'Replace DP fuse');
    expect(json['permit_book_no'], isNull);
    expect(json['work_type'], 'maintenance');
  });

  test('status parsing handles in_progress', () {
    expect(WorksheetStatusDb.parse('in_progress'), WorksheetStatus.inProgress);
    expect(WorksheetStatus.inProgress.db, 'in_progress');
  });

  test('a permit is complete only with all checks and mandatory PPE', () {
    Permit p({List<String> ppe = const ['helmet', 'gloves', 'safety_belt'], bool earthing = true}) => Permit(
          lineClearRef: 'LC/1',
          lineClearIssuedBy: 'AE',
          isolationPoints: 'AB switch',
          earthingDone: earthing,
          testedDead: true,
          toolboxTalkDone: true,
          ppe: ppe,
          signedAt: DateTime(2026),
        );
    expect(p().complete, isTrue);
    expect(p(earthing: false).complete, isFalse);
    expect(p(ppe: ['helmet', 'gloves']).complete, isFalse);
  });

  group('create (outbox)', () {
    test('online: insert then submit, in that order, with the same id', () async {
      final exec = _Executor();
      final c = _container(exec);
      addTearDown(c.dispose);
      final (id, synced) = await c.read(worksheetRepositoryProvider).create(_draft, submit: true);
      expect(synced, isTrue);
      expect(exec.calls.map((o) => o.name), ['worksheets', 'transition_worksheet']);
      expect(exec.calls.first.payload['id'], id);
      expect(exec.calls.last.payload, {'p_id': id, 'p_action': 'submit', 'p_note': null});
    });

    test('offline: both stay queued and the list shows it as pending', () async {
      final exec = _Executor()..fail = (_) => AppFailure.network;
      final c = _container(exec);
      addTearDown(c.dispose);
      final (_, synced) = await c.read(worksheetRepositoryProvider).create(_draft, submit: true);
      expect(synced, isFalse);
      expect(c.read(outboxProvider).ops, hasLength(2));
      expect(c.read(pendingWorksheetsProvider).single.label, 'Replace DP fuse');
    });

    test('rejected insert clears its queued submit too', () async {
      final exec = _Executor()
        ..fail = (op) => op.name == 'worksheets'
            ? const PostgrestException(message: 'new row violates row-level security policy', code: '42501')
            : null;
      final c = _container(exec);
      addTearDown(c.dispose);
      await expectLater(
        c.read(worksheetRepositoryProvider).create(_draft, submit: true),
        throwsA(isA<AppFailure>()),
      );
      expect(c.read(outboxProvider).ops, isEmpty);
    });
  });

  testWidgets('the permit cannot be signed until checks and mandatory PPE are confirmed', (tester) async {
    tester.view
      ..physicalSize = const Size(800, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final c = _container(_Executor());
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(onPressed: () => showPermitSheet(context, 'ws1'), child: const Text('open')),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    FilledButton sign() => tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Sign permit'));
    expect(sign().onPressed, isNull);

    await tester.tap(find.text('Earthing done on both sides'));
    await tester.tap(find.text('Line tested dead with tester'));
    await tester.tap(find.text('Toolbox talk done with the crew'));
    await tester.pump();
    expect(sign().onPressed, isNull, reason: 'PPE still missing');
    expect(find.text('Helmet, gloves and safety belt are mandatory'), findsOneWidget);

    for (final ppe in ['Helmet', 'Insulated gloves', 'Safety belt']) {
      await tester.tap(find.text(ppe));
    }
    await tester.pump();
    expect(sign().onPressed, isNotNull);
  });
}
