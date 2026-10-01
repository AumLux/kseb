import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/format/ist.dart';
import '../../../core/outbox/outbox.dart';
import '../../../core/supabase/providers.dart';
import '../../auth/application/session_controller.dart';

enum WorkType { project, maintenance, calamity }

enum WorksheetStatus { draft, submitted, approved, rejected, inProgress, completed, cancelled }

extension WorksheetStatusDb on WorksheetStatus {
  String get db => this == WorksheetStatus.inProgress ? 'in_progress' : name;
  static WorksheetStatus parse(String v) =>
      v == 'in_progress' ? WorksheetStatus.inProgress : WorksheetStatus.values.byName(v);
}

DateTime? _ts(Object? v) => v == null ? null : DateTime.parse(v as String).toLocal();

class Worksheet {
  const Worksheet({
    required this.id,
    required this.code,
    required this.workType,
    required this.title,
    required this.sectionId,
    required this.locationText,
    required this.status,
    required this.requestedBy,
    required this.createdAt,
    this.sectionName,
    this.lat,
    this.lng,
    this.permitBookNo,
    this.description,
    this.plannedDate,
    this.decidedBy,
    this.decisionNote,
    this.submittedAt,
    this.startedAt,
    this.completedAt,
    this.completionNote,
  });

  final String id;
  final String code;
  final WorkType workType;
  final String title;
  final String sectionId;
  final String? sectionName;
  final String locationText;
  final double? lat;
  final double? lng;
  final String? permitBookNo;
  final String? description;
  final DateTime? plannedDate;
  final WorksheetStatus status;
  final String requestedBy;
  final String? decidedBy;
  final String? decisionNote;
  final DateTime createdAt;
  final DateTime? submittedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? completionNote;

  bool get editable => status == WorksheetStatus.draft || status == WorksheetStatus.rejected;
  bool get closed => status == WorksheetStatus.completed || status == WorksheetStatus.cancelled;

  factory Worksheet.fromJson(Map<String, dynamic> j) => Worksheet(
        id: j['id'] as String,
        code: j['code'] as String,
        workType: WorkType.values.byName(j['work_type'] as String),
        title: j['title'] as String,
        sectionId: j['section_id'] as String,
        sectionName: (j['section'] as Map?)?['name'] as String?,
        locationText: j['location_text'] as String,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        permitBookNo: j['permit_book_no'] as String?,
        description: j['description'] as String?,
        plannedDate: j['planned_date'] == null ? null : DateTime.parse(j['planned_date'] as String),
        status: WorksheetStatusDb.parse(j['status'] as String),
        requestedBy: j['requested_by'] as String,
        decidedBy: j['decided_by'] as String?,
        decisionNote: j['decision_note'] as String?,
        createdAt: _ts(j['created_at'])!,
        submittedAt: _ts(j['submitted_at']),
        startedAt: _ts(j['started_at']),
        completedAt: _ts(j['completed_at']),
        completionNote: j['completion_note'] as String?,
      );
}

/// Input for create/edit.
class WorksheetDraft {
  const WorksheetDraft({
    required this.workType,
    required this.title,
    required this.sectionId,
    required this.locationText,
    this.lat,
    this.lng,
    this.permitBookNo,
    this.description,
    this.plannedDate,
  });

  final WorkType workType;
  final String title;
  final String sectionId;
  final String locationText;
  final double? lat;
  final double? lng;
  final String? permitBookNo;
  final String? description;
  final DateTime? plannedDate;

  Map<String, dynamic> toJson() {
    String? blank(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    return {
      'work_type': workType.name,
      'title': title.trim(),
      'section_id': sectionId,
      'location_text': locationText.trim(),
      'lat': lat,
      'lng': lng,
      'permit_book_no': blank(permitBookNo),
      'description': blank(description),
      'planned_date': plannedDate == null ? null : Ist.iso(plannedDate!),
    };
  }
}

class Permit {
  const Permit({
    required this.lineClearRef,
    required this.lineClearIssuedBy,
    required this.isolationPoints,
    required this.earthingDone,
    required this.testedDead,
    required this.toolboxTalkDone,
    required this.ppe,
    required this.signedAt,
  });

  final String lineClearRef;
  final String lineClearIssuedBy;
  final String isolationPoints;
  final bool earthingDone;
  final bool testedDead;
  final bool toolboxTalkDone;
  final List<String> ppe;
  final DateTime signedAt;

  static const requiredPpe = ['helmet', 'gloves', 'safety_belt'];
  static const allPpe = ['helmet', 'gloves', 'safety_belt', 'boots', 'insulated_tools', 'reflective_vest'];

  bool get complete =>
      earthingDone && testedDead && toolboxTalkDone && requiredPpe.every(ppe.contains);

  factory Permit.fromJson(Map<String, dynamic> j) => Permit(
        lineClearRef: j['line_clear_ref'] as String,
        lineClearIssuedBy: j['line_clear_issued_by'] as String,
        isolationPoints: j['isolation_points'] as String,
        earthingDone: j['earthing_done'] as bool,
        testedDead: j['tested_dead'] as bool,
        toolboxTalkDone: j['toolbox_talk_done'] as bool,
        ppe: List<String>.from(j['ppe_confirmed'] as List? ?? const []),
        signedAt: _ts(j['signed_at'])!,
      );
}

enum IncidentSeverity { nearMiss, minor, major, fatal }

extension IncidentSeverityDb on IncidentSeverity {
  String get db => this == IncidentSeverity.nearMiss ? 'near_miss' : name;
  static IncidentSeverity parse(String v) =>
      v == 'near_miss' ? IncidentSeverity.nearMiss : IncidentSeverity.values.byName(v);
}

class Incident {
  const Incident({
    required this.id,
    required this.code,
    required this.severity,
    required this.occurredAt,
    required this.description,
    required this.status,
  });

  final String id;
  final String code;
  final IncidentSeverity severity;
  final DateTime occurredAt;
  final String description;
  final String status;

  factory Incident.fromJson(Map<String, dynamic> j) => Incident(
        id: j['id'] as String,
        code: j['code'] as String,
        severity: IncidentSeverityDb.parse(j['severity'] as String),
        occurredAt: _ts(j['occurred_at'])!,
        description: j['description'] as String,
        status: j['status'] as String,
      );
}

/// Worksheet list scope.
enum WorksheetScope { mine, section }

final worksheetRepositoryProvider =
    Provider<WorksheetRepository>((ref) => WorksheetRepository(ref.watch(supabaseClientProvider), ref));

final worksheetsProvider = FutureProvider.autoDispose.family<List<Worksheet>, WorksheetScope>((ref, scope) {
  final me = ref.watch(currentUserProvider);
  if (me == null) return const [];
  return ref.watch(worksheetRepositoryProvider).list(mineOnly: scope == WorksheetScope.mine ? me.id : null);
});

final worksheetProvider = FutureProvider.autoDispose.family<Worksheet, String>(
    (ref, id) => ref.watch(worksheetRepositoryProvider).get(id));

final worksheetCrewProvider = FutureProvider.autoDispose.family<List<String>, String>(
    (ref, id) => ref.watch(worksheetRepositoryProvider).crew(id));

final permitProvider = FutureProvider.autoDispose.family<Permit?, String>(
    (ref, id) => ref.watch(worksheetRepositoryProvider).permit(id));

final worksheetIncidentsProvider = FutureProvider.autoDispose.family<List<Incident>, String>(
    (ref, id) => ref.watch(worksheetRepositoryProvider).incidents(id));

/// Worksheets created offline and not yet on the server.
final pendingWorksheetsProvider = Provider<List<OutboxOp>>((ref) => ref
    .watch(outboxProvider.select((s) => s.ops))
    .where((o) => o.kind == OutboxKind.insert && o.name == 'worksheets' && !o.failed)
    .toList());

class WorksheetRepository {
  WorksheetRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;
  static const _select = '*, section:sections(name)';

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<List<Worksheet>> list({String? mineOnly}) => _guard(() async {
        var q = _client.from('worksheets').select(_select);
        if (mineOnly != null) q = q.eq('requested_by', mineOnly);
        final rows = await q.order('created_at', ascending: false).limit(200);
        return rows.map(Worksheet.fromJson).toList();
      });

  Future<Worksheet> get(String id) => _guard(() async =>
      Worksheet.fromJson(await _client.from('worksheets').select(_select).eq('id', id).single()));

  /// Creates via the outbox (works offline). If [submit], the submit
  /// transition is queued right behind it. Returns (id, synced-now).
  Future<(String, bool)> create(WorksheetDraft draft, {required bool submit}) async {
    final id = const Uuid().v4();
    final outbox = _ref.read(outboxProvider.notifier);
    final now = DateTime.now().toUtc();
    await outbox.enqueue(OutboxOp(
      id: 'ws-$id',
      kind: OutboxKind.insert,
      name: 'worksheets',
      label: draft.title.trim(),
      createdAt: now,
      payload: {'id': id, ...draft.toJson()},
    ));
    if (submit) {
      await outbox.enqueue(OutboxOp(
        id: 'ws-submit-$id',
        kind: OutboxKind.rpc,
        name: 'transition_worksheet',
        label: 'Submit ${draft.title.trim()}',
        createdAt: now,
        payload: {'p_id': id, 'p_action': 'submit', 'p_note': null},
      ));
    }
    await outbox.process();
    final state = _ref.read(outboxProvider);
    final failed = state.ops.where((o) => o.id.endsWith(id) && o.failed).toList();
    if (failed.isNotEmpty) {
      // The submit can't succeed without its worksheet; clear both.
      for (final op in state.ops.where((o) => o.id.endsWith(id)).toList()) {
        await outbox.discard(op.id);
      }
      throw AppFailure('rejected', failed.first.lastError ?? 'Rejected');
    }
    return (id, !state.ops.any((o) => o.id.endsWith(id)));
  }

  Future<void> update(String id, WorksheetDraft draft) =>
      _guard(() => _client.from('worksheets').update(draft.toJson()).eq('id', id));

  Future<Worksheet> transition(String id, String action, {String? note}) => _guard(() async {
        final row = await _client.rpc('transition_worksheet', params: {'p_id': id, 'p_action': action, 'p_note': note});
        return Worksheet.fromJson(Map<String, dynamic>.from(row as Map));
      });

  Future<List<String>> crew(String id) => _guard(() async {
        final rows = await _client.from('worksheet_crew').select('user_id').eq('worksheet_id', id);
        return rows.map((r) => r['user_id'] as String).toList();
      });

  Future<void> setCrew(String id, List<String> userIds) =>
      _guard(() => _client.rpc('set_worksheet_crew', params: {'p_id': id, 'p_user_ids': userIds}));

  Future<Permit?> permit(String id) => _guard(() async {
        final row = await _client.from('permit_checklists').select().eq('worksheet_id', id).maybeSingle();
        return row == null ? null : Permit.fromJson(row);
      });

  Future<void> signPermit(String worksheetId, Permit p) => _guard(() => _client.rpc('sign_permit_checklist', params: {
        'p_worksheet_id': worksheetId,
        'p_line_clear_ref': p.lineClearRef,
        'p_line_clear_issued_by': p.lineClearIssuedBy,
        'p_isolation_points': p.isolationPoints,
        'p_earthing_done': p.earthingDone,
        'p_tested_dead': p.testedDead,
        'p_toolbox_talk_done': p.toolboxTalkDone,
        'p_ppe_confirmed': p.ppe,
      }));

  Future<List<Incident>> incidents(String worksheetId) => _guard(() async {
        final rows = await _client
            .from('incidents')
            .select()
            .eq('worksheet_id', worksheetId)
            .order('occurred_at', ascending: false);
        return rows.map(Incident.fromJson).toList();
      });

  /// Queued so it can be reported from the field without signal.
  Future<bool> reportIncident({
    required String sectionId,
    String? worksheetId,
    required IncidentSeverity severity,
    required DateTime occurredAt,
    required String description,
    String? injured,
    String? action,
  }) async {
    final id = const Uuid().v4();
    final outbox = _ref.read(outboxProvider.notifier);
    await outbox.enqueue(OutboxOp(
      id: 'inc-$id',
      kind: OutboxKind.insert,
      name: 'incidents',
      label: 'Incident report',
      createdAt: DateTime.now().toUtc(),
      payload: {
        'id': id,
        'worksheet_id': worksheetId,
        'section_id': sectionId,
        'severity': severity.db,
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'description': description.trim(),
        'injured_persons': (injured?.trim().isEmpty ?? true) ? null : injured!.trim(),
        'action_taken': (action?.trim().isEmpty ?? true) ? null : action!.trim(),
      },
    ));
    await outbox.process();
    final op = _ref.read(outboxProvider).ops.where((o) => o.id == 'inc-$id').firstOrNull;
    if (op?.failed ?? false) {
      await outbox.discard(op!.id);
      throw AppFailure('rejected', op.lastError ?? 'Rejected');
    }
    return op == null;
  }
}
