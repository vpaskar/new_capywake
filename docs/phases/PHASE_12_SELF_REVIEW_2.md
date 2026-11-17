# Phase 12 — Self-review #2

Driven from the running app on the **iPhone 18 Pro (iOS 27.0)** — both games
played to completion in practice, the chooser's Games section and "Try it"
exercised — plus a second read of the tests. **6 findings: 0 High, 2 Medium,
3 Low applied; 1 invalid on measurement.**

## M1 — The outcome line showed the answer while guessing

`lastOutcome` persists after **Ready**, and the view rendered it in every phase.
After a miss the round re-reveals the same bush (by design), so during the next
guess the screen still read "Not there. Capy is behind bush 1." — the answer, on
screen, while the user chooses.

**Applied:** the outcome shows only while revealing. Test: miss → Ready → no
"Capy is behind" text. Reverting the condition fails it.

## M2 — Ready moved under the user's finger

On device: the outcome line sat between the bushes and **Ready**, so the first
outcome pushed the button down ~30 pt. A moving primary control is exactly what
`CLAUDE.md` rules out for a half-asleep user.

**Applied:** the outcome line moved below **Ready**. Test: Ready's top-left is
identical before and after a pick.

## L1 — The Puzzles row icon was untokened black

Default `IconTheme` colour; every other row icon in the app is ink-soft.
**Applied:** ink-soft, both themes.

## L2 — Two host tests depended on a random occurrence id

The full suite failed once in ~27 runs: the Memory Hideout test picked bushes
blind, and the tolerance test's "miss" tapped the meadow's centre, where the
capybara can be. Both outcomes depend on the ring seed, which hashes a random
occurrence id. **Applied:** the Memory test reads where Capy is before picking;
misses tap the side of the field away from the capybara. Six consecutive runs
green.

## L3 — The Memory Hideout reveal and hidden bush differ wildly in size

On device the revealed card shows the 84 pt `moments_14` art and the others a
32 pt bush (G29). **Applied** as a report: logged in `asset_gaps.md` G29 with the
screenshot, and raised with the owner in session. No art generated.

## Invalid — "the capybara keeps to one column"

On device it hopped left-column three times running. **Measured over 12,000
hops: 25.6 % stay in the same column against 25 % for uniform; all nine spots
within ±4 % of each other.** Chance, not a seeding bias — no change.
