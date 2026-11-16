# Phase 02 — adversarial pre-review

Written **before any code**, against `PHASE_02_PLAN.md` draft 1. Every claim
below was checked by running a command, not by reading a document. `../capywake`
was read only — the only commands run against it were `find`, `grep`, `wc`,
`flutter test` and `git status`.

**`../capywake` was already dirty when this session started.** See M7 for the
evidence and what it does to acceptance criterion 12.

The posture is hostile: the job is to find the thing that would have shipped
broken, the way Phase 01's pre-review found that `flutter test` + `takeScreenshot`
passes while writing no file, and the way Phase 00's self-review found it had
banned 9,825 lines of reusable domain code.

**20 findings — 6 High, 8 Medium, 6 Low.**

---

## High

### H1 — The plan's own test target is still wrong, in the other direction

Draft 1 corrects "932" to "912" by subtracting `theme_test.dart`'s 20. Measured:
`flutter test test/core` → 932, `flutter test test/core/theme_test.dart` → 20.
So 912 is right **for the core suite alone**.

But the plan then writes acceptance criterion 6 as "**912** ported core tests
pass. Plus data tests, plus Phase 01's 43." That is three numbers, one of them
unmeasured, and a criterion nobody can evaluate without running the thing it
gates. A gate whose pass condition is "912 plus some unknown" is the same defect
as "has produced a real PNG" — satisfiable by a plausible-looking number.

**The data-test count is measurable right now and was not measured.** Run the
four portable files in the legacy and record the figure before implementation, so
the post-review compares against a number fixed in advance rather than one
discovered afterwards and declared correct.

**Applied.** Measured this session by running each file in the legacy,
read-only:

| File | Tests |
|---|---|
| `test/data/mappers_test.dart` | 18 |
| `test/data/puzzle_mappers_test.dart` | 15 |
| `test/data/sleep_mappers_test.dart` | 18 |
| `test/data/capywake_repository_test.dart` | 32 |
| **total** | **83** |

Acceptance becomes an exact arithmetic identity:
**912 core + 83 data + 43 Phase 01 + N new = total**, with N stated in the plan
and every term named. Any deviation is a finding.

**This finding justified itself immediately.** The first draft of it estimated
these four counts at 14/10/12/30 = 66 without running them. Measured, they are
18/15/18/32 = **83** — an error of 17 tests, or 26%. Had the plan kept the
estimate, the post-review would have found 83 where it expected 66 and had to
decide, after the fact, whether a surplus was good news or a double-count. That
is precisely the "unmeasured term in a gate" defect this finding exists to
remove, and it was present in the finding's own first draft.

### H2 — `test/core/theme_test.dart` is dropped, and nothing replaces what it guarded

The plan drops it correctly (it tests the unported `theme.dart`) and argues the
loss is safe because `theme.dart` is a leaf. The leaf claim is verified:
`grep -rln "core/theme" ../capywake/lib/core/` is empty.

That is the wrong question. The 20 tests did not only check that a file existed —
inspection shows they asserted **AA contrast between primary controls and
semantic text**, that dark mode exposes exactly one separator, and that the
scaffold background is the warm sand token. Those are accessibility and
design-system invariants about *CapyWake's palette*, and CapyWake has a palette:
`lib/design/tokens.dart`, sampled from the mockups in Phase 01.

So the port drops 20 tests of palette correctness and the new palette has **no
equivalent assertions**. Phase 01's `test/design/components_test.dart` does not
check contrast — verified by reading it.

This is exactly the shape of Phase 00's High finding: a correct local decision
("don't port the old theme") silently discarding a capability nobody noticed was
load-bearing.

**Applied.** The plan gains an explicit deliverable: a contrast test over
`lib/design/tokens.dart` asserting WCAG AA (4.5:1 body, 3:1 large) for the
foreground/background pairs the tokens define, in both light and dark. It is not
a port of `theme_test.dart` — the tokens differ — but it restores the invariant
rather than losing it in a port's rounding error. Counted in N.

### H3 — "No UI change" is asserted but the plan adds a UI-visible dependency path

The plan says exclusions include "no change to `lib/features/`, `lib/design/`,
`lib/app/`" and that `compare.dart`'s recorded Tier A state "stands unchanged".

`_openConnection()` in the ported `app_database.dart` calls
`getApplicationSupportDirectory()` from `path_provider`. Nothing in this phase
wires the database into the app — but `pubspec.yaml` gains `path_provider`,
`sqlite3_flutter_libs` and `drift`, and `sqlite3_flutter_libs` ships **native
iOS and Android artifacts**. Adding it changes the build, the pod install, and
the app's binary size.

The plan's `check_bundle_size.dart` criterion says "unchanged". That tool measures
the **art** budget, so it will indeed be unchanged — and will therefore report
green while the actual shipped binary grows by a native SQLite library. A gate
that is green for a reason unrelated to the risk is worse than no gate, because
it reads as coverage.

**Applied.** Two changes. (a) The plan states plainly that
`sqlite3_flutter_libs` adds native artifacts and that `check_bundle_size.dart`
does **not** cover them, so no claim of "bundle size unchanged" is made.
(b) Acceptance gains: the iOS simulator build must still succeed after the
dependency change, verified by actually running `tool/capture.sh` — which builds
and runs the app, so a broken pod install or a native link failure surfaces here
instead of in Phase 03. This phase changes no pixel, so the captures are
expected byte-comparable in geometry; the point is the build, not the image.

### H4 — The migration history is dropped, but the *schema it produces* is not verified to match

The plan reduces `schemaVersion` 6 → 1 and deletes `onUpgrade`. Correct for a
zero-user app. But `onUpgrade` in the legacy does more than add columns — at
v3 → v4 it **drops** two columns (`alarms.final_alarm_minutes_after`,
`alarm_occurrences.final_at`) via `alterTable`, rebuilding from the then-current
Dart schema.

That means the legacy's *live* schema is "the table definitions as written,
minus nothing" only if those two columns are genuinely absent from the current
table classes. Verified by reading `app_database.dart`: they are absent —
the classes do not declare them. Good. But this was luck, not design: had a
dropped column still been declared, starting at v1 with `createAll()` would
silently resurrect it, and the mappers (which never reference it) would leave it
NULL forever. A column nothing reads is the unbacked claim the legacy's own v4
comment was written to remove.

**Applied.** Acceptance gains a test that enumerates the created schema's actual
column names per table (`db.alarms.$columns` etc.) and asserts the set exactly —
no `final_alarm_minutes_after`, no `final_at`, and every column the mappers
touch present. This makes "the fresh schema equals the legacy's end state" a
checked property rather than a reading of a migration comment.

### H5 — `very_good_analysis` 9.0.0 excludes `tool/**` in the legacy and does not here

Verified by diffing the two `analysis_options.yaml`:

- legacy excludes `lib/l10n/generated/**`, `**/*.g.dart`, `build/**`, **and `tool/**`**
- this repo excludes `lib/l10n/generated/**` and `**/*.g.dart` only

The plan says "any new lint the ported code trips is fixed in the ported code,
never silenced". Fine. But it does not notice that the **generated**
`app_database.g.dart` is 4,650 lines in the legacy and is excluded by
`**/*.g.dart` here too — so that is safe — while the *mappers and tables* are
hand-written and have never been held to this repo's lint set.

The real exposure is unmeasured: 9,825 lines of core plus ~1,000 of data, held
for the first time to `very_good_analysis` 9.0.0 with
`missing_required_param: error` and `missing_return: error` escalated, which the
legacy did not set. The plan's risk table calls this "stricter than the legacy's
lint set" and mitigates with "fix in ported code; measure the count before
deciding the approach" — but schedules the measurement *after* the decision to
port verbatim.

**Applied.** The plan gains a mandatory **pre-implementation measurement step**:
copy core + data into the tree, run `flutter analyze`, record the issue count and
the rule histogram in the plan **before** any hand-editing. If the count is large
enough that fixing it mechanically risks behaviour change, that is a finding to
raise then, with evidence, rather than a surprise discovered at hour three. The
escalated `errors:` block is not relaxed.

### H6 — Nothing in the plan prevents the next session from re-adding migrations

Acceptance criterion 10 is "`schemaVersion == 1`, asserted by a test". A test
asserting `schemaVersion == 1` fails the moment a future phase legitimately adds
migration v2 — at which point the obvious fix is to update the constant in the
test, and the *reason* v1 was chosen (greenfield, no users, do not inherit
migrations for data nobody has) is gone from the code with nothing to replace it.

That is how the Phase 01 coverage skip would have died if nobody had written it
into the tracker. The plan is repeating the pattern one level down.

**Applied.** The test is reframed: it asserts that the `MigrationStrategy` has
**no `onUpgrade`** (i.e. a fresh database is the only supported origin) and
carries a one-line reason naming the greenfield decision. A future phase adding a
real migration will then delete a test whose purpose is explicit, not silently
bump a number. `schemaVersion == 1` is still asserted, but as the weaker half.

---

## Medium

### M1 — "62 files" is right; "48 test files" in the tracker is wrong

`find ../capywake/lib/core -name '*.dart' | wc -l` → **63**; minus `theme.dart`
= 62. The tracker and `CAPYWAKE_REUSE_AUDIT.md` both say 62 ported. Correct.

But both also say `test/core/` is "48 files, 932 passing tests" and the ported
set is **47 files, 912 tests**. The tracker's row for Phase 02 and
`memory/current-phase.md` and `docs/sessions/next.md` all repeat "932".

**Applied.** All four documents are corrected as part of this phase's bookkeeping
step, with the arithmetic shown, so the next session is not told to hit a number
that cannot be hit.

### M2 — The reuse audit says "5 files take `AppLocalizations`"; `grep` finds 6 mentioning l10n

`grep -rln "l10n" ../capywake/lib/core/` returns six files, the sixth being
`alarm_draft.dart`. Inspection: its only match is a doc comment
("Calm, plain wording lives in `lib/l10n`"), not an import or a parameter. So
the audit's five is correct and the sixth is a false positive.

Recording it because the plan repeats "five" without saying how it was
distinguished, and an unexplained number invites the next session to re-derive it
with the same `grep` and reach a different answer.

**Applied.** The plan states the method: five files **import**
`app_localizations.dart`; `alarm_draft.dart` mentions l10n in prose only.

### M3 — The five l10n-coupled core tests import `package:flutter/widgets.dart`, and the plan's port rule as written forbids them

`CLAUDE.md`'s rule is "if a file imports Flutter, it is not ported". Taken
literally, that drops `alarm_dismiss_summary_test`, `alarm_repeat_test`,
`alarm_sound_test`, `reliability_copy_service_test`,
`reliability_checklist_service_test` — 1,463 lines and a large share of the 912.

Verified what they actually need: `Locale`, to call
`AppLocalizations.delegate.load(locale)`. `Locale` lives in `dart:ui` and is
re-exported by `package:flutter/widgets.dart`. Nothing else Flutter-shaped is
used.

The rule is about **`lib/`**, where it protects the headless domain. Applying it
to tests of localized output is a category error — the test must construct a
`Locale` because the production API takes an `AppLocalizations`, which is itself
generated Flutter code.

**Applied.** Draft 1 already carves this out, but informally, mid-prose. The plan
is amended to state the rule in two parts: **`lib/core/` imports no Flutter,
enforced by a test** (acceptance 9, unchanged); **`test/core/` may import
`package:flutter/widgets.dart` solely to construct `Locale`**, and the enforcing
test asserts that narrow shape rather than a blanket ban it would otherwise fail.

### M4 — The data-layer port drops `providers.dart`, so nothing constructs the repository

The plan ports `app_database.dart`, `mappers.dart`, `capywake_repository.dart`
and `repository_sleep_night_store.dart`, and excludes `data/providers.dart`
because it imports `flutter_riverpod` and `live_sleep_gateway`.

`flutter_riverpod` is already a dependency (Phase 01, used by the shell), so that
half of the reason is wrong. The real blocker is only the `live_sleep_gateway`
import, which pulls `health`.

Leaving providers out entirely means Phase 03 opens with no way to read an alarm
from the database — it will have to write the provider graph as a side quest while
building Home, which is how a UI phase starts leaking architecture decisions.

**Applied.** `data/providers.dart` is ported **minus** the two sleep-gateway
providers, which are the only lines needing `health`. The sleep-night *store*
(`repository_sleep_night_store.dart`) is repository-backed and already in scope,
so what is dropped is exactly the platform read path, not the graph.

### M5 — Coverage on `lib/core` is gated at 95% but the plan does not say what is in the denominator

Phase 01 set the project gate to `--path lib` because `tool/` scripts are entry
points whose file I/O dilutes the figure. The core gate is `--path lib/core`.

`lib/core/` as ported contains six **fakes** (`fake_alarm_engine`,
`fake_notification_service`, `fake_motion_sensor`, `fake_permission_service`,
`fake_sleep_gateway`) and three **barrels** (`models.dart`, `sleep.dart`,
`puzzle.dart`). Fakes are exercised heavily by the tests that use them, so they
help; barrels are pure re-exports with no executable lines and are invisible to
lcov. Neither is a problem.

The legacy hit 98.97–99.30% on core with these same files (tracker rows 02–06),
so 95% is comfortably achievable. The plan's risk entry hedges ("measure first")
without citing that evidence.

**Applied.** The plan cites the legacy's measured core coverage as the reason
95% is known-achievable, so a shortfall is understood as a porting defect rather
than an unrealistic gate.

### M6 — `'Capywake'` → `'CapyWake'` is described as a doc-comment fix; it also appears in a test fixture

`grep -rn "Capywake" ../capywake/lib/core/` → 32 occurrences.
`grep -rn "Capywake" ../capywake/test/core/` → includes
`reliability_copy_service_test.dart:253,269`, where the string
`'Battery optimization may stop Capywake.'` is passed as `firstAttentionBody`
and then asserted with `startsWith('Battery optimization')`.

That is a **caller-supplied fixture**, not an ARB lookup, so renaming it is
behaviour-neutral — the assertion only reads the prefix. Checked, because a blind
`sed` across ported files is exactly the kind of change that is safe 31 times and
silently wrong once.

Separately noted: the new ARB says "battery optimisation" (British) where the
fixture says "optimization". The fixture does not compare against the ARB, so
nothing breaks.

**Applied.** The plan records that the casing fix is applied to prose and
fixtures, that fixture strings were checked not to be ARB-derived, and that the
`optimisation`/`optimization` divergence is ARB-side and intentional.

### M7 — Acceptance criterion 12 is unsatisfiable as written: the legacy is already dirty

Acceptance criterion 12 says "Nothing in `../capywake` modified —
`git -C ../capywake status` clean". Checked **before copying a single file**, and
it is **not clean**:

```
 M lib/features/alarms/alarm_edit_screen.dart
 M lib/features/common/capy/capy_nav_bar.dart
 M lib/features/common/capy/capy_scaffold.dart
 M lib/features/common/state_views.dart
 M lib/features/history/history_screen.dart
 M lib/features/reliability/reliability_screen.dart
 M lib/features/settings/sleep_screen.dart
 M test/features/alarms/alarm_edit_screen_test.dart
 M test/features/cartoon_settings_screens_test.dart
 M test/features/history/history_screen_test.dart
?? ai-orchestration/phases/phase-47-statistics-screen.md
```

Legacy HEAD is `80d009b "feat: cartoon redesign with the supplied illustration
library"`. Every modified file carries an mtime of **2026-11-15 21:14–21:16** —
the day *before* this rebuild began (today is 2026-11-16) — and the untracked
phase brief is from 21:51 the same evening. **This is the legacy's own unfinished
work, not damage from this session.** The only commands this session has pointed
at `../capywake` are `find`, `grep`, `wc`, `flutter test` and `git status`.

Had the criterion been left as written, it would have failed at acceptance and
the obvious reading would have been "the port touched the legacy" — sending a
later session hunting a defect that does not exist. The opposite error is worse:
relaxing the criterion to "clean enough" discards the only protection the
read-only rule has.

**Applied.** Criterion 12 becomes a **diff against a baseline recorded now**: the
exact `git status --porcelain` output above is captured in the plan, and
acceptance requires the end-state output to be **byte-identical to it**. That
detects any modification this phase makes while tolerating dirt it inherited.
Every path in the baseline is under `lib/features/` or `test/features/` —
precisely the trees this phase never reads — so a change to any file this phase
*does* touch cannot hide inside the tolerance.

The check runs twice: the baseline above (done, before any copy) and the
comparison at acceptance. Copying is `cp`/`rsync` from legacy → new only; no tool
is pointed at the legacy in write mode.

**Reported to the owner in-session**, since a dirty read-only reference is a
standing condition of the workspace rather than a Phase 02 artifact.

### M8 — The plan has no statement about what Phase 03 may assume

Phase 02's output is the substrate for every later phase. The plan lists what it
ports but never states the contract: which abstractions exist, which are fakes,
and what is **not** available until phase 05+.

Without that, Phase 03 will reasonably assume a working `AlarmEngine` exists
because `lib/core/engine/alarm_engine.dart` is present — when what exists is the
interface plus a fake, with the platform adapter deliberately absent.

**Applied.** The plan gains a short "What Phase 03 may assume" section, and the
same lands in `docs/sessions/next.md`.

---

## Low

### L1 — `lib/core` line count: 9,825 is correct but derived two ways in two documents

Audit says "62 files, 9,825 lines". Measured: 10,529 total − 704 (`theme.dart`)
= 9,825. Consistent. Recorded only so the next session does not re-measure.
**Applied** (stated in the plan with the subtraction shown).

### L2 — `test/core/` line total differs from the audit by exactly `theme_test.dart`

Audit: 15,503 lines / 48 files. Ported: 15,503 − 258 = **15,245** / 47 files.
**Applied** (plan states both).

### L3 — The plan says "no new ARB keys" without checking the ported code needs none

The five l10n-coupled core files reference keys by name
(`l10n.alarmSoundSoftMallets` and 40-odd others). Phase 01 ported all 384 keys,
so these resolve — but the plan asserts it rather than verifying it.
**Applied.** The verification is cheap and definitive: `flutter analyze` fails on
a missing generated getter, so acceptance criterion 1 already proves it. The plan
now says so explicitly instead of claiming it separately.

### L4 — `drift_dev` and `build_runner` versions are not in the legacy's `dependencies` block

The plan's dependency table cites "all eight are in the legacy pubspec at these
versions". Two of them are in `dev_dependencies`, not `dependencies`, and the
legacy's `build_runner` constraint was not read.
**Applied.** Read and corrected. The legacy's `dev_dependencies` declare
`build_runner: ^2.10.0` (not `^2.9.0` as draft 1 guessed) and
`drift_dev: ^2.32.1`. The plan now takes both from that block and marks which
of the eight are runtime versus dev.

### L5 — "No animation on the ringing surface" and the other safety rules are untouched by this phase, and the plan does not say so

A reviewer checking `CLAUDE.md` compliance finds a long safety list and a phase
plan that mentions none of it. Silence reads as oversight.
**Applied.** One line: this phase ships no UI and no copy, so the overpromising,
emergency-escape, permission-timing and motion-fallback rules are inert here; the
*services* that later enforce them (`reliability_copy_service`,
`permission_service`) port with their tests, which do assert honesty.

### L6 — The comment-budget adaptation is stated without a measurement

The plan says over-long comment runs are deleted while passing each file. In
`pets/` outside `gastrowerk/` this is honour-system — there is no
`check-comment-budget.mjs` here. Legacy core is heavily commented; "passed once"
is not a criterion anyone can check.
**Applied.** The plan commits to a specific, checkable rule instead: no ported
comment run exceeds 12 lines (`gastrowerk`'s enforced ceiling, adopted here as
the target), measured with a one-off script run at review time and reported in
the post-review. Facts that cannot be expressed in code stay, at one line.

---

## Verdict

The plan is sound in its central judgement — porting a verified-pure, 932-test
domain is clearly right, and the port rule is enforceable. The findings are
mostly about **gates that would have read green for the wrong reason**: a test
count containing an unmeasured term (H1), an art-budget check standing in for a
binary-size claim (H3), a schema assertion that reads a comment rather than the
schema (H4), a lint exposure measured after the decision it should inform (H5),
and a `schemaVersion` test whose obvious failure mode is to be edited (H6).

H2 is the one that would have cost something real and silent: 20 accessibility
and palette assertions dropped with the old theme, and no equivalent anywhere in
the new one.

Two findings caught errors in this pre-review's own first draft: H1's data-test
estimate was off by 26% until it was measured, and M7's "clean" assumption was
false before a single file moved. A pre-review that does not run its own commands
produces the defect it was written to prevent.

All 20 findings applied. None invalid.
