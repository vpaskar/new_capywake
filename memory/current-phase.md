# Current phase

**Phase 01 — Foundation: done, 2026-11-16. `Current phase: 02`.**

## The gate, and why it was set higher than the plan asked

`tool/capture.sh` writes three verified PNGs from the iPhone 14 Pro simulator
at **1179×2556 px = 393×852 pt**.

The plan's bar was "has produced a real PNG". The pre-review probed the planned
mechanism before writing any code and found it **passes while writing
nothing**: `takeScreenshot` hands bytes to a driver, and under `flutter test`
there is no driver, so they are dropped and the process exits 0. That is the
legacy's 40-phase failure with a green tick on top — and the old criterion
would have been satisfied by it forever.

So the gate is now the artifact, not the exit code: `capture.sh` checks the
file exists, is non-empty, is 1179×2556, is newer than the run, and has no
DEBUG banner, and exits non-zero otherwise.

Two more that only running could find: `flutter create` emits an iOS deployment
target that **cannot build for the simulator** on Flutter 3.44.7, and
`convertFlutterSurfaceToImage()` is mandatory on iOS.

## Decisions this phase made

| Question | Decision |
|---|---|
| Typeface | **Baloo 2** (x-height/cap 0.786 vs the reference's heavy rounded terminals) |
| Script fallback | Baloo 2 covers Latin+Turkish **only**. `ru`→Nunito, `ar`/`ja`→system face |
| Encode target | **3×**, not the plan's 2× — the plan contradicted its own sharpness check |
| Coverage scope | project gate is `--path lib`; `tool/` is entry points with file I/O |
| Comparison | offsets measured **from the status bar**, inset recorded per capture |

The typeface check nearly shipped wrong: a `PIL.getmask` test reported all five
scripts OK for both finalists. It returns a non-empty box for `.notdef` too.
**Only rendering shows the tofu.** Russian is a shipping locale, so the
fallback is decided here rather than discovered in Phase 03.

## Tier A — the honest state

`compare.dart` **fails today, and that is correct.** The header matches to
**0.1 pt**; the hero lower edge (−11.0), card top (−22.1) and nav bar (absent)
are off because the screens have no bodies yet. Phase 03 closes them. A tool
that passed on an empty shell would be worthless.

## Art

The owner's patch closed **G1** (hero with nightcap, duck, clock, `Zz`),
**G2** (the four game tiles — the only Blocking gap), **G3** (31 mascots via
sticker sheets) and **G10** (wordmark). No blocking gap remains.

Two defects found by measuring rather than assuming:

- **G11** — ~91% of ink sits at alpha 250–254, not 255, so the art is ~2%
  translucent. Fixed in-pipeline; verified first that the band is interior fill,
  not antialiased edge, so snapping does not harden outlines.
- **The sheets do not slice on gutters alone** — three cells held two touching
  poses each. `splitWideCell` cuts at coverage valleys. 31 poses, 0 merged.

**G9 withdrawn** after being measured wrong twice. The real crop is 28.1% of the
art band — large, but the face stays clear at every alignment, which is what
`SceneHeader` exists for.

## Validation

analyze clean · format clean · 10 locales × 384 keys · art 1818 KB of 2182 KB
(83%) · **43 tests** · **lib coverage 97.92%** against 85%.

## Next session — Phase 02

Port `lib/core/` minus `theme.dart` (62 files, 9,825 lines, verified pure Dart)
and `test/core/` (48 files, **932 passing tests**) from the read-only
`../capywake`. Drift tables at `schemaVersion = 1`, not the legacy's 6.

**ARB is already done** — Phase 01 ported all 384 keys × 10 locales and adapted
the 3 nav-coupled ones, so the five `core/` files that take `AppLocalizations`
as a parameter port directly.

**Re-enable the `lib/core` ≥ 95% coverage gate** in the plan's acceptance
criteria. Phase 01 skips it legitimately — `lib/core/` does not exist and
`check_coverage.dart` `exit(2)`s on an absent path rather than passing
trivially — but a skip nobody turns back on is how a gate dies.
