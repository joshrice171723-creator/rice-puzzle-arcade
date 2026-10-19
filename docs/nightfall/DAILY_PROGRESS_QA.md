# Daily progression and Quick Upgrade

Implemented in the local Godot proof alongside the Gear popup iteration. This is an earned-reward feature; no new ads, real-money purchases, difficulty changes or later zones are introduced.

## Player behavior

- Expedition opens Daily rewards, with Objectives and Supplies tabs.
- Four objectives: defeat 100 enemies, open 3 field caches, finish 2 expeditions, and clear 1 campaign mission or contract. Any three earn 75 Credits, 3 Parts and one Supply key once per UTC day.
- Campaign/contract outcomes qualify after 60 seconds or a victory. Defeats can complete the first three objectives. Practice, benchmarks and short abandoned attempts do not count. Progress is banked when an attempt ends, with its existing once-only receipt.
- The seven-claim calendar grants 75 Credits; 3 Parts; 100 Credits; one key; 5 Parts; 10 Gems; two keys, then repeats. Missed days keep the player's place. Each claim requires a distinct UTC day.
- Completed unclaimed objective bonuses carry forward. Incomplete objectives reset; a new day never overwrites an already earned bonus. Multiple saved bonuses can be claimed in one transaction.
- No payment, video view, chest opening or equipment purchase is required by the daily objectives.
- Daily currency claims are available while an expedition is saved; they do not change its equipped gear or combat snapshot.

## Persistence

Profile version 4 migrates versions 1–3, preserving inventory IDs, class unlocks, existing rewards and active checkpoints. Day progression uses a local UTC watermark: moving the clock backward cannot refresh the same claim. This is local prototype state, not a server-authoritative reward service; changing the clock forward or editing files is not a solved production abuse case.

Reward, claim state and attempt completion are saved together. Failed writes restore the previous in-memory state and keep earned claims available for retry. UI reads preview day rollover without writing the save. A visible daily page checks for day rollover every 30 seconds.

## Quick Upgrade

The item popup previews the maximum number of affordable level steps and their aggregate Credits/Parts cost. Confirmation applies the whole change once. It uses the same per-level price and Workshop discount as individual upgrades, respects the current level-5 ceiling, and rejects changes during an active expedition. Rarity, substats and item identity stay unchanged.

## Verification

`tests/daily_progress_test.gd` passes 73 checks covering migration, exact seven-claim payouts, missed days, rollback dates, duplicate callbacks/claims, defeated attempts, cross-midnight banking, pending-bonus carry, persistence, write-failure rollback, excluded practice/benchmark outcomes, Quick Upgrade affordability/cap/discount/atomicity, and both daily pages at 320×568 and 430×760.

The test uses a disposable save and injected clock, never the player's profile. The Gear popup test separately exercises real modal input blocking, scroll restoration and its Quick Upgrade buttons. Full-suite/native evidence is recorded after the combined delivery is built.

## Combined delivery

The integrated full suite passed 22 suites / 5,998 checks / zero failures. The 73-check daily graphics test also passed after the key-icon and selected-tab corrections. The final Android package, native menu captures, Back fix and full saved-profile comparison are recorded in [the visual iteration report](visual-iterations/gear-v1/REPORT.md#final-integrated-validation--october-19-2026). Daily claims and Quick Upgrade spending were exercised on disposable test profiles, not the active player save.

Native Objectives and Supplies navigation was also inspected on the installed APK without claiming rewards. [Objectives capture](visual-iterations/gear-v1/native-daily-final.png).
