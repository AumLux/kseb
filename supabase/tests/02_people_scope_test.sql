begin;
\ir fixtures/org.psql
select plan(12);

-- Staff W1 sees only themself.
select tests.login('a0000000-0000-0000-0000-000000000001');
select is((select count(*)::integer from public.profiles), 1, 'staff sees only their own profile');
select throws_ok(
  $$update public.profiles set role = 'director' where id = auth.uid()$$,
  '42501', null, 'staff cannot promote themself (no UPDATE privilege)');
select is((select count(*)::integer from public.people_directory() where employee_code like 'T-%'), 7,
  'directory exposes names of everyone to active users');
select is((public.me() ->> 'role'), 'staff', 'me() returns the caller''s role');
reset role;

-- Supervisor S sees their team (S, W1) only.
select tests.login('f0000000-0000-0000-0000-000000000001');
select results_eq(
  $$select employee_code from public.profiles order by employee_code$$,
  $$values ('T-S'), ('T-W1')$$,
  'supervisor sees self and own team members');
reset role;

-- Manager M sees all of Section A, not Section B.
select tests.login('e0000000-0000-0000-0000-000000000001');
select results_eq(
  $$select employee_code from public.profiles order by employee_code$$,
  $$values ('T-M'), ('T-S'), ('T-W1')$$,
  'manager sees their section only');
select is((select count(*)::integer from public.teams), 1, 'manager sees only teams in their sections');
reset role;

-- Director sees everyone.
select tests.login('d0000000-0000-0000-0000-000000000001');
select is((select count(*)::integer from public.profiles where employee_code like 'T-%'), 7, 'director sees everyone');
select lives_ok(
  $$insert into public.circles (code, name) values ('X1', 'New circle')$$,
  'director can maintain the org hierarchy');
reset role;

select tests.login('e0000000-0000-0000-0000-000000000001');
select throws_ok(
  $$insert into public.circles (code, name) values ('X2', 'Nope')$$,
  '42501', null, 'managers cannot change the org hierarchy');
reset role;

-- Suspension takes effect immediately (no stale token claims).
update public.profiles set status = 'suspended' where id = 'a0000000-0000-0000-0000-000000000001';
select tests.login('a0000000-0000-0000-0000-000000000001');
select is((select count(*)::integer from public.profiles), 0, 'suspended user can read nothing');
select is((select count(*)::integer from public.sections), 0, 'suspended user cannot read org data');
reset role;

select * from finish();
rollback;
