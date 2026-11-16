# Current phase

**Phase 02 — Domain and persistence: done, 2026-11-16. `Current phase: 03`.**

The legacy domain is ported. 62 `lib/core/` files (9,825 lines), 47
`test/core/` files, 4 `lib/data/` files at `schemaVersion = 1`, 4 `test/data/`
files, 12 sound assets. **1,051 tests**, analyze clean, `lib/core` **99.41%**.

## The gate this phase existed to re-enable

**`lib/core` ≥ 95% coverage is back on, at 99.41%.** Phase 01 skipped it
legitimately — `lib/core/` did not exist and `check_coverage.dart` `exit(2)`s on
an absent path rather than passing trivially — and Phase 01's pre-review made
turning it back on a Phase 02 requirement so the skip could not become
permanent. It is now in `CLAUDE.md`, the tracker and the acceptance criteria,
and the exception note is marked closed.

## Not 932 ported tests but 912, and why that mattered

`test/core/theme_test.dart` is **20** of the legacy's 932 and tests
`lib/core/theme.dart`, the one file that imports Flutter *and* is not ported. So
the handoff's "932 ported tests must pass" was right about the legacy suite and
wrong about the ported one.

Dropping it would have cost something real: those 20 asserted **AA contrast** and
separator discipline on the legacy palette, and nothing asserted CapyWake's own
palette. Its replacement, `test/design/tokens_contrast_test.dart`, found **two
genuine accessibility defects** in Phase 01's sampled tokens:

| Pair | Measured | Required |
|---|---|---|
| `accent` / `accentDeep` / `success` / `grass` on the three light surfaces | 1.76–2.68:1 | 3.0 (UI) |
| `error` on `surfaceAlt` | 3.93:1 | 4.5 (body) |

Both are **open design constraints, not closed findings**, recorded as checked
properties that fail if a token strengthens. Retuning a palette sampled from the
mockups is Tier A and belongs to the owner and a UI phase. **Phase 03 is the
first consumer.**

## What the identity discipline caught

The pre-review fixed every test-count term **before** implementation so the
result could not be rationalised afterwards. Its own first draft estimated the
four data-test files at 66; measured, they are **83** — 26% out. Had the estimate
stood, the post-review would have found 83 where it expected 66 and had to decide
after the fact whether a surplus was good news.

Final: 912 + 83 + 43 + **13 new** = **1,051**. N came out 13 rather than the
budgeted 5 (the contrast test split into 9 cases), so the identity was
**restated, not quietly passed**.

## Seven failures after the raw copy — none a logic defect, none skipped

1. **3 × `alarm_sound_test`** — `assets/sounds/` was never in the plan.
   `CAPYWAKE_REUSE_AUDIT.md` lists it; the plan paraphrased the audit instead of
   working through it. **Would have shipped a sound catalogue pointing at twelve
   absent files**, failing only when a user tapped one. Ported: 12 WAVs (7,752 KB)
   + `LICENSES.md` + `tool/generate_tones.dart`.
2. **3 × `sleep_boundary_test`** — asserted the *presence* of
   `live_sleep_gateway.dart`, `NSHealthShareUsageDescription`, `READ_SLEEP`:
   phase-07/08 infrastructure. Rewritten as the negative invariant they protect,
   plus a conditional that binds the moment `READ_SLEEP` appears. **Restoration
   obligation is in the tracker's 07/08 rows**, not only a code comment.
3. **1 × iOS plist read `Capywake`** — Phase 01's 194-occurrence ARB casing fix
   never reached the platform manifests. `CFBundleDisplayName` and
   `android:label` now read **CapyWake**; both user-visible.

## Decisions this phase made

| Question | Decision |
|---|---|
| Migration history | `schemaVersion = 1`, `onUpgrade` dropped. N3 asserts an upgrade **throws**, because drift substitutes a non-null default closure — `onUpgrade == null` was the wrong guard |
| Dropped columns | The legacy's v3→v4 *drops* two columns by table rebuild. Both verified absent and now asserted against the **live schema** (N4), not read off a migration comment |
| `data/providers.dart` | Ported minus the two sleep-gateway providers (the only lines needing `package:health`). Excluding it whole would have left Phase 03 unable to read an alarm |
| Port rule for tests | `lib/core/` imports no Flutter (asserted). `test/core/` may import `widgets.dart` **for `Locale` only** (asserted) — verified those five files use nothing else Flutter-shaped |
| `prefer_initializing_formals` | 3 targeted `ignore_for_file`. A *private named* initializing formal compiles but is **not callable** — verified with a minimal program. `analysis_options.yaml` untouched |
| 12-line comment ceiling | **Withdrawn.** Measured 50 runs over 12 lines; reading them showed the rule was wrong, not the code — they are a state-machine transition table and DST semantics. `gastrowerk`'s number was derived from `gastrowerk`'s tree |

## Gates that were green for the wrong reason

Four, found across the review passes:

- **`tool/audit_art.dart` does not exist** — documented in `CLAUDE.md` *and* the
  tracker as a per-phase gate. Running it errors. The audit is
  `lib/design/art_audit.dart` + two design tests inside `flutter test`.
- **`check_bundle_size.dart` measured art only** (1818/2182 KB = "83%") while the
  real asset payload had grown to **10.5 MB** with the sounds. Now budgets every
  tree and states that native libraries are not counted.
- **`lib/data` had no gate** at **85.08%**, the weakest tree, clearing the
  project gate only because `lib/core`'s 2,526 lines at 99.41% dominated the
  average. Gate added.
- **That 85.08% is itself misleading**: 67 of 496 lines are Drift `Table` column
  getters, evaluated at build time to generate `app_database.g.dart` and never at
  runtime. Unreachable by any test. Hand-written data code is **422/429 = 98.4%**.
  Do not "fix" it with a meaningless test, a `// coverage:ignore`, or a lowered
  gate.

## Validation

analyze clean (zero infos) · format clean · 10 locales × 384 keys · 1,051 tests ·
project **97.14%** · `lib/core` **99.41%** · `lib/data` 85.08% · assets 10,517 KB
of 11,082 KB across three budgeted trees · `capture.sh` 3 PNGs verified at
1179×2556 · `../capywake` **byte-identical to the pre-port baseline**.

40 findings across pre-review, two self-reviews and a full-project review. All
applied, none invalid.

## Next session — Phase 03, Home / Today

`01_HOME.png`. The domain is real: schedule math, next-alarm, today formatting,
history and the puzzle engine are all ported and tested. **Nothing rings** —
`AlarmEngine` is an interface plus a fake until phase 05.

Design against **palette constraint F1**: in light mode no control may use
accent, success or grass as its only channel for boundary or state.
