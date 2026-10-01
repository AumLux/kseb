import 'package:excel/excel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/errors/app_failure.dart';
import 'package:kseb/core/outbox/outbox.dart';
import 'package:kseb/core/supabase/providers.dart';
import 'package:kseb/features/inventory/data/inventory_repository.dart';
import 'package:kseb/features/inventory/presentation/stock_register_export.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _Store implements OutboxStore {
  List<OutboxOp> ops = [];
  @override
  Future<List<OutboxOp>> load() async => ops;
  @override
  Future<void> save(List<OutboxOp> o) async => ops = List.of(o);
}

class _Executor implements OutboxExecutor {
  Object? error;
  final calls = <OutboxOp>[];
  @override
  Future<void> execute(OutboxOp op) async {
    if (error != null) throw error!;
    calls.add(op);
  }
}

ProviderContainer _container(_Executor exec) {
  final c = ProviderContainer(overrides: [
    supabaseClientProvider.overrideWithValue(SupabaseClient('http://localhost:54321', 'k',
        authOptions: const AuthClientOptions(autoRefreshToken: false))),
    outboxStoreProvider.overrideWithValue(_Store()),
    outboxExecutorProvider.overrideWithValue(exec),
    onlineProvider.overrideWith((ref) => Stream.value(true)),
  ]);
  c.listen(outboxProvider, (_, __) {});
  return c;
}

void main() {
  group('MaterialRequestDraft', () {
    test('an issue never carries receipt-only fields', () {
      final json = const MaterialRequestDraft(
        type: MaterialRequestType.issue,
        materialId: 'm',
        storeId: 's',
        quantity: 30,
        purpose: ' Re-stringing span 14-15 ',
        unitPrice: 45,
        supplier: 'X',
        worksheetId: 'w',
      ).toJson('id1');
      expect(json['request_type'], 'issue');
      expect(json['unit_price'], isNull);
      expect(json['supplier'], isNull);
      expect(json['worksheet_id'], 'w');
      expect(json['purpose'], 'Re-stringing span 14-15');
    });

    test('returns are stored as "return" and receipts keep pricing', () {
      expect(MaterialRequestType.ret.db, 'return');
      expect(MaterialRequestTypeDb.parse('return'), MaterialRequestType.ret);
      final json = const MaterialRequestDraft(
        type: MaterialRequestType.receipt,
        materialId: 'm',
        storeId: 's',
        quantity: 100,
        purpose: 'PO 77',
        unitPrice: 45.5,
        supplier: ' Kerala Cables ',
        invoiceRef: '',
      ).toJson('id2');
      expect(json['unit_price'], 45.5);
      expect(json['supplier'], 'Kerala Cables');
      expect(json['invoice_ref'], isNull);
    });
  });

  test('on-hand lookup defaults to zero for never-stocked items', () {
    const line = StockLine(
      materialId: 'm1', materialCode: 'C', materialName: 'N', category: 'c', unit: 'm',
      storeId: 's1', storeName: 'S', onHand: 70, reorderLevel: 50, lowStock: false,
    );
    expect(onHandFor([line], 'm1', 's1'), 70);
    expect(onHandFor([line], 'm1', 's2'), 0);
  });

  test('stock register lists ins and outs in separate columns', () {
    final bytes = buildStockRegisterXlsx(
      entries: [
        LedgerEntry(id: 1, materialId: 'm1', storeId: 's1', qtyDelta: 100, txnType: 'receipt', createdAt: DateTime(2026, 10, 1, 10), unitPrice: 45.5),
        LedgerEntry(id: 2, materialId: 'm1', storeId: 's1', qtyDelta: -30, txnType: 'issue', createdAt: DateTime(2026, 10, 2, 9), note: 'MR-2026-00002'),
      ],
      materials: {
        'm1': const CatalogItem(id: 'm1', code: 'ACSR-RAB', name: 'ACSR Rabbit', category: 'Conductor', unit: 'm', reorderLevel: 50),
      },
      stores: {'s1': const Store(id: 's1', sectionId: 'x', name: 'Kaloor store')},
      title: 'Stock register — October 2026',
    );
    final rows = Excel.decodeBytes(bytes).tables['Register']!.rows;
    expect(rows[2][3]?.value.toString(), 'ACSR Rabbit');
    expect(num.parse(rows[2][6]!.value.toString()), 100);
    expect(num.parse(rows[3][7]!.value.toString()), 30);
    expect(rows[3][9]?.value.toString(), 'MR-2026-00002');
  });

  group('submit (outbox)', () {
    const draft = MaterialRequestDraft(
      type: MaterialRequestType.issue, materialId: 'm', storeId: 's', quantity: 5, purpose: 'DP-14');

    test('online → sent', () async {
      final exec = _Executor();
      final c = _container(exec);
      addTearDown(c.dispose);
      expect(await c.read(inventoryRepositoryProvider).submit(draft, label: 'Issue'), isTrue);
      expect(exec.calls.single.name, 'material_requests');
    });

    test('offline → kept for later', () async {
      final exec = _Executor()..error = AppFailure.network;
      final c = _container(exec);
      addTearDown(c.dispose);
      expect(await c.read(inventoryRepositoryProvider).submit(draft, label: 'Issue'), isFalse);
      expect(c.read(outboxProvider).ops, hasLength(1));
    });

    test('rejected → error and nothing left queued', () async {
      final exec = _Executor()
        ..error = const PostgrestException(message: 'new row violates row-level security policy', code: '42501');
      final c = _container(exec);
      addTearDown(c.dispose);
      await expectLater(c.read(inventoryRepositoryProvider).submit(draft, label: 'Issue'), throwsA(isA<AppFailure>()));
      expect(c.read(outboxProvider).ops, isEmpty);
    });
  });
}
