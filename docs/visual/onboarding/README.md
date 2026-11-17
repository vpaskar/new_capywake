# Onboarding — no mockup, no Tier A claim, deliberately excluded from capture

Phase 09 built the first-run welcome. **It has no primary mockup, so Tier A
binds nothing**, and it is **deliberately not in `integration_test/
capture_test.dart`** — a later phase that adds it would hit `compare.dart`'s
`blocksFor()` `exit(2)` (no block table) and read it as a regression.

## Why there is no mockup

`reference/01_REFERENCES/screens/primary/` holds five screens — Home, Alarms,
Add/Edit, Settings, Stats — none onboarding. The files named `onboarding_*` in
`screens/alternative/` are **exploratory boards at non-primary geometry**
(887×1774 or 852×1846, device-bezel, drawing the rejected 4-tab/Games nav),
superseded by the primary mockups per `CLAUDE.md`. Evidence:
`docs/visual/_evidence/onboarding_boards.md`.

The handoff's screen-map asks for a *direction* — "Cozy welcome, mascot, first
alarm CTA … minimal text, no extra obligatory gates" — which the welcome
honors, with no dimensional claim.

## What the screen is held to instead

- **Tokens** — `CapyButton`, `CapyColors`, `CapySpacing`, `SceneCrop.home`.
- **44 pt tap floor** — the Skip button's `minimumSize`.
- **RTL** — `EdgeInsetsDirectional`/`start`/`end`; asserted in `ar`.
- **No overpromise** — a copy test bans "never oversleep" / "guarantee" /
  "always wake".
- **No permission on app start or on the welcome** — asserted with a counting
  `FakePermissionService` (zero request calls), mutation-verified.

## Device evidence (iPhone 18 Pro, iOS 27.0 — interaction, not Tier A)

Confirmed by hand this phase (the 18 Pro is 402×874, so **not** a Tier A
measurement — interaction only):

1. Fresh install opens on onboarding (the gate fires).
2. "Set your first alarm" → the Add Alarm screen (after the self-review #1 fix;
   before it, the CTA bounced to Home).
3. Save of that first alarm → the **existing** permission prompt ("Alarm
   notifications … Cancel / Allow"), with the honest degrade copy.

Screenshots were viewed in-session, not committed — the Tier A capture harness
captures the five primary screens plus ringing, not onboarding.

## 2026-11-18 — owner art package

Welcome scene is the owner's bedroom with the sleeping Capy
(`scenes/welcome.webp`, G20 — identical to the pre-patch Home hero, no
nightcap). The puzzle step opens with the puzzle hero as a 150 pt picture card
(G22; a cutout on white, so not used as the chooser's band).
