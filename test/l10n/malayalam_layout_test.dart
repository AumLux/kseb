// Malayalam strings run much longer than English, so screens that fit in
// English can overflow in Malayalam. These tests render the busiest screens
// in Malayalam on a small phone (360dp) at normal and large (130%) system
// text, and fail on any RenderFlex overflow (Flutter reports those as errors).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/core/location/location_service.dart';
import 'package:kseb/core/outbox/outbox.dart';
import 'package:kseb/core/supabase/providers.dart';
import 'package:kseb/features/attendance/data/attendance_repository.dart';
import 'package:kseb/features/attendance/presentation/my_attendance_view.dart';
import 'package:kseb/features/attendance/presentation/team_attendance_view.dart';
import 'package:kseb/features/auth/data/auth_repository.dart';
import 'package:kseb/features/auth/presentation/login_page.dart';
import 'package:kseb/features/org/presentation/section_picker.dart';
import 'package:kseb/features/staff/data/staff_repository.dart';
import 'package:kseb/features/staff/presentation/staff_form_page.dart';
import 'package:kseb/features/worksheets/data/worksheet_repository.dart';
import 'package:kseb/features/worksheets/presentation/worksheets_page.dart';
import 'package:kseb/features/auth/application/session_controller.dart';
import 'package:kseb/features/auth/domain/app_user.dart';
import 'package:kseb/features/home/dashboard_repository.dart';
import 'package:kseb/features/home/home_page.dart';
import 'package:kseb/features/more/more_page.dart';
import 'package:kseb/features/notifications/notifications.dart';
import 'package:kseb/features/org/data/org_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth.dart';

class _Store implements OutboxStore {
  @override
  Future<List<OutboxOp>> load() async => [];
  @override
  Future<void> save(List<OutboxOp> o) async {}
}

class _Executor implements OutboxExecutor {
  @override
  Future<void> execute(OutboxOp op) async {}
}

class _Gps implements LocationService {
  @override
  Future<bool> requestPermission() async => true;
  @override
  Future<bool> permissionUndecided() async => false;
  @override
  Future<CapturedLocation> current() async =>
      const CapturedLocation(lat: 9.9943, lng: 76.2999, accuracyM: 8, isMocked: false);
}

final _manager = AppUser(
  id: 'm1',
  employeeCode: 'AUM0100',
  fullName: 'Kaloor Section Manager Ramachandran',
  role: AppRole.manager,
  active: true,
  mustChangePassword: false,
);

/// Every KPI a manager can see, with large values (worst case for width).
final _dashboard = Dashboard({
  'my_attendance': {'check_in_at': DateTime.now().toUtc().subtract(const Duration(hours: 3)).toIso8601String()},
  'my_month_present': 22,
  'pending_approvals': 128,
  'unread_notifications': 9,
  'team_present_today': 145,
  'team_size': 160,
  'worksheets_in_progress': 37,
  'open_incidents': 4,
  'low_stock_items': 12,
  'active_work_orders': 58,
  'open_tenders': 11,
  'deposits_held': 125000000,
  'deposits_expiring_30d': 6,
  'receivables_outstanding': 98765432,
  'receivables_over_90d': 4500000,
});

OrgUnit _u(String id, OrgLevel level, String name, String? parent) =>
    OrgUnit(id: id, level: level, code: id.toUpperCase(), name: name, parentId: parent);

final _tree = OrgTree([
  _u('c1', OrgLevel.circle, 'Electrical Circle, Ernakulam', null),
  _u('d1', OrgLevel.division, 'Electrical Division, Ernakulam', 'c1'),
  _u('sd', OrgLevel.subdivision, 'Electrical Sub-division, Kaloor', 'd1'),
  _u('s1', OrgLevel.section, 'Electrical Section, Kaloor', 'sd'),
  _u('s2', OrgLevel.section, 'Electrical Section, Edappally', 'sd'),
]);

StaffMember _member(String id, String name, String role) => StaffMember.fromJson({
      'id': id,
      'employee_code': 'AUM0$id',
      'full_name': name,
      'role': role,
      'status': 'active',
      'section_id': 's1',
      'section': {'name': 'Electrical Section, Kaloor'},
      'joined_on': '2024-04-01',
    });

AttendanceDay _day(String userId, {bool outside = false}) => AttendanceDay.fromJson({
      'id': 'a$userId',
      'user_id': userId,
      'work_date': '2026-10-02',
      'status': 'present',
      'source': 'device',
      'check_in_at': '2026-10-02T03:30:00Z',
      'check_out_at': '2026-10-02T12:45:00Z',
      'check_in_lat': 9.9943,
      'check_in_lng': 76.2999,
      'check_in_accuracy_m': 12,
      'check_in_distance_m': outside ? 4200 : 40,
      'check_in_outside_geofence': outside,
      'check_in_mocked': outside,
    });

Worksheet _ws(String id, String status) => Worksheet.fromJson({
      'id': id,
      'code': 'WS-2026-000$id',
      'work_type': 'maintenance',
      'title': 'Replace damaged 11kV pin insulator and re-sag conductor near Kaloor junction',
      'section_id': 's1',
      'section': {'name': 'Electrical Section, Kaloor'},
      'location_text': 'Kaloor junction, near the bus stand',
      'status': status,
      'requested_by': 'm1',
      'created_at': '2026-10-01T04:00:00Z',
      'planned_date': '2026-10-03',
    });

Future<void> _pump(WidgetTester tester, Widget child, {double textScale = 1.0}) async {
  SharedPreferences.setMockInitialValues({'aumlux.locale': 'ml'});
  final prefs = await SharedPreferences.getInstance();
  tester.view
    ..physicalSize = const Size(360, 740)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  const ml = Locale('ml');
  await tester.pumpWidget(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      currentUserProvider.overrideWithValue(_manager),
      dashboardProvider.overrideWith((ref) async => _dashboard),
      notificationsProvider.overrideWith((ref) async => const []),
      outboxStoreProvider.overrideWithValue(_Store()),
      outboxExecutorProvider.overrideWithValue(_Executor()),
      onlineProvider.overrideWith((ref) => Stream.value(true)),
      orgTreeProvider.overrideWith((ref) async => _tree),
      teamsProvider.overrideWith((ref) async => const [Team(id: 't1', sectionId: 's1', name: 'Kaloor Line Team')]),
      nextEmployeeCodeProvider.overrideWith((ref) async => 'AUM0307'),
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      teamDayProvider.overrideWith((ref, date) async => [
            TeamDayRow(_member('201', 'Suresh Kumar Narayanan', 'staff'), _day('201')),
            TeamDayRow(_member('202', 'Line Worker With A Very Long Name', 'staff'), _day('202', outside: true)),
            TeamDayRow(_member('203', 'Anil', 'staff'), null),
          ]),
      worksheetsProvider.overrideWith((ref, scope) async => [_ws('1', 'submitted'), _ws('2', 'in_progress')]),
      locationServiceProvider.overrideWithValue(_Gps()),
      myTodayProvider.overrideWith((ref) async => null),
      myMonthProvider.overrideWith((ref, month) async => const []),
    ],
    child: MaterialApp(
      locale: ml,
      theme: AppTheme.light(locale: ml),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: child,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  for (final scale in [1.0, 1.3]) {
    group('Malayalam at ${(scale * 100).round()}% text', () {
      testWidgets('home: hero, today card, shortcuts and KPI tiles fit', (tester) async {
        await _pump(tester, const HomePage(), textScale: scale);
        expect(find.byType(QuickAction), findsWidgets);
        // Scroll through the KPI grid so every tile is laid out.
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -1600));
        await tester.pumpAndSettle();
      });

      testWidgets('more menu fits', (tester) async {
        await _pump(tester, const MorePage(), textScale: scale);
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();
      });

      testWidgets('attendance (me) fits', (tester) async {
        await _pump(tester, const Scaffold(body: MyAttendanceView()), textScale: scale);
        await tester.drag(find.byType(ListView), const Offset(0, -800));
        await tester.pumpAndSettle();
      });

      testWidgets('login fits', (tester) async {
        await _pump(tester, const LoginPage(), textScale: scale);
      });

      testWidgets('add-staff form fits (auto ID card, pickers)', (tester) async {
        await _pump(tester, const StaffFormPage(), textScale: scale);
        await tester.drag(find.byType(ListView), const Offset(0, -900));
        await tester.pumpAndSettle();
      });

      testWidgets('team attendance (list and map toggle) fits', (tester) async {
        await _pump(tester, const Scaffold(body: TeamAttendanceView()), textScale: scale);
        expect(find.text('Suresh Kumar Narayanan'), findsOneWidget);
      });

      testWidgets('worksheets list with filters fits', (tester) async {
        await _pump(tester, const WorksheetsPage(), textScale: scale);
        expect(find.textContaining('WS-2026-0001'), findsOneWidget);
      });

      testWidgets('section picker sheet fits', (tester) async {
        await _pump(
          tester,
          Builder(builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showSectionPicker(context, tree: _tree, allowed: _tree.sections),
                    child: const Text('open'),
                  ),
                ),
              )),
          textScale: scale,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.text('Electrical Section, Kaloor'), findsOneWidget);
      });

      testWidgets('bottom navigation labels fit', (tester) async {
        await _pump(
          tester,
          Builder(builder: (context) {
            final l10n = context.l10n;
            return Scaffold(
              bottomNavigationBar: NavigationBar(destinations: [
                NavigationDestination(icon: const Icon(Icons.home_rounded), label: l10n.navHome),
                NavigationDestination(icon: const Icon(Icons.fingerprint_rounded), label: l10n.navAttendance),
                NavigationDestination(icon: const Icon(Icons.handyman_rounded), label: l10n.navWork),
                NavigationDestination(icon: const Icon(Icons.grid_view_rounded), label: l10n.navMore),
              ]),
            );
          }),
          textScale: scale,
        );
      });
    });
  }
}
