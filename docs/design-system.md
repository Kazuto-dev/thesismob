# BuildQuantify design system

The look is **ink and amber**: a warm, paper-like canvas for everyday
content, and a dark "ink" panel with a faint blueprint grid for the numbers
that matter (the home header, an estimate and the project total). Amber is
the construction accent; four category colours help people find their way.

Everything is defined in [`lib/core/theme.dart`](../frontend/lib/core/theme.dart) and
the shared components in [`lib/core/widgets.dart`](../frontend/lib/core/widgets.dart).
The app follows the system light or dark setting, and Settings → Appearance
can override it.

## Colour

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| Canvas (`surface`) | `#F6F4F0` | `#12100E` | Page background |
| Raised (cards, inputs, bars) | `#FFFFFF` | `#1A1715` | Cards and fields |
| Text (`onSurface`) | `#1C1917` | `#F5F5F4` | Body text, 15.9:1 / 17.4:1 |
| Muted text (`onSurfaceVariant`) | `#57534E` | `#C8C2BA` | Secondary text, 7.0:1 / 9.8:1 |
| Primary | `#B45309` | `#FBBF24` | Links, focus rings, selected states, 5.0:1 / 10.4:1 |
| Brand (button fill) | `#F59E0B` | `#FBBF24` | Primary buttons, with ink text, 8.1:1 |
| Ink panel | `#1C1917` | `#26221F` | Brand panels |
| Ink accent | `#FBBF24` | `#FCD34D` | Amounts on ink, 10.5:1 |
| Outline | `#8C847B` | `#8A837B` | Field borders, 3.7:1 / 4.6:1 |
| Error | `#B91C1C` | `#F87171` | Validation |

Category colours (icon on its container passes 4.5:1 in both modes):

| Category | Icon / container (light) | Icon / container (dark) | Chart |
| --- | --- | --- | --- |
| Structural | `#C2410C` / `#FFEDD5` | `#FDBA74` / `#3B1A0A` | orange |
| Architectural | `#047857` / `#D1FAE5` | `#6EE7B7` / `#052E22` | aqua |
| Electrical | `#A16207` / `#FEF9C3` | `#FDE047` / `#3A2E05` | yellow |
| Plumbing | `#1D4ED8` / `#DBEAFE` | `#93C5FD` / `#0B2550` | blue |

The chart colours (orange, aqua, yellow, blue, in that order) pass the
colour-blind separation checks for neighbouring segments in light and dark
mode. The cost-by-category bar always has a labelled legend with amounts, so
colour is never the only cue.

## Type

Plus Jakarta Sans, subset to Latin plus ₱, ×, ², ½ and arrows (about 24 KB
per weight). It has tabular figures, used for every amount and quantity so
columns line up.

| Style | Size / line | Weight |
| --- | --- | --- |
| Display small | 36 / 44 | 800 |
| Headline large / medium / small | 32 / 28 / 24 | 800 / 800 / 700 |
| Title large / medium / small | 20 / 16 / 14 | 700 |
| Body large / medium / small | 16 / 14 / 13 | 400 |
| Label large / medium / small | 14 / 12 / 11 | 600–700 |

## Space, shape and layout

- Spacing on a 4 px grid: 4, 8, 12, 16, 24, 32, 48.
- Radii: 10 (chips), 14 (fields, icon tiles), 20 (cards), 28 (panels and
  sheets). Buttons are pills.
- Breakpoints: under 600 px a bottom navigation bar; 600–1023 px a labelled
  rail; 1024 px and up an extended rail with the active project's total, a
  two-pane calculator, a project page with the budget beside the items, and
  a list–detail history.
- Content is centred with a 16 px gutter on phones and 32 px elsewhere, and
  capped at 1,040 px (680 px for single-column forms).
- Touch targets are at least 48 px on every platform.

## Components

| Component | Purpose |
| --- | --- |
| `InkPanel` | Dark brand panel with blueprint grid; content inside uses the dark theme |
| `IconTile` | Material or category icon tinted on its category container |
| `TapCard` | Card with hover border and a 2.5 px focus ring |
| `PageHeader` | Large page title aligned with the content |
| `SectionHeader` | Section title with an optional action |
| `KeyValueLine` | Label and tabular value, for breakdowns |
| `ProportionBar` | Stacked share bar with a labelled legend and tooltips |
| `EmptyState` | Icon, title, message and one action |
| `BrandMark`, `BrandLockup` | Logo tile and logo with name |

## Patterns

- **Live estimates.** Calculators have no Calculate button. The result
  updates as you type; until then, the result area lists what is still
  missing. On phones and tablets a dark bar pinned above the navigation shows
  the live total with an Add button.
- **Choices you can see.** Two to four short options are a segmented button,
  up to eight are chips, and longer lists fall back to a menu. Usual choices
  start selected.
- **Also needed.** Results list companion materials (cement, sand, rebar,
  adhesive, valves…) as planning quantities that are not part of the cost.
- **History records itself.** The latest result of each visit to a calculator
  is saved a moment after you stop typing, and again when you leave.
