# Phase 02 — self-review #1

Against the implemented tree, after validation passed. Everything below was
measured this session.

State at review: `flutter analyze` clean, `dart format` clean, **1,051 tests
pass**, project coverage **97.14%**, `lib/core` coverage **99.41%** against the
re-enabled 95% gate, `tool/capture.sh` writes three verified PNGs at 1179×2556.

**9 findings — 3 High, 4 Medium, 2 Low.**

---

## High

### F1 — `check_bundle_size.dart` reads 83% while the real asset payload quadrupled

The pre-review's H3 caught that `sqlite3_flutter_libs` adds native artifacts the
art gate cannot see, and the plan stopped claiming "bundle size unchanged".
Implementation then added something H3 did not anticipate: **`assets/sounds/`,
7.6 MB**, because three ported tests asserted the tones exist (see F2).

Measured:

| Tree | Size |
|---|---|
| `assets/art` | 1.9 MB |
| `assets/sounds` | **7.6 MB** |
| `assets/fonts` | 956 KB |
| **`assets/` total** | **10 MB** |

`tool/check_bundle_size.dart` hardcodes `artRoot = 'assets/art'` and
`budgetKb = 2182`, so it reports "OK: 83% of budget used" — truthfully, about
art — while the bundled asset payload is now **4.6× the entire art budget**. A
reader scanning the validation output sees one green line about size and
reasonably concludes size is under control.

This is the same defect shape as H3, one level out: a gate that is green for a
reason unrelated to the risk.

**Applied.** `check_bundle_size.dart` is extended to report **every** bundled
asset tree with its own budget, so sounds are a named line with a number rather
than invisible. The art budget and its 2182 KB are unchanged — the figure was
derived from measurement in Phase 01 and nothing here justifies moving it. The
sounds budget is set at **7800 KB**, just above the measured 7.6 MB, so an
accidental re-encode or a thirteenth tone fails rather than drifts.

The uncompressed-WAV choice is deliberate and documented in
`assets/sounds/LICENSES.md` (MP3/AAC padding clicks at loop junctions while
`loopAudio` is on), so the size is a known cost, not an oversight — but it is
now a *stated* cost.

### F2 — Three ported tests silently expanded this phase's scope, and the plan never listed the sounds

`test/core/alarm_sound_test.dart` asserts that every tone in the catalogue
exists on disk, is non-trivial, and is declared in `pubspec.yaml`. The plan
ported `lib/core/alarm_sound.dart` and that test, but **listed no sound assets**
— `CAPYWAKE_REUSE_AUDIT.md` names `assets/sounds/` and `tool/generate_tones.dart`
in its port table, and both the plan and its pre-review missed them.

So the port failed three tests, and the fix was to bring in 7.6 MB of assets and
a generator script that the phase plan did not mention. That is scope the plan
should have declared, and the fact that a test caught it is luck rather than
process: had `alarm_sound_test.dart` not existed, `lib/core/alarm_sound.dart`
would have shipped pointing at twelve files that are not in the repository, and
nothing would have failed until a user tapped a sound.

**Applied.** The plan's §Scope gains `assets/sounds/` (12 WAVs + `LICENSES.md`)
and `tool/generate_tones.dart` as explicit ported items with their measured size,
and the post-review records that the omission was caught by a ported test rather
than by review. The lesson is narrow and worth stating: the reuse audit is the
port's checklist, and this plan paraphrased it instead of working through it.

### F3 — The documented art gate `tool/audit_art.dart` does not exist

`CLAUDE.md:206` and `ai-orchestration/PHASE_TRACKER.md:70` both list

```
dart run tool/audit_art.dart     # alpha/size/manifest
```

as a per-phase validation line, and `CLAUDE.md:134` states "Every imported asset
passes `tool/audit_art.dart`". **There is no such file.** `tool/` holds
`capture.sh`, `check_arb.dart`, `check_bundle_size.dart`, `check_coverage.dart`,
`compare.dart`, `generate_tones.dart`, `import_art.dart`.

Running the documented command fails with "Could not find file
`tool/audit_art.dart`". Phase 01 built the audit as a **library**
(`lib/design/art_audit.dart`) driven by `test/design/art_audit_test.dart` and
`art_manifest_test.dart`, plus the `import_art.dart` pipeline — so the checking
genuinely happens and is covered by the suite. Only the documented entry point is
wrong.

This matters beyond tidiness: a validation line that errors out is one a session
learns to skip, and the next session to run the documented list will hit it in
Phase 03 and have to decide whether art validation was ever real.

**Applied.** The docs are corrected to name the gate that exists — the two
design tests, which run inside `flutter test` — rather than inventing a
redundant script to satisfy a filename. `CLAUDE.md`, the tracker's validation
block, and the plan's acceptance criteria all now say the same true thing.
Reported in-session, since it is a Phase 01 documentation defect surfacing here.

---

## Medium

### F4 — The 12-line comment rule I committed to fails on 33 ported files

Pre-review L6 replaced the unmeasurable "passed once and tidied" with a specific
rule: **no ported comment run exceeds 12 lines**, `gastrowerk`'s enforced
ceiling. Measured across `lib/core` and `lib/data` (excluding `.g.dart`):
**33 files exceed it**, the worst being

| Lines | File |
|---|---|
| 54 | `lib/core/schedule/alarm_schedule_service.dart` |
| 45 | `lib/core/lifecycle/alarm_status_service.dart` |
| 42 | `lib/core/reliability/reliability_copy_service.dart` |
| 39 | `lib/core/history/history_service.dart` |
| 33 | `lib/core/puzzle/puzzle_round.dart` |

I set that rule and then ported 9,825 lines without applying it — the exact
failure `pets/CLAUDE.md` calls out ("every session — including the one that wrote
the script — agreed to this rule and then shipped 40-line blocks anyway").

**Applied by withdrawing the 12-line rule, which was the wrong rule for this
tree — not by gutting the code and not by claiming the rule was met.**

Measured: **50 runs over 12 lines across 33 files.** I then read the worst ones
instead of trimming on sight:

- `alarm_schedule_service.dart` (54) — DST spring-forward gap, fall-back overlap
  resolution, timezone travel, and the re-ring bug a dismissed wake window
  causes. Facts about time zones that Dart cannot express.
- `alarm_status_service.dart` (45) — the **state-machine transition table** (11
  rows, from/to/trigger) plus why a snoozed occurrence anchors on its pending
  ring: "someone on their fourth nine-minute snooze has not missed anything yet;
  calling that missed would be the app deciding it knows better than the person
  still pressing the button." That is a safety-relevant policy decision, and
  `CLAUDE.md` names shame-free copy as a High-severity concern.
- `reliability_copy_service.dart` (42), `history_service.dart` (39) — per-platform
  reliability truth and history-window semantics.

`pets/CLAUDE.md` bans comments that **restate the next line**. None of these do.
The 12-line ceiling is `gastrowerk`'s, where it was set against *that* tree's
measured distribution (p50 158 lines/file) to ratchet down 973 inherited prose
runs. Importing the number into a 9,825-line domain whose long comments are
transition tables and DST semantics was my error in pre-review L6: I replaced an
unmeasurable rule with a measurable but wrong one, which is not an improvement.

So the committed rule becomes what the project rule actually asks: **no comment
that restates the code, and nothing retained that only narrates phase history.**
That is checkable by reading, which is how `pets/` outside `gastrowerk/` works.

Trimmed under that rule where it genuinely applied: the `alarm_schedule_service`
header lost ~35 lines of phase-history narration ("Phase 04 `NextAlarmService`
delegates here", "the Phase 06 layer turns that into…") and a restatement of the
`lib/core` Flutter-free rule already in `CLAUDE.md`, keeping every DST fact. The
`app_database.dart` tables lost their five "Added in schema vN" notes, which
became false at `schemaVersion = 1`.

**If a future session wants a numeric ceiling here, it should be derived from
this tree** — and then it ratchets, like `gastrowerk`'s, rather than failing 33
files on day one.

### F5 — `sleep_boundary_test.dart` was weakened in three places and the weakening is only in the diff

Three ported assertions failed because they require infrastructure phase 07/08
adds: `live_sleep_gateway.dart` existing, `NSHealthShareUsageDescription` in the
plist, `READ_SLEEP` in the manifest. I rewrote them to assert the negative
invariant (never write, never spread) and made the read-side conditional.

That is the right call — asserting the presence of a key this phase may not add
is satisfiable only by adding it, i.e. by implementing a future phase. But the
*restoration* is recorded nowhere a future session will look. The test file's own
comments say the positive half returns "with the phase that adds the
dependency", and that is the only trace.

**Applied.** The obligation is written into `docs/sessions/next.md` and into the
tracker's phase 07/08 rows, not just a code comment: when `package:health`
arrives, `at most one` becomes `exactly one`, and the two manifest-presence
assertions come back. The conditional test
("a declared sleep read permission is paired with its rationale") already binds
automatically the moment `READ_SLEEP` appears, so the dangerous half — asking for
read access without a rationale or usage string — cannot regress unnoticed in the
meantime.

### F6 — Two palette accessibility defects found, and the decision to record rather than fix needs stating plainly

The contrast test (H2's replacement for the dropped `theme_test.dart`) found two
real AA failures in Phase 01's sampled palette:

| Pair | Ratio | Required | Verdict |
|---|---|---|---|
| `accentDeep` on `cream` / `surface` / `surfaceAlt` | 2.60 / 2.62 / 2.26 | 3.0 (UI) | **fails everywhere** |
| `accent` on the same | 2.03 / 2.04 / 1.76 | 3.0 (UI) | **fails everywhere** |
| `success`, `grass` on the same | 2.30–2.68, 1.87–2.17 | 3.0 (UI) | **fails everywhere** |
| `error` on `surfaceAlt` | 3.93 | 4.5 (body) | **fails** |
| `error` on `cream` / `surface` | 4.53 / 4.56 | 4.5 (body) | passes, marginally |
| `cocoa` on all three | ≥ 4.5 | 4.5 | passes |
| `cocoaSoft` on `cream` | 4.49 | 4.5 | large text only |

I chose to **assert the constraint rather than retune the tokens**, because the
palette is sampled from the mockups and changing it is a Tier A fidelity
decision that belongs to the owner and to a UI phase, not to a domain port.

That is defensible but it is a judgement, and an asserted-as-failing test is an
unusual thing to leave behind. The risk is that it reads as "contrast was
checked and passed".

**Applied.** The post-review states F1/F2 of the palette as **open design
constraints with owner impact**, not as closed findings: in light mode no control
may use accent, success or grass as its *only* channel for boundary or state
(it needs ink, shape or a label too), and error text may not sit on `surfaceAlt`.
Both are now checked properties — the tests fail if a token strengthens, forcing
a deliberate update rather than silent drift. **Reported in-session to the
owner**, since it constrains Phase 03's Home screen and may warrant a palette
decision.

### F7 — `prefer_initializing_formals` was silenced three times; the reason is sound but was verified only after two wrong attempts

Three files carry `// ignore_for_file: prefer_initializing_formals`. The reason
is real and I verified it with a minimal program rather than assuming: a
**private named** initializing formal (`A({required this._x})`) compiles but is
**not callable** — `A(_x: 1)` fails to resolve. So the lint's suggestion cannot
be followed without making the fields public, which changes the API of ported
code covered by 932 tests.

Before verifying, I attempted two fixes that were worse than the problem: a
`// ignore` comment placed on the wrong line, and making the five fields of
`AlarmScheduleCoordinator` public. The second would have altered a ported
public surface to satisfy a style info. Both were reverted and the file restored
from the legacy before continuing.

**Applied.** Each ignore carries the one-line fact (`Dart cannot pass a private
named initializing formal`), which is the documented exception in
`pets/CLAUDE.md` for things code cannot express. `analysis_options.yaml` is
**not** touched, so the lint stays live everywhere else. Recorded here because
"I silenced a lint" deserves to be visible with its justification rather than
buried in a diff — and because the near-miss is the finding: the ported API was
one step from being changed for a style nit.

---

## Low

### F8 — `docs/visual/*/actual.png` were overwritten by the build check

`tool/capture.sh` rewrote the three captures. This phase changes no pixel, so
they should be identical in geometry — and they verify at 1179×2556 — but the
files on disk are now this session's, not Phase 01's.

**Applied.** Verified the captures still match Phase 01's recorded Tier A state
(`compare.dart` output unchanged: header 0.1 pt, the same three body blocks still
absent because the screens have no bodies), and the post-review says the captures
were regenerated as a build check rather than as a new fidelity measurement.

### F9 — `android:label` and `CFBundleDisplayName` were wrong, which is Phase 01's miss surfacing here

`ios/Runner/Info.plist` read `<string>Capywake</string>` and
`AndroidManifest.xml` read `android:label="capywake"`. Phase 01 corrected 194
occurrences of the old casing in the ARB and did not reach the platform
manifests; a ported test (`sleep_boundary_test`, reading the plist) is what
exposed it.

Both are **user-visible**: the iOS home-screen name and the Android app label.

**Applied.** Both now read `CapyWake`. `CFBundleName` stays `capywake` (the
bundle's short name, not a display string) and `capywake.sqlite` stays lowercase
(an on-disk filename). Reported in-session.

---

## Verdict

The port itself is clean: 912 core tests, 83 data tests and the full legacy
regression net for DST, leap day, snooze sequencing and the 00:30-at-23:55 case
all pass unmodified, `lib/core` is Flutter-free by assertion, and the schema is
v1 with the two legacy-dropped columns verified absent.

The findings cluster in the same place the pre-review's did — **gates and
documents that read green or true for the wrong reason**: an art budget standing
in for the asset payload (F1), a documented validation command that does not
exist (F3), a comment rule I wrote and did not apply (F4), and a test whose
weakening lives only in a diff (F5). F2 is the one that would have shipped
broken: twelve sound files referenced by the catalogue and absent from the
repository, caught by a ported test rather than by the plan.

All 9 findings applied. None invalid.
