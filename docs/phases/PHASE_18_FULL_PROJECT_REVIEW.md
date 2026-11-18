# Phase 18 — Full-project review

Re-ran this phase's instruments over the whole app, in the theme the phase
did not target.

**M1 — Light mode: the reliability card's body text in the "needs attention"
state was 3.89:1** (`cocoaSoft` on the `surfaceAlt` clay warning fill), since
Phase 07. Found by running the contrast gate in light. *Applied:* that text is
`cocoa` while the card warns; `text_contrast_test.dart` now runs every surface
in **both** themes, and fails if the fix is removed (checked).

**L1 — The rest of light mode fails by a hundredth:** `cocoaSoft` on cream or
surface is 4.49:1 — the sampled palette, pinned since Phase 02. Named in the
light gate (`_softCocoaOnCream`) rather than counted as a layout defect.
*Invalid as a defect — recorded constraint.*

**L2 — Every other screen that shows a time honours 12/24 h now** (grep of
`TimeFormatPreference.system` in `lib/`: only defaults and the Settings label
remain). *Applied in self-review #1; confirmed.*

**L3 — No other `Opacity` dims tappable text.** The remaining ones are game
motion, reserved-height ghosts (opacity 0) and the win spring. *Confirmed.*
