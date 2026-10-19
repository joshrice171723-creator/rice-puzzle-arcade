# Equipment, loot and internal quality grades

The design catalog contains **93 named families**: twenty weapons, 36 armor pieces in nine sets, 25 rings/pendants and twelve gadgets. `item_catalog.csv` gives every name, first zone, minimum Survivor level, slot budget, attack/effect and acquisition rule. Existing names are preserved. New names are proposals for later implementation, not claims that the current Shop contains them.

## Internal quality is separate from rarity

Joshua requested internal S/A/B/C/D/E grades, with S best, then delegated the distribution to balancing rather than fixing percentages. The grades here are **internal authored assessments**, never player-facing labels or loot weights. A Common S-grade family is possible; a Mythic E-grade family remains that family with a larger primary multiplier. Grade never changes a stat, price, equip level or drop roll.

Score each family at matched equipment level and rarity, within its role and across single-target bosses, mixed waves and movement pressure. Five integer axes run 1–5: impact 25%, coverage 20%, reliability 25%, independence from a narrow build 20%, and fair counterplay/low execution burden 10%. `score=sum(axis×weight)/5`. Thresholds are S≥90, A≥80, B≥70, C≥60, D≥50, E<50. Exact axes and scores are in `quality_grades.csv`; no hidden rounding creates a grade. This rubric favors broad reliable utility over a narrow best-case damage screenshot.

| Catalog | E | D | C | B | A | S | Total |
|---|---:|---:|---:|---:|---:|---:|
| Equipment families | 4 | 14 | 32 | 23 | 13 | 7 | 93 |
| Automatic attack abilities | 0 | 1 | 2 | 2 | 2 | 1 | 8 |
| Armor sets, scored separately | 0 | 1 | 4 | 2 | 1 | 1 | 9 |
| Passives, scored separately | 0 | 1 | 1 | 1 | 4 | 2 | 9 |
| Shrine relics, scored separately | 0 | 0 | 2 | 2 | 0 | 2 | 6 |

Equipment percentages are approximately 4.30% E, 15.05% D, 34.41% C, 24.73% B, 13.98% A and 7.53% S. Ability composition is 12.5% D, 25% C, 25% B, 25% A, 12.5% S. These proportions are outputs of the rubric, not quotas. There is no reason to invent an E-grade spell simply to fill a histogram. Percentages are displayed to two decimals and may not sum to exactly 100 after rounding; raw counts are authoritative.

Low grades indicate narrow or unreliable general performance, not permission to ship a trap. Refinery Coil extends burn *duration*, preserving total damage; it is useful for status uptime but not general DPS. A turret-range ring matters in defensive placements but does nothing for a structure-free run. A slow-cleansing accessory answers particular zones. If such an item has no meaningful matchups in play, redesign it or remove it instead of making its loot artificially common. E-grade effects must be clearly explained and easily salvaged/exchanged.

The highest scores include broadly reliable survival and normal weapons, not just late-zone items. Ironwatch's high internal score flags a possible defensive default; it does not prove dominance. Reassess grades after at least thirty valid runs per relevant role/context and whenever a global cap, boss composition or source rate changes. Promote/demote based on measured use, marginal improvement, opportunity cost and player preference. Never optimize the distribution back toward an arbitrary percentage.

## Primary budgets and visible rarity

| Slot | Level-1 Common primary budget |
|---|---|
| Weapon | 40 Power |
| Head | 20 HP, 10 armor |
| Chest | 40 HP, 15 armor |
| Pants | 10 HP, 5 armor |
| Boots | 10 HP, 5 armor |
| Pendant | 5 HP |
| Ring | 5 HP |
| Gadget | Utility only; zero primary stats |

Every family in the same slot receives this budget. A later named weapon does not secretly start with 80 Power. Rarity multipliers remain Common1 / Uncommon1.04 / Rare1.08 / Epic1.12 / Legendary1.16 / Mythic1.20, with 0/1/1/2/3/3 affixes. Mythic adds one selected bounded signature, not a fourth affix.

Primary scaling is `base×[1+0.05(L−1)]×rarity`. Utility does not scale with level/rarity unless explicitly specified. This v1 keeps all gadget utility fixed and proposes disabling meaningless gadget-level purchases until gadgets have a real primary progression axis. Gadgets can still gain affixes and rarity. Do not show a Common Medkit upgrade as stronger healing when its 20% fraction is unchanged.

## Twenty weapon concepts and their jobs

All twenty complete attack patterns are in the catalog. Early canonical roster is preserved: Service Pistol, Hunting Rifle, Ember Staff, Pump Shotgun, Runeblade, Salvage Repeater, Frost Bow and Storm Scepter. New zone identities fill actual playstyle gaps:

| First zone | New weapon | Concrete tradeoff at 40 Power |
|---:|---|---|
| 5 | Furnace Hammer | 60 damage/1.5s, three-target close arc; release delay and proximity risk |
| 10 | Railspike Lance | 64/1.6s, second pierced target takes half damage; line alignment required |
| 11 | Quarry Maul | 76/1.9s, brief ordinary/elite stagger with eight-second internal cooldown; no boss stagger |
| 12 | Purifier Carbine | Three 16-damage shots/1.2s; sustained target converts some damage to fire without adding total damage |
| 13 | Prism Wand | 36/0.9s; one 35%-damage bounce to another target; cannot bounce back into boss |
| 14 | Vapor Torch | 8/0.2s in close cone; two seconds firing plus half-second vent gives 32 sustained single-target DPS |
| 15 | Parapet Rifle | 88/2.2s; +15% beyond 7m, −15% below 4m; long safe firing lanes are its advantage |
| 16 | Pressure Harpoon | 60/1.5s; small ordinary-enemy pull; heavy enemies and bosses resist displacement |
| 17 | Marshal Carbine | 20/0.5s; first post-Dodge burst splits its damage between two targets, not twice the damage |
| 18 | Tempest Fork | 40/1s; alternate hits fork 20% to one additional enemy; no recursive chain |
| 19 | Hollow Edge | 52/1.3s in two-target sweep; ignores frontal armor on marked target but retains resistance and proximity constraints |
| 20 | Dawn Beacon | 80/2s split physical/arcane; one small post-class-power shield on a twenty-second cooldown |

Single-target normalization is generally 40 raw DPS before range/accuracy/venting. A shotgun reaches 40 only with all five pellets; three hits are 24. Storm Scepter has 28 boss DPS without a second target, 40 split across two; its crowd advantage must be evaluated separately. Do not silently multiply all spell damage by a weapon's special basic-attack DPS perk. Power is the common spell-scaling stat.

No weapon requires manual aiming buttons or ammunition purchases. Automatic target selection should favor the nearest valid threat within a readable cone, with a small hysteresis window to prevent constant target switching. All attack-release animations permit movement. A manual dodge cancels a pending melee release without spending a second cooldown; the exact cancellation rule must be tested for exploit-free repeated resets.

## Set effects

Every set has four named armor pieces in the catalog; only Rare+ equipped pieces count. Two- and three-piece effects apply once each. No four-piece bonus. A 2+2 mix is legal; 3+2 is impossible because there are only four armor slots. Ring/Pendant never supply armor-set credit.

| Set / first zone | Two-piece | Three-piece | Budget/counterbalance |
|---|---|---|---|
| Outrider / 1 | +15% pickup | +1 secure slot | Economic/collection utility; no direct boss damage |
| Ironwatch / 2 | +12 armor | +6% maximum HP | Preserve implemented version; do not also add the historical shield-on-Dodge |
| Riftweaver / 3 | +3% spell damage | +4 percentage points permanent spell CDR | CDR shares 15% cap; no turret bonus |
| Scrapwright / 4 | +10% repair speed | One nearest owned turret +10% damage | One turret, not every placed structure; lost structure means lost bonus |
| Cinderweave / 5 | +6% fire damage | Burning kill explodes for 20% Power within1.5m, max5 targets, one-second cooldown | No recursive explosion; no extra proc against lone boss without adds |
| Rimebound / 8 | +8% frost resistance | Chilled enemies deal5% less damage | Strongest outgoing-damage debuff only; bosses receive2.5% effect |
| Stormrunner / 9 | +5% movement | Next hit after Dodge adds20% Power lightning, eight-second cooldown | Shared movement cap; proc cannot crit/proc |
| Graveward / 12 | +6% max HP | Health pickup grants4% max-HP shield4s, twelve-second cooldown | No proc from passive regen or its own shield; cap applies |
| Eclipse / 19 | +5% elemental damage | Three distinct statuses empower next class power by15%, twelve-second cooldown | Needs status investment; no repeated empowerment of one pulse/echo |

Accessory bonuses consume the same global caps. The later Hollow Prism and Eclipse trigger share one `three-status empowerment` category: use the larger empowerment, never 1.15². Graveward ring and set share their health-pickup shield category. Stormrunner and Tempest Band share a post-Dodge damage-proc category; use the larger coefficient/shorter permitted cooldown, not both hits. These explicit exclusions prevent a modest-looking collection of duplicate effects becoming a runaway stack.

## Conservative unlock and equip gates

One predicate must govern **every** source: source zone/family unlocked, required Survivor level met, item level within the highest-unlocked-zone cap, and rarity milestone earned. Apply it to random crates, chosen rewards, crafting, merging, purchases, gifts, ads and future imports. The UI must never advertise unavailable power as immediately usable.

Family access starts when its first zone is legitimately unlocked. A zone's local pool comprises its canonical main-plan families plus its explicitly listed new concepts; global crates use all unlocked families. Zone 20 lets the player choose a category, then weights only unlocked families in that category. It does not bypass a missing class/family/material gate.

All newly generated equipment starts at level 1 in v1. This avoids granting large unseen upgrade investment through free high-level salvage loops. A future catch-up drop level needs its own funding/refund audit. Survivor minimum is based on family first zone, not where the item happened to drop. Owned old items are never deleted when the new source gate is added; preserve them, label legacy exceptions in testing, and apply current live upgrade/merge ceilings without downgrading their saved record.

**Legendary requires the Zone 15 Mission 5 clear receipt.** Zone 15's reward remains Epic because it is generated under the pre-clear reward tier; after committing the clear, Legendary recipes/global odds become available. Zone 16 ten-medal rewards are Legendary. There is no 1% Legendary chance in Zone 6. This resolves the contradictory historical table with one conservative gate.

Mythic requires the Zone 19 Mission 5 receipt, its blueprint, three matching Legendary items, eight relevant zone materials and one earned Mythic core. Tempest component contracts open after Zone 18; their fragments alone cannot craft before the blueprint. The Zone 20 first finale guarantees one chosen core. Additional cores cost ten endgame fragments from capped-per-clear, repeatable earned bounties. No daily payment or ad gate. The normal pre-finale balance model excludes Mythic.

## Merging, tuning and signatures

Merge exactly three same-name/same-slot/same-rarity copies. Different affixes/ranks/levels are allowed. Retain selected ID, affixes, affix ranks, lock and build/equip references; keep the highest input level. Consume two eligible donors atomically. Donors must not be equipped, locked, or referenced by a saved build. No Credits/Parts cost through Epic. Epic→Legendary additionally consumes four local materials from the family's unlocked recipe and requires the Zone15-clear receipt. Legendary→Mythic consumes the eight materials, core and blueprint already specified. Both retain the same three-copy identity rules; this is a proposed extension beyond the current Epic ceiling.

Pure duplicate cost is three Rare→Epic, nine Rare→Legendary, twenty-seven Rare→Mythic before milestone/core constraints. That ladder is a duplicate sink, **not** the required path for every slot. Chosen crafting and guaranteed milestone choices keep a desired build from depending on 27 identical random drops.

Existing six affixes retain rank1/2/3 values: Tempered3/4.5/6% weapon Power; Reinforced4/6/8% item HP; Plated4/6/8% item armor; Attuned2/3/4 percentage points CDR; Seeking5/7.5/10% pickup; Lightweight1/1.5/2% movement. Rank1→2 costs50 Credits+3 Parts, 2→3 costs100+6. Random replacement costs100+5, keeps rank, excludes duplicates and current value, and has no random strength roll.

Future modest additional affixes are Precision (+1/1.5/2 percentage points crit, Weapon/Ring), Warded (+2/3/4% one chosen elemental resistance, armor/Pendant) and Efficient (+2/3/4% structure damage, Gadget/Pendant). Introduce them only with their real damage-type/crit/structure implementations and zone gates 7/8/10. They share existing caps. They are **not** included in the current six-affix build baseline or its probabilities.

After Zone 13, a chosen-affix craft costs300 Credits+15 Parts+four Prism Seeds and replaces one eligible affix while retaining rank. This is a predictable alternative to repeated rerolls. It does not add a slot. Random rerolling among `k` eligible alternatives has expected `k` attempts to hit one desired alternative only if the eligible pool is unchanged; failed rolls can change that pool, so use the actual state machine in implementation tests.

Mythic signatures are selected utility/conditional damage, not another unlimited multiplier: Weapon offers +8% damage for3s after a manual Dodge, 12s cooldown; armor offers6% max-HP shield4s on boss arrival, once; Pendant/Ring offers +5% pickup and reveal containers within8m; Gadget offers one additional activation only for a finite-charge gadget, or a fixed10% cooldown reduction for a repeating gadget. One signature per item; post-Dodge damage signatures share one category across equipment, and concurrent shields obey the global cap. No additional Medkit charge: its Mythic option instead increases the existing heal from20% to25%, or30% with Infirmary II, once per run. Recheck EHP before approving this endgame exception.

## Reward cadence and targeted acquisition

Captains have a 35% zone-item chance; signature bosses guarantee one zone item and one named zone material. Normal field caches guarantee their listed Parts bundle plus a15% equipment chance, independent of the Parts; this is a **future change** from current either/or caches. At most one equipment roll per cache. Optional elite equipment chance is10%, at most two eligible elites per run. All gear remains unsecured until stashed or the boss is killed.

For a five-mission first pass, expected boss items are `4×0.35+1=2.4`, before caches, keys and medals. Captains also grant one zone-material fragment; three fragments convert to one full material. Thus every captain clear advances targeted crafting, not only Mission5. Eight full materials plus `2×zone standard Credits` and `4+zone` Parts craft one chosen local item at Rare through Zone5, Epic through15, Legendary after the gate. This gives a deterministic eight-signature-clear ceiling when starting from zero material; captain fragments and ten-medal awards shorten it. A ten-medal reward gives the canonical chosen item plus four local materials.

Five medals grant three standard-clear Credits. Ten medals give the canonical chosen rarity/item and four materials. Fifteen grant the named cosmetic and `30+5z` Gems. First clear grants one key and10 Gems per mission, plus30 extra Gems for Mission5. Only the clear medal is guaranteed by victory; damage/cache medals are optional. Do not fund required progression assuming fifteen medals everywhere.

Recommended global chest odds, Common/Uncommon/Rare/Epic/Legendary: Zones1–5 **55/30/13/2/0%**; Zones6–10 **30/35/28/7/0%**; Zones11–15 **15/30/41/14/0%**; after Zone15 clear **15/30/38/14/3%**. Mythic is always0%. Every tier has Rare-or-better within10 and Epic-or-better within30 openings. Only after the Legendary gate does an independent Legendary miss counter begin, with guarantee within80. Gate changes do not award retroactive Legendary pity for earlier openings. Category switching does not reset or multiply shared counters.

The pity result is selected first, then family/slot from the allowed category, then eligible affixes. Pity guarantees rarity, not a specific set. A category choice should not falsely advertise an eight-opening set guarantee. At least one earned chosen-family route is always available; random loot is extra variety.
