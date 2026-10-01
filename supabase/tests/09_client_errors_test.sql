begin;
\ir fixtures/org.psql
select plan(6);

select tests.login('a0000000-0000-0000-0000-000000000001');
select lives_ok($$insert into public.client_errors (app_version, platform, message, stack, context)
  values ('2.0.0+20', 'android', 'Null check operator', '#0 main', 'flutter')$$, 'a signed-in user can report an error');
select throws_ok($$insert into public.client_errors (user_id, app_version, platform, message)
  values ('a0000000-0000-0000-0000-000000000002', '2.0.0', 'web', 'spoofed')$$, '42501', null,
  'reports cannot be attributed to someone else');
select is((select count(*)::integer from public.client_errors), 0, 'staff cannot read error reports');
reset role;

select tests.login('e0000000-0000-0000-0000-000000000001');
select is((select count(*)::integer from public.client_errors), 0, 'managers cannot read error reports');
reset role;

select tests.login('c0000000-0000-0000-0000-000000000001');
select is((select count(*)::integer from public.client_errors where user_id = 'a0000000-0000-0000-0000-000000000001'), 1,
  'COO reads reports, stamped with the reporter');
reset role;

set local role anon;
select throws_ok($$insert into public.client_errors (app_version, platform, message) values ('x', 'web', 'anon')$$,
  '42501', null, 'anonymous clients cannot report');
reset role;

select * from finish();
rollback;
