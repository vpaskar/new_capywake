# Phase 01 — adversarial pre-review

Written **before any phase code**, per the protocol. Reviews
`docs/phases/PHASE_01_PLAN.md` at `388a338`.

The question this review asks is not "is the plan reasonable" but **"what will
this plan let a future session claim that is not true?"** That is the failure
mode this project already has on record: 40 legacy phases that reported passing
validation while capturing zero screenshots.

Two commits landed in this repo mid-session (`5bb411f`, `388a338`) from the
owner's own dry run. Both are folded in; `5bb411f` is counted below as an
already-applied finding because it is the same class of defect this review
hunts.

**Findings: 14 — 5 High, 6 Medium, 3 Low.** All applied; none deferred.

---

## HIGH

### H1 — `takeScreenshot` under `flutter test` passes and writes nothing

**The single most important finding in this review. Verified by running it.**

The plan specifies `integration_test/capture_test.dart` using
`IntegrationTestWidgetsFlutterBinding.takeScreenshot`, and `tool/capture.sh` to
"run the capture". It never says **how** the bytes reach disk.

Probed on a throwaway app against the booted iPhone 14 Pro:

```
$ flutter test integration_test/capture_test.dart -d 152C8091-…
00:00 +1: All tests passed!

$ find . -name "*.png" -newermt '-10 minutes'
(nothing)
```

**The test passes. No file is written.** `takeScreenshot` only returns bytes to
the driver; under `flutter test` there is no driver, so they are discarded
silently. Exit code 0.

This is the legacy's exact failure, and it is worse than the legacy's: this
version is green in CI. A phase that wired it this way would report a passing
capture step forever while `docs/visual/` stayed empty — and the acceptance
criterion "`tool/capture.sh` has produced a real PNG" would be satisfied by a
command that exits 0.

Proven working path:

```
flutter drive --driver=test_driver/integration_test.dart \
              --target=integration_test/capture_test.dart -d <udid>
→ WROTE docs/visual/probe/actual.png (85398 bytes)
```

It needs `test_driver/integration_test.dart` calling `integrationDriver(
onScreenshot: …)` with a callback that writes the file — a file the plan does
not mention at all.

**Applied.** Plan gains `test_driver/integration_test.dart` as a named
deliverable; `capture.sh` uses `flutter drive`, never `flutter test`; and —
because a green test is not evidence — **`capture.sh` asserts the PNG exists,
is non-empty and is newer than the run, and exits non-zero otherwise.**

### H2 — `convertFlutterSurfaceToImage()` is required on iOS and is not in the plan

Found in the same probe. Without it the capture either fails or returns a blank
surface on a real iOS device/simulator. It must be called **after** the first
`pumpAndSettle` and **before** `takeScreenshot`, and it must not be called twice
in one session.

The plan's one-line description of `capture_test.dart` would not have produced
this. A session implementing it from the plan alone would hit a blank or failed
capture and could easily "fix" it by falling back to `flutter test`, landing
straight in H1.

**Applied.** The capture test's required call order is written into the plan as
a code sketch, not prose.

### H3 — `IPHONEOS_DEPLOYMENT_TARGET = 13.0` breaks the build before any of this runs

`flutter create` on Flutter 3.44.7 emits a project that **cannot build for the
simulator at all**:

```
Target Integrity (Xcode): The iOS Simulator deployment target
'IPHONEOS_DEPLOYMENT_TARGET' is set to 13.0, but the range of supported
deployment target versions is 15.0 to 27.2.x.
Could not build the application for the simulator.
```

This is the first thing Phase 01 does and it fails. It is a 30-second fix
(3 occurrences in `project.pbxproj`), but it is not in the plan, and a session
hitting it on step one has no guidance — the risk is that it gets "fixed" by
switching to a different device or skipping the device entirely.

**Applied.** Named in the plan as the first implementation step with the exact
patch, and `15.0` recorded as the project's minimum iOS version.

### H4 — The DEBUG banner is baked into every capture

The probe PNG has Flutter's red DEBUG ribbon across the top-right corner. Every
comparison against a mockup would show a permanent Tier A delta in that corner,
on every screen, forever — and the mockups' top-right is where the Home gear and
the status-bar battery live.

Nothing in the plan mentions it.

**Applied.** `debugShowCheckedModeBanner: false` is required on the capture
harness's root widget, and the capture test asserts the captured top-right
corner is background-coloured so the banner cannot silently return.

### H5 — Acceptance criteria require a coverage gate the phase must fail

**Found by the owner's dry run (`5bb411f`) during this session; recorded here
because it is this review's own class of defect.**

The plan's acceptance criteria demanded `lib/core ≥ 95%` in the phase that
explicitly does **not** port `lib/core`. Verified in
`../capywake/tool/check_coverage.dart:77–83`: with no file matching the filter
the tool writes "No coverage data matched" and `exit(2)`s — it does not pass
trivially on an absent path. Phase 01 would have failed its own gate.

**Applied** in `5bb411f`: the core gate is skipped in Phase 01 only, noted in
CLAUDE.md, the tracker and the plan; it turns on in Phase 02 and stays on. This
review additionally requires Phase 02's plan to **re-enable it explicitly**, so
the skip cannot quietly become permanent.

---

## MEDIUM

### M1 — "project ≥ 85%" is a trap in a phase that is mostly tooling

Phase 01 writes `tool/*.dart` (audit, encode, compare, bundle size) and
`lib/design/*`. Tool scripts are `dart run` entry points with `main()` and file
I/O; they are awkward to unit-test and they are **counted by
`check_coverage.dart` unless filtered** — only `*.g.dart` and `lib/l10n/
generated/**` are excluded by default.

`tool/` sits outside `lib/`, so whether it lands in the lcov report depends on
what the test run touches. If it does, a few hundred lines of thinly-tested
tooling can drag the project figure under 85% and the phase fails on its own
scaffolding.

**Applied.** The plan states the gate is measured over `lib/` only
(`--path lib`), and that pure logic inside the tools is extracted to testable
functions in `lib/design/` or `tool/src/` rather than the gate being lowered.
CLAUDE.md's "never lower or bypass the coverage gate" is unchanged and still
binding.

### M2 — Font selection has an acceptance criterion but no decision rule

The plan says render four candidates, "compare against a reference crop", pick
one. There is no stated basis for the choice, so the result is unfalsifiable —
any of the four can be declared the winner and the document will look complete.

**Applied.** The comparison must record, per candidate, against the mockup crop:
x-height ratio, terminal shape (rounded vs flat), the single-storey vs
two-storey `a`/`g`, numeral width in `7:00`, and available weights. The
rationale names which of these decided it. Plus a hard gate: **the family must
cover Latin, Cyrillic (`ru`), Turkish (`tr`) and the `ar`/`ja` fallback path
must be stated** — the plan's own risk table raises this and then leaves it as
"check during selection".

### M3 — The wordmark has no clean source and the plan assumes one

The plan says the wordmark is "cropped from the reference header". The only
source is `01_HOME.png`, a compressed PNG (flat cream measures as `#FEF2E6`,
`#FDF2E6`, `#FEF3E6`… — a cloud, not a value). Cropping yields compression
fringing on edges, over a background that will not match the token `cream`.

Measured: the wordmark is ~175 pt wide → **525 px needed at 3×**; the mockup
contains ~380 px of it. Under-resolution and artifacted.

**Applied.** Logged as gap G10 in `docs/visual/asset_gaps.md` and reported to the
owner. Phase 01 crops, de-fringes and composites on token cream as a declared
Tier B substitution; it does not claim a clean wordmark.

### M4 — The art budget is set from a number this phase itself produces

"Measure the total, then set the gate at measured + 20%" means the gate can
never fail in the phase that sets it, and it ratchets to whatever the first
implementation happened to produce. If the encode step is misconfigured — wrong
quality, wrong target size — the budget is set around the mistake and every
later phase inherits it as correct.

Raw source measures **~17.2 MB** (scenes 7.4 MB, animations 4.1 MB, icons
4.0 MB, mascots 1.5 MB, decor 0.2 MB).

**Applied.** The plan records an independent expectation **before** encoding —
derived from render box × 2 × format — and the post-review must explain any
deviation over ±30% rather than simply recording the number. The budget is
written with the date and the inputs that produced it.

### M5 — Tier A is "±4 pt on major block positions" with no list of blocks

CLAUDE.md makes Tier A binding and `tool/compare.dart` is meant to print
"per-block deltas in pt". Neither names a single block. Phase 03 would be free
to choose the blocks it already matches.

**Applied.** Phase 01 defines the block vocabulary — status bar, header band,
hero scene lower edge, primary card top, nav bar top, nav bar height, safe-area
insets — as a typed list in `tool/compare.dart`, so every screen reports the
same rows. Per-screen blocks are added by the screen's phase, never removed.

### M6 — `compare.dart` must reconcile 853 pt against 852 pt, and the plan buries it

Measured: mockups are 851×1847 px at 2.1654 px/pt = **393×853 pt**. The device
captures **1179×2556 px = 393×852 pt** — width exact, height 1 pt short.

The plan mentions this in a parenthetical. Unhandled, every block below the fold
reads as ~1 pt off and the noise eats a quarter of the ±4 pt tolerance.

**Applied.** `compare.dart` scales the reference to the captured **height** and
declares ±1 pt as rounding, not signal; the chosen normalization is printed in
every report so a reader can tell measurement from tolerance.

---

## LOW

### L1 — `flutter create` leaves a counterfeit test that inflates coverage

The generated `test/widget_test.dart` tests the counter demo. Left behind, it
tests nothing real while adding passing assertions.

**Applied.** Deleted in the first commit; the plan says so.

### L2 — "29 mascots" is wrong by one

The plan imports "29 mascots (with the two `mascot_fixes/` replacements)".
Measured: `asset_library/mascots/` holds **31** files, and `mascot_fixes/`
replaces two of them (`thinking.png`, `sleepy_eyes.png`). The result is **31
mascots, 2 of which come from `mascot_fixes/`** — not 29.

Small, but the art-manifest test asserts the count, so a wrong number fails the
build or, worse, is "corrected" by dropping two mascots.

**Applied.** Corrected to 31 (29 + 2 replacements) in the plan; the manifest
test asserts 31.

### L3 — Nothing in the plan ever opened the asset files

The plan commits to auditing alpha, ghost pixels and margins — but Phase 01's
own planning never measured them, so the phase could not know whether the
pipeline it specifies is sufficient.

It is not, quite: **`clean_icons/` carries up to 14,091 ghost pixels**
(`bell.png`), two orders of magnitude worse than the mascots, and `book.png`/
`chart.png` are 256² where their siblings are 1254². Also found: no mascot has
opaque pixels touching an edge, so there are **no severed crops** in that set —
the legacy's warning does not apply to the mascots.

One ordering consequence: resampling can smear near-zero alpha back over the
edge, so **ghosts must be cleared before downscaling and re-audited after** —
the plan's current order does it once.

**Applied.** Audit-then-encode-then-re-audit ordering written into the plan; all
measurements recorded in `docs/visual/asset_gaps.md` (G4, G5, G6).

---

## Findings the review considered and rejected

- **"Port `lib/core` in Phase 01 since the gate wants it"** — invalid. Phase 02
  owns that move and it is large. H5's fix (skip the gate here, re-enable in 02)
  is correct; pulling the port forward to satisfy a gate would be the retrofit
  motion that failed last time.
- **"Three tabs contradicts `clean_icons/home.png` being a cottage"** — invalid.
  The nav bar in `01_HOME.png` uses flat single-colour glyphs, not illustrations
  (evidence: `_evidence/asset_gaps/mockup_navbar.png`). These are real widgets.
  Recorded as G8 so a later phase does not "fix" it by bundling the cottage.

---

## Asset gaps found while reviewing

Reported to the owner in-session and recorded in `docs/visual/asset_gaps.md`
under CLAUDE.md's reporting rule. One is **Blocking**:

- **G2 — the four game tiles do not exist.** `01_HOME.png` shows four tiles,
  each a capybara on a painted background. The package has no tile art;
  the nearest mascots are a wrong-colour (`music_headphones`, grey vs pink) and
  a wrong-pose (`athletic`, sitting vs leaping) match, with no backgrounds.

The rest are Degraded or Fixable: G1 (hero does not match the mockup — no
nightcap, duck, clock or `Zz`, much wider framing), G3 (mascots 114–343 px, too
small above ~57 pt), G10 (wordmark), G7 (decor), and G4/G5/G6 which the import
pipeline fixes.

**G9 was withdrawn after this review was written.** It claimed the hero crop
loses "~28% of the height"; re-measured, the loss is 28 **pt** of 262 — 10.7%.
The aspect-ratio delta had been reported as the crop fraction. Rendering all
three alignment extremes confirms the face stays clear and the composition
survives, and `SceneHeader` was designed around exactly this crop. Raised by the
Phase 00 session, verified here, agreed. No art needed.

---

## What this review changes about the phase's shape

Phase 01's gating deliverable was already "a real PNG". H1 shows that bar is
**too low**: a command that exits 0 and writes nothing would have satisfied it.

The gate is therefore restated:

> `tool/capture.sh shell` writes `docs/visual/shell/actual.png`; the file is
> **1179×2556 px**, non-empty, newer than the run, and free of the DEBUG banner.
> The script **exits non-zero if any of that is false.** The PNG is committed.

That is checkable by a reader who does not trust the session that produced it —
which, given the history this project is correcting, is the right standard.
