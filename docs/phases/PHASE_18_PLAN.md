# Phase 18 — Animation and visual polish

Status: **revised after the pre-review** (§9 lists the deltas).

Tracker row: "5 WebP loops, reduce-motion, dark mode pass". No mockup draws
any of the three — the primary screens are light-mode stills — so Tier A binds
nothing new; every placement is Tier B and declared.

## 0. What the phase start found (measured, not assumed)

1. **The theme picker governs nothing.** Settings → Theme saves
   `UserSettings.themeMode`; `CapyWakeApp` passes `theme` and `darkTheme` but no
   `themeMode`, so `MaterialApp` follows the system whatever the user picks.
   `grep -rn themeMode lib/app` → nothing. A control that lies (`CLAUDE.md`,
   Settings). **High.**
2. **Three of the five loops are damaged**, read off frame 0 on a dark
   backdrop and an alpha union-bbox scan of all 36 frames
   (`reference/02_ASSETS/animations/0N_*/loop.webp`, 360², 36 × 80 ms):

   | Loop | Defect |
   |---|---|
   | `01_wake_up` | blanket's lower edge cut flat (severed crop) |
   | `02_sleep_breathing` | nightcap tip cut flat at the top, blanket cut flat on the right |
   | `03_walk_cycle` | the backpack is erased — only its strap remains (masking took the pack) |
   | `04_shake_dj` | clean; a few stray specks |
   | `05_celebration` | clean; confetti touches the top edge (intended) |

   All five carry 800–2,583 alpha ≤ 16 ghost pixels per frame and total
   4.2 MB lossless. The README says each is "programmatically tweened from a
   single drawn pose".

## 1. Theme preference applies

- `lib/app/theme_mode.dart`: `ThemeMode themeModeFor(ThemeModePreference)` —
  `core/` stays Flutter-free, so the mapping lives in `app/`.
- `CapyWakeApp` watches `userSettingsStreamProvider` and passes
  `themeMode`. While settings load: `ThemeMode.system` (what the default
  preference is, so a fresh install never flashes).

## 2. Dark-mode pass

The art is raster and does not re-tint; dark is scrim + surface swap
(`CAPYWAKE_NEW_ARCHITECTURE_PLAN.md`), already built per widget with
`dark ? … : …`. The pass verifies it rather than re-deciding it.

1. **Captures in dark.** `capture_test.dart` gains a dark run of every
   captured screen (home, alarms, add_edit_alarm, stats, settings, ringing),
   seeded through the real setting (`themeMode: dark`), so the capture also
   proves §1. Written to `docs/visual/<screen>/dark.png`; `tool/capture.sh`
   verifies those artifacts the same way.
2. **A contrast gate:** `test/design/text_contrast_test.dart` pumps each screen
   (plus the puzzle chooser, onboarding's three steps and every game's practice
   card) in dark and checks every painted `Text` against its nearest opaque
   ancestor fill: ≥ 4.5:1, or ≥ 3:1 for large text (≥ 18 pt, or ≥ 14 pt
   bold).
3. **Fix every defect** the two instruments find. Each is listed in the post
   review with its before/after.

## 3. Reduce-motion pass

Inventory (from `grep` of every `AnimationController`, `Tween`/`Animated*`,
`Timer.periodic` and multi-frame image in `lib/`):

| Source | Covered by |
|---|---|
| Route pushes, sheets, switches, implicit `Animated*` | the framework: under the platform flag every `AnimationBehavior.normal` controller runs at 5 % of its duration (`animation_controller.dart:651`) |
| Games (10) | each view, under `disableAnimations` **or** `accessibleNavigation`, re-read every build (tested per game) |
| `DriftingGrid` | its game's still flag |
| Win celebration | `GameWinCelebration`, both flags |
| Multi-frame `Image` | `Image` pauses under `TickerMode` off or `disableAnimations` (`image.dart:1151`) — **not** under `accessibleNavigation` |
| `HoldToActButton` progress | user-driven feedback while held, not motion on its own |

Gaps to close:

- **A loop must also stop for a screen reader** — wrap it in `TickerMode`
  (`CapyLoop`, §4).
- **The app under a ring keeps animating.** `RingingHost` stacks the ring over
  `widget.child` and leaves its tickers running — a practice game (Catch the
  Capy runs non-stop) or a loop keeps costing frames behind the ring. Wrap the
  child in `TickerMode(enabled: no ring and no win overlay)`, with the tree
  shape unchanged so nothing remounts.

## 4. The loops

- **Pipeline:** `tool/import_art.dart` gains an animation job: decode every
  frame, clear ghosts per frame, check the union bbox for a severed edge,
  resize every frame to one canvas, write PNG frames to a temp dir, and encode
  with `img2webp` (lossy colour `-q 82`, lossless alpha, 80 ms, loop forever).
- **Audit:** `art_audit.dart` learns animated files — frame count, every frame
  RGBA, no ghosts, no severed union edge — and `art_audit_test` runs it.
  `art_manifest_test` checks the engine decodes the file with the expected
  frame count (`ui.instantiateImageCodec` under `runAsync`).
- **`CapyLoop`** (`lib/design/capy_loop.dart`): an `Image.asset` of a loop
  inside `TickerMode(enabled: !still)`, where still = `disableAnimations ||
  accessibleNavigation`. Frame 0 is the still.
- **Placement:** only where a loop replaces a bundled still of the same pose.
  - `04_shake_dj` → **Shake DJ's dancer** (today the `collection_06` still,
    86 pt). The kick per beat and the groove bob stay.
  - The other four are **not bundled**: three are damaged (above), and
    `05_celebration`'s only fit is the win screen, whose art is the owner's
    2026-11-18 replacement (G34) — swapping it would undo an owner decision.
    Each is reported in session and logged in `asset_gaps.md` (G43–G46) and
    `OPEN_QUESTIONS.md`.
- **Budget:** predicted before encoding — 36 frames at 288 px (96 pt × 3),
  lossy colour: ~6 KB a frame, **~220 KB**; a result outside ±30 % is
  explained. The art budget rises by the measured size + 20 %.

## 5. Strings

None expected. A loop is decorative (`ExcludeSemantics`); the Shake DJ card's
existing label stands.

## 6. Tests (≈ 40)

- Theme: each preference → `Theme.of(context).brightness` under both platform
  brightnesses; switching in Settings re-themes the open app.
- Dark contrast gate (§2.2), with a test that proves it fails on a planted
  dark-on-dark text.
- `CapyLoop`: ticker on by default; off under each flag; flipped mid-life.
- `RingingHost`: the child's `TickerMode` is off during a ring and the win
  overlay, back on after; the child's state survives (a counter keeps its
  value).
- Import/audit: animated audit passes the import, fails on a planted ghost
  frame and a planted severed frame; engine frame count.
- Shake DJ: the dancer is the loop; still under each flag shows frame 0.

## 7. Acceptance

- Theme picker changes the app, tested and seen on the simulator.
- Six dark captures recorded and verified; defects fixed or named.
- Contrast gate green, mutation-checked.
- Every gate in `CLAUDE.md` green; bundle budget re-set with its prediction.

## 8. Risks, rollback

- **Animated WebP decode on device** — the engine's codec handles it; proved
  in the host engine by test and on the simulator by capture. Android
  unverifiable (no emulator).
- **Watching settings in `CapyWakeApp`** needs the database in every test that
  pumps the app: five tests do; each already overrides the database or will.
- Rollback: one commit; nothing persisted changes shape.

## 9. Pre-review deltas

- H1: `CapyLoop` takes a `GlobalKey` owned by the view, so Shake DJ's kick
  and groove keys never remount the frame stream.
- H2: the contrast gate resolves fills from ancestor widgets, records the
  source, fails when blind, and is proven to fail on a planted label.
- M1: `RingingHost` keeps one tree shape; `TickerMode` off under a ring/win.
- M2: the first frame waits for settings, capped at 400 ms.
- M3: white-on-accent exempt by colour, counted per screen.
- M4: the gate pumps games from `GameRegistry` with the existing fakes.
- M5: specks inspected and cleared at import if debris.
- M6: dark captures write `dark.png`; `capture.sh` verifies them.
- L1 `ArtUse.gameLoop` 96 pt; L2 `animations/loop_shake_dj.webp`; L3 onboarding
  looked at in dark on the simulator.

## 10. Implementation deltas (found while building)

- **No loop ships.** Encoding `04_shake_dj` and looking at it on cream showed
  its dark outline, eyes and leg lines were masked out with the background —
  invisible on the dark backdrop the phase start used. Four of five loops are
  damaged; the clean one has no surface that does not undo owner art. `CapyLoop`,
  `ArtUse.gameLoop` and the importer's loop job were removed rather than left
  unused. Reported in session; G43–G47; `ART_REQUESTS.md` #15–16.
- **New import gate instead:** `outlineCoverage` in `art_audit.dart`, run over
  every bundled sticker. An enclosed-hole count was tried first and dropped: it
  flagged the wordmark's letter counters and `moments_12`'s gap between legs
  and rock — real negative space, not lost ink.
- **The brand exemption covers orange and green on either side**, not only
  white on orange: accent icons on white chips and white on the grass pill
  measured the same Phase 02 constraint.
- **Dark-only captures** for onboarding and the puzzle chooser (L3), written
  as `dark.png` and verified by `capture.sh`.
