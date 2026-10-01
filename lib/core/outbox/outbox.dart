import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../connectivity/connectivity_provider.dart';
import '../errors/app_failure.dart';
import '../supabase/providers.dart';
import 'file_bytes.dart';

/// What an outbox entry does when replayed.
enum OutboxKind {
  /// `rpc(name, payload)`. The RPC must be idempotent (e.g. keyed on a
  /// client request id, as check_in/check_out are).
  rpc,

  /// Insert `payload` into table `name`; the row carries a client-generated
  /// `id`, so a replay is a no-op (ON CONFLICT DO NOTHING).
  insert,

  /// Upload the local file at `filePath` to storage object `name` in the
  /// `attachments` bucket. An "already exists" response counts as success.
  upload,
}

/// One queued operation. Plain data, persisted as JSON.
class OutboxOp {
  const OutboxOp({
    required this.id,
    required this.kind,
    required this.name,
    required this.label,
    required this.createdAt,
    this.payload = const {},
    this.filePath,
    this.mimeType,
    this.attempts = 0,
    this.lastError,
    this.failed = false,
  });

  final String id;
  final OutboxKind kind;
  final String name;

  /// Short human description shown in the sync screen ("Check-in 09:12").
  final String label;
  final DateTime createdAt;
  final Map<String, dynamic> payload;
  final String? filePath;
  final String? mimeType;
  final int attempts;
  final String? lastError;

  /// Permanently rejected by the server; needs the user's attention.
  final bool failed;

  OutboxOp copyWith({int? attempts, String? lastError, bool? failed}) => OutboxOp(
        id: id,
        kind: kind,
        name: name,
        label: label,
        createdAt: createdAt,
        payload: payload,
        filePath: filePath,
        mimeType: mimeType,
        attempts: attempts ?? this.attempts,
        lastError: lastError ?? this.lastError,
        failed: failed ?? this.failed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'name': name,
        'label': label,
        'createdAt': createdAt.toIso8601String(),
        'payload': payload,
        'filePath': filePath,
        'mimeType': mimeType,
        'attempts': attempts,
        'lastError': lastError,
        'failed': failed,
      };

  factory OutboxOp.fromJson(Map<String, dynamic> json) => OutboxOp(
        id: json['id'] as String,
        kind: OutboxKind.values.byName(json['kind'] as String),
        name: json['name'] as String,
        label: json['label'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
        filePath: json['filePath'] as String?,
        mimeType: json['mimeType'] as String?,
        attempts: json['attempts'] as int? ?? 0,
        lastError: json['lastError'] as String?,
        failed: json['failed'] as bool? ?? false,
      );
}

abstract interface class OutboxStore {
  Future<List<OutboxOp>> load();
  Future<void> save(List<OutboxOp> ops);
}

/// Persists the queue in SharedPreferences (localStorage on web).
class PrefsOutboxStore implements OutboxStore {
  PrefsOutboxStore(this._prefs);

  static const _key = 'aumlux.outbox.v1';
  final SharedPreferences _prefs;

  @override
  Future<List<OutboxOp>> load() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => OutboxOp.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } on FormatException {
      return [];
    }
  }

  @override
  Future<void> save(List<OutboxOp> ops) =>
      _prefs.setString(_key, jsonEncode(ops.map((o) => o.toJson()).toList()));
}

abstract interface class OutboxExecutor {
  Future<void> execute(OutboxOp op);
}

class SupabaseOutboxExecutor implements OutboxExecutor {
  SupabaseOutboxExecutor(this._client);

  final SupabaseClient _client;

  @override
  Future<void> execute(OutboxOp op) async {
    switch (op.kind) {
      case OutboxKind.rpc:
        await _client.rpc(op.name, params: op.payload);
      case OutboxKind.insert:
        await _client
            .from(op.name)
            .upsert(op.payload, onConflict: 'id', ignoreDuplicates: true);
      case OutboxKind.upload:
        final path = op.filePath;
        if (path == null) throw const AppFailure('invalid', 'Upload has no file.');
        final bytes = await readFileBytes(path);
        try {
          await _client.storage.from('attachments').uploadBinary(
                op.name,
                bytes,
                fileOptions: FileOptions(contentType: op.mimeType, upsert: false),
              );
        } on StorageException catch (e) {
          // Replay after a successful upload whose response was lost.
          if (e.statusCode == '409' || e.message.contains('already exists')) return;
          if (e.statusCode == '403' || e.statusCode == '400') {
            throw AppFailure('upload_rejected', e.message);
          }
          rethrow;
        }
        await deleteLocalFile(path);
    }
  }
}

class OutboxState {
  const OutboxState({this.ops = const [], this.processing = false, this.loaded = false});

  final List<OutboxOp> ops;
  final bool processing;
  final bool loaded;

  int get pending => ops.where((o) => !o.failed).length;
  int get failed => ops.where((o) => o.failed).length;

  OutboxState copyWith({List<OutboxOp>? ops, bool? processing, bool? loaded}) => OutboxState(
        ops: ops ?? this.ops,
        processing: processing ?? this.processing,
        loaded: loaded ?? this.loaded,
      );
}

final outboxStoreProvider = Provider<OutboxStore>(
  (ref) => throw UnimplementedError('Override outboxStoreProvider at startup'),
);

final outboxExecutorProvider = Provider<OutboxExecutor>(
  (ref) => SupabaseOutboxExecutor(ref.watch(supabaseClientProvider)),
);

final outboxProvider = NotifierProvider<OutboxController, OutboxState>(OutboxController.new);

/// FIFO replay queue. Order matters (a worksheet row before its attachment
/// row before the file upload), so processing is strictly sequential.
class OutboxController extends Notifier<OutboxState> {
  late OutboxStore _store;
  late OutboxExecutor _executor;
  Completer<void>? _loading;

  @override
  OutboxState build() {
    _store = ref.watch(outboxStoreProvider);
    _executor = ref.watch(outboxExecutorProvider);
    ref.listen<AsyncValue<bool>>(onlineProvider, (_, next) {
      if (next.value == true) unawaited(process());
    });
    _loading = Completer<void>();
    unawaited(_load());
    return const OutboxState();
  }

  Future<void> _load() async {
    final ops = await _store.load();
    if (!ref.mounted) return;
    state = state.copyWith(ops: ops, loaded: true);
    _loading?.complete();
    unawaited(process());
  }

  Future<void> _ready() async => _loading?.future;

  Future<void> enqueue(OutboxOp op) async {
    await _ready();
    if (!ref.mounted) return;
    if (state.ops.any((o) => o.id == op.id)) return;
    state = state.copyWith(ops: [...state.ops, op]);
    await _store.save(state.ops);
    unawaited(process());
  }

  Future<void>? _running;

  /// Replays pending entries in order. Stops at the first transient failure
  /// (connectivity is probably gone); permanent rejections are marked failed
  /// and processing continues with the next entry. Concurrent callers share
  /// the in-flight run, which also picks up entries enqueued meanwhile.
  Future<void> process() async {
    await _ready();
    if (!ref.mounted) return;
    return _running ??= _drain().whenComplete(() => _running = null);
  }

  Future<void> _drain() async {
    state = state.copyWith(processing: true);
    final tried = <String>{};
    try {
      while (true) {
        final op = state.ops.where((o) => !o.failed && !tried.contains(o.id)).firstOrNull;
        if (op == null) break;
        tried.add(op.id);
        try {
          await _executor.execute(op);
          if (!ref.mounted) return;
          state = state.copyWith(ops: state.ops.where((o) => o.id != op.id).toList());
          await _store.save(state.ops);
        } catch (e) {
          if (!ref.mounted) return;
          final failure = AppFailure.from(e);
          final updated = op.copyWith(
            attempts: op.attempts + 1,
            lastError: failure.message,
            failed: failure.isPermanent,
          );
          state = state.copyWith(
              ops: state.ops.map((o) => o.id == op.id ? updated : o).toList());
          await _store.save(state.ops);
          if (failure.retryable) break;
        }
      }
    } finally {
      if (ref.mounted) state = state.copyWith(processing: false);
    }
  }

  Future<void> retry(String id) async {
    state = state.copyWith(
      ops: state.ops.map((o) => o.id == id ? o.copyWith(failed: false) : o).toList(),
    );
    await _store.save(state.ops);
    await process();
  }

  Future<void> discard(String id) async {
    final op = state.ops.where((o) => o.id == id).firstOrNull;
    state = state.copyWith(ops: state.ops.where((o) => o.id != id).toList());
    await _store.save(state.ops);
    final path = op?.filePath;
    if (path != null) await deleteLocalFile(path);
  }
}
