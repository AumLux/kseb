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
import 'package:kseb/features/attendance/presentation/holidays_page.dart';
import 'package:kseb/features/attendance/presentation/my_attendance_view.dart';
import 'package:kseb/features/attendance/presentation/team_attendance_view.dart';
import 'package:kseb/features/auth/data/auth_repository.dart';
import 'package:kseb/features/auth/presentation/login_page.dart';
import 'package:kseb/features/commercial/commercial_repository.dart';
import 'package:kseb/features/commercial/entity_pages.dart';
import 'package:kseb/features/inventory/data/inventory_repository.dart';
import 'package:kseb/features/inventory/presentation/catalog_pages.dart';
import 'package:kseb/features/org/presentation/org_page.dart';
import 'package:kseb/features/org/presentation/section_picker.dart';
import 'package:kseb/features/org/presentation/teams_page.dart';
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
      billAgeingProvider.overrideWith((ref) async => [
            for (final (i, b) in ['0-30', '31-60', '61-90', '90+', 'settled'].indexed)
              {'id': 'b$i', 'bucket': b, 'outstanding': 1250000 * (i + 1)},
          ]),
      depositsExpiringProvider.overrideWith((ref) async => [
            {'id': 'd1', 'kind': 'bg', 'amount': 2500000, 'instrument_no': 'BG/2026/00451', 'bank_name': 'State Bank of India',
             'validity_date': '2026-10-09', 'days_left': 7},
            {'id': 'd2', 'kind': 'emd', 'amount': 150000, 'validity_date': '2026-10-28', 'days_left': 26},
          ]),
      locationServiceProvider.overrideWithValue(_Gps()),
      myTodayProvider.overrideWith((ref) async => null),
      myMonthProvider.overrideWith((ref, month) async => const []),
      directoryProvider.overrideWith((ref) async => [
            const Person(id: 'sup', fullName: 'Suresh Kumar Narayanan', employeeCode: 'AUM0201', role: AppRole.supervisor, sectionId: 's1', teamId: 't1'),
            for (var i = 0; i < 5; i++)
              Person(id: 'w$i', fullName: 'Line Worker Number $i', employeeCode: 'AUM030$i', role: AppRole.staff, sectionId: 's1', teamId: i < 4 ? 't1' : null),
          ]),
      holidaysProvider.overrideWith((ref, year) async => [
            for (final (m, d, n) in [(1, 26, 'Republic Day'), (8, 28, 'Ayyankali Jayanthi'), (10, 2, 'Gandhi Jayanthi'), (12, 25, 'Christmas')])
              Holiday(id: 'h$m', date: DateTime(year, m, d), name: n),
            Holiday(id: 'hs', date: DateTime(year, 11, 14), name: 'Section foundation day (very long name)', sectionId: 's1'),
          ]),
      catalogProvider.overrideWith((ref) async => const [
            CatalogItem(id: 'm1', code: 'PLE-PSC-9M', name: 'PSC pole 9 m', category: 'Pole', unit: 'nos', reorderLevel: 10),
            CatalogItem(id: 'm2', code: 'CBL-ABC-3X50', name: 'LT aerial bunched cable 3×50+1×35 sq mm', category: 'Cable', unit: 'm', reorderLevel: 200),
            CatalogItem(id: 'm3', code: 'MTR-1PH-SM', name: 'Single-phase static energy meter', category: 'Metering', unit: 'nos', reorderLevel: 25),
          ]),
      storesProvider.overrideWith((ref) async => const [
            Store(id: 'st1', sectionId: 's1', name: 'Kaloor section store'),
            Store(id: 'st2', sectionId: 's2', name: 'Edappally section store'),
          ]),
      stockProvider.overrideWith((ref) async => const [
            StockLine(materialId: 'm1', materialCode: 'PLE-PSC-9M', materialName: 'PSC pole 9 m', category: 'Pole', unit: 'nos',
                storeId: 'st1', storeName: 'Kaloor section store', onHand: 4, reorderLevel: 10, lowStock: true),
          ]),
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

      testWidgets('organisation drill-down fits', (tester) async {
        await _pump(tester, const OrgPage(), textScale: scale);
        expect(find.byType(StatStrip), findsOneWidget);
        await tester.tap(find.text('Electrical Circle, Ernakulam'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Electrical Division, Ernakulam'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Electrical Sub-division, Kaloor'));
        await tester.pumpAndSettle();
        expect(find.text('Electrical Section, Kaloor'), findsOneWidget);
      });

      testWidgets('commercial overview fits', (tester) async {
        await _pump(tester, const CommercialHomePage(), textScale: scale);
        await tester.drag(find.byType(ListView).first, const Offset(0, -1400));
        await tester.pumpAndSettle();
      });

      testWidgets('teams list and team sheet fit', (tester) async {
        await _pump(tester, const TeamsPage(), textScale: scale);
        expect(find.byType(StatStrip), findsOneWidget);
        await tester.tap(find.text('Kaloor Line Team'));
        await tester.pumpAndSettle();
        expect(find.text('Line Worker Number 0'), findsOneWidget);
      });

      testWidgets('holidays (next-holiday card, months) fit', (tester) async {
        await _pump(tester, const HolidaysPage(), textScale: scale);
        await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
        await tester.pumpAndSettle();
      });

      testWidgets('material catalogue fits', (tester) async {
        await _pump(tester, const CatalogPage(), textScale: scale);
        expect(find.text('PSC pole 9 m'), findsOneWidget);
      });

      testWidgets('stores fit', (tester) async {
        await _pump(tester, const StoresPage(), textScale: scale);
        expect(find.text('Kaloor section store'), findsOneWidget);
      });

      testWidgets('language picker fits', (tester) async {
        await _pump(tester, const MorePage(), textScale: scale);
        final l10n = AppLocalizations.of(tester.element(find.byType(MorePage)));
        await tester.dragUntilVisible(find.text(l10n.moreLanguage), find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.moreLanguage));
        await tester.pumpAndSettle();
        expect(find.text('Malayalam'), findsOneWidget);
      });

      testWidgets('sign-out confirmation sheet fits', (tester) async {
        await _pump(tester, const MorePage(), textScale: scale);
        final l10n = AppLocalizations.of(tester.element(find.byType(MorePage)));
        await tester.dragUntilVisible(find.text(l10n.moreSignOut), find.byType(ListView), const Offset(0, -200));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.moreSignOut));
        await tester.pumpAndSettle();
        expect(find.text(l10n.moreSignOutConfirmTitle), findsOneWidget);
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
