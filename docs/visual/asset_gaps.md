# Asset gaps — missing, damaged or low-quality supplied art

Opened in Phase 01 under the CLAUDE.md rule *"Missing or poor-quality assets —
always report, never paper over."* Every later phase appends to this file.

Every measurement here came from running a command against the file, not from
reading a manifest. Evidence crops: `docs/visual/_evidence/asset_gaps/`.

Severity:

- **Blocking** — the screen cannot reach Tier A without new art.
- **Degraded** — shippable with a named substitution, visibly below the mockup.
- **Fixable** — we can repair it in the import pipeline, no new art needed.

## Patch received — 2026-11-16

`CapyWake_Art_Request_Patch` delivered 8 files against `ART_REQUEST.md`.
**Four gaps closed, one new defect found.** Audit: `#patch-audit` below.

| | |
|---|---|
| **Closed** | G1 (hero), G2 (game tiles — the Blocking one), G3 (mascot resolution), G10 (wordmark) |
| **New** | **G11 — ~91% of ink sits at alpha 250–254, not 255.** Fixable in the import pipeline |
| **Still open** | G4, G5, G6 (pipeline fixes), G7 (decor, low impact) |

**No blocking gap remains.** Phase 03 can reach Tier A on the game rail.

## Summary

| # | Asset | Severity | One line |
|---|---|---|---|
| G1 | Home hero (`today_integrated.png`) | **✅ Closed** | Replacement has the nightcap, duck, clock and `Zz`, tighter framing |
| G2 | Four game tiles | **✅ Closed** | All four delivered 1254², painted backgrounds, correct poses and colours |
| G3 | 31 mascots at 114–343 px | **✅ Closed** | Two sticker sheets add 16+ poses at ~300 px; needs slicing |
| G11 | Alpha 250–254 instead of 255 | Fixable | ~91% of ink in all three alpha files; art is ~2% translucent |
| G4 | All 31 mascots: ghost pixels | Fixable | 112–384 ghost pixels each, every file untrimmed |
| G5 | `clean_icons/` mixed resolution | Fixable | 9 are 1254², but `book` and `chart` are 256² |
| G6 | `clean_icons/` ghost pixels | Fixable | Up to 14,091 ghost pixels (`bell.png`) |
| G7 | Decor at 22–147 px | Degraded | Usable only as small footer decor, nothing larger |
| G8 | Nav bar icons | Not a gap | Mockup uses flat glyphs — these are real widgets, not art |
| G9 | ~~Hero scene aspect ratio~~ | **Withdrawn** | Crop is 28.1% of the art band — large, but benign and already priced into `SceneHeader` |
| G10 | Wordmark | **✅ Closed** | 2172×724 on transparency, 2103 px of ink — 4× what was needed |
| G12 | ~~Header mascot missing~~ | **Withdrawn** | Phase 03 filed it, then found two matching cells already bundled |
| G13 | Meadow footer band | Degraded | A continuous painted band; every supplied decor cutout is a small motif |

---

<a id="patch-audit"></a>

## Patch audit — what arrived and whether it is enough

### ✅ G2 — the four game tiles (was the only Blocking gap)

`reference/02_ASSETS/game_tiles/`, all **1254×1254 RGB opaque**, 1.6–1.9 MB.
Every correction from the request landed — checked by eye against the mockup
crop, not just by filename:

| Tile | Asked for | Delivered |
|---|---|---|
| `step_quest` | Blue backpack, **white headband**, park, motion marks | ✅ all four |
| `shake_dj` | **Pink** headphones, purple stage, music notes | ✅ pink, not grey |
| `catch_the_capy` | **Mid-leap**, meadow, speed lines | ✅ leaping, not sitting |
| `find_the_impostor` | Detective hat, magnifier | ✅ + paw prints |

Style matches the existing package. 1254² is 3.5× the 360 px minimum, so they
downscale cleanly to the ~120 pt tile.

### ✅ G1 — the Home hero

`header_scenes/today_integrated.png`, **1536×1024 RGB**. All four missing props
present: blue nightcap with white bobble, yellow duck, alarm clock on the
nightstand, `Zz`. Framed much tighter — the capybara now fills the frame as in
the mockup.

**Verified against the real header crop**, which is the question that mattered:
rendered top / centre / bottom at the measured 2.086:1 art band (28.1% crop).
The face, cap, duck and clock survive at every alignment. **Top alignment keeps
the `Zz`** and is what `SceneHeader` will use for this scene.

The previous file is kept as `today_integrated_ORIGINAL.png` for comparison.

### ✅ G3 — mascot resolution, via sticker sheets

Two files in `sticker_sheets/` — not the per-file re-export that was requested,
but they solve the problem:

| File | Size | Holds |
|---|---|---|
| `cozy_capybara_sticker_collection.png` | 1254×1254 | 16 poses in a 4×4 grid, ~300 px each |
| `capybara_cozy_moments_sticker_sheet.png` | 1619×971 | further poses |

~300 px per pose beats the 114–343 px originals and clears the 288 px needed
for a 96 pt empty-state illustration.

**They need slicing** — `tool/audit_art.dart` gains a sheet-splitter that cuts
on transparent gutters, trims each cell to its alpha bbox, and names them. Extra
work in this phase, not a gap.

### ✅ G10 — wordmark

`wordmark.png`, **2172×724 RGBA**, ink bbox 2103×689. The request asked for
≥1050 px; this is **2× that**. Clean transparency, no compression fringing, and
it is the mockup's own lettering rather than a font match.

### ⚠️ G11 — new defect: the art is not quite opaque

Found by measuring, and it affects **all three alpha files**:

| File | ink at alpha 250–254 | ink at 255 |
|---|---|---|
| `cozy_capybara_sticker_collection` | **90.7%** | 0.5% |
| `capybara_cozy_moments_sticker_sheet` | **91.4%** | 0.7% |
| `wordmark` | **91.3%** | 0.9% |

The artwork is ~2% translucent, so the background bleeds through everywhere.
On cream it is invisible; over the hero art or a coloured tile it would tint,
and it defeats any "is this pixel opaque" assertion.

It is a lossy-compression artifact of the generation pipeline, **not a drawing
error** — and **no new art is needed.** The import pipeline snaps alpha ≥ 250 to
255, alongside the existing ghost-clearing at ≤ 16.

**Verified safe before adopting:** sampled the 250–254 band and it is **interior
fill, not antialiased edge** — 3,243 interior pixels against 64 edge-adjacent,
a 50:1 ratio. Snapping it will not harden the outlines. (Ghost counts are high
for the same reason: 27,998–79,872 per file. Same fix, other end of the scale.)

---

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

**Corrected twice — the first two figures were both wrong, in opposite
directions.** Edge detection later separated the header from the art
(`tier_a_blocks.md`), which settles it:

| Attempt | Band used | Crop | Status |
|---|---|---|---|
| 1st draft | guessed | "~28%" | Right number, wrong reasoning — it reported the aspect delta as the crop |
| 2nd (withdrawal) | header + art, 234 pt | 10.7% | **Too small** — 59.9 pt of that band is header, not art |
| **Measured** | **art only, 188.4 pt** | **28.1%** | Edges detected at 103.9 pt and 292.3 pt |

```
hero band  393 × 188.4 pt = 2.086:1
3:2 source, cover at full width → 393 × 262.0 pt
crop = 73.6 pt of 262.0 = 28.1%, leaving 288 px of Alignment.y travel
```

**The crop is large. It is still benign**, which is what decides this. Rendered
all three alignment extremes from `today_integrated.png` at the true 2.086:1:
the capybara's face sits clear of both edges in every one, and the composition
— plant shelf, lamp, nightstand, window — survives at centre.

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

---

## G12 — Header mascot — **withdrawn, not a gap**

**Severity: none.** Opened by Phase 03's plan and withdrawn by its own
pre-review (H3) before any code was written. Kept visible, as G9 is, because
the reasoning matters more than the verdict.

`01_HOME.png` shows a sleeping capybara with `Zz` left of the wordmark. The
plan filed it as missing after reading `lib/design/art.dart`, which catalogues
only scenes, tiles and the wordmark — and then set a fallback: *if no sleeping
pose exists, omit the mascot.*

Checked against the bundle rather than the manifest, and it is there:

| Cell | Size | Reading |
|---|---|---|
| `assets/art/mascots/collection_00.webp` | 282×271 | Nightcap, `Zz`, duck, lying down — the mockup's pose |
| `assets/art/mascots/moments_12.webp` | — | Same pose, different framing |

`pubspec.yaml` already declares `assets/art/mascots/`, and
`art_manifest_test.dart` already ghost-audits the directory by scan. The only
thing missing was a catalogue id.

**The fallback would have cost a capybara.** `CLAUDE.md` requires *"as many
capybaras per screen as the mockup shows — `01_HOME.png` has six"*; omitting
the mascot ships five while the right asset sits unused in the bundle.

**Resolved in Phase 03:** `CapyArt.mascots` gains `mascot.sleeping` →
`collection_00.webp`.

**One real finding came out of it.** The mascots are bundled and ghost-audited
but were **not catalogued**, so `art_manifest_test.dart`'s `requiredPixels`
check never ran on any of them — a mascot too small for its box would have
shipped silently. Catalogued assets are now size-gated.

---

## G13 — No asset matches the meadow footer band

**Severity: Degraded.**

`01_HOME.png` draws a grass band 65.2 pt tall across the full 393 pt width,
with two small daisies. Measured at full row resolution (every row, every
pixel) rather than the sampled scan the first draft used — green dominance
(mean G−R across the row):

```
709.3 pt   −23.3    band top, the card/footer boundary
731.5 pt    −0.3    green crosses red
748.1 pt   +24.0
773.1 pt   +40.5    peak
775.8 pt    −3.8    nav bar
```

A smooth monotonic ramp over 42 pt with **no periodicity** — one continuous
painted band, not a tiled motif.

Every supplied decor asset is a small motif:

| File | px |
|---|---|
| `flower.png` | 22×53 |
| `grass_tuft.png` | 90×63 |
| `bush_round.png` | 107×71 |
| `leafy_shrub.png` | 147×81 |

The widest is 147 px ≈ 49 pt at 3×. Filling 393 pt means tiling a tuft ~4.4
times, which reads as a repeat — worse than not having the art.

**Using for now:** `lib/design/meadow_footer.dart` paints the band in `grass`
with the mockup's silhouette — two layers of overlapping rounded crowns. Logged
as a Tier B substitution.

This is **not** a return of the legacy's banned `CustomPaint` rule. That rule
was *"the capybara is vector `CustomPaint`, never a raster cutout"* — about the
**mascot**, and it is why the painted look was unreachable. Every capybara on
Home is a raster cutout. The meadow is a background shape.

**To do it properly:** one painted meadow band at ≥1179 px wide × ~196 px tall
(393 × 65.2 pt at 3×) on transparency, matching the mockup's crowns and
daisies. It would drop into `MeadowFooter` with no layout change — the band's
height is a measured constant either way.

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
5. **Meadow footer band** (G13) — ≥1179×196 px on transparency, matching the
   mockup's crowns and daisies. Currently drawn; it would drop in with no
   layout change. Visible on every tab, so it is worth more than its severity
   suggests.

G9 and **G12** were withdrawn on measurement — the header crop is benign, and
the header mascot was bundled all along.

G4, G5, G6 need no new art — Phase 01's import pipeline fixes them.

---

# Phase 04 — Alarms and Add/Edit

## G14 — the alarm-row thumbnails are cutouts, the mockup paints panels

**Tier B substitution, logged by name.** `02_ALARMS.png` gives each row a
thumbnail with its own painted background — cream gradient, grass, sky —
bleeding into the card. The bundled cells are transparent cutouts.

| Mockup row | Using | Match |
|---|---|---|
| Sleeping, blue blanket | `assets/art/mascots/moments_01.webp` | pose and subject near-exact; no painted bed |
| Headband, dumbbells | `assets/art/mascots/moments_03.webp` | near-exact; mockup adds a grass strip |
| Backpack, walking | `assets/art/mascots/collection_02.webp` | near-exact; mockup adds sky, cap and grass |
| Headphones, notes | `assets/art/mascots/collection_06.webp` | pose exact; **headphones are purple, the mockup's are blue** |

Each is drawn on a `surfaceAlt` panel so the row still reads as a picture
rather than a floating cutout. **None of these is the mockup's art**, and no
new art was generated.

**To do it properly:** four painted thumbnails at ≥372 px wide, capybara on
its own background, matching the mockup's poses and palette.

## G15 — those four cells are under-resolution for the panel

The panel is ~124 × 88 pt, needing **372 px** at 3×. The cells carry:

| Asset | px | Short by |
|---|---|---|
| `moments_01` | 288 × 190 | 84 |
| `moments_03` | 288 × 217 | 84 |
| `collection_02` | 230 × 242 | 142 |
| `collection_06` | 260 × 256 | 112 |

These are the **largest poses the package supplies** — there is no better
source in `reference/`. Recorded by name in
`test/design/art_manifest_test.dart`'s `knownUnderResolution`, so the gate
still protects every other asset and a *worse* file fails. The entry is
deleted, not widened, when the art is replaced.

## G16 — 30 of 31 bundled mascot cells were unreferenced

Before this phase only `mascot.sleeping` was in `CapyArt`. Phase 04 adds four.
**26 cells are still bundled bytes nothing draws.** Not a defect yet —
Settings, Stats and the empty states will want them — but if they are still
unused at Phase 09 they are payload, and `check_bundle_size.dart` counts them
against the budget either way.

## Not a gap — the hero scene

Both screens use `assets/art/scenes/alarms.webp`, which is a waking-in-bed
composition. `02_ALARMS.png` shows the capybara hugging an alarm clock and
`03_ADD_EDIT_ALARM.png` a third composition again. The supplied scene is
closest to neither, but it is a real supplied hero at the right aspect and the
mockups' two are not in the package. **Tier B: logged, not substituted
silently.**

---

# Phase 06 — ringing and emergency stop

## G17 — no *dedicated* ringing scene, but the Alarms scene already is one

**Filed, investigated, and largely withdrawn in the same pass.** Recorded in
full because the first answer was wrong and the correction is the useful part.

### What was filed

`AppArt.scenes` holds exactly four entries (`lib/design/art.dart:53-58`):
`scene.home`, `scene.alarms`, `scene.stats`, `scene.settings`. The Ringing
board panel (`boards/01_earlier_all_screens.png`, bottom-right) shows a
bedroom hero — capybara stretching awake in bed, window with sunrise, plant —
and no scene is named for it. Filed as "no ringing scene exists".

### The nearest candidates, measured

Measured with PIL against the file, not read off a manifest:

| Candidate | Size | Mode |
|---|---|---|
| `header_scenes/upscaled_older/cozy_bedroom.png` | 1200×800 | RGB |
| `header_scenes/upscaled_older/night_bedroom.png` | 1200×800 | RGB |
| `asset_library/scenes/sunrise_bedroom.png` | **256×183** | RGBA |
| `asset_library/scenes/cozy_bedroom.png` | **282×194** | RGBA |
| `asset_library/mascots/waking_in_bed.png` | **343×235** | RGBA |

The plan's first draft proposed substituting `upscaled_older/cozy_bedroom.png`
and logging two sub-gaps: that it is the older generation, and that it
contains **no capybara** where the board's hero is a capybara waking.

### Why that was wrong

**`assets/art/scenes/alarms.webp` is already the board's ringing hero.**
Measured 1179×786 RGB — the current generation, and exactly the width a
393 pt-wide hero needs at 3×. Viewed rather than assumed from its filename, it
shows: capybara in bed with both arms up mid-stretch, mouth open yawning,
sunrise through a window, and a **ringing alarm clock on the nightstand with
motion marks**. That is the board's composition element for element.

G16's own note already said as much — *"Both screens use
`assets/art/scenes/alarms.webp`, which is a waking-in-bed composition"* — and
called it the weaker fit for Alarms and Add/Edit, whose mockups show a
capybara hugging a clock and a third composition again.

So the asset is not missing. It is **currently used on the two screens it fits
worst, and not on the one screen it fits best.**

### Verdict

| | |
|---|---|
| Severity | **Not a gap** for Phase 06 |
| Used | `assets/art/scenes/alarms.webp`, unmodified, as the ringing hero |
| Tier B substitution | None — this is the matching asset, not a stand-in |

**What remains genuinely open**, and is *not* this phase's to fix: Alarms and
Add/Edit keep using a waking-in-bed scene their own mockups do not show (G16's
"Not a gap — the hero scene" note). Phase 06 does not change those screens.
Reusing one scene on three surfaces is a real redundancy the owner may want to
close, but no screen is blocked and nothing is substituted silently.

### What the owner would need for a dedicated ringing scene

Nothing, to ship. If the three screens should stop sharing one hero, the gap
is **two** scenes, not one: an Alarms hero (capybara hugging an alarm clock,
per `02_ALARMS.png`) and an Add/Edit hero (per `03_ADD_EDIT_ALARM.png`), each
1536×1024 in the `*_integrated.png` generation — which would leave
`alarms.webp` free to become the ringing scene it already is.

## Not a gap — the stale simulator database (recorded here because it looked like one)

Phase 06 drove the app by hand on the iPhone 18 Pro and **the Save button on
Add/Edit did nothing** — the exact symptom Phase 05 recorded and could not
explain, and which it honestly logged as unverified rather than claiming.

The device log gives the cause:

```
Unhandled Exception: Exception: You've bumped the schema version for your
drift database but didn't provide a strategy for schema updates.
```

**Not an app defect.** `AppDatabase.schemaVersion` is `1` with an `onCreate`-
only `MigrationStrategy`, deliberately and with a test
(`test/data/migration_origin_test.dart`: *"a fresh database is the only
supported origin"*). The simulator was carrying a database file from an
install made before Phase 02 set the schema to 1, so Drift found a stored
version it could not reconcile and threw on open — **after** the UI had
rendered, which is why the screen looked fine and only writes failed.

**Fix, for any session that sees it:**

```bash
xcrun simctl uninstall <udid> com.capywake.capywake
```

then `flutter run` again. Nothing in the app changes.

Worth the entry because two phases now have lost time to it, and because the
failure mode is deceptive: the app launches, navigates and paints correctly,
and only the first write fails — with the exception on the device log, not on
screen.

---

## G12 — the Settings theme tiles have no art (Phase 07)

**Reported in session, per `CLAUDE.md`'s "always report, never paper over".**

`04_SETTINGS.png` draws the Appearance group's Theme row as **three
illustrated tiles**, measured at x 180.6–240.2 / 247.1–303.0 / 310.8–366.2,
y 384.7–429.5 (saturation/dark column scan):

| Tile | What the mockup draws |
|---|---|
| 1 | A sunrise over hills, with a green check badge (selected) |
| 2 | A sunset: purple sky, orange sun at the horizon |
| 3 | A night sky: navy, crescent moon, stars |

**None of the three exists in the asset package.** `assets/art/` contains
`scenes/` (4), `tiles/` (4 game tiles), `mascots/` and `wordmark.webp`. A
search for theme / icon / sun / moon / night matches nothing.

**What is shipped instead:** each tile is drawn from palette tokens — a cream
rectangle (Light), a cream/dark split (System), a dark rectangle (Dark), with
the selected one carrying a 2.4 pt `accentDeep` border and a check. No art is
generated, per the Tier B rule.

**A second, separate issue found while mapping them.** The mockup's middle
tile reads as a **sunset**, and `ThemeModePreference` is **system / light /
dark** — there is no sunset theme. Shipping a sunset tile would put a control
on screen that changes nothing, so the middle tile is **System**. The mockup
appears to show a theme the product does not have, rather than the app
missing a tile.

**To do this properly:** three tile illustrations at ≥ 171×135 px (57×45 pt at
3×), cut to transparent PNG/WebP and passed through `tool/import_art.dart`.
The third needs to read as "follows your phone", not as a third colour scheme
— a split sun/moon rather than a sunset.

### Also from Phase 07 — not a gap, a conflict

**The mockup's settings row is 41.1 pt tall; the tap-target floor is 44 pt.**
Derived from the group spans (`docs/visual/tier_a_blocks.md`). `CLAUDE.md`
makes reachability binding — "a half-asleep user, no precision tapping" — so
rows are 44.0 pt and group 1 is 117.2 against the mockup's 110.4. This is not
fixable without breaking the accessibility rule, and is declared as a Tier A
deviation in `docs/visual/settings/README.md` rather than papered over.

## G18 — `SceneHeader` draws a flat-topped sheet; every mockup draws a cloud (Phase 08)

Measured on `05_STATS.png` while deriving the hero band. The cream shape's top
is a **scalloped cloud with lobes rising ~65 pt above its flat top** — columns
at x=48–340 return 149.6 because they hit pale lobes, while the edge columns
trace a smooth arc from 230.9 (x=4) to a flat 214.3 (x≥44).

`SceneHeader` renders `BorderRadius.vertical(top: Radius.circular(28))`.

**This affects all five screens, not Stats.** The visible consequence on Stats
is that `05_STATS.png` places "Statistics" **6.7 pt above** the cream's flat
top, inside a lobe, which a flat-topped sheet cannot do. So the title must
start below that edge, and the whole spacing budget above the switcher is
consumed by the title's own line box: `titleTopGap` and `titleToSwitcherGap`
are both **0.0** and the track still lands 1.4 pt low.

**What it would take:** a clip path or a scalloped art slice on the cream
sheet's upper edge, shared by `SceneHeader`, so the lobes are art rather than
a rounded rectangle. Not attempted here — it changes the composition of five
screens, four of them measured by other phases.

Using the flat-top measurement for `bandHeight` is correct regardless: it is
the edge the sheet actually has.

## G19 — `MeadowFooter` paints roughly twice the grass the mockups draw (Phase 08)

The widget box heights are right per screen; the painter fills far more of the
box than the mockup inks.

| | Painted grass |
|---|---|
| `05_STATS.png` | **29.1 pt** — scalloped top 744.0–764.3 down to a flat 773.1 |
| Stats capture | **60.6 pt** — 633.7 → 694.3 |

No Tier A block measures painted extent — they measure the footer's box — so
no screen has ever failed on it, which is why four phases have shipped past
it. Shared by every screen using `MeadowFooter`.

**Not changed here:** `_MeadowPainter` is used by Home, Alarms, Settings and
Stats, and three of those were measured by other phases.

## Not a gap — one nav bar, three meadows (Phase 08)

`meadow footer bottom` reports `absent` on Stats, and Phase 07 recorded Alarms
at **+10.0** and Home as `absent`. Measured across every capture:

| Screen | Painted grass ends | Nav bar |
|---|---|---|
| home | 694.3 | present |
| alarms | 694.3 | present |
| stats | 694.3 | present |
| settings | 793.0 | absent — pushed route |

**Every tab ends at exactly 694.3; the pushed route reaches the screen
bottom.** `CapyNavBar` occupies 98.7 pt (its 64.6 plus the home-indicator safe
area) where the mockup allots 79.9.

These are **one fact, not three screen-local ones**: each tab's meadow is
pushed up by the same nav bar. Recorded as a single shell-geometry item rather
than as a defect owed by three separate phases.

## G20 — Onboarding welcome: home scene substituted for the splash bedroom (Phase 09, Tier B)

The onboarding welcome has no primary mockup (`docs/visual/onboarding/`). The
exploratory splash board (`onboarding_illustrated.png`) draws a sleeping
capybara in bed with a sunrise window — a scene the asset package has no exact
cutout for. **`SceneCrop.home` (`assets/art/scenes/today.webp`) is used
instead**, the nearest supplied scene: the same cozy sleeping-capybara-at-dawn
register, already in the bundle and already audited. The wordmark
(`assets/art/wordmark.webp`) sits over it, as on Home.

Logged as a Tier B substitution by name, per `CLAUDE.md`. No new art generated,
no fidelity claim made — there is no mockup to match.

## G21 — Puzzle type cards use Material icons, not the mockup's painted tiles (Phase 10, Tier B)

`10_PUZZLE_CHOOSER.png` draws each puzzle type as a small painted tile (a stack
of memory cards, coloured blocks, an apple). The asset package has no per-type
cutouts, and the ten real types do not map onto the mockup's six illustrative
categories anyway. **Material glyphs are used** (`puzzleTypeIcon` in
`lib/features/puzzle/puzzle_labels.dart`): `calculate`, `grid_view`,
`rotate_right`, etc. — decorative, excluded from semantics, and localizing
cleanly where a baked tile could not. No new art generated; the label always
carries the meaning. No Tier A claim (the chooser has no native mockup).

## G22 — Chooser and onboarding heroes reuse existing scenes (Phase 10, Tier B)

The chooser and the onboarding puzzle/strictness steps draw a
capybara-with-puzzle-piece hero the package has no exact cutout for. The chooser
reuses `SceneCrop.settings`; onboarding reuses `SceneCrop.home` (as Phase 09's
welcome did, G20). Nearest supplied scenes, already audited and bundled. No new
art, no fidelity claim — these surfaces bind nothing in Tier A.

## G23–G28 — Six games have no tile art (Phase 11, Tier B)

`GameCatalogue` now lists all ten games (Phase 11 completes the four it carried).
Four have tile art in the package (`tile.stepQuest`, `tile.shakeDj`,
`tile.catchTheCapy`, `tile.findTheImpostor`) and stay the Home rail. The other
six carry a tile id the package does not supply:

- **G23** `tile.memoryHideout` (Memory Hideout)
- **G24** `tile.tiltMaze` (Tilt Maze)
- **G25** `tile.morningSort` (Morning Sort)
- **G26** `tile.rhythmRescue` (Rhythm Rescue)
- **G27** `tile.capyRocket` (Capy Rocket)
- **G28** `tile.qrTreasureHunt` (QR Treasure Hunt)

**Nothing in Phase 11 renders these six.** The Home rail reads
`GameCatalogue.homeRail` (the four with art); no See-All screen is built. The id
is reserved so each game's phase (12–17) adds its tile. The gap is a known
absence, not a shipped broken image: `CapyArt.byId` throws on these ids
(`art.dart:130`), and a test (`game_rail_test.dart`) asserts they throw — so a
later phase that adds art without updating this entry is caught. No art
generated; no fidelity claim (the posters are bezel-wrapped storyboards, not
native geometry — Tier A binds nothing for games).

### G23 update — Phase 12: Memory Hideout borrows its game art as a tile (Tier B)

Memory Hideout is playable, so its tile now renders (chooser Games section,
40 pt). There is still **no painted tile** in the package: `tileAssetId` points at
`game.memoryCapy` (`mascots/moments_14.webp`, the capybara peeking over a bush).
Asserted by `game_rail_test.dart`. **Owner ask:** a painted 360 px tile matching
the other four. G24–G28 unchanged (five unbuilt games, ids still throw).

## G29 — No usable plain bush for Memory Hideout (Phase 12, Tier B, reported)

The only plain bushes are `asset_library/decor/bush_round.png` (107 px, **97 px
trimmed to ink**) and `asset_library/icons/bush.png` (98 px); `source_png/sheet_*`
bushes sit on blurred, unmasked backgrounds. Imported at **32 pt**
(`ArtUse.gameBush`, the largest it stays sharp at 3×) inside ≥ 96 pt tap cards —
the import guard was not relaxed. On screen the hidden bushes are visibly tiny
beside the 84 pt reveal art (`docs/visual/ringing_memory_hideout/`).
**Owner ask:** a transparent plain bush, ≥ 288 px wide, matching the bush in
`moments_14`. Reported in session.

## G30 — Catch the Capy: no running capybara in a nightcap (Phase 12, Tier B, reported)

`04_CATCH_THE_CAPY.png` draws a running capybara in an orange nightcap. The
package's nearest is `mascots/collection_10.webp` (running, headband, 267 px),
used as `game.catchCapy` at 88 pt. **Owner ask:** the poster's pose as a cutout,
≥ 300 px. Reported in session.

## G31 — Catch the Capy: no meadow backdrop (Phase 12, Tier B, reported)

The poster's field is a painted meadow with bushes and flowers. The package's
outdoor scenes (`asset_library/scenes/*`) are 276–312 px wide — under a third of
the ≥ 1050 × 840 px a 350 × 280 pt field needs. The field is a flat
`CapyColors.meadow` fill. **Owner ask:** a meadow scene, ≥ 1050 × 840 px, no
baked text. Reported in session.

### G31 update — the meadow now carries the package's decor

After owner feedback ("not only green field") the Catch the Capy field draws the
package's own decor behind the capybara: `leafy_shrub` (46 pt), `bush_round`
(32 pt), `sprout` (32 pt), `grass_tuft` (28 pt) — each at the largest size its
source stays sharp. Still Tier B: these are small icons on a flat fill, not a
painted meadow. **Owner ask unchanged:** a meadow scene ≥ 1050 × 840 px.

## G32 — Catch the Capy has no run cycle, dust or footsteps (Phase 12, reported)

Owner asked for moving legs, a dust animation and footsteps. **None exists as
art.** `collection_10` is one still pose; `animations/03_walk_cycle` is a
backpack *walk* tweened programmatically from a single still (its own README
says so) — its legs do not move either. Drawing limbs, dust or prints in code
would be generating art (and the legacy's `CustomPaint` failure), so the game
ships a flip-to-face-direction plus a three-bounce stride on the still pose.

**Owner ask** (transparent PNG, one character, facing **right**, shared canvas
so frames do not jitter, no baked dust):

1. **Run cycle** — 6–8 frames, legs alternating, ≥ 300 × 300 px each, ideally in
   the poster's orange nightcap (closes G30 too).
2. **Dust puff** — 3–4 frames (appear, grow, fade), ≥ 150 px, separate from the
   capybara so it can trail behind.
3. **Footprint** — one paw print (or a left/right pair), ≥ 90 px, to stamp and
   fade along the path.

## G23, G29, G30, G31, G32 — closed by the owner's game art (2026-11-17)

Supplied as `CapyWake_Game_Art_Assets` (six files), kept unmodified in
`reference/02_ASSETS/game_art/` and imported by `tool/import_art.dart`:

| Gap | Supplied file | Bundled as | Notes |
|---|---|---|---|
| G30, G32 | `run_cycle_sprite_sheet.png` (4×2, nightcap, facing right) | `games/run_00`–`07.webp`, 288×240 | Cut on the grid, ink bounds at alpha ≥ 100 (the sheet carries faint specks), right- and bottom-aligned on one canvas: nose fixed, feet on one baseline. Consecutive-frame difference 7–19 %, loop seam 9 % — no jump. Lossy colour / lossless alpha (−75 % size) to keep `assets/art` inside its budget. |
| G32 | `dust_puff_sprite_sheet.png` (2×2: appear, grow, full, fade) | `games/dust_00`–`03.webp`, 144×105 | Same alignment; 31 % of its non-zero pixels were ghosts, cleared. |
| G32 | `paw_footprints.png` (a pair) | `games/paw.webp`, 72×70 | The two paws are the same drawing, so one is used; prints alternate sides of the path instead. |
| G31 | `meadow_background.png` 1402×1122 (exactly the field's 1.25 aspect) | `games/meadow.webp`, 1080×864 | **Palette note:** a saturated blue sky, cooler than the app's warm cream/peach. Used as supplied; the capybara is kept below the horizon (22 % of the field). |
| G29 | `plain_bush.png` | `games/plain_bush.webp`, 292×135 | Flat base sat on the trimmed edge and tripped the severed-crop check (visually intact); a 2 px margin rather than a relaxed guard. |
| G23 | `memory_hideout_tile.png` | `tiles/memory_hideout.webp`, 360×360 | **Wrong variant as supplied:** a baked cream frame on black corners, while the four other tiles are full-bleed. Cut 64 px inside the frame; the remaining dark corner reaches 9 px, under the tightest clip the app draws (21 px) — pinned by a pixel test. |

All ink sat at alpha 250–254 (G11's pattern), snapped by the pipeline. The
earlier stand-ins (`collection_10` runner, `decor/` bush, shrubs, sprouts and
tufts) are removed from the bundle.

## G33 — Catch the Capy tile has no nightcap (Phase 12, owner ask open)

The game's capybara wears the orange nightcap (owner run cycle); the Home tile
`reference/02_ASSETS/game_tiles/catch_the_capy.png` shows it bare-headed, so
the tile and the game disagree. **Owner decision (2026-11-17): a new tile with
the hat.** Until it arrives the current tile stays.

**Ask:** redraw `game_tiles/catch_the_capy.png` with the capybara wearing the
nightcap from `game_art/run_cycle_sprite_sheet.png` (orange, white brim and
pompom). Keep everything else as it is: 1254 × 1254 px, full-bleed (no frame,
no black corners, no baked rounded edge), the same meadow, pose and motion
lines, no text. Drop it in as `reference/02_ASSETS/game_tiles/catch_the_capy.png`;
`dart run tool/import_art.dart` picks it up with no code change.

## G34 — No win celebration for the games (Phase 12, owner ask open)

Owner asked (2026-11-17) for an animation or image when a game is won, in every
game. The package's `animations/05_celebration` (36 frames, capybara with a
trophy and confetti) does not fit: **no nightcap** (the game's Capy wears one),
**a trophy** (the app has no scores, streaks or bests), and 36 frames come to
~540 KB lossy against ~187 KB left in the `assets/art` budget. **Ask:** item 1 of
`ART_REQUESTS.md` — 6–8 frames of nightcap Capy cheering with confetti, no
trophy, ≥ 360 px, one canvas.

---

# Owner art package — `CapyWake_Open_Art_Requests` (2026-11-18)

Answers `ART_REQUESTS.md` items 1–11. 40 files, copied unmodified into
`reference/02_ASSETS/` (git-ignored) and imported by `tool/import_art.dart`.
Every file was checked for size, alpha (ghosts, the 250–254 band), backing,
crop, frame alignment and variant before use, and every defect below was
reported to the owner in session.

| Gap | Supplied | Verdict | Bundled as |
|---|---|---|---|
| G33 | `game_tiles/catch_the_capy.png` 1254² native, nightcap | **Closed.** Clean, full-bleed. | `tiles/catch_the_capy.webp` 360² |
| G24, G27 | `tilt_maze.png`, `capy_rocket.png` 1254² native | **Closed.** Clean, full-bleed. | `tiles/tilt_maze.webp`, `tiles/capy_rocket.webp` |
| G25, G26, G28 | `morning_sort.png`, `rhythm_rescue.png`, `qr_treasure_hunt.png` | **Closed, Tier B.** Upscaled from a sheet panel, and the **wrong variant**: a rounded frame (radius ≈ 220 px) on white corners, not full-bleed. Cut 72/72/80 px inside the frame (`inset:`), as with Memory Hideout; residual corner white measured 0 px. Lower native detail, invisible at 360 px. | `tiles/morning_sort.webp`, `rhythm_rescue.webp`, `qr_treasure_hunt.webp` |
| G34 | `animations/06_win_celebration/frames/frame_00`–`07.png`, 360² | **Closed, Tier B.** One canvas, every frame's feet on row 343 (checked by the importer, `BASELINE DRIFT` otherwise). Defects: a **light halo** from background removal along every outline and confetti piece, visible on dark backgrounds (unseen on cream, where the win screen draws it); **`frame_03` is noisier** and carried 1,531 ghost and 918 near-solid (250–254) pixels, cleared by the pipeline. Lossy colour, lossless alpha. | `animations/win_00`–`07.webp` |
| G13, G19 | `decor/meadow_footer.png` 1179×196, transparent | **Closed, Tier B.** Clean alpha. Flat vector style (programmatic per the manifest) — simpler than the mockup's painted grass, but the right shape: ink is the bottom 124 px, so it paints ~41 pt of grass in a 65.2 pt box, where `_MeadowPainter` painted ~60. Imported as an edge-to-edge band (`cutout: false`): it touches both sides by design, so the severed-crop check does not apply. | `decor/meadow_footer.webp` |
| G18 | `decor/cloud_edge_cream.png` 1179×200 | **Closed.** Cream is `#FEF4E8`. Defect: a **1 px tan outline on the left, right and bottom edges**, which would draw a seam where the cloud meets the sheet; cut with `inset: 1`, leaving 1177 px (2 px under 1179, recorded in `knownUnderResolution`). Lobes are rows 0–77 of 198, so they rise 26 pt above the sheet's flat top; `SceneHeader` pins both numbers and `art_manifest_test` checks them against the file. Dark mode tints it to the sheet colour (`srcIn`), which drops the outline. | `decor/cloud_edge.webp` |
| G14, G15 | `alarm_thumbnails/*.png` 372×264 | **G14 closed, G15 still open.** Painted panels, the right subjects, **blue** headphones. Defects: upscaled sheet crops (soft), **rounded white corners baked in** (up to 20 px on the diagonal). Cut with `inset: 20` → 332×224, **under the 372 px a 124 pt panel needs**, recorded in `knownUnderResolution`. | `thumbnails/sleeping`, `workout`, `walk`, `music` |
| G12 | `themes/system.png` 171×135 | **Closed, Tier B.** Split sun/moon as asked. Defects: a board crop, upscaled and soft; white margins and rounded white corners, off-centre. Cut with `inset: 13` → 145×109, **under 171 px**, recorded. | `themes/system.webp` |
| G12 | `morning_sunrise.png`, `night_sky.png` 1200×800 (`Remaining_Assets_Patch`) | **Closed.** 3:2 scenes covering a 1.27:1 tile are scaled to its 44.8 pt height, so they are imported at 204 px wide (`ArtUse.themeScene`, 68 pt). | `themes/light.webp`, `themes/dark.webp` |
| G21 | `puzzle_icons/*.png` 132² | **Closed, Tier B.** Defects: **cream tile backing** (not transparent glyphs), rounded white corners, upscaled, crops inconsistent (`rotated_shapes` and `grid_patterns` cut through the glyph edge); and **four file names are shifted against their drawings**: `digits_backwards.png` draws "[123]" (remember digits), `grid_patterns.png` draws "123" between reverse arrows (digits backwards), `spot_the_change.png` draws the 3×3 grid (grid patterns), `remember_digits.png` draws two cards (spot the change). Mapped by drawing, not by name, in `_puzzleIconJobs`. Cut with `inset: 14`, drawn at 32 pt in an 8 pt rounded clip. | `icons/puzzle_*.webp` 96² |
| G20 | `onboarding/welcome_scene.png` 1536×1024 | **Closed, Tier B.** Sleeping Capy in the bedroom with a sunrise window, matching the splash board. It is **pixel-identical to `header_scenes/today_integrated_ORIGINAL.png`** (the pre-patch Home hero), and the Capy wears **no nightcap**. | `scenes/welcome.webp` |
| G22 | `header_scenes/puzzle_hero.png` 1536×1024 | **Half closed.** Used in the onboarding puzzle step as a 150 pt picture card. Defects: **not a scene** — a cutout on a flat white matte, upscaled from a sheet, soft. **Not used in the chooser:** its 109 pt band covering a 3:2 image keeps 42 % of the height and cuts the Capy's face. The chooser keeps `SceneCrop.settings`. | `scenes/puzzle_hero.webp` 720×480 |
| G17 | `header_scenes/alarms_hero.png`, `add_edit_hero.png` | **Not new art.** `alarms_hero.png` is pixel-identical to `alarms_integrated.png` (already the Alarms scene); `add_edit_hero.png` is pixel-identical to `settings_integrated.png` (already the Settings scene). Neither is the mockups' Capy hugging a clock. Nothing imported. | — |

**Budget.** `assets/art` would not have fitted (≈ 187 KB left, ≈ 600 KB new).
The 31 sticker-sheet mascots, 1,469 KB lossless, now use the run cycle's lossy
colour / lossless alpha: 473 KB. `assets/art` is 1,380 KB of 2,182 KB; the
budget was not touched.

**Known short, by name** (`knownUnderResolution` in `art_manifest_test.dart`
and `knownShort:` in the importer, so every other file still fails the gate):
thumbnails 332 px of 372, System tile 145 of 171, cloud edge 1177 of 1179.

## What would close the rest

1. **Alarm thumbnails at ≥ 372 × 264 px, native, full-bleed** (no rounded
   corners, no white) — closes G15.
2. **System theme tile at ≥ 171 × 135 px, native, full-bleed** — the drawing is
   right, only the crop and resolution are not.
3. **Ten puzzle icons as transparent glyphs at ≥ 96 px**, each centred with a
   margin, no cream tile — or, if the cream tile is wanted, the tile drawn whole
   with no white corners.
4. **Puzzle hero as a painted scene, 1536 × 1024**, with the Capy's head and
   piece inside the middle 40 % of the height so a 109 pt band can crop it.
5. **Win celebration without the halo** — the same frames, cut with a clean
   matte edge.
6. *(optional)* **Alarms / Add-Edit heroes** that actually show the mockups'
   Capy hugging a clock (G17); the two supplied are the existing scenes.

## G34 follow-up — per-game win poses (`CapyWake_10_Celebrations`, 2026-11-18)

Ten stills in a 2×5 sheet plus ten 512×308 cell crops, copied unmodified to
`reference/02_ASSETS/animations/07_game_celebrations/`. Imported per game as
`animations/pose_<game>.webp` (300 px, lossy colour / lossless alpha, ~20 KB
each); `GameEntry.winPoseAssetId` keys them by game, and the win screen falls
back to the shared `06_win_celebration` frames for a game without one.

| Finding | Detail | Handling |
|---|---|---|
| **Blue nightcaps** | Every pose wears a **blue** cap; the games' Capy wears **orange**. The README says the generator did this. | **Used anyway**, reported. Blue is not foreign to the app — the Home hero's Capy wears a blue nightcap — and each pose names its game (bush, rocket, magnifier, flag…), which the shared frames cannot. Revert by deleting `winPoseAssetId`s. |
| **Stills, not animations** | No frames. | A 700 ms spring-in (scale 0.6→1, elastic; fade over the first 40 %). Still under reduce-motion or a screen reader. |
| **Alpha** | No pixel at 255: all ink in the 250–254 band, plus 15–21 k ghost pixels per cell. Edges are clean on dark (no halo). | Normalized by the pipeline. |
| **`09_capy_step_quest.png` is severed** | The nightcap is cut flat on the cell's top row (33 px of ink at alpha > 100 on row 0), and the sheet is cut at the same line. | **Not imported** — the severed-crop guard is right. Step Quest is blocked anyway; it falls back to the shared frames. |
| **`05_morning_sort.png` shows a backpack** | No cards or sorting; reads as a walk. | Used; reported. |

## SceneHeader cloud edge — Home excluded, and what `compare.dart` now reports

`01_HOME.png` draws a **rounded card with an outline**, not a cloud; the other
four mockups draw a cloud. Home keeps `cloudEdge: false`.

With the cloud on, `compare.dart`'s `hero scene lower edge` moves −7 to −8 pt or
reads `absent` on Alarms, Add/Edit, Settings and Stats. **That is the
instrument, not the layout:** its row detector now meets the lobes' crests,
while the table's values are the mockups' *flat top* (Stats by the arc
asymptote). Measured directly — first row where every column is sheet cream —
the flat top is unchanged within 0.7 pt on all five screens (offsets from the
status bar): Home 247.7 / 248.3, Alarms 209.0 / 208.5, Add/Edit 172.7 / 172.0,
Settings 169.3 / 168.9, Stats 172.0 / 171.4. Every other block is unchanged or
better; Alarms went from 5 blocks outside tolerance to 3 (meadow +10.0 → +0.4,
card 3 bottom +4.8 → −2.6).

**Add/Edit meadow, newly measurable.** With painted grass, `compare.dart` finds
`meadow footer top` on Add/Edit for the first time: 755.7 vs 749.4 (+6.3). The
footer's box did not move; the painter's taller grass used to hide the edge.
It joins Add/Edit's existing Tier A failures (owed, `memory/current-phase.md`).

## G35 — Rhythm Rescue: no headphones capybara cutout (Phase 13, Tier B, reported)

`09_RHYTHM_RESCUE.png` draws Capy in **orange headphones** as a cutout above the
pads, bobbing to the beat. The package has no such file: `asset_library/mascots/
music_headphones.png` (194 × 237, grey headphones, a softer 3-D style) is
under-resolved for an 88 pt box (264 px) and off-style; `alarm_thumbnails/
headphones.png` is a full-bleed panel, not a cutout. **Used meanwhile:** the
painted tile `tile.rhythmRescue` (360 px, already bundled, itself Tier B — G26)
in an 88 pt rounded panel that scales up on each lit beat. **Needed:** Capy in
the orange nightcap wearing headphones, transparent, ≥ 300 × 300, ideally 2–4
frames of a head-bob on one canvas.

## G36 — Capy Rocket: no flying rocket cutout and no sun (Phase 13, Tier B, reported)

`10_CAPY_ROCKET.png` draws Capy in goggles and a scarf **riding a rocket in
flight with a flame**, a sun at the top and a "Reach the sun!" bar. The package
has no flying-rocket cutout: `game_tiles/capy_rocket.png` is a full-bleed
painting (no alpha). **Used meanwhile:** the win pose `pose.capyRocket`
(`replacements_2026_11_18/celebrations/poses/04_capy_rocket.png`: orange cap,
Capy standing on a rocket with a puff and baked confetti) — bundled at **217 px**,
already recorded short for its 100 pt pose box, so the game draws it at
**72 pt** (217 / 3) and it stays sharp. It climbs the `themes/morning_sunrise.png`
sky (1200 × 800, imported as `games/sky.webp` at 1080 px, 21 KB). Progress is
the shared `GameHeader` pips, not a sun bar. The small sprite also limits the
visible climb to ~12 pt per boost on a 228 pt field. **Needed:** Capy (orange
nightcap) on a rocket in flight, nose up-right, with a flame, transparent,
≥ 330 × 280; optionally 2–3 flame frames on one canvas.

## G37 — Morning Sort: no item art and no open backpack (Phase 14, Tier B, reported)

`08_MORNING_SORT.png` draws six **illustrated item cards** (toothbrush, apple,
sock / rubber duck, brick, pizza), each icon above its name, and an **open
backpack** with three dashed pockets under Capy's paws. The package has none of
it: `asset_library/icons/` are 65–128 px UI icons (carrot, healthy_food, book …),
none an item from the bank and all too small for a 48 pt icon (144 px); there
is no backpack cutout. **Used meanwhile:** each card shows the item's **name
only** (a real `Text`, 18 names × 10 locales); the pockets are drawn as UI
(outlined squares that fill with a check), not art; beside them the bundled
backpack Capy `mascots/collection_02.webp` (`game.capy.hiking`, 230 px, 56 pt).
**Needed:** 18 item icons in one style — toothbrush, toothpaste, apple, banana,
water bottle, keys, socks, shoes, comb, towel / brick, anchor, traffic cone,
bowling ball, cactus, rubber duck, anvil, snowman — transparent, ≥ 160 × 160,
no text; optionally an open backpack with pockets, ≥ 600 × 360, transparent.

## G38 — Find the Impostor: no lookalike animals (Phase 14, Tier B adaptation, reported)

`05_FIND_THE_IMPOSTOR.png` asks "Which one is the real capybara?" over a 3×3
grid of **lookalike faces** — beaver, otter, hamster, guinea pig — and one
capybara. The package has no animal other than Capy. **Used meanwhile:** the
bundled capybara poses (`assets/art/mascots/`, 230–288 px, drawn at 72 pt =
216 px): one Capy doing something different among identical ones, 16 poses in
four groups (`game.capy.<pose>`). Five near-twin pairs in the bundle are kept
out of the bank, and cheering / party hat are never paired (only the hat
differs at card size). `moments_13` stands in for `collection_00` (the same
nightcap-and-duck sleeper) so the header mascot keeps a unique path.
**Needed (if the owner wants the poster's game):** head-and-shoulders faces of
a capybara and 4–6 lookalikes (beaver, otter, hamster, guinea pig, marmot) in
one style, one canvas size, transparent, ≥ 240 × 240.

## G39 — Shake DJ: no DJ decks and no dancing headphones Capy (Phase 15, Tier B, reported)

`03_SHAKE_DJ.png` draws Capy in **orange headphones, arms up, dancing behind
two turntables** with a mixer, music notes and EQ bars either side. The package
has no decks or turntable art, and no dancing headphones cutout: the win pose
`pose.shakeDj` (213 px, blue headphones, baked confetti) is a celebration, not
a game sprite. **Used meanwhile:** `game.capy.listening` (`collection_06`,
purple headphones, eyes closed, 260 px → 86 pt, sharp at 3×) bobbing to the
groove and kicking on each beat; the EQ bars and the rising note are UI
(rounded rects, a Material icon), not art; no decks. **Needed:** Capy in the
orange nightcap wearing headphones, arms up, behind a two-deck DJ table,
transparent, ≥ 330 × 300; optionally 2–4 dance frames on one canvas.

## G40 — Tilt Maze: no rolling Capy and no goal flag (Phase 15, Tier B, reported)

`07_TILT_MAZE.png` draws a small **round Capy rolling** (motion lines) and a
**checkered flag on a glowing spot**. The package has neither as a cutout: the
win pose `pose.tiltMaze` (246 px) holds a flag but bakes Capy and confetti in.
**Used meanwhile:** `game.capy.curledAsleep` (`moments_00`, 270 px, with a
baked "zz") drawn in a 27–35 pt cell, and the flag as a Material icon in cocoa
on an accent disc. The walls are drawn as UI geometry, like the poster's.
**Needed:** a round curled Capy (orange nightcap) seen from above or the side,
no "zz", transparent, ≥ 160 × 160; and a small checkered flag on a glow,
transparent, ≥ 160 × 160.

## G41 — Step Quest: no walking cycle for the backpack Capy (Phase 16, Tier B, reported)

`01_STEP_QUEST.png` draws Capy **walking with a rolled-sleeping-bag backpack
and an orange scarf** on a path, with motion marks. The package has one still
pose of a capybara with a backpack (`collection_02`, blue backpack, 230 × 242 px)
and no walk frames; the run cycle (`run_00`–`run_07`) is the nightcap runner
from Catch the Capy. **Used meanwhile:** `game.capy.hiking` (`collection_02`,
76 pt, sharp at 3×) moving from the start edge to the end edge as steps land,
with a small lift-and-tilt per step (none under reduce-motion or a screen
reader), over `game.meadow`. The count is a UI pill, not art. **Needed:** the
backpack Capy (orange scarf, rolled bag) in a 4–8 frame side-on walk cycle,
one canvas and baseline per frame, transparent, ≥ 240 × 240 — cut like
`run_00`–`run_07`.

## G42 — QR Treasure Hunt: no checkpoint scene and no peeking Capy (Phase 17, Tier B, reported)

`02_QR_TREASURE_HUNT.png` draws a **bathroom wall with a taped QR**, a towel
and a toothbrush, and a nightcap Capy **peeking over the card's top edge**.
The package has neither: no bathroom or "checkpoint" scene, no peeking cutout.
**Used meanwhile:** a plain field in the card's surface colour, viewfinder
brackets drawn as UI geometry (they pulse; still under reduce-motion or a
screen reader), and `game.capy.detective` (`collection_05`, magnifier, 72 pt)
in the middle; once "Scan QR" is tapped the real camera replaces the field.
**Needed:** a nightcap Capy peeking over an edge (head and paws only),
transparent, ≥ 300 × 160; optionally a soft bathroom-wall backdrop with an
empty taped note (no QR baked in), ≥ 1080 × 600.

## G43–G47 — The five loops (Phase 18, reported; none bundled)

`reference/02_ASSETS/animations/0N_*/` — 36 frames × 80 ms, 360², "tweened
from a single drawn pose". Read off frame 0 on cream and on dark, plus two
measures over the frames.

| Gap | Loop | Defect | Measured |
|---|---|---|---|
| G43 | `01_wake_up` | blanket's lower edge cut flat — a severed crop **inside** the canvas, which the edge-contact check cannot see | eyeballed |
| G44 | `02_sleep_breathing` | nightcap tip cut flat at the top, blanket cut flat on the right | outline coverage 0.20 |
| G45 | `03_walk_cycle` | the backpack is masked away; only its strap is left | 227 px enclosed hole |
| G46 | `04_shake_dj` | **the dark outline, eyes and leg lines were masked out with the background** — right on a dark page, holes on a light one; plus four 31 px "tofu" boxes where music notes failed to render | outline coverage 0.18 |
| G47 | `05_celebration` | clean (coverage 0.52); not bundled because its only fit, the win screen, carries the owner's 2026-11-18 replacement | — |

**Used meanwhile:** nothing changes — every screen keeps its still. Phase 18
encoded `04_shake_dj` (288 px, lossy colour + lossless alpha, 241 KB against a
220 KB prediction) before seeing G46 on cream, and removed it.

**New gate:** `outlineCoverage` (`lib/design/art_audit.dart`) — the share of a
sticker's silhouette edge with dark ink within 3 px. Every bundled sticker
(mascots, game Capys, win poses, win frames) measures 0.30 or more; the floor
is 0.25; `art_manifest_test` enforces it. It catches G44 and G46; G43 and G45
still need eyes. **Needed:** `ART_REQUESTS.md` #15 and #16.

**G47 closed (owner, 2026-11-18):** "show all of them in random order". Each
win now picks one of three by seed (`WinArt.forSeed`): the game's own pose, the
shared 8-frame cheer, or `05_celebration` as `animations/loop_celebration.webp`
(36 frames × 80 ms, 360², lossy colour + lossless alpha, **320 KB**; audited per
frame: no ghosts, edge contact 8 px, outline coverage ≥ 0.25). **Tier B:** its
Capy wears no nightcap.
