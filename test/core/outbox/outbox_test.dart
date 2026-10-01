import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kseb/core/connectivity/connectivity_provider.dart';
import 'package:kseb/core/errors/app_failure.dart';
import 'package:kseb/core/outbox/outbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MemoryStore implements OutboxStore {
  List<OutboxOp> saved = [];
  @override
  Future<List<OutboxOp>> load() async => List.of(saved);
  @override
  Future<void> save(List<OutboxOp> ops) async => saved = List.of(ops);
}

/// Fails ops according to [behaviour] keyed by op id.
class _ScriptedExecutor implements OutboxExecutor {
  final executed = <String>[];
  final behaviour = <String, Object>{};
  @override
  Future<void> execute(OutboxOp op) async {
    final error = behaviour[op.id];
    if (error != null) throw error;
    executed.add(op.id);
  }
}

OutboxOp _op(String id) => OutboxOp(
      id: id,
      kind: OutboxKind.rpc,
      name: 'check_in',
      label: 'Check-in $id',
      createdAt: DateTime(2026, 10, 1, 9),
      payload: {'p_request_id': id},
    );

void main() {
  late _MemoryStore store;
  late _ScriptedExecutor executor;
  late ProviderContainer container;

  setUp(() {
    store = _MemoryStore();
    executor = _ScriptedExecutor();
    container = ProviderContainer(overrides: [
      outboxStoreProvider.overrideWithValue(store),
      outboxExecutorProvider.overrideWithValue(executor),
      onlineProvider.overrideWith((ref) => Stream.value(false)),
    ]);
    container.listen(outboxProvider, (_, __) {}); // the app keeps it alive
  });

  tearDown(() => container.dispose());

  OutboxController controller() => container.read(outboxProvider.notifier);

  test('successful ops replay in order and leave the queue', () async {
    await controller().enqueue(_op('a'));
    await controller().enqueue(_op('b'));
    await controller().process();
    expect(executor.executed, ['a', 'b']);
    expect(container.read(outboxProvider).ops, isEmpty);
    expect(store.saved, isEmpty);
  });

  test('a network failure stops the queue and keeps everything for later', () async {
    executor.behaviour['a'] = AppFailure.network;
    await controller().enqueue(_op('a'));
    await controller().enqueue(_op('b'));
    await controller().process();
    final ops = container.read(outboxProvider).ops;
    expect(executor.executed, isEmpty, reason: 'b must not overtake a');
    expect(ops.map((o) => o.id), ['a', 'b']);
    expect(ops.first.failed, isFalse);
    expect(ops.first.attempts, greaterThanOrEqualTo(1));
  });

  test('a server rejection is marked failed and the rest continue', () async {
    executor.behaviour['a'] = const PostgrestException(
        message: 'You have already checked in today.', code: 'P0001', hint: 'already_checked_in');
    await controller().enqueue(_op('a'));
    await controller().enqueue(_op('b'));
    await controller().process();
    final state = container.read(outboxProvider);
    expect(executor.executed, ['b']);
    expect(state.ops.single.id, 'a');
    expect(state.ops.single.failed, isTrue);
    expect(state.ops.single.lastError, contains('already checked in'));
    expect(state.failed, 1);
    expect(state.pending, 0);
  });

  test('retry re-runs a failed op; discard drops it', () async {
    executor.behaviour['a'] = const PostgrestException(message: 'nope', code: 'P0001', hint: 'x');
    await controller().enqueue(_op('a'));
    await controller().process();
    executor.behaviour.remove('a');
    await controller().retry('a');
    expect(executor.executed, ['a']);

    executor.behaviour['b'] = const PostgrestException(message: 'nope', code: 'P0001', hint: 'x');
    await controller().enqueue(_op('b'));
    await controller().process();
    await controller().discard('b');
    expect(container.read(outboxProvider).ops, isEmpty);
  });

  test('enqueueing the same id twice is a no-op (idempotent capture)', () async {
    executor.behaviour['a'] = AppFailure.network;
    await controller().enqueue(_op('a'));
    await controller().enqueue(_op('a'));
    expect(container.read(outboxProvider).ops, hasLength(1));
  });

  test('the queue survives a restart via the store', () async {
    executor.behaviour['a'] = AppFailure.network;
    await controller().enqueue(_op('a'));
    container.dispose();

    final restarted = ProviderContainer(overrides: [
      outboxStoreProvider.overrideWithValue(store),
      outboxExecutorProvider.overrideWithValue(executor),
      onlineProvider.overrideWith((ref) => Stream.value(false)),
    ]);
    addTearDown(restarted.dispose);
    restarted.listen(outboxProvider, (_, __) {});
    executor.behaviour.remove('a');
    await restarted.read(outboxProvider.notifier).process();
    expect(executor.executed, ['a']);
    container = ProviderContainer(); // keep tearDown happy
  });

  test('PrefsOutboxStore round-trips ops as JSON', () async {
    SharedPreferences.setMockInitialValues({});
    final prefsStore = PrefsOutboxStore(await SharedPreferences.getInstance());
    await prefsStore.save([_op('a').copyWith(attempts: 2, lastError: 'offline')]);
    final loaded = await prefsStore.load();
    expect(loaded.single.id, 'a');
    expect(loaded.single.attempts, 2);
    expect(loaded.single.payload, {'p_request_id': 'a'});
  });
}
