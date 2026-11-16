# Shell capture — Phase 01

`actual.png` is a real capture from the iPhone 14 Pro simulator, written by
`tool/capture.sh` and verified by it: 1179×2556 px (393×852 pt), non-empty,
newer than the run, no DEBUG banner.

This is the gate Phase 01 existed to prove. The harness it replaced — the one
the plan originally specified — passes and writes nothing.

## Against `01_HOME.png`

`dart run tool/compare.dart shell 01_HOME`

| Block | Ref | Actual | Delta | |
|---|---|---|---|---|
| header band lower edge | 59.9 | 60.0 | **+0.1** | ✅ |
| hero scene lower edge | 248.3 | 237.3 | −11.0 | expected |
| card top (overlap) | 259.4 | 237.3 | −22.1 | expected |
| nav bar top | 730.5 | — | absent | expected |

Offsets are measured from the bottom of the status bar. The mockup draws a
44 pt one; the simulator reports a 59 pt inset, recorded per capture in
`inset.txt`. Comparing absolute offsets would charge every block below the
header a constant 15 pt error that no code change could fix.

**The header matches to 0.1 pt.** The three remaining deltas are not defects:
the screens have no content yet, so the hero band collapses to its art and the
nav bar sits at the screen bottom. Phase 03 closes them when Home gets a body;
they are recorded now so that phase inherits a measurement rather than a claim.
