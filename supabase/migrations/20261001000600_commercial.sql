-- =============================================================================
-- Commercial pipeline (COO/Director write; Managers read):
-- tenders → deposits (EMD/SD/BG) → work orders → bills, plus correspondence
-- (Dispatch/Letter) and GST returns. Money is numeric, dates are dates.
-- Tenders are organisation-wide (the old per-user silo is gone).
-- =============================================================================

create type public.tender_status as enum ('draft', 'submitted', 'opened', 'awarded', 'lost', 'cancelled');
create type public.deposit_kind as enum ('emd', 'sd', 'bg', 'retention');
create type public.deposit_status as enum ('held', 'refund_requested', 'released', 'forfeited');
create type public.work_order_status as enum ('awarded', 'in_progress', 'completed', 'closed', 'terminated');
create type public.bill_status as enum ('submitted', 'passed', 'partially_paid', 'paid', 'rejected');

create table public.tenders (
  id uuid primary key default gen_random_uuid(),
  reference text not null unique check (length(trim(reference)) > 0),
  title text not null check (length(trim(title)) > 2),
  tender_type text,
  work_category text,
  department text not null default 'KSEB',
  section_id uuid references public.sections (id) on delete set null,
  location text,
  notice_date date,
  submission_deadline timestamptz,
  opening_date date,
  work_start_date date,
  estimate_amount numeric(14, 2) check (estimate_amount is null or estimate_amount >= 0),
  emd_amount numeric(14, 2) check (emd_amount is null or emd_amount >= 0),
  security_deposit numeric(14, 2) check (security_deposit is null or security_deposit >= 0),
  quoted_amount numeric(14, 2) check (quoted_amount is null or quoted_amount >= 0),
  contact_person text,
  contact_phone text,
  remarks text,
  status public.tender_status not null default 'draft',
  owner_id uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index on public.tenders (status, submission_deadline);
select private.track('public.tenders');

create table public.work_orders (
  id uuid primary key default gen_random_uuid(),
  wo_number text not null unique check (length(trim(wo_number)) > 0),
  agreement_no text,
  tender_id uuid references public.tenders (id) on delete set null,
  title text not null,
  section_id uuid references public.sections (id) on delete set null,
  awarded_amount numeric(14, 2) not null check (awarded_amount >= 0),
  issue_date date not null,
  due_date date,
  status public.work_order_status not null default 'awarded',
  remarks text,
  created_by uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (due_date is null or due_date >= issue_date)
);
create index on public.work_orders (status);
select private.track('public.work_orders');

alter table public.worksheets
  add constraint worksheets_work_order_id_fkey
  foreign key (work_order_id) references public.work_orders (id) on delete set null;

create table public.deposits (
  id uuid primary key default gen_random_uuid(),
  kind public.deposit_kind not null,
  tender_id uuid references public.tenders (id) on delete restrict,
  work_order_id uuid references public.work_orders (id) on delete restrict,
  amount numeric(14, 2) not null check (amount > 0),
  payment_mode text not null check (payment_mode in ('dd', 'bg', 'online', 'fdr', 'cash', 'other')),
  instrument_no text,
  bank_name text,
  deposit_date date not null,
  validity_date date,
  status public.deposit_status not null default 'held',
  released_on date,
  remarks text,
  created_by uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (tender_id is not null or work_order_id is not null),
  check (validity_date is null or validity_date >= deposit_date),
  check (status <> 'released' or released_on is not null)
);
create index on public.deposits (status, validity_date);
select private.track('public.deposits');

create table public.bills (
  id uuid primary key default gen_random_uuid(),
  invoice_no text not null unique check (length(trim(invoice_no)) > 0),
  bill_type text not null check (bill_type in ('ra', 'final', 'advance', 'other')),
  work_order_id uuid not null references public.work_orders (id) on delete restrict,
  invoice_date date not null,
  amount numeric(14, 2) not null check (amount > 0),
  tax_amount numeric(14, 2) not null default 0 check (tax_amount >= 0),
  status public.bill_status not null default 'submitted',
  passed_amount numeric(14, 2) check (passed_amount is null or passed_amount >= 0),
  paid_amount numeric(14, 2) not null default 0 check (paid_amount >= 0),
  paid_on date,
  remarks text,
  created_by uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (paid_amount <= amount + tax_amount)
);
create index on public.bills (work_order_id);
create index on public.bills (status, invoice_date);
select private.track('public.bills');

create table public.correspondence (
  id uuid primary key default gen_random_uuid(),
  ref_no text not null,
  direction text not null check (direction in ('in', 'out')),
  doc_type text not null check (doc_type in ('letter', 'notice', 'circular', 'work_order', 'other')),
  party text not null,
  subject text not null check (length(trim(subject)) > 2),
  doc_date date not null,
  tender_id uuid references public.tenders (id) on delete set null,
  work_order_id uuid references public.work_orders (id) on delete set null,
  remarks text,
  created_by uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (direction, ref_no)
);
create index on public.correspondence (doc_date desc);
select private.track('public.correspondence');

create table public.gst_returns (
  id uuid primary key default gen_random_uuid(),
  gstin text not null check (gstin ~ '^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z][1-9A-Z]Z[0-9A-Z]$'),
  legal_name text not null,
  return_type text not null check (return_type in ('GSTR-1', 'GSTR-3B', 'GSTR-9', 'other')),
  period date not null check (extract(day from period) = 1),
  taxable_value numeric(14, 2) not null default 0 check (taxable_value >= 0),
  cgst numeric(14, 2) not null default 0 check (cgst >= 0),
  sgst numeric(14, 2) not null default 0 check (sgst >= 0),
  igst numeric(14, 2) not null default 0 check (igst >= 0),
  filed_on date,
  arn text,
  remarks text,
  created_by uuid not null default auth.uid() references public.profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (gstin, return_type, period)
);
select private.track('public.gst_returns');

-- -----------------------------------------------------------------------------
-- Read models
-- -----------------------------------------------------------------------------
create view public.bill_ageing with (security_invoker = true) as
  select b.id, b.invoice_no, b.bill_type, b.work_order_id, w.wo_number, w.title as work_title,
         b.invoice_date, b.amount, b.tax_amount, (b.amount + b.tax_amount) as gross_amount,
         b.paid_amount, (b.amount + b.tax_amount - b.paid_amount) as outstanding,
         b.status,
         (current_date - b.invoice_date) as age_days,
         case
           when b.status in ('paid', 'rejected') then 'settled'
           when current_date - b.invoice_date <= 30 then '0-30'
           when current_date - b.invoice_date <= 60 then '31-60'
           when current_date - b.invoice_date <= 90 then '61-90'
           else '90+'
         end as bucket
  from public.bills b
  join public.work_orders w on w.id = b.work_order_id;

create view public.deposits_expiring with (security_invoker = true) as
  select d.*, (d.validity_date - current_date) as days_left
  from public.deposits d
  where d.status = 'held' and d.validity_date is not null
    and d.validity_date <= current_date + 30;

-- -----------------------------------------------------------------------------
-- RLS + grants: managers+ read; COO/Director write.
-- -----------------------------------------------------------------------------
-- Column-level INSERT/UPDATE grants exclude server-set ownership/audit
-- columns. (A column REVOKE after a table-level GRANT would be a no-op, so
-- the allowed columns are granted explicitly instead.)
do $$
declare
  t text;
  cols text;
begin
  foreach t in array array['tenders', 'work_orders', 'deposits', 'bills', 'correspondence', 'gst_returns'] loop
    execute format('alter table public.%I enable row level security', t);
    select string_agg(quote_ident(c.column_name), ', ' order by c.ordinal_position) into cols
      from information_schema.columns c
     where c.table_schema = 'public' and c.table_name = t
       and c.column_name not in ('owner_id', 'created_by', 'created_at', 'updated_at');
    execute format('grant select, delete on public.%I to authenticated', t);
    execute format('grant insert (%s), update (%s) on public.%I to authenticated', cols, cols, t);
    execute format(
      'create policy %I on public.%I for select to authenticated using ((select private.has_role(''manager'')))',
      t || '_read', t);
    execute format(
      'create policy %I on public.%I for insert to authenticated with check ((select private.is_exec()))',
      t || '_insert', t);
    execute format(
      'create policy %I on public.%I for update to authenticated using ((select private.is_exec())) with check ((select private.is_exec()))',
      t || '_update', t);
    execute format(
      'create policy %I on public.%I for delete to authenticated using ((select private.is_exec()))',
      t || '_delete', t);
  end loop;
end;
$$;

grant select on public.bill_ageing, public.deposits_expiring to authenticated;
