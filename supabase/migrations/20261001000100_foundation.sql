-- =============================================================================
-- AumLux foundation: org hierarchy, people, access helpers, audit, settings.
--
-- Security model (see docs/REVAMP_PLAN.md §3):
--   * Every public table has RLS enabled and NO default grants. Access is
--     granted explicitly per table and, for writes, per COLUMN. Workflow
--     columns (status, decided_by, ...) are never granted to clients; they
--     change only inside SECURITY DEFINER RPCs. This replaces the Firestore
--     "affectedKeys" checks with native Postgres privileges.
--   * Role and scope are read live from public.profiles (no JWT claims), so a
--     suspended or demoted user loses access on the next request.
--   * Role rank mirrors the client's UserRole.hierarchyLevel:
--     director 0 < coo 1 < manager 2 < supervisor 3 < staff 4 (lower = more).
-- =============================================================================

create schema if not exists private;
grant usage on schema private to authenticated, service_role;

-- Tables/functions created from here on get no implicit client grants.
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on sequences from anon, authenticated;
-- EXECUTE-to-PUBLIC is a global default; it can only be revoked globally.
alter default privileges revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from anon, authenticated;
alter default privileges in schema private revoke execute on functions from anon;

create type public.app_role as enum ('staff', 'supervisor', 'manager', 'coo', 'director');
create type public.profile_status as enum ('active', 'suspended', 'exited');

-- -----------------------------------------------------------------------------
-- Generic triggers
-- -----------------------------------------------------------------------------
create or replace function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Org hierarchy (KSEB): circle → division → sub-division → section → team
-- -----------------------------------------------------------------------------
create table public.circles (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (length(trim(code)) > 0),
  name text not null check (length(trim(name)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.divisions (
  id uuid primary key default gen_random_uuid(),
  circle_id uuid not null references public.circles (id) on delete restrict,
  code text not null unique check (length(trim(code)) > 0),
  name text not null check (length(trim(name)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.subdivisions (
  id uuid primary key default gen_random_uuid(),
  division_id uuid not null references public.divisions (id) on delete restrict,
  code text not null unique check (length(trim(code)) > 0),
  name text not null check (length(trim(name)) > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.sections (
  id uuid primary key default gen_random_uuid(),
  subdivision_id uuid not null references public.subdivisions (id) on delete restrict,
  code text not null unique check (length(trim(code)) > 0),
  name text not null check (length(trim(name)) > 0),
  address text,
  lat double precision check (lat between -90 and 90),
  lng double precision check (lng between -180 and 180),
  geofence_radius_m integer not null default 300 check (geofence_radius_m between 25 and 20000),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check ((lat is null) = (lng is null))
);
create index on public.divisions (circle_id);
create index on public.subdivisions (division_id);
create index on public.sections (subdivision_id);

-- -----------------------------------------------------------------------------
-- People
-- -----------------------------------------------------------------------------
create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  employee_code text not null unique
    check (employee_code ~ '^[A-Za-z0-9][A-Za-z0-9_-]{1,31}$'),
  full_name text not null check (length(trim(full_name)) > 1),
  email text check (email is null or email ~* '^[^@\s]+@[^@\s]+\.[^@\s]+$'),
  phone text unique check (phone is null or phone ~ '^\+?[0-9]{10,15}$'),
  role public.app_role not null default 'staff',
  section_id uuid references public.sections (id) on delete restrict,
  team_id uuid, -- FK added after public.teams exists
  dob date check (dob is null or dob > date '1940-01-01'),
  photo_path text,
  status public.profile_status not null default 'active',
  must_change_password boolean not null default true,
  joined_on date not null default current_date,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users (id) on delete set null,
  updated_at timestamptz not null default now()
);
create unique index profiles_email_key on public.profiles (lower(email)) where email is not null;
create index on public.profiles (section_id);
create index on public.profiles (team_id);

create table public.teams (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references public.sections (id) on delete restrict,
  name text not null check (length(trim(name)) > 0),
  supervisor_id uuid references public.profiles (id) on delete set null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (section_id, name)
);
create index on public.teams (supervisor_id);

alter table public.profiles
  add constraint profiles_team_id_fkey
  foreign key (team_id) references public.teams (id) on delete set null;

-- Extra sections a manager (or supervisor) covers beyond their home section.
create table public.user_sections (
  user_id uuid not null references public.profiles (id) on delete cascade,
  section_id uuid not null references public.sections (id) on delete cascade,
  primary key (user_id, section_id)
);

-- -----------------------------------------------------------------------------
-- Access helpers. SECURITY DEFINER so policies can read profiles without
-- recursing into profiles' own RLS. All are STABLE (one evaluation per
-- statement when wrapped in a scalar sub-select inside policies).
-- -----------------------------------------------------------------------------
create or replace function private.role_rank(r public.app_role)
returns integer
language sql
immutable
set search_path = ''
as $$
  select case r
    when 'director' then 0
    when 'coo' then 1
    when 'manager' then 2
    when 'supervisor' then 3
    else 4
  end;
$$;

-- Role of the calling user, or NULL when not authenticated / not active.
create or replace function private.my_role()
returns public.app_role
language sql
stable
security definer
set search_path = ''
as $$
  select p.role
  from public.profiles p
  where p.id = auth.uid() and p.status = 'active';
$$;

create or replace function private.my_rank()
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(private.role_rank(private.my_role()), 99);
$$;

create or replace function private.has_role(min_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.my_rank() <= private.role_rank(min_role);
$$;

create or replace function private.is_exec()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.my_role() in ('coo', 'director');
$$;

-- Teams the caller belongs to or supervises.
create or replace function private.my_team_ids()
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(distinct t.id), '{}')
  from public.teams t
  where private.my_role() is not null
    and (
      t.supervisor_id = auth.uid()
      or t.id = (select p.team_id from public.profiles p where p.id = auth.uid())
    );
$$;

-- Sections the caller can see: all for COO/Director; home + assigned sections
-- (+ sections of supervised teams) for everyone else. Empty when inactive.
create or replace function private.my_section_ids()
returns uuid[]
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when private.my_role() is null then '{}'::uuid[]
    when private.is_exec() then (select coalesce(array_agg(s.id), '{}') from public.sections s)
    else (
      select coalesce(array_agg(distinct x.section_id), '{}')
      from (
        select p.section_id from public.profiles p where p.id = auth.uid()
        union
        select us.section_id from public.user_sections us where us.user_id = auth.uid()
        union
        select t.section_id from public.teams t where t.supervisor_id = auth.uid()
      ) x
      where x.section_id is not null
    )
  end;
$$;

create or replace function private.can_see_section(target_section uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select target_section = any (private.my_section_ids());
$$;

-- Can the caller see this person? Self; COO/Director everyone; managers
-- everyone in their sections; supervisors their team members.
create or replace function private.can_see_user(target uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select case
    when private.my_role() is null then false
    when target = auth.uid() then true
    when private.is_exec() then true
    when private.my_role() = 'manager' then exists (
      select 1 from public.profiles p
      where p.id = target and p.section_id = any (private.my_section_ids())
    )
    when private.my_role() = 'supervisor' then exists (
      select 1 from public.profiles p
      where p.id = target and p.team_id = any (private.my_team_ids())
    )
    else false
  end;
$$;

-- Strictly higher authority is required to manage or approve someone of
-- `target_role`; a Director may manage Directors (top of the hierarchy).
create or replace function private.outranks(target_role public.app_role)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.my_role() is not null
    and (private.my_rank() < private.role_rank(target_role)
         or private.my_role() = 'director');
$$;

-- Approver check for a request raised by `requester`: strictly higher rank
-- (no self-approval, even for directors) and the requester is in scope.
create or replace function private.can_approve_for(requester uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select requester <> auth.uid()
    and private.can_see_user(requester)
    and private.my_rank() < (
      select private.role_rank(p.role) from public.profiles p where p.id = requester
    );
$$;

grant execute on all functions in schema private to authenticated, service_role;

-- Raised from RPCs: consistent, user-presentable error codes.
create or replace function private.fail(code text, message text)
returns void
language plpgsql
set search_path = ''
as $$
begin
  raise exception using errcode = 'P0001', message = message, hint = code;
end;
$$;

-- -----------------------------------------------------------------------------
-- Audit log (append-only, written by trigger only)
-- -----------------------------------------------------------------------------
create table public.audit_log (
  id bigint generated always as identity primary key,
  table_name text not null,
  row_id uuid,
  action text not null check (action in ('INSERT', 'UPDATE', 'DELETE')),
  actor uuid default auth.uid(),
  at timestamptz not null default now(),
  old_data jsonb,
  new_data jsonb
);
create index on public.audit_log (table_name, row_id);
create index on public.audit_log (at desc);

create or replace function private.audit()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  rec jsonb := case when tg_op = 'DELETE' then to_jsonb(old) else to_jsonb(new) end;
begin
  insert into public.audit_log (table_name, row_id, action, actor, old_data, new_data)
  values (
    tg_table_name,
    -- Key column: `id`, or the FK for 1:1 tables keyed by a parent (worksheet_id).
    coalesce(rec ->> 'id', rec ->> 'worksheet_id')::uuid,
    tg_op,
    auth.uid(),
    case when tg_op in ('UPDATE', 'DELETE') then to_jsonb(old) end,
    case when tg_op in ('INSERT', 'UPDATE') then to_jsonb(new) end
  );
  return coalesce(new, old);
end;
$$;

-- Helper to attach updated_at + audit triggers to a table.
create or replace function private.track(tbl regclass, with_updated_at boolean default true)
returns void
language plpgsql
set search_path = ''
as $$
begin
  if with_updated_at then
    execute format(
      'create trigger touch_updated_at before update on %s for each row execute function private.touch_updated_at()',
      tbl);
  end if;
  execute format(
    'create trigger audit after insert or update or delete on %s for each row execute function private.audit()',
    tbl);
end;
$$;

select private.track('public.circles');
select private.track('public.divisions');
select private.track('public.subdivisions');
select private.track('public.sections');
select private.track('public.teams');
select private.track('public.profiles');

-- -----------------------------------------------------------------------------
-- Settings, holidays, notifications, devices, document numbering
-- -----------------------------------------------------------------------------
create table public.app_settings (
  key text primary key,
  value jsonb not null,
  updated_at timestamptz not null default now(),
  updated_by uuid default auth.uid() references auth.users (id) on delete set null
);
create trigger touch_updated_at before update on public.app_settings
  for each row execute function private.touch_updated_at();

insert into public.app_settings (key, value) values
  ('idle_timeout_minutes', '15'),
  ('min_app_build', '1'),
  ('attendance_window', '{"start_hour": 5, "end_hour": 23}'),
  ('offline_capture_max_hours', '72'),
  ('storage_quota_alert_pct', '70');

create table public.holidays (
  id uuid primary key default gen_random_uuid(),
  holiday_date date not null,
  name text not null,
  section_id uuid references public.sections (id) on delete cascade,
  created_at timestamptz not null default now()
);
create unique index holidays_scope_key
  on public.holidays (holiday_date, coalesce(section_id, '00000000-0000-0000-0000-000000000000'));

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  body text,
  route text,
  data jsonb not null default '{}',
  read_at timestamptz,
  created_at timestamptz not null default now()
);
create index on public.notifications (user_id, created_at desc);

create table public.device_tokens (
  token text primary key,
  user_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null check (platform in ('android', 'web')),
  updated_at timestamptz not null default now()
);
create index on public.device_tokens (user_id);

create table public.doc_counters (
  prefix text not null,
  year integer not null,
  last_value integer not null default 0,
  primary key (prefix, year)
);

-- Human-readable document numbers, e.g. WS-2026-00042. Atomic per prefix/year.
create or replace function private.next_doc_no(p_prefix text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  y integer := extract(year from (now() at time zone 'Asia/Kolkata'))::integer;
  n integer;
begin
  insert into public.doc_counters (prefix, year, last_value)
  values (p_prefix, y, 1)
  on conflict (prefix, year) do update set last_value = public.doc_counters.last_value + 1
  returning last_value into n;
  return format('%s-%s-%s', p_prefix, y, lpad(n::text, 5, '0'));
end;
$$;

-- In-app notification helper used by workflow RPCs.
create or replace function private.notify(
  p_user uuid, p_title text, p_body text, p_route text, p_data jsonb default '{}')
returns void
language sql
security definer
set search_path = ''
as $$
  insert into public.notifications (user_id, title, body, route, data)
  select p_user, p_title, p_body, p_route, coalesce(p_data, '{}')
  where p_user is not null;
$$;

-- -----------------------------------------------------------------------------
-- RLS + grants
-- -----------------------------------------------------------------------------
alter table public.circles enable row level security;
alter table public.divisions enable row level security;
alter table public.subdivisions enable row level security;
alter table public.sections enable row level security;
alter table public.teams enable row level security;
alter table public.profiles enable row level security;
alter table public.user_sections enable row level security;
alter table public.audit_log enable row level security;
alter table public.app_settings enable row level security;
alter table public.holidays enable row level security;
alter table public.notifications enable row level security;
alter table public.device_tokens enable row level security;
alter table public.doc_counters enable row level security;

-- Org master data: everyone active can read (needed for pickers); only
-- COO/Director maintain the hierarchy.
grant select on public.circles, public.divisions, public.subdivisions, public.sections to authenticated;
grant insert, update on public.circles, public.divisions, public.subdivisions, public.sections to authenticated;

create policy org_read on public.circles for select to authenticated using ((select private.my_role()) is not null);
create policy org_read on public.divisions for select to authenticated using ((select private.my_role()) is not null);
create policy org_read on public.subdivisions for select to authenticated using ((select private.my_role()) is not null);
create policy org_read on public.sections for select to authenticated using ((select private.my_role()) is not null);
create policy org_write on public.circles for insert to authenticated with check ((select private.is_exec()));
create policy org_update on public.circles for update to authenticated using ((select private.is_exec())) with check ((select private.is_exec()));
create policy org_write on public.divisions for insert to authenticated with check ((select private.is_exec()));
create policy org_update on public.divisions for update to authenticated using ((select private.is_exec())) with check ((select private.is_exec()));
create policy org_write on public.subdivisions for insert to authenticated with check ((select private.is_exec()));
create policy org_update on public.subdivisions for update to authenticated using ((select private.is_exec())) with check ((select private.is_exec()));
create policy org_write on public.sections for insert to authenticated with check ((select private.is_exec()));
create policy org_update on public.sections for update to authenticated using ((select private.is_exec())) with check ((select private.is_exec()));

-- Teams: visible within section scope; managers+ manage teams in scope.
grant select, insert on public.teams to authenticated;
grant update (name, supervisor_id, active) on public.teams to authenticated;
create policy teams_read on public.teams for select to authenticated
  using (section_id = any ((select private.my_section_ids())::uuid[]));
create policy teams_insert on public.teams for insert to authenticated
  with check ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[]));
create policy teams_update on public.teams for update to authenticated
  using ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[]))
  with check ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[]));

-- Profiles: read within scope. NO client writes at all — created/changed via
-- the admin-users Edge Function (service role) or the RPCs below.
grant select on public.profiles to authenticated;
create policy profiles_read on public.profiles for select to authenticated
  using ((select private.can_see_user(id)));

-- Minimal directory (names/roles only) so approver/requester names render
-- for everyone without exposing phone, DOB or email.
create or replace function public.people_directory(p_ids uuid[] default null)
returns table (
  id uuid, full_name text, employee_code text, role public.app_role,
  section_id uuid, team_id uuid, status public.profile_status)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.full_name, p.employee_code, p.role, p.section_id, p.team_id, p.status
  from public.profiles p
  where private.my_role() is not null
    and (p_ids is null or p.id = any (p_ids))
  order by p.full_name;
$$;
grant execute on function public.people_directory(uuid[]) to authenticated;

grant select on public.user_sections to authenticated;
create policy user_sections_read on public.user_sections for select to authenticated
  using (user_id = auth.uid() or (select private.is_exec()));

-- Audit log: COO/Director read; nobody writes directly.
grant select on public.audit_log to authenticated;
create policy audit_read on public.audit_log for select to authenticated
  using ((select private.is_exec()));

-- Settings: everyone reads, COO/Director change.
grant select, insert on public.app_settings to authenticated;
grant update (value) on public.app_settings to authenticated;
create policy settings_read on public.app_settings for select to authenticated
  using ((select private.my_role()) is not null);
create policy settings_insert on public.app_settings for insert to authenticated
  with check ((select private.is_exec()));
create policy settings_update on public.app_settings for update to authenticated
  using ((select private.is_exec())) with check ((select private.is_exec()));

-- Holidays: everyone reads; managers+ maintain (section-scoped or global by exec).
grant select, insert, delete on public.holidays to authenticated;
grant update (holiday_date, name) on public.holidays to authenticated;
create policy holidays_read on public.holidays for select to authenticated
  using ((select private.my_role()) is not null);
create policy holidays_write on public.holidays for insert to authenticated
  with check ((select private.is_exec())
    or ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[])));
create policy holidays_update on public.holidays for update to authenticated
  using ((select private.is_exec())
    or ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[])));
create policy holidays_delete on public.holidays for delete to authenticated
  using ((select private.is_exec())
    or ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[])));

-- Notifications: own only; may only mark as read.
grant select, delete on public.notifications to authenticated;
grant update (read_at) on public.notifications to authenticated;
create policy notifications_own on public.notifications for select to authenticated
  using (user_id = auth.uid());
create policy notifications_mark_read on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy notifications_delete on public.notifications for delete to authenticated
  using (user_id = auth.uid());

-- Device tokens: own only.
grant select, insert, delete on public.device_tokens to authenticated;
grant update (user_id, platform, updated_at) on public.device_tokens to authenticated;
create policy device_tokens_own on public.device_tokens for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- doc_counters: no client access (used via private.next_doc_no only).

-- -----------------------------------------------------------------------------
-- Self-service RPCs
-- -----------------------------------------------------------------------------

-- The signed-in user's own profile plus derived scope, used at app start.
create or replace function public.me()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when p.id is null then null else jsonb_build_object(
    'id', p.id,
    'employee_code', p.employee_code,
    'full_name', p.full_name,
    'email', p.email,
    'phone', p.phone,
    'role', p.role,
    'status', p.status,
    'section_id', p.section_id,
    'team_id', p.team_id,
    'dob', p.dob,
    'photo_path', p.photo_path,
    'must_change_password', p.must_change_password,
    'section_ids', to_jsonb(private.my_section_ids()),
    'team_ids', to_jsonb(private.my_team_ids())
  ) end
  from (select auth.uid() as uid) u
  left join public.profiles p on p.id = u.uid;
$$;

-- Called by the client right after a successful auth.updateUser(password).
create or replace function public.mark_password_changed()
returns void
language sql
security definer
set search_path = ''
as $$
  update public.profiles set must_change_password = false where id = auth.uid();
$$;

-- Self-service edits limited to contact details.
create or replace function public.update_my_contact(p_phone text, p_email text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if private.my_role() is null then
    perform private.fail('not_active', 'Your account is not active.');
  end if;
  update public.profiles
     set phone = nullif(trim(p_phone), ''),
         email = nullif(trim(p_email), '')
   where id = auth.uid();
end;
$$;

grant execute on function public.me() to authenticated;
grant execute on function public.mark_password_changed() to authenticated;
grant execute on function public.update_my_contact(text, text) to authenticated;
