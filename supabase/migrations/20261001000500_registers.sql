-- =============================================================================
-- Field registers: Polevar (pole survey records) and the asset register with
-- an event history.
-- =============================================================================

create type public.asset_category as enum
  ('transformer', 'pole', 'conductor', 'meter', 'tool', 'vehicle', 'other');
create type public.asset_status as enum ('in_store', 'deployed', 'under_repair', 'scrapped', 'lost');
create type public.asset_condition as enum ('new', 'good', 'fair', 'poor', 'unserviceable');

create table public.pole_records (
  id uuid primary key default gen_random_uuid(), -- client may supply (offline)
  pole_number text not null check (length(trim(pole_number)) > 0),
  section_id uuid not null references public.sections (id) on delete restrict,
  feeder_name text not null,
  transformer_ref text,
  pole_type text not null check (pole_type in ('psc', 'rcc', 'steel_tubular', 'rail', 'wooden', 'other')),
  height_m numeric(4, 1) check (height_m is null or height_m between 3 and 30),
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180),
  landmark text,
  condition text not null default 'good' check (condition in ('good', 'leaning', 'damaged', 'replaced')),
  remarks text,
  surveyed_at timestamptz not null default now(),
  surveyed_by uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (section_id, pole_number),
  check ((lat is null) = (lng is null))
);
create index on public.pole_records (section_id, feeder_name);
select private.track('public.pole_records');

create table public.assets (
  id uuid primary key default gen_random_uuid(),
  asset_tag text not null unique check (length(trim(asset_tag)) > 0),
  category public.asset_category not null,
  name text not null,
  serial_no text,
  make text,
  rating text,
  section_id uuid not null references public.sections (id) on delete restrict,
  location_text text,
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180),
  assigned_to uuid references public.profiles (id) on delete set null,
  purchase_date date,
  purchase_value numeric(14, 2) check (purchase_value is null or purchase_value >= 0),
  condition public.asset_condition not null default 'good',
  status public.asset_status not null default 'in_store',
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((lat is null) = (lng is null))
);
create index on public.assets (section_id, category);
create index on public.assets (assigned_to);
select private.track('public.assets');

create table public.asset_events (
  id uuid primary key default gen_random_uuid(),
  asset_id uuid not null references public.assets (id) on delete cascade,
  event_type text not null check (event_type in
    ('created', 'assigned', 'moved', 'inspected', 'repaired', 'status_changed', 'scrapped')),
  note text,
  from_section_id uuid references public.sections (id),
  to_section_id uuid references public.sections (id),
  assigned_to uuid references public.profiles (id),
  status public.asset_status,
  condition public.asset_condition,
  actor uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now()
);
create index on public.asset_events (asset_id, created_at desc);

create or replace function private.asset_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.asset_events (asset_id, event_type, to_section_id, status, condition, actor)
  values (new.id, 'created', new.section_id, new.status, new.condition, coalesce(auth.uid(), new.assigned_to));
  return new;
exception when not_null_violation then
  return new; -- created by the service role without an actor
end;
$$;
create trigger asset_created after insert on public.assets
  for each row execute function private.asset_created();

-- Assign / move / inspect / repair / change status, atomically with history.
create or replace function public.record_asset_event(
  p_asset_id uuid,
  p_event_type text,
  p_note text default null,
  p_to_section_id uuid default null,
  p_assigned_to uuid default null,
  p_status public.asset_status default null,
  p_condition public.asset_condition default null)
returns public.assets
language plpgsql
security definer
set search_path = ''
as $$
declare
  a public.assets;
begin
  perform private.require_active();
  select * into a from public.assets where id = p_asset_id for update;
  if not found or not private.can_see_section(a.section_id) or not private.has_role('supervisor') then
    perform private.fail('forbidden', 'You cannot update this asset.');
  end if;
  if p_event_type = 'moved' and (p_to_section_id is null or not private.can_see_section(p_to_section_id)) then
    perform private.fail('forbidden', 'Choose a destination section you have access to.');
  end if;
  if p_event_type in ('moved', 'scrapped') and not private.has_role('manager') then
    perform private.fail('forbidden', 'Only managers can move or scrap assets.');
  end if;
  if p_event_type = 'assigned' and p_assigned_to is not null and not private.can_see_user(p_assigned_to) then
    perform private.fail('forbidden', 'You can only assign to people in your scope.');
  end if;

  insert into public.asset_events (asset_id, event_type, note, from_section_id, to_section_id,
                                   assigned_to, status, condition)
  values (a.id, p_event_type, nullif(trim(p_note), ''), a.section_id,
          case when p_event_type = 'moved' then p_to_section_id end,
          p_assigned_to, p_status, p_condition);

  update public.assets set
    section_id = case when p_event_type = 'moved' then p_to_section_id else section_id end,
    assigned_to = case when p_event_type = 'assigned' then p_assigned_to else assigned_to end,
    status = case when p_event_type = 'scrapped' then 'scrapped'::public.asset_status
                  else coalesce(p_status, status) end,
    condition = coalesce(p_condition, condition)
  where id = a.id
  returning * into a;
  return a;
end;
$$;

alter table public.pole_records enable row level security;
alter table public.assets enable row level security;
alter table public.asset_events enable row level security;

-- Pole surveys: any active user may record in their sections; the surveyor
-- or a supervisor+ may edit; managers+ delete.
grant select, delete on public.pole_records to authenticated;
grant insert (id, pole_number, section_id, feeder_name, transformer_ref, pole_type, height_m, lat, lng,
              landmark, condition, remarks, surveyed_at)
  on public.pole_records to authenticated;
grant update (pole_number, feeder_name, transformer_ref, pole_type, height_m, lat, lng, landmark,
              condition, remarks)
  on public.pole_records to authenticated;
create policy poles_read on public.pole_records for select to authenticated
  using (section_id = any ((select private.my_section_ids())::uuid[]));
create policy poles_insert on public.pole_records for insert to authenticated
  with check (surveyed_by = auth.uid() and section_id = any ((select private.my_section_ids())::uuid[]));
create policy poles_update on public.pole_records for update to authenticated
  using (section_id = any ((select private.my_section_ids())::uuid[])
         and (surveyed_by = auth.uid() or (select private.has_role('supervisor'))));
create policy poles_delete on public.pole_records for delete to authenticated
  using ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[]));

-- Assets: read in scope; managers+ register and edit descriptive fields;
-- section/assignee/status changes go through record_asset_event().
grant select on public.assets, public.asset_events to authenticated;
grant insert (id, asset_tag, category, name, serial_no, make, rating, section_id, location_text, lat, lng,
              purchase_date, purchase_value, condition, status, notes)
  on public.assets to authenticated;
grant update (name, serial_no, make, rating, location_text, lat, lng, purchase_date, purchase_value, notes)
  on public.assets to authenticated;
create policy assets_read on public.assets for select to authenticated
  using (section_id = any ((select private.my_section_ids())::uuid[]) or assigned_to = auth.uid());
create policy assets_insert on public.assets for insert to authenticated
  with check ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[]));
create policy assets_update on public.assets for update to authenticated
  using ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[]));
create policy asset_events_read on public.asset_events for select to authenticated
  using (exists (select 1 from public.assets a where a.id = asset_id));

grant execute on function public.record_asset_event(uuid, text, text, uuid, uuid, public.asset_status, public.asset_condition) to authenticated;
grant execute on all functions in schema private to authenticated, service_role;
