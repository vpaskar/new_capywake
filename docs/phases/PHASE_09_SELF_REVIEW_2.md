# Phase 09 — self-review #2

A second pass from a different angle than #1: edge states, not the happy path.

**2 findings: 1 Medium, 1 Low. Both applied.**

---

## Medium

### M1 — `requireValue` on the alarms stream could throw if it errored

The folded provider checked `settings.isLoading || alarms.isLoading`, then
called `alarms.requireValue` inside `settings.whenData`. If the alarms stream
reached an **error** state (not loading, not data) — a Drift failure, say —
`isLoading` is false, so execution fell through to `requireValue`, which
**throws** on a non-data `AsyncValue`. A throwing provider in a `go_router`
redirect is read on every navigation; the failure mode is a crash on the hot
path, for the one state hardest to reproduce in a test.

**Applied.** The provider now returns a value **only when both streams have
data** (`settings.hasValue && alarms.hasValue`), and `loading` otherwise. The
redirect acts only on a `true` value, so loading **and** error both resolve to
"do not redirect" — the safe direction — with no `requireValue` on a
non-data value anywhere. The H3 provider test ("is loading before the streams
emit — never a value") already pins the no-value-until-resolved invariant this
depends on.

---

## Low

### L1 — No test proved the welcome survives large text

The welcome is a scene of fixed height plus a title, a body, and two buttons.
At a 2× system text size the copy grows but the scene does not, and nothing
asserted the screen neither overflows nor clips its actions. `CLAUDE.md`'s
honoring-`disableAnimations`-and-accessibility posture extends to text scale,
and the accessibility-as-code skill bans `FittedBox`/`ellipsis` fixes — the
content must *reflow*, which here means scroll.

**Applied.** The body is already a `SingleChildScrollView` inside an
`Expanded`, so it reflows by scrolling rather than overflowing. A new test
pumps the welcome at `TextScaler.linear(2)` and asserts no exception and the
screen still renders. It passes, confirming the existing layout already
reflows — the finding is the missing proof, now supplied.

---

## Outcome

2 findings, both applied. Neither is a happy-path defect: M1 is an error-state
crash on a hot path, L1 a missing large-text proof. The phase's one real
behavioural defect was H1 in self-review #1 (the device bounce); this pass
found the two edge states that a green happy-path suite would otherwise carry
silently.
