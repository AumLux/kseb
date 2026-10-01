begin;
\ir fixtures/org.psql
select plan(16);

-- W1 drafts a worksheet in their own section.
select tests.login('a0000000-0000-0000-0000-000000000001');
select lives_ok($$
  insert into public.worksheets (id, work_type, title, section_id, location_text, lat, lng)
  values ('80000000-0000-0000-0000-000000000001', 'maintenance', 'Replace DP fuse', '40000000-0000-0000-0000-00000000000a',
          'Kaloor junction', 9.9950, 76.3005)$$,
  'staff can draft a worksheet in their section');
select matches((select code from public.worksheets), '^WS-[0-9]{4}-[0-9]{5}$', 'a document number is assigned');
select throws_ok($$
  insert into public.worksheets (work_type, title, section_id, location_text)
  values ('maintenance', 'Elsewhere', '40000000-0000-0000-0000-00000000000b', 'Aluva')$$,
  '42501', null, 'staff cannot create worksheets in other sections');
select throws_ok(
  $$update public.worksheets set status = 'approved'$$,
  '42501', null, 'status cannot be set directly');
select lives_ok(
  $$select public.transition_worksheet('80000000-0000-0000-0000-000000000001', 'submit')$$,
  'requester can submit');
select throws_like(
  $$select public.transition_worksheet('80000000-0000-0000-0000-000000000001', 'approve')$$,
  '%higher authority%', 'requester cannot approve their own worksheet');
-- Attachments follow the worksheet's visibility.
select lives_ok($$
  insert into public.attachments (id, owner_table, owner_id, storage_path, mime_type, size_bytes)
  values ('81000000-0000-0000-0000-000000000001', 'worksheets', '80000000-0000-0000-0000-000000000001',
          'worksheets/80000000-0000-0000-0000-000000000001/p1.jpg', 'image/jpeg', 120000)$$,
  'requester can attach a photo');
reset role;

select tests.login('a0000000-0000-0000-0000-000000000002');
select is((select count(*)::integer from public.worksheets), 0, 'staff in another section cannot see it');
select is((select count(*)::integer from public.attachments), 0, 'nor its attachments');
reset role;

-- Supervisor approves; start is blocked until the permit is signed.
select tests.login('f0000000-0000-0000-0000-000000000001');
select is(
  (select status::text from public.transition_worksheet('80000000-0000-0000-0000-000000000001', 'approve')),
  'approved', 'supervisor approves');
select throws_like(
  $$select public.transition_worksheet('80000000-0000-0000-0000-000000000001', 'approve')$$,
  '%is approved%', 'a second approval is rejected');
select throws_like(
  $$select public.transition_worksheet('80000000-0000-0000-0000-000000000001', 'start')$$,
  '%permit-to-work%', 'work cannot start without a permit-to-work');
select lives_ok($$
  select public.sign_permit_checklist('80000000-0000-0000-0000-000000000001', 'LC/2026/118', 'AE Kaloor',
    'AB switch at DP-14 opened and locked', true, true, true, array['helmet', 'gloves', 'safety_belt', 'boots'])$$,
  'supervisor signs the permit');
select is(
  (select status::text from public.transition_worksheet('80000000-0000-0000-0000-000000000001', 'start')),
  'in_progress', 'work starts once the permit is complete');
select throws_like(
  $$select public.set_worksheet_crew('80000000-0000-0000-0000-000000000001', array['a0000000-0000-0000-0000-000000000002'::uuid])$$,
  '%section%', 'crew must belong to the worksheet''s section');
reset role;

select tests.login('a0000000-0000-0000-0000-000000000001');
select is(
  (select status::text from public.transition_worksheet('80000000-0000-0000-0000-000000000001', 'complete', 'Fuse replaced')),
  'completed', 'requester completes the job');
reset role;

select * from finish();
rollback;
