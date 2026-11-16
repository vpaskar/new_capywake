# Typeface selection

Pre-review finding M2: the plan said "compare against a reference crop, pick
one" with no stated basis, which makes the result unfalsifiable. The criteria
below were fixed **before** rendering, and the measurements decided it.

Reference: the "CapyWake" wordmark in `01_HOME.png`, ink bbox 377×75 px.
Comparison: `font_compare.png`. Script test: `script_coverage.png`.

## Candidates

All four rendered at the same size, weight 700 where the variable axis applied.

| | x-height ÷ cap | "CapyWake" width | Terminals | Verdict |
|---|---|---|---|---|
| Nunito | 0.696 | 549 px | Rounded, light | **Out** — lowest x-height, too light at display size |
| **Baloo 2** | **0.786** | **512 px** | **Fully rounded, heavy** | **Chosen** |
| Quicksand | 0.756 | 569 px | Geometric, thin | **Out** — widest and lightest; geometric, not storybook |
| Fredoka | 0.779 | 515 px | Rounded, wide | Runner-up — rounder but wider and more geometric |

## What decided it

**Weight and terminal shape**, in that order.

The reference wordmark is **heavy** with fully rounded stroke ends. Nunito and
Quicksand read as light-to-regular at display size and were out on sight.

Between Baloo 2 and Fredoka — the two that match the weight — Baloo 2's letter
shapes track the reference more closely: the single-storey `a`, the descender of
`y`, and the `W` join. Fredoka is more geometric and ~0.6% wider on the same
string, which at the wordmark's 175 pt accumulates.

x-height ÷ cap-height confirms the eye: reference-like faces cluster at
0.78–0.79 (Baloo 2, Fredoka); Nunito's 0.696 is visibly different.

## Script coverage — the hard gate

Shipping locales: `en de ru es tr fr it pt ar ja`.

**Baloo 2 does not cover Cyrillic, Arabic or Japanese.** Verified by rendering,
not by a glyph-table lookup:

| Script | Baloo 2 | Fredoka | Nunito |
|---|---|---|---|
| Latin | ✅ | ✅ | ✅ |
| Turkish (`ğ İ ş`) | ✅ | ✅ | ✅ |
| Cyrillic (`ru`) | ❌ tofu | ❌ tofu | ✅ |
| Arabic (`ar`) | ❌ tofu | ❌ tofu | ❌ |
| Japanese (`ja`) | ❌ tofu | ❌ tofu | ❌ |

**A `PIL.getmask` check reported all five as OK for both fonts. That was wrong**
— it returns a non-empty box for `.notdef` as well, so it cannot tell coverage
from tofu. Only rendering showed the boxes. Noted because the same mistake would
pass a naive automated font gate.

### Fallback stack — decided here, not deferred

```dart
fontFamily: 'Baloo2',
fontFamilyFallback: ['Nunito', <system>],
```

- **Latin + Turkish** → Baloo 2. Covers `en de es tr fr it pt`.
- **Cyrillic** (`ru`) → **Nunito**, verified rendering correctly. Lighter than
  Baloo 2, so Russian reads slightly less heavy — an accepted, recorded
  deviation, not a defect to rediscover in Phase 03.
- **Arabic** (`ar`) and **Japanese** (`ja`) → the **system** face (SF Arabic /
  Hiragino on iOS, Noto on Android). Neither bundled candidate covers them, and
  bundling Noto Sans Arabic + Noto Sans JP would add several MB against a budget
  this phase is also setting. The system faces are well-designed and
  locale-correct.

The project does **not** claim one typeface across all ten locales. It claims
Baloo 2 where Baloo 2 covers, a recorded fallback elsewhere.

## Bundled

| File | Licence |
|---|---|
| `assets/fonts/Baloo2-Variable.ttf` | `OFL-Baloo2.txt` (SIL OFL 1.1) |
| `assets/fonts/Nunito-Variable.ttf` | `OFL-Nunito.txt` (SIL OFL 1.1) |

Both variable (`wght` axis), so weights 400–800 cost no extra files.

## The wordmark is not this font

`CapyWake` in the header is **art**, not type — no candidate reproduces its
exact lettering. See gap G10: the only source is the compressed mockup, ~380 px
where 525 px is needed at 3×. Requested from the owner in `ART_REQUEST.md`.
