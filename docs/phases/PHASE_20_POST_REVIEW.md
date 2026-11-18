# Phase 20 — Post-review

## Result

Five screens replace the long Settings page and the one-page puzzle chooser:
Settings overview, Wake puzzle overview, Games, Puzzle types, Advanced. Every
setting the two old screens held is reachable within two pushes of Settings
(`settings_screen_test`, "every puzzle setting is two pushes from Settings").
No file under `lib/core/` or `lib/data/` changed; persistence and the escape
rules are the ones Phase 10 shipped.

## Tier A — Settings (`01_SETTINGS_REFINED.png`)

| Block | Ref | Actual | Delta |
|---|---|---|---|
| header band lower edge | 78.4 | 88.0 | +9.6 ❌ named (44 pt back control) |
| hero scene lower edge | 180.4 | 180.3 | −0.1 ✅ |
| group 1 card top | 201.1 | 201.3 | +0.2 ✅ |

Measured on the capture by the mockup's own methods; `compare.dart` reports
the last two `absent` (column-scan blind spot under art,
`docs/visual/settings/README.md`). Blocks below group 1 move by design (44 pt
rows) and are not claimed. The other four references are composite crops and
bind structure only; their deviations are named per screen in
`docs/visual/puzzle_*/README.md`.

## Tier B

| Element | Used | Gap |
|---|---|---|
| Wake puzzle hero with nightcap (`02`) | `scene.settings`, bare-headed | **G49**, reported |
| Settings hero, theme tiles, game tiles, puzzle icons, mascot, meadow, cloud | the production assets — exact matches | none |

Nothing from the package's `02_ASSETS/` was imported.

## Found by capture, not by tests

1. **Puzzle types grid inherited the status-bar inset as padding** — ~100 pt
   empty bands above and below each group. Widget tests run with no inset and
   were green. Fixed, then the grid replaced entirely (U2); a test now sets a
   59.1 pt inset, mutation-checked against the original fix.
2. **Hero 4.5 pt high:** the cloud scallop hides the art's lower band, so the
   arithmetic band (92.4) put the edge at 175.7. Band 96.9, re-measured −0.1.
3. **"0 of 10 selected" wrapped** in the Games card at 1× English; the card's
   icon and padding were tightened.

## Reviews

Pre-review 18 findings (3 High), self-review #1 10, self-review #2
(unanchored subagent) 12, full-project 6 — every one applied or invalid with
a reason. Five guards were mutation-checked: pool-floor lock (both screens),
the toggle's semantic tap, the grid inset, and the header's 2× height (whose
first test version passed with the defect restored and was rewritten).

## Validation

2,629 tests; analyze clean; format, ARB (10 locales), bundle size, fake-stats
gates pass; coverage lib 98.72%, `lib/core` 99.74%, `lib/data` 91.20%.
iOS simulator only (iPhone 14 Pro, iOS 16.4). **Android not run.** No real
device.

## Not done

- **Not committed:** this checkout also holds the "Home stats removal"
  session's uncommitted work in the same files (P6).
