import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/supabase/providers.dart';
import '../../auth/domain/app_user.dart';

enum OrgLevel { circle, division, subdivision, section }

extension OrgLevelTable on OrgLevel {
  String get table => switch (this) {
        OrgLevel.circle => 'circles',
        OrgLevel.division => 'divisions',
        OrgLevel.subdivision => 'subdivisions',
        OrgLevel.section => 'sections',
      };

  /// Foreign-key column pointing at the parent level.
  String? get parentColumn => switch (this) {
        OrgLevel.circle => null,
        OrgLevel.division => 'circle_id',
        OrgLevel.subdivision => 'division_id',
        OrgLevel.section => 'subdivision_id',
      };

  OrgLevel? get child => switch (this) {
        OrgLevel.circle => OrgLevel.division,
        OrgLevel.division => OrgLevel.subdivision,
        OrgLevel.subdivision => OrgLevel.section,
        OrgLevel.section => null,
      };
}

/// One node of the KSEB hierarchy. Section-only fields are null elsewhere.
class OrgUnit {
  const OrgUnit({
    required this.id,
    required this.level,
    required this.code,
    required this.name,
    this.parentId,
    this.address,
    this.lat,
    this.lng,
    this.geofenceRadiusM,
    this.active = true,
  });

  final String id;
  final OrgLevel level;
  final String code;
  final String name;
  final String? parentId;
  final String? address;
  final double? lat;
  final double? lng;
  final int? geofenceRadiusM;
  final bool active;

  factory OrgUnit.fromJson(OrgLevel level, Map<String, dynamic> j) => OrgUnit(
        id: j['id'] as String,
        level: level,
        code: j['code'] as String,
        name: j['name'] as String,
        parentId: level.parentColumn == null ? null : j[level.parentColumn] as String?,
        address: j['address'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        geofenceRadiusM: j['geofence_radius_m'] as int?,
        active: j['active'] as bool? ?? true,
      );
}

class OrgTree {
  const OrgTree(this.units);

  final List<OrgUnit> units;

  List<OrgUnit> of(OrgLevel level, {String? parentId}) => units
      .where((u) => u.level == level && (parentId == null || u.parentId == parentId))
      .toList();

  List<OrgUnit> get sections => of(OrgLevel.section);

  OrgUnit? byId(String? id) => id == null ? null : units.where((u) => u.id == id).firstOrNull;
}

class Team {
  const Team({
    required this.id,
    required this.sectionId,
    required this.name,
    this.supervisorId,
    this.active = true,
  });

  final String id;
  final String sectionId;
  final String name;
  final String? supervisorId;
  final bool active;

  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: j['id'] as String,
        sectionId: j['section_id'] as String,
        name: j['name'] as String,
        supervisorId: j['supervisor_id'] as String?,
        active: j['active'] as bool? ?? true,
      );
}

/// Name/role directory entry (visible to every active user).
class Person {
  const Person({
    required this.id,
    required this.fullName,
    required this.employeeCode,
    required this.role,
    this.sectionId,
    this.teamId,
    this.active = true,
  });

  final String id;
  final String fullName;
  final String employeeCode;
  final AppRole role;
  final String? sectionId;
  final String? teamId;
  final bool active;

  factory Person.fromJson(Map<String, dynamic> j) => Person(
        id: j['id'] as String,
        fullName: j['full_name'] as String,
        employeeCode: j['employee_code'] as String,
        role: AppRole.parse(j['role'] as String?),
        sectionId: j['section_id'] as String?,
        teamId: j['team_id'] as String?,
        active: j['status'] == 'active',
      );
}

final orgRepositoryProvider =
    Provider<OrgRepository>((ref) => OrgRepository(ref.watch(supabaseClientProvider)));

final orgTreeProvider = FutureProvider.autoDispose<OrgTree>(
    (ref) => ref.watch(orgRepositoryProvider).loadTree());

final teamsProvider =
    FutureProvider.autoDispose<List<Team>>((ref) => ref.watch(orgRepositoryProvider).teams());

final directoryProvider =
    FutureProvider.autoDispose<List<Person>>((ref) => ref.watch(orgRepositoryProvider).directory());

class OrgRepository {
  OrgRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<OrgTree> loadTree() => _guard(() async {
        final results = await Future.wait([
          for (final level in OrgLevel.values) _client.from(level.table).select().order('name'),
        ]);
        return OrgTree([
          for (var i = 0; i < OrgLevel.values.length; i++)
            ...results[i].map((j) => OrgUnit.fromJson(OrgLevel.values[i], j)),
        ]);
      });

  /// Inserts when [id] is null, otherwise updates code/name (+ section fields).
  Future<void> saveUnit({
    required OrgLevel level,
    String? id,
    String? parentId,
    required String code,
    required String name,
    String? address,
    double? lat,
    double? lng,
    int? geofenceRadiusM,
    bool? active,
  }) =>
      _guard(() async {
        final row = <String, dynamic>{
          'code': code.trim(),
          'name': name.trim(),
          if (level == OrgLevel.section) ...{
            'address': (address?.trim().isEmpty ?? true) ? null : address!.trim(),
            'lat': lat,
            'lng': lng,
            'geofence_radius_m': ?geofenceRadiusM,
            'active': ?active,
          },
        };
        if (id == null) {
          if (level.parentColumn != null) row[level.parentColumn!] = parentId;
          await _client.from(level.table).insert(row);
        } else {
          await _client.from(level.table).update(row).eq('id', id);
        }
      });

  Future<List<Team>> teams() => _guard(() async {
        final rows = await _client.from('teams').select().order('name');
        return rows.map(Team.fromJson).toList();
      });

  Future<void> saveTeam({
    String? id,
    required String sectionId,
    required String name,
    String? supervisorId,
    bool active = true,
  }) =>
      _guard(() async {
        if (id == null) {
          await _client.from('teams').insert({
            'section_id': sectionId,
            'name': name.trim(),
            'supervisor_id': supervisorId,
          });
        } else {
          await _client.from('teams').update({
            'name': name.trim(),
            'supervisor_id': supervisorId,
            'active': active,
          }).eq('id', id);
        }
      });

  Future<List<Person>> directory() => _guard(() async {
        final rows = await _client.rpc('people_directory') as List;
        return rows.map((r) => Person.fromJson(Map<String, dynamic>.from(r as Map))).toList();
      });
}
