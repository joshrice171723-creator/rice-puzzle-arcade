# Nightfall campaign balance design v1

October 18–19, 2026. **Proposed content and quantitative design, not implemented game behavior.** This package authors the future twenty-zone campaign. It does not authorize importing its tables into the game. The parent feature delivery and its tests do not validate these new balance values.

The canonical names, campaign structure and player decisions come from [the main plan](../NIGHTFALL_MAIN_PLAN.md). The implemented baseline is recorded in [the equipment ledger](../EQUIPMENT_BALANCE_LEDGER.md) and [progression QA](../PROGRESSION_FEATURES_QA.md). Where this package proposes a different number, the difference is identified below. The old documents remain historical evidence; this package is the internally consistent **future-design proposal**.

## Read in this order

1. [Campaign model](CAMPAIGN_BALANCE_MODEL.md): formulas, minimum/typical/strong builds, difficulty boundaries and survivability.
2. [Leveling and skills](LEVELING_AND_SKILL_MATH.md): all XP curves, skill-tree costs, spell ranks/branches/evolutions, automatic powers and stacking rules.
3. [Equipment and loot](EQUIPMENT_AND_LOOT_DESIGN.md): 93 named equipment families, set budgets, acquisition gates, tuning, rewards and investment.
4. [Enemies, bosses and waves](ENEMIES_BOSSES_AND_WAVES.md): seventeen monster archetypes, twenty zone ecologies, one hundred named bosses, complete schedules and readable attack constraints.
5. [Economy and recovery](ECONOMY_AND_RECOVERY.md): currency separation, sequential progression, facilities, side modes, failure and optional advertising.
6. [Validation and handoff](VALIDATION_AND_HANDOFF.md): calculations actually executed, bounded stochastic experiments, unresolved risks and human playtest acceptance.

## Structured handoff tables

These are design data, never runtime code. CSV numbers use decimal points and seconds/meters/HP unless the column names say otherwise. UTF-8 names are authoritative. IDs are stable proposal IDs; future implementation must map them explicitly to source IDs.

| Table | Scope and interpretation |
|---|---|
| `formula_registry.csv` | Canonical formula identifiers, constants, order and rounding |
| `zones.csv` | Twenty approved zones, all captain/signature names, materials, caps and source gates |
| `missions.csv` | One hundred missions: duration, boss budgets, ordinary-enemy multipliers, caps and rewards |
| `waves.csv` | Six contiguous segments per mission: 600 rows, explicit enemy counts and spawn/XP budgets |
| `monster_archetypes.csv` | Seventeen base archetypes: HP, hit, movement, range, tell, attack period, resistance and cost |
| `zone_monsters.csv` | Zone-floor normal/elite numbers for every unlocked archetype; mission modifier is applied afterward |
| `bosses.csv` | All one hundred named encounters, phase HP, attack budgets, cycles and reinforcement limits |
| `signature_attacks.csv` | Three concrete attacks for each signature boss, with damage, tell, geometry and response |
| `item_catalog.csv` | 93 named families: twenty weapons, 36 armor pieces, 25 accessories, twelve gadgets |
| `quality_grades.csv` | Internal S–E scores for equipment, abilities, sets, passives and relics; no fixed distribution quota |
| `shared_evolution_combinations.csv` | Six legal three-evolution builds using the Frost/Ground shared passive |
| `calculation_receipt.json` | Local arithmetic-audit result and table cardinalities |
| `upgrade_costs.csv` | Every level 1→30 transition and cumulative investment |
| `survivor_levels.csv`, `mastery_levels.csv`, `combat_levels.csv` | Complete permanent and temporary XP thresholds |
| `class_skill_nodes.csv` | Twenty permanent unlock nodes, prerequisite edges and earliest affordable mastery |
| `ability_ranks.csv` | All eight spells at rank 1 and both rank 2/3 branches: forty rows |
| `mission_xp_forecast.csv` | Three collection scenarios for each mission, including level after every wave segment |
| `player_builds.csv`, `build_recipes.csv` | 180 end-of-zone builds and legal ordered picks: three investment tiers × three archetypes × twenty zones |
| `economy_forecast.csv` | Independent no-ad cumulative reward versus target-investment snapshots; excludes prior contract income |
| `economy_sequential.csv` | Carry-forward ledger that pays deficits with earned contracts and includes their XP |
| `boundary_checks.csv` | Explicit transitions across Zones 1→2, 5→6, 10→11, 15→16, 18→19 and 19→20 |
| `stochastic_damage_scenarios.csv`, `loot_simulation.csv` | Seeded mathematical experiments; no empirical player success claims |

## Decisions that remain fixed

Native portrait action; automatic basic attacks, spells and class powers; manual movement and Dodge. Every campaign mission has timed waves followed by a required boss kill. There is no second boss timer, survival-only win, forced-loss schedule or payment-dependent AI. Existing enemies remain at boss arrival; normal wave spawning ends. Boss reinforcements are capped and cannot become an infinite reward farm.

Permanent Survivor levels, class mastery, unlocked skill pools, equipment and Haven are separate from temporary combat levels, ranks, branches, Field Scrap and buffs. Permanent skill ownership grants draft eligibility, never free spells at run start. Run choices are paused decisions. One reusable fast merchant shrine, two slower buff shrines, at most three distinct buffs per attempt. Secure stash protects selected newly found loot on defeat. Five tabs remain Shop, Gear, Expedition, Base, Class; inventory is five columns with vertical scrolling. No art or UI redesign is part of this package.

## Explicit proposed changes from the current proof

| Area | Current source evidence | Future v1 proposal |
|---|---|---|
| Campaign | Zone 1 only, five 240-second missions | Twenty zones and one hundred authored encounters |
| Zone 1 boss HP | 700 / 820 / 900 / 1,000 / 1,200 | 1,800 / 1,980 / 2,160 / 2,340 / 3,000; a separately testable tuning proposal, not a shipped fix |
| Equipment level | Constant ceiling 5 | Campaign cap `min(30,4+z+floor(z/3))` |
| Legendary | Unavailable through current merge | Available only after legitimate Zone 15 Mission 5 clear; no Zone 6 Legendary cache odds |
| Mythic | No acquisition/signature system | Blueprint after Zone 19 clear, earned components after Zone 18, final chosen core after Zone 20; never random chest loot |
| Armor family access | All three current sets in early crates | Outrider Zone 1, Ironwatch Zone 2, Riftweaver Zone 3, then authored family gates; preserve legacy ownership |
| Equipment costs | 40×current level Credits, current level+1 Parts through level 5 | Preserve early steps, taper later costs as specified in the cost table |
| Combat XP | Five times current combat level to next level; unit drops | Weighted XP with complete cumulative table, telegraphed elite bonus and measured capture scenarios |
| Enemy units | Current world-unit values, three normal families | Meter-based content specification; conversion and geometry acceptance required |
| Dodge | Three-second recharge, 0.18-second normal invulnerability | Preserve this observed cadence for v1; historical six-second proposal is not used |
| Damage types | Current proof broadly applies armor | Explicit physical/elemental separation; mixed-type stress checks required |
| Crit | Historical proposal, not a proven runtime feature | 5% base, 150% damage, basic weapons only for the baseline model |
| Shrines | Current merchant spends Field Scrap | Separate Field Tokens for merchant purchases so construction and magic have transparent budgets |

Most future numbers are deliberately conservative starting points. A mathematically legal build is not evidence that aiming, screen readability, randomness, pacing or combat feel is good. The package distinguishes exact arithmetic, assumed contact/capture fractions, stochastic toy models and untested player experience throughout.
