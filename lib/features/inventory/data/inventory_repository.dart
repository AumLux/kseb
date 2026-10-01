import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/format/ist.dart';
import '../../../core/outbox/outbox.dart';
import '../../../core/supabase/providers.dart';
import '../../../core/supabase/update_guard.dart';

num _n(Object? v) => (v as num?) ?? 0;

class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.reorderLevel,
    this.hsnCode,
    this.active = true,
  });

  final String id;
  final String code;
  final String name;
  final String category;
  final String unit;
  final num reorderLevel;
  final String? hsnCode;
  final bool active;

  factory CatalogItem.fromJson(Map<String, dynamic> j) => CatalogItem(
        id: j['id'] as String,
        code: j['code'] as String,
        name: j['name'] as String,
        category: j['category'] as String,
        unit: j['unit'] as String,
        reorderLevel: _n(j['reorder_level']),
        hsnCode: j['hsn_code'] as String?,
        active: j['active'] as bool? ?? true,
      );

  static const units = ['nos', 'm', 'km', 'kg', 'set', 'litre', 'box', 'roll', 'pair'];
}

class Store {
  const Store({required this.id, required this.sectionId, required this.name, this.active = true});

  final String id;
  final String sectionId;
  final String name;
  final bool active;

  factory Store.fromJson(Map<String, dynamic> j) => Store(
        id: j['id'] as String,
        sectionId: j['section_id'] as String,
        name: j['name'] as String,
        active: j['active'] as bool? ?? true,
      );
}

/// A row of `stock_overview`.
class StockLine {
  const StockLine({
    required this.materialId,
    required this.materialCode,
    required this.materialName,
    required this.category,
    required this.unit,
    required this.storeId,
    required this.storeName,
    required this.onHand,
    required this.reorderLevel,
    required this.lowStock,
  });

  final String materialId;
  final String materialCode;
  final String materialName;
  final String category;
  final String unit;
  final String storeId;
  final String storeName;
  final num onHand;
  final num reorderLevel;
  final bool lowStock;

  factory StockLine.fromJson(Map<String, dynamic> j) => StockLine(
        materialId: j['material_id'] as String,
        materialCode: j['material_code'] as String,
        materialName: j['material_name'] as String,
        category: j['category'] as String,
        unit: j['unit'] as String,
        storeId: j['store_id'] as String,
        storeName: j['store_name'] as String,
        onHand: _n(j['on_hand']),
        reorderLevel: _n(j['reorder_level']),
        lowStock: j['low_stock'] as bool? ?? false,
      );
}

enum MaterialRequestType { issue, ret, receipt }

extension MaterialRequestTypeDb on MaterialRequestType {
  String get db => this == MaterialRequestType.ret ? 'return' : name;
  static MaterialRequestType parse(String v) => v == 'return' ? MaterialRequestType.ret : MaterialRequestType.values.byName(v);
}

enum Priority { low, medium, high, critical }

class MaterialRequest {
  const MaterialRequest({
    required this.id,
    required this.code,
    required this.type,
    required this.materialId,
    required this.materialName,
    required this.unit,
    required this.storeId,
    required this.storeName,
    required this.quantity,
    required this.purpose,
    required this.priority,
    required this.status,
    required this.requestedBy,
    required this.createdAt,
    this.unitPrice,
    this.supplier,
    this.invoiceRef,
    this.worksheetId,
    this.requiredBy,
    this.decidedBy,
    this.decidedAt,
    this.decisionNote,
  });

  final String id;
  final String code;
  final MaterialRequestType type;
  final String materialId;
  final String materialName;
  final String unit;
  final String storeId;
  final String storeName;
  final num quantity;
  final num? unitPrice;
  final String? supplier;
  final String? invoiceRef;
  final String? worksheetId;
  final String purpose;
  final Priority priority;
  final DateTime? requiredBy;
  final String status;
  final String requestedBy;
  final String? decidedBy;
  final DateTime? decidedAt;
  final String? decisionNote;
  final DateTime createdAt;

  factory MaterialRequest.fromJson(Map<String, dynamic> j) => MaterialRequest(
        id: j['id'] as String,
        code: j['code'] as String,
        type: MaterialRequestTypeDb.parse(j['request_type'] as String),
        materialId: j['material_id'] as String,
        materialName: (j['material'] as Map?)?['name'] as String? ?? '',
        unit: (j['material'] as Map?)?['unit'] as String? ?? '',
        storeId: j['store_id'] as String,
        storeName: (j['store'] as Map?)?['name'] as String? ?? '',
        quantity: _n(j['quantity']),
        unitPrice: j['unit_price'] as num?,
        supplier: j['supplier'] as String?,
        invoiceRef: j['invoice_ref'] as String?,
        worksheetId: j['worksheet_id'] as String?,
        purpose: j['purpose'] as String,
        priority: Priority.values.byName(j['priority'] as String? ?? 'medium'),
        requiredBy: j['required_by'] == null ? null : DateTime.parse(j['required_by'] as String),
        status: j['status'] as String,
        requestedBy: j['requested_by'] as String,
        decidedBy: j['decided_by'] as String?,
        decidedAt: j['decided_at'] == null ? null : DateTime.parse(j['decided_at'] as String).toLocal(),
        decisionNote: j['decision_note'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
      );
}

class MaterialRequestDraft {
  const MaterialRequestDraft({
    required this.type,
    required this.materialId,
    required this.storeId,
    required this.quantity,
    required this.purpose,
    this.priority = Priority.medium,
    this.unitPrice,
    this.supplier,
    this.invoiceRef,
    this.worksheetId,
    this.requiredBy,
  });

  final MaterialRequestType type;
  final String materialId;
  final String storeId;
  final num quantity;
  final String purpose;
  final Priority priority;
  final num? unitPrice;
  final String? supplier;
  final String? invoiceRef;
  final String? worksheetId;
  final DateTime? requiredBy;

  Map<String, dynamic> toJson(String id) {
    String? blank(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
    final receipt = type == MaterialRequestType.receipt;
    return {
      'id': id,
      'request_type': type.db,
      'material_id': materialId,
      'store_id': storeId,
      'quantity': quantity,
      'unit_price': receipt ? unitPrice : null,
      'supplier': receipt ? blank(supplier) : null,
      'invoice_ref': receipt ? blank(invoiceRef) : null,
      'worksheet_id': worksheetId,
      'purpose': purpose.trim(),
      'priority': priority.name,
      'required_by': requiredBy == null ? null : Ist.iso(requiredBy!),
    };
  }
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.materialId,
    required this.storeId,
    required this.qtyDelta,
    required this.txnType,
    required this.createdAt,
    this.note,
    this.unitPrice,
  });

  final int id;
  final String materialId;
  final String storeId;
  final num qtyDelta;
  final String txnType;
  final DateTime createdAt;
  final String? note;
  final num? unitPrice;

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        id: j['id'] as int,
        materialId: j['material_id'] as String,
        storeId: j['store_id'] as String,
        qtyDelta: _n(j['qty_delta']),
        txnType: j['txn_type'] as String,
        createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
        note: j['note'] as String?,
        unitPrice: j['unit_price'] as num?,
      );
}

class WorksheetUsage {
  const WorksheetUsage({
    required this.materialName,
    required this.unit,
    required this.issued,
    required this.returned,
    required this.netConsumed,
  });

  final String materialName;
  final String unit;
  final num issued;
  final num returned;
  final num netConsumed;

  factory WorksheetUsage.fromJson(Map<String, dynamic> j) => WorksheetUsage(
        materialName: j['material_name'] as String,
        unit: j['unit'] as String,
        issued: _n(j['issued']),
        returned: _n(j['returned']),
        netConsumed: _n(j['net_consumed']),
      );
}

final inventoryRepositoryProvider =
    Provider<InventoryRepository>((ref) => InventoryRepository(ref.watch(supabaseClientProvider), ref));

final catalogProvider =
    FutureProvider.autoDispose<List<CatalogItem>>((ref) => ref.watch(inventoryRepositoryProvider).catalog());
final storesProvider = FutureProvider.autoDispose<List<Store>>((ref) => ref.watch(inventoryRepositoryProvider).stores());
final stockProvider = FutureProvider.autoDispose<List<StockLine>>((ref) => ref.watch(inventoryRepositoryProvider).stock());
final materialRequestsProvider =
    FutureProvider.autoDispose<List<MaterialRequest>>((ref) => ref.watch(inventoryRepositoryProvider).requests());
final materialRequestProvider = FutureProvider.autoDispose.family<MaterialRequest, String>(
    (ref, id) => ref.watch(inventoryRepositoryProvider).request(id));
final ledgerProvider = FutureProvider.autoDispose.family<List<LedgerEntry>, ({String materialId, String storeId})>(
    (ref, k) => ref.watch(inventoryRepositoryProvider).ledger(k.materialId, k.storeId));
final worksheetUsageProvider = FutureProvider.autoDispose.family<List<WorksheetUsage>, String>(
    (ref, id) => ref.watch(inventoryRepositoryProvider).usage(id));

class InventoryRepository {
  InventoryRepository(this._client, this._ref);

  final SupabaseClient _client;
  final Ref _ref;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  static const _requestSelect = '*, material:material_catalog(name, unit), store:stores(name)';

  Future<List<CatalogItem>> catalog() => _guard(() async =>
      (await _client.from('material_catalog').select().order('name')).map(CatalogItem.fromJson).toList());

  Future<List<Store>> stores() =>
      _guard(() async => (await _client.from('stores').select().order('name')).map(Store.fromJson).toList());

  Future<List<StockLine>> stock() => _guard(() async =>
      (await _client.from('stock_overview').select().order('material_name')).map(StockLine.fromJson).toList());

  Future<List<MaterialRequest>> requests() => _guard(() async => (await _client
          .from('material_requests')
          .select(_requestSelect)
          .order('created_at', ascending: false)
          .limit(200))
      .map(MaterialRequest.fromJson)
      .toList());

  Future<MaterialRequest> request(String id) => _guard(() async =>
      MaterialRequest.fromJson(await _client.from('material_requests').select(_requestSelect).eq('id', id).single()));

  Future<List<LedgerEntry>> ledger(String materialId, String storeId) => _guard(() async => (await _client
          .from('stock_ledger')
          .select()
          .eq('material_id', materialId)
          .eq('store_id', storeId)
          .order('created_at', ascending: false)
          .limit(100))
      .map(LedgerEntry.fromJson)
      .toList());

  Future<List<LedgerEntry>> ledgerForPeriod(DateTime from, DateTime to, {String? storeId}) => _guard(() async {
        var q = _client
            .from('stock_ledger')
            .select()
            .gte('created_at', from.toUtc().toIso8601String())
            .lt('created_at', to.toUtc().toIso8601String());
        if (storeId != null) q = q.eq('store_id', storeId);
        return (await q.order('created_at')).map(LedgerEntry.fromJson).toList();
      });

  Future<List<WorksheetUsage>> usage(String worksheetId) => _guard(() async => (await _client
          .from('worksheet_material_usage')
          .select()
          .eq('worksheet_id', worksheetId)
          .order('material_name'))
      .map(WorksheetUsage.fromJson)
      .toList());

  /// Queued through the outbox (requests can be raised from site). Returns
  /// true when it reached the server now.
  Future<bool> submit(MaterialRequestDraft draft, {required String label}) async {
    final id = const Uuid().v4();
    final outbox = _ref.read(outboxProvider.notifier);
    await outbox.enqueue(OutboxOp(
      id: 'mr-$id',
      kind: OutboxKind.insert,
      name: 'material_requests',
      label: label,
      createdAt: DateTime.now().toUtc(),
      payload: draft.toJson(id),
    ));
    await outbox.process();
    final op = _ref.read(outboxProvider).ops.where((o) => o.id == 'mr-$id').firstOrNull;
    if (op?.failed ?? false) {
      await outbox.discard(op!.id);
      throw AppFailure('rejected', op.lastError ?? 'Rejected');
    }
    return op == null;
  }

  Future<void> decide(String id, bool approve, {String? note}) => _guard(() =>
      _client.rpc('decide_material_request', params: {'p_id': id, 'p_approve': approve, 'p_note': note}));

  Future<void> cancel(String id) => _guard(() => _client.rpc('cancel_material_request', params: {'p_id': id}));

  Future<void> adjust(String materialId, String storeId, num delta, String reason, {bool scrap = false}) =>
      _guard(() => _client.rpc('adjust_stock', params: {
            'p_material_id': materialId,
            'p_store_id': storeId,
            'p_qty_delta': delta,
            'p_reason': reason,
            'p_is_scrap': scrap,
          }));

  Future<void> transfer(String materialId, String fromStore, String toStore, num qty, {String? note}) =>
      _guard(() => _client.rpc('transfer_stock', params: {
            'p_material_id': materialId,
            'p_from_store': fromStore,
            'p_to_store': toStore,
            'p_qty': qty,
            'p_note': note,
          }));

  Future<void> saveMaterial({
    String? id,
    required String code,
    required String name,
    required String category,
    required String unit,
    required num reorderLevel,
    String? hsn,
  }) =>
      _guard(() async {
        final row = {
          'name': name.trim(),
          'category': category.trim(),
          'unit': unit,
          'hsn_code': (hsn?.trim().isEmpty ?? true) ? null : hsn!.trim(),
          'reorder_level': reorderLevel,
        };
        if (id == null) {
          await _client.from('material_catalog').insert({'code': code.trim().toUpperCase(), ...row});
        } else {
          await updateOrFail(_client, 'material_catalog', row, id);
        }
      });

  Future<void> addStore(String sectionId, String name) =>
      _guard(() => _client.from('stores').insert({'section_id': sectionId, 'name': name.trim()}));
}

/// Stock on hand for a material in a store (0 when never stocked).
num onHandFor(List<StockLine> stock, String materialId, String storeId) =>
    stock.where((s) => s.materialId == materialId && s.storeId == storeId).firstOrNull?.onHand ?? 0;
