# Phase 18 — Pre-review (adversarial, before any code)

Reviewed: `PHASE_18_PLAN.md` draft; `lib/app/app.dart`, `main.dart`,
`bootstrap.dart`; `RingingHost.build`; `ShakeDjView._capy`; Flutter 3.44.7's
`image.dart` (`_ImageState.didChangeDependencies`) and `animation_controller.dart`
(`AnimationBehavior`); the five loop files, frame by frame.

## High

**H1 — Shake DJ would restart its loop on every beat.** `_capy()` wraps the
image in `TweenAnimationBuilder(key: ValueKey(('kick', beats)))` around
`TweenAnimationBuilder(key: ValueKey(('groove', cycle)))`. A new key remounts
the subtree, so the `Image` element — and its frame stream — is rebuilt from
frame 0 on every shake and every groove cycle, and swapping between the bare
image (still, done) and the wrapped one moves it too. The dance would stutter.
**`CapyLoop` takes a `GlobalKey` held by the view state**, so the image's state
reparents instead of remounting; a test pumps beats and asserts the loop's
`State` is the same object. *Applied.*

**H2 — A contrast gate that cannot see the background passes vacuously.**
"Nearest opaque ancestor fill" misses fills painted by a `Stack` sibling (a
card behind a label) and art behind text. Each miss falls back to the scaffold
— which in dark is dark, so a dark-on-dark label over a light sibling card
would pass while the real one fails, and vice versa. **The gate resolves fills
from ancestor widgets (`ColoredBox`, `DecoratedBox`/`Container` colour or
`BoxDecoration`, `Material`, `Card`), records which source it used per text,
and fails if any screen resolves fewer than half its texts to a real fill**
(a sign it is blind there). It is **proven to fail** on a planted cocoa label
in dark. Text over raster art is a declared blind spot, covered by the
captures. *Applied.*

## Medium

**M1 — The app under a ring keeps ticking**, a practice game or a loop
included, and removing that must not remount the app. `RingingHost` returns
`widget.child` bare with no ring and inside a `Stack` with one, which already
moves the child's element on every ring. **One tree shape always:** `Stack`
→ `TickerMode(enabled: no ring && no win, child: widget.child)` → optional
overlay. A test keeps a stateful counter under the child across a ring and a
win and asserts it survives and its ticker pauses. *Applied.*

**M2 — A night ring could flash light.** Settings arrive one database read
after the first frame; a user who chose Dark on a phone set to Light would see
a light first frame — on an alarm that launches the app, at night. **Defer the
first frame until the settings' first value, capped at 400 ms**
(`RendererBinding.deferFirstFrame`/`allowFirstFrame`, which only withholds
pixels from the engine). Tested: allowed on the first value, allowed by the cap
when the stream never emits. *Applied.*

**M3 — The white-on-orange CTA fails contrast in both themes** (white on
`accent` 2.07:1, under even the 3:1 large-text bar). That is the Phase 02
palette constraint, a Tier A decision for the owner, not this phase's to
retune. The gate **exempts text on an `accent`/`accentDeep` fill by colour,
names the exemption in its failure output, and pins the exempt count per
screen**, so a new exempt label is visible rather than silent. *Applied.*

**M4 — Practice cards for all ten games need ten sets of fakes** (motion,
steps, camera). Building them in the gate duplicates the per-game tests.
**The gate pumps each game's `GameRingingView` from `GameRegistry` with the
fakes the game tests already use**, not the practice screen. *Applied.*

**M5 — The loop's specks.** `04_shake_dj` carries a few isolated dots above
the head. If they are not drawn notes they are masking debris. **Inspect at
render size; the importer clears connected alpha islands under 12 px per frame
if they are debris.** *Applied — decided at import with a crop in the post
review.*

**M6 — The dark captures double the harness and its artifacts.** Every
existing screenshot stays `actual.png` (what `compare.dart` reads); dark
writes `dark.png`, never compared to the light mockups — there is no dark
mockup. `capture.sh` checks both. *Applied.*

## Low

**L1 — One more `ArtUse`.** The loop renders at 86 pt; `ArtUse.animation` is
120 pt (360 px). Use a new `ArtUse.gameLoop(renderBoxPt: 96)` → 288 px,
matching `gameRunner`. *Applied.*

**L2 — Path.** `assets/art/anim/` is not declared in `pubspec.yaml`;
`assets/art/animations/` is. **Write `animations/loop_shake_dj.webp`.**
*Applied.*

**L3 — Onboarding is not in the capture harness**, so its dark look is seen
only by the gate. **Look at it once on the iOS 27 simulator in dark** and
record what was seen. *Applied.*

**L4 — The groove bob plus the loop's sway is two motions on one dancer.**
Both are slow and in phase with nothing the user must judge (beats are counted,
never timed). Keep both; the still path removes both. *Invalid as a defect —
recorded as a choice.*

**L5 — Every new file meets the comment budget**; nothing joins the baseline.
*Applied.*
