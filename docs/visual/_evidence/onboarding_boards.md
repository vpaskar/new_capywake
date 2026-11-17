# Evidence — the onboarding "mockups" are not primary mockups

Phase 09 needs to establish whether a Tier-A onboarding mockup exists. It does
not. Recorded here so no later phase re-derives it.

## The five primary screens contain no onboarding

`reference/01_REFERENCES/screens/primary/` = `01_HOME.png`, `02_ALARMS.png`,
`03_ADD_EDIT_ALARM.png`, `04_SETTINGS.png`, `05_STATS.png`. None is onboarding.
Primary geometry is **851×1847 px** (bezel-less) = 393×853 pt.

## The "onboarding" files are exploratory boards at non-primary geometry

| File | Bytes | px | What it actually is |
|---|---|---|---|
| `screens/alternative/onboarding_full.png` | 1,564,490 | 852×1846 | **Early Home/Alarms** variant, rejected 4-tab nav (Home·Games·Stats·Settings), device bezel |
| `screens/alternative/onboarding_sunrise.png` | 1,564,490 | 852×1846 | **Byte-identical** to `onboarding_full.png` |
| `screens/alternative/onboarding_illustrated.png` | 1,447,420 | 887×1774 | Brand **splash**: wordmark, sleeping mascot, "Fun wake-up challenges with Capy!", "Set Alarm" CTA, Games/Stats/Settings tiles, device bezel |
| `screens/alternative/onboarding_variant.png` | 1,447,420 | 887×1774 | **Byte-identical** to `onboarding_illustrated.png` |
| `05_LEGACY_HANDOFFS/.../CapyWake_Handover/assets/app/01_onboarding.png` | — | 887×1774 | **Byte-identical** to `onboarding_illustrated.png` |

Two distinct images, re-handed-off under five names. Verified by file size +
visual inspection 2026-11-17.

## Why none binds Tier A

1. **Wrong geometry.** 887×1774 (device bezel) and 852×1846, neither the
   primary 851×1847.
2. **Rejected navigation.** All draw the 4-tab/Games nav Phase 00 overruled in
   favor of Home·Alarms·Stats + pushed Settings.
3. **`CLAUDE.md` precedence.** The primary mockups "override every earlier board
   and exploration." These are earlier explorations.

## What the handoff screen-map asked

`03_DOCUMENTATION/02_VISUAL_PRIORITY_AND_SCREEN_MAP.md:28` points onboarding at
`onboarding_illustrated.png` and asks for: *"Cozy welcome, mascot, first alarm
CTA, optional try-puzzle step, permissions and check for reliable scheduling;
minimal text, no extra obligatory gates."*

**Directional, not dimensional.** Phase 09 honors the direction (cozy welcome,
mascot, first-alarm CTA, minimal text, no obligatory gates) and makes **no
Tier-A claim** — there is nothing at the primary geometry to measure against.
