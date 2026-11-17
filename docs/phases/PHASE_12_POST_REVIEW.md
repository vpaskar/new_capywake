# Phase 12 — Post-review

**Touch games I — Catch the Capy, Memory Hideout. Done 2026-11-17.**

## What shipped

- **The selection model (owner decision, in session).** Games join the Puzzle
  dismissal — no new `DismissMethod`, no schema bump. `PuzzleSettings` and
  `AlarmPuzzleOverride` gained `enabledGames` and `includePuzzles` (stored in the
  existing JSON); `WakeChallengeSelector` picks one challenge per ring, uniformly
  and seeded, and falls back to puzzles on an empty launchable pool. An alarm
  inherits the app-wide pool or carries its own: a specific game, or a subset.
- **Two games**, headless state in `lib/core/games/` (100 %), views in
  `lib/features/games/` (100 %), registered in `GameRegistry` — a test pins
  registered ids == catalogue-playable ids.
- **Made dynamic at the owner's direction, mid-phase** (plan §12): Catch the Capy
  runs non-stop, faces its direction, bolts from missed taps, runs faster on
  harder settings, over a meadow dressed with the package's decor; Memory
  Hideout shuffles its bushes like a shell game. Every motion stops under
  reduce-motion or a screen reader, where both games stay finishable.
  `CLAUDE.md`'s animation rule is narrowed to the ringing chrome.
- **Ringing**: `RingingHost` launches the picked game into `puzzleSlot`; struggle
  raises the escape against the **alarm's resolved** tolerance; completion
  dismisses once. The escape stays `RingingScreen`'s.
- **Entry points**: chooser Games section with "Try it"; Add/Edit pool picker
  when the alarm has its own settings; Home's playable tile opens practice
  (`/games/:id`), which reads settings and writes nothing.

## Numbers

| | Phase 11 | Phase 12 |
|---|---|---|
| Tests | 1,572 | **1,767** (+195) |
| `lib` | 97.95 % | **98.20 %** |
| `lib/core` | 99.61 % | **99.67 %** |
| `lib/core/games` | 100 % | **100 %** |
| `lib/features/games` | — | **100 %** |
| `lib/data` | 88.95 % | **89.17 %** |
| `lib/features/ringing` | 98.53 % | **98.62 %** |
| ARB keys × 10 | 446 | **466** (+21, −1) |
| Comment baseline | 113 | **113** (+0) |

**Restated, not passed quietly:** the pre-review estimated +12–16 keys;
measurement settled at +21 (the outcome lines, practice and pool copy, and the
shuffle instruction added for the owner's dynamic direction). The bush
render box was planned at 35 pt and shipped at **32 pt** — trimmed to ink the
file is 97 px, not 107, and the import guard measures after trimming.

## Findings

| Pass | Total | H | M | L | Invalid |
|---|---|---|---|---|---|
| Pre-review | 16 | 7 | 6 | 3 | 0 |
| Self-review #1 | 5 | 1 | 2 | 2 | 1 (L1) |
| Self-review #2 | 6 | 0 | 2 | 3 | 1 (measured) |
| Full-project | 6 | 2 | 2 | 2 | 0 |

The ones that matter:

- **SR1 H1** — the games had no card and would have drawn dark text on the
  scrimmed hero art. Green in every view test; caught by reading the host.
- **SR2 M1/M2** — on device, Memory Hideout kept the answer on screen while
  guessing, and its Ready button jumped ~30 pt under the finger.
- **FP H1** — Settings had painted "Default snooze leng9 minutes" since Phase 07;
  it is in that phase's own capture. Guard fails 10/10 on the old row.
- **FP H2** — es/fr/it/ar called the puzzles "games"; harmless until games
  existed. 73 strings retranslated, guarded per locale.

## Tier A / Tier B

**Tier A binds nothing new** — the posters are bezel-wrapped storyboards (as
06/09/10/11). Re-captured to prove no regression:

- **Home**: same six `absent` blocks, worst measured **1.4 pt** (Phase 07's
  figure). Catch the Capy lost its "Soon" badge, which the mockup never drew.
- **Settings**: header **+0.1**, hero **+0.1**, group 2 top **−0.6**; group 1
  bottom **+4.5** is Phase 07's declared tap-floor conflict, unchanged; group 1
  top `absent`, unchanged.

**Tier B:** G23, G29, G30, G31 and G32 were reported in session and then
**closed by the owner's art** (plan §13): run cycle, dust, paw prints, meadow,
plain bush and tile, each validated and imported through the pipeline. Two
supply defects handled in the pipeline, not by loosening a guard: the tile's
baked frame (cut inside it, pinned by a pixel test) and the bush's flat base
(2 px margin). The meadow's saturated blue sky is cooler than the app palette —
noted, used as supplied. See `docs/visual/asset_gaps.md`.

## Evidence

- **Device, iPhone 18 Pro (iOS 27.0):** Home tile → Catch the Capy practice,
  miss + five catches → "Practice done"; Settings → chooser → Games section →
  "Try it" Memory Hideout → Ready, a wrong pick ("Not there…"), a right pick
  ("Found Capy."). **That build predates the SR2/FP fixes**; those are evidenced
  by the 14 Pro captures and tests below, not by a second hand run.
- **Captures, iPhone 14 Pro, verified by `tool/capture.sh`:**
  `ringing_catch_the_capy`, `ringing_memory_hideout` (a ring fired into the
  running app, games-only alarm), `ringing`, `home`, `settings`.
- **Device, after the owner's dynamic changes:** Catch the Capy runs on its own,
  turns to face its direction, over the decorated meadow; observed again with
  the difficulty at hard (7 catches). The first attempt opened at medium
  because practice started before settings loaded — fixed and pinned by a test
  that fails without the fix.
- **Not watched:** a real platform alarm ringing in real time into a game (as in
  every phase since 06 — the ringing evidence is the fired-ring capture plus the
  host tests). **Android untested; no emulator.**

## Carried, owned by nobody

Sleep boundary / `package:health` (unbuilt 07–12); `CapyNavBar` 98.7 vs 79.9;
G18/G19; Alarms 3 / Add-Edit 8 Tier A failures; `ringNow` uncalled.
