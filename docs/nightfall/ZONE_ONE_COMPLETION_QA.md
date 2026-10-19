# Blackout Outskirts: implemented content and acquisition

October 19, 2026. This records the playable Godot first zone and the acquisition additions made while visual directions are being selected. It does not claim that the twenty-zone balance proposal is shipped or that difficulty has been proven by human playtesting.

## Main mission loop

Every campaign mission has 240 seconds of ordinary waves. The authored boss then arrives; killing it is required for success, with no second boss timer. An ordinary boss victory unlocks the next mission regardless of bonus medals. Movement and Dodge are manual; basic attacks, learned spells and class powers run automatically. Temporary XP, spell ranks, traits, relics and Field Scrap reset between attempts. Survivor XP, class mastery, equipped items and secured winnings persist.

| Mission | Boss | HP | Wave pressure | Boss attack cycle |
|---|---|---:|---:|---|
| 1. Garage Lights | Garage Mauler | 700 | 0.85 | Slam, rush |
| 2. Beyond the Fence | Fence Runner | 820 | 0.95 | Rush, rush, toss |
| 3. Hollow Porches | Porchcaller | 900 | 1.05 | Summon, toss, slam |
| 4. Scrapwall | Scrapback | 1,000 | 1.15 | Slam, toss, rush; physical attacks against its front are reduced |
| 5. The Last Street | The Breaker | 1,200 | 1.25 | Rush, slam, toss; shorter recovery cadence below half health |

These are the existing proof budgets, preserved deliberately. The future balance package proposes 1,800/1,980/2,160/2,340/3,000 HP; its own index labels those numbers a separately testable proposal. They have not been silently substituted into the playable game. Ordinary enemy families remain Drifter, Rift Runner and Ash Spitter; this slice adds acquisition content rather than unreviewed combat multipliers.

## Complete local equipment pool

Eight new-source families cover all equipment slots. Every newly acquired item starts at Level 1. Level upgrades stop at 5; merging stops at Epic. Existing higher-level/rarity saves and older Ironwatch/Riftweaver ownership are preserved.

| Stable catalog ID | Item | Slot | Common Level 1 budget | Utility/set |
|---|---|---|---|---|
| service_pistol | Service Pistol | Weapon | 40 Power | Automatic basic weapon; Power also scales magic |
| outrider_hood | Outrider Hood | Head | 20 HP, 10 armor | Outrider |
| outrider_vest | Outrider Vest | Chest | 40 HP, 15 armor | Outrider |
| outrider_boots | Outrider Boots | Boots | 10 HP, 5 armor | Outrider |
| beacon_pendant | Beacon Pendant | Pendant | 5 HP | Accessory substats |
| field_medkit | Field Medkit | Gadget | No Power/HP/armor | One automatic 20%-maximum-HP heal; 25% with Infirmary II |
| beacon_ring | Beacon Ring | Ring | 5 HP | Accessory substats |
| outrider_trousers | Outrider Trousers | Pants | 10 HP, 5 armor | Outrider |

Starter total remains 40 Power, 210 HP and 35 armor. Primary stats scale by `(1 + 0.05 x (level - 1)) x rarity`, with Common/Uncommon/Rare/Epic multipliers 1/1.04/1.08/1.12. Rare+ Outrider armor counts toward two pieces (+15% XP pickup reach) and three pieces (+1 secure slot). Affix eligibility and permanent speed/cooldown/pickup caps remain the existing tested rules. No new unimplemented gadget or weapon effect is advertised.

The catalog IDs are authored metadata in `zone_one.gd`; the current version-4 save continues using unchanged names, slots and rarity for merge identity. Introducing IDs into saved inventory is not necessary for this acquisition change and was not done.

## Sources and deterministic recovery route

| Source | Implemented reward boundary |
|---|---|
| New account | Eight Common starter pieces |
| Three ordinary field caches | Existing 25% equipment roll now selects any of the eight local slots; Common/Uncommon 70/30 within the gear result. Otherwise 2-4 Parts. Field Scrap/Credits are additional |
| Outrider's Pack field cache | Guaranteed Uncommon Outrider Boots |
| Captains 1-4 | Existing 35% chance of a local item, Common/Uncommon 70/30 |
| Finale | Guaranteed Uncommon Outrider Vest plus one Breaker Plate on each victory |
| First clear of each mission | One chest key and 10 Gems; Mission 5 gives 40 Gems |
| Supply/targeted chests | Only local families for newly opened chests. Base rarity odds 55/30/13/2% Common/Uncommon/Rare/Epic; shared Rare within 10, Epic within 30 guarantees unchanged |
| Salvage Contracts | After Mission 1, chosen-slot local Common/Uncommon gear; every third completion adds a chest key |
| Ten total mastery medals | One chosen local Rare item; no random-slot requirement |
| Breaker Forge (new) | After Mission 5, chosen local Rare item for 8 Breaker Plates, 330 Credits and 5 Parts |

New crates no longer introduce the future-zone Ironwatch/Riftweaver families. Already-owned pieces remain equippable, mergeable within the existing ceiling, and retain their real set bonuses. The low-level source restriction does not delete or downgrade legacy equipment.

The recipe applies the balance proposal's eight full zone materials, two standard-clear Credit grants and `4 + zone` Parts. Current captains do not drop the proposal's material fragments. Therefore the current guaranteed route is eight finale victories from zero Plates, which also earn 1,984 base Credits and 40 Parts before field loot. This funds the recipe's non-Plate costs without ads, purchases or a circular requirement to equip a crafted item first. The recipe produces ordinary Rare stats and one normal eligible affix, not extra hidden power.

Workshop → Craft exposes all eight recipes, a preview of the actual next item and its affix, owned/required resources, and a second-tap confirmation. Changing the slot clears confirmation. Active expeditions lock crafting. The profile checks the real Mission 5 clear, slot and all three currencies; inventory, identity and spending commit atomically, rolling back on write failure. The preview and cost fit at both tested phone widths.

## Rewards, failure and existing feature coverage

Normal clears grant 165 Credits, 3 Parts, 85 Survivor XP and 45 class Mastery XP. The finale grants rounded 1.5x values: 248/5/128/68. Performance medals remain earned separately: combat requires at most eight damage events without rescue; scavenging requires at least three caches. First-time extra medals each grant 55 Credits. Five/ten/fifteen total medals grant 495 Credits; a Rare choice plus 20 Parts; and the Garage Lantern plus 35 Gems, respectively.

A five-mission first pass with only clear medals grants 1,403 completion/milestone Credits, 17 Parts, 80 Gems, five keys, 468 Survivor XP and 248 Mastery XP before collected run rewards or random boss drops. Higher performance adds rewards but never blocks mission unlocking.

On failure, collected Credits and earned permanent XP remain; only protected backpack loot is banked. Unprotected gear/material bundles are lost. No clear reward, Plate or mission unlock is granted. Three-copy merging, substat upgrades/replacement, saved loadouts, class skill availability, daily objectives, calendar rewards, three facility upgrades, boss practice and contracts already exist and remain in place. The new craft route uses those same inventory and save boundaries.

## Verification

Executed with Godot 4.7.2, using isolated `user://nightfall_*_test.json` saves. No emulator installation, restart, player-save edit, production account change or ad request was made.

| Suite | Checks | Failures |
|---|---:|---:|
| `tests/zone_one_test.gd` (new) | 69 | 0 |
| `tests/equipment_workshop_test.gd` (updated source-pool expectation) | 81 | 0 |
| `tests/loot_test.gd` | 140 | 0 |
| `tests/profile_test.gd` | 39 | 0 |
| `tests/field_test.gd` | 33 | 0 |
| `tests/expedition_test.gd` | 17 | 0 |
| `tests/salvage_test.gd` | 33 | 0 |
| Total focused checks | 412 | 0 |

The new test checks the eight-family catalog, four chest categories across 1,024 seeded rolls, all-slot field acquisition across 512 seeds, all five authored boss arrivals, clear-only progression, eight earned Plates, chosen-slot Rare budgets, exact spending, each insufficient currency, repeat rejection, save/reload, failed-write rollback, expedition locks, legacy equipping, actual UI confirmation and phone layout. It simulates result transitions to test transactions; it is not a human full-combat playthrough.

Six rendered fixture screens were inspected at 430x760 and 320x568 requested sizes: locked, funded and confirmation. An initial recipe layout clipped the bottom of its cost card inside the scroll area; the selector was changed to four columns/two rows. The final funded and confirmation captures show the item, affix, all resource costs and action buttons together. Captures are under ignored `artifacts/nightfall-godot/zone-craft-*.png`; parent integration may preserve selected images with the visual evidence package.

Standalone command:

```powershell
& "$env:LOCALAPPDATA/NightfallTools/Godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe" --headless --path apps/nightfall-godot --script tests/zone_one_test.gd --quit-after 1800
```

### Final integration verification

The new suite is registered in `scripts/nightfall-godot.ps1`. The full `-Action Test` run completed **24 suites, 6,666 checks, zero failures and zero script errors**, with exit code 0. Several GUI suites still print an exit-only warning about two ObjectDB instances; this warning is recorded rather than treated as proof of a clean resource-lifetime audit.

The complete disposable menu catalog produced **85 captures with zero geometry failures**, covering both phone widths and the new locked/funded/confirmation crafting states. Its overflow check now ignores the hidden home menu when capturing combat modals. Active-expedition mission presentation reduces only the island stage from 194 to 138 pixels, preserving the taller action buttons and fitting both Resume and End controls. Its art and particle overlay use the same fitted rectangle. Gear's malformed equipped-marker text is replaced by the explicit Unicode escape `\u25C6`; ambiguous Roman rank strokes now show rarity initials C/U/R/E/L/M. Updated Gear, mission-resume and victory-modal images were inspected after rendering.

Full logs: ignored `artifacts/nightfall-godot/zone-one-full-test.log` and `zone-one-menu-catalog.log`. Screens: `artifacts/nightfall-godot/zone-one-menu-catalog/`. This verification does not install a new Android build or change the user's emulator save.

## Remaining acceptance gaps

Human combat feel, measured win rates, real-phone performance and sustained difficulty across all five missions remain unproven here. The new Rare route is numerically bounded and transaction-tested; the eight-clear investment is a provisional design value, not a verified ideal grind length. Paid billing, production ad mediation, full directional animation, future zone content and the parent's selected visual redesign are outside this functional slice. The Garage Lantern is an owned cosmetic record; placement as an interactive base decoration is still future work. No claim of a production-complete Zone 1 is made from these tests alone.
