import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/supabase/providers.dart';
import '../../auth/domain/app_user.dart';

enum StaffStatus { active, suspended, exited }

/// A profile row as visible to the caller (RLS-scoped).
class StaffMember {
  const StaffMember({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.role,
    required this.status,
    this.email,
    this.phone,
    this.sectionId,
    this.sectionName,
    this.teamId,
    this.teamName,
    this.dob,
    this.joinedOn,
  });

  final String id;
  final String employeeCode;
  final String fullName;
  final AppRole role;
  final StaffStatus status;
  final String? email;
  final String? phone;
  final String? sectionId;
  final String? sectionName;
  final String? teamId;
  final String? teamName;
  final DateTime? dob;
  final DateTime? joinedOn;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return fullName.toLowerCase().contains(q) ||
        employeeCode.toLowerCase().contains(q) ||
        (phone?.contains(q) ?? false);
  }

  factory StaffMember.fromJson(Map<String, dynamic> j) => StaffMember(
        id: j['id'] as String,
        employeeCode: j['employee_code'] as String,
        fullName: j['full_name'] as String,
        role: AppRole.parse(j['role'] as String?),
        status: StaffStatus.values.byName(j['status'] as String? ?? 'active'),
        email: j['email'] as String?,
        phone: j['phone'] as String?,
        sectionId: j['section_id'] as String?,
        sectionName: (j['section'] as Map?)?['name'] as String?,
        teamId: j['team_id'] as String?,
        teamName: (j['team'] as Map?)?['name'] as String?,
        dob: DateTime.tryParse(j['dob'] as String? ?? ''),
        joinedOn: DateTime.tryParse(j['joined_on'] as String? ?? ''),
      );
}

/// Input for creating or editing an account.
class StaffDraft {
  const StaffDraft({
    required this.employeeCode,
    required this.fullName,
    required this.role,
    this.sectionId,
    this.teamId,
    this.email,
    this.phone,
    this.dob,
  });

  final String employeeCode;
  final String fullName;
  final AppRole role;
  final String? sectionId;
  final String? teamId;
  final String? email;
  final String? phone;
  final DateTime? dob;

  Map<String, dynamic> toJson() => {
        'employee_code': employeeCode.trim(),
        'full_name': fullName.trim(),
        'role': role.name,
        'section_id': sectionId,
        'team_id': teamId,
        'email': (email?.trim().isEmpty ?? true) ? null : email!.trim(),
        'phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
        'dob': dob?.toIso8601String().substring(0, 10),
      };
}

/// Returned once by create / reset_password.
class IssuedCredentials {
  const IssuedCredentials({required this.userId, required this.loginId, required this.tempPassword});

  final String userId;
  final String loginId;
  final String tempPassword;
}

final staffRepositoryProvider =
    Provider<StaffRepository>((ref) => StaffRepository(ref.watch(supabaseClientProvider)));

final staffListProvider = FutureProvider.autoDispose<List<StaffMember>>(
    (ref) => ref.watch(staffRepositoryProvider).list());

final staffMemberProvider = FutureProvider.autoDispose.family<StaffMember, String>(
    (ref, id) => ref.watch(staffRepositoryProvider).get(id));

class StaffRepository {
  StaffRepository(this._client);

  final SupabaseClient _client;

  static const _select = '*, section:sections!profiles_section_id_fkey(name), '
      'team:teams!profiles_team_id_fkey(name)';

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<List<StaffMember>> list() => _guard(() async {
        final rows = await _client.from('profiles').select(_select).order('full_name');
        return rows.map(StaffMember.fromJson).toList();
      });

  Future<StaffMember> get(String id) => _guard(() async {
        final row = await _client.from('profiles').select(_select).eq('id', id).single();
        return StaffMember.fromJson(row);
      });

  Future<Map<String, dynamic>> _admin(Map<String, dynamic> body) => _guard(() async {
        final res = await _client.functions.invoke('admin-users', body: body);
        return Map<String, dynamic>.from(res.data as Map);
      });

  /// Suggested next employee code (AUM0001 style). The server allocates the
  /// final one when [create] is called with `autoCode`, so races are safe.
  Future<String> nextEmployeeCode() => _guard(() async => await _client.rpc('next_employee_code') as String);

  Future<IssuedCredentials> create(StaffDraft draft, {bool autoCode = false}) async {
    final body = draft.toJson();
    if (autoCode) {
      body
        ..remove('employee_code')
        ..['auto_code'] = true;
    }
    final data = await _admin({'action': 'create', ...body});
    return IssuedCredentials(
      userId: data['user_id'] as String,
      loginId: data['login_id'] as String,
      tempPassword: data['temp_password'] as String,
    );
  }

  Future<void> update(String userId, StaffDraft draft) async {
    final body = draft.toJson()..remove('employee_code');
    await _admin({'action': 'update', 'user_id': userId, ...body});
  }

  Future<void> setStatus(String userId, StaffStatus status) =>
      _admin({'action': 'set_status', 'user_id': userId, 'status': status.name});

  Future<IssuedCredentials> resetPassword(StaffMember member) async {
    final data = await _admin({'action': 'reset_password', 'user_id': member.id});
    return IssuedCredentials(
      userId: member.id,
      loginId: member.email ?? member.employeeCode,
      tempPassword: data['temp_password'] as String,
    );
  }
}

/// Preview of the next employee code for the "Add staff" form.
final nextEmployeeCodeProvider =
    FutureProvider.autoDispose<String>((ref) => ref.watch(staffRepositoryProvider).nextEmployeeCode());
