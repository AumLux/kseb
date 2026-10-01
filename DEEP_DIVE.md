# AumLux: Deep Dive

> **Who this is for:** anyone (human or AI agent) picking up this codebase cold. It explains **what** AumLux is, **why** it exists, **how** every layer works (database, backend, app, design, delivery), and **how to change it safely**. Read §1–§4 for orientation. §5–§10 are the reference you'll keep coming back to. §11–§18 cover running, testing, shipping and operating it.
>
> **Source of truth:** when this document and the code disagree, the code wins. Then fix this document in the same change. Companion docs: [DESIGN.md](DESIGN.md) (design rules), [docs/BACKEND.md](docs/BACKEND.md) (ops runbook), [docs/LOCAL_TESTING.md](docs/LOCAL_TESTING.md) (local setup), [docs/RELEASE_PROCESS.md](docs/RELEASE_PROCESS.md) (branch flow), [docs/REVAMP_PLAN.md](docs/REVAMP_PLAN.md) (why things changed).

---

## Table of contents

1. [What AumLux is, and why it exists](#1-what-aumlux-is-and-why-it-exists)
2. [Who uses it: personas and roles](#2-who-uses-it-personas-and-roles)
3. [Feature tour (module by module)](#3-feature-tour-module-by-module)
4. [Architecture at a glance](#4-architecture-at-a-glance)
5. [Repository layout](#5-repository-layout)
6. [Database deep dive](#6-database-deep-dive)
7. [Security model](#7-security-model)
8. [Backend API reference (RPCs, views, edge functions)](#8-backend-api-reference)
9. [Flutter client architecture](#9-flutter-client-architecture)
10. [Design system](#10-design-system)
11. [Module internals (client ↔ server, per feature)](#11-module-internals)
12. [Offline-first behaviour](#12-offline-first-behaviour)
13. [Localisation (English + Malayalam)](#13-localisation)
14. [Testing](#14-testing)
15. [Local development](#15-local-development)
16. [CI/CD and releases](#16-cicd-and-releases)
17. [Operations](#17-operations)
18. [Recipes: how to change things safely](#18-recipes-how-to-change-things-safely)
19. [Gotchas and lessons learned](#19-gotchas-and-lessons-learned)
20. [Decision log](#20-decision-log)
21. [Backlog](#21-backlog)
22. [Glossary](#22-glossary)

---

## 1. What AumLux is, and why it exists

### 1.1 The business

The client is an **electrical contractor** that carries out repair and deployment work on the distribution network of the **Kerala State Electricity Board (KSEB)**: transformers, poles, conductors (overhead lines), service connections and meters. KSEB awards the work through **tenders**. The contractor then:

1. bids on tenders, paying an **EMD** (earnest money deposit);
2. on winning, receives a **work order** and lodges a **security deposit** or **bank guarantee**;
3. sends **line crews** to sites under KSEB **Sections** to do the physical work, under strict electrical-safety rules (**permit-to-work**, line clear, earthing);
4. issues and consumes **materials** (conductors, insulators, poles, fuses) from its stores;
5. raises **bills** (RA = running-account, final) against the work order, gets them passed and paid, and files **GST** returns.

### 1.2 The problem AumLux solves

Before AumLux, this ran on paper registers, WhatsApp and spreadsheets. There was no reliable way to know:

- who was actually on site today, and where (attendance fraud, buddy-punching);
- which jobs were running, approved, safe to start, or done;
- what material was in which store, who issued it, and for which job;
- which deposits and bank guarantees were about to expire (lost money);
- which bills were overdue, and by how long.

**AumLux** is a single operations system covering all of this: **workforce + attendance**, **worksheets with permit-to-work**, **ledger-based inventory**, **field registers** (pole survey, asset register) and the **commercial pipeline**. It runs as an **Android app** for field crews and a **web app** for the office.

### 1.3 History (why the code looks the way it does)

- **v1 (pre-revamp):** a Flutter app on **Firebase** (Firestore + Firebase Auth + Storage), package `com.example.kseb`. A production-readiness audit found security holes in the rules, broken flows, placeholder modules, hardcoded master data, debug signing, and a dependency on Firebase Storage, which requires the paid Blaze plan the client will not pay for.
- **Revamp (phases 0–12, then the UI revamp):** a full rebuild:
  - backend moved to **Supabase free tier** (Postgres + RLS + RPCs + Edge Functions); Firebase kept **only** for FCM push;
  - client restructured into **feature modules** with **Riverpod + go_router + repositories**;
  - new **design system** (Stripe structure, indigo actions, AumLux orange brand accent);
  - **offline outbox**, GPS check-in with geofence, permit-to-work, ledger inventory, commercial registers with alerts and KPIs, Malayalam, push notifications;
  - Android package renamed to **`com.aumlux.app`**, release signing and R8 added.
- **Data:** the revamp **started fresh**, with no data migration from Firestore (an explicit client decision). `supabase/seed.sql` provides a sample org, Kerala holidays and a KSEB material catalogue.

The plan and every audit finding are in [docs/REVAMP_PLAN.md](docs/REVAMP_PLAN.md). Phase-by-phase history is in `git log` (one commit per phase: `feat(<area>): phase N — …`).

### 1.4 Hard constraints that shaped every decision

| Constraint | Consequence |
|---|---|
| **₹0/month infrastructure** | Supabase free tier (500 MB DB, 1 GB storage, pauses after 7 idle days), with nightly keep-alive and encrypted backups in GitHub Actions. No Firebase Blaze. Push via FCM HTTP v1, which is free. Self-hosted crash reports (`client_errors`). |
| **Field crews: sunlight, gloves, patchy 4G, Malayalam-first** | 48dp+ tap targets, ≥ 4.5:1 contrast, body weight never below 400, offline outbox, Malayalam UI, minimal typing. |
| **Electrical safety** | A worksheet **cannot start** until the permit-to-work checklist (line clear, earthing, tested dead, toolbox talk, PPE) is signed. This is enforced in the database. |
| **Repo is public** | No secrets in git. Only *publishable* Supabase keys (safe by design, because RLS protects everything) appear in `lib/core/config/env.dart`. |
| **Two platforms only** | Android + Web. iOS and desktop runners were removed. |

---

## 2. Who uses it: personas and roles

### 2.1 Personas

| Persona | Where | Needs |
|---|---|---|
| **Line crew (`staff`)** | Outdoors, phone, often offline, often Malayalam | Check in and out in one tap; see their own jobs; request material; apply for leave |
| **Supervisor** | Site, phone | Run a team: verify attendance, approve their crew's worksheets, materials and leave |
| **Manager** | Section office, phone + web | Run one or more Sections: staff, teams, stores, stock, approvals |
| **COO / Director** | Office, web | Everything org-wide: commercial pipeline, KPIs, settings, org structure |

### 2.2 Role ladder

`app_role` enum: **`staff` < `supervisor` < `manager` < `coo` < `director`**

Rank numbers (`private.role_rank`): director **0**, coo **1**, manager **2**, supervisor **3**, staff **4**. Lower means more authority. An inactive or anonymous caller gets rank **99**.

Core rules, enforced in SQL helpers and mirrored in the `admin-users` edge function:

- **Strictly higher authority** is needed to manage or approve someone (`private.outranks`). The one exception: a **Director may manage Directors**, because they are the top of the tree.
- **No self-approval**, ever, even for Directors (`private.can_approve_for` requires `requester <> auth.uid()`).
- **Scope:**

  | Role | Sees |
  |---|---|
  | staff | themselves |
  | supervisor | their team members (teams they supervise or belong to) |
  | manager | everyone in **their sections**: home section, plus extra sections in `user_sections`, plus sections of teams they supervise |
  | coo / director | everything |

- **Status:** `profile_status` = `active | suspended | exited`. Only **active** users have a role at all (`private.my_role()` returns NULL otherwise). A suspended user is therefore locked out on their **very next request**, with no waiting for a token to expire.
- **Nobody is hard-deleted.** "Exited" bans the login and keeps the history.

### 2.3 Organisation hierarchy (mirrors KSEB)

```
Circle  (e.g. Electrical Circle, Ernakulam)
 └─ Division        (Electrical Division, Ernakulam / Aluva)
     └─ Sub-division (Kaloor / Aluva)
         └─ Section  (Electrical Section, Kaloor) ← has GPS point + geofence radius
             └─ Team (crew, led by a supervisor)
```

People belong to a home **Section** (`profiles.section_id`) and optionally a **Team** (`profiles.team_id`). Managers can cover extra sections via `user_sections`. Almost every operational record carries a `section_id`, which is how scope is enforced.

---

## 3. Feature tour (module by module)

| Module | What users do | Who |
|---|---|---|
| **Auth** | Sign in with **Employee ID or email**. A forced password change applies at first login. Progressive lockout after failed attempts. "Forgot password" explains that a superior resets it. | everyone |
| **Home** | Gradient-mesh hero with greeting; **Today** card (check-in status, live "On duty · 3h 12m", one-tap Check in); role-aware **Shortcuts**; colour-coded **KPI tiles** | everyone (KPIs vary by role) |
| **Attendance** | GPS **check-in / check-out**, with geofence distance (in and out), mock-location flag and offline capture. **Map** of where each day started and ended. Supervisors and managers get a **List | Map** team view (pins coloured inside / outside / mock). Month calendar. Supervisors see **team day**, mark absent or present, **correct** (reason required, audited), **verify** in bulk. **Muster roll export** (PDF/XLSX). | staff+ / supervisor+ |
| **Leave** | Apply (casual/sick/earned/unpaid/other), cancel while pending; superiors approve or reject | everyone / supervisor+ |
| **Holidays** | Kerala fixed-date holidays (seeded) + org/section holidays | read: all; edit: COO/Director |
| **Worksheets (Work)** | Create a job (type project/maintenance/calamity, section, location + GPS, permit book no., planned date) → submit → approve/reject → **sign permit checklist** → start → complete. Crew assignment, photos and documents, incidents. | everyone creates; supervisor+ approves |
| **Inventory** | Material **catalogue**, **stores** per section, live **stock balances**, append-only **ledger**. **Material requests** (receipt / issue / return) approved by a superior, which posts to the ledger. Adjust, scrap and transfer stock. **Stock register export.** Low-stock alerts. | everyone requests; supervisor+ sees the ledger; manager+ manages |
| **Registers** | **Polevar** (pole survey: number, feeder, transformer, type, height, GPS, condition) and **Asset register** (tag, category, make, rating, assignment, condition, status, with an event history) | section members; manager+ for assets |
| **Commercial** | Six registers: **Tenders, Deposits (EMD/SD/BG/retention), Work orders, Bills, Letters (dispatch/inward), GST returns**. A dashboard with **bill ageing** buckets and **deposits expiring**. Cross-register search. Exports. | read: manager+; write: COO/Director |
| **Approvals** | One inbox (`my_approvals()`) for worksheets, material requests, leave and bonus awaiting *me* | supervisor+ |
| **Notifications** | In-app bell (live via Realtime) + **FCM push** on Android; tapping deep-links to the record | everyone |
| **Staff & Teams** | Create, edit, suspend and exit accounts (through `admin-users`); **employee IDs generated** (AUM0001…, race-safe); section chosen through the **Circle → Division → Sub-division → Section picker**; show temporary credentials **once**; teams and supervisors | manager+ (supervisors: reset passwords for their staff) |
| **Organisation** | Circle → Division → Sub-division → Section editor; section office and geofence set by **dragging a pin on a map** with a radius slider | COO/Director |
| **Bonus** *(feature-flagged)* | Ledger of proposed and approved bonus points/amounts. Totals derive from approved entries. | supervisor+ proposes; COO/Director approve |
| **More** | Profile, sync queue, language (English/Malayalam), change password, about, sign out | everyone |
| **Ops features** | Forced app update (`min_app_build`), idle sign-out (web + supervisor+), crash reports, location-permission rationale | — |

---

## 4. Architecture at a glance

```
┌────────────────────────── Flutter app (Android + Web) ──────────────────────────┐
│  UI (features/*/presentation) ── Riverpod providers/notifiers ── repositories   │
│        │                                   │                     │              │
│   design system (lib/core/design)     outbox (offline queue)   supabase_flutter │
└───────────────────────────────────────────┼─────────────────────┼──────────────┘
                                            │ HTTPS (PostgREST,   │ Realtime (WS)
                                            ▼ Auth, Storage, RPC) ▼
┌──────────────────────────────── Supabase (free tier) ───────────────────────────┐
│ Auth (email/password; crew = <code>@staff.aumlux.internal)                      │
│ Postgres 15+: RLS on every table · column grants · SECURITY DEFINER RPCs        │
│   private.* helpers · audit_log trigger · pg_cron jobs · pg_net · Vault         │
│ Storage bucket `attachments` (private, 10 MB, jpeg/png/webp/pdf)                │
│ Edge Functions (Deno): admin-users (accounts) · push (FCM HTTP v1)              │
└──────────────────────────────────────┬──────────────────────────────────────────┘
                                       │ notifications INSERT → trigger → pg_net
                                       ▼
                         Edge Function `push` ──► FCM ──► Android phones
```

**Key ideas**

1. **The database is the backend.** Business rules live in Postgres: RLS policies, CHECK constraints, triggers and `SECURITY DEFINER` RPCs. The app is a thin client. Even a hostile client with a valid token can only do what SQL allows.
2. **Workflow columns are never client-writable.** Status, approver, balances and attendance change only inside RPCs that check rank and scope, lock rows (`FOR UPDATE`) and audit.
3. **Edge Functions only where SQL can't go:** the Auth Admin API (creating users) and outbound HTTPS to FCM.
4. **Offline by design.** Field writes go through an idempotent outbox (client-generated UUIDs and request ids), replayed FIFO when online.

**Environments**

| Env | Supabase project ref | Deployed by | App flag |
|---|---|---|---|
| Local | `supabase start` (Docker) | you | `--dart-define-from-file=env/local.json` |
| Staging | `dtficnziewtaplbqoofn` | push to `staging` | default (`AUMLUX_ENV=staging`) |
| Production | `zjgqpyiceqofubjbevtv` | push to `releases` | `--dart-define=AUMLUX_ENV=production` |

URLs and publishable keys live in `lib/core/config/env.dart`. Publishable keys are public by design; **never** put a secret or service-role key in the app.

**Tech stack**

| Layer | Tech |
|---|---|
| Client | Flutter (Dart ≥ 3.8), `flutter_riverpod` 3, `go_router` 17, `supabase_flutter` 2, `connectivity_plus`, `shared_preferences`, `uuid`, `geolocator`, `image_picker`, `file_selector`, `url_launcher`, `pdf`, `excel`, `share_plus`, `open_filex`, `path_provider`, `package_info_plus`, `intl`, `flutter_localizations`, `firebase_core` + `firebase_messaging` (push only) |
| Backend | Supabase: Postgres, PostgREST, GoTrue Auth, Storage, Realtime, Edge Functions (Deno + `npm:@supabase/supabase-js@2`), `pg_cron`, `pg_net`, Vault |
| Tests | `flutter_test`; **pgTAP** via `supabase test db` |
| CI | GitHub Actions: `Supabase` workflow (lint, pgTAP, deploy, backup) and `Aumlux Release Cycle` (analyze, test, build, Pages) |
| Hosting | GitHub Pages (`aumlux.simplewebsite.in`): web app at `/web/`, APK at `/downloads/aumlux.apk` |

---

## 5. Repository layout

```
.
├── DESIGN.md                    design system rules (tokens, components, a11y)
├── DEEP_DIVE.md                 this file
├── README.md
├── docs/
│   ├── BACKEND.md               ops runbook: setup, push, signing, backups, key rotation
│   ├── LOCAL_TESTING.md         local stack + demo accounts + staging bootstrap
│   ├── RELEASE_PROCESS.md       branch flow and what CI does
│   ├── REVAMP_PLAN.md           audit findings, target architecture, phases
│   ├── adr/                     Architecture Decision Records (maps, locations, codes, restarts, navigation)
│   ├── brand/aumlux-mark-1024.png
│   └── archive/                 Firestore-era docs (reference only)
├── lib/                         Flutter app (see §9)
│   ├── main.dart  app.dart  firebase_options.dart
│   ├── core/                    cross-cutting: config, design, errors, outbox, router, session…
│   ├── features/<module>/       data/ application/ domain/ presentation/
│   └── l10n/                    app_en.arb, app_ml.arb (+ generated localizations)
├── test/                        Flutter unit/widget tests (mirrors lib/)
├── supabase/
│   ├── config.toml              local stack config (auth settings, functions)
│   ├── migrations/*.sql         schema, RLS, RPCs, jobs — applied in filename order
│   ├── seed.sql                 sample org, Kerala holidays, material catalogue
│   ├── tests/*.sql              pgTAP suites + fixtures/org.psql
│   └── functions/
│       ├── _shared/supabase.ts  clients, CORS, HttpError, json()
│       ├── admin-users/         account lifecycle (Auth Admin API)
│       └── push/                FCM HTTP v1 delivery
├── android/                     Android runner (package com.aumlux.app)
├── web/                         web runner (index.html, manifest, icons)
├── tools/
│   ├── bootstrap/create-director.mjs   first Director on a fresh project
│   ├── dev/local-setup.mjs             local env file + demo accounts (local only)
│   ├── brand/render_icons_test.dart    renders every PNG icon from the painter
│   └── ci/build-site.sh, landing.html  CI site build (web + APK + landing page)
├── env/local.example.json       template for --dart-define-from-file
└── .github/workflows/           supabase.yml, deploy-aumlux.yml
```

---

## 6. Database deep dive

All schema lives in `supabase/migrations/`. Files apply in order:

| File | Contents |
|---|---|
| `20261001000100_foundation.sql` | enums `app_role`, `profile_status`; org tables; `profiles`, `teams`, `user_sections`; access helpers; audit; `app_settings`; `holidays`; `notifications`; `device_tokens`; `doc_counters`; `me()`, `people_directory()`, `mark_password_changed()`, `update_my_contact()` |
| `…000200_attendance.sql` | `attendance_days`, `attendance_corrections`, `leave_requests`; `check_in`/`check_out`; mark, correct and verify; leave decisions; `attendance_month()` |
| `…000300_worksheets.sql` | `worksheets`, `worksheet_crew`, `permit_checklists`, `incidents`, `attachments`; storage bucket + policies; `transition_worksheet()` etc. |
| `…000400_inventory.sql` | `material_catalog`, `stores`, `stock_ledger`, `stock_balances`, `material_requests`; ledger triggers; decisions, adjust, transfer; views `stock_overview`, `worksheet_material_usage` |
| `…000500_registers.sql` | `pole_records`, `assets`, `asset_events`; `record_asset_event()` |
| `…000600_commercial.sql` | `tenders`, `work_orders`, `deposits`, `bills`, `correspondence`, `gst_returns`; views `bill_ageing`, `deposits_expiring` |
| `…000700_bonus_dashboard_jobs.sql` | `bonus_ledger`, view `bonus_totals`, `decide_bonus()`, `my_approvals()`, `dashboard_kpis()`, daily-alerts cron |
| `…000800_push.sql` | Realtime on notifications, `push_notification` trigger (pg_net → Edge Function), `register_device` / `unregister_device`, `mark_all_notifications_read` |
| `…000850_client_errors.sql` | `client_errors` table (self-hosted crash reports) + weekly purge |
| `…000900_lockdown.sql` | Revokes all function execute rights and re-grants the public RPC list as of the first release. **Already applied in staging/production, so it is never edited**: later migrations grant their own RPCs. |
| `20261002000100_employee_codes_checkout_geofence.sql` | `app_settings.employee_code_format`; `private.generate_employee_code()` + `public.next_employee_code()`; `attendance_days.check_out_distance_m` / `check_out_outside_geofence`, computed by a replaced `check_out()` (ADR-0002, ADR-0003) |

### 6.1 Conventions used everywhere

- **Primary keys:** `uuid default gen_random_uuid()`. Many tables accept a **client-generated `id`** (granted on INSERT) so the offline outbox can replay with `ON CONFLICT DO NOTHING`. Ledger/log tables use `bigint generated always as identity`.
- **Timestamps:** `created_at`/`updated_at timestamptz not null default now()`. `updated_at` is maintained by the `touch_updated_at` trigger, installed via `private.track()`.
- **Auditing:** `private.track('public.<table>')` installs the audit trigger (`private.audit()`), which writes `INSERT/UPDATE/DELETE` with old and new JSON, the actor (`auth.uid()`) and the time to `audit_log`.
- **Money:** `numeric(14,2)`. Quantities: `numeric(14,3)`. Dates are `date`; instants are `timestamptz`.
- **Business day = IST.** `private.ist_date(ts)` converts to the Asia/Kolkata date. Attendance `work_date` uses it.
- **Validation in CHECK constraints** (lengths, regexes for employee code, phone, GSTIN; coordinate ranges; `(lat is null) = (lng is null)`).
- **Human document numbers** via `private.next_doc_no(prefix)` → `PREFIX-YYYY-00042` (`doc_counters` row per prefix and year, locked on increment). Used for `WS` (worksheets), `INC` (incidents) and `MR` (material requests).
- **Errors:** RPCs call `private.fail(code, message)`, which raises SQLSTATE `P0001` with `HINT = code`. The client maps the hint to a localised message (see §9.7). Codes are stable API.
- **Search path:** every function sets `search_path = ''` and fully qualifies names. This is security-critical for `SECURITY DEFINER`.

### 6.2 Enums

| Enum | Values |
|---|---|
| `app_role` | staff, supervisor, manager, coo, director |
| `profile_status` | active, suspended, exited |
| `attendance_status` | present, absent, leave, half_day, holiday |
| `request_status` | pending, approved, rejected, cancelled |
| `leave_type` | casual, sick, earned, unpaid, other |
| `worksheet_type` | project, maintenance, calamity |
| `worksheet_status` | draft, submitted, approved, rejected, in_progress, completed, cancelled |
| `incident_severity` | near_miss, minor, major, fatal |
| `stock_txn_type` | receipt, issue, return, adjustment, transfer_in, transfer_out, scrap |
| `material_request_type` | receipt, issue, return |
| `priority_level` | low, medium, high, critical |
| `asset_category` | transformer, pole, conductor, meter, tool, vehicle, other |
| `asset_status` | in_store, deployed, under_repair, scrapped, lost |
| `asset_condition` | new, good, fair, poor, unserviceable |
| `tender_status` | draft, submitted, opened, awarded, lost, cancelled |
| `deposit_kind` | emd, sd, bg, retention |
| `deposit_status` | held, refund_requested, released, forfeited |
| `work_order_status` | awarded, in_progress, completed, closed, terminated |
| `bill_status` | submitted, passed, partially_paid, paid, rejected |

### 6.3 Tables, by domain

Legend: **PK** primary key · **FK→** foreign key · **NN** not null · **UQ** unique · defaults after `=`.

#### Organisation and people (foundation)

**`circles`, `divisions`, `subdivisions`**: `id` PK, `code` NN UQ, `name` NN, parent FK (`circle_id` / `division_id`), timestamps.

**`sections`**: `id` PK; `subdivision_id` FK→subdivisions NN; `code` UQ; `name`; `address`; `lat`, `lng` (both or neither); `geofence_radius_m` int = 300 (25–20000); `active` = true; timestamps. Its GPS point and radius drive the attendance geofence.

**`profiles`** (1:1 with `auth.users`):

| Column | Notes |
|---|---|
| `id` | PK, FK→auth.users (cascade) |
| `employee_code` | NN UQ, `^[A-Za-z0-9][A-Za-z0-9_-]{1,31}$`; also the crew login |
| `full_name` | NN |
| `email` | optional, regex-checked |
| `phone` | UQ, `^\+?[0-9]{10,15}$` |
| `role` | `app_role` = staff |
| `section_id` | FK→sections (home section) |
| `team_id` | FK→teams |
| `dob`, `photo_path`, `joined_on` | — |
| `status` | `profile_status` = active |
| `must_change_password` | = true (forced change at first sign-in) |
| `created_by`, timestamps | — |

There are **no client INSERT/UPDATE grants**. Accounts change only through the `admin-users` function (service role) and the RPCs `mark_password_changed()` and `update_my_contact()`.

**`teams`**: `id`; `section_id` NN; `name` (UQ per section); `supervisor_id` FK→profiles; `active`. Managers create and update teams in their sections (only `name, supervisor_id, active` are updatable).

**`user_sections`**: (`user_id`, `section_id`) PK. Extra sections a manager covers.

**`audit_log`**: `id` bigint; `table_name`; `row_id`; `action` (INSERT/UPDATE/DELETE); `actor` = auth.uid(); `at`; `old_data`, `new_data` jsonb. Read by COO/Director only.

**`app_settings`** (key → jsonb) is server-controlled configuration. Seeded keys:

| Key | Default | Used by |
|---|---|---|
| `idle_timeout_minutes` | 15 | client `IdleGuard` (clamped 5–240) |
| `min_app_build` | 1 | client forced-update gate |
| `attendance_window` | `{"start_hour":5,"end_hour":23}` | `check_in`/`check_out` (IST hours) |
| `offline_capture_max_hours` | 72 | oldest offline capture accepted |
| `storage_quota_alert_pct` | 70 | storage alerting |
| `employee_code_format` | `{"prefix":"AUM","digits":4}` | generated employee IDs (ADR-0003) |

Everyone signed in reads it; COO/Director write (only `value` is updatable).

**`holidays`**: `holiday_date`, `name`, optional `section_id` (NULL = org-wide), unique per (date, scope).

**`notifications`**: `user_id`, `title`, `body`, `route` (deep link like `/work/<id>`), `data` jsonb, `read_at`. Users see, mark read and delete **their own**. Rows are only ever inserted server-side via `private.notify()`. They're published to **Realtime**.

**`device_tokens`**: `token` PK, `user_id`, `platform` (android/web), `updated_at`. Managed by `register_device` / `unregister_device`.

**`doc_counters`**: (`prefix`, `year`) PK, `last_value`.

#### Attendance and leave

**`attendance_days`**, one row per user per IST day (`unique (user_id, work_date)`):

| Column group | Columns |
|---|---|
| Identity | `id`, `user_id`, `work_date`, `status` (= present), `source` (device/supervisor/leave/system) |
| Check-in | `check_in_at`, `check_in_lat/lng`, `check_in_accuracy_m`, `check_in_mocked`, `check_in_distance_m`, `check_in_outside_geofence`, `check_in_request_id` UQ |
| Check-out | `check_out_at`, `check_out_lat/lng`, `check_out_accuracy_m`, `check_out_mocked`, `check_out_distance_m`, `check_out_outside_geofence`, `check_out_request_id` UQ |
| Context | `worksheet_id` (optional worksite), `note` |
| Supervision | `marked_by`, `verified_by`, `verified_at` |

Constraint: check-out must be after check-in. There are **no client writes**; everything goes through RPCs. A day **needs review** when the location was mocked, outside the geofence, or missing. This flag is computed in the client domain model and the supervisor UI.

**`attendance_corrections`**: `attendance_id`, `changed_by`, `reason` (≥ 5 chars), `before_data`, `after_data`. This is the immutable correction trail.

**`leave_requests`**: `user_id` = auth.uid(), `from_date`, `to_date` (≤ 60 days, not before from), `leave_type`, `reason`, `status` = pending, `decided_by`/`at`, `decision_note`. Clients may insert only `id, from_date, to_date, leave_type, reason`, and back-dating is limited to 7 days.

#### Worksheets and safety

**`worksheets`**: `id`; `code` UQ = `next_doc_no('WS')`; `work_type`; `title` (≥ 3); `section_id` NN; `work_order_id`; `location_text`; `lat/lng`; `permit_book_no`; `description`; `planned_date`; `status` = draft; `requested_by` = auth.uid(); `submitted_at`; `decided_by/at`; `decision_note`; `started_at`; `completed_at`; `completion_note`. The requester may edit only while `draft` or `rejected`, and delete only `draft`. Status changes go through `transition_worksheet()`.

**`worksheet_crew`**: (`worksheet_id`, `user_id`) PK. Set via `set_worksheet_crew()`.

**`permit_checklists`** (1:1 with worksheet): `line_clear_ref`, `line_clear_issued_by`, `isolation_points`, `earthing_done`, `tested_dead`, `toolbox_talk_done`, `ppe_confirmed text[]`, `signed_by`, `signed_at`. Signed via `sign_permit_checklist()`.

**`incidents`**: `code` = `next_doc_no('INC')`; `worksheet_id`; `section_id`; `severity`; `occurred_at` (no more than 5 minutes in the future); `description` (≥ 10); `injured_persons`; `action_taken`; `status` open/investigating/closed; `reported_by`. Managers update `status, action_taken`.

**`attachments`** (polymorphic): `owner_table`, `owner_id`, `kind` (photo/document), `storage_path` UQ (must be `<owner_table>/<owner_id>/…`), `file_name`, `mime_type` (jpeg/png/webp/pdf), `size_bytes` (≤ 10 MB), `captured_at`, `lat/lng`, `uploaded_by`. **Visibility follows the owner row** (`private.can_see_owner()` checks that the owner row is visible under *its* RLS). The uploader can delete within 24 hours; COO/Director can delete any time.

#### Inventory

**`material_catalog`**: `code` UQ; `name`; `category`; `unit` (nos, m, km, kg, set, litre, box, roll…); `hsn_code`; `reorder_level` ≥ 0; `active`. Everyone reads; manager+ writes.

**`stores`**: `section_id`, `name` (UQ per section), `active`.

**`stock_ledger`**, **append-only** (a trigger blocks UPDATE and DELETE): `material_id`, `store_id`, `qty_delta` ≠ 0, `txn_type`, `unit_price`, `ref_table`/`ref_id` (e.g. the material request), `note`, `actor`. The sign must match the type (issues, transfers out and scrap are negative).

**`stock_balances`**: (`material_id`, `store_id`) PK, `on_hand` ≥ 0. Maintained **only** by the `apply_stock_ledger` trigger. It updates first and inserts only for positive deltas, so an overdraw fails the CHECK and rolls the whole transaction back.

**`material_requests`**: `code` = `next_doc_no('MR')`; `request_type` (receipt/issue/return); `material_id`; `store_id`; `quantity` > 0; `unit_price` + `supplier` (required for receipts); `invoice_ref`; `worksheet_id` (issue against a job); `purpose`; `priority`; `required_by`; `status`; `requested_by`; decision fields. The requester may edit only `purpose, priority, required_by` while pending.

#### Registers

**`pole_records`**: `pole_number` (UQ per section); `section_id`; `feeder_name`; `transformer_ref`; `pole_type` (psc/rcc/steel_tubular/rail/wooden…); `height_m` (3–30); `lat/lng`; `landmark`; `condition` (good/leaning/damaged/replaced); `remarks`; `surveyed_at`/`by`.

**`assets`**: `asset_tag` UQ; `category`; `name`; `serial_no`; `make`; `rating`; `section_id`; `location_text`; `lat/lng`; `assigned_to`; `purchase_date`; `purchase_value`; `condition`; `status`; `notes`. The `asset_created` trigger writes the first event.

**`asset_events`**: `asset_id`, `event_type`, `note`, `from_section_id`, `to_section_id`, `assigned_to`, `status`, `condition`, `actor`. This is the history, written via `record_asset_event()`.

#### Commercial

All six tables: **manager+ read, COO/Director insert, update and delete**, with column-level grants that exclude ownership and audit columns.

| Table | Key columns |
|---|---|
| `tenders` | `reference` UQ, `title`, `tender_type`, `work_category`, `department` = 'KSEB', `section_id`, `location`, `notice_date`, `submission_deadline`, `opening_date`, `work_start_date`, `estimate_amount`, `emd_amount`, `security_deposit`, `quoted_amount`, `contact_person/phone`, `remarks`, `status`, `owner_id` |
| `work_orders` | `wo_number` UQ, `agreement_no`, `tender_id`, `title`, `section_id`, `awarded_amount`, `issue_date`, `due_date` (≥ issue), `status`, `remarks` |
| `deposits` | `kind` (emd/sd/bg/retention), `tender_id` and/or `work_order_id` (at least one), `amount` > 0, `payment_mode` (dd/bg/online/fdr/cash/other), `instrument_no`, `bank_name`, `deposit_date`, `validity_date` (≥ deposit), `status`, `released_on` (required when released) |
| `bills` | `invoice_no` UQ, `bill_type` (ra/final/advance/other), `work_order_id` NN, `invoice_date`, `amount`, `tax_amount`, `status`, `passed_amount`, `paid_amount` (≤ amount + tax), `paid_on` |
| `correspondence` | `ref_no` (UQ per direction), `direction` (in/out), `doc_type` (letter, notice, circular, work_order…), `party`, `subject`, `doc_date`, links to tender and work order |
| `gst_returns` | `gstin` (regex-validated), `legal_name`, `return_type` (GSTR-1/3B/9/other), `period` (1st of month), `taxable_value`, `cgst`, `sgst`, `igst`, `filed_on`, `arn`; UQ (gstin, type, period) |

#### Bonus, telemetry

**`bonus_ledger`**: `user_id`, `points`, `amount` (at least one non-zero), `reason` (≥ 5), `status`, `requested_by` (≠ `user_id`), decision fields. Totals come only from approved rows (view `bonus_totals`).

**`client_errors`**: `user_id` = auth.uid(), `app_version`, `platform`, `message` (≤ 2000), `stack` (≤ 8000), `context` (≤ 500), `created_at`. Signed-in users can only insert their own; COO/Director read; purged after 60 days.

### 6.4 Views (all `security_invoker = true`, so the caller's RLS applies)

| View | Purpose |
|---|---|
| `stock_overview` | Balances joined with catalogue and store, with `low_stock` = on_hand ≤ reorder_level |
| `worksheet_material_usage` | Material issued and returned per worksheet |
| `bill_ageing` | Per bill: gross, outstanding, `age_days`, `bucket` ∈ settled / 0-30 / 31-60 / 61-90 / 90+ |
| `deposits_expiring` | Held deposits with `validity_date` within 30 days, plus `days_left` |
| `bonus_totals` | Approved points and amount per user |

### 6.5 Triggers

| Trigger | Table | Does |
|---|---|---|
| `touch_updated_at` | most tables (via `private.track`) | sets `updated_at` |
| audit (via `private.track`) | most tables | writes `audit_log` |
| `apply_stock_ledger` | `stock_ledger` AFTER INSERT | updates `stock_balances` (overdraw → error) |
| `ledger_immutable` | `stock_ledger` BEFORE UPDATE/DELETE | forbids changing history |
| `asset_created` | `assets` AFTER INSERT | first `asset_events` row |
| `push_notification` | `notifications` AFTER INSERT | `pg_net` POST to the `push` Edge Function (reads Vault secrets; no-op if not configured) |

### 6.6 Scheduled jobs (pg_cron, UTC)

| Job | Schedule | Does |
|---|---|---|
| `aumlux-daily-alerts` | `0 2 * * *` (07:30 IST) | Notifies COO/Director of deposits expiring within 15 days (de-duplicated per deposit); notifies managers covering a store's section about low stock; deletes notifications read more than 90 days ago |
| `aumlux-purge-client-errors` | `30 2 * * 0` (weekly) | Deletes `client_errors` older than 60 days |

### 6.7 Storage

There is one **private** bucket, **`attachments`**: 10 MB limit, MIME types jpeg/png/webp/pdf. Object paths are `<owner_table>/<owner_id>/<uuid>.<ext>`. Storage policies require a matching `attachments` row: to read, the row must exist (and is visible to you); to upload, it must be yours; to delete, the same rule as the row. Clients fetch **signed URLs** valid for 1 hour.

### 6.8 Realtime

`public.notifications` is in the `supabase_realtime` publication. The client subscribes to `INSERT` and `UPDATE` for its own `user_id`, which keeps the bell badge live.

### 6.9 Seed data (`supabase/seed.sql`)

There are no users. Seeded data:

- an Ernakulam sample org (Circle → 2 Divisions → 2 Sub-divisions → Sections Kaloor, Edappally, Aluva, with GPS and a 500 m geofence);
- two stores;
- fixed-date Kerala holidays;
- a KSEB material catalogue (ACSR conductors, insulators, poles, fuses…).

Staging is pushed with `--include-seed`. **Production is not seeded by CI.**

---

## 7. Security model

### 7.1 Principles

1. **RLS on every table, with no default grants.** `alter default privileges … revoke` ensures new objects start closed.
2. **Column-level grants** for INSERT/UPDATE. Ownership, workflow and audit columns (`status`, `decided_by`, `requested_by`, balances…) are **never granted**. Note that a column REVOKE after a table-level GRANT is a no-op in Postgres, so we grant only the allowed columns.
3. **Workflows are RPCs** (`SECURITY DEFINER`, `search_path = ''`). They re-check role, rank and scope, lock with `SELECT … FOR UPDATE` (so double-approval races fail), write audit and notifications, and raise stable error codes.
4. **Live authorisation.** Helpers read the caller's *current* profile row, not JWT claims. Suspension, demotion and section changes take effect on the very next request, with no custom access-token hook to configure.
5. **Lockdown is the API surface.** `…000900_lockdown.sql` revokes execute on all public functions from `public, anon, authenticated`, then re-grants the explicit list in §8.1. Anonymous callers can execute nothing.
6. **Edge functions verify the caller themselves** (`verify_jwt = false` in `config.toml`, because they validate the bearer token through the caller client and apply the same rank and scope rules).

### 7.2 Helper functions (`private` schema)

| Helper | Returns |
|---|---|
| `role_rank(role)` | 0 director … 4 staff |
| `my_role()` | caller's role if **active**, else NULL |
| `my_rank()` | rank or 99 |
| `has_role(min)` | caller rank ≤ min's rank |
| `is_exec()` | COO or Director |
| `my_team_ids()` | teams the caller supervises or belongs to |
| `my_section_ids()` | all sections (exec), or home + `user_sections` + supervised teams' sections; empty when inactive |
| `can_see_section(id)` | id ∈ my sections |
| `can_see_user(id)` | self / exec / manager-in-section / supervisor-of-team |
| `outranks(role)` | strictly higher (director may manage director) |
| `can_approve_for(user)` | not self, outranks them, and in scope |
| `require_active()` | role, or `fail('not_active')` |
| `assert_can_manage_user(user)` | used by mark and correct attendance |
| `can_see_worksheet(id)`, `can_see_owner(table,id)`, `store_section(store)` | scope helpers |
| `fail(code, msg)` | raises P0001 with HINT = code |
| `notify(user, title, body, route, data)` | inserts a notification (which triggers push) |
| `next_doc_no(prefix)` | `PREFIX-YYYY-NNNNN` |
| `ist_date`, `distance_m`, `setting_int`, `assert_capture_time`, `geofence_check` | attendance utilities |

Policies call helpers as **scalar sub-selects**, `(select private.x())`, so Postgres evaluates them once per statement, not per row. Array membership uses `= any ((select private.my_section_ids())::uuid[])`. The cast avoids a `uuid = uuid[]` operator error.

### 7.3 Policy summary (who can do what, at row level)

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| org tables | any active user | exec | exec | — |
| teams | in my sections | manager+ in my sections | manager+ in my sections | — |
| profiles | `can_see_user(id)` | (edge function only) | (edge function / RPCs) | never |
| user_sections | self or exec | — | — | — |
| audit_log | exec | (trigger) | — | — |
| app_settings | any active | exec | exec | — |
| holidays | any active | exec | exec | exec |
| notifications | own | (server) | own (`read_at` only) | own |
| device_tokens | own | own | own | own |
| attendance_days | `can_see_user(user_id)` | RPC | RPC | — |
| leave_requests | `can_see_user(user_id)` | self, active, ≤ 7 days back-dated | RPC | — |
| worksheets | requester, or supervisor+ in section, or crew member | self, in my sections | requester while draft/rejected | requester while draft |
| incidents | reporter, or supervisor+ in section | reporter in my sections | manager+ in section | — |
| attachments / storage | if owner row visible | own, path matches owner | — | own < 24 h, or exec |
| material_catalog | any active | manager+ | manager+ | — |
| stores | in my sections | manager+ | manager+ | — |
| stock_ledger | supervisor+ for store's section | RPC/trigger only | never | never |
| stock_balances | store in my sections | trigger | trigger | — |
| material_requests | requester, or supervisor+ for store's section | self, store in my sections | requester while pending | — |
| pole_records | in my sections | surveyor, in my sections | surveyor or supervisor+ | manager+ |
| assets | in my sections, or assigned to me | manager+ | manager+ | — |
| commercial (6 tables) | manager+ | exec | exec | exec |
| bonus_ledger | own, or supervisor+ who can see the user | supervisor+ who can approve for the user | RPC | — |
| client_errors | exec | own | — | — |

### 7.4 Accounts and authentication

- **Supabase Auth, email + password.** Public sign-up is **disabled**: `[auth] enable_signup = false`, while `[auth.email] enable_signup = true` must stay true because it enables the email provider. Production and staging also need the dashboard toggles (see BACKEND.md).
- Password policy: min 8 characters, letters + digits (`config.toml`; mirrored client-side by `passwordMeetsPolicy`).
- **Crew without email** sign in with their **employee code**. The app maps `AUM0301` → `aum0301@staff.aumlux.internal` (`loginEmailFor()` in `features/auth/domain/app_user.dart`; the domain lives in `Env.crewLoginDomain` and the `admin-users` function). No mail is ever sent there.
- New accounts and resets return a **temporary password once**, with `must_change_password = true`. The router forces `/change-password`.
- **Single session:** after login the client calls `signOut(scope: others)`, ending sessions on other devices.
- Login lockout (client): 3 failures → 5 s, 5 → 15 s, 8+ → 30 s.

---

## 8. Backend API reference

All RPCs are called as `supabase.rpc('<name>', params: {...})`, which is `POST /rest/v1/rpc/<name>`. Only **authenticated** callers may execute them.

### 8.1 Public RPCs (the complete list, from `lockdown.sql`)

#### Identity
| RPC | Params | Returns | Rules / notes |
|---|---|---|---|
| `me()` | — | jsonb: id, employee_code, full_name, email, phone, role, status, section_id, team_id, dob, photo_path, must_change_password, **section_ids**, **team_ids** | Session bootstrap; cached offline by the client |
| `mark_password_changed()` | — | void | Clears `must_change_password` after the client updates the password |
| `update_my_contact(p_phone, p_email)` | text, text | void | Self-service contact edit (validated) |
| `people_directory(p_ids uuid[] = null)` | — | rows: id, full_name, employee_code, role, section_id, team_id, status | Names of people the caller may reference (pickers, "requested by"). With `p_ids`, resolves just those. |
| `next_employee_code()` | — | text | Manager+. Next free `PREFIX<n>` code org-wide (preview for the Add Staff form). |

#### Attendance and leave
| RPC | Params | Rules |
|---|---|---|
| `check_in` | `p_request_id uuid, p_captured_at timestamptz, p_lat, p_lng, p_accuracy_m, p_is_mocked, p_worksheet_id` | Idempotent on `p_request_id`: a replay returns the existing row. Capture time ≤ now + 5 min (`clock_ahead`), ≥ now − `offline_capture_max_hours` (`capture_too_old`), and inside `attendance_window` (`outside_window`). `work_date` is the IST date of the capture. Fails with `already_checked_in` or `on_leave`. Computes the geofence distance to the nearest of the home section and the worksheet location; a missing section GPS never blocks. Stores the mocked flag and the distance. |
| `check_out` | same, without worksheet | Requires a check-in; idempotent; out must be after in; records geofence distance and outside flag (nearest of home section and the day's worksite) |
| `mark_attendance(p_user_id, p_work_date, p_status, p_reason)` | | Supervisor+ who can manage the user; source = supervisor |
| `correct_attendance(p_attendance_id, p_status, p_check_in_at, p_check_out_at, p_reason)` | | Reason ≥ 5; writes `attendance_corrections` (before and after) |
| `verify_attendance(p_ids uuid[])` | → count | Supervisor+ verifies days in scope |
| `decide_leave(p_id, p_approve, p_note)` | → leave row | `can_approve_for` requester; reason required to reject; on approve, upserts each day as `status = leave, source = leave`, except days already checked in; notifies |
| `cancel_leave(p_id)` | | Requester, while pending |
| `attendance_month(p_month date, p_section_id = null)` | → table | Muster-roll data for a month (scoped) |

#### Worksheets
| RPC | Rules |
|---|---|
| `transition_worksheet(p_id, p_action, p_note)` | State machine (below). Notifies the requester on approve or reject. |
| `set_worksheet_crew(p_id, p_user_ids uuid[])` | Requester or approver (`forbidden`); not on closed worksheets (`invalid_transition`); members must be **active staff of the worksheet's section** (`invalid_crew`) |
| `sign_permit_checklist(p_worksheet_id, p_line_clear_ref, p_line_clear_issued_by, p_isolation_points, p_earthing_done, p_tested_dead, p_toolbox_talk_done, p_ppe_confirmed text[])` | Owner or approver, and the signer must be **supervisor+** (`forbidden`); only once the worksheet is approved or in progress (`invalid_transition`); upserts the checklist |

**Worksheet state machine**

```
draft ──submit──► submitted ──approve──► approved ──start*──► in_progress ──complete──► completed
  ▲                   │                      │
  └──(edit)◄─reject───┘                      │
draft/submitted/approved/rejected ──cancel──► cancelled
* start requires a signed permit checklist with earthing_done, tested_dead,
  toolbox_talk_done and PPE ⊇ {helmet, gloves, safety_belt}  → else `permit_incomplete`
```

- `submit`: requester only; from draft or rejected. A repeated submit by the requester is idempotent (outbox-safe).
- `approve` / `reject`: strictly higher authority in the section (`forbidden`); only from submitted (`already_decided`); reject needs a note (`reason_required`).
- `start` / `complete`: requester or approver.
- `cancel`: requester or approver, from draft, submitted, approved or rejected.

#### Inventory
| RPC | Rules |
|---|---|
| `decide_material_request(p_id, p_approve, p_note)` | Locks the request; approver must outrank the requester and cover the store's section; on approve, inserts into `stock_ledger` (issue = −qty; receipt and return = +qty), and the trigger updates the balance (overdraw fails atomically); notifies |
| `cancel_material_request(p_id)` | Requester, while pending |
| `adjust_stock(p_material_id, p_store_id, p_qty_delta, p_reason, p_is_scrap)` | Manager+; adjustment or scrap ledger entry |
| `transfer_stock(p_material_id, p_from_store, p_to_store, p_qty, p_note)` | Manager+; paired transfer_out/transfer_in entries |

#### Registers
| RPC | Rules |
|---|---|
| `record_asset_event(p_asset_id, p_event_type, p_note, p_to_section_id, p_assigned_to, p_status, p_condition)` | Manager+ in scope; updates the asset and appends an event |

#### Bonus, approvals, dashboard, notifications
| RPC | Rules |
|---|---|
| `decide_bonus(p_id, p_approve, p_note)` | COO/Director; no self-approval |
| `my_approvals()` | Pending items **I** can decide. Columns: `kind` (worksheet, material_request, leave, bonus), `id`, `code`, `title`, `requested_by`, `requester_name`, `requested_at`, `priority`, `route` |
| `dashboard_kpis()` | jsonb. **Everyone:** `my_attendance`, `my_month_present`, `pending_approvals`, `unread_notifications`. **Supervisor+:** `team_present_today`, `team_size`, `worksheets_in_progress`, `open_incidents`, `low_stock_items`. **Manager+:** `active_work_orders`, `open_tenders`, `deposits_held`, `deposits_expiring_30d`, `receivables_outstanding`, `receivables_over_90d`. The client shows only keys that are present (`Dashboard.has(key)`). |
| `register_device(p_token, p_platform)` | Claims the FCM token for the caller (moves it if another user had it, e.g. a shared phone); rejects junk tokens |
| `unregister_device(p_token)` | On sign-out |
| `mark_all_notifications_read()` | → count |

### 8.2 Direct table access (PostgREST)

Plain CRUD goes straight to tables, and RLS plus column grants make it safe:

- reads everywhere;
- inserts of worksheets, leave, material requests, incidents, attachments, poles, assets, commercial rows, catalogue, stores, teams, holidays, bonus, client_errors;
- updates of drafts and editable fields.

The client wraps updates in **`updateOrFail()`** (`lib/core/supabase/update_guard.dart`). It requests `.select('id')` and throws `forbidden` when zero rows came back, because PostgREST reports an RLS-blocked UPDATE as *success with 0 rows*.

### 8.3 Error codes (stable contract)

Raised via `private.fail` (as `hint`) or the edge functions (as `code`), and mapped in `lib/core/errors/app_failure.dart` and the l10n files.

| Area | Codes |
|---|---|
| General | `not_found`, `forbidden`, `not_active`, `invalid_request`, `invalid_action`, `invalid_transition`, `already_decided`, `reason_required`, `network` (client), `unauthenticated` |
| Attendance | `invalid_time`, `clock_ahead`, `capture_too_old`, `outside_window`, `already_checked_in`, `not_checked_in`, `on_leave` |
| Worksheets | `permit_incomplete`, `invalid_crew` |
| Inventory | (CHECK violation on balance → insufficient stock), `already_decided` |
| Location (client) | `location_off`, `location_denied`, `location_denied_forever`, `location_timeout` |
| admin-users | `invalid_json`, `invalid_action`, `invalid_code`, `invalid_name`, `invalid_role`, `invalid_sections`, `invalid_status`, `invalid_user`, `forbidden_role`, `forbidden_scope`, `forbidden_self`, `not_active`, `not_found`, `duplicate`, `duplicate_login`, `method_not_allowed`, `server_error` |

### 8.4 Edge Function `admin-users`

`POST /functions/v1/admin-users` with the caller's access token. This is the **only** way accounts are created or changed.

| Action | Body | Notes |
|---|---|---|
| `create` | `{employee_code \| auto_code: true, full_name, role, section_id, team_id?, email?, phone?, dob?, extra_section_ids?}`. With `auto_code`, the code is allocated via `next_employee_code()` as the caller and **retried on a clash** (up to 5×; ADR-0003). | Creates the auth user (email, or `<code>@staff.aumlux.internal`) with a random temporary password, then the profile. **Compensates** (deletes the auth user) if the profile insert fails, so there are no orphans. Returns `{user_id, login_id, temp_password}` **once**. |
| `update` | `{user_id, …fields}` | Changing section clears the team unless one is given |
| `set_status` | `{user_id, status}` | suspended or exited **ban** the auth user; active un-bans |
| `reset_password` | `{user_id}` | New temporary password plus a forced change. **Supervisors may reset staff in teams they supervise.** |

Rules: the caller must be active and manager or above (except the supervisor reset case); must strictly outrank the target's current *and* new role; managers act only within their sections; nobody changes themselves through this (`forbidden_self`).

### 8.5 Edge Function `push`

It's called by the `push_notification` DB trigger: `POST {notification_id}` with header `x-push-secret`. It looks up the notification and the user's device tokens, signs a Google OAuth JWT with `crypto.subtle` (service-account key; the token is cached), and sends an FCM HTTP v1 message with `data.route` for deep linking. Tokens FCM reports as `UNREGISTERED` or `INVALID_ARGUMENT` are deleted. It responds `not_configured` when secrets are missing, and the trigger is a no-op without the Vault secrets, so push never blocks a notification insert.

Secrets: `FCM_SERVICE_ACCOUNT`, `PUSH_WEBHOOK_SECRET` (function); Vault `push_function_url`, `push_webhook_secret` (DB). Setup is in BACKEND.md.

### 8.6 Shared edge code

`supabase/functions/_shared/supabase.ts` provides `adminClient()` (service role, from platform env), `callerClient(token)`, `bearer(req)`, CORS headers, `HttpError(status, code, message)` and `json()`. It supports both the new `SUPABASE_SECRET_KEYS` JSON env and legacy names.


---

## 9. Flutter client architecture

### 9.1 Layers and folder rules

```
lib/
├── main.dart            bootstrap (see 9.2)
├── app.dart             MaterialApp.router, lifecycle → outbox, update gate, idle guard
├── core/                shared infrastructure, no feature imports (except session for settings/idle)
└── features/<module>/
    ├── domain/          plain Dart models + rules (no Flutter, no Supabase)
    ├── data/            repositories: the ONLY code that talks to Supabase
    ├── application/     Riverpod notifiers/controllers (use-cases, orchestration)
    └── presentation/    pages and widgets (read providers, call controllers)
```

Smaller modules (leave, notifications, bonus, commercial) keep these layers in a few files, but follow the same direction of dependency: **presentation → application → data → Supabase**.

### 9.2 Bootstrap (`lib/main.dart`)

1. `WidgetsFlutterBinding.ensureInitialized()`; register font licenses (Inter, Noto Sans Malayalam, OFL).
2. `SharedPreferences.getInstance()`.
3. `initFirebaseForPush()`: Android only. Failure is swallowed, because push is optional.
4. `Supabase.initialize(url: Env.supabaseUrl, publishableKey: Env.supabasePublishableKey)`.
5. `ErrorReporter.install()`: release builds only; hooks `FlutterError.onError` and `PlatformDispatcher.onError`.
6. `runApp(ProviderScope(overrides: [sharedPreferencesProvider, outboxStoreProvider → PrefsOutboxStore], child: AumluxApp()))`.

`AumluxApp` (`lib/app.dart`):

- watches `localeProvider` and `routerProvider`, and builds `AppTheme.light(locale)` (memoised per script);
- keeps the outbox alive and calls `outbox.process()` on **app resume**;
- watches `pushControllerProvider`;
- in `builder:`, shows `UpdateRequiredPage` if `updateRequiredProvider`, otherwise wraps everything in `IdleGuard(timeoutMinutes: appSettings.idleTimeoutMinutes)`.

### 9.3 Configuration

- `lib/core/config/env.dart`:
  - `AUMLUX_ENV` (staging | production, default staging) chooses the Supabase URL and publishable key;
  - `SUPABASE_URL` / `SUPABASE_PUBLISHABLE_KEY` dart-defines override both (used for the local stack);
  - `crewLoginDomain = 'staff.aumlux.internal'`.
- `lib/core/config/feature_flags.dart`: `ENABLE_BONUS_MODULE` (bool define, default off).
- Pass defines with `--dart-define=K=V` or `--dart-define-from-file=env/local.json`.

### 9.4 State management (Riverpod 3)

- **Providers** for services and repositories (`supabaseClientProvider`, `<x>RepositoryProvider`).
- **`FutureProvider`** (often `.autoDispose` / `.family`) for reads, e.g. `dashboardProvider`, `notificationsProvider`, `worksheetProvider(id)`.
- **`Notifier`** for stateful controllers: `SessionController`, `OutboxController`, `LocaleController`.
- Async UI uses Dart 3 pattern matching:
  `switch (async) { AsyncData(:final value) => …, AsyncError(:final error) => ErrorState(…), _ => LoadingView() }`.
- After `await` inside notifiers, guard with **`ref.mounted`** (Riverpod 3 throws if a disposed ref is used).
- Tests override providers (`overrideWith`, `overrideWithValue`) and use `ProviderContainer`.

### 9.5 Session lifecycle (`features/auth/application/session_controller.dart`)

```
SessionLoading ──(no session)──────────────► SessionSignedOut(reason?)
      │                                            ▲   reasons: not_active, no_profile, idle, network
      └──(session) → me() ──► SessionSignedIn(user, offline: bool)
                     │
                     └── network error → cached profile (offline: true), refreshed when back online
```

- `signIn(identifier, password)`: maps an employee code to the crew email, calls Supabase auth, revokes other sessions, then loads `me()`.
- **Missing profile** → signed out with `no_profile`; **inactive** → `not_active`.
- Loads are de-duplicated (`_inflight`) and guarded against late `signedOut` events.
- `signOut()` unregisters this device's FCM token first (`AuthRepository.signOut`).
- `currentUserProvider` gives the `AppUser` or null. `AppUser` has `role`, `sectionId`, `sectionIds`, `teamIds`, `firstName`, `mustChangePassword`…, and `AppRole.atLeast()` / `outranks()`.

### 9.6 Routing (`lib/core/router/app_router.dart`)

`go_router` with a **`StatefulShellRoute.indexedStack`** (four tabs keep their own stacks) and a redirect driven by the session (`resolveRedirect`, which is unit-tested):

| Session | Redirect |
|---|---|
| Loading | → `/splash` |
| SignedOut | → `/login` |
| SignedIn and `mustChangePassword` | → `/change-password` |
| SignedIn on a public route | → `/home` |

Route map:

```
/splash   /login   /change-password
/home                          (tab 1)
  /home/approvals
  /home/notifications
/attendance                    (tab 2)
  /attendance/leave
/work                          (tab 3)
  /work/new
  /work/:id
  /work/:id/edit
/more                          (tab 4)
  /more/sync
  /more/staff  /more/staff/new  /more/staff/:id  /more/staff/:id/edit
  /more/teams  /more/org  /more/holidays  /more/bonus
  /more/commercial
  /more/commercial/:entity  …/new  …/:id  …/:id/edit
  /more/poles  /more/poles/new  /more/poles/:id  /more/poles/:id/edit
  /more/assets /more/assets/new /more/assets/:id /more/assets/:id/edit
  /more/inventory  /more/inventory/new  /more/inventory/requests/:id
  /more/inventory/catalog  /more/inventory/stores
```

**Navigation model (ADR-0005).** Tab roots live in the shell. Every direct child of a tab root is on the **root navigator** (`rootNavigatorKey`), so it opens full-screen above the tab bar. Tapping a tab always opens its root. The redirect keeps the intended destination through `/splash?from=` and `/login?from=` (in-app paths only), and with `restorationScopeId` on app, router, shell and branches, Android restores the screen if it kills the app (ADR-0004).

`Routes` holds the constants. **Server-embedded deep links** (notification `route`, `my_approvals.route`) use `/work/<id>` and `/more/inventory/requests/<id>`. Don't rename these without a migration. Unknown routes render a friendly "coming soon" `EmptyState`.

`AppShell` (`features/shell/app_shell.dart`) shows a **bottom `NavigationBar`** below 600dp, and a **`NavigationRail`** with the brand mark at 600dp and wider. It shows an `OfflineBanner` when there's no connectivity, and gives a selection haptic on tab change.

### 9.7 Data layer and errors

- Repositories take a `SupabaseClient` and expose typed models. Every Supabase call is wrapped so it throws an **`AppFailure`**.
- `AppFailure.from(e)` maps:
  - a `PostgrestException` with `hint` → that code;
  - auth errors → `invalid_credentials`, etc.;
  - `SocketException` / timeouts → `network` (retryable);
  - edge-function `{code, message}` → that code.
- `failureMessage(l10n, e)` turns a failure into **localised** copy. Raw exception text is never shown.
- `isPermanent` vs `retryable` drives outbox behaviour.
- `updateOrFail(query)` makes RLS-blocked updates fail loudly (see §8.2).

### 9.8 Cross-cutting services (`lib/core`)

| Module | Responsibility |
|---|---|
| `connectivity/` | `onlineProvider` (stream of bool from `connectivity_plus`) |
| `outbox/` | Offline queue (see §12) + platform `file_bytes` helpers (persist picked files for later upload) |
| `location/location_service.dart` | `LocationService` interface (`current()`, `permissionUndecided()`) + `GeolocatorLocationService`; throws `location_*` failures; flags mocked locations |
| `location/location_rationale.dart` | `explainLocationIfNeeded(context, ref)`: a bottom sheet explaining *why* before the first OS prompt (scrollable) |
| `media/` | `AttachmentService` (queue on phone, direct upload on web; remembers the target before opening the camera and `recoverLostPhotos()` re-attaches a photo taken while Android killed the app), `attachmentsProvider` (incl. `lat/lng`), `pendingPhotoPathsProvider`, `signedUrlProvider` (1 h), `PhotoStrip` (GPS fix taken while the camera is open; pending uploads shown from the phone; thumbnails decoded at tile size), `PhotoViewerPage` (swipe, zoom, time, coordinates, map), `DocumentList`; photos downscaled to ~1600px JPEG q70 |
| `export/` | `saveAndOpen` bytes → file (IO: temp dir + `open_filex`/share; web: download). Used by the PDF/XLSX exports. |
| `push/push_service.dart` | Android FCM: permission, token → `register_device`, refresh, tap → `router.go(route)` |
| `session/` | `IdleGuard` (web and supervisor+ only; crews on phones are never timed out, because signing back in needs connectivity) + `IdleTimeoutService` |
| `settings/` | `appSettingsProvider` (reads `app_settings` after sign-in; never blocks offline), `installedBuildProvider`, `updateRequiredProvider` (Android only), `UpdateRequiredPage` (→ APK download URL) |
| `errors/error_reporter.dart` | Release-only crash reports to `client_errors` (signed-in, de-duplicated, ≤ 20 per session) |
| `format/` | `Fmt` (money ₹ en-IN, compact money, qty, date, time, dateTime) and `Ist` (today in IST, IST conversions) |
| `ui/` | `showSnack`, `confirmAction`; **`sheets.dart`**: `showAppSheet`, `SheetScaffold` (title, content, pinned actions, keyboard-aware), `promptText()` and `DisposeWith` (owns controllers until the sheet is unmounted); `openInMaps(lat,lng)` |
| `maps/` | `AppMap` (OSM tiles + attribution + UA), `MapPin`, `LocationPreview` (static mini-map → `MapViewPage`), `LocationPickerPage`/`pickLocation()` (drag-to-place, optional geofence slider), `LocationField` (form field: GPS + map). Tile URL overridable with `MAP_TILE_URL` (ADR-0001). |
| `l10n/` | `context.l10n`, `LocaleController` (persisted) |
| `supabase/` | `supabaseClientProvider`, `sharedPreferencesProvider`, `updateOrFail` |

---

## 10. Design system

Rules live in [DESIGN.md](DESIGN.md); code lives in `lib/core/design/` (import only `core/design/design.dart`).

### 10.1 Language and inspiration

- **Stripe** structure: white canvas, deep-navy ink instead of black, hairlines over shadows, pill actions, tabular numbers, thin display type, and the **gradient mesh**.
- **Groww**: a hero card with the day's key status, round shortcut tiles, big thin numbers, colour-coded KPI tiles.
- **Notion**: calm white pages, icon-tile list rows, quiet dividers.
- **Field-first overrides:**
  - body never below weight 400;
  - every text pair ≥ 4.5:1 (enforced by `test/core/design/contrast_test.dart`);
  - interactive borders ≥ 3:1;
  - targets ≥ 48dp (primary buttons 52dp);
  - Malayalam gets 0 letter-spacing and line height ≥ 1.5.

### 10.2 Tokens (`app_tokens.dart`)

**Colours**

| Token | Hex | Role |
|---|---|---|
| `primary` | `#533AFD` | Indigo: filled CTAs, active states, checkboxes, focus. White text = 6.19:1 |
| `primaryPress` / `primaryDeep` | `#2E2B8C` / `#4434D4` | Pressed / indigo text and icons (`primaryInk`) |
| `primarySoft` | `#EEEBFF` | Nav indicator, selected rows, soft chips |
| `brandOrange` / `brandOrangeInk` / `brandOrangeSoft` | `#FF6B35` / `#B93D10` / `#FFF1EA` | Brand accent: logo, mesh, highlights. **Never** a button fill or a text background (white on it = 2.84:1) |
| `ruby`, `magenta`, `lavender`, `cream` | `#EA2261`, `#F96BEE`, `#B9B9F9`, `#F5E9D4` | Mesh and accent stops |
| `brandDark` | `#1C1E54` | Featured KPI / inverse surfaces |
| `ink`, `inkSecondary`, `inkMute`, `inkDisabled` | `#0D253D`, `#273951`, `#5B6B84`, `#9AA6B8` | Text |
| `canvas`, `canvasSoft`, `canvasSunken`, `hairline` | `#FFFFFF`, `#F6F9FC`, `#EEF2F7`, `#E3E8EE` | Surfaces |
| `borderInput` | `#7F8EA6` | Input outlines (3.32:1) |
| semantic | success `#137A3F`/`#E7F6ED`, warning `#8A5300`/`#FFF4DB`, danger `#C4213F`/`#FDECEF`, info `#1D5FD1`/`#EAF1FD` | fg/bg pairs ≥ 4.5:1 |

**Spacing:** 2, 4, 8, 12, 16, 24, 32, 48, 64 (`xxs`…`huge`). Page gutter 16 (24 at ≥ 600dp). Form max width 640; content max 1200.

**Radius:** xs 4 · sm 10 (inputs) · md 12 · lg 16 (cards) · xl 24 (sheets, dialogs) · pill.

**Shadows:** `level1` (subtle lift); `level2` for floating layers only (the Today card, sheets).

**Sizes:** touch target 48, primary action 52, input 52, list row 56, icons 16/20/24/48.

**Typography (Inter + Noto Sans Malayalam fallback, bundled offline):**

| Style | Size/weight | Use |
|---|---|---|
| `display` | 34/300, −0.9, tnum | greeting name, sign-in title, hero numbers |
| `headline` | 26/300 | large titles |
| `title` | 20/600 | app bar, sheets, dialogs, empty-state titles |
| `subtitle` | 17/600 | section headers, card titles |
| `body` / `bodyStrong` | 15/400 / 15/600 | reading text / row titles |
| `bodyTabular` | 15/500, tnum | numbers in rows |
| `kpi` | 30/300, tnum | KPI values |
| `label` / `button` | 14/500 / 16/600 | labels / buttons |
| `caption` / `overline` | 13/400 mute / 11/600 tracked | helpers / eyebrows |

**Motion (`AppMotion`):** press 90ms, fast 140ms, base 220ms, slow 320ms. Curve = emphasized decelerate `Cubic(0.05, 0.7, 0.1, 1)`.

### 10.3 Theme (`app_theme.dart`)

`AppTheme.light(locale)` maps the tokens onto Material 3:

- the colour scheme;
- text theme;
- filled, outlined and text buttons as pills, with a pressed colour;
- inputs (white fill, 10px radius, 2px indigo focus);
- `NavigationBar` and `NavigationRail` with a `primarySoft` indicator;
- chips, segmented buttons, sheets (24px top radius, drag handle), dialogs, snackbars (floating, ink), switches, checkboxes, radios, date picker, popup menus;
- **`InkRipple`** as the splash factory (cheaper than InkSparkle);
- **`AppPageTransitions`** for every platform.

It's **memoised** per script, so it isn't rebuilt on every root rebuild.

### 10.4 Motion primitives (`motion/motion.dart`)

| Widget | Behaviour |
|---|---|
| `AppPageTransitions` | Incoming page rises 3% and fades (260ms in / 200ms out). Only one layer animates and nothing scales: cheap on low-end phones. |
| `PressScale` | Visual only: scales to 0.97 on pointer-down, springs back (easeOutBack). No gesture or semantics changes. |
| `Pressable` | `PressScale` + `InkWell` (soft highlight, no splash) + selection haptic |
| `FadeSlideIn` | One-shot 12px rise + fade, staggered by `index` (40ms steps, capped at 6). The delay is folded into an `Interval`, so it uses **no timers**. |
| `Skeleton` + `SkeletonBox` | One controller pulses the whole placeholder group |
| `reduceMotion(context)` | Every primitive honours the OS reduce-motion setting |

### 10.5 Components (`widgets/`)

| Component | Notes |
|---|---|
| `AppButton` (+ `.secondary`, `.tertiary`, `.danger`) | Pill; `loading` shows a spinner **on the enabled colour** and ignores taps (no double submit); `expand` for full width; press-scale; cross-fades the loading state |
| `AppTextField`, `AppDropdownField` | Labelled above the field; `required` marker; validators; suffix and prefix |
| `AppCard` | White, 16px radius, hairline; `onTap` → `Pressable`; `elevated` → level2 shadow |
| `IconTile` | Tinted rounded square with an icon. The leading visual everywhere. |
| `KpiCard` | `IconTile` + big thin tabular value + caption; `tint` for semantics; `featured` (brandDark) |
| `QuickAction` | Shortcut circle (52px tile) + label; 4 per row on phones |
| `AppListRow` | 56dp+ row: leading, title, subtitle (2 lines), trailing or chevron; selected state; haptic |
| `SectionHeader` | Header semantics + optional action |
| `StatusChip` | Colour **+** text **+** icon. **`StatusChip.fromDomain(status)` is the only status → tone mapping.** |
| `EmptyState`, `ErrorState`, `LoadingView` | Halo icon + title + message + action; `LoadingView` renders skeleton rows (spinner only when given a message) |
| `OfflineBanner`, `SyncBadge` | Live-region banner; "N pending" pill → `/more/sync` |
| `GradientMesh` | Brand backdrop (cream, orange, lavender, indigo, ruby, magenta radial blobs fading to white); `RepaintBoundary`, painted once |
| `LazyListView` | Header widgets + lazily built rows + footer. **Use it for any data list.** |
| `Avatar` | Initials on a stable per-person tint (people lists, map pins) |
| `StatStrip` / `StatItem` | Row of headline numbers in one card (Groww "invested · current · returns") |
| `DateBlock` | Calendar-tile leading visual (day number + locale weekday) |
| `DetailHeader`, `InfoGroup` / `InfoRow` | Detail-page identity block; titled card of label → value facts (long values stack) |
| `StickyActionBar` | Primary actions pinned at the bottom of forms and detail pages |
| `NoteBanner` | Tinted callout for decisions, warnings and notes |
| `SectionPickerField` (features/org) | Hierarchical section field with drill-down sheet, breadcrumbs and search |
| `BrandMark` / `BrandMarkPainter` | The logo (see 10.6). `progress` draws it on (splash). |

### 10.6 Brand mark and launch experience

- **Mark:** an "A" drawn as a **transmission pylon** (two legs, a crossarm with insulator dots, a lattice bar), in white on an **orange → ruby → indigo** tile. Geometry lives in a 108-unit square (the Android adaptive-icon canvas) and fits the 66-unit safe zone.
- **One geometry, every output:**
  - `BrandMarkPainter` (in-app, splash page draw-on);
  - `android/app/src/main/res/drawable/ic_launcher_{background,foreground}.xml` + `mipmap-anydpi-v26/ic_launcher.xml` (adaptive + **monochrome** themed icon);
  - `drawable/splash_logo.xml` (pre-Android-12 launch screen);
  - `drawable-v31/splash_icon.xml`: an **animated vector** where the pylon draws itself in ~700ms on the Android 12+ system splash;
  - PNGs (legacy mipmaps, web `Icon-*.png`, maskable, `favicon.png`, `docs/brand/aumlux-mark-1024.png`), rendered by `flutter test tools/brand/render_icons_test.dart`;
  - the landing page (`tools/ci/landing.html`) inlines the SVG.
- **Launch windows are light in day and night themes** (`values*/styles.xml`), so there's no black flash.

### 10.7 Screen patterns

- **Home:** `CustomScrollView` → mesh hero (brand mark, sync badge, bell, greeting, role and ID chips, floating **Today** card) → **Shortcuts** (`QuickAction`, filtered by role) → **Overview** (`SliverGrid` of `KpiCard`; 2/3/4 columns by width; height scales with text size).
- **List pages:** `Scaffold` + filter chips + `RefreshIndicator(LazyListView(AppListRow…))` + extended FAB for "New".
- **Forms:** centred column (max 640), labels above fields, one primary `AppButton` (expand) + secondary.
- **Detail:** summary card with status chip, sections (`SectionHeader`), actions as buttons at the bottom; destructive actions use `confirmAction`.
- **Sheets:** modal bottom sheets with drag handle; `isScrollControlled` and scrollable content for anything that can be tall.

### 10.8 Accessibility checklist (enforced in review)

- Contrast pairs are covered by tests; add new pairs to `contrast_test.dart`.
- Every tappable item is ≥ 48dp and has a label (icons get a `tooltip` or semantics).
- Status never relies on colour alone.
- Live regions: offline banner, login error.
- Large text: grids and tiles scale with `MediaQuery.textScalerOf`; rows allow two lines.
- Reduced motion is honoured.

---

## 11. Module internals

| Module | Key files | Server calls |
|---|---|---|
| **auth** | `domain/app_user.dart` (`AppRole`, `loginEmailFor`, `passwordMeetsPolicy`), `domain/login_rate_limiter.dart`, `data/auth_repository.dart`, `application/session_controller.dart`, `presentation/{login,change_password,splash}_page.dart` | Auth sign-in, sign-out (others/local), `updateUser(password)`, `me()`, `mark_password_changed()`, `unregister_device` |
| **home** | `dashboard_repository.dart` (`Dashboard` wraps the jsonb; `number()`, `has()`), `home_page.dart` | `dashboard_kpis()` |
| **attendance** | `data/attendance_repository.dart`, `application/capture_controller.dart` (check-in/out via outbox with client `request_id` + captured time; `PendingCapture` list), `application/muster_export.dart` (PDF + XLSX muster roll), `presentation/{attendance_page,my_attendance_view,team_attendance_view,holidays_page,attendance_labels}.dart` | `check_in`, `check_out`, `attendance_days` select, `mark_attendance`, `correct_attendance`, `verify_attendance`, `attendance_month`, `holidays` CRUD |
| **leave** | `leave.dart` | `leave_requests` insert/select, `cancel_leave`, `decide_leave` (via approvals) |
| **approvals** | `approvals_page.dart` | `my_approvals()`, then `transition_worksheet` / `decide_material_request` / `decide_leave` / `decide_bonus` |
| **worksheets** | `data/worksheet_repository.dart` (`WorksheetDraft`, create via outbox with client id, `update` with `updateOrFail`, `transition`), `presentation/{worksheets_page,worksheet_form_page,worksheet_detail_page,worksheet_sheets,worksheet_labels}.dart` | `worksheets` CRUD, `transition_worksheet`, `set_worksheet_crew`, `sign_permit_checklist`, `incidents`, `attachments` + storage, `worksheet_material_usage` |
| **inventory** | `data/inventory_repository.dart` (`CatalogItem`, stores, balances, requests, ledger), `presentation/{inventory_page,material_request_form_page,material_request_detail_page,catalog_pages,stock_register_export,inventory_labels}.dart` | `stock_overview`, `stock_ledger`, `material_requests`, `decide_material_request`, `cancel_material_request`, `adjust_stock`, `transfer_stock`, catalogue and stores CRUD |
| **registers** | `registers_repository.dart`, `poles_pages.dart` (GPS capture with rationale; offline pending list), `assets_pages.dart` (event history), `registers_labels.dart` | `pole_records` CRUD, `assets` CRUD, `record_asset_event`, `asset_events` |
| **commercial** | `entities.dart`: **field-definition driven** (`EntityDef`, `FieldDef`, `FieldKind` text/multiline/money/date/datetime/month/choice/ref/phone/gstin; `LinkDef` back-references). Six entities: `tenders`, `deposits`, `work-orders`, `bills`, `letters` (correspondence), `gst`. Plus `entity_pages.dart` (generic list, detail, form, dashboard, search), `field_format.dart`, `commercial_repository.dart`, `commercial_export.dart`. | Direct table CRUD on the six tables; `bill_ageing`, `deposits_expiring` |
| **notifications** | `notifications.dart` (`AppNotification`, `notificationsProvider` with a **Realtime channel** `notifications-<uid>`, `NotificationBell`, `NotificationsPage`) | `notifications` select/update/delete, `mark_all_notifications_read` |
| **staff** | `data/staff_repository.dart` (calls `admin-users`), `presentation/{staff_list_page,staff_detail_page,staff_form_page,credentials_sheet}.dart` | `people_directory`, `profiles` select, `admin-users` function |
| **org** | `data/org_repository.dart` (`orgTreeProvider`, `directoryProvider`, `OrgUnit`, `OrgLevel`), `presentation/{org_page,teams_page}.dart` | org tables CRUD, `teams` |
| **bonus** | `bonus_page.dart` (only routed when `ENABLE_BONUS_MODULE=true`) | `bonus_ledger` insert/select, `decide_bonus` |
| **more** | `more_page.dart` (profile, admin and register links by role, sync, language, password, about, sign out), `sync_queue_page.dart` (outbox entries: retry, discard) | — |
| **shell** | `app_shell.dart` | — |

**Adding a commercial register** usually means adding an `EntityDef` (fields, primary and secondary columns, order, search columns, status field) and a migration. The list, detail, form, validation, export and links are generated from it.

---

## 12. Offline-first behaviour

### 12.1 The outbox (`lib/core/outbox/outbox.dart`)

- **`OutboxOp`**: `{id, kind, name, payload, filePath?, label, createdAt, attempts, failed, lastError}`, persisted as JSON in SharedPreferences (`aumlux.outbox.v1`; localStorage on web).
- **Kinds:**
  - `rpc`: calls RPC `name` with `payload`. It must be idempotent, e.g. `check_in` keyed on `p_request_id`.
  - `insert`: upserts `payload` into table `name` with `ignoreDuplicates`. The row carries a **client UUID**, so a replay is a no-op.
  - `upload`: uploads the local file to storage object `name`. "Already exists" counts as success.
- **Processing:** strictly **FIFO and sequential**, because order matters (worksheet row → attachment row → file). It's triggered on enqueue, on connectivity regained (`onlineProvider`), and on app resume. Concurrent `process()` calls share one run.
  - **Retryable** failure (network) → stop and wait for the next trigger.
  - **Permanent** failure → mark `failed` and carry on with the next entry.
  - The user can **retry** or **discard** failed entries in More → Sync queue.
- **UI signals:**
  - `SyncBadge` on Home ("N pending");
  - `pending_sync` status chips on optimistic rows;
  - "Saved on this phone" snacks;
  - `pendingCapturesProvider` shows unsynced check-ins on the attendance screen.

### 12.2 What works offline

| Action | Offline? |
|---|---|
| Check-in / check-out | ✅ queued with the original capture time. The server enforces `offline_capture_max_hours` (72h) and the attendance window on that time. |
| Create a worksheet (+ submit) | ✅ |
| Photos and documents on records | ✅ on phones (file persisted locally, then row and upload queued); web uploads immediately |
| Pole survey | ✅ |
| Reading previously loaded screens | ✅ (in-memory), and the session survives with the cached profile |
| Approvals, account changes, commercial edits | ❌ online only (they need fresh server state) |

---

## 13. Localisation

- `flutter gen-l10n` (`generate: true`); sources are `lib/l10n/app_en.arb` (template, with `@key` metadata for placeholders) and `app_ml.arb`. The generated `app_localizations*.dart` files are committed.
- Access with `context.l10n.key`. **No user-facing string literals in widgets.**
- Language is switchable in More → Language and persisted (`LocaleController`).
- Malayalam typography: Noto Sans Malayalam fallback, `AppTypography.forMalayalam` (no negative tracking, line height ≥ 1.5), and a separate memoised theme.
- Server-generated notification text is English. Client error copy is localised via codes.
- To add strings, edit **both** ARB files, then run `flutter gen-l10n` (or any build).

---

## 14. Testing

### 14.1 Flutter (`flutter test`; ~176 tests)

| Area | Examples |
|---|---|
| `test/core/design/` | `contrast_test.dart` (WCAG pairs), `widgets_test.dart` (state views, sync badge…), `motion_test.dart` (lazy list builds only visible rows, press scale, timer-free entrance, reduced motion, brand mark) |
| `test/core/` | outbox (FIFO, retry vs permanent, shared drain), router redirect policy, idle timeout, `AppFailure` mapping, formatters, settings + update gate, location rationale sheet |
| `test/l10n/malayalam_layout_test.dart` | 9 dense screens rendered in Malayalam at 360dp, at 100% and 130% text; **fails on any overflow** |
| `test/core/ui/sheets_test.dart` | prompts close without "used after dispose"; `DisposeWith` keeps controllers alive until unmount |
| `test/features/` | attendance (capture online and offline, no-GPS path, geofence review flags), auth (login, change password), commercial (forms, required fields), inventory, registers, notifications (bell badge), staff (manager creates crew, credentials shown once), worksheets, more (Malayalam switch persists) |

Conventions:

- Override providers, and never hit the network. Fake `SupabaseClient`s use `AuthClientOptions(autoRefreshToken: false)` to avoid pending timers.
- Set `tester.view` size for lazily built lists.
- An animation's first frame has zero elapsed time: `pump()` once before `pump(duration)`.
- Stop `busy` spinners before showing dialogs and sheets, or `pumpAndSettle` will time out.

### 14.2 Database (`supabase test db`; pgTAP, ~110 assertions)

`supabase/tests/fixtures/org.psql` builds a fixed org:

- users D (director), C (coo), M (manager section A), M2 (manager section B), S (supervisor of team 1), W1 (staff, team 1, section A), W2 (staff, section B);
- `tests.login(uuid)` impersonates a user (`set role authenticated` + JWT claims); `reset role` returns to postgres.

| Suite | Proves |
|---|---|
| `01_baseline` | RLS enabled everywhere, no anon access, lockdown grants |
| `02_people_scope` | visibility by role and section; no escalation |
| `03_attendance` | idempotent check-in, window/clock/age rules, geofence, corrections, leave |
| `04_worksheets` | state machine, permit gate, column-based read policy, outbox upsert path |
| `05_inventory` | ledger immutability, balances, overdraw, decisions, transfers |
| `06_commercial_bonus` | manager read / exec write, bonus no-self-approval |
| `07_reports_smoke` | views and KPI functions run for every role |
| `08_notifications` | device-token takeover, push trigger never blocks, own-only reads |
| `09_client_errors` | insert-own, no spoofing, exec-only read, anon blocked |
| `10_codes_checkout_geofence` | generated codes (org-wide max, case, custom ignored, format setting, role check), anon lockout, check-out geofence recorded |

Counts are always **scoped to fixture rows**, so a dirty local DB can't break them. Tests run inside `begin; … rollback;`.

### 14.3 Gate before every commit

```bash
flutter analyze            # must be "No issues found!"
flutter test               # all green
supabase db reset          # if migrations changed
supabase test db           # "Result: PASS"
supabase db lint --level warning
```

---

## 15. Local development

Full guide: [docs/LOCAL_TESTING.md](docs/LOCAL_TESTING.md). Summary:

```bash
supabase start                    # Docker stack: Postgres, Auth, Storage, Realtime, Functions, Studio
supabase db reset                 # migrations + seed
node tools/dev/local-setup.mjs    # writes env/local.json + demo accounts (refuses non-local URLs)
flutter run -d chrome --dart-define-from-file=env/local.json
# Android over USB:
adb reverse tcp:54321 tcp:54321
flutter run --dart-define-from-file=env/local.json
```

- Demo accounts: one per role (director, coo, Kaloor manager, Kaloor supervisor and team, staff in team, an out-of-scope Aluva staff member). Logins and the shared local password are in LOCAL_TESTING.md.
- Studio: http://127.0.0.1:54323. Functions hot reload: `supabase functions serve`.
- Local function secrets: `supabase/functions/.env` (gitignored; template `.env.example`).
- **A dashboard-created auth user cannot sign in** (no `profiles` row → `no_profile`). Use the bootstrap script or the app.
- **Staging bootstrap:** `supabase login`, `supabase link --project-ref dtficnziewtaplbqoofn`, `supabase db push --include-seed`, `supabase functions deploy admin-users` and `push`, then `node --env-file=.env tools/bootstrap/create-director.mjs …` with the **secret** key (`sb_secret_…`, never the publishable one; the script refuses that). Delete the key file afterwards.

---

## 16. CI/CD and releases

### 16.1 Branches

| Branch | Meaning |
|---|---|
| `revamp/phase-0 … phase-12-release`, `revamp/ui-revamp` | Stacked phase branches (each builds on the previous) |
| `revamp/prod-ready` | Integration branch for the revamp |
| `staging` | Deploys the staging DB + builds test artifacts |
| `releases` | Production: deploys the prod DB + publishes the site |
| `main` (on the `parzi-al/kseb` remote) | Unrelated initial commit; not used by this flow |

Commits follow `type(scope): summary` (`feat(ui): …`, `fix(bootstrap): …`, `docs: …`) and end with the co-author trailer. PR descriptions end with the Claude Code line.

### 16.2 Workflow `Supabase` (`.github/workflows/supabase.yml`)

- **test** (PRs and pushes to `staging`, `releases`, `revamp/**`): `supabase db start` → `supabase db lint --level warning --fail-on warning` → `supabase test db`.
- **deploy** (push to `staging`/`releases`): checks secrets → `supabase link` → `supabase db push` (staging gets `--include-seed`) → `supabase functions deploy`.
- **backup** (nightly 02:00 IST): pings both projects (free tier pauses after 7 idle days) → dumps prod roles, schema and data → encrypts with `BACKUP_PASSPHRASE` → 30-day artifact.

### 16.3 Workflow `Aumlux Release Cycle` (`.github/workflows/deploy-aumlux.yml`)

- **validate** (PRs): `flutter analyze`, `flutter test`.
- **build-staging** (push to `staging`): tests → writes `android/key.properties` from secrets → `tools/ci/build-site.sh staging site-staging` **and** `tools/ci/build-site.sh production site-production` (same commit). Uploads both artifacts. Signing material is removed afterwards.
- **deploy-release** (push to `releases`): downloads the **production** artifact of the latest green staging run, asserts `environment=production`, and deploys to GitHub Pages.

`tools/ci/build-site.sh <env> <out>`:

- builds the APK (arm64) and web with `--dart-define=AUMLUX_ENV=<env>` and `--build-number = 1000 + GITHUB_RUN_NUMBER`;
- verifies the zip, signer (**a production build that is debug-signed fails**), sha256 and aapt badging;
- assembles `index.html` (landing page from `tools/ci/landing.html`), `web/`, `downloads/aumlux.apk` (+ `.sha256`, info) and `release-metadata.txt`.

### 16.4 Android release specifics

- Package **`com.aumlux.app`**; `minSdk` = Flutter default (24); R8 minify + resource shrinking (`proguard-rules.pro`).
- Release signing from `android/key.properties` (gitignored; CI writes it from `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`). It falls back to debug signing locally.
- **The keystore can never be rotated** without every user reinstalling. Keep it and its passwords in the company password manager.
- Permissions are least-privilege:
  - kept: CAMERA, FINE/COARSE location (foreground only), INTERNET, NETWORK_STATE, POST_NOTIFICATIONS (+ FCM's WAKE_LOCK / c2dm);
  - stripped from plugin merges with `tools:node="remove"`: media/storage reads and `FOREGROUND_SERVICE_LOCATION`.
- **Forced update:** `update public.app_settings set value = '<build>' where key = 'min_app_build';` → older Android builds show "Update required" with a download button. Outbox data stays on the phone and syncs after updating.

---

## 17. Operations

Runbook: [docs/BACKEND.md](docs/BACKEND.md). Highlights:

**One-time setup checklist**

1. GitHub environments `staging` and `production` with `SUPABASE_ACCESS_TOKEN`, `SUPABASE_DB_PASSWORD`, `BACKUP_PASSPHRASE` (prod); repository secrets for Android signing.
2. Supabase dashboard (each project): Auth → Email: **disable sign-ups and email confirmation**.
3. Deploy the schema (CI or `supabase db push`); bootstrap the first Director.
4. Optional push:
   - register `com.aumlux.app` in Firebase and run `flutterfire configure` (this rewrites `lib/firebase_options.dart`);
   - set function secrets `FCM_SERVICE_ACCOUNT` and `PUSH_WEBHOOK_SECRET`;
   - create Vault secrets `push_function_url` and `push_webhook_secret`.
5. Rehearse a backup restore into staging.

**Monitoring**

- `select … from public.client_errors order by created_at desc` (crash reports);
- `audit_log` (who changed what);
- Supabase dashboard usage (DB 500 MB, storage 1 GB; an alert at 70%).

**Key rotation:** see the table in BACKEND.md (publishable key → release + `min_app_build`; the push secret must change in both places at once; the keystore is never rotated).

**Lost phone:** set the user to *suspended* in-app. They're blocked on their next request.

**Free-tier limits:** 500 MB DB (watch `audit_log` growth), 1 GB storage (photos are compressed; R2 is the fallback), 2 projects (exactly staging + prod), pauses after 7 idle days (nightly ping).

---

## 18. Recipes: how to change things safely

**Add a column or table**

1. Create a new migration `supabase/migrations/<timestamp>_<name>.sql`. **Never edit an applied migration.**
2. `alter table … enable row level security`; write policies using the helpers; grant **only** the needed columns.
3. `select private.track('public.<table>');` for audit and `updated_at`.
4. If you add RPCs: `SECURITY DEFINER`, `set search_path = ''`, rank and scope checks, `FOR UPDATE` on decisions, `private.fail(code, …)` errors. Then **add the signature to the grant list in `…000900_lockdown.sql`.** A new file sorting before lockdown means `supabase db reset` locally.
5. Add pgTAP assertions (role matrix + one happy path), scoped to fixture rows.
6. Map new error codes in `AppFailure` and both ARB files.

**Add a screen**

1. Add a route under the right tab branch in `app_router.dart` (and a `Routes` constant if it's linked from elsewhere).
2. Use design-system widgets only. One primary `AppButton`. Lists via `LazyListView`. Loading via `LoadingView` or `Skeleton`. Errors via `ErrorState` + `failureMessage`.
3. Data via a repository + provider; mutations through a controller; `updateOrFail` for updates.
4. Strings in both ARB files. Widget test with provider overrides.

**Add a KPI**

1. Add the key to `dashboard_kpis()` under the right role gate (new migration with `create or replace`).
2. Add a tile in `home_page.dart` `_KpiGrid` guarded by `d.has('<key>')`, plus a label in the ARBs.

**Add a notification**

1. Call `private.notify(user, title, body, route, data)` in the RPC. Push happens automatically. Use an existing route shape for deep links.

**Change the logo**

1. Edit `BrandMarkPainter` **and** the vector XMLs (same 108-unit geometry).
2. Run `flutter test tools/brand/render_icons_test.dart` and commit the PNGs.

**Change a design token**

1. Update `app_tokens.dart` and DESIGN.md in the same commit.
2. If a colour changes, the contrast test must still pass.

---

## 19. Gotchas and lessons learned

These cost real debugging time. Don't relearn them.

| Gotcha | Fix in place |
|---|---|
| `uuid = uuid[]` operator error in policies | cast: `= any ((select private.my_section_ids())::uuid[])` |
| Functions were executable by `anon` | global `alter default privileges … revoke execute`, plus the lockdown migration |
| `INSERT … ON CONFLICT DO NOTHING` also checks **SELECT** policies on the new row | SELECT policies must be column-based (e.g. `requested_by = auth.uid()`), not id lookups |
| Column REVOKE after a table GRANT does nothing | grant only the allowed columns |
| STABLE functions can't call a volatile `fail()` | assertion helpers aren't STABLE |
| Audit trigger reading `old.id` on tables without `id` | read the id from the row's JSON |
| Negative stock delta with an upsert violated the CHECK | update first; insert only positive deltas |
| Client-supplied `id` was rejected | grant the `id` column on INSERT |
| `[auth.email] enable_signup = false` disables email login entirely | keep it true; disable sign-up at `[auth]` and in the dashboard |
| RLS-blocked UPDATE "succeeds" with 0 rows | `updateOrFail` |
| `supabase db reset` wipes local auth users | re-run `tools/dev/local-setup.mjs` |
| New edge functions aren't served until restart | `supabase stop && supabase start` |
| `process.exit()` crashes Node on Windows with open sockets | use `process.exitCode` |
| Riverpod "Ref used after dispose" in async notifiers | `if (!ref.mounted) return;` after awaits |
| Session/outbox races at sign-in | in-flight load de-dupe, signed-out event guard, shared drain future |
| Promoting the *staging* artifact to production pointed prod at the staging DB | CI builds both variants; deploy asserts `environment=production` |
| Eager `ListView(children: [for …])` janked on 100+ rows | `LazyListView` |
| Full-screen scale+fade page transitions janked on mid-range phones | single-layer rise + fade |
| Loading button turned disabled-grey, so the white spinner was invisible | keep enabled colours while loading and swallow taps |
| `Future.delayed` in animations leaves pending timers in tests | fold delays into `Interval` curves |
| Dark-mode launch window was black | light launch themes in `values-night*` |
| Bootstrap with the publishable key → `permission denied for table profiles` (ran as anon) | the script now rejects `sb_publishable_` keys |
| Disposing a `TextEditingController` right after `await showDialog/showModalBottomSheet` | The future completes when the route *starts* closing; the field is still on screen. Caused the `_dependents.isEmpty` red screen. Use `promptText` / `DisposeWith`. |
| Selected chips showed dark text on the ink pill | Chips resolve the label **colour** by state; put a `WidgetStateColor` in `labelStyle.color` (a `WidgetStateTextStyle` is ignored). |
| `latlong2` exports its own `Path`, which shadows Flutter's | `import 'package:latlong2/latlong.dart' show LatLng;` |
| Edited edge functions not picked up by the local stack | `docker restart supabase_edge_runtime_aumlux` |
| Two simultaneous `createUser` calls for the same login | GoTrue returns a generic "Database error creating new user", not "already registered"; treat it as a code clash when the login is code-derived. |
| Samsung: app "reloads" on screen off/on and after the camera | `colorMode` missing from `configChanges` recreated the activity (ADR-0004). |
| Debug web build in an emulated viewport dies with `ViewInsets cannot be negative` | Engine debug assertion on simulated resize; review UI on a release build (and beware the browser's HTTP cache of `main.dart.js`). |
| `google-services` Gradle plugin breaks after the package rename | removed; `firebase_options.dart` is enough (re-run `flutterfire configure` for the new package) |

---

## 20. Decision log

Newer decisions are recorded as ADRs in [docs/adr/](docs/adr/README.md): FOSS maps, attendance location visibility, generated employee codes, Android restarts/restoration, full-screen sub-screens.

| Decision | Why |
|---|---|
| **Supabase instead of Firebase** | Firebase Storage and Cloud Functions need Blaze (paid). Supabase's free tier gives Postgres (relational data, constraints, transactions), RLS, RPCs, Storage and Edge Functions at ₹0. |
| **Keep Firebase only for FCM** | Free on Spark; the most reliable Android push. |
| **Business rules in SQL** | One enforcement point; works for every client; testable with pgTAP; safe even against a tampered app. |
| **Live role checks (no custom JWT claims)** | Suspension and demotion take effect immediately; no auth hook to maintain. |
| **Start fresh (no Firestore migration)** | Client decision; old data quality was poor. |
| **Riverpod + go_router + repositories** | Testable, explicit dependencies, declarative auth redirects, per-tab stacks. |
| **Offline outbox (not full sync)** | Covers the field-critical writes (attendance, worksheets, photos, poles) with far less complexity than a sync engine. |
| **GPS check-in with geofence that flags, not blocks** | Sites are often away from the section office; flagging for review is fairer, and `mocked` / `outside` / `no GPS` are all visible to supervisors. |
| **Permit-to-work enforced in the DB** | Safety-critical: no worksheet can start without line clear, earthing, tested dead, toolbox talk and PPE. |
| **Ledger-based inventory** | Auditable history; balances can't drift; overdraws are impossible. |
| **Bonus behind a flag** | The client may or may not adopt it. |
| **Android + Web only** | That's what crews and office use; fewer runners to maintain. |
| **Package `com.aumlux.app`** | Brand-based identity (replaces `com.example.kseb`). |
| **Design: Stripe structure + indigo actions + orange brand accent; Groww/Notion layout cues** | Approved by the product owner. Indigo gives accessible white-on-primary (6.19:1); orange stays as brand identity. |
| **Flutter-native motion instead of Rive (so far)** | Rive needs designer-authored `.riv` files. The motion primitives are where Rive assets would plug in later. |
| **Phased PRs** | Reviewable chunks: phases stack into `revamp/prod-ready`, then one PR into `releases` after staging validation. |

---

## 21. Backlog

- Asset QR labels and scanning.
- Phone OTP login.
- A fully offline-first sync engine (reads cached and editable offline).
- iOS and desktop builds.
- Rive assets for celebratory or empty-state moments (check-in success, onboarding), plugged into the existing motion slots.
- Dark theme (tokens are centralised, so it's mostly a second `ColorScheme`).
- Cloudflare R2 for attachments if storage outgrows 1 GB.
- Real org data import (circles, sections with GPS) once the client provides it.

---

## 22. Glossary

| Term | Meaning |
|---|---|
| **KSEB** | Kerala State Electricity Board, the utility awarding the work |
| **Circle / Division / Sub-division / Section** | KSEB's administrative hierarchy. A Section is the field office that owns local lines. |
| **Line crew** | Field workers who do the electrical work (`staff`) |
| **Worksheet** | One job or work assignment (`WS-YYYY-NNNNN`) |
| **Permit-to-work / Line clear** | Formal authorisation that a line is de-energised and isolated before work |
| **Earthing / Tested dead** | Grounding the isolated line; confirming it's dead with a tester |
| **Toolbox talk** | Pre-job safety briefing |
| **PPE** | Helmet, gloves, safety belt (required to start work) |
| **Polevar** | Pole survey register (pole number, feeder, type, condition, GPS) |
| **Feeder** | A distribution line from a substation |
| **DT / transformer ref** | Distribution transformer the pole or asset belongs to |
| **ACSR** | Aluminium conductor steel-reinforced (overhead conductor; "Rabbit", "Weasel" are sizes) |
| **Tender / NIT** | Invitation to bid for work |
| **EMD** | Earnest money deposit, paid with a bid |
| **SD** | Security deposit, paid on award |
| **BG** | Bank guarantee (has a validity date, hence the expiry alerts) |
| **Retention** | Money withheld from bills until defect liability ends |
| **Work order (WO)** | The award document authorising the work |
| **RA bill** | Running-account (interim) bill; **Final bill** closes the WO |
| **Passed amount** | What KSEB approved on a bill (may be less than claimed) |
| **GSTIN / GSTR-1 / GSTR-3B / GSTR-9** | GST registration number and the monthly/annual returns |
| **HSN code** | Harmonised System code for materials (GST) |
| **Muster roll** | Monthly attendance register (exported PDF/XLSX) |
| **MR** | Material request (`MR-YYYY-NNNNN`) |
| **INC** | Incident report (`INC-YYYY-NNNNN`) |
| **IST** | India Standard Time (UTC+5:30), the business day for attendance |
| **Outbox** | The client's offline queue of writes |
| **RLS** | Postgres row-level security |
| **RPC** | A Postgres function called through PostgREST (`/rest/v1/rpc/<name>`) |
| **Publishable key** | Supabase's public client key (safe in the app; RLS protects data) |
| **Secret key** | Supabase's server key that bypasses RLS. **Never** in the app or the repo. |
