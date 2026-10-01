# AumLux production-readiness revamp plan (approved)

## Context

AumLux is a Flutter app (Android and web, about 22k lines of Dart) for a contractor that repairs and deploys KSEB distribution infrastructure: transformers, poles, conductors. It covers staff and teams, attendance, worksheets, a materials request and approval flow, tenders, and PDF/XLSX downloads. It runs on Firebase on the free Spark plan, and Firestore rules are the only backend.

A full walkthrough found that the app is not production-safe. There are security holes in the rules, broken flows, placeholder modules, hardcoded master data, debug signing, and a storage dependency that no longer works on the free plan. The client will not pay for Firebase Blaze. The aim is a production-grade, ₹0/month system with a consistent design language, built in reviewable phases.

### Decisions (agreed in Q&A)
| Topic | Decision |
|---|---|
| Design system | **Stripe** (from getdesign.md) for structure, keeping **AumLux orange #FF6B35** as the single brand accent |
| Backend | **Migrate to Supabase free tier**: Postgres, Auth, Storage, Edge Functions, pg_cron. Firebase is kept only for FCM push and Crashlytics, both free on Spark |
| Data | **Start fresh**: no Firestore data migration. The Firestore structure (`firestore.rules`, `firebase.json`) is reference only. A bootstrap script creates the first Director account, and a sample KSEB org hierarchy is seeded (editable in-app) |
| Platforms | **Android + Web** only. Android package `com.aumlux.app` |
| Org master | **KSEB hierarchy**: Circle → Division → Sub-division → Section → Team |
| Attendance | **Check-in/out with GPS**, geofence flag, supervisor verification, audited corrections |
| Offline | **Outbox**: check-in/out, worksheets and photos queue locally and sync later (Android) |
| Portal modules | **Build all 8 for real** |
| Bonus | **Rebuild on a ledger**, approved by COO/Director, and **keep behind `ENABLE_BONUS_MODULE` (off by default)** |
| New features in scope | Ops core, Commercial alerts + KPIs, Safety + Malayalam. **Asset QR labels go to the backlog** |
| Login | **Employee ID or email** plus password; temporary password with forced change on first login |
| Client architecture | **Restructure**: feature-first layout, repositories, Riverpod, go_router |
| Delivery | **Phased PRs** into `revamp/prod-ready` (branched from `releases`), then one final PR into `releases` |

---

## 1. Audit findings (the loopholes being fixed)

### Backend and database (critical)
1. **Firebase Storage is already dead on Spark.** Since 3 Feb 2026, Spark projects have no Storage access. Worksheet photos (`worksheet_screen.dart:235`) and module uploads (`portal_module_screen.dart:440`) fail.
2. **Privilege escalation.** A user can update their own `users/{uid}` and change anything except `role` and `email`: `teamId`, `bonusPoints`, `bonusAmount`, `areaCode`, `activeSessionToken` (`firestore.rules:468`).
3. **No hierarchy check on deletes.** A manager can delete a director's user doc (`firestore.rules:480`). Deleting staff only removes the Firestore doc, so the Auth login stays alive (`staff_service.dart`, `delete_staff_dialog.dart`).
4. **`StaffService.addStaff` creates profiles with random IDs** (`.add()`), so those users can never log in. Real creation runs from a manager's phone through a secondary Firebase app (`staff_form_dialog.dart:228`). If that flow fails partway, it leaves an orphaned Auth account.
5. **The approval rule for managers allows any field edit** as long as `status` or `approvedBy` is among the changed keys (`hasAny`, `firestore.rules:539`).
6. **A withdraw approval can be replayed.** The same `lastApprovedRequestId` can decrement stock repeatedly (`firestore.rules:553`). There is no stock ledger, so stock history can't be reconstructed.
7. **Bonus updates are non-atomic.** They read, modify and write the user, then add a separate bonus doc (`bonus_management_screen.dart:180`). Any creator can edit any field of their bonus doc.
8. **`auth_events` accepts unauthenticated creates with any email**, which makes it a spam and log-poisoning vector (`firestore.rules:440`).
9. **Self-attendance is likely rejected by the rule.** The rule compares the local IST midnight timestamp with `request.time.date()`, which is UTC midnight (`firestore.rules:496`). Supervisors can also back-date any user on any date with no audit.
10. **Approvals are not scoped to the org.** Any manager anywhere can approve any supervisor's request. Tenders are siloed per user (`user_tenders/{uid}`), so the COO and Director can't see each other's tenders.
11. **Data types are wrong.** Tender amounts and dates are stored as **strings**. Team membership is duplicated (`teams.members[]` and `users.teamId`) with no sync. There is no `firestore.indexes.json`, no backups, and a legacy `workers/{uid}` collection is still writable.

### App and UI
12. **The 8 portal modules are placeholders.** "Save Draft" and "Submit for Review" are `onPressed: () {}` (`portal_module_screen.dart:111`).
13. **Master data is hardcoded:** `Office A/B/C`, `Project X/Y/Z` (`worksheet_screen.dart:1090,1124`), material categories, units and locations. Public holidays are wrong for Kerala (no Onam or Vishu) and approximate (`app_constants.dart`).
14. **Submitting a worksheet calls `Navigator.pop()` on a root tab** (`worksheet_screen.dart:~296`), which pops the shell.
15. **Home "monthly hours" reads the legacy `workers/{uid}/attendance`** (`worker_home_screen.dart:~215`), so it always shows 0.
16. **The current user is looked up by email** (`getUserByEmail`) in some places and by uid in others. Changing an email breaks things.
17. **`dart:io File` and `putFile` in screens break on web**, which is a deployed target.
18. **"Forgot password" shows "coming soon"** (`login_screen.dart:386`). There is no forced first-login password change, no force-update, no crash reporting, and no localization.
19. **Release builds log PII** through `debugPrint` (`worker_home_screen.dart:140`).
20. **The 1.2k–1.6k-line god-screens query Firestore directly.** `StaffService` and `TeamService` are bypassed by the UI.

### Release and ops
21. **Android has `applicationId com.example.kseb` and is signed with the debug key** (`android/app/build.gradle.kts:48`). Version is `1.0.0+1`.
22. **CI only runs `flutter analyze`.** No tests run on PRs, there's no rules or DB testing, and `gh` isn't installed locally.

### Unused or dead code to remove
- `lib/screens/attendance_history_screen.dart`, `lib/services/team_service.dart`, and `lib/utils/design_tokens.dart`: nothing imports them.
- `firestore.rules.new`, `build_output.txt`, `stdout.txt`, `stderr.txt`, `fix_windows_build.ps1`, `fix_windows_plugins.bat`, `prepare_windows_build.bat`, `build_windows.ps1`, `WINDOWS_BUILD_FIX*.md`, and `releses.md` (duplicate of `RELEASE_PROCESS.md`).
- The `windows/`, `linux/`, `macos/` and `ios/` platform folders (Android and web only). This also discards the uncommitted generated-registrant changes in the working tree. Any of these can be regenerated later with `flutter create --platforms=...`.
- 15 stale root `*.md` docs (Firestore-era setup and migration notes) get consolidated into `docs/` (architecture, setup, runbook, release).
- `PortalModuleScreen` and `PortalModuleField` (the generic placeholder) are replaced by real feature screens.

---

## 2. Target architecture

```
Flutter (Android + Web)
 ├─ features/<feature>/{data,domain,presentation}   Riverpod + go_router (role-guarded)
 ├─ core/{design, l10n(en, ml), network, outbox(drift/SQLite), errors, logging}
 └─ supabase_flutter ──► Supabase (free)
                          ├─ Postgres: tables + RLS + SECURITY DEFINER RPCs (approvals, check-in, stock)
                          ├─ Auth: email/password, custom-access-token hook → role/section claims
                          ├─ Storage: private buckets + RLS, client-side image compression
                          ├─ Edge Functions: admin-users (create/disable/reset), push (FCM v1), export jobs
                          └─ pg_cron: EMD/BG expiry, low-stock, keep-alive, daily digest
 Firebase (Spark, free): FCM push + Crashlytics only
 GitHub Actions: analyze + test + `supabase test db` (pgTAP RLS tests) on PR; nightly pg_dump backup (encrypted artifact)
```

**Why Supabase over the alternatives:**
- **The data is relational.** Section → team → staff, material → ledger, request → approval, tender → EMD → work order → bill. Postgres gives foreign keys, `CHECK (on_hand >= 0)`, unique constraints (one attendance row per user per day), real transactions, and SQL views for reports and KPIs. In Firestore those are application conventions that rules can't fully enforce.
- **No paid functions are needed.** `SECURITY DEFINER` RPCs replace Cloud Functions for atomic approvals with locking (`SELECT … FOR UPDATE`), which kills the replay and race bugs. Edge Functions (500k invocations/month free) handle the few Admin-API operations, like creating and disabling auth users.
- **RLS is far more expressive than Firestore rules,** and it can be unit-tested with pgTAP in CI.
- **Lock-in is low:** it's plain Postgres plus SQL migrations in git.
- **The free-tier limits are manageable:**
  - 500 MB DB is plenty.
  - 1 GB Storage: images are compressed to ≈150–250 KB. If usage passes 70%, the documented fallback is Cloudflare R2 (10 GB free).
  - No automatic backups: a nightly `pg_dump` runs in GitHub Actions.
  - Pausing after 7 idle days: a pg_cron and GitHub keep-alive prevents it.
  - Exactly 2 free projects: one for **staging** and one for **prod**, which matches your v7 → staging → releases flow.

---

## 3. Database schema (Postgres)

All tables have `id uuid pk default gen_random_uuid()`, `created_at`, `created_by`, `updated_at` (trigger), and a `legacy_firebase_id` where data is migrated. A generic `audit_log` trigger records before and after on every mutable business table.

**Org and people**
- `circles`, `divisions`, `subdivisions`, `sections` (`code` unique, `lat`, `lng`, `geofence_radius_m`), `teams(section_id, supervisor_id, manager_id, active)`.
- `profiles(id = auth.users.id, employee_code unique, full_name, phone unique, email, role app_role, team_id, section_id, dob, photo_path, status {active, suspended, exited}, must_change_password, joined_on)`.
  - Team membership lives **only** in `profiles.team_id`, which removes the `members[]` duplication.
- `app_role` enum: `staff < supervisor < manager < coo < director`. The helper `role_rank()` mirrors `UserRole.hierarchyLevel`.
- **Scope rule:** staff see themselves; supervisors see their team; managers see their section(s); COO and Director see everything. This is enforced by the RLS helper `can_see(section_id, team_id, user_id)`, which reads JWT claims set by the custom-access-token hook. Claims avoid per-row profile lookups, which is the Firestore `get()` cost problem.
- `device_tokens(user_id, token, platform)`, `notifications(user_id, title, body, route, read_at)`, `app_settings(key, value jsonb)`, which holds the idle timeout, minimum app version, and storage quota alert level.

**Attendance**
- `attendance_days(user_id, work_date date, status {present, absent, leave, half_day, holiday}, check_in_at, check_in_lat, lng, accuracy_m, is_mocked, outside_geofence bool, check_out_*…, worksheet_id, captured_at (device), synced_at, verified_by, verified_at)` with **`UNIQUE(user_id, work_date)`**.
  - `work_date` is computed **server-side in `Asia/Kolkata`**, which fixes the timezone bug.
- `attendance_corrections(attendance_id, changed_by, reason NOT NULL, before jsonb, after jsonb)`. Supervisor edits only go through the RPC `correct_attendance()`.
- `holidays(date, name, scope_section_id null)`, managed by admins and seeded with Kerala state holidays.
- `leave_requests(user_id, from_date, to_date, type, reason, status, approver_id)`.
- RPCs `check_in()` and `check_out()` validate the time window, compute the geofence distance from the section or worksite point, accept an offline `captured_at` within 72h, and are idempotent through a client `request_uuid`.

**Worksheets (one lifecycle record instead of request plus copy)**
- `worksheets(code 'WS-YYYY-#####', type {project, maintenance, calamity}, section_id, project_ref (work_order_id), location_text, lat, lng, permit_book_no, description, status {draft, submitted, approved, rejected, in_progress, completed, cancelled}, requested_by, decided_by, decided_at, rejection_reason)`.
  - Today, approval copies a `worksheet_requests` doc into `worksheets`, which creates duplicate data and a drift risk. A single row with a status machine and an RPC `decide_worksheet(id, approve, reason)` is the standard pattern.
- `worksheet_crew(worksheet_id, user_id)`, `worksheet_photos(storage_path, captured_at, lat, lng)`.
- **Safety:** `permit_checklists(worksheet_id, line_clear_ref, isolation_points, earthing_done, ppe_confirmed[], supervisor_sign_at)` and `incidents(worksheet_id, severity, description, photos)`. A worksheet can't move to `in_progress` without a completed checklist.

**Inventory (ledger-based)**
- `material_catalog(code unique, name, category, unit, hsn, reorder_level, active)`.
- `stores(section_id, name)`.
- `stock_ledger` (append-only, no UPDATE or DELETE grants): `material_id, store_id, qty_delta, txn_type {receipt, issue, return, adjust, transfer_in, transfer_out, scrap}, ref_table, ref_id, unit_price, actor`.
- `stock_balances(material_id, store_id, on_hand CHECK >= 0)`, maintained by a trigger on the ledger.
- `material_requests(type {receipt, issue, return}, material_id, store_id, qty, unit_price, supplier, worksheet_id, purpose, priority, required_by, status, requested_by, decided_by…)`.
  - The RPC `decide_material_request()` locks the request and balance rows, checks approver rank and scope, writes the ledger and updates status in **one transaction**, which removes the replay and negative-stock bugs.
  - Material issue against a worksheet gives per-job reconciliation. Low stock triggers a notification through pg_cron.

**Field registers (portal modules)**
- **Polevar:** `pole_records(pole_number, feeder_name, transformer_ref, section_id, pole_type, lat, lng, landmark, remarks, photos)`.
- **Asset Details:** `assets(asset_tag unique, category {transformer, pole, conductor, meter, tool, vehicle, other}, name, serial_no, make, rating, section_id, assigned_to, purchase_date, condition, status)` plus `asset_events` (history). QR labels are in the backlog.

**Commercial (COO/Director, plus managers read-only where relevant)**
- `tenders` (org-wide, no longer per-user). Amounts are `numeric(14,2)`, dates are `date` or `timestamptz`, and `status` is one of `{draft, submitted, opened, awarded, lost, cancelled}`.
- `deposits(kind {emd, sd, bg}, tender_id, work_order_id, amount, mode, instrument_no, deposit_date, validity_date, status {held, released, forfeited})`.
- `work_orders(wo_number unique, agreement_no, tender_id, title, awarded_amount, issue_date, due_date, status, section_id)`.
- `bills(invoice_no unique, bill_type {ra, final, other}, work_order_id, invoice_date, amount, tax_amount, status {submitted, passed, paid, rejected}, paid_on, paid_amount)` with an ageing view.
- `correspondence(ref_no, direction {in, out}, doc_type, party, subject, doc_date)` for Dispatch/Letter.
- `gst_returns(gstin, legal_name, period, taxable, cgst, sgst, igst, filed_on)`.
- `attachments(owner_table, owner_id, storage_path, mime, size_bytes, uploaded_by)`, a generic file link used by every module.
- **View Details** becomes a cross-module search and reporting screen backed by SQL views.

**Bonus (flagged off)**
- `bonus_ledger(user_id, points, amount, reason, status {pending, approved, rejected}, requested_by, decided_by)` and a `bonus_totals` view. `profiles` stores no bonus totals.

**Auth audit:** the custom `auth_events` collection is dropped in favour of Supabase's built-in `auth.audit_log_entries`, with an admin view over it. Single-device login uses `signOut(scope: others)` at login, so no custom token is needed.

---

## 4. Client restructure

- `lib/core/`
  - `design/`: tokens and theme from DESIGN.md, with Inter via `google_fonts` and tabular figures.
  - `router/`: go_router with role guards and a forced password change on first login.
  - `l10n/`: ARB files for `en` and `ml`.
  - `outbox/`: drift-based. Images are stored as local files until uploaded. It retries on connectivity change and app resume, and shows a "pending sync" badge.
  - `errors/`, `logging/`: release builds drop `debugPrint`; errors go to Crashlytics.
  - `supabase/`
- `lib/features/`: `auth`, `home` (role KPI dashboard), `attendance`, `leave`, `worksheets`, `inventory`, `staff` (admin users through an Edge Function), `org` (master data), `poles`, `assets`, `tenders`, `deposits`, `work_orders`, `bills`, `correspondence`, `gst`, `reports`, `notifications`, `bonus` (flagged), `downloads`.
- **Reuse:**
  - PDF/XLSX export: `lib/utils/generated_file_actions.dart`, `generated_file_opener_*.dart`, and tender PDF/XLSX builders, refactored into `core/export/`.
  - Common widgets in `lib/components/common/`, restyled to the new tokens.
  - The `LoginRateLimiter` and `IdleTimeoutService` logic.
  - `UserRole` hierarchy semantics.
  - Existing test helpers where they still apply.
- **New packages:**
  - Backend and state: `supabase_flutter`, `flutter_riverpod`, `go_router`.
  - Offline: `drift` with `sqlite3_flutter_libs`, `connectivity_plus`.
  - Device: `geolocator`, `flutter_image_compress`.
  - Firebase (kept only for push and crash reporting): `firebase_messaging`, `firebase_crashlytics`.
  - Localization: `flutter_localizations`.
- **Removed packages:** `cloud_firestore`, `firebase_auth`, `firebase_storage`, `fake_cloud_firestore`.

---

## 5. Delivery phases

The work happens on branch `revamp/prod-ready`, created from `releases`. Each phase is one PR into that branch. Before Phase 0, the uncommitted generated-registrant changes are stashed, since those platforms are being removed.

0. **DESIGN.md + repo hygiene** (done first, as you asked).
   - Write `DESIGN.md` at the repo root: Stripe structure with the AumLux orange accent.
     - Colors:
       - Ink and surfaces: ink `#0d253d`, ink-secondary `#273951`, ink-mute `#64748d`, canvas `#ffffff`, canvas-soft `#f6f9fc`, hairline `#e3e8ee`, input hairline `#a8c3de`.
       - Brand accent: primary `#FF6B35` used for fills with `#0d253d` text, because white on orange fails AA for small text. Press color `#E64A19`.
       - Semantic: success `#1f9d55`, warning `#b86e00`, danger `#d92d4b`, info `#2563eb`.
     - Inter 400 for body and 300 for display only, because 300 is unreadable outdoors. Tabular numbers for all quantities and money.
     - Spacing 2/4/8/12/16/24/32/64; radii 4/6/8/12/16/pill. Pill buttons with a 48dp minimum touch target. Level-1 and level-2 shadows only.
     - Components: buttons, inputs, cards, tables, status chips, list rows, empty and error states, offline badge.
     - Field-use rules: contrast ≥ 4.5:1 and large tap targets.
   - Delete the unused files and platforms listed in section 1, and consolidate the docs into `docs/`.
   - Add `flutter test` to PR CI.
1. **Design system in code.** Token files under `lib/core/design/`, built from `lib/utils/app_*.dart`. ThemeData in `main.dart`. Common widgets restyled. Golden tests for the key widgets.
2. **Supabase foundation.**
   - Directory `supabase/`: `config.toml`, `migrations/*.sql` (schema, enums, RLS, RPCs, triggers, audit, views), `seed.sql` (Kerala holidays, a sample org hierarchy), and `tests/*.sql` (pgTAP coverage of every RLS policy and RPC per role).
   - Edge Functions `admin-users` (create, disable, reset password, and enforce the caller's rank) and `push` (FCM v1).
   - Custom-access-token hook, pg_cron jobs, and the nightly GitHub Actions `pg_dump` backup.
3. **Client core.** Riverpod, go_router, repositories, auth (Employee ID or email, forced password change, admin reset, idle timeout, single-session), error handling, Crashlytics, l10n scaffolding, and the outbox.
4. **Org, staff and teams.** Master-data admin screens. Staff CRUD through `admin-users`: deactivating a user disables their login; nobody is hard-deleted. Team assignment.
5. **Attendance and leave.** GPS check-in/out, geofence, offline queue, supervisor verify and correct with a reason, a calendar from the holidays table, leave requests, and the muster-roll PDF/XLSX export.
6. **Worksheets and safety.** Lifecycle, crew, photos (compressed, offline-capable), permit-to-work checklist, incidents, and approvals through the RPC.
7. **Inventory.** Catalog, stores, requests (receipt, issue, return), ledger, balances, issue against a worksheet, low-stock alerts, and a stock register export.
8. **Field registers.** Polevar and Asset Details.
9. **Commercial.** Tenders (org-wide), EMD/SD/BG with expiry alerts, work orders, bills with ageing, Dispatch/Letter, GST, View Details search, the COO/Director KPI dashboard, and Downloads rewired.
10. **Notifications and bonus.** Notification inbox, FCM push on approval events, and the bonus ledger behind `ENABLE_BONUS_MODULE`.
11. **Bootstrap (no migration).** `tools/bootstrap/` creates the first Director through the Admin API, and `supabase/seed.sql` provides the sample org hierarchy, Kerala holidays and the material catalogue. Firestore and Firebase Storage are decommissioned once production is live on Supabase.
12. **Release hardening.**
    - Android: real `applicationId` `com.aumlux.app`, release keystore through GitHub secrets, `key.properties` gitignored, R8, versioning from tags.
    - Web: `SUPABASE_URL` and `SUPABASE_ANON_KEY` passed via `--dart-define` per environment, with staging and prod projects wired into the existing `deploy-aumlux.yml`.
    - Minimum-version force-update check, privacy and permission rationale screens, and `docs/RUNBOOK.md` (backups, restore, storage quota, rotating keys).
13. **Final PR** from `revamp/prod-ready` into `releases`, after staging validation. `gh` isn't installed locally, so I'll either install it with your OK or push the branch and give you the compare URL.

**Backlog (documented, not built):** Asset QR labels and scanning, phone OTP login, a fully offline-first sync engine, iOS and desktop builds.

### Inputs required from the client (not blocking)
- A Supabase account with two projects (staging and prod), and their URL and anon key. Service-role keys go only into GitHub Secrets and Edge Function env, never into the app.
- The real KSEB circles, divisions, sections and their GPS points (a sample set is seeded until then, editable in-app).

---

## 6. Verification

- **Per PR:** `flutter analyze`, `flutter test` (repositories with mocked clients, widget and golden tests, outbox tests), and `supabase start` + `supabase test db` (pgTAP, which asserts each role can and cannot do every operation, plus RPC invariants like no negative stock, no double approval, and one attendance row per day).
- **Security checks run in CI as pgTAP tests:**
  - Staff can't change their own role, team or bonus.
  - A manager can't touch a director.
  - Out-of-scope sections are invisible.
  - Replaying an approval fails.
  - The ledger can't be updated or deleted.
- **Manual end-to-end on staging,** using the in-app browser for web and an emulator or device APK for Android, once per role (staff, supervisor, manager, COO, director):
  - Log in by Employee ID and change the forced password.
  - Check in with airplane mode on, then turn it off and confirm the sync.
  - Submit a worksheet with a photo and approve it.
  - Request a material issue, approve it, and verify the ledger and balance.
  - Create a tender, EMD, work order and bill, and check the expiry alert.
  - Export the muster roll.
  - Switch to Malayalam.
- **Bootstrap:** the bootstrap script on staging creates the first Director, who can then create the org and staff entirely in-app.
- **Release:** a signed APK installs over the old build (confirm the package-name change implication with you), the web build at `/web/` works, and the restore from a backup is rehearsed once.
