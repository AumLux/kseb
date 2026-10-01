begin;
\ir fixtures/org.psql
select plan(14);

-- Leave: request, decide, and the attendance rows it produces.
select tests.login('a0000000-0000-0000-0000-000000000001');
select lives_ok($$
  insert into public.leave_requests (id, from_date, to_date, leave_type, reason)
  values ('a3000000-0000-0000-0000-000000000001', current_date + 1, current_date + 2, 'casual', 'Family function')$$,
  'staff request leave');
reset role;

select tests.login('f0000000-0000-0000-0000-000000000001');
select lives_ok($$select public.decide_leave('a3000000-0000-0000-0000-000000000001', true)$$, 'supervisor approves leave');
select is((select count(*)::integer from public.attendance_days where status = 'leave'), 2,
  'approved leave fills the attendance calendar');
select is((select count(*)::integer from public.my_approvals()), 0, 'nothing left in the approvals inbox');
reset role;

select tests.login('a0000000-0000-0000-0000-000000000001');
select is((select count(*)::integer from public.notifications), 1, 'requester is notified of the decision');
select throws_like($$select public.cancel_leave('a3000000-0000-0000-0000-000000000001')$$,
  '%pending%', 'decided leave cannot be cancelled');
select ok((public.dashboard_kpis() ->> 'pending_approvals') is not null, 'staff dashboard renders');
select is((select count(*)::integer from public.attendance_month(current_date)), extract(day from
  (date_trunc('month', current_date) + interval '1 month - 1 day'))::integer,
  'muster roll returns one row per day for a staff member (own row only)');
reset role;

select tests.login('d0000000-0000-0000-0000-000000000001');
select ok((public.dashboard_kpis() ? 'receivables_outstanding'), 'executive dashboard includes commercial KPIs');
select lives_ok($$select * from public.attendance_month(current_date, '40000000-0000-0000-0000-00000000000a')$$,
  'section muster roll runs');
reset role;

-- Assets: register (manager), assign (supervisor), move (manager only).
select tests.login('e0000000-0000-0000-0000-000000000001');
select lives_ok($$
  insert into public.assets (id, asset_tag, category, name, section_id, rating)
  values ('a4000000-0000-0000-0000-000000000001', 'TR-EKM-0042', 'transformer', '100 kVA DT', '40000000-0000-0000-0000-00000000000a', '100 kVA')$$,
  'manager registers an asset');
reset role;

select tests.login('f0000000-0000-0000-0000-000000000001');
select lives_ok($$select public.record_asset_event('a4000000-0000-0000-0000-000000000001', 'assigned', 'Issued for DP work',
  null, 'a0000000-0000-0000-0000-000000000001')$$, 'supervisor assigns the asset to a crew member');
select throws_like($$select public.record_asset_event('a4000000-0000-0000-0000-000000000001', 'moved', 'x',
  '40000000-0000-0000-0000-00000000000a')$$, '%Only managers%', 'supervisors cannot move assets');
reset role;

-- Scheduled job runs cleanly.
select lives_ok($$select private.daily_alerts()$$, 'daily alerts job runs');

select * from finish();
rollback;
