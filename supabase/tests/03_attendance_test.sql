begin;
\ir fixtures/org.psql
select plan(16);

-- W1 checks in yesterday 10:00 IST near Section A (offline replay window).
select tests.login('a0000000-0000-0000-0000-000000000001');
select lives_ok(
  $$select public.check_in('70000000-0000-0000-0000-000000000001', tests.yesterday_at(10), 9.9944, 76.3000, 12, false)$$,
  'staff can check in');
select is(
  (select id from public.check_in('70000000-0000-0000-0000-000000000001', tests.yesterday_at(10), 9.9944, 76.3000, 12, false)),
  (select id from public.attendance_days where check_in_request_id = '70000000-0000-0000-0000-000000000001'),
  'retrying the same request id is idempotent (offline outbox replay)');
select is((select count(*)::integer from public.attendance_days), 1, 'replay did not create a duplicate');
select is(
  (select work_date from public.attendance_days),
  ((now() at time zone 'Asia/Kolkata')::date - 1),
  'work date is computed in IST on the server');
select is((select check_in_outside_geofence from public.attendance_days), false, 'inside the section geofence');
select throws_like(
  $$select public.check_in('70000000-0000-0000-0000-000000000002', tests.yesterday_at(11), 9.9944, 76.3000, 12, false)$$,
  '%already checked in%', 'a second check-in for the same day is rejected');
select lives_ok(
  $$select public.check_out('70000000-0000-0000-0000-000000000003', tests.yesterday_at(18), 9.9944, 76.3000, 12, false)$$,
  'staff can check out');
select throws_like(
  $$select public.check_in('70000000-0000-0000-0000-000000000004', now() - interval '10 days', 9.99, 76.30, 10, false)$$,
  '%cannot be synced%', 'stale offline captures are rejected');
select throws_ok(
  $$insert into public.attendance_days (user_id, work_date) values (auth.uid(), current_date)$$,
  '42501', null, 'attendance cannot be inserted directly');
select throws_like(
  $$select public.mark_attendance('a0000000-0000-0000-0000-000000000002', current_date - 1, 'absent', 'not allowed')$$,
  '%only manage people below you%', 'staff cannot mark others');
reset role;

-- Far from the section → flagged, not blocked.
select tests.login('a0000000-0000-0000-0000-000000000002');
select lives_ok(
  $$select public.check_in('70000000-0000-0000-0000-000000000005', tests.yesterday_at(9), 9.9943, 76.2999, 15, false)$$,
  'check-in outside the geofence is accepted');
select is(
  (select check_in_outside_geofence from public.attendance_days where user_id = auth.uid()),
  true, 'and flagged as outside the geofence');
reset role;

-- Supervisor tools are scoped and audited.
select tests.login('f0000000-0000-0000-0000-000000000001');
select lives_ok(
  $$select public.mark_attendance('a0000000-0000-0000-0000-000000000001', current_date - 2, 'absent', 'Did not report to site')$$,
  'supervisor can mark their team member');
select is(
  (select count(*)::integer from public.attendance_corrections),
  1, 'the supervisor action is logged with its reason');
select throws_like(
  $$select public.mark_attendance('a0000000-0000-0000-0000-000000000002', current_date - 2, 'absent', 'Out of scope')$$,
  '%only manage people below you%', 'supervisor cannot mark people outside their team');
select throws_like(
  $$select public.mark_attendance('a0000000-0000-0000-0000-000000000001', current_date - 2, 'present', 'ok')$$,
  '%reason%', 'a meaningful reason is mandatory');
reset role;

select * from finish();
rollback;
