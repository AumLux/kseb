-- =============================================================================
-- Worksheets: one row per job with a status machine (replaces the old
-- worksheet_requests → worksheets copy-on-approve), crew, permit-to-work
-- safety checklist, incidents, and shared attachments + storage.
-- =============================================================================

create type public.worksheet_type as enum ('project', 'maintenance', 'calamity');
create type public.worksheet_status as enum
  ('draft', 'submitted', 'approved', 'rejected', 'in_progress', 'completed', 'cancelled');
create type public.incident_severity as enum ('near_miss', 'minor', 'major', 'fatal');

create table public.worksheets (
  id uuid primary key default gen_random_uuid(), -- client may supply (offline outbox)
  code text not null unique default private.next_doc_no('WS'),
  work_type public.worksheet_type not null,
  title text not null check (length(trim(title)) >= 3),
  section_id uuid not null references public.sections (id) on delete restrict,
  work_order_id uuid, -- FK added in the commercial migration
  location_text text not null check (length(trim(location_text)) >= 2),
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180),
  permit_book_no text,
  description text,
  planned_date date,
  status public.worksheet_status not null default 'draft',
  requested_by uuid not null default auth.uid() references public.profiles (id),
  submitted_at timestamptz,
  decided_by uuid references public.profiles (id) on delete set null,
  decided_at timestamptz,
  decision_note text,
  started_at timestamptz,
  completed_at timestamptz,
  completion_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((lat is null) = (lng is null))
);
create index on public.worksheets (section_id, status);
create index on public.worksheets (requested_by);
select private.track('public.worksheets');

alter table public.attendance_days
  add constraint attendance_days_worksheet_id_fkey
  foreign key (worksheet_id) references public.worksheets (id) on delete set null;

create table public.worksheet_crew (
  worksheet_id uuid not null references public.worksheets (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  added_at timestamptz not null default now(),
  primary key (worksheet_id, user_id)
);
create index on public.worksheet_crew (user_id);

-- Permit-to-work / line clear checklist; required before work can start.
create table public.permit_checklists (
  worksheet_id uuid primary key references public.worksheets (id) on delete cascade,
  line_clear_ref text not null check (length(trim(line_clear_ref)) > 0),
  line_clear_issued_by text not null,
  isolation_points text not null,
  earthing_done boolean not null,
  tested_dead boolean not null,
  toolbox_talk_done boolean not null,
  ppe_confirmed text[] not null default '{}',
  signed_by uuid not null references public.profiles (id),
  signed_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
select private.track('public.permit_checklists');

create table public.incidents (
  id uuid primary key default gen_random_uuid(),
  code text not null unique default private.next_doc_no('INC'),
  worksheet_id uuid references public.worksheets (id) on delete set null,
  section_id uuid not null references public.sections (id) on delete restrict,
  severity public.incident_severity not null,
  occurred_at timestamptz not null,
  description text not null check (length(trim(description)) >= 10),
  injured_persons text,
  action_taken text,
  status text not null default 'open' check (status in ('open', 'investigating', 'closed')),
  reported_by uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.incidents (section_id, status);
select private.track('public.incidents');

-- -----------------------------------------------------------------------------
-- Visibility: requester, crew, and supervisors+ in the section.
-- -----------------------------------------------------------------------------
create or replace function private.can_see_worksheet(p_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.worksheets w
    where w.id = p_id
      and private.my_role() is not null
      and (
        w.requested_by = auth.uid()
        or exists (select 1 from public.worksheet_crew c where c.worksheet_id = w.id and c.user_id = auth.uid())
        or (private.has_role('supervisor') and w.section_id = any (private.my_section_ids()))
      )
  );
$$;

-- -----------------------------------------------------------------------------
-- Workflow
-- -----------------------------------------------------------------------------
create or replace function public.transition_worksheet(p_id uuid, p_action text, p_note text default null)
returns public.worksheets
language plpgsql
security definer
set search_path = ''
as $$
declare
  w public.worksheets;
  is_requester boolean;
  is_approver boolean;
  permit public.permit_checklists;
begin
  perform private.require_active();
  select * into w from public.worksheets where id = p_id for update;
  if not found or not private.can_see_worksheet(p_id) then
    perform private.fail('not_found', 'Worksheet not found.');
  end if;

  is_requester := w.requested_by = auth.uid();
  is_approver := private.can_approve_for(w.requested_by);

  case p_action
    when 'submit' then
      -- Idempotent for the requester: an offline replay of a submit whose
      -- response was lost must not surface as an error.
      if is_requester and w.status = 'submitted' then
        return w;
      end if;
      if not is_requester or w.status not in ('draft', 'rejected') then
        perform private.fail('invalid_transition', 'Only your own draft or rejected worksheets can be submitted.');
      end if;
      update public.worksheets
         set status = 'submitted', submitted_at = now(),
             decided_by = null, decided_at = null, decision_note = null
       where id = p_id returning * into w;

    when 'approve', 'reject' then
      if not is_approver then
        perform private.fail('forbidden', 'Only a higher authority in this section can decide this worksheet.');
      end if;
      if w.status <> 'submitted' then
        perform private.fail('already_decided', format('This worksheet is %s.', w.status));
      end if;
      if p_action = 'reject' and length(trim(coalesce(p_note, ''))) < 3 then
        perform private.fail('reason_required', 'Give a reason for rejecting.');
      end if;
      update public.worksheets
         set status = case when p_action = 'approve' then 'approved'::public.worksheet_status else 'rejected' end,
             decided_by = auth.uid(), decided_at = now(), decision_note = nullif(trim(p_note), '')
       where id = p_id returning * into w;
      perform private.notify(
        w.requested_by,
        case when p_action = 'approve' then 'Worksheet approved' else 'Worksheet rejected' end,
        w.code || ' · ' || w.title, '/work/' || w.id);

    when 'start' then
      if not (is_requester or is_approver) or w.status <> 'approved' then
        perform private.fail('invalid_transition', 'Only approved worksheets can be started.');
      end if;
      select * into permit from public.permit_checklists where worksheet_id = p_id;
      if not found or not permit.earthing_done or not permit.tested_dead
         or not permit.toolbox_talk_done
         or not (permit.ppe_confirmed @> array['helmet', 'gloves', 'safety_belt']) then
        perform private.fail('permit_incomplete',
          'Complete the permit-to-work checklist (line clear, earthing, tested dead, toolbox talk, PPE) before starting.');
      end if;
      update public.worksheets set status = 'in_progress', started_at = now()
       where id = p_id returning * into w;

    when 'complete' then
      if not (is_requester or is_approver) or w.status <> 'in_progress' then
        perform private.fail('invalid_transition', 'Only work in progress can be completed.');
      end if;
      update public.worksheets
         set status = 'completed', completed_at = now(), completion_note = nullif(trim(p_note), '')
       where id = p_id returning * into w;

    when 'cancel' then
      if not (is_requester or is_approver) or w.status not in ('draft', 'submitted', 'approved', 'rejected') then
        perform private.fail('invalid_transition', 'This worksheet can no longer be cancelled.');
      end if;
      update public.worksheets set status = 'cancelled', decision_note = coalesce(nullif(trim(p_note), ''), decision_note)
       where id = p_id returning * into w;

    else
      perform private.fail('invalid_action', 'Unknown action.');
  end case;

  return w;
end;
$$;

-- Replace the crew list (requester or approver; not after completion).
create or replace function public.set_worksheet_crew(p_id uuid, p_user_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  w public.worksheets;
  bad uuid;
begin
  perform private.require_active();
  select * into w from public.worksheets where id = p_id for update;
  if not found or not (w.requested_by = auth.uid() or private.can_approve_for(w.requested_by)) then
    perform private.fail('forbidden', 'You cannot change this crew.');
  end if;
  if w.status in ('completed', 'cancelled') then
    perform private.fail('invalid_transition', 'The crew of a closed worksheet cannot change.');
  end if;

  select u into bad from unnest(coalesce(p_user_ids, '{}')) u
   where not exists (select 1 from public.profiles p
                      where p.id = u and p.status = 'active' and p.section_id = w.section_id)
   limit 1;
  if bad is not null then
    perform private.fail('invalid_crew', 'Crew members must be active staff of the worksheet''s section.');
  end if;

  delete from public.worksheet_crew where worksheet_id = p_id and user_id <> all (coalesce(p_user_ids, '{}'));
  insert into public.worksheet_crew (worksheet_id, user_id)
  select p_id, u from unnest(coalesce(p_user_ids, '{}')) u
  on conflict do nothing;
end;
$$;

create or replace function public.sign_permit_checklist(
  p_worksheet_id uuid,
  p_line_clear_ref text,
  p_line_clear_issued_by text,
  p_isolation_points text,
  p_earthing_done boolean,
  p_tested_dead boolean,
  p_toolbox_talk_done boolean,
  p_ppe_confirmed text[])
returns public.permit_checklists
language plpgsql
security definer
set search_path = ''
as $$
declare
  w public.worksheets;
  result public.permit_checklists;
begin
  perform private.require_active();
  select * into w from public.worksheets where id = p_worksheet_id;
  if not found or not (w.requested_by = auth.uid() or private.can_approve_for(w.requested_by)) then
    perform private.fail('forbidden', 'Only the worksheet owner or their approver can sign the permit.');
  end if;
  if not private.has_role('supervisor') then
    perform private.fail('forbidden', 'A supervisor or above must sign the permit-to-work.');
  end if;
  if w.status not in ('approved', 'in_progress') then
    perform private.fail('invalid_transition', 'The permit can be signed once the worksheet is approved.');
  end if;

  insert into public.permit_checklists as pc (
    worksheet_id, line_clear_ref, line_clear_issued_by, isolation_points,
    earthing_done, tested_dead, toolbox_talk_done, ppe_confirmed, signed_by, signed_at)
  values (
    p_worksheet_id, trim(p_line_clear_ref), trim(p_line_clear_issued_by), trim(p_isolation_points),
    p_earthing_done, p_tested_dead, p_toolbox_talk_done, coalesce(p_ppe_confirmed, '{}'), auth.uid(), now())
  on conflict (worksheet_id) do update set
    line_clear_ref = excluded.line_clear_ref,
    line_clear_issued_by = excluded.line_clear_issued_by,
    isolation_points = excluded.isolation_points,
    earthing_done = excluded.earthing_done,
    tested_dead = excluded.tested_dead,
    toolbox_talk_done = excluded.toolbox_talk_done,
    ppe_confirmed = excluded.ppe_confirmed,
    signed_by = excluded.signed_by,
    signed_at = excluded.signed_at
  returning * into result;
  return result;
end;
$$;

-- -----------------------------------------------------------------------------
-- Attachments (photos/documents for any record) + private storage bucket.
-- Visibility follows the owning record: if you can see the record, you can
-- see its files.
-- -----------------------------------------------------------------------------
create table public.attachments (
  id uuid primary key default gen_random_uuid(),
  owner_table text not null check (owner_table in (
    'worksheets', 'incidents', 'pole_records', 'assets', 'tenders', 'deposits',
    'work_orders', 'bills', 'correspondence', 'gst_returns', 'material_requests')),
  owner_id uuid not null,
  kind text not null default 'photo' check (kind in ('photo', 'document')),
  storage_path text not null unique,
  file_name text,
  mime_type text not null check (mime_type in ('image/jpeg', 'image/png', 'image/webp', 'application/pdf')),
  size_bytes integer not null check (size_bytes > 0 and size_bytes <= 10485760),
  captured_at timestamptz,
  lat double precision,
  lng double precision,
  uploaded_by uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now()
);
create index on public.attachments (owner_table, owner_id);
select private.track('public.attachments', false);

-- SECURITY INVOKER on purpose: the EXISTS runs under the caller's RLS on the
-- owner table, so attachment visibility can never exceed record visibility.
create or replace function private.can_see_owner(p_table text, p_id uuid)
returns boolean
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  ok boolean;
begin
  if to_regclass('public.' || p_table) is null then
    return false;
  end if;
  execute format('select exists (select 1 from public.%I where id = $1)', p_table)
    into ok using p_id;
  return ok;
end;
$$;

alter table public.worksheets enable row level security;
alter table public.worksheet_crew enable row level security;
alter table public.permit_checklists enable row level security;
alter table public.incidents enable row level security;
alter table public.attachments enable row level security;

-- Worksheets: insert/edit own drafts on whitelisted columns; workflow
-- columns change only via transition_worksheet().
grant select, delete on public.worksheets to authenticated;
grant insert (id, work_type, title, section_id, work_order_id, location_text, lat, lng,
              permit_book_no, description, planned_date)
  on public.worksheets to authenticated;
grant update (work_type, title, section_id, work_order_id, location_text, lat, lng,
              permit_book_no, description, planned_date)
  on public.worksheets to authenticated;

-- Column-based (not an id lookup): INSERT ... ON CONFLICT DO NOTHING, which
-- the offline outbox uses for idempotent replays, also evaluates the SELECT
-- policy against the *new* row, which an id lookup cannot find yet.
create policy worksheets_read on public.worksheets for select to authenticated
  using (
    (select private.my_role()) is not null
    and (
      requested_by = auth.uid()
      or ((select private.has_role('supervisor'))
          and section_id = any ((select private.my_section_ids())::uuid[]))
      or exists (select 1 from public.worksheet_crew c
                  where c.worksheet_id = id and c.user_id = auth.uid())
    )
  );
create policy worksheets_insert on public.worksheets for insert to authenticated
  with check (requested_by = auth.uid()
              and section_id = any ((select private.my_section_ids())::uuid[]));
create policy worksheets_update on public.worksheets for update to authenticated
  using (requested_by = auth.uid() and status in ('draft', 'rejected'))
  with check (requested_by = auth.uid() and status in ('draft', 'rejected')
              and section_id = any ((select private.my_section_ids())::uuid[]));
create policy worksheets_delete on public.worksheets for delete to authenticated
  using (requested_by = auth.uid() and status = 'draft');

grant select on public.worksheet_crew, public.permit_checklists to authenticated;
create policy crew_read on public.worksheet_crew for select to authenticated
  using ((select private.can_see_worksheet(worksheet_id)));
create policy permit_read on public.permit_checklists for select to authenticated
  using ((select private.can_see_worksheet(worksheet_id)));

-- Incidents: anyone active may report in their sections; managers+ update status.
grant select on public.incidents to authenticated;
grant insert (id, worksheet_id, section_id, severity, occurred_at, description, injured_persons, action_taken)
  on public.incidents to authenticated;
grant update (status, action_taken) on public.incidents to authenticated;
create policy incidents_read on public.incidents for select to authenticated
  using (reported_by = auth.uid()
         or ((select private.has_role('supervisor'))
             and section_id = any ((select private.my_section_ids())::uuid[])));
create policy incidents_insert on public.incidents for insert to authenticated
  with check (reported_by = auth.uid()
              and section_id = any ((select private.my_section_ids())::uuid[])
              and occurred_at <= now() + interval '5 minutes');
create policy incidents_update on public.incidents for update to authenticated
  using ((select private.has_role('manager'))
         and section_id = any ((select private.my_section_ids())::uuid[]));

grant select, delete on public.attachments to authenticated;
grant insert (id, owner_table, owner_id, kind, storage_path, file_name, mime_type, size_bytes,
              captured_at, lat, lng)
  on public.attachments to authenticated;
create policy attachments_read on public.attachments for select to authenticated
  using (private.can_see_owner(owner_table, owner_id));
create policy attachments_insert on public.attachments for insert to authenticated
  with check (uploaded_by = auth.uid()
              and (select private.my_role()) is not null
              and storage_path like owner_table || '/' || owner_id || '/%'
              and private.can_see_owner(owner_table, owner_id));
create policy attachments_delete on public.attachments for delete to authenticated
  using ((uploaded_by = auth.uid() and created_at > now() - interval '24 hours')
         or (select private.is_exec()));

-- Storage: private bucket; object access mirrors the attachments row.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('attachments', 'attachments', false, 10485760,
        array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'])
on conflict (id) do nothing;

create policy attachments_object_read on storage.objects for select to authenticated
  using (bucket_id = 'attachments'
         and exists (select 1 from public.attachments a where a.storage_path = name));
create policy attachments_object_insert on storage.objects for insert to authenticated
  with check (bucket_id = 'attachments'
              and exists (select 1 from public.attachments a
                           where a.storage_path = name and a.uploaded_by = auth.uid()));
create policy attachments_object_delete on storage.objects for delete to authenticated
  using (bucket_id = 'attachments'
         and exists (select 1 from public.attachments a
                      where a.storage_path = name
                        and ((a.uploaded_by = auth.uid() and a.created_at > now() - interval '24 hours')
                             or private.is_exec())));

grant execute on function public.transition_worksheet(uuid, text, text) to authenticated;
grant execute on function public.set_worksheet_crew(uuid, uuid[]) to authenticated;
grant execute on function public.sign_permit_checklist(uuid, text, text, text, boolean, boolean, boolean, text[]) to authenticated;
grant execute on all functions in schema private to authenticated, service_role;
