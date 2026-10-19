# Nightfall equipment and balance ledger

Owner: dedicated equipment/balance workstream. Updated October 18, 2026.

For the authored twenty-zone expansion, use the [campaign balance design package](balance-design/DESIGN_INDEX.md). Its future numbers and acquisition gates are proposals, not replacements for the implemented baseline recorded here. The current profile is version 4 following the daily-reward migration.

This is the item catalog and balancing reference for the feature build. It distinguishes values actually present in source from the larger campaign design. Numerical comparisons below are calculated from source formulas, not evidence of player difficulty or measured win rates. The campaign currently contains only the five Blackout Outskirts missions. Later-zone rewards are design commitments, not obtainable content.

## 1. Source of truth and maintenance

| Concern | Source and symbols |
|---|---|
| Slots, item families, base stats, rarity, affixes and sets | `apps/nightfall-godot/haven_content.gd`: `SLOTS`, `STARTER_NAMES`, `BASE_STATS`, `RARITIES`, `RARITY_SCALE`, `AFFIXES`, `SETS`, `item_stats`, `affix_value` |
| Random item generation and crate odds | `apps/nightfall-godot/loot.gd`: `CATEGORIES`, `equipment`, `affixes`, `roll` |
| Ownership, upgrades, merging, tuning, equipment eligibility | `apps/nightfall-godot/profile.gd`: `fresh`, `valid`, `upgrade_cost`, `merge_candidates`, `merge_items`, `upgrade_substat`, `reroll_substat`, `equip`, `stats` |
| Campaign, contracts, first clears and mastery rewards | `profile.gd`: `finish_attempt`, `claim_rare_choice`; `haven_content.gd`: `clear_rewards`; `salvage.gd`: `REWARDS`, `unlocked` |
| Field cache contents and secure stash | `apps/nightfall-godot/field.gd`: `open_cache`, `banked_loot`, `health_multiplier`, `damage_multiplier`, `pickup_multiplier` |
| Actual combat application and caps | `apps/nightfall-godot/run.gd`: `configure`, `max_health`, `spell_cooldown`, `hurt`, movement and XP collection |
| Permanent class ability availability | `apps/nightfall-godot/skill_tree.gd`: `STARTERS`, `BRANCHES`, `COSTS`, `POINT_CAP`; `profile.gd`: `ability_pool` |
| Player-facing merge, tuning and set inspection | `apps/nightfall-godot/equipment_workshop_ui.gd`, `armory_ui.gd`, `skill_tree_ui.gd` |
| Campaign intentions and unreleased items | `docs/nightfall/NIGHTFALL_MAIN_PLAN.md`: equipment, sets, twenty zones and cache sections |

When adding an item, update this ledger in the same change as its source and tests. Required record: stable family identity, display name, slot, level-1 budget, utility, eligible substats, rarity ceiling, acquisition source, earliest campaign access, equip restriction, upgrade costs and caps, set membership, class/skill interactions, and validation evidence. A UI name or concept illustration does not count as implemented behavior. Changes to level/rarity access must be enforced at generation and mutation entry points, not solely by hiding buttons.

## 2. Progression vocabulary

* **Survivor level:** permanent level from Survivor XP; starts at 1, caps at 40. Each next level costs `current level × 120 XP`. Adds 4 base HP per level after the first. This currently does not gate equipping items.
* **Equipment level:** independent item investment; generated equipment starts at level 1. The current upgrade action stops at level 5. The save validator permits levels 1–30 for compatibility; that does not mean the upgrade action can reach 30.
* **Rarity:** Common, Uncommon, Rare, Epic, Legendary, Mythic. Modifies primary stats and substat capacity; it does not change item identity.
* **Substat rank:** 1–3 on each affix owned by a particular item. It survives tuning and the selected base item's merge.
* **Class mastery:** permanent, per-class XP; spends separate skill-tree availability points. Combat XP and temporary spell ranks reset with each expedition.
* **Campaign access:** the highest mission unlocked through boss victories. Current playable range is Zone 1, Missions 1–5; do not call higher zones unlocked.

Items with the same slot, family name and rarity remain merge-compatible when levels, affix names, affix ranks or rolled substats differ. The selected item's substats must be visible before committing; the two donor items are consumed. Display names presently serve as identity in source. A future rename/localization should introduce stable family IDs before changing those names.

## 3. Current complete item-family catalog

Eight local families below are newly obtainable in Zone 1. The other eight remain recognized by `Loot.equipment` for legacy ownership and future content; fresh Outskirts crates no longer award them. Every item starts at equipment level 1. **There is no survivor-level requirement to equip any currently owned item.** No class currently restricts an equipment slot. For ordinary gear, names within a slot do not supply extra primary stats; the slot budget, rarity, level and affixes do.

| Item | Slot | Level-1 Common primary stats | Set | Current acquisition and earliest access |
|---|---|---|---|---|
| Service Pistol | Weapon | 40 Power | None | Starter; field caches; boss drop; targeted Weapon contract after Mission 1; Weapons/Supply crate after obtaining a key |
| Outrider Hood | Head | 20 HP, 10 armor | Outrider | Starter; armor/supply crates; head contract; boss drops; Rare choice |
| Outrider Vest | Chest | 40 HP, 15 armor | Outrider | Starter; armor/supply crates; chest contract; boss drops; guaranteed Uncommon chest on Mission 5 victory; Rare choice |
| Outrider Boots | Boots | 10 HP, 5 armor | Outrider | Starter; guaranteed Uncommon from Outrider's Pack field cache; armor/supply crates; boots contract; boss drops; Rare choice |
| Outrider Trousers | Pants | 10 HP, 5 armor | Outrider | Starter; armor/supply crates; pants contract; boss drops; Rare choice |
| Ironwatch Helm | Head | 20 HP, 10 armor | Ironwatch | Legacy owned items preserved; no new Zone 1 source. Future Zone 2 family |
| Ironwatch Cuirass | Chest | 40 HP, 15 armor | Ironwatch | Legacy owned items preserved; no new Zone 1 source. Future Zone 2 family |
| Ironwatch Boots | Boots | 10 HP, 5 armor | Ironwatch | Legacy owned items preserved; no new Zone 1 source. Future Zone 2 family |
| Ironwatch Greaves | Pants | 10 HP, 5 armor | Ironwatch | Legacy owned items preserved; no new Zone 1 source. Future Zone 2 family |
| Riftweaver Cowl | Head | 20 HP, 10 armor | Riftweaver | Legacy owned items preserved; no new Zone 1 source. Future Zone 3 family |
| Riftweaver Robe | Chest | 40 HP, 15 armor | Riftweaver | Legacy owned items preserved; no new Zone 1 source. Future Zone 3 family |
| Riftweaver Boots | Boots | 10 HP, 5 armor | Riftweaver | Legacy owned items preserved; no new Zone 1 source. Future Zone 3 family |
| Riftweaver Leggings | Pants | 10 HP, 5 armor | Riftweaver | Legacy owned items preserved; no new Zone 1 source. Future Zone 3 family |
| Beacon Pendant | Pendant (`charm`) | 5 HP | None | Starter; Supply/Engineer's crate; pendant contract; boss drop; Rare choice |
| Beacon Ring | Ring | 5 HP | None | Starter; Supply/Engineer's crate; ring contract; boss drop; Rare choice |
| Field Medkit | Gadget | No primary stats | None | Starter; Supply/Engineer's crate; gadget contract; boss drop; Rare choice. Run restores 20% max HP once when a nonlethal hit leaves HP at or below 25%; Infirmary II increases to 25% |

For the table, “contract” means a chosen-slot Salvage Contract, unlocked after clearing Mission 1. A crate can be opened before any campaign clear if the player earns a shop video key. Boss drops, Rare choices, new random crates and the Breaker Forge use the local Outrider family for armor. Ordinary field-cache equipment rolls can now produce all eight local families; the named Outrider Pack still guarantees Uncommon boots. Existing Ironwatch/Riftweaver gear remains owned and equippable. There are no implemented weapon-specific animations/damage profiles beyond Service Pistol yet.

**Starter total:** character base 120 HP + equipment 90 HP = **210 HP**, **40 Power**, **35 armor**. Pendant and Ring split the original charm budget; Chest and Pants split the original chest budget. Adding the new slots did not simply add extra starting power.

**Medkit integration boundary:** the current run receives a `medkit` fraction from profile stats; it does not dispatch different utility based on gadget identity. This is sufficient while Field Medkit is the only gadget. Adding a second gadget requires an actual equipped-gadget utility switch. Rarity and item levels currently do not strengthen Medkit's heal fraction, so an otherwise empty Common Medkit should not appear to promise a healing upgrade on promotion.

## 4. Primary-stat budgets and rarity

`primary = slot base × [1 + 0.05 × (equipment level − 1)] × rarity scale`

An applicable Power/HP/armor affix then multiplies that item's matching primary stat. It is not a percentage of the entire character's total.

| Rarity | Primary multiplier | Maximum affixes | Level-1 pistol Power | Level-5 pistol Power before affixes |
|---|---:|---:|---:|---:|
| Common | 1.00 | 0 | 40.00 | 48.00 |
| Uncommon | 1.04 | 1 | 41.60 | 49.92 |
| Rare | 1.08 | 1 | 43.20 | 51.84 |
| Epic | 1.12 | 2 | 44.80 | 53.76 |
| Legendary | 1.16 | 3 | 46.40 | 55.68 |
| Mythic | 1.20 | 3 | 48.00 | 57.60 |

These small primary increments intentionally leave room for the additional substats. Mythic's planned selectable signature is **not implemented** and must not be counted in current budgets. Newly generated items have their full normal affix allocation. Legacy owned items may have fewer affixes, which the validator currently accepts.

### Equipment investment

| Upgrade | Credits, Workshop I | Parts | Credits, Workshop II |
|---|---:|---:|---:|
| Level 1 → 2 | 40 | 2 | 36 |
| Level 2 → 3 | 80 | 3 | 72 |
| Level 3 → 4 | 120 | 4 | 108 |
| Level 4 → 5 | 160 | 5 | 144 |
| Total 1 → 5 per item | 400 | 14 | 360 |

Workshop II costs 400 Credits and 12 Parts. At eight slots, maxing the entire loadout costs 3,200 Credits and 112 Parts before the Workshop discount. Level upgrades are deterministic. Salvage yields `2 + rarity index + equipment level − 1` Parts, not a refund of all investment. Donor level investment is preserved as the highest of the three merged item levels; donor tuning investment is consumed. There is currently no 80% investment-transfer feature despite its appearance in the main design plan.

### Merge ladder

The requested rule is three identical-family, same-rarity items becoming one item of the next rarity. Differing substats are allowed. The selected base preserves ID, substats and their ranks; new affix capacity is filled; its level becomes the highest input level. Donors must be unequipped, unlocked and absent from saved builds. Active expeditions block equipment mutations.

| Result from Rare starting copies | Identical Rare copies consumed in a pure ladder | Balance interpretation |
|---|---:|---|
| Epic | 3 | Useful sink for random chest duplicates |
| Legendary | 9 | Should require a future campaign/material gate before availability |
| Mythic | 27 | Should require endgame access and an earned component before availability |

**Implemented ceiling:** the current five-mission build only permits Common → Uncommon → Rare → Epic merging. Epic cannot be promoted further through this action. Legendary/Mythic rows quantify a future ladder if those tiers are enabled; they are not available promotions now. Already-owned higher-rarity items remain valid and are preserved. Future access still needs explicit campaign/material rules when those zones exist.

## 5. Substats: current values and tuning

| Affix | Eligible slots | Rank 1 | Rank 2 | Rank 3 | Application |
|---|---|---:|---:|---:|---|
| Tempered | Weapon | +3% | +4.5% | +6% | This item's Power |
| Reinforced | Head, Chest, Boots, Pendant, Ring, Pants | +4% | +6% | +8% | This item's HP |
| Plated | Head, Chest, Boots, Pants | +4% | +6% | +8% | This item's armor |
| Attuned | All eight | 2% | 3% | 4% | Additive permanent spell cooldown reduction; profile aggregate capped at 15% |
| Seeking | All eight | +5% | +7.5% | +10% | Additive permanent XP pickup reach |
| Lightweight | All eight | +1% | +1.5% | +2% | Additive permanent movement multiplier; profile maximum 1.15 |

No duplicate affix appears on a single generated item. There is no random strength roll within a rank yet: variability is which eligible affix is present. Rank defaults to 1 when absent from the save.

* Rank 1 → 2: 50 Credits + 3 Parts.
* Rank 2 → 3: 100 Credits + 6 Parts.
* Tuning/replacing one chosen affix: 100 Credits + 5 Parts; selects another eligible affix absent from the item. Its rank is preserved. An item with no eligible alternative cannot tune.
* Reroll stream advances independently of combat generation; restarting should not rewind a committed result.
* Merging keeps the chosen base's tuned affixes. Different donor affixes do not disqualify a match and do not combine into an oversized affix list.

The budget must consider **aggregate** bonuses. Eight rank-3 Attuned affixes total 32% raw, then hit the 15% equipment cap. Eight rank-3 Lightweight affixes total 16%; Scavenger's starting 5% consumes part of the same 15% profile allowance. Seeking, class pickup and Outrider's pickup bonus share a permanent multiplier cap of 1.50. This creates low-value rolls near the caps; UI comparisons should show effective changes rather than encouraging wasted investment.

## 6. Set bonuses and compatibility

Only **equipped Rare-or-higher** pieces count. Same set name at Common/Uncommon is cosmetic membership without active piece credit. Each family has four slots; four pieces retain the same two/three-piece bonuses and add no fourth threshold.

| Set | Named pieces | Two-piece | Three-piece | Current access |
|---|---|---|---|---|
| Outrider | Hood, Vest, Boots, Trousers | +15% XP pickup reach | +1 protected loot slot | Starter family, but Rare pieces must be earned/merged; all regular armor reward channels |
| Ironwatch | Helm, Cuirass, Boots, Greaves | +12 armor | +6% maximum HP | Random armor/supply crates immediately; campaign's intended Zone 2 family |
| Riftweaver | Cowl, Robe, Boots, Leggings | +3% spell damage | +4% permanent spell cooldown reduction | Random armor/supply crates immediately; new source-defined set without a final future-zone assignment |

Two sets at two pieces each can coexist in the four armor slots. Three pieces from one set cannot simultaneously supply two pieces from another. Neither pendant nor ring supplies a set count. Substat changes never change family/set identity. Rarity merging preserves the family.

Ironwatch HP applies after survivor HP and all equipped item HP are summed. Riftweaver cooldown shares the 15% permanent cap with Attuned. Outrider protects one more bag item, not an entire cache's contents. Current Storehouse II increases capacity from eight to nine but does not independently increase secure slots.

The main plan's old Ironwatch three-piece shield proc is a different proposal; this first implementation uses +6% HP. Do not apply both. Its older three-slot armor wording is superseded by four armor slots, including Pants.

## 7. Acquisition/access ledger

### Repeatable and guaranteed sources

| Source | Earliest access | Item level | Rarity/family | Limits and meaning |
|---|---|---:|---|---|
| Initial equipment | New profile, Survivor 1 | 1 | Common, exact eight starter names | One per slot; no affixes |
| Outrider's Pack field cache | First expedition | 1 on banking | Guaranteed Uncommon Outrider Boots | Once per run; must bank victory loot or protect the item on defeat |
| Other three field caches | First expedition | 1 | Each 25% pistol, else 2–4 Parts; pistol 70% Common/30% Uncommon | Cache reward rolls once on collection; no Rare/Epic field equipment |
| Mission 1–4 boss victory | That mission unlocked | 1 | 35% one item; within that 70% Common/30% Uncommon; uniform slot; armor Outrider | Repeatable; unconditional per-clear equipment probabilities 24.5% Common/10.5% Uncommon |
| Mission 5 boss victory | Clear Missions 1–4 | 1 | Guaranteed Uncommon Outrider Vest | Also earns one Breaker Plate; no existing recipe consumes it |
| Chosen-slot Salvage Contract | Clear Mission 1 | 1 | Guaranteed selected slot, 75% Common/25% Uncommon; armor Outrider | Opens three caches, beacon ready after 90 seconds, charge 3 seconds; max duration 180 seconds |
| Contract key milestone | Three successful contracts | N/A | One equipment-cache key per three victories | Repeatable, no daily cap |
| First campaign clears | First victory for each mission | N/A | One key per first clear | Five keys across implemented campaign |
| Ten Outskirts medals | Ten unique mission medals | 1 | One selected-slot Rare item, armor Outrider | One choice token; not repeatable per clear |
| Optional shop video | New profile | N/A | One key per earned video | Maximum two per UTC day; a closed/failed/unearned video grants no key |
| Gem purchase | Wallet has 25 Gems | N/A | One key | Current first-clear total 80 Gems, plus 35 for fifteen medals; no real-money billing implemented |

All generated gear is independent of survivor level. There is no current drop-level scaling, item minimum-equip level or class-specific chest weighting. Quest/campaign progress gates access to a source, not the equipment itself once owned.

**Crates:** Supply Crate includes all eight slots; Weapons Cache only Weapon; Armor Locker Head/Chest/Boots/Pants; Engineer's Case Pendant/Gadget/Ring. Category slots are uniformly chosen. An armor result uniformly chooses Outrider, Ironwatch or Riftweaver. The category name Engineer's Case does not require the Engineer class.

**Current shared crate odds:** Common 55%, Uncommon 30%, Rare 13%, Epic 2%, Legendary 0%, Mythic 0%. Rare-or-better guaranteed within ten openings; Epic guaranteed within thirty. Rare miss counter resets on Rare or better; Epic miss counter resets on Epic. Counters are profile-wide across all four categories. Epic pity takes precedence. Guarantees do not guarantee a particular family/slot or set completion.

Thirty keys take at least fifteen UTC earning days from shop videos alone, absent first-clear/contract keys and any day-boundary effects. Contracts are uncapped, so this is not an overall minimum time-to-Epic. A player can earn an Epic before clearing Mission 1 through a lucky shop-key crate: that is a current intended possibility to test, not proof of an overpowered outcome.

**Non-equipment resources:** Credits pay item upgrades, tuning and facilities; Parts pay upgrades/tuning/facilities and come from field caches/salvage. Gems buy keys. Field Scrap buys shrine traits and structures during the run; it is not the persistent Credits wallet. Breaker Plates are recorded but currently have no crafting consumer. Protected loot is banked on defeat; unprotected items are lost. Base rewards are added only once per committed attempt; a replay of the same result must not duplicate loot.

## 8. Class, magic and temporary-build interactions

Scavenger is available immediately; Engineer requires Mission 4 clear. Warden (Zone 2) and Arcanist (Zone 3 Mission 3) remain locked future content. The eight equipment slots are shared across classes. A high-mastery class does not automatically unlock every spell on another class.

Permanent skill trees determine which spells may appear in random level-up offers. Starter pools: Scavenger Ember Bolt/Frost Ring/Chain Spark; Engineer Ember Bolt/Chain Spark/Orbiting Wisp; Warden Frost Ring/Stone Lance/Consecrated Ground; Arcanist Ember Bolt/Frost Ring/Orbiting Wisp. Five unlock nodes per class cost 1/1/2/2/3 mastery points, total nine. Permanent unlocks expand availability; spell ranks, specialization and evolution still must be earned within the expedition. They are not equipped item stats and do not persist as run ranks.

Actual interactions to include in balance simulations:

* Basic pistol starts at `0.6 × equipped Power` every 0.6 seconds. Permanent weapon growth also scales spells and placed defenses through `spell_multiplier`, making weapon Power unusually broad in value.
* Riftweaver's +3% is a separate `equipment_spell_bonus` applied by `Run.spell_scale`; `spell_multiplier` remains raw equipped Power divided by40. Placed defenses receive that raw Power scaling and do not inherit the spell-only set bonus. The optional checkpoint field defaults to0 for legacy checkpoints, preserving their existing run state. Verify spell damage rises3% while an otherwise identical turret/trap remains unchanged.
* Permanent cooldown reduction caps at 15%; Efficient Channel contributes 6% per temporary rank, with total spell cooldown reduction capped at 30%.
* Profile movement caps at 1.15; Fleet Foot multiplies it within the run, capped at 1.30 before Obsidian Heart's 5% penalty.
* Max HP is profile HP multiplied by `1 + 0.10 × Vitality rank + 0.12 if Moonstone + 0.08 × Vital Reserve rank`. At three ranks each and Moonstone this is 1.66× profile HP. Percentage healing and shields scale with that resulting maximum.
* Armor reduction is `min(50%, armor / (armor + 150))`; other applicable reductions multiply it, with overall reduction capped at 65%. Starter 35 armor reduces damage 18.92%, not 35%.
* Scavenger starts at 1.15 pickup multiplier. Seeking and Outrider's two-piece bonus share the permanent 1.50 cap. Long Reach III (1.75×), Magnetic Harness III and evolved Wisp (1.80×) can produce **4.725×** the base 70-unit collection radius, or **330.75 units**, without Cinder Lens. The initial uncapped proposal would have reached 463.05 units; the cap reduces that risk. Temporary collection growth still deserves a game-feel/performance review.

## 9. Early-zone risk register and conservative bounds

| Risk | Source-grounded magnitude | Recommended decision / verification |
|---|---|---|
| High-rarity access | Epic merge ceiling is now enforced; Legendary/Mythic existing ownership remains accepted | Future tiers need explicit campaign/material gates before new generation or promotion paths are enabled |
| Early lucky Epic | Level-1 Epic pistol 44.8 Power, +12% over starter before up to two affixes | Keep the excitement but test first-mission boss/survival with this loadout; rarity alone must not auto-clear mechanics |
| Maximum normal Zone 1 weapon investment | Level-5 Epic pistol with rank-3 Tempered = 56.9856 Power, +42.464% versus starter. A preserved legacy/hypothetical Mythic equivalent would be 61.056, +52.64% | Avoid treating +12% rarity as whole-loadout power; item level and affix ranks compound it |
| Defensive compounding | All slots level-5 Epic before affixes:240.96 HP at Survivor1 versus210; armor47.04 versus35; Ironwatch addsHP/armor beyond this | Test full builds, survivor HP, temporaryHP and percent healing together; no artificial forced loss counter |
| Historical save ceiling wider than upgrade ceiling | Validator accepts level30; normal upgrade function stops5 | Preserve valid legacy data but make live upgrade/generation ceilings explicit; do not infer normal level30 access from validator |
| Armor sets ignore planned geography | Ironwatch and Riftweaver can drop in first crate | Decide introductory broad-family crates versus zone-unlocked family pools; make the selected rule consistent in UI, generation and this ledger |
| Unlimited farming/currency-to-key conversion | Contracts repeatedly award keys; rewards are not daily limited | Do not claim an exact number of days to power. Simulate key, material and affix growth across free farming and rewarded-video routes |
| Stat saturation reduces useful loot | Attuned/Lightweight can exceed their aggregate caps | Show effective deltas and support tuning; avoid raising caps solely to justify surplus rolls |
| Generic gadget scaling | Medkit primary stats zero; rarity/level do not improve its utility | Give utility comparison text; design separate bounded progression before adding other gadgets |
| Endgame effects absent | No Mythic signature, Legendary recipe or later-zone scaling exists | Do not balance unavailable effects as though implemented; all later-tier numbers below remain planning |

Proposed future equipment-level limit from the main plan is `min(30, 4 + highest unlocked zone + floor(zone/3))`: Zone1=5, Zone2=6, Zone3=8, Zone5=10, Zone10=17, Zone15=24, Zone20=30. This formula is **not currently wired to campaign progress**; only a constant upgrade ceiling5 exists. The formula must use highest legitimately unlocked zone, not selected preview zone or current replay zone.

Suggested equip access for future content: use a family/source unlock and a campaign-based item-level ceiling rather than inventing survivor-level requirements that current XP progression has not validated. There is no approved table mapping Survivor level to every future weapon. Mark those fields TBD until campaign XP/reward pace is simulated. Do not sell or reward locked high-level power that bypasses the same gates applied to earned gear.

## 10. Planned equipment roster, separate from implementation

All entries in this section are unreleased designs unless also listed in the current catalog. Equipment level starts at 1 unless a future drop-level system explicitly changes it. Stated zone is intended earliest campaign source, not an implemented equip restriction. Required survivor level is **TBD / no runtime rule** for every planned family.

### Named weapons

All have planned base40 Power; firing patterns are additional behavior, not extra permanent Power.

| Weapon | Planned base basic attack | Earliest planned source | Implementation |
|---|---|---|---|
| Service Pistol | 24 every0.60s | Starter/Zone1 | Implemented |
| Hunting Rifle | 72 every1.80s | Zone2 | Planned |
| Ember Staff | 32 impact +8 burn every1.00s | Zone3 | Planned |
| Pump Shotgun | Five14-damage pellets every1.75s | Zone4 | Planned; all pellets hitting one enemy would total40 raw DPS versus40 pistol, before accuracy |
| Runeblade | 40 every1.00s, up to3 targets | Zone6 | Planned; multi-target coverage must not be counted as single-target DPS |
| Salvage Repeater | 10 every0.25s | Zone7 | Planned |
| Frost Bow | 48 every1.20s | Zone8 | Planned; chill duration/boss resistance TBD |
| Storm Scepter | 28 primary +12 secondary every1.00s | Zone9 | Planned; secondary-target availability matters |

### Charms and gadgets

| Family | Earliest planned source | Planned purpose / bounded effect |
|---|---|---|
| Beacon Pendant | Starter; Zone3 pool | General survival; current5HP base |
| Beacon Ring | Starter | Current5HP base; no separate future signature approved |
| Hunter's Sigil | Zone2 | Precision/critical build; exact crit values TBD |
| Ember Locket | Zone5 | Fire build; exact modifier TBD |
| Wayfinder Coin | Zone6 | Collection/CombatXP; exact modifier TBD |
| Clockwork Seal | Zone9 | Gadgets/cooldown; shares global cooldown budget |
| Hollow Prism | Zone19 | Elemental combinations; exact trigger and cap TBD |
| Field Medkit | Starter; Zone12 reward pool | Current once/run20% maxHP at≤25%HP; InfirmaryII25% |
| Survey Lantern | Zone3 | Reveals containers/hidden enemies; detection radius TBD |
| Repair Drone | Zone4 | Slow structure repair outside nearby combat; rate and combat lockout TBD |
| Shock Mine Kit | Zone7 | Periodically leaves mine on Dodge; damage/internal cooldown TBD |
| Ward Projector | Zone10 materials; Zone16 item reward | Shield10% maxHP on boss arrival; once per arrival, no extraction trigger |
| Decoy Beacon | No zone assigned | Once/run distract ordinary enemies at lowHP; boss immunity; threshold/duration TBD |

The unassigned Decoy, Riftweaver distribution and future ring families require a source decision. Their existence in a document must not silently add them to a starter crate.

### Planned sets and effect budgets

Four armor slots must share the same per-slot primary budgets across families. New family names/pants art should be approved with content, not fabricated as shipped equipment. Each set needs four concrete family IDs before implementation.

| Set | Intended first zone | Two-piece design | Three-piece design | Current status |
|---|---:|---|---|---|
| Outrider |1| +15% pickup | +1 secure slot | Implemented at Rare+ |
| Ironwatch |2| +12armor | Main-plan shield-on-Dodge/Aegis with12s cooldown | Implemented first version instead uses+6%HP; choose one behavior before revising |
| Scrapwright |4| +10% repair speed | One turret+10%damage | Planned; turret effect must not multiply once per structure/piece |
| Cinderweave |5| +6%fire damage | Burning-kill explosion, at most once/sec | Planned; proc cannot recursively trigger itself |
| Rimebound |8| +8%frost resistance | Chilled enemies deal5%less damage | Planned; damage type/resistance pipeline required |
| Stormrunner |9| +5%movement | Dodge empowers next hit with lightning,8s cooldown | Planned; shares movement cap |
| Graveward |12| +6%maxHP | Health pickups grant small shield | Planned; shield amount, duration and stacking TBD |
| Eclipse |19| +5%elementaldamage | Three distinct statuses empower class ability,12s cooldown | Planned; status tracking and consume timing TBD |
| Riftweaver |TBD| +3%spell damage | +4%permanent cooldown reduction | Implemented; future-zone assignment TBD |

### Zone provenance and materials

All rows after Zone1 are planned. Each zone has five missions and a signature boss; only Zone1 rewards currently bank in code. Materials are intended for targeted crafting, generally eight materials plus Credits/Parts for an ordinary zone item in the design; recipes and actual costs are not implemented.

| Zone | Signature boss / material | Planned equipment pool or target reward |
|---|---|---|
|1 Blackout Outskirts | The Breaker / Breaker Plate | Pistol, Outrider, Medkit; ten medals selects Rare; fifteen Garage Lantern cosmetic |
|2 Freight Yard | Chainjaw / Chainlink Core | Ironwatch, Hunting Rifle, Hunter's Sigil; ten medals Rare Ironwatch/rifle |
|3 Silent Suburbs | The Whisperer / Whisper Shard | Ember Staff, Beacon Pendant, Survey Lantern; ten medals Rare choice |
|4 Flooded Market | The Drowned Bell / Tidal Brass | Scrapwright, Pump Shotgun, Repair Drone; ten medals Rare set/drone |
|5 Ironworks | The Forge Warden / Furnace Heart | Cinderweave, Ember Staff, Ember Locket; ten medals Rare set/locket |
|6 Orchard County | The Rootmother / Heartwood Knot | Wayfinder Coin, Outrider, Runeblade; ten medals Epic coin/set |
|7 Coldwater Docks | Captain Undertow / Anchor Fragment | Shock Mine Kit, Salvage Repeater, Hunter's Sigil; ten medals Epic mine/repeater |
|8 Whiteout Village | The Pale Howler / Rime Fang | Rimebound, Frost Bow; ten medals Epic choice |
|9 Dead Signal | The Antenna Saint / Storm Coil | Stormrunner, Storm Scepter, Clockwork Seal; ten medals Epic scepter/set |
|10 Buried Transit | The Railbreaker / Railbreaker Bearing | Runeblade, Ironwatch, Ward Projector materials; ten medals Epic blade/set |
|11 Ashfall Quarry | The Stone Maw / Quarry Geode | Defensive equipment, Stone Lance research; ten medals Epic armor-affix item |
|12 Quarantine Ward | The Plague Matron / Purified Gland | Graveward, Field Medkit; ten medals Epic set/medkit |
|13 Glasshouse Labs | The Glass Gardener / Prism Seed | Unlocked elemental charms/reforge materials; ten medals Epic charm |
|14 Rustwater Refinery | The Oilbound / Refined Emberglass | Ember Staff, Ember Locket, Cinderweave; ten medals Epic fire item |
|15 Rooftop District | The Sky Reaver / Reaver Pinion | Precision weapons, Hunter's Sigil, Stormrunner; ten medals Epic precision item; Legendary crafting unlock |
|16 Broken Reservoir | The Dam Keeper / Pressure Crystal | Ward Projector, defensive equipment; ten medals Legendary choice |
|17 Hollow Bunker | The Hollow Marshal / Command Seal | Salvage Repeater, Ironwatch, Clockwork Seal; ten medals Legendary repeater/set |
|18 Storm Coast | The Tempest Colossus / Tempest Heart | Storm Scepter, Stormrunner, advanced gadget materials; ten medals Legendary storm item; Mythic-component contracts |
|19 Nightfall Core | The Hollow Regent / Regent Shard | Eclipse, Hollow Prism; ten medals Legendary choice; first Mythic blueprint |
|20 Last Beacon | The Night Sovereign / Sovereign Ember | All unlocked families, targeted category weighting; ten medals Legendary choice; finale chosen Mythic core |

Future cache table in the main plan: Zones1–5 `55/30/13/2/0%`; Zones6–10 `30/35/27/7/1%`; Zones11–20 `15/30/38/14/3%` for Common/Uncommon/Rare/Epic/Legendary. Only the first table exists in runtime. Legendary-within80 guarantee and endgame Mythic crafting are planned. Reconcile the proposed Zone6 Legendary cache access against Zone15 Legendary-crafting progression before implementation; it is a design inconsistency to decide, not an implemented feature.

## 11. Required balance and regression checks

These are acceptance targets for meaningful tests, not claims that this documentation ran them.

1. **Merge correctness:** three same-family Rare items with different affixes/ranks/levels produce one Epic; selected affixes/ranks remain; highest input level remains; exactly two donors disappear; IDs/equipment/build references remain valid; replay/save failure never consumes twice. Different family, rarity or slot fails without mutation. Locked/equipped/build donors fail. Terminal rarity and campaign ceiling reject explicitly.
2. **Tuning:** eligible replacement, unique affixes, rank retained, deterministic committed sequence, exact wallet cost, rank3 cap, no mutation on insufficient funds/save failure/active run. No tuned gear has more affixes than rarity allows.
3. **Set counting:** Common/Uncommon do not count; Rare counts; unequip one piece crosses threshold immediately; two-plus-two works; three-plus-two impossible in four slots; set effects apply once; merge does not change membership.
4. **Acquisition gates:** every source emits only permitted family/rarity/level; advertised odds agree with generation; tenth and thirtieth guarantees survive restart and category switching; unavailable zones cannot be selected to increase reward power.
5. **Early build matrix:** Survivor1 starter; lucky Epic weapon; level5 Rare three-piece set; maximum legitimate Zone1 build. Exercise Mission1 and Mission5 with each. Compare time-to-kill, incoming effective hits, survival, HP recoveries, offer count and inventory gain. Tests prove math/constraints; representative human play is still required to judge fun.
6. **Class matrix:** Scavenger/Engineer; available spell tree starters/unlocks; key cooldown and armor/pickup caps. Verify permanent availability does not grant run ranks or class power early.
7. **Economy simulation:** fixed campaign first-clear rewards; repeated contracts; two videos/day; unlucky/median/lucky crates; targeted-family merge counts; realistic upgrade-vs-tune costs. Report distributions and routes, not a promised week count.
8. **Save preservation:** version1/2 migration retains ownership and active checkpoint; version3 round-trip preserves affix ranks, skill unlocks, locks/builds and set stats; future schema never silently resets a profile. Legacy higher-tier gear needs an explicit preservation decision when caps change.

### Change log

* October 18: established sixteen-family current catalog, all six affixes with rank budgets, three implemented sets, full acquisition rules, current versus planned progression, twenty-zone provenance, merge/tuning review findings and test gates. Initial unrestricted merge and uncapped pickup findings were addressed during integration: Epic merge ceiling and permanent pickup 1.50 are now enforced. Parent engineer reports all 20 automated suites passed 5,739 checks, including progression 3,142 and equipment 81; this agent reviewed source and documentation, and did not independently rerun those suites. That result verifies constraints/regressions, not player fun or campaign difficulty.

## Zone 1 acquisition completion - October 19

`apps/nightfall-godot/zone_one.gd` now records eight stable catalog IDs, source lists, slot budgets, source rarity ceilings and the current Level 5 equipment ceiling. These are catalog identifiers; the existing save schema still merges by unchanged display-name/slot/rarity identity. No save migration or rename occurred.

The Workshop's **Breaker Forge** creates one selected local Rare item at Level 1 for **8 Breaker Plates + 330 Credits + 5 Parts** after clearing Mission 5. This adopts the balance proposal's eight-material recipe, twice the standard-clear Credit award (2 x 165), and 4 + zone Parts (5). It does not adopt that proposal's unimplemented captain fragments or higher boss health. The current finale grants one Plate on each successful clear, so the deterministic no-ad route is eight finale victories from zero Plates. Those clears themselves grant 1,984 base Credits and 40 Parts, comfortably funding the 330/5 currency component; field rewards are extra. This is an acquisition ceiling in clear count, not a measured session-time or difficulty claim.

The item preview uses the real next inventory identity and affix generator. A second tap confirms spending. The profile verifies the clear receipt, chosen slot, all three currencies and inactive expedition at the transaction boundary. Item generation, identity advancement and all spending commit together; a failed save restores all of them. Existing gear is not consumed. A forged item has the ordinary Rare budget, affix capacity and Level 5 upgrade ceiling; crafting supplies no special damage multiplier.

See [Zone 1 completion and QA](ZONE_ONE_COMPLETION_QA.md) for tests, authored encounters, content sources and remaining acceptance gaps.
