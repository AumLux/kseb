import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/errors/app_failure.dart';
import 'package:kseb/core/format/ist.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/core/location/location_service.dart';
import 'package:kseb/core/outbox/outbox.dart';
import 'package:kseb/features/auth/application/session_controller.dart';
import 'package:kseb/features/org/data/org_repository.dart';
import 'package:kseb/features/attendance/application/capture_controller.dart';
import 'package:kseb/features/attendance/application/muster_export.dart';
import 'package:kseb/features/attendance/data/attendance_repository.dart';
import 'package:kseb/features/attendance/presentation/my_attendance_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Store implements OutboxStore {
  List<OutboxOp> ops = [];
  @override
  Future<List<OutboxOp>> load() async => ops;
  @override
  Future<void> save(List<OutboxOp> o) async => ops = List.of(o);
}

class _Executor implements OutboxExecutor {
  Object? error;
  final calls = <OutboxOp>[];
  @override
  Future<void> execute(OutboxOp op) async {
    calls.add(op);
    if (error != null) throw error!;
  }
}

class _Gps implements LocationService {
  _Gps({this.failure});
  final AppFailure? failure;
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> permissionUndecided() async => false;
  @override
  Future<CapturedLocation> current() async {
    if (failure != null) throw failure!;
    return const CapturedLocation(lat: 9.9943, lng: 76.2999, accuracyM: 8, isMocked: false);
  }
}

ProviderContainer _container(_Executor exec, {LocationService? gps}) {
  final c = ProviderContainer(overrides: [
    outboxStoreProvider.overrideWithValue(_Store()),
    outboxExecutorProvider.overrideWithValue(exec),
    onlineProvider.overrideWith((ref) => Stream.value(true)),
    locationServiceProvider.overrideWithValue(gps ?? _Gps()),
    myTodayProvider.overrideWith((ref) async => null),
    myMonthProvider.overrideWith((ref, month) async => const []),
    orgTreeProvider.overrideWith((ref) async => const OrgTree([])),
    currentUserProvider.overrideWithValue(null),
  ]);
  c.listen(outboxProvider, (_, __) {});
  return c;
}

MusterCell _cell(String user, int day, AttendanceStatus? s, {int? minutes, bool holiday = false}) => MusterCell(
      userId: user,
      employeeCode: user.toUpperCase(),
      fullName: 'Person $user',
      date: DateTime(2026, 10, day),
      status: s,
      workedMinutes: minutes,
      isHoliday: holiday,
    );

void main() {
  group('IST', () {
    test('a late-evening UTC instant is already the next day in India', () {
      expect(Ist.dateOf(DateTime.utc(2026, 10, 1, 19, 0)), DateTime(2026, 10, 2));
      expect(Ist.dateOf(DateTime.utc(2026, 10, 1, 18, 29)), DateTime(2026, 10, 1));
      expect(Ist.iso(DateTime(2026, 1, 5)), '2026-01-05');
      expect(Ist.monthEnd(DateTime(2026, 2, 10)), DateTime(2026, 2, 28));
    });
  });

  group('CaptureController', () {
    test('online: the check-in reaches the server with location and a request id', () async {
      final exec = _Executor();
      final c = _container(exec);
      addTearDown(c.dispose);
      final result = await c.read(captureControllerProvider).capture(
            CaptureKind.checkIn,
            location: const CapturedLocation(lat: 9.99, lng: 76.29, accuracyM: 6, isMocked: false),
          );
      expect(result.outcome, CaptureOutcome.synced);
      final op = exec.calls.single;
      expect(op.name, 'check_in');
      expect(op.payload['p_request_id'], op.id);
      expect(op.payload['p_lat'], 9.99);
      expect(c.read(outboxProvider).ops, isEmpty);
    });

    test('offline: the capture is kept with its original time and shows as pending', () async {
      final exec = _Executor()..error = AppFailure.network;
      final c = _container(exec);
      addTearDown(c.dispose);
      final at = DateTime.utc(2026, 10, 1, 3, 40);
      final result = await c.read(captureControllerProvider).capture(CaptureKind.checkIn, now: at);
      expect(result.outcome, CaptureOutcome.queued);
      final pending = c.read(pendingCapturesProvider).single;
      expect(pending.kind, CaptureKind.checkIn);
      expect(pending.capturedAt.toUtc(), at);
    });

    test('rejected: the server reason is shown and nothing stays queued', () async {
      final exec = _Executor()
        ..error = const PostgrestException(
            message: 'You have already checked in today.', code: 'P0001', hint: 'already_checked_in');
      final c = _container(exec);
      addTearDown(c.dispose);
      final result = await c.read(captureControllerProvider).capture(CaptureKind.checkIn);
      expect(result.outcome, CaptureOutcome.rejected);
      expect(result.message, contains('already checked in'));
      expect(c.read(outboxProvider).ops, isEmpty);
    });
  });

  group('muster roll', () {
    final cells = [
      _cell('a', 1, AttendanceStatus.present, minutes: 480),
      _cell('a', 2, AttendanceStatus.halfDay, minutes: 240),
      _cell('a', 3, null, holiday: true),
      _cell('b', 1, AttendanceStatus.leave),
      _cell('b', 2, AttendanceStatus.absent),
      _cell('b', 3, null),
    ];

    test('codes and per-person totals', () {
      final people = groupMuster(cells);
      expect(people.map((p) => p.employeeCode), ['A', 'B']);
      expect(people.first.cells.map(musterCode), ['P', 'HD', 'H']);
      expect(people.first.presentDays, 1.5);
      expect(people.first.workedMinutes, 720);
      expect(people.last.cells.map(musterCode), ['L', 'A', '-']);
      expect(people.last.leaveDays, 1);
      expect(people.last.absentDays, 1);
    });

    test('PDF export renders with the bundled font', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final bytes = await buildMusterPdf(
          cells: cells, month: DateTime(2026, 10), title: 'Muster roll — October 2026', generatedBy: 'Tester');
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
      expect(bytes.length, greaterThan(2000));
    });

    test('Excel export has the grid and the detail sheet', () {
      final bytes = buildMusterXlsx(cells: cells, month: DateTime(2026, 10), title: 'Muster roll — October 2026');
      final book = Excel.decodeBytes(bytes);
      expect(book.tables.keys, containsAll(['Muster', 'Check-in times']));
      final grid = book.tables['Muster']!;
      expect(grid.rows[2][0]?.value.toString(), 'Employee ID');
      expect(grid.rows[3][1]?.value.toString(), 'Person a');
      expect(grid.rows[3][2]?.value.toString(), 'P');
    });
  });

  test('review flags: mock location, outside area and missing GPS need attention', () {
    AttendanceDay day({bool mocked = false, bool? outside, bool hasLocation = true}) => AttendanceDay(
          id: 'x',
          userId: 'u',
          workDate: DateTime(2026, 10, 1),
          status: AttendanceStatus.present,
          source: 'device',
          checkInAt: DateTime(2026, 10, 1, 9),
          checkInMocked: mocked,
          outsideGeofence: outside,
          hasLocation: hasLocation,
        );
    expect(day().needsReview, isFalse);
    expect(day(mocked: true).needsReview, isTrue);
    expect(day(outside: true).needsReview, isTrue);
    expect(day(hasLocation: false).needsReview, isTrue);
  });

  testWidgets('check-in from the attendance screen confirms success', (tester) async {
    final exec = _Executor();
    final c = _container(exec);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: MyAttendanceView()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check in'));
    await tester.pumpAndSettle();
    expect(exec.calls.single.name, 'check_in');
    expect(find.text('Attendance recorded'), findsOneWidget);
  });

  testWidgets('without GPS the crew member can still record, explicitly', (tester) async {
    final exec = _Executor();
    final c = _container(exec,
        gps: _Gps(failure: const AppFailure('location_timeout', "Couldn't get your location.", retryable: true)));
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        theme: AppTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: MyAttendanceView()),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Check in'));
    await tester.pumpAndSettle();
    expect(find.text('Location unavailable'), findsOneWidget);
    await tester.tap(find.text('Record without location'));
    await tester.pumpAndSettle();
    expect(exec.calls.single.payload['p_lat'], isNull);
  });
}
