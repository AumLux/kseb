# Testing locally

There are two ways to test, and you can use both:

| | Local stack | Staging |
|---|---|---|
| Backend | Docker on your PC (`supabase start`) | `dtficnziewtaplbqoofn.supabase.co` |
| Data | Throwaway: `db reset` wipes it | Shared with testers |
| Accounts | One per role, created by a script | You bootstrap the Director, then create the rest in-app |
| Good for | Development, role and permission checks, breaking things | Real phones in the field, client demos |

> **Can't I just add a user in the Supabase dashboard?** No. The app needs a `profiles` row (role, section, team) next to the auth user. An auth user created in the dashboard has none, so the app signs straight back out ("account not set up"). Always create the first account with the bootstrap script, and everyone else from inside the app.

## A. Local stack (recommended first)

Requires Docker Desktop (running) and the Supabase CLI.

```bash
supabase start                      # first run downloads images (a few minutes)
supabase db reset                   # schema + sample org, holidays, material catalogue
node tools/dev/local-setup.mjs      # writes env/local.json + demo accounts
```

`local-setup.mjs` refuses to run against anything but `127.0.0.1`. Re-run it after every `supabase db reset`.

### Demo accounts

Every account uses the password **`LocalTest2026y`**. These are local-only demo values; the stack is not reachable from outside your PC.

| Role | Sign in with | What to check |
|---|---|---|
| Director | `director@aumlux.test` | Everything; org setup; settings |
| COO | `coo@aumlux.test` | Approvals, commercial, KPIs |
| Manager (Kaloor section) | `manager@aumlux.test` | Sees Kaloor only; creates staff there |
| Supervisor (Kaloor Line Team) | `supervisor@aumlux.test` | Team attendance, worksheet approvals |
| Staff (Kaloor Line Team) | `AUM0301` (employee-ID login) | Check-in, worksheets, material requests |
| Staff (Aluva) | `AUM0302` | Must be invisible to the Kaloor manager and supervisor |

### Run the app

**Web (Chrome):**
```bash
flutter run -d chrome --dart-define-from-file=env/local.json
```

**Android phone over USB** (or an emulator). `adb reverse` makes the phone's `127.0.0.1:54321` reach your PC:
```bash
adb reverse tcp:54321 tcp:54321
flutter run --dart-define-from-file=env/local.json
```
Run `adb reverse` again after re-plugging the phone. Without it, sign-in fails with a network error.

**Attendance geofence.** The seeded sections sit at real Kochi coordinates with a 500 m radius, so check-ins from elsewhere are flagged *outside geofence* (by design: recorded, but marked for review). To test the happy path, sign in as the Director and change Kaloor's location under **More → Organisation**.

### Useful extras

- **Studio** (tables, auth users, logs): http://127.0.0.1:54323
- **Edge-function logs:** `supabase functions serve` in a second terminal (hot reload). Push stays off unless `supabase/functions/.env` has the FCM values (see `.env.example` there).
- **Bonus module** is on in `env/local.json`. Set `"ENABLE_BONUS_MODULE": "false"` to see the build without it.
- **Back to a clean slate:** `supabase db reset && node tools/dev/local-setup.mjs`.

## B. Staging

Staging is empty until the schema is deployed, so do this once:

1. **Deploy the schema.** Either push to the `staging` branch (CI applies the migrations; needs the GitHub secrets from [BACKEND.md](BACKEND.md#one-time-setup)) or apply it from your PC:
   ```bash
   supabase link --project-ref dtficnziewtaplbqoofn     # asks for the staging DB password
   supabase db push --include-seed
   supabase functions deploy admin-users
   supabase functions deploy push
   ```
2. **Dashboard → Authentication → Providers → Email:** turn off "Allow new users to sign up" and "Confirm email".
3. **Create the first Director.** Paste the staging secret key (Project Settings → API Keys) into `tools/bootstrap/.env.staging` (gitignored), then:
   ```bash
   node --env-file=tools/bootstrap/.env.staging tools/bootstrap/create-director.mjs --code AUM0001 --name "Your Name" --email you@example.com
   ```
   It prints a temporary password once. Remove the key from the file afterwards.
4. **Run the app against staging.** It's the default, so no env file is needed:
   ```bash
   flutter run
   ```
   Sign in as the Director, set a new password, then create managers, supervisors and crew from **More → Staff**. Each new account gets a temporary password to hand over.
