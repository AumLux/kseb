import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/errors/app_failure.dart';
import 'package:kseb/core/outbox/outbox.dart';
import 'package:kseb/core/supabase/providers.dart';
import 'package:kseb/features/registers/registers_repository.dart';
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
    supabaseClientProvider.overrideWithValue(
        SupabaseClient('http://localhost:54321', 'k', authOptions: const AuthClientOptions(autoRefreshToken: false))),
    outboxStoreProvider.overrideWithValue(_Store()),
    outboxExecutorProvider.overrideWithValue(exec),
    onlineProvider.overrideWith((ref) => Stream.value(true)),
  ]);
  c.listen(outboxProvider, (_, __) {});
  return c;
}

final _fields = {
  'pole_number': 'KLR/F3/114',
  'feeder_name': 'Kaloor F3',
  'pole_type': 'psc',
  'condition': 'leaning',
  'section_id': 's1',
  'lat': 9.99,
  'lng': 76.3,
};

void main() {
  test('pole and asset rows parse from the API', () {
    final pole = PoleRecord.fromJson({
      'id': 'p1', 'pole_number': 'KLR/F3/114', 'section_id': 's1', 'feeder_name': 'Kaloor F3',
      'pole_type': 'psc', 'condition': 'leaning', 'height_m': 9, 'lat': 9.99, 'lng': 76.3,
      'surveyed_at': '2026-10-01T04:30:00Z', 'surveyed_by': 'u1',
    });
    expect(pole.heightM, 9);
    expect(pole.surveyedBy, 'u1');
    final asset = Asset.fromJson({
      'id': 'a1', 'asset_tag': 'TR-EKM-0042', 'category': 'transformer', 'name': '100 kVA DT',
      'section_id': 's1', 'condition': 'good', 'status': 'deployed', 'serial_no': 'SN-77812',
    });
    expect(asset.matches('0042'), isTrue);
    expect(asset.matches('sn-778'), isTrue);
    expect(asset.matches('meter'), isFalse);
    expect(asset.scrapped, isFalse);
  });

  test('a pole survey is queued with a client id and survey time', () async {
    final exec = _Executor()..error = AppFailure.network;
    final c = _container(exec);
    addTearDown(c.dispose);
    final (id, synced) = await c.read(registersRepositoryProvider).recordPole(_fields);
    expect(synced, isFalse);
    final op = c.read(pendingPolesProvider).single;
    expect(op.payload['id'], id);
    expect(op.payload['surveyed_at'], isNotNull);
    expect(op.label, 'Pole KLR/F3/114');
  });

  test('a duplicate pole number is reported as such and not left queued', () async {
    final exec = _Executor()
      ..error = const PostgrestException(message: 'duplicate key value violates unique constraint', code: '23505');
    final c = _container(exec);
    addTearDown(c.dispose);
    await expectLater(
      c.read(registersRepositoryProvider).recordPole(_fields),
      throwsA(isA<AppFailure>().having((f) => f.code, 'code', 'duplicate')),
    );
    expect(c.read(outboxProvider).ops, isEmpty);
  });
}
