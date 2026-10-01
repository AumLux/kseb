-- =============================================================================
-- Inventory: material catalogue, stores, append-only stock ledger with
-- trigger-maintained balances (CHECK on_hand >= 0), and approval-driven
-- material requests (receipt / issue / return).
-- =============================================================================

create type public.stock_txn_type as enum
  ('receipt', 'issue', 'return', 'adjustment', 'transfer_in', 'transfer_out', 'scrap');
create type public.material_request_type as enum ('receipt', 'issue', 'return');
create type public.priority_level as enum ('low', 'medium', 'high', 'critical');

create table public.material_catalog (
  id uuid primary key default gen_random_uuid(),
  code text not null unique check (length(trim(code)) > 0),
  name text not null check (length(trim(name)) > 1),
  category text not null,
  unit text not null check (unit in ('nos', 'm', 'km', 'kg', 'set', 'litre', 'box', 'roll', 'pair')),
  hsn_code text,
  reorder_level numeric(14, 3) not null default 0 check (reorder_level >= 0),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
select private.track('public.material_catalog');

create table public.stores (
  id uuid primary key default gen_random_uuid(),
  section_id uuid not null references public.sections (id) on delete restrict,
  name text not null check (length(trim(name)) > 1),
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (section_id, name)
);
select private.track('public.stores');

create table public.stock_ledger (
  id bigint generated always as identity primary key,
  material_id uuid not null references public.material_catalog (id) on delete restrict,
  store_id uuid not null references public.stores (id) on delete restrict,
  qty_delta numeric(14, 3) not null check (qty_delta <> 0),
  txn_type public.stock_txn_type not null,
  unit_price numeric(14, 2) check (unit_price is null or unit_price >= 0),
  ref_table text,
  ref_id uuid,
  note text,
  actor uuid default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  check (
    (txn_type in ('receipt', 'return', 'transfer_in') and qty_delta > 0)
    or (txn_type in ('issue', 'transfer_out', 'scrap') and qty_delta < 0)
    or txn_type = 'adjustment'
  )
);
create index on public.stock_ledger (material_id, store_id, created_at desc);
create index on public.stock_ledger (ref_table, ref_id);

create table public.stock_balances (
  material_id uuid not null references public.material_catalog (id) on delete restrict,
  store_id uuid not null references public.stores (id) on delete restrict,
  on_hand numeric(14, 3) not null default 0 check (on_hand >= 0),
  updated_at timestamptz not null default now(),
  primary key (material_id, store_id)
);

create or replace function private.apply_stock_ledger()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- UPDATE first: INSERT ... ON CONFLICT would evaluate CHECK (on_hand >= 0)
  -- against the proposed row (a negative delta) before resolving the conflict.
  update public.stock_balances
     set on_hand = on_hand + new.qty_delta, updated_at = now()
   where material_id = new.material_id and store_id = new.store_id;
  if not found then
    if new.qty_delta < 0 then
      raise exception using errcode = 'P0001', hint = 'insufficient_stock',
        message = 'Not enough stock in this store for this transaction.';
    end if;
    insert into public.stock_balances as b (material_id, store_id, on_hand, updated_at)
    values (new.material_id, new.store_id, new.qty_delta, now())
    on conflict (material_id, store_id)
    do update set on_hand = b.on_hand + excluded.on_hand, updated_at = now();
  end if;
  return new;
exception when check_violation then
  raise exception using errcode = 'P0001', hint = 'insufficient_stock',
    message = 'Not enough stock in this store for this transaction.';
end;
$$;

create trigger apply_stock_ledger after insert on public.stock_ledger
  for each row execute function private.apply_stock_ledger();

-- The ledger is append-only for everyone, including the service role.
create or replace function private.ledger_immutable()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception 'stock_ledger is append-only; post a reversing adjustment instead.';
end;
$$;
create trigger ledger_immutable before update or delete on public.stock_ledger
  for each row execute function private.ledger_immutable();

create table public.material_requests (
  id uuid primary key default gen_random_uuid(),
  code text not null unique default private.next_doc_no('MR'),
  request_type public.material_request_type not null,
  material_id uuid not null references public.material_catalog (id) on delete restrict,
  store_id uuid not null references public.stores (id) on delete restrict,
  quantity numeric(14, 3) not null check (quantity > 0),
  unit_price numeric(14, 2) check (unit_price is null or unit_price >= 0),
  supplier text,
  invoice_ref text,
  worksheet_id uuid references public.worksheets (id) on delete set null,
  purpose text not null check (length(trim(purpose)) >= 3),
  priority public.priority_level not null default 'medium',
  required_by date,
  status public.request_status not null default 'pending',
  requested_by uuid not null default auth.uid() references public.profiles (id),
  decided_by uuid references public.profiles (id) on delete set null,
  decided_at timestamptz,
  decision_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (request_type <> 'receipt' or (unit_price is not null and supplier is not null))
);
create index on public.material_requests (store_id, status);
create index on public.material_requests (requested_by);
create index on public.material_requests (worksheet_id);
select private.track('public.material_requests');

create or replace function private.store_section(p_store uuid)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select section_id from public.stores where id = p_store;
$$;

-- -----------------------------------------------------------------------------
-- Workflow RPCs
-- -----------------------------------------------------------------------------
create or replace function public.decide_material_request(p_id uuid, p_approve boolean, p_note text default null)
returns public.material_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  req public.material_requests;
  delta numeric(14, 3);
  txn public.stock_txn_type;
begin
  perform private.require_active();
  -- Row lock: a concurrent or replayed approval waits here, then sees the
  -- decided status below and fails, so stock can never move twice.
  select * into req from public.material_requests where id = p_id for update;
  if not found then
    perform private.fail('not_found', 'Request not found.');
  end if;
  if not private.can_approve_for(req.requested_by)
     or not private.can_see_section(private.store_section(req.store_id)) then
    perform private.fail('forbidden', 'Only a higher authority for this store can decide this request.');
  end if;
  if req.status <> 'pending' then
    perform private.fail('already_decided', format('This request is already %s.', req.status));
  end if;
  if not p_approve and length(trim(coalesce(p_note, ''))) < 3 then
    perform private.fail('reason_required', 'Give a reason for rejecting.');
  end if;

  if p_approve then
    txn := req.request_type::text::public.stock_txn_type;
    delta := case when req.request_type = 'issue' then -req.quantity else req.quantity end;
    insert into public.stock_ledger (material_id, store_id, qty_delta, txn_type, unit_price, ref_table, ref_id, note)
    values (req.material_id, req.store_id, delta, txn, req.unit_price, 'material_requests', req.id,
            req.code || ' · ' || req.purpose);
  end if;

  update public.material_requests set
    status = case when p_approve then 'approved'::public.request_status else 'rejected' end,
    decided_by = auth.uid(), decided_at = now(), decision_note = nullif(trim(p_note), '')
  where id = p_id
  returning * into req;

  perform private.notify(
    req.requested_by,
    case when p_approve then 'Material request approved' else 'Material request rejected' end,
    req.code, '/inventory/requests/' || req.id);
  return req;
end;
$$;

create or replace function public.cancel_material_request(p_id uuid)
returns public.material_requests
language plpgsql
security definer
set search_path = ''
as $$
declare
  req public.material_requests;
begin
  update public.material_requests set status = 'cancelled'
   where id = p_id and requested_by = auth.uid() and status = 'pending'
  returning * into req;
  if not found then
    perform private.fail('not_cancellable', 'Only your own pending requests can be cancelled.');
  end if;
  return req;
end;
$$;

-- Physical-count corrections and scrap (manager+, reason mandatory).
create or replace function public.adjust_stock(
  p_material_id uuid, p_store_id uuid, p_qty_delta numeric, p_reason text, p_is_scrap boolean default false)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_active();
  if not private.has_role('manager') or not private.can_see_section(private.store_section(p_store_id)) then
    perform private.fail('forbidden', 'Only managers of this store can adjust stock.');
  end if;
  if length(trim(coalesce(p_reason, ''))) < 5 then
    perform private.fail('reason_required', 'Give a reason (at least 5 characters).');
  end if;
  if p_qty_delta = 0 or (p_is_scrap and p_qty_delta > 0) then
    perform private.fail('invalid_quantity', 'Enter a non-zero quantity (negative for scrap).');
  end if;
  insert into public.stock_ledger (material_id, store_id, qty_delta, txn_type, note)
  values (p_material_id, p_store_id, p_qty_delta,
          case when p_is_scrap then 'scrap'::public.stock_txn_type else 'adjustment' end, trim(p_reason));
end;
$$;

create or replace function public.transfer_stock(
  p_material_id uuid, p_from_store uuid, p_to_store uuid, p_qty numeric, p_note text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  ref uuid := gen_random_uuid();
begin
  perform private.require_active();
  if not private.has_role('manager')
     or not private.can_see_section(private.store_section(p_from_store))
     or not private.can_see_section(private.store_section(p_to_store)) then
    perform private.fail('forbidden', 'You need access to both stores to transfer stock.');
  end if;
  if p_from_store = p_to_store or p_qty is null or p_qty <= 0 then
    perform private.fail('invalid_quantity', 'Choose two different stores and a positive quantity.');
  end if;
  insert into public.stock_ledger (material_id, store_id, qty_delta, txn_type, ref_table, ref_id, note)
  values (p_material_id, p_from_store, -p_qty, 'transfer_out', 'transfer', ref, p_note),
         (p_material_id, p_to_store, p_qty, 'transfer_in', 'transfer', ref, p_note);
end;
$$;

-- -----------------------------------------------------------------------------
-- Read models (run as caller; RLS applies)
-- -----------------------------------------------------------------------------
create view public.stock_overview with (security_invoker = true) as
  select b.material_id, m.code as material_code, m.name as material_name, m.category, m.unit,
         m.reorder_level, b.store_id, s.name as store_name, s.section_id, b.on_hand,
         (b.on_hand <= m.reorder_level) as low_stock, b.updated_at
  from public.stock_balances b
  join public.material_catalog m on m.id = b.material_id
  join public.stores s on s.id = b.store_id;

-- Per-worksheet material reconciliation (issued minus returned).
create view public.worksheet_material_usage with (security_invoker = true) as
  select r.worksheet_id, r.material_id, m.code as material_code, m.name as material_name, m.unit,
         sum(case when r.request_type = 'issue' then r.quantity else 0 end) as issued,
         sum(case when r.request_type = 'return' then r.quantity else 0 end) as returned,
         sum(case when r.request_type = 'issue' then r.quantity
                  when r.request_type = 'return' then -r.quantity else 0 end) as net_consumed
  from public.material_requests r
  join public.material_catalog m on m.id = r.material_id
  where r.status = 'approved' and r.worksheet_id is not null
  group by r.worksheet_id, r.material_id, m.code, m.name, m.unit;

-- -----------------------------------------------------------------------------
-- RLS + grants
-- -----------------------------------------------------------------------------
alter table public.material_catalog enable row level security;
alter table public.stores enable row level security;
alter table public.stock_ledger enable row level security;
alter table public.stock_balances enable row level security;
alter table public.material_requests enable row level security;

grant select on public.material_catalog to authenticated;
grant insert (code, name, category, unit, hsn_code, reorder_level) on public.material_catalog to authenticated;
grant update (name, category, unit, hsn_code, reorder_level, active) on public.material_catalog to authenticated;
create policy catalog_read on public.material_catalog for select to authenticated
  using ((select private.my_role()) is not null);
create policy catalog_insert on public.material_catalog for insert to authenticated
  with check ((select private.has_role('manager')));
create policy catalog_update on public.material_catalog for update to authenticated
  using ((select private.has_role('manager'))) with check ((select private.has_role('manager')));

grant select on public.stores to authenticated;
grant insert (section_id, name) on public.stores to authenticated;
grant update (name, active) on public.stores to authenticated;
create policy stores_read on public.stores for select to authenticated
  using (section_id = any ((select private.my_section_ids())::uuid[]));
create policy stores_insert on public.stores for insert to authenticated
  with check ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[]));
create policy stores_update on public.stores for update to authenticated
  using ((select private.has_role('manager')) and section_id = any ((select private.my_section_ids())::uuid[]));

grant select on public.stock_ledger, public.stock_balances to authenticated;
create policy ledger_read on public.stock_ledger for select to authenticated
  using ((select private.has_role('supervisor'))
         and private.store_section(store_id) = any ((select private.my_section_ids())::uuid[]));
create policy balances_read on public.stock_balances for select to authenticated
  using (private.store_section(store_id) = any ((select private.my_section_ids())::uuid[]));

grant select on public.material_requests to authenticated;
grant insert (id, request_type, material_id, store_id, quantity, unit_price, supplier, invoice_ref,
              worksheet_id, purpose, priority, required_by)
  on public.material_requests to authenticated;
grant update (purpose, priority, required_by) on public.material_requests to authenticated;
create policy mreq_read on public.material_requests for select to authenticated
  using (requested_by = auth.uid()
         or ((select private.has_role('supervisor'))
             and private.store_section(store_id) = any ((select private.my_section_ids())::uuid[])));
create policy mreq_insert on public.material_requests for insert to authenticated
  with check (requested_by = auth.uid()
              and private.store_section(store_id) = any ((select private.my_section_ids())::uuid[]));
create policy mreq_update on public.material_requests for update to authenticated
  using (requested_by = auth.uid() and status = 'pending')
  with check (requested_by = auth.uid() and status = 'pending');

grant select on public.stock_overview, public.worksheet_material_usage to authenticated;

grant execute on function public.decide_material_request(uuid, boolean, text) to authenticated;
grant execute on function public.cancel_material_request(uuid) to authenticated;
grant execute on function public.adjust_stock(uuid, uuid, numeric, text, boolean) to authenticated;
grant execute on function public.transfer_stock(uuid, uuid, uuid, numeric, text) to authenticated;
grant execute on all functions in schema private to authenticated, service_role;
