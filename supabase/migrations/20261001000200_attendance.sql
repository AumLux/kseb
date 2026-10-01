-- =============================================================================
-- Attendance (GPS check-in/out, offline-safe), corrections, leave.
-- Clients never write attendance tables directly; every change goes through
-- the RPCs below, which enforce time windows, scope and an audit trail.
-- =============================================================================

create type public.attendance_status as enum ('present', 'absent', 'leave', 'half_day', 'holiday');
create type public.request_status as enum ('pending', 'approved', 'rejected', 'cancelled');
create type public.leave_type as enum ('casual', 'sick', 'earned', 'unpaid', 'other');

create table public.attendance_days (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  work_date date not null,
  status public.attendance_status not null default 'present',
  source text not null default 'device' check (source in ('device', 'supervisor', 'leave', 'system')),
  check_in_at timestamptz,
  check_in_lat double precision,
  check_in_lng double precision,
  check_in_accuracy_m real,
  check_in_mocked boolean not null default false,
  check_in_distance_m integer,
  check_in_outside_geofence boolean,
  check_in_request_id uuid unique,
  check_out_at timestamptz,
  check_out_lat double precision,
  check_out_lng double precision,
  check_out_accuracy_m real,
  check_out_mocked boolean not null default false,
  check_out_request_id uuid unique,
  worksheet_id uuid, -- FK added in the worksheets migration
  marked_by uuid references public.profiles (id) on delete set null,
  verified_by uuid references public.profiles (id) on delete set null,
  verified_at timestamptz,
  note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, work_date),
  check (check_out_at is null or (check_in_at is not null and check_out_at > check_in_at))
);
create index on public.attendance_days (work_date);
select private.track('public.attendance_days');

create table public.attendance_corrections (
  id uuid primary key default gen_random_uuid(),
  attendance_id uuid not null references public.attendance_days (id) on delete cascade,
  changed_by uuid not null references public.profiles (id),
  reason text not null check (length(trim(reason)) >= 5),
  before_data jsonb,
  after_data jsonb not null,
  created_at timestamptz not null default now()
);
create index on public.attendance_corrections (attendance_id);

create table public.leave_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references public.profiles (id) on delete cascade,
  from_date date not null,
  to_date date not null,
  leave_type public.leave_type not null,
  reason text not null check (length(trim(reason)) >= 3),
  status public.request_status not null default 'pending',
  decided_by uuid references public.profiles (id) on delete set null,
  decided_at timestamptz,
  decision_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (to_date >= from_date),
  check (to_date - from_date < 60)
);
create index on public.leave_requests (user_id, from_date);
create index on public.leave_requests (status);
select private.track('public.leave_requests');

-- -----------------------------------------------------------------------------
-- Helpers
-- -----------------------------------------------------------------------------
create or replace function private.ist_date(ts timestamptz)
returns date
language sql
immutable
set search_path = ''
as $$
  select (ts at time zone 'Asia/Kolkata')::date;
$$;

-- Great-circle distance in metres (haversine).
create or replace function private.distance_m(
  lat1 double precision, lng1 double precision,
  lat2 double precision, lng2 double precision)
returns double precision
language sql
immutable
set search_path = ''
as $$
  select 2 * 6371000 * asin(sqrt(
    power(sin(radians(lat2 - lat1) / 2), 2)
    + cos(radians(lat1)) * cos(radians(lat2)) * power(sin(radians(lng2 - lng1) / 2), 2)
  ));
$$;

create or replace function private.setting_int(p_key text, p_default integer)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select (value #>> '{}')::integer from public.app_settings where key = p_key), p_default);
$$;

-- Validates an (optionally offline) device capture time and attendance window.
create or replace function private.assert_capture_time(p_captured_at timestamptz)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  max_hours integer := private.setting_int('offline_capture_max_hours', 72);
  win jsonb := coalesce((select value from public.app_settings where key = 'attendance_window'),
                        '{"start_hour": 5, "end_hour": 23}');
  local_hour integer := extract(hour from (p_captured_at at time zone 'Asia/Kolkata'))::integer;
begin
  if p_captured_at is null then
    perform private.fail('invalid_time', 'Capture time is required.');
  end if;
  if p_captured_at > now() + interval '5 minutes' then
    perform private.fail('clock_ahead', 'Your phone''s clock is ahead. Set the correct time and try again.');
  end if;
  if p_captured_at < now() - make_interval(hours => max_hours) then
    perform private.fail('capture_too_old', format('Offline entries older than %s hours cannot be synced. Ask your supervisor to mark it.', max_hours));
  end if;
  if local_hour < (win ->> 'start_hour')::integer or local_hour >= (win ->> 'end_hour')::integer then
    perform private.fail('outside_window', 'Attendance can only be recorded during working hours.');
  end if;
end;
$$;

-- Distance to the nearest allowed point (home section, and optionally the
-- worksite) and whether that is outside the geofence. NULLs when no
-- coordinates are configured, so a missing section location never blocks.
create or replace function private.geofence_check(
  p_user uuid, p_lat double precision, p_lng double precision, p_worksheet uuid)
returns table (distance_m integer, outside boolean)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  best double precision;
  radius integer := 300;
  d double precision;
  r record;
begin
  if p_lat is null or p_lng is null then
    return query select null::integer, null::boolean;
    return;
  end if;

  for r in
    select s.lat, s.lng, s.geofence_radius_m as radius
    from public.profiles p join public.sections s on s.id = p.section_id
    where p.id = p_user and s.lat is not null
  loop
    d := private.distance_m(p_lat, p_lng, r.lat, r.lng);
    if best is null or d < best then best := d; radius := r.radius; end if;
  end loop;

  if p_worksheet is not null and to_regclass('public.worksheets') is not null then
    for r in execute
      'select w.lat, w.lng, s.geofence_radius_m as radius
         from public.worksheets w join public.sections s on s.id = w.section_id
        where w.id = $1 and w.lat is not null'
      using p_worksheet
    loop
      d := private.distance_m(p_lat, p_lng, r.lat, r.lng);
      if best is null or d < best then best := d; radius := r.radius; end if;
    end loop;
  end if;

  if best is null then
    return query select null::integer, null::boolean;
  else
    return query select round(best)::integer, best > radius;
  end if;
end;
$$;

create or replace function private.require_active()
returns public.app_role
language plpgsql
security definer
set search_path = ''
as $$
declare
  r public.app_role := private.my_role();
begin
  if r is null then
    perform private.fail('not_active', 'Your account is not active. Contact your supervisor.');
  end if;
  return r;
end;
$$;

-- -----------------------------------------------------------------------------
-- Check-in / check-out (device). Idempotent on the client-generated request id
-- so an offline outbox can safely retry.
-- -----------------------------------------------------------------------------
create or replace function public.check_in(
  p_request_id uuid,
  p_captured_at timestamptz,
  p_lat double precision default null,
  p_lng double precision default null,
  p_accuracy_m real default null,
  p_is_mocked boolean default false,
  p_worksheet_id uuid default null)
returns public.attendance_days
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := auth.uid();
  existing public.attendance_days;
  result public.attendance_days;
  wd date;
  geo record;
begin
  perform private.require_active();
  if p_request_id is null then
    perform private.fail('invalid_request', 'Request id is required.');
  end if;

  select * into existing from public.attendance_days where check_in_request_id = p_request_id;
  if found then
    if existing.user_id <> me then
      perform private.fail('invalid_request', 'Request id already used.');
    end if;
    return existing; -- replay of an already-synced check-in
  end if;

  perform private.assert_capture_time(p_captured_at);
  wd := private.ist_date(p_captured_at);
  select * into geo from private.geofence_check(me, p_lat, p_lng, p_worksheet_id);

  select * into existing from public.attendance_days
   where user_id = me and work_date = wd for update;

  if found then
    if existing.check_in_at is not null then
      perform private.fail('already_checked_in', 'You have already checked in today.');
    end if;
    if existing.status = 'leave' then
      perform private.fail('on_leave', 'You are on approved leave today.');
    end if;
    update public.attendance_days set
      status = 'present', source = 'device',
      check_in_at = p_captured_at, check_in_lat = p_lat, check_in_lng = p_lng,
      check_in_accuracy_m = p_accuracy_m, check_in_mocked = coalesce(p_is_mocked, false),
      check_in_distance_m = geo.distance_m, check_in_outside_geofence = geo.outside,
      check_in_request_id = p_request_id, worksheet_id = p_worksheet_id
    where id = existing.id
    returning * into result;
  else
    insert into public.attendance_days (
      user_id, work_date, status, source,
      check_in_at, check_in_lat, check_in_lng, check_in_accuracy_m, check_in_mocked,
      check_in_distance_m, check_in_outside_geofence, check_in_request_id, worksheet_id)
    values (
      me, wd, 'present', 'device',
      p_captured_at, p_lat, p_lng, p_accuracy_m, coalesce(p_is_mocked, false),
      geo.distance_m, geo.outside, p_request_id, p_worksheet_id)
    returning * into result;
  end if;

  return result;
end;
$$;

create or replace function public.check_out(
  p_request_id uuid,
  p_captured_at timestamptz,
  p_lat double precision default null,
  p_lng double precision default null,
  p_accuracy_m real default null,
  p_is_mocked boolean default false)
returns public.attendance_days
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid := auth.uid();
  existing public.attendance_days;
  result public.attendance_days;
begin
  perform private.require_active();
  if p_request_id is null then
    perform private.fail('invalid_request', 'Request id is required.');
  end if;

  select * into existing from public.attendance_days where check_out_request_id = p_request_id;
  if found then
    if existing.user_id <> me then
      perform private.fail('invalid_request', 'Request id already used.');
    end if;
    return existing;
  end if;

  perform private.assert_capture_time(p_captured_at);

  -- The open shift (allows checking out after midnight for night work).
  select * into existing from public.attendance_days
   where user_id = me
     and check_in_at is not null
     and check_out_at is null
     and check_in_at between p_captured_at - interval '20 hours' and p_captured_at
   order by check_in_at desc
   limit 1
   for update;

  if not found then
    perform private.fail('not_checked_in', 'Check in first before checking out.');
  end if;

  update public.attendance_days set
    check_out_at = p_captured_at, check_out_lat = p_lat, check_out_lng = p_lng,
    check_out_accuracy_m = p_accuracy_m, check_out_mocked = coalesce(p_is_mocked, false),
    check_out_request_id = p_request_id
  where id = existing.id
  returning * into result;

  return result;
end;
$$;

-- -----------------------------------------------------------------------------
-- Supervisor tools. All changes are logged with a mandatory reason.
-- -----------------------------------------------------------------------------
create or replace function private.assert_can_manage_user(p_user uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_active();
  if not private.can_approve_for(p_user) then
    perform private.fail('forbidden', 'You can only manage people below you in your own team or section.');
  end if;
end;
$$;

create or replace function public.mark_attendance(
  p_user_id uuid,
  p_work_date date,
  p_status public.attendance_status,
  p_reason text)
returns public.attendance_days
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing public.attendance_days;
  result public.attendance_days;
  today date := private.ist_date(now());
begin
  perform private.assert_can_manage_user(p_user_id);
  if p_work_date > today or p_work_date < today - 31 then
    perform private.fail('date_out_of_range', 'Attendance can be marked for the last 31 days only.');
  end if;
  if length(trim(coalesce(p_reason, ''))) < 5 then
    perform private.fail('reason_required', 'Give a reason (at least 5 characters).');
  end if;

  select * into existing from public.attendance_days
   where user_id = p_user_id and work_date = p_work_date for update;

  if found then
    update public.attendance_days
       set status = p_status, source = 'supervisor', marked_by = auth.uid()
     where id = existing.id
    returning * into result;
  else
    insert into public.attendance_days (user_id, work_date, status, source, marked_by)
    values (p_user_id, p_work_date, p_status, 'supervisor', auth.uid())
    returning * into result;
  end if;

  insert into public.attendance_corrections (attendance_id, changed_by, reason, before_data, after_data)
  values (result.id, auth.uid(), trim(p_reason),
          case when existing.id is null then null else to_jsonb(existing) end, to_jsonb(result));
  return result;
end;
$$;

create or replace function public.correct_attendance(
  p_attendance_id uuid,
  p_status public.attendance_status,
  p_check_in_at timestamptz,
  p_check_out_at timestamptz,
  p_reason text)
returns public.attendance_days
language plpgsql
security definer
set search_path = ''
as $$
declare
  existing public.attendance_days;
  result public.attendance_days;
begin
  select * into existing from public.attendance_days where id = p_attendance_id for update;
  if not found then
    perform private.fail('not_found', 'Attendance record not found.');
  end if;
  perform private.assert_can_manage_user(existing.user_id);
  if length(trim(coalesce(p_reason, ''))) < 5 then
    perform private.fail('reason_required', 'Give a reason (at least 5 characters).');
  end if;
  if p_check_in_at is not null and private.ist_date(p_check_in_at) <> existing.work_date then
    perform private.fail('invalid_time', 'Check-in time must be on the same day.');
  end if;

  update public.attendance_days set
    status = p_status,
    check_in_at = p_check_in_at,
    check_out_at = p_check_out_at,
    source = 'supervisor',
    marked_by = auth.uid(),
    verified_by = null,
    verified_at = null
  where id = existing.id
  returning * into result;

  insert into public.attendance_corrections (attendance_id, changed_by, reason, before_data, after_data)
  values (result.id, auth.uid(), trim(p_reason), to_jsonb(existing), to_jsonb(result));
  return result;
end;
$$;

-- Marks the given records as verified; silently skips records out of scope.
create or replace function public.verify_attendance(p_ids uuid[])
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  n integer;
begin
  perform private.require_active();
  update public.attendance_days a
     set verified_by = auth.uid(), verified_at = now()
   where a.id = any (p_ids)
     and a.verified_at is null
     and private.can_approve_for(a.user_id);
  get diagnostics n = row_count;
  return n;
end;
$$;

-- -----------------------------------------------------------------------------
-- Leave
-- -----------------------------------------------------------------------------
create or replace function public.decide_leave(p_id uuid, p_approve boolean, p_note text default null)
returns public.leave_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  req public.leave_requests;
  d date;
begin
  select * into req from public.leave_requests where id = p_id for update;
  if not found then
    perform private.fail('not_found', 'Leave request not found.');
  end if;
  perform private.assert_can_manage_user(req.user_id);
  if req.status <> 'pending' then
    perform private.fail('already_decided', format('This request is already %s.', req.status));
  end if;
  if not p_approve and length(trim(coalesce(p_note, ''))) < 3 then
    perform private.fail('reason_required', 'Give a reason for rejecting.');
  end if;

  update public.leave_requests set
    status = case when p_approve then 'approved'::public.request_status else 'rejected' end,
    decided_by = auth.uid(), decided_at = now(), decision_note = nullif(trim(p_note), '')
  where id = p_id
  returning * into req;

  if p_approve then
    for d in select generate_series(req.from_date, req.to_date, interval '1 day')::date loop
      insert into public.attendance_days (user_id, work_date, status, source, marked_by)
      values (req.user_id, d, 'leave', 'leave', auth.uid())
      on conflict (user_id, work_date) do update
        set status = 'leave', source = 'leave', marked_by = auth.uid()
        where public.attendance_days.check_in_at is null;
    end loop;
  end if;

  perform private.notify(
    req.user_id,
    case when p_approve then 'Leave approved' else 'Leave rejected' end,
    format('%s to %s', to_char(req.from_date, 'DD Mon'), to_char(req.to_date, 'DD Mon')),
    '/leave/' || req.id);
  return req;
end;
$$;

create or replace function public.cancel_leave(p_id uuid)
returns public.leave_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  req public.leave_requests;
begin
  update public.leave_requests set status = 'cancelled'
   where id = p_id and user_id = auth.uid() and status = 'pending'
  returning * into req;
  if not found then
    perform private.fail('not_cancellable', 'Only your own pending requests can be cancelled.');
  end if;
  return req;
end;
$$;

-- -----------------------------------------------------------------------------
-- Reporting: one row per person per day for a month (muster roll). Runs as
-- the caller, so RLS limits it to people in scope.
-- -----------------------------------------------------------------------------
create or replace function public.attendance_month(p_month date, p_section_id uuid default null)
returns table (
  user_id uuid, employee_code text, full_name text, role public.app_role,
  section_id uuid, team_id uuid, work_date date,
  status public.attendance_status, check_in_at timestamptz, check_out_at timestamptz,
  worked_minutes integer, outside_geofence boolean, verified boolean, is_holiday boolean)
language sql
stable
security invoker
set search_path = ''
as $$
  with days as (
    select generate_series(date_trunc('month', p_month)::date,
                           (date_trunc('month', p_month) + interval '1 month - 1 day')::date,
                           interval '1 day')::date as d
  ),
  people as (
    select p.* from public.profiles p
    where p.status = 'active'
      and (p_section_id is null or p.section_id = p_section_id)
  )
  select p.id, p.employee_code, p.full_name, p.role, p.section_id, p.team_id, days.d,
         a.status, a.check_in_at, a.check_out_at,
         case when a.check_out_at is not null
              then (extract(epoch from a.check_out_at - a.check_in_at) / 60)::integer end,
         a.check_in_outside_geofence,
         a.verified_at is not null,
         exists (select 1 from public.holidays h
                  where h.holiday_date = days.d
                    and (h.section_id is null or h.section_id = p.section_id))
  from people p
  cross join days
  left join public.attendance_days a on a.user_id = p.id and a.work_date = days.d
  order by p.full_name, days.d;
$$;

-- -----------------------------------------------------------------------------
-- RLS + grants
-- -----------------------------------------------------------------------------
alter table public.attendance_days enable row level security;
alter table public.attendance_corrections enable row level security;
alter table public.leave_requests enable row level security;

grant select on public.attendance_days, public.attendance_corrections to authenticated;
create policy attendance_read on public.attendance_days for select to authenticated
  using ((select private.can_see_user(user_id)));
create policy corrections_read on public.attendance_corrections for select to authenticated
  using (exists (select 1 from public.attendance_days a where a.id = attendance_id));

grant select on public.leave_requests to authenticated;
grant insert (id, from_date, to_date, leave_type, reason) on public.leave_requests to authenticated;
create policy leave_read on public.leave_requests for select to authenticated
  using ((select private.can_see_user(user_id)));
create policy leave_insert on public.leave_requests for insert to authenticated
  with check (user_id = auth.uid() and (select private.my_role()) is not null
              and from_date >= private.ist_date(now()) - 7);

grant execute on function public.check_in(uuid, timestamptz, double precision, double precision, real, boolean, uuid) to authenticated;
grant execute on function public.check_out(uuid, timestamptz, double precision, double precision, real, boolean) to authenticated;
grant execute on function public.mark_attendance(uuid, date, public.attendance_status, text) to authenticated;
grant execute on function public.correct_attendance(uuid, public.attendance_status, timestamptz, timestamptz, text) to authenticated;
grant execute on function public.verify_attendance(uuid[]) to authenticated;
grant execute on function public.decide_leave(uuid, boolean, text) to authenticated;
grant execute on function public.cancel_leave(uuid) to authenticated;
grant execute on function public.attendance_month(date, uuid) to authenticated;
grant execute on all functions in schema private to authenticated, service_role;
