# Permanent combat progression balance

Design contract agreed for the October 19, 2026 implementation. Mathematical examples below are calculations, not measured playtime. Runtime and save acceptance must be established by the implementation checks. This document does not claim that future campaign balance tables are already playable.

## Scope and existing systems

Add six permanent stats: **Attack, Strength, Defence, Ranged, Magic and Vitality**, each starting at **1/99** and capped at **99/99**. A separately displayed **Combat Level** starts at 1 and ends at 99. It supplies one permanent talent point per level gained.

Keep these existing systems distinct:

| System | Existing source | Relationship to the new system |
|---|---|---|
| Expedition XP and levels | `run.gd`: pickups, `xp`, `level`, draft offers | Still reset each expedition; damage-earned permanent XP does not trigger draft choices. Use “Expedition level” to avoid confusing it with permanent Combat Level. |
| Survivor XP and level | `haven_content.gd`, `profile.gd` | Existing permanent progression and base HP remain; no automatic conversion into combat XP. |
| Class mastery | `haven_content.gd`, `class_talents.gd` | Existing mastery earnings and milestone passives remain; new mastery ranks no longer mint talent points. |
| Permanent ability availability | `skill_tree.gd`, `profile.gd` | Combat-earned points fund the existing branches. Unlocking availability still does not give a spell a free expedition rank. |
| Permanent combat stats | New progression implementation | Damage earns XP into the selected training focus, with additional automatic Vitality XP. |

The inspected starting equipment totals 40 Power, 210 HP and 35 armor before class effects. Ordinary source enemies have 32–48 HP; mission bosses have 700–1,200 HP. The future campaign model proposes different boss HP and zone growth. Reward normalization must therefore survive both content sets without making a health rebalance an accidental progression multiplier.

This contract supersedes the mastery-earned point rule in `balance-design/LEVELING_AND_SKILL_MATH.md` for the new implementation. That older document's temporary “combat levels” refer to expedition draft progression. Its rule that boss damage does not award XP applies to its old expedition-XP model; the new permanent stat XP explicitly does accrue from eligible boss damage.

## Reference and evidence boundary

The reference is the familiar Old School RuneScape-shaped XP curve, not a claim of identical combat mechanics. Jagex's historical design explanation describes support for specialized and mixed combat builds; an [archived copy of the Jagex announcement](https://oldschool.runescape.wiki/w/Update%3ARS2_Combat_system_explained) was available through search. The original publisher URL could not be retrieved in this research pass.

The [OSRS Wiki skill page](https://oldschool.runescape.wiki/w/Free_to_play_skills) documents the cumulative XP formula in searchable content. This is a community-maintained mathematical reference, not an official current training-time guarantee. The original Experience page was blocked to the research browser. The [community combat-level formula](https://oldschoolrunescape.fandom.com/wiki/Combat_level) uses Defence, Hitpoints, Prayer and the strongest offensive style; Nightfall deliberately uses a different six-stat average. No measured OSRS training rate is asserted here.

## XP thresholds and the one-sixth target

For integer level `L` from 1 through 99:

```text
reference_xp(L) = floor(sum[n=1..L-1](floor(n + 300 * 2^(n/7))) / 4)
nightfall_xp(L) = floor(reference_xp(L) / 6)
level(xp) = greatest L in [1,99] for which xp >= nightfall_xp(L)
```

The empty sum at level 1 is zero. Divide the cumulative integer threshold by six; do not divide and round every level's increment independently. Store each stat's cumulative earned XP and derive its level. Clamp credited progress at the level-99 threshold, without reducing another stat's independently earned share.

| Level | Reference cumulative XP | Nightfall cumulative XP | Focused hours at an assumed 60,000 focus XP/hour |
|---:|---:|---:|---:|
| 1 | 0 | 0 | 0 |
| 2 | 83 | 13 | 0.0002 |
| 10 | 1,154 | 192 | 0.0032 |
| 20 | 4,470 | 745 | 0.0124 |
| 30 | 13,363 | 2,227 | 0.0371 |
| 40 | 37,224 | 6,204 | 0.1034 |
| 50 | 101,333 | 16,888 | 0.2815 |
| 60 | 273,742 | 45,623 | 0.7604 |
| 70 | 737,627 | 122,937 | 2.0490 |
| 80 | 1,986,068 | 331,011 | 5.5169 |
| 90 | 5,346,332 | 891,055 | 14.8509 |
| 92 | 6,517,253 | 1,086,208 | 18.1035 |
| 99 | 13,034,431 | 2,172,405 | 36.2068 |

**A sixth of the XP is a sixth of the time only at the same earned XP/hour.** In general:

```text
Nightfall_time / reference_time ≈ (1/6) * reference_XP_per_hour / Nightfall_XP_per_hour
```

Use 60,000 XP/hour solely as a named comparison assumption. It yields 217.24 reference hours versus 36.21 Nightfall focused hours. It is not a measured average for either game. Actual Nightfall earnings depend on targets, survival, downtime, gear, area damage and the damage-credit rules below. Do not advertise “six times faster” as a verified experience until those rates have been measured.

This curve intentionally advances early levels quickly and places roughly half the total XP after level 92. At the assumed rate, a focused stat reaches 40 in 6.2 minutes. That is an explicit pacing consequence, not an arithmetic error; early levels are feedback, while upper levels are long-term goals.

## Damage credit and enemy reward budgets

Award permanent XP for eligible damage as it happens, not only on a kill. For each spawned enemy, record immutable spawn maximum HP `H`, authored reward weight `w` and remaining rewardable HP `R`, initially `H`.

```text
actual_damage = min(max(post_mitigation_damage, 0), max(HP_before_hit, 0))
rewardable_damage = min(actual_damage, R)
normalized_damage = rewardable_damage * (48 * w / H)
focus_xp = 0.5 * normalized_damage
R = R - rewardable_damage
vitality_xp = focus_xp / 3
```

Require finite positive `H`; invalid entities must not manufacture XP. Only actual HP damage counts: invulnerability, shield-only hits, misses, zero/negative damage and overkill give no extra credit. Normalization uses the original spawned maximum HP, not remaining HP. Healing or phase changes must not reset `R` or the reward budget.

| Enemy category | Weight | Maximum focus XP per body | Additional Vitality XP |
|---|---:|---:|---:|
| Ordinary | 1 | 24 | 8 |
| Boss | 10 | 240 | 80 |
| Future authored elite | 3 | 72 | 24 |

The current slice has ordinary and boss flags; the elite row is a future recommendation, not an existing runtime category. Do not infer elite status from unusually high HP. Future archetype rewards can be authored explicitly and calibrated against threat and time; health alone must not assign weight.

Examples: 24 actual damage against a fresh 48-HP ordinary enemy gives 12 focus XP and 4 Vitality XP. Killing a 32-HP runner still awards at most 24 focus XP. A 1,000-damage overkill on a fresh 48-HP enemy also awards at most 24. Dealing 350 actual damage to a fresh 700-HP boss gives 120 focus XP; dealing 600 to a 1,200-HP boss gives the same amount. Doubling an enemy's HP while retaining its weight does not double its XP budget.

Player-owned basic attacks, spells, damage over time, structures and eligible damage procs share this central damage-credit path. Count each real HP decrement once, even if several systems observe the hit. Area damage can earn credit from each distinct affected enemy within that enemy's budget. This legitimately rewards clearing several bodies; it cannot generate repeated credit from one corpse.

Practice and benchmark modes grant **zero permanent combat XP**. Noncombat objects, self damage and enemy-on-enemy damage are ineligible. Future boss reinforcements need an encounter-wide authored reward cap; per-body normalization alone does not prevent infinite summon farming. The current implementation must at least retain the existing bounded encounter behavior and not introduce a healing or summon reset loophole.

## Training focus and precision

Selectable focuses are Attack, Strength, Defence, Ranged, Magic and Balanced. A focused mode assigns all `focus_xp` to its named stat. Balanced splits the same pool equally among Attack, Strength and Defence. Vitality is the automatic sixth stat, earning one third of the total focus pool in every mode; it is not a seventh selectable mode or an additional pool per Balanced recipient.

The selected focus controls allocation for **all eligible damage sources**. Selecting Attack does not invent a melee animation or switch the current automatic weapon; selecting Magic can train Magic while the existing pistol is firing. Explain the control as “Training focus.” Source-specific damage types still determine combat bonuses, independently of where XP is trained.

Calculate Vitality from the pre-cap earned focus pool. If the selected stat is already 99, it receives no further progress, but eligible uncapped Vitality can still progress. Balanced retains equal allocation; do not redirect a capped stat's share into the others without an explicit new rule. Changing focus must not reassign earlier pending XP.

Keep fractional XP, including Balanced and Vitality thirds, across hits and checkpoints. The agreed implementation uses double-precision cumulative XP persisted in the profile and snapshot, with no per-hit integer floor. Check chunking invariance within a small floating-point tolerance: a single 24-damage hit and twenty-four one-damage hits must produce the same totals. Exact level thresholds and the level-99 cap remain integer-valued; a comparison tolerance must not allow a materially early level.

## Combat Level and talent budget

```text
CombatLevel = floor((Attack + Strength + Defence + Ranged + Magic + Vitality) / 6)
new_lifetime_points = CombatLevel - 1
available_points = new_lifetime_points + legacy_allowance - total_spent_all_classes
```

Clamp Combat Level to 1–99 after validating individual levels. Six level-1 stats give Combat 1 and zero earned points. Six level-2 stats give Combat 2 and one point. Six level-99 stats give Combat 99 and **98 lifetime earned points**, not 99. One newly gained stat level need not increase Combat Level; six summed stat levels increase it once. Crossing multiple Combat Levels awards the complete difference, including across save/reload.

The average makes every stat relevant and is easy to explain. Its tradeoff is that a specialist earns fewer talents than a character with broad training. A max-offensive-style formula would better preserve specialist identity but would stop rewarding several off-style advances and require additional scaling to land exactly at 1 and 99. Do not silently substitute it.

The existing five nodes per class cost `1 + 1 + 2 + 2 + 3 = 9`. Four trees therefore contain **36 points of current purchases**. One global balance is spent across them; switching class cannot duplicate the earned budget. Without legacy allowance, all currently authored nodes could be bought by Combat 37 if the classes are legitimately unlocked. At Combat 99, **62 points remain banked for future content** after all four trees. Do not add repeatable stat purchases or expand the trees merely to consume that surplus.

Existing saves retain their unlocked abilities. Migration sets a one-time `legacy_allowance` equal to the exact total cost of already purchased nodes, not unspent old mastery points. Existing purchases still count as spent, so this preserves ownership without granting an extra immediate spendable balance. At the eventual cap, the unspent total after purchasing all current nodes is `62 + legacy_allowance`. Validate migration idempotency; reloading cannot add the allowance again. Mastery passives remain at their existing milestones without also issuing new points.

## Stat bonuses and maximum combined effect

Let `u(stat) = (stat_level - 1) / 98`, clamped to `[0,1]`. Bonuses are zero at level 1 and reach these ceilings at 99:

| Stat | Formula | Scope |
|---|---|---|
| Attack | Critical chance `0.10 * u(Attack)`; critical multiplier 1.5 | Direct basic weapon hits only; no recursive spell, burn, structure or proc criticals. |
| Strength | `+0.20 * u(Strength)` damage | Non-elemental damage component. |
| Ranged | `+0.20 * u(Ranged)` damage | Non-elemental damage component; additive with Strength in the same multiplier. |
| Magic | `+0.30 * u(Magic)` damage | Elemental damage component, applied once. |
| Defence | Received damage multiplier `1 - 0.15 * u(Defence)` | Combine multiplicatively with existing mitigation inside the remaining-damage floor `max(0.35, combined_multiplier)`, retaining the 65% total reduction limit. |
| Vitality | HP multiplier `1 + 0.30 * u(Vitality)` | Profile HP once, before expedition HP additions; preserve existing class/equipment order. |

Strength and Ranged reach a combined `1.40` non-elemental multiplier, not `1.20 * 1.20`. Attack's maximum mean basic damage factor is `1 + 0.10 * (1.5 - 1) = 1.05`. Their combined mean eligible basic multiplier is therefore **1.47**, while one critical at those caps deals **2.10** times the unmodified hit. Magic's ceiling is **1.30**. A mixed-damage attack applies each modifier to its own component, never both to the same component.

Vitality and Defence together increase HP-based effective health by at most `1.30 / 0.85 = 1.5294` relative to the otherwise identical build, unless an existing mitigation cap reduces Defence's marginal benefit. This excludes healing and shields. At the unmodified 210-HP/35-armor baseline, level-99 Vitality gives 273 HP; 35 armor's existing `armor/(armor+150)` physical reduction plus capped Defence gives roughly 396.12 physical effective HP versus 259 baseline. Other gear, class, Survivor and run bonuses remain separate investments.

Apply newly earned stat effects when configuring the **next expedition**. An active expedition retains its starting stat modifiers; pending XP must not change maximum HP, damage or incoming mitigation halfway through its checkpoint. This avoids gaining healing by saving, banking or reconfiguring the same active attempt.

## Timeline sensitivity and calibration

The following rates describe the focus pool before the additional Vitality third. They include actual combat downtime within the measured session; choose and report separately whether Haven/menu time is included.

| Assumed focus XP/hour | Ordinary-equivalent kills/minute at 24 XP each | One focused stat to 99 | Vitality to 99 from its automatic third | All five selectable stats to 99, with Vitality also capped |
|---:|---:|---:|---:|---:|
| 20,000 | 13.89 | 108.62 h | 325.86 h | 543.10 h |
| 60,000 | 41.67 | 36.21 h | 108.62 h | 181.03 h |
| 120,000 | 83.33 | 18.10 h | 54.31 h | 90.52 h |

These are constant-throughput scenarios, not forecasts. The full-stat scenario rotates between the five selectable stats without wasting focus XP into capped stats; by its end, automatic Vitality has received `5/3` of a single stat's required XP, so it already caps. The Vitality-only column assumes continued eligible combat even if a selected stat is capped. Balanced mode trains three stats concurrently at one third each, not three times the total XP.

At the comparison rate, the six-stat maximum still represents about 181 hours. That is a substantial long-term completion goal and should not gate finishing the campaign. The small existing talent trees will be exhausted much sooner than that endpoint. If playtests show the campaign expects high Combat Level, fix the requirement or progression calibration before claiming the grind target has been met.

Initial coefficient `k = 0.5` is a tuning starting point. If representative measured normalized damage per hour is `N`, then desired focus rate `R_target` requires `k = R_target / N`. Measure across classes, beginner versus mature gear, single-target versus area builds, normal waves, bosses and repeat missions. Altering `k` is a deliberate progression rebalance; do not silently reinterpret already banked XP.

## Persistence and acceptance checks

Pending stat XP, selected training focus, enemy remaining reward budgets and fractional residue belong to the attempt snapshot. Bank earned XP on victory or defeat through the same once-only attempt transaction; failure must not erase legitimate damage progress. Preserve existing save-write rollback behavior. Abandon/exit and interrupted attempts need an explicit, tested settlement policy; they must not replay the same earned damage repeatedly.

Before claiming this progression is complete, verify:

1. All 99 thresholds increase strictly; anchors include levels 1, 2, 50, 92 and 99. Exact-threshold and one-unit-below tests agree.
2. Fresh profiles show six `1/99` stats, Combat 1 and zero new points. Old saves retain exact unlocked-node ownership once.
3. Ordinary, boss, overkill, front-mitigation, zero damage, burn, area and turret hits honor one reward budget per enemy. Healing and reload cannot refill that budget.
4. Balanced plus Vitality conserves the intended pools; fractional tick chunking and checkpoint resumes do not change credited totals. Capped focus still gives uncapped Vitality its share.
5. Victory, defeat, restart and repeated banking cannot lose or duplicate already settled XP or points. Failed writes restore the previous profile state.
6. Practice/benchmark modes award no permanent XP. Expedition pickups still produce only expedition draft progress.
7. Every bonus is zero at 1 and bounded at 99; damage components receive their modifier once. Active-run values remain unchanged while the next expedition receives earned bonuses.
8. The rendered training controls, six progress bars, permanent Combat Level, expedition level, talent balance and result XP report agree after reload. Arithmetic tests are not UI acceptance.
9. Log actual focus XP/minute, Vitality XP/minute, normalized damage, kills, boss time and noncombat time for representative complete runs. Replace scenario assumptions with measured distributions before promising a duration.

No runtime files were changed by this balance-document task. Arithmetic was independently evaluated for the milestone table and cap calculations; gameplay pacing remains a measurement task.
