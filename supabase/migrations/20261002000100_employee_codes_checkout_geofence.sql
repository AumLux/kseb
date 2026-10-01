-- =============================================================================
-- 1. Employee codes are generated (ADR-0003): the next free AUM0001-style code
--    is suggested by `next_employee_code()` and allocated race-free by the
--    admin-users function, which retries on a duplicate.
-- 2. Check-out records its geofence distance too (ADR-0002), so supervisors
--    can see whether a shift ended on site.
--
-- Migrations after 20261001000900_lockdown.sql grant their own RPCs: the
-- lockdown file is already applied in staging/production and is never edited.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Employee codes
-- -----------------------------------------------------------------------------
insert into public.app_settings (key, value)
values ('employee_code_format', '{"prefix": "AUM", "digits": 4}')
on conflict (key) do nothing;

-- Next code after the highest existing PREFIX<number>, zero-padded to at
-- least `digits` (it grows past that naturally: AUM9999 → AUM10000).
-- Codes that don't follow the pattern (legacy or custom) are ignored.
create or replace function private.generate_employee_code()
returns text
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  fmt jsonb := coalesce(
    (select value from public.app_settings where key = 'employee_code_format'),
    '{"prefix": "AUM", "digits": 4}');
  prefix text := upper(coalesce(fmt ->> 'prefix', 'AUM'));
  digits integer := greatest(coalesce((fmt ->> 'digits')::integer, 4), 1);
  last_n bigint;
begin
  select max(substring(upper(p.employee_code) from length(prefix) + 1)::bigint)
    into last_n
    from public.profiles p
   where upper(p.employee_code) ~ ('^' || prefix || '[0-9]{1,15}$');
  return prefix || lpad((coalesce(last_n, 0) + 1)::text, digits, '0');
end;
$$;

-- Suggestion shown on the "Add staff" form. Managers and above only (the
-- same people who may create accounts).
-- Not STABLE: it can raise via private.fail(), which is volatile.
create or replace function public.next_employee_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not private.has_role('manager') then
    perform private.fail('forbidden', 'Only managers and above can create staff.');
  end if;
  return private.generate_employee_code();
end;
$$;

grant execute on function public.next_employee_code() to authenticated;

-- -----------------------------------------------------------------------------
-- 2. Geofence at check-out
-- -----------------------------------------------------------------------------
alter table public.attendance_days
  add column if not exists check_out_distance_m integer,
  add column if not exists check_out_outside_geofence boolean;

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
  geo record;
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

  -- Same rule as check-in: nearest of home section and the day's worksite.
  select * into geo from private.geofence_check(me, p_lat, p_lng, existing.worksheet_id);

  update public.attendance_days set
    check_out_at = p_captured_at, check_out_lat = p_lat, check_out_lng = p_lng,
    check_out_accuracy_m = p_accuracy_m, check_out_mocked = coalesce(p_is_mocked, false),
    check_out_distance_m = geo.distance_m, check_out_outside_geofence = geo.outside,
    check_out_request_id = p_request_id
  where id = existing.id
  returning * into result;

  return result;
end;
$$;
