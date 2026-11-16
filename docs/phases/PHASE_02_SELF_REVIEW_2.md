# Phase 02 — self-review #2

A second adversarial pass after self-review #1's nine findings were applied. The
brief for this pass was explicitly *what did #1 not look at*: #1 audited the
gates and the documents, so this one audits the **numbers underneath the gates**
and the **behaviour of what was ported**.

State at review: analyze clean, format clean, **1,051 tests pass**, project
coverage 97.14%, `lib/core` 99.41%, every bundled tree inside its budget,
`capture.sh` verified.

**6 findings — 2 High, 3 Medium, 1 Low.**

---

## High

### G1 — `lib/data` sits at 85.08% and nothing gates it; the project gate hides it by averaging

`check_coverage.dart --path lib` reports 97.14% and passes. Measured per tree:

| Tree | Coverage | Gated? |
|---|---|---|
| `lib/app` | 100.00% (58/58) | no |
| `lib/features` | 100.00% (11/11) | no |
| `lib/design` | 97.38% (260/267) | no |
| `lib/core` | **99.41%** (2511/2526) | **yes, ≥95%** |
| `lib/data` | **85.08%** (422/496) | **no** |

`lib/data` is the weakest tree in the repository and clears the project's 85%
gate by 0.08 percentage points — only because `lib/core`'s 2,526 lines at 99.41%
dominate the average. If `lib/data` degraded further, the project gate would
still pass for a long time, which makes it an unmonitored tree holding the
database, the mappers and the repository: the code that persists the user's
alarms.

This is the inverse of the defect Phase 01 fixed. Phase 01 scoped the project
gate to `--path lib` so tool scripts could not dilute it; nobody then checked
whether the *remaining* trees could dilute each other.

**Applied, after finding out why it is 85%** (G2) rather than reflexively adding
a gate. The honest number for hand-written data code is 95%+; see G2 for the
arithmetic. A `lib/data` gate is added to the validation block at **≥85% now**,
with the reason recorded that the figure is depressed by 67 structurally
uncoverable lines and that the *intent* is parity with `lib/core`. Setting it at
95% today would fail for a reason unrelated to test quality, which is the kind of
gate this project keeps removing.

### G2 — 67 of `lib/data`'s 496 lines can never be covered, and the gate counts them anyway

`lib/data/database/app_database.dart` measures **8% (6 of 73 lines)**. That looks
like a hole in the suite. It is not.

Inspected the uncovered lines directly from `coverage/lcov.info`: they are the
`Table` column getters —

```dart
TextColumn get id => text()();
BoolColumn get enabled => boolean().withDefault(const Constant(true))();
```

Drift evaluates these at **build time** to generate `app_database.g.dart`. At
runtime the generated code executes and these getters never do. They are
therefore *unreachable by any test that could be written*, and the generated file
that does the work is excluded from coverage by design
(`check_coverage.dart` drops `*.g.dart` so machine output cannot inflate the
signal).

So the arithmetic is: `lib/data` is 422/496 = 85.08% as measured, but
**422/429 = 98.4%** over lines a test can actually reach. The four hand-written
files are 100% (`mappers.dart` 263/263, `repository_sleep_night_store.dart` 9/9),
95% (`capy_wake_repository.dart` 144/151) and 8% (the table definitions).

Recording this matters because the next session to look at "8%" has three bad
options available — write a meaningless test that touches the getters, add
`// coverage:ignore` (which `CLAUDE.md` forbids), or lower the gate — and the
right answer is none of them.

**Applied.** The finding is written into the post-review and `docs/sessions/next.md`
with the arithmetic, so the figure is explained where someone will meet it. No
`coverage:ignore` is added, no test is written to game the ratio, and the gate is
not lowered.

---

## Medium

### G3 — `--min 0` makes `check_coverage.dart` print PASS with no percentage

While measuring G1 I ran `check_coverage.dart --min 0 --path lib/data` and got a
bare `PASS` — no `Coverage (...)` line. Diagnosed: the tool writes its figure to
stdout and the Dart build-hooks preamble shares the stream, so a one-line result
can be swallowed by a naive filter; with `--min 1` the line appears.

Minor in itself, but it is a **measurement tool that can report success without
reporting the measurement**, which is this project's recurring defect in
miniature. Phase 01 built `capture.sh` precisely because an exit code is not
evidence.

**Applied.** Not by rewriting the tool's output plumbing mid-port — that is
unrelated to this phase and risks the gate itself — but by recording in
`docs/sessions/next.md` that figures must be read from the `Coverage (...)` line
and never inferred from `PASS` alone, and that `tr '\r' '\n'` is needed to split
the preamble. A session that trusts `PASS` learns nothing about the number.

### G4 — The schema-column test was never cross-checked against the mappers it claims to protect

N4 asserts the exact column set of all four tables. Its stated purpose (H4) is
that "every column the mappers touch is present". I wrote the expected sets by
reading `app_database.dart` — i.e. from the same source the test inspects — which
makes the assertion self-consistent but not actually a check against the mappers.

**Applied: verified independently, and it holds.** Extracted every column
reference from `mappers.dart` (`grep -oE "row\.[a-zA-Z]+"` → 42 distinct) and
confirmed each appears in N4's expected sets, across all four tables. Both
legacy-dropped columns (`final_alarm_minutes_after`, `final_at`) are absent from
the mapper references too, which is the independent confirmation that dropping
the migration history lost nothing a mapper reads.

The cross-check is now stated in the post-review with its method, so the claim
rests on two sources rather than one.

### G5 — Five core files take `AppLocalizations`, and nothing verified the keys resolve beyond `flutter analyze`

Pre-review L3 argued that acceptance criterion 1 covers this: a missing
generated getter is an analyze error, so a clean analyze proves every referenced
key exists. That reasoning is sound and analyze is clean.

But it proves only that the *symbol* resolves. It does not show the ARB actually
carries all ten locales for those keys — `check_arb.dart` does that — and I did
not confirm the two gates together cover the five files' 48 distinct key
references.

**Applied: checked explicitly.** Extracted all `l10n.<key>` references from
`lib/core/` (48 distinct) and confirmed each has a declaration in
`lib/l10n/generated/app_localizations.dart`. The single apparent miss,
`localeName`, is a built-in `AppLocalizations` member rather than an ARB key.
`check_arb.dart` independently reports all 10 locales complete at 384 keys. So
the five l10n-coupled files port with their keys fully resolved in every shipping
locale, as the reuse audit predicted — now verified rather than inferred.

---

## Low

### G6 — `lib/features` is 11 lines and 100% covered, which means nothing

`lib/features` reports 100.00% (11/11). The four screens are Phase 01
placeholders. A reader comparing trees could mistake that for feature coverage.

**Applied.** The post-review reports per-tree coverage with line counts beside
the percentages, so an 11-line 100% cannot be read as the same kind of fact as
`lib/core`'s 2,526-line 99.41%.

---

## Verdict

#1 found the gates that read green for the wrong reason. #2 found that the
**coverage** figures had the same problem one level down: a 97.14% project number
concealing the repository's weakest tree at 85.08%, and that 85.08% itself
concealing 67 lines no test can reach, with the hand-written data code actually
at 98.4%.

G2 is the finding worth keeping: three plausible "fixes" for `app_database.dart`'s
8% are all wrong, and without the explanation written down somebody will pick
one.

Nothing in this pass found a defect in the ported domain logic. The 912 core
tests and 83 data tests pass unmodified, and G4/G5 independently confirm the two
structural claims this port rests on — that the v1 schema loses no mapped column,
and that the l10n-coupled files resolve in all ten locales.

All 6 findings applied. None invalid.
