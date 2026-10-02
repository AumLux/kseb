// End-to-end navigation through the real router: a sub-page opened from a
// full-screen page must be the one on screen (not hidden behind it).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/core/media/attachments.dart';
import 'package:kseb/core/outbox/outbox.dart';
import 'package:kseb/core/router/app_router.dart';
import 'package:kseb/core/supabase/providers.dart';
import 'package:kseb/features/auth/data/auth_repository.dart';
import 'package:kseb/features/auth/domain/app_user.dart';
import 'package:kseb/features/commercial/commercial_repository.dart';
import 'package:kseb/features/commercial/entities.dart';
import 'package:kseb/features/commercial/entity_pages.dart';
import 'package:kseb/features/home/dashboard_repository.dart';
import 'package:kseb/features/notifications/notifications.dart';
import 'package:kseb/features/org/data/org_repository.dart';
import 'package:kseb/features/staff/data/staff_repository.dart';
import 'package:kseb/features/staff/presentation/staff_detail_page.dart';
import 'package:kseb/features/staff/presentation/staff_form_page.dart';
import 'package:kseb/features/staff/presentation/staff_list_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/fake_auth.dart';

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

final _manager = AppUser(
  id: 'm1',
  employeeCode: 'AUM0100',
  fullName: 'Meera Nair',
  role: AppRole.manager,
  active: true,
  mustChangePassword: false,
  sectionId: 's1',
  sectionIds: const ['s1'],
);

final _director = AppUser(
  id: 'd1',
  employeeCode: 'AUM0001',
  fullName: 'Devika Menon',
  role: AppRole.director,
  active: true,
  mustChangePassword: false,
  sectionId: null,
  sectionIds: const [],
);

/// In-memory registers, enough for list → new → detail → back.
class _FakeCommercial implements CommercialRepository {
  final rows = <String, List<DbRow>>{};

  @override
  Future<List<DbRow>> list(EntityDef e) async => [...?rows[e.key]];
  @override
  Future<DbRow> get(EntityDef e, String id) async => rows[e.key]!.firstWhere((r) => r['id'] == id);
  @override
  Future<String> save(EntityDef e, DbRow values, {String? id}) async {
    final list = rows.putIfAbsent(e.key, () => []);
    final newId = id ?? 'r${list.length + 1}';
    list
      ..removeWhere((r) => r['id'] == newId)
      ..add({...values, 'id': newId});
    return newId;
  }

  @override
  Future<List<DbRow>> linked(EntityDef e, String column, String id) async => const [];
  @override
  Future<List<DbRow>> view(String name, String orderBy, {bool ascending = false}) async => const [];
  @override
  Future<Map<String, String>> refOptions(String refEntity) async => const {};
  @override
  Future<List<({EntityDef entity, DbRow row})>> search(String query) async => const [];
}

final _member = StaffMember.fromJson(const {
  'id': 'w1',
  'employee_code': 'AUM0301',
  'full_name': 'Line Worker One',
  'role': 'staff',
  'status': 'active',
  'section_id': 's1',
  'section': {'name': 'Kaloor'},
  'joined_on': '2025-04-01',
});

Future<void> _boot(
  WidgetTester tester, {
  AppUser? user,
  String at = Routes.staff,
  List<Override> extra = const [],
}) async {
  final me = user ?? _manager;
  tester.view
    ..physicalSize = const Size(400, 860)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(overrides: [
    sharedPreferencesProvider.overrideWithValue(prefs),
    authRepositoryProvider.overrideWithValue(FakeAuthRepository(profile: me, session: fakeSession(me.id))),
    outboxStoreProvider.overrideWithValue(_Store()),
    outboxExecutorProvider.overrideWithValue(_Executor()),
    onlineProvider.overrideWith((ref) => Stream.value(true)),
    dashboardProvider.overrideWith((ref) async => const Dashboard({})),
    notificationsProvider.overrideWith((ref) async => const []),
    orgTreeProvider.overrideWith((ref) async => const OrgTree([
          OrgUnit(id: 's1', level: OrgLevel.section, code: 'KLR', name: 'Kaloor', parentId: null),
        ])),
    teamsProvider.overrideWith((ref) async => const []),
    directoryProvider.overrideWith((ref) async => const []),
    staffListProvider.overrideWith((ref) async => [_member]),
    staffMemberProvider.overrideWith((ref, id) async => _member),
    nextEmployeeCodeProvider.overrideWith((ref) async => 'AUM0302'),
    ...extra,
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: Consumer(
      builder: (context, ref, _) => MaterialApp.router(
        theme: AppTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        routerConfig: ref.watch(routerProvider),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  container.read(routerProvider).go(at);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Staff → Add staff shows the form on top', (tester) async {
    await _boot(tester);
    expect(find.byType(StaffListPage), findsOneWidget);
    await tester.tap(find.text('Add staff'));
    await tester.pumpAndSettle();
    // `find` skips off-stage widgets: a page hidden behind another fails here.
    expect(find.byType(StaffFormPage), findsOneWidget);
    expect(find.byType(StaffListPage), findsNothing, reason: 'the list is covered');

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(StaffListPage), findsOneWidget, reason: 'back returns to the list');
  });

  testWidgets('Staff → a person shows their details on top', (tester) async {
    await _boot(tester);
    await tester.tap(find.text('Line Worker One'));
    await tester.pumpAndSettle();
    expect(find.byType(StaffDetailPage), findsOneWidget);
    expect(find.byType(StaffListPage), findsNothing);
  });

  // Regression: the form replaces itself with the new record's page
  // (pushReplacement), which drops the list's `await push` completer; the
  // list must still show the record when you come back.
  testWidgets('Commercial → new record → back shows it in the register', (tester) async {
    final repo = _FakeCommercial();
    await _boot(tester, user: _director, at: '${Routes.commercial}/tenders', extra: [
      commercialRepositoryProvider.overrideWithValue(repo),
      attachmentsProvider.overrideWith((ref, owner) async => const []),
    ]);
    expect(find.byType(EntityListPage), findsOneWidget);
    expect(find.text('LT line extension'), findsNothing);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.byType(EntityFormPage), findsOneWidget);
    final fields = find.descendant(of: find.byType(EntityFormPage), matching: find.byType(TextFormField));
    await tester.enterText(fields.at(0), 'TND-1');
    await tester.enterText(fields.at(1), 'LT line extension');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(EntityDetailPage), findsOneWidget, reason: 'lands on the new record');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(EntityListPage), findsOneWidget);
    expect(find.textContaining('LT line extension'), findsOneWidget, reason: 'the list refreshed');
  });
}
