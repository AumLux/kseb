import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/format/ist.dart';
import '../../../core/supabase/providers.dart';
import '../../auth/application/session_controller.dart';
import '../../auth/domain/app_user.dart';
import '../../staff/data/staff_repository.dart';

enum AttendanceStatus { present, absent, leave, halfDay, holiday }

extension AttendanceStatusDb on AttendanceStatus {
  String get db => this == AttendanceStatus.halfDay ? 'half_day' : name;

  static AttendanceStatus parse(String? v) =>
      v == 'half_day' ? AttendanceStatus.halfDay : AttendanceStatus.values.byName(v ?? 'present');
}

DateTime? _ts(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();

/// One person-day (`attendance_days`).
class AttendanceDay {
  const AttendanceDay({
    required this.id,
    required this.userId,
    required this.workDate,
    required this.status,
    required this.source,
    this.checkInAt,
    this.checkOutAt,
    this.checkInAccuracyM,
    this.checkInMocked = false,
    this.checkInDistanceM,
    this.outsideGeofence,
    this.hasLocation = false,
    this.verifiedAt,
    this.note,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.checkOutAccuracyM,
    this.checkOutMocked = false,
    this.checkOutDistanceM,
    this.checkOutOutsideGeofence,
  });

  final String id;
  final String userId;
  final DateTime workDate;
  final AttendanceStatus status;
  final String source;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final double? checkInAccuracyM;
  final bool checkInMocked;
  final int? checkInDistanceM;
  final bool? outsideGeofence;
  final bool hasLocation;
  final DateTime? verifiedAt;
  final String? note;

  // Where the shift started and ended (visible to the person and to anyone
  // who can see their attendance: supervisor, manager, COO/Director).
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final double? checkOutAccuracyM;
  final bool checkOutMocked;
  final int? checkOutDistanceM;
  final bool? checkOutOutsideGeofence;

  bool get hasCheckOutLocation => checkOutLat != null && checkOutLng != null;
  bool get verified => verifiedAt != null;

  /// Something a supervisor should look at before verifying.
  bool get needsReview =>
      checkInMocked ||
      checkOutMocked ||
      outsideGeofence == true ||
      checkOutOutsideGeofence == true ||
      (source == 'device' && !hasLocation);

  Duration? get worked =>
      (checkInAt != null && checkOutAt != null) ? checkOutAt!.difference(checkInAt!) : null;

  factory AttendanceDay.fromJson(Map<String, dynamic> j) => AttendanceDay(
        id: j['id'] as String,
        userId: j['user_id'] as String,
        workDate: DateTime.parse(j['work_date'] as String),
        status: AttendanceStatusDb.parse(j['status'] as String?),
        source: j['source'] as String? ?? 'device',
        checkInAt: _ts(j['check_in_at']),
        checkOutAt: _ts(j['check_out_at']),
        checkInAccuracyM: (j['check_in_accuracy_m'] as num?)?.toDouble(),
        checkInMocked: j['check_in_mocked'] as bool? ?? false,
        checkInDistanceM: j['check_in_distance_m'] as int?,
        outsideGeofence: j['check_in_outside_geofence'] as bool?,
        hasLocation: j['check_in_lat'] != null,
        verifiedAt: _ts(j['verified_at']),
        note: j['note'] as String?,
        checkInLat: (j['check_in_lat'] as num?)?.toDouble(),
        checkInLng: (j['check_in_lng'] as num?)?.toDouble(),
        checkOutLat: (j['check_out_lat'] as num?)?.toDouble(),
        checkOutLng: (j['check_out_lng'] as num?)?.toDouble(),
        checkOutAccuracyM: (j['check_out_accuracy_m'] as num?)?.toDouble(),
        checkOutMocked: j['check_out_mocked'] as bool? ?? false,
        checkOutDistanceM: j['check_out_distance_m'] as int?,
        checkOutOutsideGeofence: j['check_out_outside_geofence'] as bool?,
      );
}

/// A team member and their record for the selected day (if any).
class TeamDayRow {
  const TeamDayRow(this.member, this.day);
  final StaffMember member;
  final AttendanceDay? day;
}

/// One cell of the monthly muster roll.
class MusterCell {
  const MusterCell({
    required this.userId,
    required this.employeeCode,
    required this.fullName,
    required this.date,
    this.status,
    this.checkInAt,
    this.checkOutAt,
    this.workedMinutes,
    this.isHoliday = false,
    this.verified = false,
  });

  final String userId;
  final String employeeCode;
  final String fullName;
  final DateTime date;
  final AttendanceStatus? status;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final int? workedMinutes;
  final bool isHoliday;
  final bool verified;

  factory MusterCell.fromJson(Map<String, dynamic> j) => MusterCell(
        userId: j['user_id'] as String,
        employeeCode: j['employee_code'] as String,
        fullName: j['full_name'] as String,
        date: DateTime.parse(j['work_date'] as String),
        status: j['status'] == null ? null : AttendanceStatusDb.parse(j['status'] as String),
        checkInAt: _ts(j['check_in_at']),
        checkOutAt: _ts(j['check_out_at']),
        workedMinutes: j['worked_minutes'] as int?,
        isHoliday: j['is_holiday'] as bool? ?? false,
        verified: j['verified'] as bool? ?? false,
      );
}

class Holiday {
  const Holiday({required this.id, required this.date, required this.name, this.sectionId});
  final String id;
  final DateTime date;
  final String name;
  final String? sectionId;

  factory Holiday.fromJson(Map<String, dynamic> j) => Holiday(
        id: j['id'] as String,
        date: DateTime.parse(j['holiday_date'] as String),
        name: j['name'] as String,
        sectionId: j['section_id'] as String?,
      );
}

final attendanceRepositoryProvider =
    Provider<AttendanceRepository>((ref) => AttendanceRepository(ref.watch(supabaseClientProvider)));

final myTodayProvider = FutureProvider.autoDispose<AttendanceDay?>((ref) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return null;
  return ref.watch(attendanceRepositoryProvider).day(me.id, Ist.today());
});

final myMonthProvider = FutureProvider.autoDispose.family<List<AttendanceDay>, DateTime>((ref, month) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.watch(attendanceRepositoryProvider).range(me.id, Ist.monthStart(month), Ist.monthEnd(month));
});

final teamDayProvider = FutureProvider.autoDispose.family<List<TeamDayRow>, DateTime>((ref, date) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.watch(attendanceRepositoryProvider).teamDay(me, date);
});

final holidaysProvider = FutureProvider.autoDispose.family<List<Holiday>, int>(
    (ref, year) => ref.watch(attendanceRepositoryProvider).holidays(year));

class AttendanceRepository {
  AttendanceRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<AttendanceDay?> day(String userId, DateTime date) => _guard(() async {
        final row = await _client
            .from('attendance_days')
            .select()
            .eq('user_id', userId)
            .eq('work_date', Ist.iso(date))
            .maybeSingle();
        return row == null ? null : AttendanceDay.fromJson(row);
      });

  Future<List<AttendanceDay>> range(String userId, DateTime from, DateTime to) => _guard(() async {
        final rows = await _client
            .from('attendance_days')
            .select()
            .eq('user_id', userId)
            .gte('work_date', Ist.iso(from))
            .lte('work_date', Ist.iso(to))
            .order('work_date');
        return rows.map(AttendanceDay.fromJson).toList();
      });

  /// Everyone below the caller in scope (RLS decides who that is) and their
  /// record for [date].
  Future<List<TeamDayRow>> teamDay(AppUser me, DateTime date) => _guard(() async {
        final people = await _client
            .from('profiles')
            .select('*, section:sections!profiles_section_id_fkey(name), team:teams!profiles_team_id_fkey(name)')
            .eq('status', 'active')
            .neq('id', me.id)
            .order('full_name');
        final members = people
            .map(StaffMember.fromJson)
            .where((m) => me.role.outranks(m.role))
            .toList();
        if (members.isEmpty) return const <TeamDayRow>[];
        final rows = await _client
            .from('attendance_days')
            .select()
            .eq('work_date', Ist.iso(date))
            .inFilter('user_id', members.map((m) => m.id).toList());
        final byUser = {for (final r in rows) r['user_id'] as String: AttendanceDay.fromJson(r)};
        return [for (final m in members) TeamDayRow(m, byUser[m.id])];
      });

  Future<void> mark(String userId, DateTime date, AttendanceStatus status, String reason) =>
      _guard(() => _client.rpc('mark_attendance', params: {
            'p_user_id': userId,
            'p_work_date': Ist.iso(date),
            'p_status': status.db,
            'p_reason': reason,
          }));

  Future<void> correct(AttendanceDay day,
          {required AttendanceStatus status,
          DateTime? checkIn,
          DateTime? checkOut,
          required String reason}) =>
      _guard(() => _client.rpc('correct_attendance', params: {
            'p_attendance_id': day.id,
            'p_status': status.db,
            'p_check_in_at': checkIn?.toUtc().toIso8601String(),
            'p_check_out_at': checkOut?.toUtc().toIso8601String(),
            'p_reason': reason,
          }));

  Future<int> verify(List<String> ids) =>
      _guard(() async => (await _client.rpc('verify_attendance', params: {'p_ids': ids}) as num).toInt());

  Future<List<MusterCell>> muster(DateTime month, {String? sectionId}) => _guard(() async {
        final rows = await _client.rpc('attendance_month', params: {
          'p_month': Ist.iso(Ist.monthStart(month)),
          'p_section_id': sectionId,
        }) as List;
        return rows.map((r) => MusterCell.fromJson(Map<String, dynamic>.from(r as Map))).toList();
      });

  Future<List<Holiday>> holidays(int year) => _guard(() async {
        final rows = await _client
            .from('holidays')
            .select()
            .gte('holiday_date', '$year-01-01')
            .lte('holiday_date', '$year-12-31')
            .order('holiday_date');
        return rows.map(Holiday.fromJson).toList();
      });

  Future<void> addHoliday(DateTime date, String name, {String? sectionId}) => _guard(() =>
      _client.from('holidays').insert({'holiday_date': Ist.iso(date), 'name': name.trim(), 'section_id': sectionId}));

  Future<void> deleteHoliday(String id) => _guard(() => _client.from('holidays').delete().eq('id', id));
}
