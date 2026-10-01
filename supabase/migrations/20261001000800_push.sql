-- =============================================================================
-- Notifications delivery: Realtime for the in-app inbox, device registration,
-- and an AFTER INSERT trigger that asks the `push` Edge Function to send an
-- FCM message.
--
-- Push is configured per environment through Supabase Vault (no secrets in
-- git); without these two secrets the trigger is a no-op:
--   select vault.create_secret('https://<ref>.supabase.co/functions/v1/push', 'push_function_url');
--   select vault.create_secret('<random string>', 'push_webhook_secret');
-- The same random string goes into the function's PUSH_WEBHOOK_SECRET.
-- =============================================================================

-- Live unread badge (RLS still applies to Realtime).
alter publication supabase_realtime add table public.notifications;

create extension if not exists pg_net with schema extensions;

create or replace function private.push_notification()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  fn_url text;
  secret text;
begin
  if not exists (select 1 from public.device_tokens where user_id = new.user_id) then
    return new;
  end if;
  select decrypted_secret into fn_url from vault.decrypted_secrets where name = 'push_function_url';
  select decrypted_secret into secret from vault.decrypted_secrets where name = 'push_webhook_secret';
  if fn_url is null or secret is null then
    return new; -- push not configured in this environment
  end if;
  perform net.http_post(
    url := fn_url,
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', secret),
    body := jsonb_build_object('notification_id', new.id)
  );
  return new;
exception when others then
  -- Delivery is best-effort; never fail the business transaction over it.
  return new;
end;
$$;

create trigger push_notification after insert on public.notifications
  for each row execute function private.push_notification();

-- A phone can change hands (shift handover, re-login as another user), so
-- registration re-assigns an existing token to the caller instead of
-- failing on someone else's row.
create or replace function public.register_device(p_token text, p_platform text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform private.require_active();
  if p_platform not in ('android', 'web') or length(coalesce(p_token, '')) < 20 then
    perform private.fail('invalid', 'Invalid device registration.');
  end if;
  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (p_token, auth.uid(), p_platform, now())
  on conflict (token) do update set user_id = auth.uid(), platform = excluded.platform, updated_at = now();
end;
$$;

create or replace function public.unregister_device(p_token text)
returns void
language sql
security definer
set search_path = ''
as $$
  delete from public.device_tokens where token = p_token and user_id = auth.uid();
$$;

create or replace function public.mark_all_notifications_read()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  n integer;
begin
  update public.notifications set read_at = now() where user_id = auth.uid() and read_at is null;
  get diagnostics n = row_count;
  return n;
end;
$$;
