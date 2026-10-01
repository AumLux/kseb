---
version: 1.0
name: AumLux-design-system
basis: "Stripe DESIGN.md (getdesign.md/stripe) — structure, type rhythm, hairlines, tabular numerics, pill actions — re-keyed to the AumLux orange accent and hardened for outdoor field use."
description: "A calm, white-canvas operations UI for a KSEB electrical contractor. Deep navy ink (#0d253d) carries all text; Stripe indigo (#533afd) is the action colour (one filled pill per screen, active states, links); AumLux orange (#FF6B35) is the brand accent, living in the logo and the gradient mesh. Surfaces are white and cool off-white separated by 1px hairlines. Every number that represents money, quantity, count or time uses tabular figures. Controls are large (48dp minimum) and high-contrast because the primary users are line crews working in direct sunlight with gloves."

colors:
  # Brand
  primary: "#533afd"            # indigo: filled CTAs, active nav, selection, links
  on-primary: "#ffffff"         # white on indigo = 6.19:1
  primary-press: "#2e2b8c"
  primary-deep: "#4434d4"
  primary-soft: "#eeebff"       # nav indicator, selected rows, soft tags
  primary-ink: "#4434d4"        # indigo AS TEXT/ICON on white (7.1:1)
  brand-dark: "#1c1e54"         # featured KPI card, inverse surfaces
  # Brand accents: logo, gradient mesh, highlights. Never body text or a button fill.
  brand-orange: "#FF6B35"
  brand-orange-ink: "#B93D10"   # orange as text/icon on white (5.62:1)
  ruby: "#ea2261"
  magenta: "#f96bee"
  lavender: "#b9b9f9"
  cream: "#f5e9d4"
  # Ink
  ink: "#0d253d"                # body + headings (15.57:1 on white)
  ink-secondary: "#273951"      # secondary text (11.73:1)
  ink-mute: "#5b6b84"           # helper text, captions, table labels (5.41:1 white / 5.12:1 canvas-soft)
  ink-disabled: "#9aa6b8"       # disabled text only (exempt from contrast)
  on-dark: "#ffffff"
  # Surfaces
  canvas: "#ffffff"
  canvas-soft: "#f6f9fc"        # page background behind cards, table header rows
  canvas-sunken: "#eef2f7"      # pressed rows, skeletons
  hairline: "#e3e8ee"           # decorative dividers, card borders
  border-input: "#7f8ea6"       # input / checkbox / radio outlines (3.32:1, meets WCAG 1.4.11)
  focus-ring: "#533afd"
  scrim: "#0d253d99"
  # Semantic (fg = text/icon, bg = tint). Every fg/bg pair ≥ 4.5:1.
  success: "#137a3f"
  success-bg: "#e7f6ed"
  warning: "#8a5300"
  warning-bg: "#fff4db"
  danger: "#c4213f"
  danger-bg: "#fdecef"
  info: "#1d5fd1"
  info-bg: "#eaf1fd"

typography:
  # Inter (bundled, OFL) substitutes Stripe's Sohne. Noto Sans Malayalam is the fallback for ml.
  # Weight 300 is permitted ONLY at >= 28px. Body never goes below 400 (outdoor legibility).
  display:      { fontFamily: Inter, fontSize: 32px, fontWeight: 300, lineHeight: 1.15, letterSpacing: -0.64px }
  headline:     { fontFamily: Inter, fontSize: 24px, fontWeight: 400, lineHeight: 1.20, letterSpacing: -0.3px }
  title:        { fontFamily: Inter, fontSize: 20px, fontWeight: 500, lineHeight: 1.30, letterSpacing: -0.2px }
  subtitle:     { fontFamily: Inter, fontSize: 17px, fontWeight: 500, lineHeight: 1.35, letterSpacing: 0 }
  body:         { fontFamily: Inter, fontSize: 15px, fontWeight: 400, lineHeight: 1.45, letterSpacing: 0 }
  body-strong:  { fontFamily: Inter, fontSize: 15px, fontWeight: 600, lineHeight: 1.45, letterSpacing: 0 }
  body-tabular: { fontFamily: Inter, fontSize: 15px, fontWeight: 500, lineHeight: 1.40, letterSpacing: -0.2px, fontFeature: tnum }
  kpi:          { fontFamily: Inter, fontSize: 28px, fontWeight: 400, lineHeight: 1.10, letterSpacing: -0.5px, fontFeature: tnum }
  label:        { fontFamily: Inter, fontSize: 14px, fontWeight: 500, lineHeight: 1.30, letterSpacing: 0 }
  button:       { fontFamily: Inter, fontSize: 16px, fontWeight: 600, lineHeight: 1.00, letterSpacing: 0 }
  caption:      { fontFamily: Inter, fontSize: 13px, fontWeight: 400, lineHeight: 1.40, letterSpacing: 0 }
  overline:     { fontFamily: Inter, fontSize: 12px, fontWeight: 600, lineHeight: 1.20, letterSpacing: 0.6px, textTransform: uppercase }

spacing: { xxs: 2px, xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 24px, xxl: 32px, xxxl: 48px, huge: 64px }

rounded: { xs: 4px, sm: 6px, md: 8px, lg: 12px, xl: 16px, pill: 9999px }

elevation:
  level-0: "none (default — prefer hairlines)"
  level-1: "0 1px 3px rgba(0,55,112,0.08)"                                   # cards on canvas-soft
  level-2: "0 8px 24px rgba(0,55,112,0.08), 0 2px 6px rgba(0,55,112,0.04)"   # sheets, menus, dialogs, bottom nav

touch:
  min-target: 48dp
  primary-action-height: 52dp
  list-row-min-height: 56dp

motion:
  fast: 120ms
  base: 200ms
  slow: 280ms
  curve: easeOutCubic
  reduce-motion: "respect MediaQuery.disableAnimations — cross-fade only"

components:
  button-primary:   { background: "{colors.primary}", text: "{colors.on-primary}", typography: "{typography.button}", rounded: "{rounded.pill}", height: 52dp, padding: "0 24px" }
  button-primary-pressed: { background: "{colors.primary-press}", text: "{colors.on-primary}" }
  button-secondary: { background: "{colors.canvas}", text: "{colors.ink}", border: "1px {colors.border-input}", rounded: "{rounded.pill}", height: 48dp }
  button-tertiary:  { background: transparent, text: "{colors.primary-ink}", typography: "{typography.label}", height: 48dp }
  button-danger:    { background: "{colors.danger}", text: "{colors.on-dark}", rounded: "{rounded.pill}", height: 48dp }
  text-input:       { background: "{colors.canvas}", text: "{colors.ink}", border: "1px {colors.border-input}", rounded: "{rounded.sm}", height: 52dp, padding: "0 12px", label: "{typography.label} above field" }
  text-input-focused: { border: "2px {colors.focus-ring}" }
  text-input-error: { border: "2px {colors.danger}", helper: "{colors.danger} {typography.caption}" }
  card:             { background: "{colors.canvas}", border: "1px {colors.hairline}", rounded: "{rounded.lg}", padding: "{spacing.lg}", elevation: level-1 }
  card-kpi:         { background: "{colors.canvas}", border: "1px {colors.hairline}", rounded: "{rounded.lg}", value: "{typography.kpi}", label: "{typography.caption} {colors.ink-mute}" }
  card-featured:    { background: "{colors.brand-dark}", text: "{colors.on-dark}", rounded: "{rounded.lg}" }
  list-row:         { minHeight: 56dp, padding: "12px 16px", divider: "1px {colors.hairline}", trailing: "status chip or chevron" }
  table:            { header: "{colors.canvas-soft} {typography.overline} {colors.ink-mute}", row: "{typography.body}", numericColumns: "{typography.body-tabular} right-aligned", divider: "1px {colors.hairline}" }
  status-chip:      { rounded: "{rounded.pill}", padding: "4px 10px", typography: "{typography.label}", variants: "neutral|info|success|warning|danger|brand (fg on matching bg)" }
  app-bar:          { background: "{colors.canvas}", text: "{colors.ink}", typography: "{typography.title}", bottomBorder: "1px {colors.hairline}", elevation: none, centerTitle: false }
  bottom-nav:       { background: "{colors.canvas}", elevation: level-2, active: "{colors.primary} pill indicator behind icon, label {colors.ink}", inactive: "{colors.ink-mute}" }
  sheet-dialog:     { background: "{colors.canvas}", rounded: "{rounded.xl} top corners (sheet) / {rounded.lg} (dialog)", elevation: level-2 }
  banner-offline:   { background: "{colors.warning-bg}", text: "{colors.warning}", icon: cloud_off, typography: "{typography.label}" }
  sync-badge:       { background: "{colors.info-bg}", text: "{colors.info}", content: "N pending" }
  empty-state:      { icon: "48dp {colors.ink-mute}", title: "{typography.subtitle}", body: "{typography.body} {colors.ink-mute}", action: button-secondary }
  error-state:      { icon: "48dp {colors.danger}", title: "{typography.subtitle}", body: "plain-language cause + what to do", action: "button-secondary 'Try again'" }
  skeleton:         { background: "{colors.canvas-sunken}", rounded: "{rounded.sm}", shimmer: "disabled when reduce-motion" }
---

# AumLux Design System

## Overview

AumLux is the operations system for a contractor that builds and repairs KSEB distribution infrastructure: transformers, poles, conductors and service lines. Three kinds of people use it, and the design has to work for all three:

| Persona | Context | What the UI must do |
|---|---|---|
| **Line crew (staff)** | Outdoors, direct sun, gloves, patchy 4G, often Malayalam-first | Huge tap targets, one obvious action, high contrast, works offline, minimal typing |
| **Supervisor / Manager** | Site and section office, phone and occasionally web | Fast scanning of lists, approve and reject in two taps, clear status |
| **COO / Director / Office** | Desk, web, long sessions | Dense tables, tabular money, filters, exports, KPI overview |

The language borrows **Stripe's** structure: white canvas, deep navy ink instead of black, 1px hairlines instead of heavy shadows, tabular figures wherever numbers matter, and pill-shaped actions. Actions are **Stripe indigo**; **AumLux orange** is the brand accent (logo, gradient mesh). Layout and density take cues from **Groww** (hero card, round shortcuts, big thin numbers) and **Notion** (icon-tile rows, calm white pages). Stripe's thin type is used for display sizes only (≥ 26px); all reading text is 400 or heavier, because thin type disappears in sunlight.

**Key characteristics**
- One filled indigo pill per screen: the primary action. Everything else is secondary, tertiary or a list row.
- The gradient mesh (cream → orange → lavender → indigo → ruby) washes the top of Home and Sign-in; content floats over it on white cards.
- Navy ink `#0d253d` for text; never pure black.
- Hairline-first separation (`#e3e8ee`); shadows only on floating layers.
- Tabular numbers (`tnum`) for every amount, quantity, count, date column and time.
- Status is always colour **plus** text **plus** icon, never colour alone.
- Offline is a first-class state with a banner, a pending-sync badge and optimistic rows.

## Colors

### Primary and accent (accessibility-critical)
- **Indigo `#533afd`** carries actions: filled buttons (white text, 6.19:1), active nav, checkboxes, focus rings. As text or icons use `primary-ink #4434d4` (7.1:1).
- **AumLux orange `#FF6B35`** is the brand accent. White on orange is **2.84:1**, so orange is never a button fill or a text background. As text, use `brand-orange-ink #B93D10` (5.62:1).
- **Gradient mesh:** blobs are kept pale enough that ink text over them stays ≥ 7:1 (`test/core/design/contrast_test.dart`).

### Ink
| Token | Hex | On white | Use |
|---|---|---|---|
| ink | `#0d253d` | 15.6:1 | Headings, body, values |
| ink-secondary | `#273951` | 11.7:1 | Secondary lines in rows |
| ink-mute | `#5b6b84` | 5.4:1 | Labels, captions, helper text, table headers |
| ink-disabled | `#9aa6b8` | n/a | Disabled only |

### Surfaces
`canvas #ffffff` for cards and sheets; `canvas-soft #f6f9fc` for page backgrounds and table headers; `canvas-sunken #eef2f7` for pressed and skeleton states. Use `hairline #e3e8ee` for dividers and card borders. Use `border-input #7f8ea6` for anything interactive that needs a visible boundary (inputs, checkboxes, secondary buttons), which meets the 3:1 non-text contrast requirement.

### Semantic
| State | fg | bg | Typical use |
|---|---|---|---|
| success | `#137a3f` | `#e7f6ed` | Approved, Present, Paid, In stock |
| warning | `#8a5300` | `#fff4db` | Pending, Expiring soon, Low stock, Offline |
| danger | `#c4213f` | `#fdecef` | Rejected, Absent, Overdue, Out of stock, Incident |
| info | `#1d5fd1` | `#eaf1fd` | Submitted, Syncing, Informational |
| brand | `#B93D10` | `#ffe9df` | Draft, Mine, Highlighted |

### Status mapping (single source of truth)
| Domain status | Chip |
|---|---|
| draft | brand |
| submitted / pending / awaiting approval | warning |
| approved / present / paid / passed / released / completed | success |
| rejected / absent / forfeited / cancelled / overdue | danger |
| in_progress / syncing / opened | info |
| leave / holiday / half_day | neutral (ink-secondary on canvas-sunken) |

## Typography

**Family:** Inter, bundled as an app asset so it never fetches at runtime (crews are often offline). **Noto Sans Malayalam** is the fallback for Malayalam glyphs. For Malayalam text, letter-spacing is forced to 0 and line height to at least 1.5, because negative tracking breaks conjuncts.

| Token | Size / Weight / LH | Use |
|---|---|---|
| display | 34 / 300 / 1.1, tnum | Home greeting name, sign-in title, hero numbers |
| headline | 26 / 300 / 1.15 | Large screen titles |
| title | 20 / 600 / 1.25 | App bar, sheet and dialog titles |
| subtitle | 17 / 600 / 1.3 | Card titles, section headers |
| body | 15 / 400 / 1.45 | Default text |
| body-strong | 15 / 600 | Emphasis inside body, row primary text |
| body-tabular | 15 / 500, `tnum` | Money, quantities, counts, times in rows and tables |
| kpi | 28 / 400, `tnum` | KPI card values |
| label | 14 / 500 | Field labels, chips, tertiary buttons |
| button | 16 / 600 | Button labels |
| caption | 13 / 400 | Helper text, metadata |
| overline | 12 / 600 / +0.6 uppercase | Table headers, group labels (English only; Malayalam uses `label`) |

**Principles**
- Never go below 13px. Never use 300 below 28px.
- Money is always `₹ 1,23,456.00`: Indian digit grouping via `intl` `en_IN`, tabular, right-aligned in tables.
- Dates are `dd MMM yyyy` (`01 Oct 2026`) in lists; times are `hh:mm a`. Show relative time ("2h ago") only as secondary metadata.

## Layout

- **Spacing scale:** 2, 4, 8, 12, 16, 24, 32, 48, 64. Base unit 8, with 4 and 12 for fine work.
- **Screen padding:** 16 on phones, 24 on tablet and web.
- **Content width:** forms max out at 640px wide; tables and dashboards at 1200px, centred on web.
- **Breakpoints:**
  - compact < 600 (phone): bottom nav, single column, full-screen forms.
  - medium 600–1024: navigation rail, 2-column card grids.
  - expanded ≥ 1024 (web, office): side navigation, master-detail, data tables.
- **Lists over grids** for operational data. Grids of icon tiles are reserved for the home launcher.
- **Forms:** one column, label above field, required fields marked `*`, and the primary action pinned to the bottom safe area on phones.

## Elevation & depth

Level 0 (flat with hairline) is the default. Level 1 is for cards sitting on `canvas-soft`. Level 2 is only for things that float: bottom sheets, dialogs, menus, the bottom navigation and snackbars. No coloured shadows, no gradients in product UI. The `brand-dark` featured card is the one "inverse" accent surface allowed per dashboard.

## Shapes

| Token | Value | Use |
|---|---|---|
| xs | 4 | Table chrome, tiny tags |
| sm | 6 | Inputs, checkboxes |
| md | 8 | Compact cards, banners, snackbars |
| lg | 12 | Cards, dialogs |
| xl | 16 | Bottom-sheet top corners |
| pill | 9999 | All buttons, status chips, segmented controls, nav indicator |

## Components

### Buttons
- **Primary:** orange pill, navy label, 52dp tall, full-width on phones. One per screen.
- **Secondary:** white pill with a `border-input` outline and navy label, 48dp.
- **Tertiary:** text-only `primary-ink`, 48dp hit area. Used for "View all", "Edit", "Cancel".
- **Danger:** `danger` fill with a white label. Only inside a confirmation dialog, never as the first tap.
- **Loading state:** keep the width, swap the label for a 20dp spinner, and disable the button (prevents double submits).

### Inputs
Label above (`label`, ink), 52dp field, 6px radius, `border-input` outline. Focus is a 2px `focus-ring`; error is a 2px `danger` border plus a caption that says what to fix. Use numeric keyboards for quantities and amounts, a date picker for dates (never free text), and a searchable picker for any list over 7 items (sections, materials, staff).

### Cards and KPIs
White card, 1px hairline, 12px radius, 16px padding. A KPI card shows a `caption` label, a `kpi` value (tabular), and an optional delta chip. A dashboard row holds 2 KPIs on phones and 4 on web.

### Lists and tables
- **Phone:** list rows (56dp min). The primary line is `body-strong`; the secondary line is `caption` ink-mute; on the right sits a status chip or a tabular value.
- **Web:** data tables with a sticky `overline` header on `canvas-soft`, right-aligned numeric columns, row hover `canvas-soft`, and a selected row `primary-soft`.
- Every list has search, filters (as chips), pull-to-refresh on mobile, pagination or infinite scroll, and an empty state.

### Status chips
Pill, label typography, fg on bg from the semantic table, a leading 16dp icon (check, clock, x, info, edit). The text is always present.

### Navigation
- Bottom nav with at most 4 destinations on phones: **Home · Attendance · Work · More**. The active item gets an orange pill indicator behind the icon.
- Web uses a left side nav grouped as Operations / Inventory / Commercial / Admin.
- Each app bar has a left-aligned title, a hairline bottom border, and at most 2 actions.

### Feedback
- **Snackbar** (md radius, level 2, bottom) for confirmations: "Check-in saved".
- **Banner** for persistent states: offline, pending sync, app update required.
- **Dialog** only for destructive or irreversible confirmation. The title states the consequence ("Disable login for Ravi K?").
- **Error copy** is in plain language: cause, then what to do. Never show raw exceptions to users; log them to Crashlytics.

### Offline & sync
- An offline banner (warning) appears at the top while there's no connectivity.
- Items queued in the outbox show an info `Pending sync` chip and are fully readable.
- A sync failure turns the row into a danger chip with "Retry".
- Never block check-in, check-out or worksheet capture for lack of connectivity.

## Field-use & accessibility rules

1. Contrast: text ≥ 4.5:1; large text and UI boundaries ≥ 3:1. Checked tokens are listed above.
2. Touch targets ≥ 48dp, with ≥ 8dp between adjacent targets. Primary actions are 52dp.
3. Never rely on colour alone. Pair it with text and an icon.
4. Support system text scaling up to 1.3× without clipping. Test at 1.3×.
5. Every icon-only button has a tooltip and a semantics label.
6. Respect reduce-motion: no shimmer, no slide; cross-fade only.
7. Camera and GPS flows explain *why* before the OS prompt (rationale sheet).
8. Every string is localised (en, ml). No string concatenation for sentences; use ICU placeholders.

## Iconography

Material Symbols Rounded at a 24dp default (20dp in dense tables, 48dp in empty states). The icon colour follows its text colour. Domain icons: `bolt` (brand), `electrical_services` (pole), `transform` / `power` (transformer), `inventory_2` (materials), `assignment` (worksheet), `fingerprint` / `how_to_reg` (attendance), `request_quote` (bills), `account_balance` (deposits/GST), `gavel` (tenders), `health_and_safety` (permit/safety).

## Screen patterns (UI revamp 2)

- **Lists:** every row leads with a visual (icon tile, `DateBlock` or `Avatar`); dividers are inset to the text column.
- **Filters:** pills; selected = ink fill with a white label, no checkmark.
- **Details:** `DetailHeader` (icon, title, code line, status), headline numbers in a `StatStrip`, facts in an `InfoGroup`, location in a `LocationPreview`, workflow actions in a `StickyActionBar`.
- **Forms:** labels above fields, the primary action pinned in a `StickyActionBar`; short inputs and choices in bottom sheets (`SheetScaffold`), never centred dialogs.
- **Navigation:** sub-screens open full-screen above the tab bar; a tab tap returns to its root.
- **Maps:** OpenStreetMap via `AppMap`, with brand pins and the geofence ring in indigo. Attribution is always visible.
- **Long text (Malayalam):** chips cap their width and truncate; buttons that sit side by side wrap to a second line. Every dense screen is covered by `test/l10n/malayalam_layout_test.dart`.

## Brand mark

An "A" drawn as a transmission pylon: two legs, a crossarm with insulators, and a lattice bar. It sits in white on the orange → ruby → indigo tile. One geometry, in a 108-unit square (the adaptive-icon canvas), feeds every output:

- **In app:** `BrandMarkPainter` (`lib/core/design/widgets/brand_mark.dart`).
- **Android vectors:** `ic_launcher_*` (adaptive and themed icon), `splash_logo`, and the Android 12+ animated `splash_icon`, where the pylon draws itself.
- **PNGs:** legacy mipmaps, web, maskable and favicon, rendered from the painter with `flutter test tools/brand/render_icons_test.dart`.

## Motion

The goal is snappy, not showy. The UI answers the finger within one frame, and nothing blocks input.

| Pattern | Spec |
|---|---|
| Page transition | The incoming page rises 3% and fades in: 260ms in, 200ms out, emphasized-decelerate. Only one layer moves and nothing is scaled. |
| Press | `PressScale`: 0.97 (0.93 for shortcuts) over 90ms, springs back with easeOutBack. Selection haptic on tap. |
| Entrance | `FadeSlideIn`: 12px rise and fade, 320ms, staggered 40ms per item (capped at 6). Timer-free. |
| Loading | `Skeleton` rows shaped like the content, with a single pulse. No spinners for lists. |
| Splash | The native pylon draws itself in 700ms; the Flutter splash continues the same drawing. |
| Reduced motion | Every animation honours the OS setting (`reduceMotion(context)`). |

Lists with data must use `LazyListView` or `ListView.builder`, never `ListView(children: [for ...])`.

## Do / Don't

| Do | Don't |
|---|---|
| Use one indigo primary per screen | Put white text on orange, or use orange as a button |
| Use navy ink for text | Use pure black or grey-on-grey text |
| Use tabular figures for all numbers | Mix proportional digits in columns |
| Use hairlines to separate | Stack shadows or use gradients in product UI |
| Pair status colour with text and an icon | Use colour-only status dots |
| Keep forms single-column with labels above | Use placeholder-as-label |
| Use plain-language errors with a next step | Show `Exception: [cloud_firestore/permission-denied]` |
| Use 48dp+ targets | Use tiny icon buttons in field flows |

## Flutter mapping

| DESIGN.md | Flutter |
|---|---|
| colors.* | `AppColors` (`lib/core/design/app_colors.dart`) → `ColorScheme(primary: primary, onPrimary: onPrimary, surface: canvas, onSurface: ink, outline: borderInput, outlineVariant: hairline, error: danger …)` |
| typography.* | `AppTypography` → `TextTheme` (`displaySmall=display`, `headlineSmall=headline`, `titleLarge=title`, `titleMedium=subtitle`, `bodyLarge=body`, `labelLarge=button`, `labelMedium=label`, `bodySmall=caption`) and `FontFeature.tabularFigures()` for `body-tabular` and `kpi` |
| spacing / rounded / elevation | `AppSpacing`, `AppRadius`, `AppShadows` |
| components.* | `lib/core/design/widgets/` (`AppButton`, `AppTextField`, `AppCard`, `KpiCard`, `StatusChip`, `AppListRow`, `AppDataTable`, `OfflineBanner`, `SyncBadge`, `EmptyState`, `ErrorState`) |
| Status mapping | `StatusChip.fromDomain(String status)`, the only place the status → colour mapping lives |
