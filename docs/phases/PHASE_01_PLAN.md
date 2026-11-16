# Phase 01 — Foundation: tokens, type, art pipeline, shell, capture harness

## Status

in progress — revised against `PHASE_01_PRE_REVIEW.md` (14 findings: 5H/6M/3L,
all applied)

The pre-review probed the capture harness on a throwaway app against the booted
iPhone 14 Pro before this revision. Three of its five Highs were found that way
and could not have been found by reading. What changed:

- `flutter test` + `takeScreenshot` **passes and writes no file** (H1). The
  harness uses `flutter drive` with a driver that writes the bytes, and
  `capture.sh` verifies the PNG rather than trusting the exit code.
- `convertFlutterSurfaceToImage()` is mandatory on iOS and was absent (H2).
- `flutter create` emits `IPHONEOS_DEPLOYMENT_TARGET = 13.0`, which **cannot
  build for the simulator** on Flutter 3.44.7 (H3).
- The DEBUG banner is baked into every capture (H4).

## Goal

Stand up the Flutter project and everything a screen needs to exist: design
tokens sampled from the mockups, the typeface, the art import/audit/encode
pipeline, the shared illustrated components, the router and shell, 10-locale
l10n, and — gating everything — a **working screenshot capture harness**.

No product screen is built here. The deliverable is the ability to build one
and prove it matches.

## Must implement

### Project
- `flutter create` with org, iOS + Android platforms, Dart 3.12 / Flutter stable.
- **First, before anything else (H3):** raise the iOS deployment target.
  `flutter create` on Flutter 3.44.7 emits `IPHONEOS_DEPLOYMENT_TARGET = 13.0`,
  and the simulator build fails outright:

  ```
  Target Integrity (Xcode): The iOS Simulator deployment target
  'IPHONEOS_DEPLOYMENT_TARGET' is set to 13.0, but the range of supported
  deployment target versions is 15.0 to 27.2.x.
  ```

  ```bash
  sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 13.0;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' \
    ios/Runner.xcodeproj/project.pbxproj   # 3 occurrences
  ```

  **iOS 15.0 is this project's minimum.** Record it in the README.
- `pubspec.yaml` with only what this phase needs: `flutter_riverpod ^3.3.1`,
  `go_router ^17.2.2`, `intl ^0.20.2`, `meta`, plus dev deps
  `very_good_analysis ^9.0.0`, `flutter_test`, `integration_test`.
  **No alarm/Drift/health/sensors dependency yet** — phases 02 and 05 own those.
- `analysis_options.yaml` on `very_good_analysis`, zero issues including infos.
- **Delete `test/widget_test.dart` (L1)** — `flutter create` leaves a counter-demo
  test that asserts nothing real and inflates coverage.

### Typography
- Render "CapyWake 7:00" at mockup size in Nunito, Baloo 2, Quicksand and
  Fredoka; compare against a reference crop; pick one.
- **The choice must be decided on recorded measurements, not preference (M2).**
  Per candidate, against the mockup crop, record:

  | Criterion | Why it decides |
  |---|---|
  | x-height ÷ cap-height | The loudest weight/roundness signal at a glance |
  | Terminal shape | The mockups are rounded, not flat-cut |
  | `a` / `g` — single or two-storey | Separates Quicksand/Fredoka from Nunito |
  | Numeral width in `7:00` | The time is the largest type in the app |
  | Available weights | Needs ≥ 600 for headings, 400 for body |

  The rationale names which criterion decided it.
- **Script coverage is a hard gate, not a note.** The family must cover Latin,
  **Cyrillic (`ru`)** and **Turkish (`tr`)**. If it does not cover Arabic (`ar`)
  or Japanese (`ja`), the per-script fallback is chosen and written down **in
  this phase** — the risk table may not carry it forward unresolved.
- Bundle it with its SIL OFL licence file.
- Write `docs/visual/typography/` with the comparison and the rationale.
- The **wordmark is an asset**, cropped from the reference header, not a font
  match. **It has no clean source (M3, gap G10):** the only one is the
  compressed `01_HOME.png`, and it holds ~380 px where 525 px is needed at 3×.
  Crop, de-fringe, composite on token `cream`, and **log it as a declared Tier B
  substitution.** Do not claim a clean wordmark.

### Tokens — `lib/design/tokens.dart`
- `CapyColors` from the sampled palette: `cream #FEF3E7`, `surface #FEF4E8`,
  `surfaceAlt #F8E1CC`, `accent #F89736`, `accentDeep #E97C22`,
  `cocoa #2F1106`, `cocoaSoft #8A6A55`, `success #57AA3A`, `grass #85B83B`.
- **Re-verified against the mockups during the pre-review — these hold.**
  Clustered sampling over `01_HOME.png` (the mockups are compression-noisy, so
  every flat area is a cloud of values, not one value):

  | Token | Plan | Sampled cluster | Verdict |
  |---|---|---|---|
  | `accent` | `#F89736` | `~#F69636` | ✅ |
  | `accentDeep` | `#E97C22` | `~#E47E18` | ✅ |
  | `grass` | `#85B83B` | `~#8ABA3C` / `~#84B436` | ✅ |
  | `cocoa` | `#2F1106` | `~#301206` | ✅ |
  | `cream` | `#FEF3E7` | inside the distribution | ✅ |

  `surfaceAlt`, `cocoaSoft` and `success` are refined against per-screen crops
  before freezing; the five above are settled.
- `CapySpacing` (4/8/12/16/24/32/48), `CapyRadius`, `CapyType`, `CapyDuration`.
- Light **and** dark decided together. Dark = scrim + surface swap, since the
  raster art cannot re-tint.
- Token-only: no inline `Color(0xFF…)`, no inline `TextStyle(fontSize:)`, no
  off-scale `EdgeInsets` in widgets, ever.

### Art pipeline
- `tool/audit_art.dart` — per file: alpha present, ghost pixels (alpha ≤ 16)
  cleared, transparent margin trimmed, intrinsic size recorded, manifest
  written. Fails on a severed crop.
- `tool/encode_art.dart` — downscale to 2× the largest on-screen render box,
  WebP (lossy `-q 82` for scenes, lossless for flat cutouts), verify parity at
  render size.
- **Order is audit → encode → re-audit (L3).** Clearing ghosts must happen
  *before* downscaling, because resampling smears near-zero alpha back across
  the edge; the second audit proves it did not come back. A single pass is not
  sufficient.
- **Measured during the pre-review** (`docs/visual/asset_gaps.md`), so the
  pipeline is sized against real numbers:

  | Set | Ghost pixels | Note |
  |---|---|---|
  | 31 mascots | 112–384 each | All untrimmed; **no severed crops** — no opaque pixel touches an edge |
  | `clean_icons/` | up to **14,091** (`bell.png`) | Two orders of magnitude worse |
  | 14 decor | 20–149 | Untrimmed |

  `clean_icons/book.png` and `chart.png` are **256²** where their 7 siblings are
  1254² — a different, later export (gap G5). Both are clean (≈60 ghosts), which
  corroborates that reading. 256² is sharp to ~85 pt, so this is not blocking.
- Import, per the architecture plan §4. **Source is `reference/02_ASSETS/`, in
  this repo — never `../capywake/assets/`, whose art was processed for the old
  vector-first design.** Sound is the one exception: the 12 WAVs come from the
  legacy, re-generated via its `tool/generate_tones.dart` (Phase 05, not here).

  | From `reference/02_ASSETS/` | To `assets/art/` | Count |
  |---|---|---|
  | `header_scenes/*_integrated.png` | `scenes/` | 4 |
  | `asset_library/mascots/` + `mascot_fixes/` | `mascots/` | **31** (29 as-is + 2 replaced from `mascot_fixes/`) |
  | `clean_icons/` | `icons/` | 11 |
  | `asset_library/decor/` | `decor/` | 14 |
  | `animations/*/loop.webp` | `anim/` | 5 |

  **Not** imported: the 180 PNG animation frames, the 18 raster UI buttons in
  `asset_library/ui/` (they carry baked-in English and become real widgets),
  `asset_library/scenes/` (superseded by `header_scenes/`),
  `header_scenes/upscaled_older/` and `alternate_*`, `SOURCE_ARCHIVES/`, or
  `05_LEGACY_HANDOFFS/`.
- **Budget: predict first, then measure (M4).** "Measure, then set the gate at
  +20%" alone can never fail in the phase that sets it — it ratchets around
  whatever the first encode produced, mistakes included.

  Raw source measures **~17.2 MB**: scenes 7.4 MB, animations 4.1 MB, icons
  4.0 MB, mascots 1.5 MB, decor 0.2 MB.

  So: (a) write the **expected** post-encode total *before* encoding, derived
  from render box × 2 × format; (b) encode; (c) compare. **A deviation over
  ±30% is explained in the post-review, not silently accepted** — it means the
  render-box assumption or the encode settings are wrong. Only then is the gate
  set at measured + 20%, recorded with the date and the inputs behind it.

### Asset gaps — opened in this phase
- `docs/visual/asset_gaps.md` is created here and **appended to by every later
  phase**, per CLAUDE.md's reporting rule. Ten gaps are already recorded from
  the pre-review; one is **Blocking**:
  - **G2 — the four game tiles do not exist.** `01_HOME.png` shows four tiles,
    each a capybara on a painted background. The package has none. Nearest
    mascots are wrong-colour (`music_headphones` is grey, mockup is pink) and
    wrong-pose (`athletic` sits, mockup leaps), with no backgrounds at all.
    **Phase 03 cannot reach Tier A on the game rail without new art.**
  - Degraded: G1 (hero lacks the nightcap, duck, clock and `Zz`, and is framed
    far wider), G3 (mascots 114–343 px — too small above ~57 pt), G10
    (wordmark), G7 (decor). **G9 withdrawn** — the header crop re-measured at
    28 pt (10.7%), not 28%, and is already priced into `SceneHeader`.
  - Fixable in this phase's pipeline: G4, G5, G6.

### Design components — `lib/design/`
- `SceneHeader` — hero art, per-scene `BoxFit`/`Alignment` crop, overlapping
  cream card, safe-area padding. The most important component in the app;
  five screens share it so their compositions cannot drift.
- `CapyCard`, `CapyButton` (chunky orange with the darker lower edge),
  `CapyToggle` (large green/grey), `CapyNavBar` (three illustrated tabs),
  `DayPills`, `MeadowFooter`, `CapySegmented`.
- Each gets a widget test and a golden at 393×852.

### App shell
- `go_router` with `StatefulShellRoute`: `/home`, `/alarms`, `/stats`.
- `/settings` declared **outside** the shell with branch state preserved, so
  pop returns to the originating tab. Router test asserts this for all three.
- Placeholder screens only — real screens are phases 03+.

### l10n
- **Port the 10 ARB files from `../capywake/lib/l10n/`** — 383 keys × 10
  locales, human-quality, incl. Arabic RTL and Japanese. Only 3 keys are
  navigation-coupled (`navTodayLabel`, `navAlarmsLabel`, `navSettingsLabel`);
  rename to `navHomeLabel` / `navAlarmsLabel` / `navStatsLabel` and add the
  Settings entry point. Keys for screens not yet built stay — they cost
  nothing and phase 02+ consumes them.
- **Port `tool/check_arb.dart`** rather than writing one.
- RTL verified for `ar` on the shell.

### Capture harness — **the gating deliverable**

**Proven end-to-end during the pre-review before this plan was revised.** The
mechanism below is what actually wrote a PNG; the original plan's was verified
*not* to.

**`flutter test` + `takeScreenshot` reports "All tests passed!" and writes
nothing (H1).** `takeScreenshot` hands bytes to a driver; under `flutter test`
there is no driver, so they are dropped and the process exits 0. That is the
legacy's 40-phase failure with a green tick on top. **Never use `flutter test`
for captures.**

Four files, not two:

- `test_driver/integration_test.dart` — **the piece the original plan omitted
  entirely.** Calls `integrationDriver(onScreenshot:)` and writes the bytes:

  ```dart
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      final out = File('docs/visual/$name/actual.png');
      await out.parent.create(recursive: true);
      await out.writeAsBytes(bytes);
      return true;
    },
  );
  ```

- `integration_test/capture_test.dart` — call order is **mandatory on iOS (H2)**:

  ```dart
  await tester.pumpWidget(const CapyWakeApp(
    debugShowCheckedModeBanner: false,          // H4
  ));
  await tester.pumpAndSettle();
  await binding.convertFlutterSurfaceToImage(); // required, exactly once
  await tester.pumpAndSettle();
  await binding.takeScreenshot(screenName);
  ```

  Without `convertFlutterSurfaceToImage()` the capture is blank or fails.
  `debugShowCheckedModeBanner: false` is **not cosmetic** — the DEBUG ribbon
  renders into the PNG's top-right corner, exactly where the Home gear and the
  status-bar battery sit, producing a permanent false Tier A delta on every
  screen.

- `tool/capture.sh <screen>` — runs

  ```bash
  flutter drive --driver=test_driver/integration_test.dart \
                --target=integration_test/capture_test.dart -d <udid>
  ```

  then **verifies rather than trusting the exit code**:
  the PNG exists, is non-empty, is **1179×2556 px**, is newer than the run, and
  its top-right corner is background-coloured. **Exits non-zero if any check
  fails.** A green command that wrote no file must be impossible.

- `tool/compare.dart` — writes `side_by_side.png` and prints per-block deltas.
  - **Normalization (M6):** measured — mockups are 851×1847 px at 2.1654 px/pt
    = 393×**853** pt; the device captures 1179×2556 px = 393×**852** pt. Width
    is exact, height is 1 pt short. Scale the reference to the captured
    **height**, treat ±1 pt as rounding, and **print the normalization used in
    every report** so a reader can tell measurement from tolerance.
  - **Block vocabulary (M5):** Tier A is "±4 pt on major block positions" and
    nothing names the blocks, which would let a screen pick the blocks it
    already matches. Fixed as a typed list, identical for every screen: status
    bar, header band top/bottom, hero scene lower edge, primary card top, nav
    bar top, nav bar height, safe-area insets. A screen's phase may **add**
    blocks; it may never remove one.

- Coverage tooling: `tool/check_coverage.dart`.

**Environment, verified:** Flutter 3.44.7 / Dart 3.12.2, iPhone 14 Pro simulator
`152C8091-22D4-49C0-AA67-E6A2D9181165`, iOS deployment target 15.0, `cwebp` at
`/opt/homebrew/bin/cwebp`.

## Must not implement

- No Home, Alarms, Add/Edit, Settings or Stats screen.
- **No `core/` port** — phase 02 owns that, and it is a large, careful move.
  Phase 01 ports only the l10n files and the two check tools, because the
  shell needs strings and the gate must be green from the first commit.
- No `Alarm` model, no Drift, no repositories — phase 02.
- No alarm engine, notifications or permissions — phase 05.
- No games, no puzzle types.
- No speculative abstractions; no dependency not listed above.

## Acceptance criteria

- `flutter analyze` reports zero issues including infos.
- `dart format --set-exit-if-changed .` is clean.
- `tool/check_arb.dart` passes with all 10 locales.
- `tool/audit_art.dart` passes; the manifest lists every bundled file.
- `tool/check_bundle_size.dart` passes against the **measured** budget.
- Coverage: project ≥ 85 %, **measured over `lib/` (`--path lib`) (M1)**.
  Phase 01's output is mostly `tool/*.dart` — `dart run` entry points with
  `main()` and file I/O — and `check_coverage.dart` excludes only `*.g.dart`
  and `lib/l10n/generated/**` by default, so unfiltered they can drag the figure
  under 85 % and fail the phase on its own scaffolding. **The gate is not
  lowered and nothing is marked `coverage:ignore`**; logic inside the tools is
  extracted into testable functions under `lib/design/` or `tool/src/`.
- **The `lib/core` ≥ 95 % gate is skipped in Phase 01** — `lib/core/` is not
  ported until Phase 02, and `tool/check_coverage.dart` does not pass trivially
  on an absent path: it `exit(2)`s with "No coverage data matched" when no file
  matches the filter (verified at `../capywake/tool/check_coverage.dart:77-83`).
  Running it here would fail the build for the wrong reason. **Phase 02's plan
  must re-enable it explicitly** so the skip cannot quietly become permanent.
- Every `design/` component has a widget test and a 393×852 golden.
- Router test: push `/settings` from each of the three tabs, pop, land back on
  the originating tab.
- **The capture gate (H1) — the phase's definition of done:**
  `tool/capture.sh shell` writes `docs/visual/shell/actual.png`, and that file
  is **1179×2556 px**, non-empty, newer than the run, and free of the DEBUG
  banner. **The script exits non-zero if any of that is false**, and the PNG is
  committed. "The command exited 0" is explicitly *not* sufficient — the
  pre-review proved a command that exits 0 and writes nothing.
- `docs/visual/asset_gaps.md` exists, records the ten gaps found so far, and the
  Blocking one (G2, game tiles) has been reported to the owner in-session.
- `docs/visual/typography/` records the font comparison, the per-criterion
  measurements, the choice, and the `ar`/`ja` fallback decision.
- The app boots on the iPhone 14 Pro simulator and the three tabs switch.

## Tests

Widget tests per component; golden tests at 393×852; a router test for the
settings-pop behavior; an l10n completeness test; an art-manifest test
asserting every catalogue entry is actually bundled (the legacy's
`capy_art_test.dart` pattern).

## Risks

| Risk | Mitigation |
|---|---|
| ~~Capture harness does not work~~ | **Retired — proven working in the pre-review.** PNG written at 1179×2556 via `flutter drive` |
| **The harness silently stops writing later** | The real risk, now that it works. `capture.sh` verifies the file rather than the exit code; a regression fails loudly |
| Art budget turns out large | Predict before encoding, explain any ±30 % deviation, then set the gate (M4) |
| Token values drift from the mockups | 5 of 9 re-verified against sampled clusters; goldens lock them after |
| 10 locales for placeholder screens is busywork | Only the handful of shell strings exist at this point — the cost is small now and the gate never goes red later |
| Chosen font lacks Arabic or Japanese coverage | **Resolved in this phase, not carried forward** — script coverage is a hard gate and the fallback is written down (M2) |
| **Game tiles do not exist (G2)** | Blocking for Phase 03's rail, not for Phase 01. Reported to the owner now so art can be generated before Phase 03 starts, rather than discovered there |
| **Another session commits to `main` concurrently** | Happened during this phase (`5bb411f`, `388a338`). Re-read `git log` before committing; never amend or force-push |

## Rollback

Self-contained — this is the first code. Reverting is deleting the Flutter
project; the Phase 00 documents stand on their own.
