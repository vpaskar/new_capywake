# Ringing — capture and deviations

`actual.png` — **1179×2556 px = 393×852 pt**, iPhone 14 Pro, written and
verified by `tool/capture.sh` (dimensions, non-empty, newer than the run, no
DEBUG banner).

The captured alarm is **puzzle-backed**, which is the configuration the board
draws and the one where the emergency escape must be visible.

## There is no Tier A reference for this screen

The five primary mockups are Home, Alarms, Add/Edit, Settings, Stats. The only
reference is a **board panel** — `boards/01_earlier_all_screens.png`,
bottom-right, a ~333×467 px crop of a 1448×1086 presentation board, of which
the phone's screen content is ~333×416 px.

A ±4 pt tolerance cannot be derived from that, so **no Tier A claim is made**
and no row is added to `tier_a_blocks.md`. Declared in `PHASE_06_PLAN.md`
before measuring, not discovered at review.

## What it is held to instead

| Standard | Result |
|---|---|
| Design tokens — spacing, radii, type scale, palette | Met; all values from `CapySpacing` / `CapyType` / `CapyColors` |
| Control-height floor, measured with `tester.getRect` | Met; Snooze and the escape clear 44 pt, option chips are 56 pt |
| Board comparison — **order and presence** | Met; see below |
| No animation | Asserted on the composed surface, and again after a wrong answer |

## Board comparison — order and presence

| Board, top to bottom | Captured |
|---|---|
| Wordmark "CapyWake" | **absent** — see deviation D1 |
| Alarm label with a sun glyph | present ("Wake Up"), no glyph — D2 |
| Large clock, digits and AM apart | **present**, via `AlarmFormat.timeParts` |
| Hero: capybara waking in bed | present, bleeding to the top edge |
| Puzzle card: title, prompt, options | present (instruction, prompt, 4 chips) — D3 |
| Snooze · Dismiss row | Snooze present; Dismiss **deliberately absent** — D4 |
| *(nothing)* | **Stop without solving** — D5, a deliberate addition |

## Measured block edges (pt, row-mean detector on flat boundaries)

| Edge | pt |
|---|---|
| Art band lower edge | **262** |
| Puzzle card top | **531** |
| Card bottom / Snooze top | **679** |
| Snooze bottom | **735** |
| Escape control | **778** |

Method: row-mean luminance, which per `CLAUDE.md` may be used only for
boundaries **between two flat areas**. The art/cream edge at 262 and the
card/cream edges qualify. No glyph edge is reported as a block boundary.

## Named deviations

- **D1 — no wordmark.** The board puts "CapyWake" above the label. On a
  ringing screen the app's own name is the least useful thing present, and the
  space it wants is the clock's. Dropped deliberately.
- **D2 — no sun glyph beside the label.** The board draws one; the asset
  package has no matching cutout at this size and `CLAUDE.md` forbids
  generating art. The label is a real `Text`, which is what localizes.
- **D3 — the puzzle card is plainer than the board's.** No puzzle-type title
  row ("Wake Puzzle: Math Sprint") and no coloured puzzle icon. The
  instruction string carries the same information and comes from ARB.
- **D4 — no Dismiss button while a puzzle gates the alarm.** The board draws a
  *locked* Dismiss reading "(Solve the puzzle first)". A disabled control whose
  sub-copy says there is no other way out contradicts the escape that sits
  below it, so the puzzle states the gate and the escape states itself.
- **D5 — the escape is an addition, not a deviation to fix.** The board shows
  no way past the puzzle at all. `CLAUDE.md` makes that *always a High
  finding*: "Never ship a puzzle without a reachable emergency escape."
- **D6 — a cream gap between the art band and the puzzle card.** The board's
  card overlaps the art's lower third; ours sits below it with ~269 pt of
  surface between. The card is bottom-aligned so it stays reachable at any
  height, and the gap grows on taller screens. The honest state, not a match.

## Asset

`assets/art/scenes/alarms.webp`, 1179×786 RGB, unmodified. **Not a Tier B
substitution** — see `asset_gaps.md` G17: this file already *is* the board's
ringing composition and is currently shared with two screens whose own mockups
show something else.

Fitted to width at the top rather than `BoxFit.cover`, because the scene is
3:2 and the band is taller — `cover` zoomed past the capybara's face, which
`CLAUDE.md` forbids.
