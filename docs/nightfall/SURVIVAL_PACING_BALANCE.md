# Survival pacing and class progression revision

October 19, 2026 numerical contract for the requested slower hero, escalating four-minute waves, larger world, slower progression and substantial class talent trees. The tenfold per-enemy XP reduction and custom curve below are implementation-team tuning decisions, not exact multipliers specified by the user. This revises the initial contract in [COMBAT_PROGRESSION_BALANCE.md](COMBAT_PROGRESSION_BALANCE.md). Values marked **recommended** remain tuning proposals; arithmetic tables are calculations, not simulations or observed completion rates. Implementation and rendered acceptance remain separate work.

## Recommended implementation values

| Quantity | Inspected baseline | Recommended revision |
|---|---:|---:|
| Ordinary full-body focus XP | 24 | **2.4** |
| Boss full-body focus XP | 240 | **24** |
| Vitality XP | One third of earned focus pool | Retain one third; no duplicate pool per Balanced recipient |
| Per-stat cumulative XP at 99 | 2,172,405, reference curve divided by six | **211,706** under the custom curve below |
| Hero ordinary speed | 125 px/s | **80 px/s**; profile permanent speed capped at **1.15 times**, with separate run/field modifiers and final run movement cap |
| Dodge speed | 520 px/s | **360 px/s**; retain duration/cooldown and invulnerability rules |
| Wave duration | 240 seconds | 240 seconds |
| Arrival rate | Four interval steps, 1.4 to 0.6 seconds before mission pressure | Smooth rate from `pressure/1.4` to **5 times that initial rate** |
| Ordinary HP within round | Fixed by archetype | **1.00–1.65 times** archetype HP |
| Ordinary walking speed within round | Fixed by archetype | **1.00–1.40 times** archetype speed |
| Ordinary outgoing damage within round | Fixed by attack | **1.00–1.35 times** attack damage |
| Enemy hard limit | 120 | **Keep 120**, including the boss |
| World side | 1,200 px | **2,400 px**, four times total world area |
| Altar interaction radius | 60 px | Implemented **145 px** for shop/relic altars, centered at `site.pos + (0,70)`; caches remain 60 px at `site.pos` |
| Permanent tracks | Shared six-stat dictionary | **Separate six-stat dictionary for each class** |
| Normal talent entitlement | Combat Level minus one: maximum 98 | **Combat Level: maximum 99**, including one starting point |
| Tree capacity | Rejected draft: **130** ranks per class | **136 Scavenger / 140 other classes** in the replacement [class branch design](TALENT_BRANCH_BALANCE.md) |

Do not stack a fivefold multiplier on top of the old late-wave interval. That would produce a final rate 11.67 times the initial 1.4-second baseline before differences in mission pressure. The recommended curve replaces the interval schedule; the existing 45/100/165-second wave boundaries continue to change enemy composition.

## Bounded four-minute ramps

Let `t` be elapsed combat simulation time, excluding pauses and selection screens:

```text
u = clamp(t / 240, 0, 1)
q = u*u*(3 - 2*u)
arrival_rate(t) = mission_pressure / 1.4 * (1 + 4*q)
spawn_interval(t) = 1 / arrival_rate(t)
ordinary_hp_multiplier(t) = 1 + 0.65*q
ordinary_walk_multiplier(t) = 1 + 0.40*q
ordinary_hit_multiplier(t) = 1 + 0.35*q
```

All ramps start and end with zero slope and stop growing at 240 seconds. Sample an enemy's factors when it spawns and persist them. Existing enemies must not heal, gain reward budget or become faster every frame as the clock advances. Record original scaled spawn HP for normalized XP accounting. The recommendations increase encounter pressure without shortening reaction windows.

| Time | Smooth progress `q` | Mission 1 arrivals/s, pressure 0.85 | Cumulative scheduled arrivals, Mission 1 | HP factor | Walk factor | Hit factor |
|---:|---:|---:|---:|---:|---:|---:|
| 0 s | 0 | 0.607 | 0 | 1.000 | 1.000 | 1.000 |
| 60 s | 0.15625 | 0.987 | 44.40 | 1.102 | 1.063 | 1.055 |
| 90 s | 0.31641 | 1.376 | 79.62 | 1.206 | 1.127 | 1.111 |
| 120 s | 0.5 | 1.821 | 127.50 | 1.325 | 1.200 | 1.175 |
| 180 s | 0.84375 | 2.656 | 262.97 | 1.548 | 1.338 | 1.295 |
| 240 s | 1 | 3.036 | 437.14 | 1.650 | 1.400 | 1.350 |

The cumulative count is the continuous-rate integral:

```text
scheduled_arrivals(t) = pressure/1.4 * [t + 4*(t^3/240^2 - t^4/(2*240^3))]
scheduled_arrivals(240) = pressure * 514.285714...
```

Discrete tick timing and a possible initial immediate spawn introduce small differences. Occupancy caps can reduce actual spawns substantially. These values are not kill counts. Mission 5's pressure 1.25 produces approximately 642.86 scheduled arrivals, versus Mission 1's 437.14. Maximum rates are respectively 4.464 and 3.036 per second.

For comparison, the inspected Mission 1 schedule integrates to `0.85*(45/1.4 + 55/1.05 + 65/0.8 + 75/0.6) = 247.16` arrivals. The revised schedule has **1.769 times as many scheduled bodies per round**, despite its final rate being five times its own opening rate. At a tenth of the XP per body, total scheduled regular-enemy focus XP is about **17.69% of the previous schedule**, assuming every body is killed in both cases.

### Enemy endpoints and damage coverage

| Enemy | Opening HP → final-spawn HP | Opening speed → final-spawn speed | Representative attack endpoint |
|---|---:|---:|---|
| Drifter | 48 → 79.2 | 32 → 44.8 px/s | Contact/swipe 10 → 13.5 |
| Runner | 32 → 52.8 | 56 → 78.4 px/s | Pounce 8 → 10.8 |
| Spitter | 40 → 66 | 24 → 33.6 px/s | Projectile 12 → 16.2 |
| Scrap Bulwark | 88 → 145.2 | 26 → 36.4 px/s | Contact/cleave 18 → 24.3 |
| Rift Hexer | 52 → 85.8 | 30 → 42 px/s | Contact 10 → 13.5; each hex projectile 9 → 12.15 |

The spitter's current projectile is authored separately from its contact field. Scaling only `enemy.contact` would leave its main attack unchanged. Apply the spawn hit factor once to each ordinary outgoing attack, including structure damage and hostile projectiles where applicable. A projectile retains its firing enemy's factor; it must not inherit a newer global elapsed-time factor on impact.

The implemented wave expansion adds Bulwarks and Hexers as **ordinary reward-weight-1 enemies**, not three-weight elites. Bulwarks have a front guard against non-elemental damage and a committed cleave. Hexers fire a three-bolt spread at 145 px/s with 9 base damage per projectile; do not mislabel this as one 27-damage unavoidable hit. Their attack packets, hurt protection and avoidance determine actual received damage. Their higher HP does not raise their 2.4-focus-XP body budgets.

Keep ordinary pounce speed/duration, projectile speed, attack cadence and windups unchanged initially. Increasing those simultaneously would multiply the effect of the slower hero and make the damage ramp hard to interpret. Existing pounce windup 0.34 seconds gives an 80 px/s hero 27.2 px of unimpeded movement; at 125 it gave 42.5 px. This is already a meaningful reaction change without altering the tell.

Keep authored bosses outside these ordinary ramps. They enter at 240 seconds, so applying the full ordinary HP/speed/damage factors to every boss would be an additional permanent boss rebalance. Boss HP already varies by mission. Retain existing windups, recovery and attack sequences; individually test the slower hero against each slam/rush pattern. Under a 20% slow, the hero walks at 64 px/s before other bonuses. Dodging must remain a usable answer when walking cannot leave a telegraphed area in time.

Boss reinforcements can use the final ordinary spawn factors, but retain the inspected total cap of 24 and simultaneous cap of six. Their XP remains bounded per body. If the occupancy cap is full, defer the boss briefly or make a specified nonrewarding transition slot; never let the mandatory boss silently fail to spawn. Do not delete a partly damaged enemy and recreate its XP budget through a retry.

### Damage demand and intended survival pressure

The inspected expanded wave composition is:

| Wave start | Drifter | Runner | Spitter | Bulwark | Hexer |
|---:|---:|---:|---:|---:|---:|
| 0 s | 95% | 5% | 0% | 0% | 0% |
| 45 s | 64% | 28% | 8% | 0% | 0% |
| 100 s | 39% | 25% | 18% | 12% | 6% |
| 165 s | 25% | 30% | 20% | 15% | 10% |

At Mission 1's opening, mean scheduled enemy HP is 47.2 and influx is **28.66 HP/s**. At 120 seconds the five-enemy composition averages 47.6 base HP, or **63.07** after its 1.325 ramp, giving **114.88 HP/s**. At the end, mean base HP is 48, or **79.2** after the 1.65 ramp, producing **240.43 HP/s**. Mission 5's final influx is **353.57 HP/s**. These revised numbers supersede the earlier three-enemy composition estimate of 202.36/297.59 final HP/s.

These are scheduled HP-loss demands, not attainable player DPS measurements. Bulwark front mitigation can require additional raw non-elemental damage, depending on facing. The starter pistol's nominal 40 DPS cannot clear the final flow by itself. Area spells, structures, earned upgrades and maneuvering around survivors matter. A complete round is a survival objective; killing every scheduled body must not become an implicit victory requirement. The hard cap prevents unbounded population, but persistent cap saturation is a balancing signal rather than evidence that the wave is playable.

Using the existing 210 HP and 35 armor baseline, the final 13.5 raw physical drifter hit becomes approximately 10.95 after armor alone. Nineteen such isolated hits are survivable; the twentieth is lethal without healing or other damage. This is a single-attack arithmetic example, not a projected survival time in a crowd. Simultaneous attacks, hurt protection, elemental treatment, shields and actual dodge execution must be evaluated separately.

## Larger world, slower traversal and larger altars

Doubling both world dimensions gives exactly four times total area. The inspected walkable bounds are `Rect2(135,135,930,930)`, not the full 1,200-square world. Two valid geometry choices have different outcomes:

| New walkable bounds | Walkable area relative to old | Straight-line side traversal at 80 px/s |
|---|---:|---:|
| `Rect2(270,270,1860,1860)` | Exactly 4.00 times | 23.25 s |
| `Rect2(135,135,2130,2130)` | 5.246 times | 26.63 s |

The selected implementation doubles the inset to 270 and doubles authored landmark positions, giving an exact fourfold walkable-area interpretation. The original 930-px side took 7.44 seconds at 125 px/s; the new side takes **3.125 times longer**, combining distance and movement changes. Obstacle paths take longer still. Keep a reachable shrine near the starting route rather than requiring a long empty journey before the player can interact with the new landmark.

The implemented shrine interaction radius is **145**, superseding the initial 120 recommendation. Its area is `(145/60)^2 = 5.8403` times the old interaction area. The ring and interaction predicate share the center **`site.pos + Vector2(0,70)`**; caches keep their 60-px radius and unshifted `site.pos` center. Collision footprint, visible art and interaction ring need separate values so large decorative art cannot trap the hero. Base shop/relic charge times remain two/seven seconds before eligible interaction-speed talents. Walking across the new 290-px altar diameter takes **3.625 seconds** at base speed, so relic collection still requires deliberate lingering or circling.

Keep enemy spawning local, around a **330–420 px annulus** from the hero, with the current minimum safety distance enforced after boundary correction. Do not simply double the spawn distance because the map doubled: that would add empty travel time and could make the new arrival schedule invisible. Preserve attack ranges initially: pistol 225, scattergun 170, crossbow 290, wand 210 and sabre 80 px. Larger terrain should not silently double weapon reach, spell radius, targeting or pickup range.

## Population, rendering and frame-time limits

**Recommend retaining the hard limit of 120 enemies** rather than multiplying it by five. Arrival frequency and concurrent population are different quantities. A tentative soft crowd target is 96, leaving headroom for a boss and its limited summons. An implementation can stop ordinary arrivals at that target or taper admission above it; it must document which behavior it uses. Skipped arrivals must not accumulate into a sudden catch-up burst after kills or pauses.

The inspected enemy deformation mesh uses 63 vertices and 96 triangles per enemy. At 120 visible enemies this is 7,560 vertices and 11,520 triangles before bosses and effects; 600 enemies would require 37,800 vertices and 57,600 triangles. More consequentially, 64 player shots checked against 120 enemies can require 7,680 candidate hit checks per tick; at 600 enemies this rises to 38,400, before area effects, movement and rendering. These operation counts explain the bounded recommendation; they do not predict FPS on a particular device.

Measure frame-time distributions at 30/60/90/120 live enemies with representative shots, burning, spells, structures, enlarged altars and world art. A 60-FPS target corresponds to 16.67 ms/frame; a 30-FPS fallback corresponds to 33.33 ms/frame. Use recorded p50/p95/p99 frame times, not a single average FPS counter. Cull offscreen world decoration; avoid scaling texture work with all four times the map area every frame. Existing projectile/effect bounds must remain enforced, and damage/XP must remain independent of a dropped visual effect.

## Permanent XP, early levels and long-term grind

Retain the prior normalized damage rule, lower its focus coefficient from 0.5 to **0.05**, and replace the earlier reference thresholds with the custom curve below:

```text
rewardable_damage = min(actual_post_mitigation_HP_damage, remaining_rewardable_HP)
focus_xp = 0.05 * rewardable_damage * (48 * enemy_weight / spawn_max_HP)
enemy_weight = 1 ordinary, 10 boss
vitality_xp = focus_xp / 3
```

Thus full ordinary and boss budgets become 2.4 and 24. Enemy HP growth cannot inflate those budgets. Full precision, overkill exclusion, one-time banking, practice/benchmark exclusion and the separation from expedition pickup XP all remain required.

### Chosen custom threshold curve

For current integer stat level `n` from 1 through 98:

```text
cost(n -> n+1) = round(60 + 10*n^1.35)
threshold(L) = sum[n=1..L-1](cost(n -> n+1))
threshold(1) = 0
threshold(99) = 211706
```

Round each positive per-level cost to the nearest integer, with halves upward; then sum those integer costs. The first increase costs **70 XP**, compared with the old 13; the last increase costs **4,937 XP**. This deliberately slows early stat advancement while removing the old exponential endgame grind. Do not divide the resulting thresholds by six again. It is a Nightfall-specific polynomial curve, not a faithful RuneScape curve or a verified training-time ratio.

| Stat level | Cumulative XP | Focused minutes at 100 XP/min | Focused minutes at 200 XP/min |
|---:|---:|---:|---:|
| 1 | 0 | 0 | 0 |
| 2 | 70 | 0.70 | 0.35 |
| 3 | 155 | 1.55 | 0.78 |
| 5 | 384 | 3.84 | 1.92 |
| 10 | 1,382 | 13.82 | 6.91 |
| 20 | 5,713 | 57.13 | 28.57 |
| 30 | 13,843 | 138.43 | 69.22 |
| 40 | 26,376 | 263.76 | 131.88 |
| 50 | 43,792 | 437.92 | 218.96 |
| 60 | 66,492 | 664.92 | 332.46 |
| 70 | 94,834 | 948.34 | 474.17 |
| 80 | 129,130 | 1,291.30 | 645.65 |
| 90 | 169,667 | 1,696.67 | 848.34 |
| 99 | 211,706 | 2,117.06 | 1,058.53 |

The supplied baseline observation was **81 kills in 90 seconds and Combat Level 8** under the previous reward settings. This document has not rerun that journey; it treats it as a reported measurement. Holding those 81 ordinary kills fixed, the revised award is 194.4 focus XP and 64.8 Vitality XP:

| Training focus | Result from a fresh class track after those 81 kills | Combat Level |
|---|---|---:|
| Ranged | Ranged 3, Vitality 1, other four stats 1 | **1** |
| Balanced | Attack/Strength/Defence/Vitality 1, Ranged/Magic 1; trained stats have 64.8 XP each | **1** |

This comparison isolates the XP change. It does not assume the slower hero, stronger enemies and revised arrival schedule still permit 81 kills. The continuous arrival curve schedules only about 79.62 bodies by 90 seconds before discrete timing, occupancy or kills, so actual new XP can be lower.

For a complete Mission 1 wave, the following **illustrative kill-completion scenarios** apply percentages to the 437.14 continuously scheduled ordinary bodies and add one fully damaged boss:

| Scheduled bodies killed | Total focus XP including boss | Ranged focus: Ranged / Vitality / Combat | Balanced focus: each trained stat / Combat |
|---:|---:|---|---|
| 60% | 653.49 | 6 / 3 / **2** | 3 / **2** |
| 80% | 863.31 | 7 / 4 / **2** | 4 / **3** |
| 100% | 1,073.14 | 8 / 4 / **2** | 4 / **3** |

These percentages are not empirical success rates. Caps, partial damage to living enemies, attack mitigation, boss duration and expedition downtime change the outcome. Percentage-of-bodies calculations also ignore varying HP costs. A nominal first-round investigation band is **100–200 focus XP/minute**, permanent Combat **1 around 90 seconds**, and Combat **2–3 after a first successful expedition**, depending on training choice. Treat these as playtest targets, not automatic rewards. Visible fractional/stat progress and ordinary expedition upgrades carry the early feedback. The first useful permanent talent choice exists immediately because the revised 99-point model supplies a starting point.

### Long-term pacing and the discarded exponential curve

Under the chosen custom thresholds:

| Focus XP/minute | One focused stat to 50 | One focused stat to 70 | One focused stat to 99 | Five selectable stats to 99, with automatic Vitality capped |
|---:|---:|---:|---:|---:|
| 100 | 7.30 h | 15.81 h | **35.28 h** | **176.42 h** |
| 200 | 3.65 h | 7.90 h | **17.64 h** | **88.21 h** |

The table assumes constant throughput and efficient switching away from capped stats. It excludes menu time unless that time is already included in the measured XP/minute. Balanced divides one pool among three stats; it does not triple progress. Separate class tracks make these totals **per class**. Completing all four classes would multiply the workload approximately fourfold if their rates matched.

The earlier exponential thresholds combined with 2.4 XP per ordinary body would instead require **181–362 hours for one stat**, or **905–1,810 hours for all five selectable stats plus automatic Vitality per class**, at these same rates. That arithmetic motivated the custom curve. The new Mission 1 theoretical all-body wave budget gives only about 268 focus XP/minute before extra boss time, so the original assumption of 1,000 XP/minute was unsuitable for the revised awards.

The selected curve produces a focused 99 in roughly 18–35 hours across the investigation band and does not require an extra campaign-XP reward. Do not claim a universal sixfold speedup versus another game. Measure actual class/build rates and total session downtime before making a public duration promise. The all-class completion horizon remains substantial, and campaign completion should not require every stat or every class at 99.

The chosen threshold migration preserves each existing stat's level and fractional progress within that level. For old level `L < 99`, calculate `f = clamp((old_xp - old_threshold(L)) / old_cost(L), 0, 1)` and set `new_xp = new_threshold(L) + f*new_cost(L)`. For old level 99, set exactly 211,706. Preserve fractional precision; do not promote a below-threshold value through per-stat integer rounding. Update the save version once and test migration idempotency. This threshold conversion is separate from deciding ownership when splitting an old shared track into class tracks.

## Class-specific ownership and exactly 99 points

Each class owns its six XP totals, selected training focus, derived Combat Level and purchased talent ranks. Lock the earning class at expedition start and snapshot it; a class switch in Haven cannot redirect completed or pending XP. Inactive classes do not inherit another class's new progress. Survivor progression, equipment and account currency remain separate systems unless another requirement changes them.

```text
class_combat = floor(sum(the class's six stat levels) / 6)
normal_class_points_earned = class_combat
normal_class_points_available = normal_class_points_earned - sum(purchased ranks)
```

At level 1 a class has **one starting point**; each of the 98 gained Combat Levels supplies one more, totaling **99 at Combat 99**. This explicitly replaces the previous zero-at-start/98-total rule. Points are not shared or multiplied by switching classes. A rank normally costs one point. A class unlock can expose its starting point without granting levels to it.

Migration is a separate accounting requirement. The old global XP dictionary cannot reconstruct which class earned every historic hit. Choose and document a one-time policy before migration; do not present invented per-class history as recovered data. Preserve old unlock ownership through explicit rank mappings or a separately labeled legacy allowance. If legacy allowances permit more than 99 spent points, describe 99 as the normal earned cap and disclose the legacy exception; do not claim a strict total spending cap. Repeated migration or reload must never create another allowance.

## Ranked talent tree budget

**Superseded:** the 129-point layout below was an earlier mathematical proposal. The rejected implemented grid actually totaled 130 ranks: five spell unlocks plus twenty-five five-rank generic nodes. Neither is the replacement design. Follow [TALENT_BRANCH_BALANCE.md](TALENT_BRANCH_BALANCE.md) and its exact node data instead: three thematic fork/merge branches, 136 possible purchases for Scavenger, 140 for each other class, and the same 99-point normal budget. The old branch-local gates and capstone restriction in this historical section are not current requirements.

A concrete bounded layout is **three branches with eleven nodes each**, using per-branch maximum ranks:

```text
[5, 5, 3, 5, 3, 5, 3, 5, 3, 5, 1]
sum = 43 points per branch
3 branches * 43 = 129 available ranks per class
129 - 99 = 30 ranks left unpurchased at the normal point cap
```

This exceeds the budget enough to require real choices while supporting one-rank capstones and three-/five-rank incremental talents. Use branch-local spending gates `[0,0,5,5,10,10,15,20,25,30,35]` and a visible one-rank prerequisite in the preceding node after the initial row. Validate that the player can reach each gate with earlier legal nodes. Do not require every preceding node to be fully ranked unless that restriction is intentional and shown.

Each capstone needs 35 points already spent in its own branch and costs one point itself. Three capstones therefore require at least `3*36 = 108` points, exceeding 99: a normal capped character can reach at most two. All three full branches require 129, so a player cannot buy everything. Free point reallocation, if implemented, must run as one atomic legal-tree transaction outside an active expedition and must not refund the same rank twice.

Rank count alone is not meaningful depth. Give branches distinct purposes, for example weapon reliability, survival/positioning and class mechanics. Rank-1 descriptions must state the gain per rank and the cap. Preserve current spell availability unlocks through explicit nodes; do not give one character dozens of simultaneous unbounded global damage multipliers.

Recommended **whole-tree incremental power ceilings** for the first pass, beyond existing combat-stat bonuses, are +20% basic weapon damage, +20% elemental damage, +15% maximum HP, +10 flat armor, and +10% movement before the existing movement cap. These are envelope limits for combinations, not bonuses for every node. Cooldown, resistance and critical effects must remain inside existing combined caps. At most one new major triggered class behavior should be active per relevant event; damage from a proc must not recursively trigger itself.

For scale, +20% talent weapon damage on the previous maximum stat-based mean basic multiplier of 1.47 gives 1.764, not an unlimited multiplicative chain. +20% talent spell damage on 1.30 gives 1.56. Maximum stat HP/Defence effective-health factor 1.5294 combined with +15% talent HP gives about 1.7588 before the additional armor, class, equipment and run effects. These calculations define screening bounds; complete legal builds still need comparison against fresh builds and boss telegraphs.

## Validation required before claiming the revision balanced

1. Record old/new runs with fixed seed, class, gear, training focus and input route. Compare 90-second kills, XP, Combat Level, damage taken, local enemy count and frame-time distributions. A change in XP coefficients is not proof of the combined experience.
2. Log scheduled, admitted, skipped, live and killed enemies separately. Verify final arrival rate is five times the opening rate at equal pressure, not five times the old final rate. Confirm no catch-up burst after cap saturation or a pause.
3. Verify exact ordinary HP/speed/hit endpoints, including spitter projectiles, structures and partial-damage rewards. Reload must preserve each enemy's spawn factors and remaining reward budget.
4. Walk the doubled map at the new speed. Check collision boundaries, nearby shrine access, all relocated sites, altar art/rings, cache radii, camera edges, targeting range and local spawn safety.
5. Test every boss with the slower hero and ordinary wave survivors. Confirm readable dodge routes, finite reinforcements and mandatory boss admission. Do not increase boss speed because an ordinary speed ramp exists.
6. Verify per-class XP and talent isolation, 1 starting point, 99 normal maximum points, one-point rank costs, legal gates, capstone restrictions and once-only save migration. A second class should not receive the first class's pending XP.
7. Verify expedition draft levels remain independent. More enemy bodies also produce more pickups; measure whether the temporary level-12 cap is reached too early. Lowering permanent XP alone does not slow expedition spell drafting.
8. Measure economy effects: more kills can create more Survivor XP, mastery XP, Credits and scrap under existing kill rewards. Decide those rates deliberately; do not assume the permanent-XP cut also reduces other payouts.
9. Retain fail/write rollback, idempotent bank, defeat XP, practice/benchmark exclusion, fractional chunking and capped-stat behavior from the original progression tests.
10. Only after measured results, revise the proposed arrival/HP/hit coefficients or permanent training targets. Report simulation evidence, rendered evidence and human play evidence separately.

This task changed documentation only. All rate integrals, threshold conversions, level outcomes and operation counts above were calculated directly; no new survival simulation or FPS benchmark was run for this document.
