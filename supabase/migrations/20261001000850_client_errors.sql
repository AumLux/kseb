-- =============================================================================
-- Client error reports (self-hosted crash reporting on the free tier).
-- Signed-in apps may only insert; COO/Director read. Rows older than 60 days
-- are purged by the daily job.
-- =============================================================================

create table public.client_errors (
  id bigint generated always as identity primary key,
  user_id uuid default auth.uid() references public.profiles (id) on delete set null,
  app_version text not null check (length(app_version) <= 40),
  platform text not null check (platform in ('android', 'web', 'other')),
  message text not null check (length(message) <= 2000),
  stack text check (length(stack) <= 8000),
  context text check (length(context) <= 500),
  created_at timestamptz not null default now()
);
create index on public.client_errors (created_at desc);

alter table public.client_errors enable row level security;
grant select on public.client_errors to authenticated;
grant insert (app_version, platform, message, stack, context) on public.client_errors to authenticated;

create policy client_errors_insert on public.client_errors for insert to authenticated
  with check (user_id = auth.uid() and (select private.my_role()) is not null);
create policy client_errors_read on public.client_errors for select to authenticated
  using ((select private.is_exec()));

create or replace function private.purge_client_errors()
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.client_errors where created_at < now() - interval '60 days';
$$;

select cron.schedule('aumlux-purge-client-errors', '30 2 * * 0', $$select private.purge_client_errors()$$);
