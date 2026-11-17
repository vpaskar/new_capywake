# Puzzle chooser + onboarding puzzle/strictness — visual notes (Phase 10)

## Tier A binds nothing — and this is measured, not assumed

The owner supplied three references in
`CapyWake_Puzzle_Chooser_Onboarding_Handoff` (2026-11-17), copied into
`reference/01_REFERENCES/`:

| File | Pixel size | Native 393×852? |
|---|---|---|
| `screens/primary/10_PUZZLE_CHOOSER.png` | 378×1161 | No |
| `screens/primary/09_ONBOARDING_PUZZLE_TRY.png` | 382×930 | No |
| `screens/primary/09_ONBOARDING_STRICTNESS.png` | 384×931 | No |
| `screens/secondary/03_ALARM_DISMISS_METHOD_DETAIL.png` | 565×307 | No (component crop) |

The Tier A contract requires the mockup at **851×1847 px = 393×852 pt**,
compared at that exact viewport to ±4 pt. None of these is that geometry — they
are crops from one combined storyboard, which the handoff's own
`README_START_HERE.md` states outright ("not independent native-resolution
screenshots… do not stretch"). So **Tier A binds nothing** on any Phase 10
surface, exactly as Phase 06 (ringing) and Phase 09 (onboarding) declared. The
handoff text labels them "Tier A layout references," but the repo's fidelity
contract is canonical and its tolerance cannot be evaluated against a non-native
crop. They are **structural/layout references**: section order, the 2-column
type grid, segmented controls, radio cards.

Held instead to tokens, the 44 pt tap floor, RTL, large-text reflow, the
no-overpromise rule, and the puzzle safety rules. Not added to
`integration_test/capture_test.dart` (`compare.dart` `exit(2)`s on a screen
with no block table).

## The three deviations from the art, by name

### D1 — Escape strictness: two values, not the mockup's three (safety rule)

`10_PUZZLE_CHOOSER.png` and `09_ONBOARDING_STRICTNESS.png` draw **Always /
After 1 min / Never**, and the chooser's "Never" card reads *"can only be
dismissed by solving the puzzles."* Our domain's `PuzzleEscapeStrictness` has
exactly two values — `confirm` / `confirmAndHold` — and **no "off"**, because
`CLAUDE.md` makes the escape always reachable ("Never ship a puzzle without a
reachable emergency escape… always a High finding"). The handoff's own
`AGENT_PROMPT.md` even says "'Never' does not eliminate emergency/accessible
alarm stopping." So the mockup's "Never" is misleading art.

**Shipped (owner decision, 2026-11-17): keep the domain, honest labels.** The
control renders **"One confirmation" / "Confirm, then hold"** with the
explanation *"You can always stop the alarm without solving. This only sets how
deliberate that has to be."* No "Never". Verified on the iPhone 18 Pro: the
chooser and the onboarding strictness step both show exactly two options.

### D2 — "After 1 min" split back into its two real fields

The mockup's middle escape segment conflates escape *strictness* with the
*tolerance* threshold (`toleratedWrongAnswers`). These are two separate,
separately-persisted domain fields. Shipped as **two controls**: the two-value
escape-strictness segment (D1) and a separate tolerance stepper
("When Stop without solving stands out — After N wrong answers").

### D3 — Ten real types and Material icons; no Shake

The chooser draws six illustrative cards; the ten **real** `PuzzleType`s ship,
with their ported localized names, grouped spoken-first ("Numbers and
sequences") then visual ("Shapes and positions"). Icons are **Material glyphs**,
not the mockup's painted per-type tiles — no such cutouts exist
(`asset_gaps.md` G21). The dismiss-method control offers **Tap / Puzzle** only;
the mockup's **Shake** is not a `DismissMethod` and is not shown
(`asset_gaps.md` notes the hero substitutions G22).

## Device evidence (iPhone 18 Pro, iOS 27.0)

The whole flow was run on the device, not inferred from a green suite (Phase 09's
rule). Confirmed:

- Onboarding: welcome → Next → puzzle preview → Next → strictness → **"Set your
  first alarm" lands on Add Alarm, not Home** (Phase 09's redirect race does not
  recur; the H2 device check).
- Add Alarm: the Dismiss section shows Tap / Puzzle (no Shake); selecting Puzzle
  reveals the follow-defaults switch and the "Medium · 1 puzzle" summary row.
- The summary row opens the chooser: ten type cards with check/circle
  indicators, the floor note, Difficulty (Easy/Medium/Hard), Puzzles to solve
  (1–5), the two-value escape control, and the tolerance stepper.

Captures are not run through `compare.dart` (no block table); these are
interaction evidence, not Tier A measurements.
