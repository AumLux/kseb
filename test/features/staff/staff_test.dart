import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/design/design.dart';
import 'package:kseb/core/l10n/l10n.dart';
import 'package:kseb/features/auth/application/session_controller.dart';
import 'package:kseb/features/auth/data/auth_repository.dart';
import 'package:kseb/features/auth/domain/app_user.dart';
import 'package:kseb/features/org/data/org_repository.dart';
import 'package:kseb/features/staff/data/staff_repository.dart';
import 'package:kseb/features/staff/presentation/staff_form_page.dart';

import '../../helpers/fake_auth.dart';

OrgUnit _section(String id, String name) =>
    OrgUnit(id: id, level: OrgLevel.section, code: id.toUpperCase(), name: name, parentId: 'sd');

final _tree = OrgTree([_section('s1', 'Kaloor'), _section('s2', 'Aluva')]);

AppUser _manager() => AppUser.fromJson(const {
      'id': 'm1',
      'employee_code': 'AUM0100',
      'full_name': 'Meera Nair',
      'role': 'manager',
      'status': 'active',
      'must_change_password': false,
      'section_id': 's1',
      'section_ids': ['s1'],
    });

class _FakeStaffRepo implements StaffRepository {
  StaffDraft? created;
  @override
  Future<IssuedCredentials> create(StaffDraft draft) async {
    created = draft;
    return const IssuedCredentials(userId: 'new', loginId: 'AUM0201', tempPassword: 'Tmp4x9Kq2z');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('assignment rules (mirror admin-users)', () {
    test('managers assign only roles below them', () {
      expect(assignableRoles(AppRole.manager), [AppRole.staff, AppRole.supervisor]);
      expect(assignableRoles(AppRole.supervisor), [AppRole.staff]);
      expect(assignableRoles(AppRole.director), contains(AppRole.director));
    });

    test('non-executives only see their own sections', () {
      expect(assignableSections(_manager(), _tree).map((s) => s.id), ['s1']);
      final director = testUser(role: AppRole.director);
      expect(assignableSections(director, _tree), hasLength(2));
    });
  });

  group('StaffDraft / StaffMember', () {
    test('blank optional fields are sent as null, codes trimmed', () {
      final json = StaffDraft(
        employeeCode: ' AUM0201 ',
        fullName: 'Biju P',
        role: AppRole.staff,
        sectionId: 's1',
        email: '  ',
        phone: '',
        dob: DateTime(1995, 3, 9),
      ).toJson();
      expect(json['employee_code'], 'AUM0201');
      expect(json['email'], isNull);
      expect(json['phone'], isNull);
      expect(json['dob'], '1995-03-09');
      expect(json['role'], 'staff');
    });

    test('search matches name, code and phone', () {
      final m = StaffMember.fromJson(const {
        'id': 'x',
        'employee_code': 'AUM0201',
        'full_name': 'Biju Paul',
        'role': 'staff',
        'status': 'suspended',
        'phone': '9847012345',
        'section': {'name': 'Kaloor'},
        'team': null,
      });
      expect(m.status, StaffStatus.suspended);
      expect(m.sectionName, 'Kaloor');
      expect(m.matches('biju'), isTrue);
      expect(m.matches('0201'), isTrue);
      expect(m.matches('98470'), isTrue);
      expect(m.matches('aluva'), isFalse);
    });
  });

  testWidgets('a manager creates crew in their section and sees the credentials once',
      (tester) async {
    tester.view
      ..physicalSize = const Size(800, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final staffRepo = _FakeStaffRepo();
    final authRepo = FakeAuthRepository(profile: _manager());
    addTearDown(authRepo.dispose);
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      onlineProvider.overrideWith((ref) => Stream.value(true)),
      staffRepositoryProvider.overrideWithValue(staffRepo),
      orgTreeProvider.overrideWith((ref) async => _tree),
      teamsProvider.overrideWith((ref) async => const [Team(id: 't1', sectionId: 's1', name: 'Gang A')]),
      staffListProvider.overrideWith((ref) async => const []),
    ]);
    addTearDown(container.dispose);
    await container.read(sessionProvider.notifier).signIn('AUM0100', 'abc12345');

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light(),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: Text('list')),
      ),
    ));
    final nav = tester.state<NavigatorState>(find.byType(Navigator));
    nav.push(MaterialPageRoute<void>(builder: (_) => const StaffFormPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'AUM0201');
    await tester.enterText(find.byType(TextFormField).at(1), 'Biju Paul');

    await tester.tap(find.byType(DropdownButtonFormField<AppRole>));
    await tester.pumpAndSettle();
    expect(find.text('Manager'), findsNothing, reason: 'cannot create a peer');
    await tester.tap(find.text('Staff').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    expect(find.text('Aluva'), findsNothing, reason: 'out-of-scope section is not offered');
    await tester.tap(find.text('Kaloor').last);
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(staffRepo.created?.employeeCode, 'AUM0201');
    expect(staffRepo.created?.sectionId, 's1');
    expect(staffRepo.created?.role, AppRole.staff);
    expect(find.text('Tmp4x9Kq2z'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('list'), findsOneWidget, reason: 'form closes after the credentials are shown');
  });
}
