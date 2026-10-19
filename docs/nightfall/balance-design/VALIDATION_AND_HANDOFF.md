# Validation receipt, limits and implementation handoff

**This package is a design proposal. No gameplay code, production definitions, save data, art, purchase configuration or executable balance tooling was changed by this design task.** The calculation commands used ephemeral Python stdin and wrote only documents/tables/receipts. The parent delivery owns source control and any future implementation decision.

## What was actually calculated

The local arithmetic audit executed **15,742 assertions with zero failures**, followed by720 class-gate/EHP/TTK checks after correcting Zone2 Bastion to use Engineer before Warden unlocks. `calculation_receipt.json` records the result, method and table cardinalities. It checks authored numbers and references; the assertion count is not a count of player sessions or game tests.

Verified:

- Twenty unique zone definitions,100 missions,600 wave segments,93 unique item IDs,100 boss joins and complete campaign duration coverage.
- Mission boss HP/heavy-hit formulas and standard/Mission5 Parts grants against their canonical equations.
- All ordinary spawn counts, nonnegative quantities, archetype first-zone gates, valid elite-conversion source counts, elite-adjusted spawn-budget/XP equations and adjacent wave boundaries.
- All300 capture forecasts against cumulative Combat XP thresholds and integer choice budgets.
- All180 build recipes against three-spell/three-passive family limits, three-rank limits and their actual selection counts; physical/mixed EHP and signature TTK arithmetic.
- All20 independent economy snapshots' net currency arithmetic and all20 sequential ledger rows' nonnegative funded wallets.
- Every internal quality score and threshold assignment from its five explicit axes.
- All495 unordered four-armor-slot combinations across nine sets: no accidental3+2 bonuses, at most one three-piece set, legal2+2 combinations.
- All136 tested combinations of raw permanent CDR, Riftweaver and Channel ranks: permanent15%, combined30%, maximum frequency multiplier1/0.70.
- All56 three-spell family combinations for shared-pair selection cost; six can use Frost/Ground's shared Vital Reserve to evolve three spells in eleven choices. That exception is recorded rather than hidden by an incorrect blanket rule.

Parent review independently caught and prompted correction of two prose examples: starter70/30 mixed EHP is242.06, and210 HP survives seven34-raw physical hits but not an eighth. A tabulated37-raw hit becomes exactly30 after starter armor, so the seventh is lethal and only six are *survived*. The hit-tolerance formula explicitly handles exact division. The Zone6 optional reward example was also corrected to390 Credits/6 Parts→488/8 at25% half-up rounding.

## Exact boundary evidence

After the class-gate correction, the parent independently passed 4,865 additional checks over the final 25 CSV tables (2,318 rows): receipt cardinalities, wave boundaries/counts/gates/elite budgets/XP, player EHP/TTK and Warden access, all quality scores/grades, economy net arithmetic/nonnegative funded wallets, and local Markdown links. These remain document arithmetic checks, not engine or human playtests.

`boundary_checks.csv` contains three archetypes for each of six milestone boundaries. It holds the previous zone's minimum equipment/Survivor/DPS constant for a throughput stress comparison. It does not carry run spells into the next actual attempt; that attempt earns its own draft again.

Zone5 Mission5→Zone6 Mission1:

- Boss HP drops4,656→3,060, a34.28% drop from signature to introductory captain.
- Ordinary HP changes−0.42% and damage+0.98% relative to the previous finale's ordinary enemies.
- Arrival-to-arrival zone growth is+9.54% HP/+11.08% damage.
- Wave duration rises300→360s, a20% endurance increase, plus the Briarhound lane mechanic.
- Prior minimum Wayfarer throughput49.22 DPS gives62.17s against the new arrival boss if the same end-build throughput is re-earned.
- Equipment cap rises10→12, but Legendary stays unavailable. The comparison uses prior minimum level6 gear, not a newly purchased level12 loadout.

This is a deliberately gradual damage boundary with a meaningful endurance/mechanics change. It is not evidence that the extra minute is fun or survivable on a phone. The15→16 and19→20 checks likewise exclude the new Legendary/Mythic reward as a prerequisite for beating its own gate.

## Stochastic damage exposure:270,000 trials

`stochastic_damage_scenarios.csv` records54 scenarios×5,000 trials, seeded20261019. Each uses the typical target build for one of Zones1/5/6/10/15/20 and one of three archetypes. A Poisson process produces hypothetical *landed-hit opportunities* during the wave and fixed modeled boss duration. Each event is70% physical/30% unresisted elemental; wave hit is14 times the mission damage multiplier, boss hit is the mission heavy value. The global0.45s hurt interval removes too-close events. A surviving player below25% HP can trigger one20% Medkit heal. Death ends exposure.

Scenario inputs are deliberately transparent: Practiced0.006 wave hits/s and0.018 boss hits/s with no clusters; Learning0.014/0.040 with15% chance of a second hit0.6s later; Overwhelmed0.028/0.080 with25% clusters. These names are labels for assumed rates, not calibrated human skill groups. They omit shields, other healing, actual navigation, attack selection, draft randomness, boss phases and DPS lost after taking hits.

At Zone20 under the Learning assumptions, conditional fixed-window survival was24.60% Wayfarer,27.16% Bastion and27.62% Spellweaver. Sampling standard errors were about0.61–0.63 percentage points. **Those percentages are not predicted real clear rates.** Input/model uncertainty is much larger than sampling error. Bastion's larger health buffer partly offsets its longer exposure; Spellweaver's faster kill partly offsets lower defense. The result is useful for detecting gross incoherence, not proving those sets equally enjoyable or choosing a target failure percentage.

The damage CSV includes median and90th-percentile damage accumulated until death/end. Those are truncated by death, so they are not the uncensored total damage an immortal dummy would receive. A mean rate also hides clustered hits; the separate cluster parameter exists specifically because averages cannot prove burst safety. The worst legal event combination still requires deterministic geometry and simultaneous-hit tests.

Do not tune an individual's enemy health or attacks to make their observed wins match this table. No hidden forced losses, dynamic ad pressure or purchase-dependent success probability belongs in this design.

## Stochastic chest experiment:6.4 million openings

`loot_simulation.csv` records20,000 independent80-opening cohorts in each of four bands, seed20261020. Each opening draws the published raw odds, then applies the shared Rare/Epic/Legendary guarantee precedence. Each cohort starts with fresh pity counters. Family/category/affix draws and campaign gate transitions are not modeled in this experiment.

| Band | Median first Epic-or-better |90th percentile | Legendary result |
|---|---:|---:|---|
| Zones1–5 |30|30|Unavailable |
| Zones6–10 |10|30|Unavailable |
| Zones11–15 |5|16|Unavailable |
| After Zone15 clear |4|13|First Legendary median23,90th percentile76, guarantee80 |

Early Epic frequency including pity was about3.884%, versus the raw advertised2% natural draw. This is not a contradiction: guarantees increase the realized rate. UI odds must distinguish base probability from the guarantee rather than presenting the simulation rate as every independent opening's odds. A30-opening Epic guarantee does not guarantee a weapon, matching set, desired affix or three merge copies.

The100 first-clear keys, earned Gems that can purchase64 more, contract keys and daily lane make key acquisition materially faster than videos alone. This package deliberately excludes that random inventory value from the minimum currency-solvency ledger. Next inventory simulation should model the complete legal source pool per zone, family targeting, selected-key categories, merging and salvage; until then a full Rare/Epic matching set is a target profile, not an asserted median drop outcome.

## What remains unproven or deliberately conservative

1. **Current Zone1 boss duration.** Raising700–1,200 HP to1,800–3,000 is a significant proposed retune. Ship nothing from this table until measured current damage uptime and human feel support it. Retain an explicit old/new comparison build.
2. **Spatial wave throughput.** Group DPS is a proxy. The packet/entity/attack caps are requirements, not proof that a real phone viewport always has a safe path or that all scheduled bodies spawn.
3. **Draft attainability.** Recipes are legal but conditional. Run the actual draft generator and fallback policy over full attempts before treating the named recipes as commonly available.
4. **Rare-set acquisition.** The typical target assumes useful matching equipment; the baseline money ledger does not buy all targeted crafts. Minimum builds deliberately exclude sets. Targeted materials/stamps need full inventory simulation and human pacing review.
5. **Survivability extremes.** Shields, Aegis, Sanctuary, Emberleaf and class mastery are excluded from baseline EHP/simulation. Their interactions need deterministic long-fight tests; exclusion is conservative but cannot prove a defensive immortality loop is impossible.
6. **Low-grade niches.** Four E-grade equipment families need convincing use cases. A poor general grade is not license for unhelpful loot. Ironwatch/Medkit's high scores may indicate overly reliable defaults; compare meaningful collection/tempo utility before raising damage sets.
7. **Side-mode yields.** Three-and-a-half-minute contract time is an assumption including menus. The22 supplemental wins are arithmetic at those rewards, not an empirical time-to-completion estimate.
8. **Legacy ownership.** New source gates must preserve saved items and visibly handle old out-of-band gear. Current Profile version 4 adds daily rewards to the implemented version-3 equipment slice; future tables are not a save-migration specification.
9. **Damage-type migration.** Current broad armor behavior differs from the proposed physical/elemental pipeline. Revalidate every enemy attack and defensive build when that engine change is separately authorized.
10. **Daily acceleration.** The parent implementation's daily calendar/objectives are a meaningful early Parts/key boost. They are excluded from required progression; verify no reward is issued twice and no delayed claim resets its source receipt.

## Human and engine acceptance before promoting any zone

Use existing engine tests for rules, then actual complete home→mission→boss→reward→next mission journeys. Test the first attempt with exact starter40/210/35; an unlucky minimum loadout; typical target; strong earned cap loadout; three class/build routes; one deliberately bad draft; no shrine buffs; no structures; and no ads/rescue. Report build/version, equipped IDs, permanent stats, draft sequence, seed, device/viewport, and observed outcome separately.

Proposed acceptance criteria:

- Every required heavy response is reachable at base movement with Dodge unavailable; slow-floor cases still have a route. No unavoidable transition damage or offscreen attack.
- Typical measured boss median falls within45–120s early,60–150s late; defensive outliers may take longer without a hidden enrage. Strong builds can be faster without ignoring every mechanic.
- At least three distinct build routes can clear each milestone without a purchased/exclusive item. Do not require equal clear percentages; record tradeoffs in hit tolerance, kill time, collection and reward retention.
- Intro missions reliably teach a new threat before combining it with another. Repeated failure should expose a readable mistake or transparent investment path, not demand an ad.
- Minimum builds can earn persistent progress on defeat; required progression remains possible without daily attendance or optional monetization.
- No boss summon/phase/restart loop creates infinite XP, materials, invulnerability, damage procs or repeated once-per-run utility.
- Surviving to countdown zero without killing the boss never clears. Killing the boss does clear, including the defined same-tick lethal ordering.
- All caps and local item/skill/rarity gates agree across previews, crates, rewards, crafting, merging, equip and restore.
- The lower-end target phone sustains the agreed frame budget at capped bodies/projectiles/structures; numerical correctness does not substitute for device performance.

Release content in bounded batches: first run the old/new Zone1 comparison, then Zone2 to prove repeatable content authoring, then Zones3–5, the explicit5→6 boundary,10-zone,15-zone and full20-zone passes. This package supplies the initial numbers and identities for those passes; no test count here replaces them.
