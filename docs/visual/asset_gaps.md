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
