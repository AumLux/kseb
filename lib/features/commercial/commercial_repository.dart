import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/errors/app_failure.dart';
import '../../core/supabase/providers.dart';
import '../../core/supabase/update_guard.dart';
import 'entities.dart';

typedef DbRow = Map<String, dynamic>;

final commercialRepositoryProvider =
    Provider<CommercialRepository>((ref) => CommercialRepository(ref.watch(supabaseClientProvider)));

final entityRowsProvider = FutureProvider.autoDispose.family<List<DbRow>, String>(
    (ref, key) => ref.watch(commercialRepositoryProvider).list(entityByKey(key)));

final entityRowProvider = FutureProvider.autoDispose.family<DbRow, ({String key, String id})>(
    (ref, k) => ref.watch(commercialRepositoryProvider).get(entityByKey(k.key), k.id));

/// Options for a reference picker: id → display text.
final refOptionsProvider = FutureProvider.autoDispose.family<Map<String, String>, String>(
    (ref, refEntity) => ref.watch(commercialRepositoryProvider).refOptions(refEntity));

final linkedRowsProvider = FutureProvider.autoDispose.family<List<DbRow>, ({String entity, String column, String id})>(
    (ref, k) => ref.watch(commercialRepositoryProvider).linked(entityByKey(k.entity), k.column, k.id));

final depositsExpiringProvider = FutureProvider.autoDispose<List<DbRow>>(
    (ref) => ref.watch(commercialRepositoryProvider).view('deposits_expiring', 'validity_date', ascending: true));

final billAgeingProvider = FutureProvider.autoDispose<List<DbRow>>(
    (ref) => ref.watch(commercialRepositoryProvider).view('bill_ageing', 'invoice_date'));

class CommercialRepository {
  CommercialRepository(this._client);

  final SupabaseClient _client;

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } catch (e) {
      throw AppFailure.from(e);
    }
  }

  Future<List<DbRow>> list(EntityDef e) => _guard(() async =>
      List<DbRow>.from(await _client.from(e.table).select().order(e.orderBy, ascending: e.ascending).limit(500)));

  Future<DbRow> get(EntityDef e, String id) =>
      _guard(() async => DbRow.from(await _client.from(e.table).select().eq('id', id).single()));

  Future<List<DbRow>> linked(EntityDef e, String column, String id) => _guard(() async =>
      List<DbRow>.from(await _client.from(e.table).select().eq(column, id).order(e.orderBy, ascending: e.ascending)));

  Future<List<DbRow>> view(String name, String orderBy, {bool ascending = false}) =>
      _guard(() async => List<DbRow>.from(await _client.from(name).select().order(orderBy, ascending: ascending)));

  Future<Map<String, String>> refOptions(String refEntity) => _guard(() async {
        final cols = refDisplayColumns(refEntity);
        final rows = await _client.from(refTable(refEntity)).select(['id', ...cols].join(',')).order(cols.first);
        return {
          for (final r in rows) r['id'] as String: cols.map((c) => r[c]?.toString() ?? '').where((s) => s.isNotEmpty).join(' · '),
        };
      });

  /// Returns the id of the saved row.
  Future<String> save(EntityDef e, DbRow values, {String? id}) => _guard(() async {
        if (id == null) {
          final row = await _client.from(e.table).insert(values).select('id').single();
          return row['id'] as String;
        }
        await updateOrFail(_client, e.table, values, id);
        return id;
      });

  /// Matches across all registers for the search box ("View details").
  Future<List<({EntityDef entity, DbRow row})>> search(String query) => _guard(() async {
        final q = query.trim().replaceAll(RegExp(r'[,()%]'), ' ');
        if (q.length < 2) return const [];
        final results = await Future.wait([
          for (final e in commercialEntities)
            _client
                .from(e.table)
                .select()
                .or(e.searchColumns.map((c) => '$c.ilike.%$q%').join(','))
                .limit(10)
                .then((rows) => [for (final r in rows) (entity: e, row: DbRow.from(r))]),
        ]);
        return results.expand((r) => r).toList();
      });
}
