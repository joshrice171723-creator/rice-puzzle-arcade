# Campaign balance model

This is the numerical spine for the future campaign. The model starts at the actual eight-slot baseline: **40 Power, 210 HP, 35 armor**, before a class, run upgrade, buff or affix changes it. All later encounters are proposals. Values in CSV files are expanded instances of the formulas here and in `formula_registry.csv`.

## Units, order and rounding

Damage, HP, armor, XP and currency have different units. Armor 35 is not 35% reduction. Percentages in machine tables are fractions unless explicitly called percentage points. A 3-point critical-chance bonus adds 0.03, not 3% of existing critical chance. Distance is meters; proposed ordinary player speed is 4 m/s. Converting to world pixels must use one project-wide scale, not a per-enemy scale.

Compute primary stats and damage in full precision. Round authored enemy HP/hits and currency grants half upward to integers once at the content boundary. Keep player-stat and DPS CSV display values to two decimals; compute TTK from unrounded intermediates. Never repeatedly round equipment components or per-frame damage. XP can be fixed-point hundredths; award the exact weighted kill value, then compare the accumulated total with integer thresholds. Healing and shields use full precision internally. Item costs round upward after discounts. A floating-point comparison tolerance of 0.02 is reasonable for displayed HP/DPS; it is not permission to tolerate a wrong integer cost.

Stat order:

1. Character base HP, equipment level/rarity primary values, item-local percentage affixes.
2. Add flat armor/accessory bonuses; calculate set eligibility from equipped Rare-or-higher armor only.
3. Apply whole-character class and set HP multipliers. Warden ×1.10 and Ironwatch ×1.06 multiply; they do not also apply separately to each item.
4. Apply run HP additions in one sum: `1 + 0.08×Vital Reserve rank + 0.10×Vitality rank + 0.12 if Moonstone`.
5. Aggregate permanent speed, pickup, cooldown, crit and resistance, then apply permanent caps.
6. Apply run effects and their documented combined caps. Damage-type mitigation is selected once per damage component.
7. Apply shields, then HP loss. No recursive proc, hit, shield or damage loop.

## Zone and mission growth

For zone `z`, let `n=z−1`:

`H(z)=1+0.13n+0.002n²` and `D(z)=1+0.16n+0.003n²`.

For mission `m`, ordinary HP/hit modifier is `M(m)=1+0.025(m−1)`. Thus an ordinary Drifter in Zone 6 Mission 5 has `round(48×1.7×1.1)=90 HP` and `round(10×1.875×1.1)=21 hit`. Speed does **not** scale by zone. Difficulty comes from learned combinations, counts, spacing and damage, not indefinitely faster enemies.

Captain base HP by mission is 1,800 / 1,980 / 2,160 / 2,340; signature HP is 3,000. Multiply only by `H(z)`, since mission position is already represented in those five bases. A signature reaches 12,576 HP at Zone 20. Boss standard-hit base is 22, heavy-hit base 34, multiplied by `D(z)×M(m)`. Multi-projectile attacks share one damage-event group: overlapping pellets cannot multiply the same listed hit on one player.

Four-minute waves in Zone 1, five minutes in Zones 2–5, six thereafter. Mission 1 introduces the zone's threats, Mission 2 emphasizes flankers, Mission 3 ranged/support units, Mission 4 armor, Mission 5 the combined ecology. Counts and caps are fixed in the wave table, not secretly raised when a player is succeeding.

## Player growth and equipment ceilings

Character base HP is `120+4(SurvivorLevel−1)`. Level 40 reaches 276. A complete starter loadout adds 90 HP and 35 armor. Weapon Power is 40 before scaling; the gadget adds no Power, HP or armor. The new Ring and Pants budgets are already included in those totals.

`Q(L,R)=[1+0.05(L−1)]×R` scales each item's base primary stats. Rarity multipliers are 1.00 / 1.04 / 1.08 / 1.12 / 1.16 / 1.20. Tempered modifies only weapon Power; Reinforced modifies only its item's HP; Plated modifies only its item's armor. One rank-3 Reinforced ring does not add 8% to the character's entire HP.

Equipment level ceiling uses the **highest legitimately unlocked zone**, not a preview, selected replay or purchased item: `min(30,4+z+floor(z/3))`. Examples are 5, 10, 12, 17, 24 and 30 at Zones 1, 5, 6, 10, 15 and 20. A level-30 Mythic weapon reaches 117.6 Power before Tempered, 124.656 with rank-3 Tempered. This is an endgame upper bound, not a starter purchase option.

Survivor level and equipment level are separate. The future family minimum Survivor requirement is `1+floor((firstZone−1)/2)`, at most 10 for the last families. The first-clear progression forecast reaches each requirement before its zone; it is an anti-bypass condition, not an extra grind wall. Acquiring a family still requires the campaign/source gate even if a player farms Survivor level 40 in Zone 1.

## What the three investment tiers mean

The 180 rows in `player_builds.csv` are **end-of-zone Mission 5 targets**. Zone 1's Bastion can use Engineer because Mission 4 has already been cleared. They are not legal loadouts for a new account's first mission. The separate entry-boundary table uses the preceding zone's earned loadout.

| Tier | Equipment | Survivor XP assumption | Field XP captured | Boss contact fraction before archetype modifier |
|---|---|---|---:|---:|
| Minimum | Level `cap−4`, at least 1; Common in Zone 1, Uncommon through 5, Rare through 15, Epic later; no tuned affixes or set bonus assumed | Previous-zone first-clear-plus-field XP | 60% | 60% |
| Typical target | Level `cap−2`; Rare through 5, Epic through 15, Legendary later; rank-1 useful affixes | Current-zone first-clear-plus-field XP | 78% | 77% |
| Strong earned | At equipment cap; Epic through 15, Legendary later; selected rank-3 affixes | 1.5× current-zone XP | 90% | 88% |

These tiers intentionally vary both investment and execution. They are **not percentiles measured from players**. “Typical” means a design target, not a claim that random loot on a first pass gives a full matching set. Targeted contracts/crafting can be needed; the acquisition analysis quantifies that separately. A pure skill comparison must hold gear constant and vary contact/capture, as the sensitivity checks do.

Affixes fit real slot limits. Typical Rare gear puts Tempered on the weapon; Reinforced on Head, Chest and Pants (70 base HP total); Attuned on Boots, Pendant and Ring; Seeking on Gadget. At Epic+, a second slot permits broader Reinforced coverage. Strong gear uses Tempered on Weapon, Reinforced on all six HP slots, Plated on the four armor slots, and three rank-3 Attuned allocations across Weapon, Ring and Gadget. Other available slots carry pickup/utility. This avoids assuming eight simultaneous maxed affixes on a one-affix item.

## Three viable build routes

**Wayfarer:** Scavenger, Service Pistol or a normalized ranged weapon, Outrider armor, Medkit. Ember/Frost/Chain are all starter-eligible. Higher ranks favor focused Ember/Chain; Vital Reserve and Arcane Focus compete with Magnetic Harness for limited selections. Advantages are pickup, safe positioning, more secured loot and consistent target access. It gives up Bastion's HP/armor and Spellweaver's area coverage.

**Bastion:** Engineer for Zone 1 and Zone 2 final bosses; Warden from Zone 3, after the Zone 2 clear. Engineer's starting Ember/Chain/Wisp pool works without assuming a locked spell. Warden uses Frost/Lance/Ground, Ironwatch and Medkit or Ward Projector after its gate. Vital Reserve, Piercing Shot and spell ranks form the core. It receives more effective HP and shields but has lower contact-adjusted DPS. Structure damage is **excluded** from baseline build DPS so a lost turret does not invalidate the required kill route.

**Spellweaver:** Scavenger's Ember/Frost/Chain until Arcanist is available, then Arcanist's Ember/Frost/Wisp, Riftweaver armor and an unlocked utility gadget. Focus and Channel compete with Vital Reserve. Area coverage and elemental combinations improve, but Wisp requires proximity and Ground-like effects require occupancy. Its HP buffer is lower than Bastion's and it lacks Outrider's secure slot.

`build_recipes.csv` supplies the ordered choices, actual ranks, eligible evolutions and selection counts for every row. Every recipe uses at most three spell and three passive families, and no rank exceeds three. Recipes are target routes through a randomized draft, **not promised draft results**. The draft safeguards and fallback analysis in the skill document are necessary to avoid making a lucky exact sequence mandatory.

No set is asserted to be globally best. The model separates single-target damage, group damage proxy, physical/mixed EHP and collection. A set can outperform on one axis while losing on another. Human testing must still check that pickup/secure utility matters enough to compete with direct damage. “Not Pareto-dominant in this model” is weaker than “balanced in play.”

## Damage throughput and time to kill

The baseline weapon is the normalized Service Pistol: `Power` raw DPS. Proposed basic critical hits add expected factor `1+0.05×(1.5−1)=1.025`. Spell damage uses actual rank/branch coefficients from `ability_ranks.csv`, applicable evolution additions, Focus, class/set bonuses and cooldown reduction. Spell damage does not inherit the weapon crit factor.

Target occupancy is explicit: Frost 75%, Wisp 55%, Ground 65%, other modeled spells 100% when the overall target-contact condition holds. Wisp's 1.1-second shared target-hit interval is not reduced by cooldown. Arcanist's automatic pulse contributes `1.2/16×0.65×1.08` Power/s before overall contact. Bastion's overall contact multiplier is 0.92 and Spellweaver's 0.96 relative to the tier's contact assumption, reflecting their positioning constraints. These are assumptions to replace with telemetry, not observed measurements.

`bossDPS = Power × (1.025 + summedSpellPowerPerSecond + classPowerCoefficient) × contactFraction`.

`TTK = bossHP / bossDPS`. No shield, heal, summon or recovery time is double-counted as extra boss HP. Missing a recovery window lowers measured contact. Front-guard captains require a separate facing mixture; the signature TTK table assumes no generic resistance. A temporary 30% front guard with 40% front-facing damage lowers physical throughput by 12%, not the full 30% for all damage.

The calculated signature ranges across all zones/archetypes are approximately **77–157 seconds minimum, 48–106 typical, 35–84 strong**. Early minimum builds can exceed the desired 90-second experience target. That is a tuning concern, not an invisible timer or automatic failure. Late minimum Bastion is deliberately slower and must retain repeatable safe windows.

The `group_dps_proxy` column multiplies single-target DPS by 1.85 / 2.10 / 2.60 for the three routes. It is a conservative screening assumption for density, **not an exact sum of every AoE target cap**. Full-health throughput cannot prove real wave clearability without collision, aim and target-distribution simulation. Never use this proxy as empirical kills per second.

## Effective HP and hit tolerance

Physical reduction `DR=min(0.50, armor/(armor+150))`; `physicalEHP=HP/(1−DR)`. With a 70% physical/30% unresisted elemental mix, `mixedEHP=HP/[0.70(1−DR)+0.30]`. This is an average damage-mix calculation; a purely elemental barrage bypasses armor entirely.

Starter EHP is 259 physical, 242.06 at the stated mixed damage assumption, before healing. The starter survives seven 34-damage physical heavy hits from full HP (the eighth kills) if all other damage is zero. Endgame heavy hits are deliberately consequential: Zone 20 Mission 5 is 192 raw damage, not a percentage of the player's current HP. Read the build table for exact class/gear tolerance. A fully unresisted heavy hit can be much worse than the displayed physical-hit column.

Medkit's once-per-run 20% recovery raises a long-horizon damage allowance to at most 1.20×HP if it triggers before lethal damage and is not overhealed. It does not guarantee surviving a single oversized hit. Shields and repeated Warden/Frost healing are excluded from tabulated EHP so they cannot silently create an infinite effective-health claim. A conservative incoming damage budget is `HP + actualHeal + absorbedShield − reservedExitHP`; shield potential is not the same as shield actually absorbed.

For physical armor plus Obsidian's 10% and Ward's 10%, combine remaining fractions multiplicatively, then cap total reduction at 65%. At armor cap the result is 59.5%, not 70%. Elemental resistance at its 40% combined cap plus those effects gives 51.4%. Do not apply physical armor again to an elemental hit. Mixed attacks must split into components before mitigation.

## Boundary policy

The explicit boundary table tests Zone 5 Mission 5→Zone 6 Mission 1 rather than comparing unrelated fully upgraded builds. The next zone's arrival boss is less healthy than the preceding signature; ordinary HP and damage rise smoothly. The major new demand is an additional minute of waves plus Briarhound lane control. No Legendary item is introduced to bridge that boundary.

When the level cap jumps by two, enemies must still be beatable with the previous cap. No automatic character rescaling occurs. Test the old gear at new waves, then the new gear to verify a worthwhile improvement. At the 15→16 boundary, Legendary access is a reward after the gate, not a prerequisite for beating the gate. At 19→20, the Night Sovereign must be beatable before receiving its Mythic core.

Zone 1→2 deliberately raises arrival damage 16.3% from the tutorial baseline; compared with the previous signature mission's ordinary damage, the rise is only about5.7%. Other major boundaries remain below15%. Fail the design review if any further new arrival requires more than15% extra ordinary enemy HP or damage over the preceding zone's arrival without an explicit mechanic justification, or if a previous-zone minimum build cannot maintain a reachable safe response. Boss TTK alone cannot determine survival; the packet, crowd, projectile and hazard constraints are equally binding.
