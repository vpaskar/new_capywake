# Next session — start here

## State

Phases 00–05 are **done** and committed.

**Current phase: `06` — Ringing and emergency stop.** Dismiss-exactly-once;
reachable escape.

**1,279 tests** pass. `lib` 97.46%, `lib/core` 99.49%, `lib/data` 88.95%.
**405 ARB keys × 10 locales.** Home, Alarms and Add/Edit are built, captured
and their deviations named — **and as of Phase 05 a saved alarm actually
reaches the platform.**

## Read in this order

1. `CLAUDE.md` — the project's rules.
2. `ai-orchestration/PHASE_TRACKER.md` — pointer, protocol, 20 phases.
3. `memory/current-phase.md` — what Phase 05 found.
4. `docs/phases/PHASE_05_POST_REVIEW.md` — including what did **not** run.
5. `docs/visual/tier_a_blocks.md` and `docs/visual/asset_gaps.md` — append.

## The simulator build is solved. Do not chase it again.

**`flutter build ios --simulator` fails for a reason that is not ours.**
`flutter_tools` runs `lipo <binary> -verify_arch arm64 x86_64`, and Xcode
27.2's lipo answers "requires exactly one input file". A stock
`flutter create` project fails identically. The binary is correct; the
verifier is broken.

**Use `flutter run -d <udid>`.** It works, and it is also why `flutter drive`
and `tool/capture.sh` have worked all along (single arch → one argument).

**Two devices, two jobs:**

| Job | Device | Why |
|---|---|---|
| Interaction, taps | iPhone 18 Pro, **iOS 27.0** | Taps do not reach the app on iOS 16.4 |
| Tier A capture | iPhone 14 Pro, **iOS 16.4** | 393×852 is the mockup geometry; the 18 Pro is 402×874 |

**Never measure Tier A on the 18 Pro.**

A caution from this phase: a `flutter drive` of a *new* integration target
after adding three plugins did not finish within ten minutes and was stopped.
`tool/capture.sh` is the proven path; budget time if you add a target.

## What Phase 05 leaves you

**The engine is wired and nothing was wired before it.**
`AlarmScheduleCoordinator` existed, fully tested, and was never constructed.
Now `AppShell` watches `alarmScheduleCoordinatorProvider` — **that watch is
load-bearing**: a Riverpod provider with no subscriber is disposed at once and
arms nothing. Removing it silently stops every alarm. There is a test that
fails if you do.

**`AlarmEngine.ringingStream` is your surface for Phase 06.** The platform
engine de-duplicates ring events already, because `Alarm.ringing` is a seeded
`BehaviorSubject` that replays to late subscribers.

**Adapters are split pure-mapper / thin-shell**, and that is why `lib/data`
went *up* to 88.95% while adding 165 lines. Keep the split: put every decision
in the mapper, leave the shell a pass-through. A decision that reaches the
shell becomes untestable by construction.

**Permissions are gated, not requested.** `AlarmPermissionGate` decides *when*
to ask — on the first transition leaving at least one alarm enabled, never on
app start, never once only Settings can help. **Nothing calls it yet.** Phase
06 or 07 wires it to a real prompt with the reason shown.

**Six new ARB keys** (399 → 405): ring notification title/body, a stop action,
two permission rationales, "Not now".

## The measurement rule, now with a third half

Phase 03: a row-mean detector cannot tell text from a layout edge — state the
method next to the number.

Phase 04: a method named beside a number is not enough if it ran against the
wrong artifact.

**Phase 05: when a tool reports a failure, check whether the tool is wrong
before believing it about your code.** Xcode 255 was read as a project defect
for a whole phase; it was a broken `lipo` call in `flutter_tools`, provable in
one command against a stock project. The same shape as `compare.dart`
reporting blocks "absent" that were on screen.

## Owed, and honest gaps

- **No arming was watched interactively.** The Save button did not respond
  while the run session was ending. The evidence that arming works is 87 tests
  against the real provider graph plus a device log proving the notification
  adapter reached iOS UserNotifications. **Do not inherit this as "tested".**
- **Android is untested and has no emulator.** Never mark it tested.
- **`check_bundle_size.dart` cannot see the three new native plugins.** It
  measures `assets/` only and still reads 95% of budget while the shipped
  binary certainly grew.
- **Phase 07/08** — when `package:health` and `live_sleep_gateway.dart` land,
  `test/core/sleep/sleep_boundary_test.dart` must go back to `exactly one`
  importer and re-assert `NSHealthShareUsageDescription` + `READ_SLEEP`.

## Validation (every phase)

```bash
flutter pub get
flutter gen-l10n                                            # if ARB changed
dart run build_runner build                                 # if Drift changed
dart format --set-exit-if-changed .
flutter analyze                                             # zero issues
dart run tool/check_arb.dart                                # 10 locales
dart run tool/check_bundle_size.dart                        # every asset tree
flutter test --coverage       # incl. art audit, manifest + comment budget
dart run tool/check_coverage.dart --path lib                # project >= 85%
dart run tool/check_coverage.dart --min 95 --path lib/core  # core >= 95%
dart run tool/check_coverage.dart --min 85 --path lib/data  # data >= 85%
```

Read coverage from the `Coverage (...)` line, never from `PASS` alone — pipe
through `tr '\r' '\n'`.

## Standing reminders

- `../capywake` is **read-only** and was already dirty before the rebuild.
- **If a file imports Flutter, it is not ported.**
- Never claim a screen matches without a recorded capture.
- A finding is applied or invalid. Never deferred.
- `main` only. **No branches, no worktrees, no stashes.**
- The comment budget bites every new file. Trim by hand — the auto-fix cuts
  mid-sentence. **Never add a file to the baseline.**
- Store publishing is drafts only.
