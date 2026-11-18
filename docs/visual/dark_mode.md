# Dark mode — Phase 18

No mockup draws dark mode, so nothing here is Tier A. The treatment is the one
decided in Phase 00: raster art does not re-tint; surfaces swap and a scrim
lies over the scenes. Captured through the real setting (Settings → Theme →
Dark, seeded by `integration_test/capture_test.dart`), so every `dark.png`
also proves the preference is applied.

| Screen | Capture |
|---|---|
| Home, Alarms, Add/Edit, Stats, Settings, Ringing | `docs/visual/<screen>/dark.png` |
| Onboarding, puzzle chooser (dark only — no block table) | `docs/visual/onboarding/dark.png`, `docs/visual/puzzle_chooser/dark.png` |

`tool/capture.sh` verifies each like `actual.png` (size, freshness, no banner).

## Defects found and fixed

| Where | Before | Found by | Fix |
|---|---|---|---|
| Header, three tabs | wordmark and gear in cocoa on the night page — invisible | capture (wordmark), gate (gear, 1.05:1) | the one-ink wordmark re-inked `darkInk` via `srcIn`; gear `darkInk` |
| Ringing | a cream band under the scene | capture | `darkCream` page |
| Reliability checklist | "needs attention" card stayed light clay under light ink (1.02:1) | gate | `darkSurfaceAlt` |
| Alarms, disabled row (both themes) | faded to 0.55 — label 3.16:1 dark, 2.09:1 light; the mockup draws it at full ink | gate (opacity folded in) | no fade; the toggle carries the state |
| Reliability, light | body text 3.89:1 on the clay warning fill | gate, light run | `cocoa` while warning |

## What the gate cannot see

`test/design/text_contrast_test.dart` composites each text span with the
fills, opacities and painted-below `Stack` siblings behind it, in both themes.
It cannot see raster lettering (the wordmark, found by capture, has its own
test) or measure text over a raster scene — those are counted per screen as
`art` and judged by the captures.

## Counted, not fixed

White on the brand orange (2.07:1) and on grass (2.36:1), and orange icons on
white chips (2.85:1), fail in both themes. It is the Phase 02 palette
constraint, the owner's call (`OPEN_QUESTIONS.md`); the gate pins the count per
screen so a new one is deliberate.
