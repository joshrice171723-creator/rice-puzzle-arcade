# Nightfall progression features — October 18, 2026

## Scope and user decisions

Continue features while deferring the full visual overhaul. Joshua added permanent class skill trees, merging duplicate equipment, separately configurable substats and set bonuses during this delivery. A dedicated subagent maintains the companion [equipment balance ledger](EQUIPMENT_BALANCE_LEDGER.md). Its source-based calculations are not a substitute for player balance testing.

## Implemented behavior

### Class skill trees

- Class > Skill tree shows a connected permanent tree for the inspected class, including locked class previews. Scavenger and Engineer remain the playable classes under existing campaign unlock rules.
- Three starter spells per class; five unlock nodes in two prerequisite branches followed by a shared capstone. Costs are 1, 1, 2, 2 and 3 points. Earn one permanent point per class mastery level through level 9. Previously earned mastery counts. Spending a point does not subtract mastery XP or disable existing mastery talents.
- Scavenger starters: Ember Bolt, Frost Ring, Chain Spark. Engineer: Ember Bolt, Chain Spark, Orbiting Wisp. Warden preview: Frost Ring, Stone Lance, Consecrated Ground. Arcanist preview: Ember Bolt, Frost Ring, Orbiting Wisp.
- Permanent unlocks expand that class's campaign and contract level-up pool. They do not grant an equipped spell at mission start. New runs still begin without learned spells; spell rank, specialization and evolution remain run-local.
- Level 2 offers three available spells; later drafts offer only unlocked new spells, existing spell upgrades, existing passive choices and eligible healing. The three-spell/three-passive limits remain unchanged.
- Checkpoints preserve the draft pool, random generator state and pending offers. Pre-tree checkpoints retain their old eight-spell availability for that saved expedition. Unlocking skills while an expedition is active is blocked.
- Boss training remains a reward-free sandbox with its existing prescribed three-spell kits; it can preview abilities outside the campaign unlock pool. It never grants permanent unlocks.

### Equipment collection and builds

- Three named build slots save the class and all eight equipped item IDs. Applying restores the whole selection atomically. Upgrading a referenced item improves every build using that item; builds do not duplicate gear or freeze its statistics.
- Explicit item locks and build membership prevent salvage. A saved expedition blocks build changes, locking, crafting and skill purchases.
- Inventory filters combine slot, rarity and explicit locked state. Sorting remains available; the inventory remains five columns with vertical scrolling. Empty-filter state is explicit.
- Replacing or clearing a saved build requires a second tap. Clearing a build does not delete items.

### Three-copy merging

- Choose an item and two donor copies of the same name, equipment slot and rarity. Substats, substat ranks and item levels may differ.
- The selected item keeps its ID, name, set, substats, substat ranks, equipped/build references and explicit lock. Its item level becomes the highest of all three. Newly available substat slots receive eligible distinct substats.
- Exactly two donor items are removed; rarity advances one step. No credits, Parts or gems are charged. Consumed donors' substats are not transferred.
- Equipped, explicitly locked or saved-build donor items cannot be selected or consumed. Duplicate donor IDs, the target itself, mismatched copies and replayed consumed IDs are rejected in the profile layer as well as the UI.
- Current campaign ceiling is Epic: Common → Uncommon → Rare → Epic. Repeated merging cannot manufacture Legendary/Mythic gear in the first playable zone. Existing higher-tier records remain readable; their later acquisition gates are still future content.
- This replaces the old credits-and-Parts rarity promotion action. Item-level upgrades remain separate and currently cap at level 5.

### Substats

- Individual substats have ranks 1–3, scaling their existing base effect by 1×, 1.5× and 2×. Upgrade costs: rank 1→2 costs 50 credits + 3 Parts; rank 2→3 costs 100 credits + 6 Parts.
- Reroll costs 100 credits + 5 Parts. It changes only the selected substat, preserving its rank. Each compatible alternative not already present on the item has equal selection probability; no duplicate substats or same-stat rerolls. A second tap confirms spending.
- New substats and old implicit rank-1 records use the same calculation path. Item-level growth and rarity still affect the base item stats before applicable percentage substats.
- Permanent movement multiplier is capped at 1.15, permanent spell cooldown reduction at 15%, and permanent pickup multiplier at 1.50. The existing combined run movement and cooldown caps remain 30%. Pickup cap includes class, equipment and Outrider bonuses; temporary run effects are separate.

### Equipment sets

All sets use Head, Chest, Boots and Pants. Rare or better equipped pieces qualify; two- and three-piece bonuses apply once each and can both be active.

| Set | Two pieces | Three pieces |
|---|---|---|
| Outrider | +15% XP pickup reach | +1 protected loot slot |
| Ironwatch | +12 armor | +6% maximum HP |
| Riftweaver | +3% spell damage | +4% spell cooldown reduction |

Armor results from supply/armor chests choose among the three sets with equal probability. Existing rarity odds and guarantees are unchanged. Existing field/contract/choice generation retains the Outrider pool. Gear > Sets shows qualifying piece counts and active bonuses. Substats do not alter set identity. The selected item can be locked and merged upward because it is retained; only donor consumption is prohibited by a lock.

## Save integrity

Profile version 3 adds build slots, explicit item locks, per-class skill ownership and a substat reroll counter. Version 1/2 migration preserves existing item IDs, wallet, upgrade levels, mastery, claimed rewards and active expedition checkpoints. No real player profile is used by automated fixtures.

Profile mutations use existing write/backup/rollback transactions. Failed merge restores both donors and target; failed reroll restores currency, stat and RNG counter; failed skill purchase restores ownership and available points. Validation rejects missing saved-build references, invalid substat ranks, duplicate/invalid tree nodes, missing prerequisites and overspent points.

## Verification

Command: `./scripts/nightfall-godot.ps1 -Action Test`.

- Full suite: **20 suites, 5,741 checks, zero failures**.
- New progression suite: 3,142 checks. Most assertions sweep seeded level-up drafts to verify no locked abilities or duplicate choices; they are not thousands of human play sessions.
- New equipment workshop suite: 83 checks covering three-copy conservation, mismatches, protection, level/substat preservation, exact costs, reroll isolation, rollback/restart, set effects in actual run statistics, chest set distribution, progression ceiling and UI journeys. Riftweaver spell damage is separately checkpointed and does not increase structure Power.
- Existing combat, spells, specializations, field systems, defenses, reward flow, contracts, mastery and expedition integration pass.
- Phone layout checks at 320×568, 390×844 and 430×760 cover Gear, filters, saved builds, class trees including locked class previews, merge selection, substat tuning, set summaries and item details through the supported rarity presentation range.
- Known ObjectDB exit warnings remain part of the previously deferred cleanup; they did not produce failed assertions. These checks do not establish final artwork acceptance, frame-rate performance or real-player difficulty balance.

Local test log: `artifacts/nightfall-godot/progression-features-tests.log`. Android export/install evidence is appended after packaging.

### Android package and menu check

- Android export completed using the existing Godot/Gradle pipeline. APK: `artifacts/nightfall-godot/nightfall-proof.apk`; SHA256 `FFBC1B6B28D269ABCF965FD7832049AD01F32227BBA1D86D63004F2E9518FEE1`.
- Replacement installation succeeded on `emulator-5554` without clearing application data. One transient offline ADB response was resolved by checking the device and retrying installation.
- Launched the installed application and used native touch to open Class > Skill tree. The tree, description, action row and all five navigation tabs fit the emulator display; snapshot `artifacts/nightfall-godot/progression-native-skills.png`.
- Before/after installed-profile comparison confirms identical inventory, wallet, supply keys and active Mission 1 checkpoint. The existing expedition was not abandoned, replayed or modified to provide test currency. Purchases/unlocks remain correctly blocked during that saved expedition.
- Native log inspection found the existing shader-cache recompilation warning but no observed script error or Android runtime crash in this menu check. It does not validate prolonged gameplay performance, a physical handset, or new real-ad delivery.

## Next balance and content work

- Use the equipment ledger before changing rewards, item stats, unlock gates or zone budgets.
- Measure survivability, damage, XP acquisition and attempts-to-clear with minimum/typical/strong earned builds before scaling content. Numerical bounds and seeded drafts do not prove that the game is fun or sufficiently challenging.
- Keep Legendary/Mythic creation unavailable until the planned campaign/component gates and corresponding enemy budgets exist.
- Later zones, Warden/Arcanist campaign unlocks, additional item identities and production purchases remain separate milestones.
