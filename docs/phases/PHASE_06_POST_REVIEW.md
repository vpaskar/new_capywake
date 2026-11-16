# Phase 06 — post-review

**Ringing and emergency stop.** Tracker row: *"Dismiss-exactly-once; reachable
escape."*

## Measured outcome

| | Registered | Measured | |
|---|---|---|---|
| Tests | 55–80 new | **1,372 total (+93)** | **over the band — restated below** |
| ARB keys | 405 → 405–412 | **405 (zero new)** | inside |
| `lib` coverage | **falls** to 95.5–97.3% | **97.63%** | **over the band — restated below** |
| `lib/core` | exactly 99.49% | **99.49%** | exact |
| `lib/data` | ≥ 85% | 88.95% (held) | inside |
| `lib/features/ringing` | — | 94.67% | — |

`flutter analyze` clean including infos. `dart format` clean. ARB: 10 locales
complete. Bundle: every tree inside budget. Comment budget: **0 new files
baselined**, 10 inherited entries tightened.

### Both over-band figures, restated rather than passed

**Tests: 93 new against a registered 55–80.** The band was set before the
pre-review added four findings that each demanded tests (H1's ring
idempotence, H3's three dismiss methods, H4's second-alarm case, M5's
across-a-snooze case), and before two self-reviews added 18 more. The estimate
was made against the original scope and the scope grew for stated reasons.

**`lib` coverage: 97.63% against a registered *fall* to 95.5–97.3%.** The
direction was wrong, not just the magnitude. The reasoning — "a widget-heavy
feature tree dilutes a figure carried by 99.49% core" — was sound and the
first measurement bore it out (**96.95%** immediately after implementation,
inside the band). What moved it back up was the two self-reviews: 18 further
tests pushed `lib/features/ringing` from 90.85% to 94.67%, which lifted the
project figure past its own starting point. **A prediction made before the
reviews cannot account for the reviews.** Phase 05 recorded the same shape.

## What this phase found

### 1. The legacy has no dismiss-exactly-once guard — the thing the tracker row names

Read read-only at `../capywake/lib/features/ringing/`. `dismiss()` (line 339)
and `escape()` (line 500) both open with `if (session == null) return;` and
then `await` twice before `_emit(null)` clears `_current`. `ringing_screen.dart`
holds no busy flag (grep finds only `_puzzleOpen`). `test/features/ringing/`
has no test for a double call.

So a second tap inside that window passes the null check and transitions an
occurrence whose in-memory copy is still `triggered`. **The previous project
shipped the defect this phase's row is named after.**

### 2. A third duplicate-row path, found by this phase's own test

The pre-review (H1) identified two. Implementation found a third, and the
final-alarm test is what surfaced it.

`AlarmScheduleService.targetForRing` returns the alarm's wall-clock target
only while the ring falls inside its wake window, and the fire instant
otherwise — its own doc names **"a snooze"** as a case with "no window left to
belong to". Measured: a 07:00 Europe/Berlin alarm resolves `06:00Z` for the
first ring and `06:09Z` for the snooze re-ring.

So matching an occurrence on `scheduledAt` alone meant **every snooze re-ring
created a second row**, with `snoozeCount` back at 0 — which also silently
defeats the cap and the final-alarm boundary. Fixed by matching a live
`snoozed` row on its pending ring first.

### 3. The escape confirmation threw instead of opening

Found by self-review #1 (F1), and it is the most serious thing this phase
caught in its own code. `RingingHost` sits in `MaterialApp.builder`, **above**
the router's `Navigator`, so `showModalBottomSheet` had no Navigator in its
context: tapping *Stop without solving* raised
`Navigator operation requested with a context that does not include a
Navigator`. **In the app as wired, the emergency escape did not work.**

The standalone screen tests passed throughout, because they wrap
`RingingScreen` in their own `MaterialApp`. Only the host test — the one that
rings an alarm into the live app — could see it.

Fixed by giving the host its own `Navigator`. That fix then broke the update
path (a route built in `onGenerateRoute` is cached, so the screen never saw a
new round), which the escape-prominence test caught in turn.

### 4. The escape strictness was read from the defaults, not the user's settings

Also F1. `RingingScreen._confirmEscape` resolved against
`PuzzleSettings.defaults()`, discarding the user's app-wide puzzle settings.
A user who chose *Confirm, then hold* would have got one tap. Now resolved by
the caller and passed in.

### 5. The guard's test passed for the wrong reason — proven by removing the guard

Self-review #2 (G1). The `Future.wait([dismiss(), dismiss()])` tests prove the
latch rejects a same-turn duplicate, but with in-memory fakes the async window
the latch defends **never opens**.

Verified by mutation: disabling `_claim` left **all six "exactly once" tests
green** and failed only the ring test. The terminal-action guard was held up
entirely by the status check.

Fixed with an engine whose `cancel` blocks until the test releases it. With
that, disabling the latch fails **three** tests, each for the reason the latch
exists.

### 6. Ported `lib/core/` dartdoc names the wrong phases — 12 references, five phases unread

Full-project review (P1). Phase 02 ported 62 files with their dartdoc verbatim,
carrying the **legacy's** phase numbers into a project that renumbered
everything:

- "the lifecycle layer (Phase 07)" — Phase 07 here is **Settings**
- "the Phase 18 debug gallery", "wake surface (Phase 18)" — Phase 18 here is
  **Animation and visual polish**
- "Phase 19 persists it", "settings UI (Phase 19)" — Phase 19 here is
  **Release QA**
- "The schedule engine (Phase 05) creates these" — **this phase** creates them
- "the Phase 07 `AlarmStatusService`" — ported in **Phase 02**

All 12 forward-looking references now name the **layer** instead of a number,
which cannot go stale when phases renumber. The 5 historical ones ("Until
Phase 32 …") are kept as provenance.

### 7. The ringing hero already exists and is on the wrong screens

Filed as asset gap G17, then largely withdrawn on measurement.
`assets/art/scenes/alarms.webp` (1179×786 RGB) **is** the board's ringing
composition: capybara mid-stretch in bed, yawning, sunrise window, ringing
clock on the nightstand. It is currently used by Alarms and Add/Edit, whose
own mockups show different scenes, and not by the screen it matches.

No Tier B substitution was needed. What remains open — two new scenes so the
three screens stop sharing one hero — is not this phase's and blocks nothing.

## The reference, and the standard applied

**There is no primary mockup for the ringing screen.** The five Tier A
references are Home, Alarms, Add/Edit, Settings, Stats. The only reference is
a **board panel** (`boards/01_earlier_all_screens.png`, bottom-right), a
~333×467 px crop of a 1448×1086 presentation board — which cannot produce a
±4 pt measurement.

**So no Tier A claim is made for this screen**, declared in the plan before
measuring rather than discovered at review. The standard applied instead:
design tokens (the same constants Tier A screens use), the control-height
floor measured with `tester.getRect`, and the board compared for **order and
presence** of elements.

### Where the board was deliberately not followed

The board draws a **locked Dismiss** reading "(Solve the puzzle first)" and
**no escape at all**. Shipped literally, that is a surface where someone who
cannot solve the puzzle cannot stop their own alarm — which `CLAUDE.md` makes
*always a High finding*.

The escape is present, labelled, and reachable from the first frame, and
becomes prominent once the user passes their tolerated wrong answers. Every
rule behind it already existed in `lib/core/` (`escapeVisibilityFor`,
`PuzzleEscapeStrictness` with no "off" value, `AlarmStatusService.escape`);
this phase wired them, it did not invent them.

## Scope corrections

- **`AlarmPermissionGate` removed from scope** (pre-review M3). Phase 05's
  handoff said "Phase 06 or 07 wires it". It cannot correctly live here: the
  gate fires on the first transition leaving an alarm enabled — a save/enable
  event — and by the time an alarm rings, the permission was granted or the
  alarm would not have fired. It is Phase 07's, now stated as such rather than
  left dangling.
- **Seven of ten puzzle types have no renderer.** `RingingHost.renderableTypes`
  restricts the enabled set to the three that do, so a puzzle alarm always
  shows a puzzle that can be answered. `PuzzleView` now **throws** on an
  unrenderable type rather than captioning it wrongly. The puzzle chooser is
  Phase 10.
- **Motion confirmation / "still up?" is out.** The ported ARB keys for it stay
  unused; verified that `tool/check_arb.dart` checks locale completeness, not
  usage, so this is not a gate failure and not a placeholder.

## Review ledger

| Pass | Findings | Applied | Invalid |
|---|---|---|---|
| Pre-review | 12 (4H/5M/3L) | 12 | 0 |
| Self-review #1 | 9 (2H/4M/3L) | 9 | 0 |
| Self-review #2 | 9 (2H/4M/3L) | 9 | 0 |
| Full-project | 6 (1H/3M/2L) | 6 | 0 |
| **Total** | **36** | **36** | **0** |

None deferred.

## What ran on a device, and what did not

Verified by hand on **iPhone 18 Pro (iOS 27.0)**, driving the running app:

- The app launches, Home / Alarms / Add-Edit render and navigate.
- **An alarm was created and saved through the UI** — the first time this has
  worked on a device. Phase 05 recorded "the Save button did not respond" and
  honestly did not claim it; **this phase found out why.**

### The Save button has been broken on this simulator since before Phase 04 — and it was never the app

The device log, read rather than inferred:

```
Unhandled Exception: Exception: You've bumped the schema version for your
drift database but didn't provide a strategy for schema updates.
```

`AppDatabase.schemaVersion` is `1` with an `onCreate`-only
`MigrationStrategy`, **deliberately and with a test**
(`test/data/migration_origin_test.dart`: *"a fresh database is the only
supported origin"*). The simulator was carrying a database file from an
install predating that decision, so Drift threw on open — *after* the UI had
rendered, which is why the screens looked right and only writes failed.

`xcrun simctl uninstall <udid> com.capywake.capywake`, then `flutter run`, and
the save worked immediately. **No app change.** Filed in `asset_gaps.md` under
"Not a gap", because two phases have now lost time to it.

This is the Phase 05 rule a third time: *check whether the tool — or the
device state — is wrong before believing it about your code.*

### Not verified

- **An alarm was not watched ringing in real time.** The ringing surface's
  evidence is 93 tests against the real provider graph plus a **verified
  capture taken by firing a ring into the running app**
  (`docs/visual/ringing/actual.png`, 1179×2556). Recorded, not claimed.
- **Android: untested, no emulator.**

## Honest gaps

- **Android is untested. There is no emulator on this machine.**
- **Seven puzzle types are generated but not drawable.** Named, enforced with
  a throw, and restricted at the host — not a silent gap.
- **`AlarmEngine.ringNow` is still called by nothing in `lib/`**, like
  `AlarmScheduleCoordinator` was for three phases. Recorded so it is inherited
  rather than rediscovered.
- **`AlarmPermissionGate` is still called by nothing in `lib/`** — see above.
- **`check_bundle_size.dart` still measures `assets/` only** and cannot see
  the native plugins. Unchanged from Phase 05.
