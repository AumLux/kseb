import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../core/errors/app_failure.dart';
import '../../core/format/ist.dart';
import '../../core/outbox/outbox.dart';
import '../../core/supabase/providers.dart';
import '../../core/supabase/update_guard.dart';

// ── Poles (Polevar) ─────────────────────────────────────────────────────

const poleTypes = ['psc', 'rcc', 'steel_tubular', 'rail', 'wooden', 'other'];
const poleConditions = ['good', 'leaning', 'damaged', 'replaced'];

class PoleRecord {
  const PoleRecord({
    required this.id,
    required this.poleNumber,
    required this.sectionId,
    required this.feederName,
    required this.poleType,
    required this.condition,
    required this.surveyedAt,
    required this.surveyedBy,
    this.transformerRef,
    this.heightM,
    this.lat,
    this.lng,
    this.landmark,
    this.remarks,
  });

  final String id;
  final String poleNumber;
  final String sectionId;
  final String feederName;
  final String? transformerRef;
  final String poleType;
  final num? heightM;
  final double? lat;
  final double? lng;
  final String? landmark;
  final String condition;
  final String? remarks;
  final DateTime surveyedAt;
  final String surveyedBy;

  factory PoleRecord.fromJson(Map<String, dynamic> j) => PoleRecord(
        id: j['id'] as String,
        poleNumber: j['pole_number'] as String,
        sectionId: j['section_id'] as String,
        feederName: j['feeder_name'] as String,
        transformerRef: j['transformer_ref'] as String?,
        poleType: j['pole_type'] as String,
        heightM: j['height_m'] as num?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        landmark: j['landmark'] as String?,
        condition: j['condition'] as String,
        remarks: j['remarks'] as String?,
        surveyedAt: DateTime.parse(j['surveyed_at'] as String).toLocal(),
        surveyedBy: j['surveyed_by'] as String,
      );
}

// ── Assets ──────────────────────────────────────────────────────────────

const assetCategories = ['transformer', 'pole', 'conductor', 'meter', 'tool', 'vehicle', 'other'];
const assetConditions = ['new', 'good', 'fair', 'poor', 'unserviceable'];
const assetStatuses = ['in_store', 'deployed', 'under_repair', 'scrapped', 'lost'];

class Asset {
  const Asset({
    required this.id,
    required this.tag,
    required this.category,
    required this.name,
    required this.sectionId,
    required this.condition,
    required this.status,
    this.serialNo,
    this.make,
    this.rating,
    this.locationText,
    this.lat,
    this.lng,
    this.assignedTo,
    this.purchaseDate,
    this.purchaseValue,
    this.notes,
  });

  final String id;
  final String tag;
  final String category;
  final String name;
  final String sectionId;
  final String condition;
  final String status;
  final String? serialNo;
  final String? make;
  final String? rating;
  final String? locationText;
  final double? lat;
  final double? lng;
  final String? assignedTo;
  final DateTime? purchaseDate;
  final num? purchaseValue;
  final String? notes;

  bool get scrapped => status == 'scrapped';

  bool matches(String q) {
    if (q.isEmpty) return true;
    final s = q.toLowerCase();
    return tag.toLowerCase().contains(s) || name.toLowerCase().contains(s) || (serialNo?.toLowerCase().contains(s) ?? false);
  }

  factory Asset.fromJson(Map<String, dynamic> j) => Asset(
        id: j['id'] as String,
        tag: j['asset_tag'] as String,
        category: j['category'] as String,
        name: j['name'] as String,
        sectionId: j['section_id'] as String,
        condition: j['condition'] as String,
        status: j['status'] as String,
        serialNo: j['serial_no'] as String?,
        make: j['make'] as String?,
        rating: j['rating'] as String?,
        locationText: j['location_text'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        assignedTo: j['assigned_to'] as String?,
        purchaseDate: j['purchase_date'] == null ? null : DateTime.parse(j['purchase_date'] as String),
        purchaseValue: j['purchase_value'] as num?,
        notes: j['notes'] as String?,
      );
}

class AssetEvent {
  const AssetEvent({required this.type, required this.at, required this.actor, this.note, this.toSectionId, this.assignedTo, this.status, this.condition});

  final String type;
  final DateTime at;
  final String actor;
  final String? note;
  final String? toSectionId;
  final String? assignedTo;
  final String? status;
  final String? condition;

  factory AssetEvent.fromJson(Map<String, dynamic> j) => AssetEvent(
        type: j['event_type'] as String,
        at: DateTime.parse(j['created_at'] as String).toLocal(),
        actor: j['actor'] as String,
        note: j['note'] as String?,
        toSectionId: j['to_section_id'] as String?,
        assignedTo: j['assigned_to'] as String?,
        status: j['status'] as String?,
        condition: j['condition'] as String?,
      );
}

final registersRepositoryProvider =
    Provider<RegistersRepository>((ref) => RegistersRepository(ref.watch(supabaseClientProvider), ref));

final polesProvider = FutureProvider.autoDispose<List<PoleRecord>>((ref) => ref.watch(registersRepositoryProvider).poles());
final poleProvider =
    FutureProvider.autoDispose.family<PoleRecord, String>((ref, id) => ref.watch(registersRepositoryProvider).pole(id));
final assetsProvider = FutureProvider.autoDispose<List<Asset>>((ref) => ref.watch(registersRepositoryProvider).assets());
final assetProvider =
    FutureProvider.autoDispose.family<Asset, String>((ref, id) => ref.watch(registersRepositoryProvider).asset(id));
final assetEventsProvider = FutureProvider.autoDispose.family<List<AssetEvent>, String>(
    (ref, id) => ref.watch(registersRepositoryProvider).assetEvents(id));

/// Pole surveys captured offline and not yet on the server.
final pendingPolesProvider = Provider<List<OutboxOp>>((ref) => ref
    .watch(outboxProvider.select((s) => s.ops))
    .where((o) => o.kind == OutboxKind.insert && o.name == 'pole_records' && !o.failed)
    .toList());

class RegistersRepository {
  RegistersRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<List<PoleRecord>> poles() => _guard(() async =>
      (await _client.from('pole_records').select().order('surveyed_at', ascending: false).limit(500))
          .map(PoleRecord.fromJson)
          .toList());

  Future<PoleRecord> pole(String id) =>
      _guard(() async => PoleRecord.fromJson(await _client.from('pole_records').select().eq('id', id).single()));

  /// Survey entry, queued so it works without signal. Returns (id, synced).
  Future<(String, bool)> recordPole(Map<String, dynamic> fields) async {
    final id = const Uuid().v4();
    final outbox = _ref.read(outboxProvider.notifier);
    await outbox.enqueue(OutboxOp(
      id: 'pole-$id',
      kind: OutboxKind.insert,
      name: 'pole_records',
      label: 'Pole ${fields['pole_number']}',
      createdAt: DateTime.now().toUtc(),
      payload: {'id': id, ...fields, 'surveyed_at': DateTime.now().toUtc().toIso8601String()},
    ));
    await outbox.process();
    final op = _ref.read(outboxProvider).ops.where((o) => o.id == 'pole-$id').firstOrNull;
    if (op?.failed ?? false) {
      await outbox.discard(op!.id);
      throw AppFailure(op.lastError?.contains('already exists') ?? false ? 'duplicate' : 'rejected',
          op.lastError ?? 'Rejected');
    }
    return (id, op == null);
  }

  Future<void> updatePole(String id, Map<String, dynamic> fields) =>
      _guard(() => updateOrFail(_client, 'pole_records', fields, id));

  Future<List<Asset>> assets() => _guard(
      () async => (await _client.from('assets').select().order('asset_tag')).map(Asset.fromJson).toList());

  Future<Asset> asset(String id) =>
      _guard(() async => Asset.fromJson(await _client.from('assets').select().eq('id', id).single()));

  Future<List<AssetEvent>> assetEvents(String id) => _guard(() async => (await _client
          .from('asset_events')
          .select()
          .eq('asset_id', id)
          .order('created_at', ascending: false))
      .map(AssetEvent.fromJson)
      .toList());

  Future<String> registerAsset(Map<String, dynamic> fields) => _guard(() async {
        final id = const Uuid().v4();
        await _client.from('assets').insert({'id': id, ...fields});
        return id;
      });

  Future<void> updateAsset(String id, Map<String, dynamic> fields) =>
      _guard(() => updateOrFail(_client, 'assets', fields, id));

  Future<void> recordEvent(
    String assetId,
    String eventType, {
    String? note,
    String? toSectionId,
    String? assignedTo,
    String? status,
    String? condition,
  }) =>
      _guard(() => _client.rpc('record_asset_event', params: {
            'p_asset_id': assetId,
            'p_event_type': eventType,
            'p_note': note,
            'p_to_section_id': toSectionId,
            'p_assigned_to': assignedTo,
            'p_status': status,
            'p_condition': condition,
          }));

  static String? isoOrNull(DateTime? d) => d == null ? null : Ist.iso(d);
}
