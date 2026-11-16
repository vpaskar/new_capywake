# Phase 01 — Foundation: tokens, type, art pipeline, shell, capture harness

## Status

pending

> Draft. Per the protocol, this plan must be revised and an adversarial
> `PHASE_01_PRE_REVIEW.md` written **before** any code in this phase.

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
- `pubspec.yaml` with only what this phase needs: `flutter_riverpod ^3.3.1`,
  `go_router ^17.2.2`, `intl ^0.20.2`, `meta`, plus dev deps
  `very_good_analysis ^9.0.0`, `flutter_test`, `integration_test`.
  **No alarm/Drift/health/sensors dependency yet** — phases 02 and 05 own those.
- `analysis_options.yaml` on `very_good_analysis`, zero issues including infos.

### Typography
- Render "CapyWake 7:00" at mockup size in Nunito, Baloo 2, Quicksand and
  Fredoka; compare against a reference crop; pick one.
- Bundle it with its SIL OFL licence file.
- Write `docs/visual/typography/` with the comparison and the rationale.
- The **wordmark is an asset**, cropped from the reference header, not a font
  match.

### Tokens — `lib/design/tokens.dart`
- `CapyColors` from the sampled palette: `cream #FEF3E7`, `surface #FEF4E8`,
  `surfaceAlt #F8E1CC`, `accent #F89736`, `accentDeep #E97C22`,
  `cocoa #2F1106`, `cocoaSoft #8A6A55`, `success #57AA3A`, `grass #85B83B`.
  Refine against crops before freezing.
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
- Import, per the architecture plan §4. **Source is `reference/02_ASSETS/`, in
  this repo — never `../capywake/assets/`, whose art was processed for the old
  vector-first design.** Sound is the one exception: the 12 WAVs come from the
  legacy, re-generated via its `tool/generate_tones.dart` (Phase 05, not here).

  | From `reference/02_ASSETS/` | To `assets/art/` | Count |
  |---|---|---|
  | `header_scenes/*_integrated.png` | `scenes/` | 4 |
  | `asset_library/mascots/` + `mascot_fixes/` | `mascots/` | 29 + 2 replacements |
  | `clean_icons/` | `icons/` | 11 |
  | `asset_library/decor/` | `decor/` | 14 |
  | `animations/*/loop.webp` | `anim/` | 5 |

  **Not** imported: the 180 PNG animation frames, the 18 raster UI buttons in
  `asset_library/ui/` (they carry baked-in English and become real widgets),
  `asset_library/scenes/` (superseded by `header_scenes/`),
  `header_scenes/upscaled_older/` and `alternate_*`, `SOURCE_ARCHIVES/`, or
  `05_LEGACY_HANDOFFS/`.
- **Measure the total, then set `tool/check_bundle_size.dart` at measured
  + 20 %.**

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
- `integration_test/capture_test.dart` using
  `IntegrationTestWidgetsFlutterBinding.takeScreenshot`.
- `tool/capture.sh <screen>` — boots the iPhone 14 Pro simulator, runs the
  capture, writes `docs/visual/<screen>/actual.png`.
- `tool/compare.dart` — writes `side_by_side.png`, prints per-block deltas in
  pt, scales the reference to the captured height and tolerates ±1 pt of
  rounding (1847 / 2.165 = 853.1 vs the device's 852).
- Coverage tooling: `tool/check_coverage.dart`.

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
- Coverage: project ≥ 85 %. **The `lib/core` ≥ 95 % gate is skipped in Phase
  01** — `lib/core/` is not ported until Phase 02, and
  `tool/check_coverage.dart` does not pass trivially on an absent path: it
  `exit(2)`s with "No coverage data matched" when no file matches the filter
  (verified at `../capywake/tool/check_coverage.dart:77-83`). Running it here
  would fail the build for the wrong reason. Phase 02 turns it on and it stays
  on from then.
- Every `design/` component has a widget test and a 393×852 golden.
- Router test: push `/settings` from each of the three tabs, pop, land back on
  the originating tab.
- **`tool/capture.sh` has produced a real PNG of the shell at 393×852, and it
  is committed under `docs/visual/shell/`.**
- `docs/visual/typography/` records the font comparison and the choice.
- The app boots on the iPhone 14 Pro simulator and the three tabs switch.

## Tests

Widget tests per component; golden tests at 393×852; a router test for the
settings-pop behavior; an l10n completeness test; an art-manifest test
asserting every catalogue entry is actually bundled (the legacy's
`capy_art_test.dart` pattern).

## Risks

| Risk | Mitigation |
|---|---|
| Capture harness does not work | It is the gating deliverable — if it cannot work, raise it as a blocker here, not in phase 03 |
| Art budget turns out large | Measure first, then set the gate; downscale aggressively to render box |
| Token values drift from the mockups | Refine against crops before freezing; goldens lock them after |
| 10 locales for placeholder screens is busywork | Only the handful of shell strings exist at this point — the cost is small now and the gate never goes red later |
| Chosen font lacks Arabic or Japanese coverage | Check coverage during selection; fall back to a per-script family if needed |

## Rollback

Self-contained — this is the first code. Reverting is deleting the Flutter
project; the Phase 00 documents stand on their own.
