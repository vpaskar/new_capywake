# Phase 13 — Full-project review

Across the app, not only this phase's files: the ringing surface all four games
share, the chooser, practice, the shared game widgets, tokens, art pipeline,
l10n and the docs future phases read. **5 findings: 1 High, 2 Medium, 2 Low.
All applied; none invalid.**

## High

**FP-H1 — On a short phone every game card reaches over the clock, and this
phase made it worse.** Measured at 375 × 667 (iPhone SE, 20 pt inset) with a
labelled alarm: the clock ends at 111 pt; Catch the Capy's card starts at 92 pt
(**since Phase 12**), Memory Hideout 193, Rhythm Rescue 148, Capy Rocket **58**.
The reference phone is clear for all four (SR2-H1).
*Tried and reverted:* laying the slot out *below* the hero text, so a card can
never climb over the clock. Every host test that taps Catch the Capy at the
default 800 × 600 surface then missed — the field's bottom row fell below the
fold. On a short phone that is a half-asleep user scrolling mid-game, which is
worse than a covered clock foot (`CLAUDE.md`: no precision, large reachable
controls). **Applied:**
- Capy Rocket's card is cut to **Catch the Capy's 424 pt** (instruction
  shortened to one line in all ten locales; field 240 → 228 pt), so this phase
  adds no new overlap.
- A host test fails if any game's card reaches higher than Catch the Capy's on
  the small phone — **verified to fail at a 270 pt field**.
- The trade-off is the owner's and is in `OPEN_QUESTIONS.md` with three options.

## Medium

**FP-M1 — Game progress was silent for screen-reader users in every game**,
not only the two new ones (SR2-M1 fixed it in the shared `GameHeader`, so
Catch the Capy and Memory Hideout announce each catch and find now too). Their
existing tests still pass; the new `game_header_test` pins the flag and fails
without it. Recorded here because it changed two games outside this phase.

**FP-M2 — A stray capture set was found in `docs/visual/`**, all twelve files
written at 01:15:33, before this session ran `tool/capture.sh`, showing the
pre-SR1 Capy Rocket layout. Nothing in this session ran `flutter drive` then;
the likeliest writer is another session sharing the checkout. It was useful
(SR2-H1 came from it) but it is not evidence of the committed code. **Applied:**
every capture committed with this phase was re-taken after the last layout
change and verified by `tool/capture.sh` (`All captures verified.`), and the
post-review names the run.

## Low

**FP-L1 — `docs/sessions/next.md`'s "How a game plugs in" predates three
rules this phase found the hard way** (a live-region outcome line that never
moves the chrome; still mode re-read on every build; the clock guard).
**Applied:** added there and to `memory/current-phase.md`.

**FP-L2 — `grep "Phase [0-9]" lib/ --include=*.dart` (excluding generated)**
was re-run: **0**. The new ARB descriptions name no phase either.
