import 'package:supabase_flutter/supabase_flutter.dart';

import '../errors/app_failure.dart';

/// Runs an UPDATE and fails loudly when row-level security filtered it out.
///
/// PostgREST reports an RLS-blocked UPDATE as success with zero rows, which
/// would otherwise look like a saved change that never happened.
Future<void> updateOrFail(SupabaseClient client, String table, Map<String, dynamic> values, String id) async {
  final rows = await client.from(table).update(values).eq('id', id).select('id');
  if (rows.isEmpty) {
    throw const AppFailure('forbidden', "You don't have permission to change this record.");
  }
}
