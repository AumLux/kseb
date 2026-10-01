# ADR-0005: Sub-screens open full-screen; tabs reset to their root

- **Status:** Accepted (2026-10-02)
- **Area:** `lib/core/router/app_router.dart`, `lib/features/shell/app_shell.dart`

## Context

- Detail pages, forms and registers (Inventory, Staff, Worksheet detail…) opened *inside* their tab, so the bottom navigation bar stayed on screen. That costs space on small phones, and forms ended with their Save button at the bottom of a long scroll.
- The product owner reported: More → Inventory → switch to Attendance → back to More still showed Inventory. The intended behaviour is the More menu itself.

## Decision

- **Tab roots** (`/home`, `/attendance`, `/work`, `/more`) stay in the `StatefulShellRoute`.
- Every **direct child** of a tab root has `parentNavigatorKey: rootNavigatorKey`. It opens full-screen above the tab bar, Groww-style, and its descendants inherit that.
- **Tapping a tab always opens its root** (`goBranch(index, initialLocation: true)`).
- Forms pin their primary action in a `StickyActionBar` (`Scaffold.bottomNavigationBar`), and detail pages pin their workflow actions the same way.
- The offline banner moved from the shell to the app builder, so full-screen pages show it too.

## Consequences

- More room for content, and an always-visible primary action. Back returns to the tab you came from.
- Deep links and notification routes are unchanged (`/work/<id>`, `/more/inventory/requests/<id>`).
- Leaving a tab and coming back no longer resumes a half-finished sub-flow. This is deliberate (requested); forms are short, and drafts that matter (worksheets) are saved explicitly.

## Alternatives considered

| Option | Why not |
|---|---|
| Keep sub-pages in the tab, but hide the bar per route | Fragile (every route must opt in), and it fights `StatefulShellRoute`. |
| Reset only the More tab | Inconsistent behaviour between tabs. |
