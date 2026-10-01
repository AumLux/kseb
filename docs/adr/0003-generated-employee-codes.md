# ADR-0003: Employee codes generated server-side, race-safe

- **Status:** Accepted (2026-10-02)
- **Area:** database (`20261002000100_…sql`), edge function `admin-users`, staff form
- **DB change:** yes, one function and one settings key

## Context

When adding staff, the manager had to invent the employee ID. The product owner wants the **next available ID generated automatically** (`AUM0001`-style). Crew sign in with this code, so it must be unique **org-wide**, even though a manager can only *see* people in their own sections.

Two managers can add staff at the same moment, so "read the max and add one" in the app would hand both of them the same code.

## Decision

- **Format** lives in `app_settings.employee_code_format` = `{"prefix": "AUM", "digits": 4}`. It's changeable without a release; the width grows naturally past 9999.
- `private.generate_employee_code()` (SECURITY DEFINER, so it sees **all** profiles regardless of RLS):
  - takes the highest number among codes matching `^PREFIX[0-9]+$` (case-insensitive) and adds one;
  - ignores codes that don't follow the pattern (legacy or custom).
- `public.next_employee_code()` is a manager-and-above wrapper, used to **preview** the code on the Add Staff form.
- `admin-users` `create` accepts **`auto_code: true`**. It allocates via `next_employee_code()` *as the caller*, then provisions. If the code is taken (a profile unique violation, or the derived crew login already exists, including GoTrue's generic "Database error creating new user" when two creates race), it **retries with a fresh code**, up to five times. Each failed attempt is fully compensated (the auth user is deleted).
- The form shows the suggestion read-only, with **"Use a custom ID"** for legacy numbering. The credentials sheet shows the code that was actually assigned, which may differ from the preview after a race.

## Consequences

- Verified live: two simultaneous creates produced AUM0305 and AUM0306, with no errors.
- pgTAP covers the format, the org-wide max, case handling, ignored custom codes, the role check and anon lockout.
- **Migration policy note:** this is the first migration after `…000900_lockdown.sql`. Lockdown is already applied in staging, so it isn't edited. New migrations grant their own RPCs, and the baseline test still asserts that anon can execute nothing.

## Alternatives considered

| Option | Why not |
|---|---|
| A Postgres sequence | Gaps on every failed create, and it can't adopt existing codes or change the format without DDL. |
| `doc_counters` (as for WS/MR numbers) | Yearly counters; employee codes aren't year-scoped and must respect existing data. |
| Generate in the app | Races; and managers can't see other sections, so they can't compute an org-wide max. |
