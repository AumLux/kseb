# Backend (Supabase): setup and runbook

| Environment | Project ref | Branch that deploys it |
|---|---|---|
| Staging | `dtficnziewtaplbqoofn` | `staging` |
| Production | `zjgqpyiceqofubjbevtv` | `releases` |

Both run on the Supabase **free tier**. Firebase is kept only for FCM push, which is free on Spark. Crash reports go to our own `client_errors` table, so no extra service is needed.

## Layout

```
supabase/
  config.toml            local stack + auth settings (signup disabled, 8+ char passwords)
  migrations/*.sql       schema, RLS, RPCs, triggers, jobs — applied in order
  seed.sql               sample org / Kerala fixed holidays / material catalogue (no users)
  tests/*_test.sql       pgTAP security + workflow tests (run in CI)
  functions/admin-users  account create / update / suspend / reset (service role)
  functions/push         FCM delivery for notifications (called by a DB trigger)
tools/bootstrap/         one-off: create the first Director
```

## Security model, in one paragraph

Every table has RLS and **no default grants**. Reads are scoped by the caller's live profile: staff see themselves; supervisors see their team; managers see their sections (home section plus `user_sections`); COO/Director see everything. Writes are granted **per column**, and workflow columns (`status`, `decided_by`, stock balances, the ledger, attendance) are never client-writable. They change only inside `SECURITY DEFINER` RPCs that check rank (strictly higher, no self-approval) and scope, lock rows (`FOR UPDATE`, so replays fail), and log to `audit_log`. A suspended or exited user loses access on their next request, because nothing depends on cached JWT claims. `supabase/tests/` proves these properties.

## One-time setup

1. **GitHub → Settings → Environments.** Create `staging` and `production`, each with these secrets:
   - `SUPABASE_ACCESS_TOKEN`: a personal access token from supabase.com/dashboard/account/tokens.
   - `SUPABASE_DB_PASSWORD`: that project's database password.
   - `BACKUP_PASSPHRASE` (production only): a long random passphrase for the encrypted nightly backups. Store it in the company password manager too; without it, backups can't be restored.

   Also add these **repository** secrets for Android release signing (see [Android releases](#android-releases)): `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.
2. **Supabase dashboard → Authentication → Providers → Email.** Turn off "Allow new users to sign up" and "Confirm email". The `config.toml` values only apply to the local stack.
3. Push to `staging`. The `Supabase` workflow runs the tests, applies migrations plus the sample seed, and deploys functions.
4. **Bootstrap the first Director** (once per project):
   ```powershell
   $env:SUPABASE_URL = "https://dtficnziewtaplbqoofn.supabase.co"
   $env:SUPABASE_SECRET_KEY = "<secret key from Project Settings → API Keys>"
   node tools/bootstrap/create-director.mjs --code AUM0001 --name "Full Name" --email director@company.com
   ```
   The Director signs in, sets a password, and creates everyone else in-app.

## Push notifications (optional, free)

In-app notifications (the bell, kept live by Realtime) work without any setup. To also deliver them to phones through FCM:

1. **Register the Android app.** The package is now `com.aumlux.app` (it was `com.example.kseb`), so FCM needs a matching Firebase app. Add an Android app with that package in the Firebase console, then from the repo root run:
   ```bash
   flutterfire configure --project=<firebase-project-id> --platforms=android,web
   ```
   This rewrites `lib/firebase_options.dart` and `android/app/google-services.json`. Re-add the Google Services Gradle plugin only if you need it; `firebase_options.dart` is enough for FCM. Until this is done, push initialisation fails quietly and everything else works.
2. **Firebase console → Project settings → Service accounts → Generate new private key.** Then:
   ```bash
   supabase secrets set --project-ref <ref> FCM_SERVICE_ACCOUNT="$(cat service-account.json)" PUSH_WEBHOOK_SECRET=<long random string>
   ```
3. In the SQL editor of the same project:
   ```sql
   select vault.create_secret('https://<ref>.supabase.co/functions/v1/push', 'push_function_url');
   select vault.create_secret('<the same long random string>', 'push_webhook_secret');
   ```
4. The Android app registers its FCM token after sign-in and unregisters it on sign-out. Tapping a notification opens the linked screen.

Without these secrets, the database trigger is a no-op and nothing else is affected.

## Android releases

The `Aumlux Release Cycle` workflow (`deploy-aumlux.yml`) runs as follows:

| Event | What happens |
|---|---|
| PR | `flutter analyze` and `flutter test` |
| Push to `staging` | Tests, then **two** builds from the same commit: a *staging* site (staging project) and a *production* site (production project, `--dart-define=AUMLUX_ENV=production`). Both are kept as artifacts. |
| Push to `releases` | Promotes the **production** artifact of the latest green staging run to GitHub Pages (`aumlux.simplewebsite.in`): web app at `/web/`, APK at `/downloads/aumlux.apk`. |

What ships is exactly what was tested on staging, and a staging-pointed build can never reach production (the deploy step checks `environment=production`).

**Signing.** Create the release keystore once and keep it, together with its passwords, in the company password manager. If the key is lost, installed apps can't be updated; every phone would need an uninstall.
```bash
keytool -genkeypair -v -keystore aumlux-release.jks -alias aumlux -keyalg RSA -keysize 4096 -validity 10000
base64 -w0 aumlux-release.jks   # → ANDROID_KEYSTORE_BASE64
```
Production builds that come out debug-signed fail the workflow. For a local release build, create `android/key.properties` (gitignored) with `storeFile`, `storePassword`, `keyAlias` and `keyPassword`.

**Build numbers** are `1000 + run number`, so each CI build installs over the last one. To force everyone onto a build (for example after a breaking schema change), set the minimum in the production SQL editor:
```sql
update public.app_settings set value = '1057' where key = 'min_app_build';
```
Older Android builds then show "Update required" with a download button. Unsynced outbox items stay on the phone and sync after updating. The web app is always current.

## Crash reports

Release builds send uncaught errors to `public.client_errors`: app version, platform, message, stack, signed-in user. Only the COO and Director can read them. Each session caps and de-duplicates its reports, and rows older than 60 days are purged weekly.
```sql
select created_at, app_version, platform, message from public.client_errors order by created_at desc limit 50;
```

## Accounts and sign-in

- Officers with a real email sign in with that email.
- Crew without email sign in with their **employee code**. Internally that maps to `<code>@staff.aumlux.internal`; no mail is ever sent there.
- New accounts and admin resets get a temporary password, which must be changed at first sign-in (`profiles.must_change_password`).
- Nobody is hard-deleted. *Exited* or *suspended* bans the login and keeps the history.

## Local development

Requires Docker Desktop and the Supabase CLI.

```bash
supabase start                 # full stack; prints local URL + keys
supabase db reset              # re-apply migrations + seed
supabase test db               # pgTAP suite
supabase db lint --level warning
supabase functions serve       # edge functions with hot reload
```

To add a schema change, create a new file `supabase/migrations/<timestamp>_<name>.sql` (never edit applied migrations), add or extend a pgTAP test, and add any new RPC to the grant list in `20261001000900_lockdown.sql`.

## Backups and restore

The `Supabase` workflow runs nightly at 02:00 IST. It dumps production (roles, schema, data), encrypts the dump with `BACKUP_PASSPHRASE`, and keeps it as a 30-day artifact. The same job pings both projects so the free tier never pauses.

To restore into an empty project:

```bash
gpg -d aumlux-<stamp>.tgz.gpg | tar xz
psql "$TARGET_DB_URL" -f backup/roles.sql
psql "$TARGET_DB_URL" -f backup/schema.sql
psql "$TARGET_DB_URL" -f backup/data.sql
```

Rehearse a restore into staging once before go-live, and then quarterly.

## Free-tier limits to watch

| Limit | Mitigation |
|---|---|
| 500 MB database | Plenty for this workload. Watch `audit_log` growth (prune or archive yearly). |
| 1 GB storage | Photos are compressed client-side (about 200 KB). An alert fires at 70% (`app_settings.storage_quota_alert_pct`). Fallback: Cloudflare R2 (10 GB free). |
| No automatic backups | The nightly encrypted dump above. |
| Pause after 7 idle days | Nightly keep-alive ping. |
| 2 active projects | Exactly staging + production. |
