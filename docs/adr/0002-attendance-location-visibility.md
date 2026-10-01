# ADR-0002: Attendance location visibility, and geofence at check-out

- **Status:** Accepted (2026-10-02)
- **Area:** database (`20261002000100_employee_codes_checkout_geofence.sql`) and client (attendance)
- **DB change:** yes, two new columns and a replaced RPC

## Context

Check-in and check-out already store GPS coordinates, accuracy and a mock-location flag (`attendance_days.check_in_*`, `check_out_*`). Until now the app didn't show them anywhere. The product owner asked that:

1. people can see where their attendance was recorded;
2. managers can see where their employees checked in and out.

Only check-**in** recorded the distance to the section office and whether it was outside the geofence. A shift that started on site but ended elsewhere (e.g. "checking out" from home) was invisible.

## Decision

**Visibility (no new access).** Whoever can already read an attendance row can see its locations. That's the existing RLS policy `attendance_read` → `private.can_see_user(user_id)`:

| Viewer | Sees locations of |
|---|---|
| Staff | their own days |
| Supervisor | members of the teams they supervise |
| Manager | everyone in their sections |
| COO / Director | everyone |

No new RPC, view or grant was added. The client simply stops discarding the columns.

**Check-out geofence (DB change).** Add `attendance_days.check_out_distance_m integer` and `check_out_outside_geofence boolean`, and replace `public.check_out(...)` (same signature, so existing grants hold) to compute them with the same `private.geofence_check` used at check-in (nearest of home section and the day's worksite).
- Existing rows keep NULLs. The UI treats NULL as "not computed".
- `needsReview` now also flags a mocked or outside-geofence **check-out**.

**UI.**
- **My attendance:** a map of the check-in (green) and check-out (indigo) pins, the section geofence ring, and the distance, accuracy and inside/outside readout.
- **Team view:** a **List | Map** toggle. The map shows everyone's check-in, coloured green (inside), amber (outside) or red (mock location), with section geofences. Tapping a pin opens that person's day with both points.

## Consequences

- Location data was already collected for this purpose (fraud prevention, crews' explicit consent at first launch through the OS permission plus our rationale screen). Showing it to the same people who could already query it changes no privacy boundary.
- Supervisors can verify a day with evidence instead of trust.
- pgTAP `10_codes_checkout_geofence_test.sql` proves the check-out distance and flag are recorded.

## Alternatives considered

| Option | Why not |
|---|---|
| A dedicated `team_locations()` RPC | Duplicates what RLS already allows; another surface to secure and test. |
| Live location tracking during the shift | A far larger privacy step (background location, battery). It's not what was asked; it would need consent changes and a separate decision. |
| Block check-out outside the geofence | Crews legitimately end shifts at substations and stores. We flag, we don't block (the same rule as check-in). |
