begin;
\ir fixtures/org.psql
select plan(9);

-- Employee codes ---------------------------------------------------------------
-- Assertions use codes far above any seeded/demo data, so they hold on a dirty DB.
select tests.login('e0000000-0000-0000-0000-000000000001');
select matches(public.next_employee_code(), '^AUM[0-9]{4,}$', 'codes look like AUM0001');
reset role;

update public.profiles set employee_code = 'AUM9041' where id = 'a0000000-0000-0000-0000-000000000001';
update public.profiles set employee_code = 'aum0007' where id = 'a0000000-0000-0000-0000-000000000002';
update public.profiles set employee_code = 'AUM-OLD-9' where id = 'f0000000-0000-0000-0000-000000000001';

select tests.login('e0000000-0000-0000-0000-000000000001');
select is(public.next_employee_code(), 'AUM9042',
  'next code follows the highest AUM number org-wide (case-insensitive, custom codes ignored)');
reset role;

-- Managers see only their sections, but the code must be unique org-wide.
select tests.login('e0000000-0000-0000-0000-000000000002');
select is(public.next_employee_code(), 'AUM9042', 'a manager of another section gets the same org-wide next code');
reset role;

select tests.login('f0000000-0000-0000-0000-000000000001');
select throws_like($$select public.next_employee_code()$$, '%managers and above%', 'supervisors cannot generate codes');
reset role;

update public.app_settings set value = '{"prefix": "KSE", "digits": 5}' where key = 'employee_code_format';
select tests.login('c0000000-0000-0000-0000-000000000001');
select is(public.next_employee_code(), 'KSE00001', 'prefix and width come from app_settings');
reset role;

select is(
  (select count(*)::integer from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and has_function_privilege('anon', p.oid, 'execute')),
  0, 'anon still cannot execute any public function');

-- Check-out geofence -----------------------------------------------------------
select tests.login('a0000000-0000-0000-0000-000000000001');
select lives_ok(
  $$select public.check_in('71000000-0000-0000-0000-000000000001', tests.yesterday_at(9), 9.9944, 76.3000, 12, false)$$,
  'W1 checks in at Section A');
select lives_ok(
  $$select public.check_out('71000000-0000-0000-0000-000000000002', tests.yesterday_at(18), 10.1076, 76.3516, 20, false)$$,
  'W1 checks out ~16 km away (flagged, not blocked)');
select ok(
  (select check_out_outside_geofence and check_out_distance_m > 10000
     from public.attendance_days where check_out_request_id = '71000000-0000-0000-0000-000000000002'),
  'check-out records distance and the outside-geofence flag');
reset role;

select * from finish();
rollback;
