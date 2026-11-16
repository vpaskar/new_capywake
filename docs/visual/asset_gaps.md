# Asset gaps — missing, damaged or low-quality supplied art

Opened in Phase 01 under the CLAUDE.md rule *"Missing or poor-quality assets —
always report, never paper over."* Every later phase appends to this file.

Every measurement here came from running a command against the file, not from
reading a manifest. Evidence crops: `docs/visual/_evidence/asset_gaps/`.

Severity:

- **Blocking** — the screen cannot reach Tier A without new art.
- **Degraded** — shippable with a named substitution, visibly below the mockup.
- **Fixable** — we can repair it in the import pipeline, no new art needed.

## Summary

| # | Asset | Severity | One line |
|---|---|---|---|
| G1 | Home hero (`today_integrated.png`) | Degraded | Mockup capybara wears a nightcap and holds a duck; supplied art has neither |
| G2 | Four game tiles | Blocking | No game-tile art exists at all; mockup tiles have painted backgrounds |
| G3 | 31 mascots at 114–343 px | Degraded | Too small for a 3× render above ~57 pt; game tiles need ~120 pt |
| G4 | All 31 mascots: ghost pixels | Fixable | 112–384 ghost pixels each, every file untrimmed |
| G5 | `clean_icons/` mixed resolution | Fixable | 9 are 1254², but `book` and `chart` are 256² |
| G6 | `clean_icons/` ghost pixels | Fixable | Up to 14,091 ghost pixels (`bell.png`) |
| G7 | Decor at 22–147 px | Degraded | Usable only as small footer decor, nothing larger |
| G8 | Nav bar icons | Not a gap | Mockup uses flat glyphs — these are real widgets, not art |
| G9 | ~~Hero scene aspect ratio~~ | **Withdrawn** | Re-measured: crop is 28 pt (10.7%), not 28%. Benign, already priced in |
| G10 | Wordmark | Degraded | Must be cropped from a compressed mockup; no clean source |

---

## G1 — Home hero: the mockup art is not the supplied art

**Severity: Degraded.** Already found in Phase 00; re-verified here and it is
larger than recorded.

`reference/02_ASSETS/header_scenes/today_integrated.png` — 1536×1024, RGB.

| In `01_HOME.png` | In `today_integrated.png` |
|---|---|
| Blue nightcap with a white bobble | **Bare head** |
| Yellow duck held against the chest | **No duck** |
| Alarm clock on the nightstand | **A mug and a stack of books** |
| `Zz` floating above the head | **No `Zz`** |
| Tight crop, capybara fills the frame | Wide room, capybara ~⅓ of frame |

Evidence: `_evidence/asset_gaps/mockup_home_hero.png` vs
`supplied_today_integrated.png`.

Phase 00 recorded the cap, duck and clock. The `Zz` and the much wider framing
are new findings. The composition difference matters more than the props: to
fill the header band the supplied scene must be cropped hard, and the Phase 00
rule *"never cut the capybara's face"* plus *"never distort"* leaves a narrow
window.

**Using for now:** `today_integrated.png`, `BoxFit.cover`, alignment tuned per
scene in Phase 03. Logged as a Tier B substitution.

**To do it properly:** regenerate `today_integrated.png` to match the mockup —
nightcap, duck, alarm clock on the nightstand, `Zz`, and framed tighter so the
capybara fills a 1.7:1 band. This is the single highest-value asset in the app;
it is the first thing a user sees.

---

## G2 — The four game tiles do not exist

**Severity: Blocking** for Phase 03's game rail at Tier A.

`01_HOME.png` shows four rounded-square tiles, each a **complete illustration**:
a capybara on a painted background, inside the tile. Searched the whole package:

```
find reference/02_ASSETS -iname "*game*" -o -iname "*tile*" -o -iname "*poster*"
```

Returns only `clean_icons/gamepad.png` and three puzzle icons. **There is no
game-tile art.**

| Tile | Mockup shows | Nearest supplied | Verdict |
|---|---|---|---|
| Step Quest | Walking, blue backpack, white headband, green park, motion marks | `walking_backpack.png` | Near — no headband, no motion marks, no background |
| Shake DJ | **Pink** headphones, purple background, music notes | `music_headphones.png` | **Wrong colour** — headphones are grey |
| Catch the… | Mid-leap, green meadow, speed lines | `athletic.png` | **Wrong pose** — sitting, not leaping |
| Find the… | Detective hat, magnifier | `detective.png` | **Good match** |

Evidence: `_evidence/asset_gaps/mockup_game_rail.png` vs
`supplied_mascot_candidates.png`.

Each tile also has a **painted scenic background** (park, purple stage, meadow).
The mascots are transparent cutouts with no background at all.

**Using for now:** mascot cutout composited on a flat token-coloured tile. That
is visibly not the mockup — the mockup's tiles are painted scenes.

**To do it properly:** four tile illustrations at ≥360² (120 pt × 3×), one per
game, capybara on its painted background, matching the mockup's poses and
colours — especially Shake DJ's pink headphones and Catch the…'s leap.

---

## G3 — Mascots are too small for their render boxes

**Severity: Degraded.** All 31 measured:

| | px |
|---|---|
| Smallest | `thinking.png` 114×125 |
| Median | ~160×170 |
| Largest | `waking_in_bed.png` 343×235 |

At 3× (the iPhone 14 Pro's scale), a 160 px asset is sharp to **~53 pt** and a
343 px one to ~114 pt. The game tiles in `01_HOME.png` are ~120 pt wide with
the capybara filling most of that — so every game-rail mascot is upscaled, and
upscaling a soft-edged illustration reads as blur, not as style.

| Use | Box | Needs @3× | Have | Verdict |
|---|---|---|---|---|
| Game tile | ~120 pt | 360 px | 114–274 px | **Short** |
| Empty-state | ~96 pt | 288 px | 114–274 px | **Mostly short** |
| List row | ~44 pt | 132 px | 114–274 px | OK |
| Footer decor | ~32 pt | 96 px | ≥114 px | OK |

**Using for now:** mascots only at ≤56 pt, where they are genuinely sharp.
Anything larger is flagged on the screen that needs it.

**To do it properly:** re-export the mascots at ≥512² — same artwork, higher
resolution. They appear to have been generated small rather than downscaled, so
this is a regeneration, not a re-export, unless a larger original exists in
`SOURCE_ARCHIVES/`.

---

## G4 — Every mascot has ghost pixels and an untrimmed margin

**Severity: Fixable** — this is exactly what `tool/audit_art.dart` is for.

All 31 have scattered pixels at alpha 1–16, the signature of automatic
background masking: 112 (`confident`) to 384 (`music_headphones`). None is
trimmed to its alpha bounding box.

Ghost pixels show as a faint halo over a cream background, which is what every
screen has. Untrimmed margins make every `Alignment` wrong by an unpredictable
amount.

**Fix in Phase 01's import, no new art needed:** clear alpha ≤ 16 to 0, trim to
the alpha bbox, record the trimmed intrinsic size in the manifest. No mascot had
opaque pixels touching an edge — **no severed crops in the mascot set.**

---

## G5 — `clean_icons/` is two different asset sets

**Severity: Fixable.**

| File | Size |
|---|---|
| `alarm_clock`, `bell`, `calendar`, `gamepad`, `home`, `moon`, `settings` | 1254×1254 |
| `book`, `chart` | **256×256** |

`book.png` and `chart.png` are 1/24th the pixel count of their siblings and ship
alongside `book.svg` and `chart.svg` — a different, later export. At 256² they
are sharp to ~85 pt, which covers icon use, so this is not blocking. But they
are not the same set and should not be assumed interchangeable.

The 1254² files are **5× larger than any icon render box** (≤ 44 pt → 132 px).
Phase 01 downscales them; that is the pipeline working, not a defect.

---

## G6 — `clean_icons/` ghost pixels are severe

**Severity: Fixable.**

| File | Ghost px |
|---|---|
| `bell.png` | 14,091 |
| `settings.png` | 13,842 |
| `moon.png` | 13,026 |
| `gamepad.png` | 12,234 |
| `calendar.png` | 6,983 |
| `home.png` | 6,624 |
| `alarm_clock.png` | 5,232 |
| `book.png` | 63 |
| `chart.png` | 57 |

Two orders of magnitude worse than the mascots. Note `book`/`chart` — the later
256² exports — are clean, which supports G5's two-set reading.

Same fix as G4. Worth re-checking after downscale: resampling can smear
near-zero alpha back across the edge, so **clear ghosts before downscaling, then
re-audit after.**

---

## G7 — Decor is small

**Severity: Degraded**, low impact.

22×53 (`flower`) to 147×81 (`leafy_shrub`); sharp to 7–49 pt at 3×. That is fine
for the footer meadow band, which is what decor is for. Flagged so nobody later
reaches for `tree.png` (135×112 → 45 pt) as a hero element.

---

## G8 — Nav bar icons are *not* an asset gap

Recorded so a later phase does not "fix" this by bundling art.

`_evidence/asset_gaps/mockup_navbar.png` shows Home, Alarms and Stats as **flat
single-colour glyphs** — orange for the active tab, cocoa for inactive. Not
illustrations. These are real widgets with a token colour, per CLAUDE.md's
*"Text is always a real `Text`; buttons are always real widgets."*

`clean_icons/home.png` is a glossy 3D-style cottage, which is **not** what the
nav bar shows. Do not bundle it for the nav bar.

---

## G9 — Hero scene aspect ratio — **withdrawn, not a gap**

**Severity: none.** Logged as Degraded in the first draft on a miscalculation;
re-measured and withdrawn.

Supplied: 1536×1024 = **3:2**. Header band in `01_HOME.png`: y ≈ 62→296 pt over
393 pt wide = **1.679:1**.

The first draft said `BoxFit.cover` crops "~28% of the height". **That was
wrong** — it reported the aspect-ratio delta as if it were the crop fraction.
Measured properly:

```
cover at full width → 393 × 262.0 pt; the band needs 234 pt
vertical crop = 28.0 pt of 262.0 pt = 10.7%
```

28 **pt**, not 28 **percent**. The crop keeps 89.3% of the source height and
leaves 28 pt of `Alignment.y` travel.

Rendered all three extremes (top / center / bottom) from `today_integrated.png`.
At center the capybara's face sits well clear of both edges and the composition
— plant shelf, lamp, nightstand, window — survives intact. The crop is benign.

This is a cost Phase 00 **already priced in**: `SceneHeader` was designed around
a per-scene `BoxFit`/`Alignment` crop precisely so the face is never cut. The
mechanism exists because this crop was expected.

Raised by the Phase 00 session on review; verified here and agreed. Per-scene
alignment is tuned in Phase 03 as planned — ordinary work, not a gap.

**No new art needed.** The earlier suggestion to re-export at 1536×915 is
withdrawn with the finding.

---

## G10 — No clean wordmark source

**Severity: Degraded.**

The architecture plan says the wordmark is an asset "cropped from the reference
header". The only source is `01_HOME.png` — a **compressed** PNG whose flat
areas are clouds of near-identical values (`#FEF2E6`, `#FDF2E6`, `#FEF3E6`…).
Cropping it yields a wordmark with compression artifacts baked into its edges,
on a background that will not match the app's flat `cream` exactly.

At the mockup's size the wordmark is ~175 pt wide → 525 px at 3×; the mockup
only has ~380 px of it. **Under-resolution and artifacted.**

**Using for now:** crop, de-fringe, and composite on the token cream. Logged as
Tier B.

**To do it properly:** a transparent-background PNG of the wordmark at ≥1050 px
wide, or the vector/source file if one exists.

---

## What the owner would need to generate

Ordered by impact:

1. **Four game tiles** (G2) — the only Blocking gap. ≥360², capybara on its
   painted background, matching the mockup poses and colours.
2. **Home hero to match the mockup** (G1) — nightcap, duck, nightstand clock,
   `Zz`, tighter framing. Most-seen art in the app.
3. **Mascots at ≥512²** (G3) — unblocks game tiles, empty states and any
   large-format use.
4. **Wordmark on transparency at ≥1050 px** (G10).
G9 was withdrawn on re-measurement — the header crop is benign and needs no art.

G4, G5, G6 need no new art — Phase 01's import pipeline fixes them.
