begin;
\ir fixtures/org.psql
select plan(10);

select is(
  (select count(*)::integer from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and not c.relrowsecurity),
  0, 'every public table has RLS enabled');

select is(
  (select count(*)::integer from information_schema.role_table_grants
    where grantee = 'anon' and table_schema = 'public'),
  0, 'anon has no privileges on any public table or view');

select is(
  (select count(*)::integer from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')),
  0, 'anon cannot execute any public function');

select ok(not has_table_privilege('authenticated', 'public.profiles', 'update'),
  'clients cannot update profiles directly');
select ok(not has_table_privilege('authenticated', 'public.profiles', 'insert'),
  'clients cannot create profiles directly');
select ok(not has_column_privilege('authenticated', 'public.worksheets', 'status', 'update'),
  'worksheet status is not client-writable');
select ok(not has_table_privilege('authenticated', 'public.stock_ledger', 'insert'),
  'clients cannot post to the stock ledger directly');
select ok(not has_table_privilege('authenticated', 'public.attendance_days', 'insert'),
  'clients cannot insert attendance directly');
select ok(not has_column_privilege('authenticated', 'public.tenders', 'owner_id', 'insert'),
  'tender ownership is server-set');
select ok(has_table_privilege('service_role', 'public.profiles', 'insert'),
  'service role (admin-users function) can provision profiles');

select * from finish();
rollback;
