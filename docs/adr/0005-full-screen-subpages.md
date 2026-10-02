# ADR-0005: Sub-screens open full-screen; tabs reset to their root

- **Status:** Accepted (2026-10-02)
- **Area:** `lib/core/router/app_router.dart`, `lib/features/shell/app_shell.dart`

## Context

- Detail pages, forms and registers (Inventory, Staff, Worksheet detail…) opened *inside* their tab, so the bottom navigation bar stayed on screen. That costs space on small phones, and forms ended with their Save button at the bottom of a long scroll.
- The product owner reported: More → Inventory → switch to Attendance → back to More still showed Inventory. The intended behaviour is the More menu itself.

## Decision

- **Tab roots** (`/home`, `/attendance`, `/work`, `/more`) stay in the `StatefulShellRoute`.
- **Every route below a tab root**, at any depth, has `parentNavigatorKey: rootNavigatorKey`, so it opens full-screen above the tab bar, Groww-style. Descendants do **not** inherit it: go_router puts a route without the key on the nearest *shell* navigator, i.e. behind its full-screen parent, where it is invisible. `test/core/router/route_tree_test.dart` walks the tree and fails on any route that misses it.
- **Every modal bottom sheet** opens on the root navigator (`showAppSheet`, or `useRootNavigator: true`). Otherwise a sheet opened from a tab root sits under the bottom navigation bar. Guarded by `test/core/ui/root_sheets_test.dart`.
- **Tapping a tab always opens its root** (`goBranch(index, initialLocation: true)`).
- Forms pin their primary action in a `StickyActionBar` (`Scaffold.bottomNavigationBar`), and detail pages pin their workflow actions the same way.
- The offline banner moved from the shell to the app builder, so full-screen pages show it too.

## Consequences

- More room for content, and an always-visible primary action. Back returns to the tab you came from.
- Deep links and notification routes are unchanged (`/work/<id>`, `/more/inventory/requests/<id>`).
- Leaving a tab and coming back no longer resumes a half-finished sub-flow. This is deliberate (requested); forms are short, and drafts that matter (worksheets) are saved explicitly.

## Revision (2026-10-02)

The first version said descendants inherit the root navigator. They don't. Add staff, staff details, commercial records and the Assets, Polevar and Inventory sub-pages opened hidden behind their parents, so taps seemed to do nothing. All 18 nested routes now set the key explicitly, with the structural test above and a behavioural one (`navigation_flow_test.dart`).

## Alternatives considered

| Option | Why not |
|---|---|
| Keep sub-pages in the tab, but hide the bar per route | Fragile (every route must opt in), and it fights `StatefulShellRoute`. |
| Reset only the More tab | Inconsistent behaviour between tabs. |
