import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/features/auth/domain/app_user.dart';

void main() {
  group('loginEmailFor', () {
    test('employee codes map to the crew login domain (case-insensitive)', () {
      expect(loginEmailFor(' AUM0123 '), 'aum0123@staff.aumlux.internal');
    });

    test('emails are used as typed, lower-cased', () {
      expect(loginEmailFor('Officer@AumLux.in'), 'officer@aumlux.in');
    });
  });

  test('password policy matches the server (8+, letters and digits)', () {
    expect(passwordMeetsPolicy('abc12345'), isTrue);
    expect(passwordMeetsPolicy('abcdefgh'), isFalse);
    expect(passwordMeetsPolicy('12345678'), isFalse);
    expect(passwordMeetsPolicy('ab1'), isFalse);
  });

  group('AppRole', () {
    test('mirrors the database rank order', () {
      expect(AppRole.director.rank, 0);
      expect(AppRole.staff.rank, 4);
      expect(AppRole.manager.atLeast(AppRole.supervisor), isTrue);
      expect(AppRole.staff.atLeast(AppRole.supervisor), isFalse);
    });

    test('approval needs strictly higher authority, except director', () {
      expect(AppRole.manager.outranks(AppRole.supervisor), isTrue);
      expect(AppRole.manager.outranks(AppRole.manager), isFalse);
      expect(AppRole.director.outranks(AppRole.director), isTrue);
    });

    test('unknown roles degrade to staff (least privilege)', () {
      expect(AppRole.parse('superadmin'), AppRole.staff);
      expect(AppRole.parse(null), AppRole.staff);
    });
  });

  test('AppUser parses the me() payload and round-trips through the cache', () {
    final user = AppUser.fromJson(const {
      'id': 'u1',
      'employee_code': 'AUM0101',
      'full_name': 'Ravi Kumar',
      'role': 'supervisor',
      'status': 'active',
      'must_change_password': true,
      'section_id': 's1',
      'section_ids': ['s1', 's2'],
      'team_ids': ['t1'],
      'dob': '1990-05-04',
    });
    expect(user.role, AppRole.supervisor);
    expect(user.active, isTrue);
    expect(user.firstName, 'Ravi');
    expect(user.sectionIds, ['s1', 's2']);
    expect(user.dob, DateTime(1990, 5, 4));
    final again = AppUser.fromJson(user.toJson());
    expect(again.sectionIds, user.sectionIds);
    expect(again.mustChangePassword, isTrue);
    expect(user.copyWith(mustChangePassword: false).mustChangePassword, isFalse);
  });
}
