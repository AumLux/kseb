begin;
\ir fixtures/org.psql
select plan(12);

select tests.login('d0000000-0000-0000-0000-000000000001');
select lives_ok($$
  insert into public.tenders (id, reference, title, estimate_amount, emd_amount, submission_deadline)
  values ('a1000000-0000-0000-0000-000000000001', 'KSEB/EKM/2026/41', '11kV line extension, Kaloor',
          2450000.00, 24500.00, now() + interval '10 days')$$,
  'director creates a tender');
select is((select owner_id from public.tenders), auth.uid(), 'ownership is set by the server');
select throws_ok($$
  insert into public.tenders (reference, title, owner_id)
  values ('X/1', 'Spoofed owner', 'a0000000-0000-0000-0000-000000000001')$$,
  '42501', null, 'owner cannot be spoofed');
select lives_ok($$
  insert into public.deposits (kind, tender_id, amount, payment_mode, deposit_date, validity_date)
  values ('emd', 'a1000000-0000-0000-0000-000000000001', 24500, 'online', current_date, current_date + 10)$$,
  'director records the EMD');
reset role;

select tests.login('e0000000-0000-0000-0000-000000000001');
select is((select count(*)::integer from public.tenders), 1, 'managers can read tenders');
select throws_ok($$insert into public.tenders (reference, title) values ('M/1', 'Manager tender')$$,
  '42501', null, 'managers cannot create tenders');
select is((select count(*)::integer from public.deposits_expiring), 1, 'expiring deposits are surfaced');
reset role;

select tests.login('a0000000-0000-0000-0000-000000000001');
select is((select count(*)::integer from public.tenders), 0, 'staff cannot see commercial data');
reset role;

-- Bonus ledger: supervisor proposes, an executive decides, totals are derived.
select tests.login('f0000000-0000-0000-0000-000000000001');
select lives_ok($$
  insert into public.bonus_ledger (id, user_id, points, amount, reason)
  values ('a2000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000001', 10, 500, 'Storm restoration overtime')$$,
  'supervisor proposes a bonus for their team member');
select throws_like($$select public.decide_bonus('a2000000-0000-0000-0000-000000000001', true)$$,
  '%COO or Director%', 'supervisor cannot approve bonuses');
reset role;

select tests.login('c0000000-0000-0000-0000-000000000001');
select lives_ok($$select public.decide_bonus('a2000000-0000-0000-0000-000000000001', true)$$, 'COO approves');
reset role;

select tests.login('a0000000-0000-0000-0000-000000000001');
select is((select amount from public.bonus_totals), 500.00::numeric, 'staff see their approved total');
reset role;

select * from finish();
rollback;
