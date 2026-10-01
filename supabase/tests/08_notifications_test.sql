begin;
\ir fixtures/org.psql
select plan(8);

-- A shared phone: W1 registers, then W2 signs in on the same device.
select tests.login('a0000000-0000-0000-0000-000000000001');
select lives_ok($$select public.register_device('fcm-token-shared-device-000000001', 'android')$$, 'W1 registers the phone');
reset role;
select tests.login('a0000000-0000-0000-0000-000000000002');
select lives_ok($$select public.register_device('fcm-token-shared-device-000000001', 'android')$$,
  'W2 takes over the same token without an error');
select is((select user_id from public.device_tokens where token = 'fcm-token-shared-device-000000001'),
  'a0000000-0000-0000-0000-000000000002'::uuid, 'the token now belongs to W2 only');
select throws_like($$select public.register_device('short', 'android')$$, '%Invalid device%', 'junk tokens are refused');
reset role;

-- Notifications insert fine even with a device registered and push unconfigured.
select lives_ok($$select private.notify('a0000000-0000-0000-0000-000000000002', 'Test', 'Body', '/home')$$,
  'push trigger never blocks the insert');

select tests.login('a0000000-0000-0000-0000-000000000002');
select is((select count(*)::integer from public.notifications where read_at is null), 1, 'one unread');
select is(public.mark_all_notifications_read(), 1, 'mark all read');
reset role;

select tests.login('a0000000-0000-0000-0000-000000000001');
select is((select count(*)::integer from public.notifications), 0, 'other users cannot see W2''s notifications');
reset role;

select * from finish();
rollback;
