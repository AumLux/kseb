-- =============================================================================
-- Bonus ledger (client keeps it behind ENABLE_BONUS_MODULE), role dashboards,
-- the unified approvals inbox, and scheduled alert jobs (pg_cron).
-- =============================================================================

create table public.bonus_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  points integer not null default 0,
  amount numeric(12, 2) not null default 0,
  reason text not null check (length(trim(reason)) >= 5),
  status public.request_status not null default 'pending',
  requested_by uuid not null default auth.uid() references public.profiles (id),
  decided_by uuid references public.profiles (id) on delete set null,
  decided_at timestamptz,
  decision_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (points <> 0 or amount <> 0),
  check (user_id <> requested_by)
);
create index on public.bonus_ledger (user_id, status);
select private.track('public.bonus_ledger');

-- Totals are derived from approved entries; nothing is stored on profiles.
create view public.bonus_totals with (security_invoker = true) as
  select user_id, sum(points)::integer as points, sum(amount) as amount, count(*) as entries
  from public.bonus_ledger
  where status = 'approved'
  group by user_id;

create or replace function public.decide_bonus(p_id uuid, p_approve boolean, p_note text default null)
returns public.bonus_ledger
language plpgsql
security definer
set search_path = ''
as $$
declare
  b public.bonus_ledger;
begin
  perform private.require_active();
  if not private.is_exec() then
    perform private.fail('forbidden', 'Only the COO or Director can decide bonuses.');
  end if;
  select * into b from public.bonus_ledger where id = p_id for update;
  if not found then
    perform private.fail('not_found', 'Bonus entry not found.');
  end if;
  if b.user_id = auth.uid() or b.requested_by = auth.uid() then
    perform private.fail('forbidden', 'You cannot decide a bonus you raised or that is for you.');
  end if;
  if b.status <> 'pending' then
    perform private.fail('already_decided', format('This entry is already %s.', b.status));
  end if;
  update public.bonus_ledger set
    status = case when p_approve then 'approved'::public.request_status else 'rejected' end,
    decided_by = auth.uid(), decided_at = now(), decision_note = nullif(trim(p_note), '')
  where id = p_id returning * into b;
  if p_approve then
    perform private.notify(b.user_id, 'Bonus awarded', b.reason, '/bonus');
  end if;
  return b;
end;
$$;

alter table public.bonus_ledger enable row level security;
grant select on public.bonus_ledger, public.bonus_totals to authenticated;
grant insert (id, user_id, points, amount, reason) on public.bonus_ledger to authenticated;
create policy bonus_read on public.bonus_ledger for select to authenticated
  using (user_id = auth.uid() or (select private.can_see_user(user_id)) and (select private.has_role('supervisor')));
create policy bonus_insert on public.bonus_ledger for insert to authenticated
  with check (requested_by = auth.uid() and (select private.has_role('supervisor'))
              and (select private.can_approve_for(user_id)));
grant execute on function public.decide_bonus(uuid, boolean, text) to authenticated;

-- -----------------------------------------------------------------------------
-- Approvals inbox: everything the caller can decide right now.
-- -----------------------------------------------------------------------------
create or replace function public.my_approvals()
returns table (
  kind text, id uuid, code text, title text, requested_by uuid, requester_name text,
  requested_at timestamptz, priority text, route text)
language sql
stable
security definer
set search_path = ''
as $$
  select 'worksheet', w.id, w.code, w.title, w.requested_by, p.full_name,
         coalesce(w.submitted_at, w.created_at), null::text, '/work/' || w.id
  from public.worksheets w join public.profiles p on p.id = w.requested_by
  where w.status = 'submitted' and private.can_approve_for(w.requested_by)
  union all
  select 'material_request', r.id, r.code,
         initcap(r.request_type::text) || ' · ' || m.name || ' × ' || trim(to_char(r.quantity, 'FM999999990.###')) || ' ' || m.unit,
         r.requested_by, p.full_name, r.created_at, r.priority::text, '/inventory/requests/' || r.id
  from public.material_requests r
  join public.profiles p on p.id = r.requested_by
  join public.material_catalog m on m.id = r.material_id
  where r.status = 'pending' and private.can_approve_for(r.requested_by)
    and private.can_see_section(private.store_section(r.store_id))
  union all
  select 'leave', l.id, null, initcap(l.leave_type::text) || ' leave · ' || to_char(l.from_date, 'DD Mon')
         || case when l.to_date > l.from_date then ' – ' || to_char(l.to_date, 'DD Mon') else '' end,
         l.user_id, p.full_name, l.created_at, null, '/leave/' || l.id
  from public.leave_requests l join public.profiles p on p.id = l.user_id
  where l.status = 'pending' and private.can_approve_for(l.user_id)
  union all
  select 'bonus', b.id, null, b.reason, b.requested_by, p.full_name, b.created_at, null, '/bonus/' || b.id
  from public.bonus_ledger b join public.profiles p on p.id = b.user_id
  where b.status = 'pending' and private.is_exec()
    and b.user_id <> auth.uid() and b.requested_by <> auth.uid()
  order by 7 desc;
$$;
grant execute on function public.my_approvals() to authenticated;

-- -----------------------------------------------------------------------------
-- Role dashboards (scope-aware KPIs). Executes as the caller where possible.
-- -----------------------------------------------------------------------------
create or replace function public.dashboard_kpis()
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  today date := private.ist_date(now());
  result jsonb;
begin
  result := jsonb_build_object(
    'today', today,
    'my_attendance', (select to_jsonb(a) from public.attendance_days a
                       where a.user_id = auth.uid() and a.work_date = today),
    'my_month_present', (select count(*) from public.attendance_days a
                          where a.user_id = auth.uid() and a.status = 'present'
                            and a.work_date >= date_trunc('month', today)::date),
    'pending_approvals', (select count(*) from public.my_approvals()),
    'unread_notifications', (select count(*) from public.notifications n
                              where n.user_id = auth.uid() and n.read_at is null)
  );

  if private.has_role('supervisor') then
    result := result || jsonb_build_object(
      'team_present_today', (select count(*) from public.attendance_days a
                              where a.work_date = today and a.status = 'present' and a.user_id <> auth.uid()),
      'team_size', (select count(*) from public.profiles p where p.status = 'active' and p.id <> auth.uid()),
      'worksheets_in_progress', (select count(*) from public.worksheets w where w.status = 'in_progress'),
      'open_incidents', (select count(*) from public.incidents i where i.status <> 'closed'),
      'low_stock_items', (select count(*) from public.stock_overview s where s.low_stock)
    );
  end if;

  if private.has_role('manager') then
    result := result || jsonb_build_object(
      'active_work_orders', (select count(*) from public.work_orders w where w.status in ('awarded', 'in_progress')),
      'open_tenders', (select count(*) from public.tenders t where t.status in ('draft', 'submitted', 'opened')),
      'deposits_held', (select coalesce(sum(d.amount), 0) from public.deposits d where d.status = 'held'),
      'deposits_expiring_30d', (select count(*) from public.deposits_expiring),
      'receivables_outstanding', (select coalesce(sum(b.outstanding), 0) from public.bill_ageing b
                                   where b.bucket <> 'settled'),
      'receivables_over_90d', (select coalesce(sum(b.outstanding), 0) from public.bill_ageing b
                                where b.bucket = '90+')
    );
  end if;

  return result;
end;
$$;
grant execute on function public.dashboard_kpis() to authenticated;

-- -----------------------------------------------------------------------------
-- Scheduled alerts (07:30 IST daily). In-app notifications; the push
-- function (phase 10) fans these out to devices.
-- -----------------------------------------------------------------------------
create or replace function private.daily_alerts()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  r record;
begin
  -- Deposits expiring within 15 days → COO/Director.
  for r in
    select d.id, d.kind, d.amount, d.validity_date, coalesce(t.reference, w.wo_number) as ref
    from public.deposits d
    left join public.tenders t on t.id = d.tender_id
    left join public.work_orders w on w.id = d.work_order_id
    where d.status = 'held' and d.validity_date between current_date and current_date + 15
  loop
    insert into public.notifications (user_id, title, body, route, data)
    select p.id, upper(r.kind::text) || ' expiring ' || to_char(r.validity_date, 'DD Mon'),
           r.ref || ' · ₹ ' || to_char(r.amount, 'FM99,99,99,99,990.00'),
           '/commercial/deposits/' || r.id, jsonb_build_object('deposit_id', r.id)
    from public.profiles p
    where p.status = 'active' and p.role in ('coo', 'director')
      and not exists (select 1 from public.notifications n
                       where n.user_id = p.id and n.data ->> 'deposit_id' = r.id::text
                         and n.created_at > now() - interval '6 days');
  end loop;

  -- Low stock → managers covering that store's section.
  for r in
    select s.material_id, s.material_name, s.store_id, s.store_name, s.section_id, s.on_hand, s.unit
    from public.stock_overview s
    where s.low_stock and s.reorder_level > 0
  loop
    insert into public.notifications (user_id, title, body, route, data)
    select p.id, 'Low stock: ' || r.material_name,
           r.store_name || ' · ' || trim(to_char(r.on_hand, 'FM999999990.###')) || ' ' || r.unit || ' left',
           '/inventory/stock', jsonb_build_object('material_id', r.material_id, 'store_id', r.store_id)
    from public.profiles p
    where p.status = 'active' and p.role = 'manager'
      and (p.section_id = r.section_id
           or exists (select 1 from public.user_sections us where us.user_id = p.id and us.section_id = r.section_id))
      and not exists (select 1 from public.notifications n
                       where n.user_id = p.id
                         and n.data ->> 'material_id' = r.material_id::text
                         and n.data ->> 'store_id' = r.store_id::text
                         and n.created_at > now() - interval '3 days');
  end loop;

  -- Housekeeping: read notifications older than 90 days.
  delete from public.notifications where read_at is not null and read_at < now() - interval '90 days';
end;
$$;

create extension if not exists pg_cron with schema pg_catalog;
grant usage on schema cron to postgres;

select cron.schedule('aumlux-daily-alerts', '0 2 * * *', $$select private.daily_alerts()$$);

grant execute on all functions in schema private to authenticated, service_role;
