# Design QA

The previous release was audited at 390 px (phone), 820 px (tablet) and
1,440 px (desktop) in Chromium, then redesigned and checked again at the same
sizes in light and dark mode. Severity: **High** blocks or slows the main
task, **Medium** hurts clarity or trust, **Low** is polish.

## Findings and resolutions

| # | Area | Finding (before) | Severity | Resolution (after) |
| --- | --- | --- | --- | --- |
| 1 | Calculator | Every change needed a Calculate press; results went "stale" with a warning instead of updating | High | Live estimates as you type; a pinned total bar on phones |
| 2 | Calculations | Several formulas were wrong for Philippine products (3.785 L "gallons", wallpaper and carpet counted as 4 × 8 ft panels and rugs, corrugated widths that are not sold, roof slope ignored) | High | Formulas rebuilt from Philippine sources; see [calculations.md](calculations.md) |
| 3 | Calculator | Result appeared below the fold after Calculate; with the keyboard open the button was hidden | High | Pinned total bar above the keyboard and navigation; two-pane layout on desktop |
| 4 | Calculator | Dropdowns for two to four options (block size, waste, roof type) took two taps and hid the choices | Medium | Segmented buttons and chips; usual options preselected |
| 5 | Calculator | No defaults; waste allowance was off by default | Medium | Sensible defaults (5% waste, two coats with primer, gable roof…) |
| 6 | Results | Only the material itself; no cement, sand, adhesive, fittings | Medium | "Also needed" list on every result where it applies |
| 7 | Home | No search; finding paint required knowing it is "Architectural" | Medium | Search by English or Filipino words (yero, gripo, pintura…) |
| 8 | Visual | Three icon styles: flat amber category art, black material art, outline navigation icons | Medium | One icon language: every icon tinted on its category colour tile |
| 9 | Visual | Screen titles rendered at about 15 px; desktop titles were lost in the corner | Medium | 28 px page headers aligned with content; 20 px app-bar titles |
| 10 | Visual | Wide letter spacing (Material default 0.5) made body text look loose | Medium | Plus Jakarta Sans with tuned tracking per style |
| 11 | Visual | Amounts used proportional digits, so columns of ₱ values did not line up | Medium | Tabular figures for every amount and quantity |
| 12 | Visual | ₱ came from a fallback font, mismatched with the rest of the text | Low | The new font includes ₱ |
| 13 | Visual | Brown primary buttons looked muddy; amber appeared only in the header | Medium | Bright amber buttons with ink text (8.1:1); amber reserved for actions and totals |
| 14 | Brand | Browser tab and installed app used the default Flutter logo | Medium | House mark on an amber tile for favicon, app icons and the loading screen |
| 15 | Navigation | "Sheet" tab was ambiguous next to plywood and roofing sheets, and a one-time setup took a main tab | Low | "Settings" tab: Google Sheets, appearance, help, about |
| 16 | Summary | Flat list, no grouping; desktop left most of the screen empty | Low | Grouped by category with subtotals, cost-by-category bar, copy as text; table with pinned total on desktop |
| 17 | History | Labels like "CHB 4"" without icon or context; desktop list in an empty page | Low | Material icons, Today/Yesterday groups, the inputs used; list–detail on desktop |
| 18 | Phone layout | Result buttons wrapped into two rows of different widths | Low | Full-width stacked buttons on phones |
| 19 | Phone layout | The service-account e-mail broke mid-word | Low | Breaks after "@" and before dots only |
| 20 | Theme | No dark mode | Low | Dark theme with its own validated colours; system, light or dark |
| 21 | Feedback | Empty forms showed nothing until Calculate, then every error at once | Low | The result area lists what is missing; each field validates once touched |

## Checks after the redesign

| Check | Result |
| --- | --- |
| Text contrast (WCAG AA 4.5:1) | All text tokens pass in both themes (lowest 4.57:1, primary on canvas) |
| Non-text contrast (3:1) | Field outlines 3.7:1 light, 4.6:1 dark; focus ring uses primary |
| Chart colours | Validated for adjacent-segment colour-blind separation in light and dark mode; legend always labelled |
| Touch targets | 48 px minimum, including chips and segmented buttons |
| Keyboard | Every card and button is focusable with a visible ring |
| Screen readers | Headers, live-region totals, labelled icon buttons, step numbers announced |
| Layout | No horizontal overflow at 390, 820 and 1,440 px (browser smoke test) |
| Tests | Unit, widget, golden (including dark mode) and browser smoke tests pass |

## Known limits

- Some sources for Fajardo factors and the PEC are secondary copies; the app
  says estimates are for planning.
- Category art comes from the original illustrations, tinted; a custom icon
  set would sharpen it further.
- Android and iOS projects were not rebuilt in this pass.
