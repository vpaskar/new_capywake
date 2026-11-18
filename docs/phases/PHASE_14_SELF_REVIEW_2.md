# Phase 14 — Self-review #2

A fresh, unanchored read: a subagent given the code and `CLAUDE.md` but not
self-review #1's conclusions, read-only, with its own scratchpad tests
(`midslide_test.dart`, `bold_clip_test.dart`). Its findings were re-checked here
before applying. **8 findings: 0 High, 2 Medium, 6 Low. All applied; none
invalid.** It confirmed what holds: every game finishable, the escape the
host's, all motion stopped under `disableAnimations` or a screen reader, RTL by
start/end, no hardcoded strings, completion reported once, deterministic.

---

## Medium

**G1 — A tap during a slide went to the wrong card, or to nothing.** Self-review
#1 held the drift while a finger is down, but a slide already under way kept
going, and `AnimatedPositioned` hit-tests where the card is *painted*. Aimed at
the odd card's resting centre on hard (seed 4): 30 % into the slide it counted
as a find, 50 % it hit nothing (lost tap), 70 % it hit the neighbour (a
struggle). Cards are moving ~18 % of the time on hard. **Applied:** each card
is laid out at the slot it **rested in when the slide began** and painted along
the slide by a `Transform.translate(transformHitTests: false)` driven by one
`AnimationController`; the resting slots update when the slide completes. A tap
mid-slide goes to the card the user aimed at. Tested at 30 / 50 / 70 % into a
carousel step (`drifting_grid_test`). Side effect, intended: a test must let the
slide settle (`pumpAndSettle`) before tapping by painted position.

**G2 — The "names fit" test could not fail.** `RenderParagraph` clips to its
constraints, so a text rect always sits inside its card and no overflow is
thrown; the test passed with the measurement replaced by the 56 pt minimum.
**Applied:** the test compares each paragraph's max intrinsic height with its
laid-out height, for every card of every bag, in de / ru / fr at 2× text, easy
and hard. Negative test run: returning `cellMinHeight` fails it in all three
locales. (The reviewer's sweep — 10 locales × bold text × 1–3× × 393/375 pt —
found nothing clipped: the code was right, the test was blind.)

## Low

**G3 — The winning move dealt a fresh set.** Find the Impostor showed a new,
active-looking grid behind the win; Morning Sort a new empty bag beside
"Bag packed." and 3 / 3. **Applied:** the last find / last pocket keeps the
final set on show, all resolved; Impostor cells are `enabled: false` once
complete. Core and view tests.

**G4 — A repeated outcome was not announced.** A live region speaks only when
its text changes, so two wrong taps in a row gave a screen-reader user nothing
the second time. **Applied:** `GameOutcomeLine.serial` — a new answer with the
same text calls `SemanticsService.sendAnnouncement`; a changed text stays the
live region's job (no double announcement). Both games pass a serial; the four
earlier games are unchanged (they pass none). Tested via the accessibility
channel.

**G5 — The packed indicator was `accentDeep` on cream, ~2.6:1** (the known
palette constraint, memory `capywake-palette-contrast-constraint`). **Applied:**
the packed border is cocoa (ink in dark); the badge is a cocoa check on an
accent disc (~8:1), the same pairing as the pocket.

**G6 — Arabic instruction treated Capy as feminine** (ما تحتاجه); every other
Arabic key is masculine. **Applied:** ما يحتاجه كابي.

**G7 — Arabic "left at home" verb clashed with feminine items** (طوبة: يبقى…).
**Applied:** a verbless "{item}: في البيت", matching "{item}: في الحقيبة".

**G8 — Four pose labels meant something else** — and on hard the labels are
the screen-reader user's only answer key. es "corriendo con cinta" (a
treadmill) → "corriendo con una cinta en la cabeza"; it "con una lente" (a
lens) → "con una lente d'ingrandimento"; tr "takkeyle" (a skullcap) →
"gece takkesiyle uyuyor"; pt "correndo de faixa" → "correndo com uma faixa na
cabeça". **Applied.**

---

Re-validated: `flutter analyze` clean; `test/core/games`, `test/features/games`,
`test/features/ringing`, `test/features/home` green (469).
