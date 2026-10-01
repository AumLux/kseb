import '../../../core/config/env.dart';

/// Role hierarchy, mirroring `private.role_rank` in the database.
/// Lower [rank] = more authority.
enum AppRole {
  staff(4),
  supervisor(3),
  manager(2),
  coo(1),
  director(0);

  const AppRole(this.rank);

  final int rank;

  static AppRole parse(String? value) =>
      AppRole.values.firstWhere((r) => r.name == value, orElse: () => AppRole.staff);

  /// True when this role has at least the authority of [other].
  bool atLeast(AppRole other) => rank <= other.rank;

  /// Strictly higher authority (required to approve or manage [other]),
  /// except that a Director may manage Directors.
  bool outranks(AppRole other) => rank < other.rank || this == AppRole.director;

  bool get isExecutive => this == AppRole.coo || this == AppRole.director;
}

/// The signed-in user as returned by the `me()` RPC.
class AppUser {
  const AppUser({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    required this.role,
    required this.active,
    required this.mustChangePassword,
    this.email,
    this.phone,
    this.sectionId,
    this.teamId,
    this.sectionIds = const [],
    this.teamIds = const [],
    this.dob,
  });

  final String id;
  final String employeeCode;
  final String fullName;
  final AppRole role;
  final bool active;
  final bool mustChangePassword;
  final String? email;
  final String? phone;
  final String? sectionId;
  final String? teamId;
  final List<String> sectionIds;
  final List<String> teamIds;
  final DateTime? dob;

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        employeeCode: json['employee_code'] as String,
        fullName: json['full_name'] as String,
        role: AppRole.parse(json['role'] as String?),
        active: json['status'] == 'active',
        mustChangePassword: json['must_change_password'] as bool? ?? false,
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        sectionId: json['section_id'] as String?,
        teamId: json['team_id'] as String?,
        sectionIds: List<String>.from(json['section_ids'] as List? ?? const []),
        teamIds: List<String>.from(json['team_ids'] as List? ?? const []),
        dob: json['dob'] == null ? null : DateTime.tryParse(json['dob'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_code': employeeCode,
        'full_name': fullName,
        'role': role.name,
        'status': active ? 'active' : 'suspended',
        'must_change_password': mustChangePassword,
        'email': email,
        'phone': phone,
        'section_id': sectionId,
        'team_id': teamId,
        'section_ids': sectionIds,
        'team_ids': teamIds,
        'dob': dob?.toIso8601String().substring(0, 10),
      };

  AppUser copyWith({bool? mustChangePassword}) => AppUser.fromJson({
        ...toJson(),
        if (mustChangePassword != null) 'must_change_password': mustChangePassword,
      });
}

/// Crew sign in with their employee code; officers with their email.
/// Must match `loginEmail()` in the admin-users Edge Function.
String loginEmailFor(String identifier) {
  final id = identifier.trim();
  if (id.contains('@')) return id.toLowerCase();
  return '${id.toLowerCase()}@${Env.crewLoginDomain}';
}

/// Password policy shared with Supabase Auth (8+ chars, letters and digits).
bool passwordMeetsPolicy(String password) =>
    password.length >= 8 &&
    RegExp(r'[A-Za-z]').hasMatch(password) &&
    RegExp(r'[0-9]').hasMatch(password);
