# Phase 09 — full-project review

One pass over the whole repository, not just this phase. Findings about earlier
phases and the handoff are the point of it.

**3 findings: 1 Medium, 2 Low. All applied or recorded with a reason.**

---

## Medium

### M1 — The "Onboarding — just-in-time permissions" phase name was half wrong, and the handoff's own screen-map points at a non-mockup

The tracker, the architecture plan and `next.md` all frame Phase 09 as
"just-in-time permissions". Reading `../capywake`'s onboarding
(`lib/features/onboarding/`, read-only) and this repo's Phase 07 code shows the
framing is inaccurate in two ways, and both are worth writing down because the
next games phases inherit the same permission machinery:

1. **The just-in-time permission request was already built and shipping**
   (Phase 07: `AlarmPermissionGate`, `AlarmPermissionPrompt`,
   `permissionStateProvider`). Permissions are requested at first alarm enable,
   never on app start, and — confirmed on device this phase — the prompt fires
   on Save of the first enabled alarm. Onboarding adds a **first-run entry
   point** and the **write that closes it**, not a permission flow.
2. **The legacy onboarding asked for no permission at any step.** It is a
   three-step preferences flow (welcome → puzzle types → strictness) that
   writes `hasCompletedOnboarding`. The permission ask lived later, at first
   enable — which is what this rebuild already does.

**Applied as a correction to the record**, not the code: the plan states what
onboarding adds (entry point + write) and what it reuses (the whole Phase 07
prompt), and the post-review and `next.md` carry it. The phase shipped the
welcome + first-alarm CTA only; the puzzle/strictness steps are Phase 10's and
settings the user can already reach, named out of scope rather than padded in.

The handoff's screen-map
(`reference/.../02_VISUAL_PRIORITY_AND_SCREEN_MAP.md:28`) points onboarding at
`screens/alternative/onboarding_illustrated.png`. That file is a **brand splash
at 887×1774 (device-bezel geometry, not the primary 851×1847), drawing the
rejected 4-tab/Games nav** — an earlier exploration the primary mockups
override. **There is no onboarding mockup; Tier A binds nothing here.** Recorded
in `docs/visual/_evidence/onboarding_boards.md` and `docs/visual/onboarding/`.
The screen is held to tokens, the tap floor, RTL and the no-overpromise rule —
the same bar Phase 06's ringing screen used when it, too, had no mockup.

---

## Low

### L1 — The ported `OnboardingStatus` dartdoc describes a grandfathering path that cannot occur in this rebuild

`lib/core/onboarding/onboarding_status.dart` (ported, Phase 02) explains the
two-signal design partly by "a person who installed CapyWake before onboarding
existed has no flag, and the stored-settings reader grandfathers that case."
That was true for `../capywake`, which had 40 phases of real installs and a
six-version migration history. **It is false here.** This rebuild is at
`schemaVersion = 1` with **no users**, and the mapper's `?? true` branch
(`mappers.dart:257`) is unreachable because `toJson` always writes the key
(`:199`) — no row this app writes lacks it. The grandfathering path is dead,
kept only as defensiveness.

The code is correct and the two-signal design is still sound — the
`hasExistingAlarms` signal is the real guard, and the fresh-install path gives
`false` directly via `UserSettings.initial`, not via the mapper default. So
this is a **prose** finding, the same class as Phase 06's "ported dartdoc naming
legacy phase numbers": ported text describing the old project's world, read past
by the phase that ported it.

**Recorded, not rewritten.** Phase 02 read and judged `lib/core/`'s prose
justified, and rewriting ported domain dartdoc to chase a greenfield nuance
risks more than it fixes. The pre-review (H1) and this review state the real
path: fresh install → no row → `initial` → `false` → onboarding. The predicate
test is correct (it tests the pure function); only its third test's *comment*
narrates the legacy grandfathering case, harmlessly.

### L2 — The baseline's `grep -rn "Phase [0-9]" lib/` = 0 is scoped to hand-written Dart but stated as a bare grep

`next.md` and `current-phase.md` assert `grep -rn "Phase [0-9]" lib/` returns
**0**. Run as written it returns **2**: an ARB description in `app_en.arb:17`
("the Phase 00 launch surface it was written for was replaced by the app
shell") and its generated mirror in `app_localizations.dart`. Both predate
Phase 09 (introduced in commit `4d58efc`, Phase 01 wip).

The `CLAUDE.md` rule is "**name the layer, not the phase number**, in any doc
comment" — about Dart doc comments, where
`grep ... --include="*.dart" | grep -v generated/` is the honest measure and
returns **0** (Phase 09 added nothing). The ARB hit is a *localisation
description string* recording an accurate architectural history, not a code
comment, so it is not a rule violation.

**Applied as a precision correction:** the post-review and `next.md` state the
grep as `--include="*.dart"` excluding generated, which is **0**, and note the
ARB description is pre-existing accurate history. Not a code change — rewriting
a correct history note in a description string to satisfy a grep would be the
tail wagging the dog.

---

## Outcome

3 findings. M1 and L2 are corrections to the record; L1 is a recorded prose
observation about ported domain code.

The one that matters beyond this phase is **M1**: the phase whose name promised
a permission flow found the permission flow already built, and the honest
output was to say so and ship the small thing that was actually missing — the
first-run entry and its one write — rather than rebuild what Phase 07 already
got right (including the `permanentlyDenied` routing that Phase 07 itself found
broken and fixed). Reporting "already done" is the finding, not a reason to pad.
