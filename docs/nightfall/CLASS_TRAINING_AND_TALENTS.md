# Independent class training and ranked talents

## Permanent progression

Every class owns six permanent combat skills, a training focus and a talent allocation. Newly created class records start with Ranged focus because the current starter weapon is a pistol. An explicit saved focus is preserved, and changing equipment never silently changes focus. Switching class changes the entire progression record; equipment, campaign progress and currencies still follow the existing shared profile. Damage training follows the selected focus regardless of automatic attack source. Balanced splits its share equally between Attack, Strength and Defence. Vitality additionally receives one-third of the focus XP.

An ordinary enemy awards at most **2.4 focus XP**, distributed by actual health removed as a fraction of its original reward health. A boss awards at most **24**. Existing Run protections against overkill, repeat damage, healing and practice/benchmark awards remain authoritative. HP inflation does not increase the enemy budget. These awards are ten times slower than the previous 24/240 rates.

The cost of skill level `n` to `n+1` is `round(60 + 10 × n^1.35)`, for n=1 through 98. Level 1 starts at zero XP; all skill levels cap at 99. Selected cumulative thresholds are:

| Level | Total XP |
|---|---:|
| 2 | 70 |
| 3 | 155 |
| 5 | 384 |
| 10 | 1,382 |
| 20 | 5,713 |
| 40 | 26,376 |
| 60 | 66,492 |
| 80 | 129,130 |
| 99 | 211,706 |

Class Combat Level is the floored average of its six skill levels, capped at 99. Each class receives **one point at Combat Level 1 and one point for each subsequent level**, for exactly **99 lifetime earned points**. No shared class bank exists. Training and talents persist after defeat; mission levels, acquired spell ranks and temporary buffs reset as before. Approximate training pace still needs actual play telemetry: the curve is a starting balance, not a promised completion time.

## Branching ranked trees

`skill_tree.gd` is the runtime source shared by Talent Preview and Talent Tree. Each class has three authored specializations. The menu shows one full-width path at a time, with branch tabs and spent totals, a dark backdrop with the original class hero, circles for passive talents, squares for spell unlocks, directed fork/merge links, explicit locks and rank badges. The path scrolls vertically while the selected talent and rank/refund actions remain fixed. Preview exposes inspection and navigation only.

| Class | Specializations | Total rank capacity |
|---|---|---:|
| Scavenger | Precision, Scavenge, Mobility | 136 |
| Engineer | Machines, Energy, Fortification | 140 |
| Warden | Guard, Retribution, Sanctuary | 140 |
| Arcanist | Fire, Frost, Arcane | 140 |

Each branch has twelve named passive nodes, with ranks between one and five. The five original spell unlocks are inserted into their relevant paths **before** the first passive that specializes in that spell. No specialization requires a spell that can only be unlocked by buying that specialization. Nodes offer distinct weapon, spell, structure, defensive, mobility or expedition utility effects; the repeated generic stat columns are removed. Full names, effects, per-rank values and exact links are recorded in `TALENT_BRANCH_DESIGN.json` and embedded in the runtime definition. `TALENT_BRANCH_BUILD_EXAMPLES.json` provides legal 1/25/50/99-point allocations for every class.

Every rank costs one class point. Connections require **any one fully purchased incoming parent**. Merges allow either approach rather than requiring both arms. Spend gates require **15, 35 or 60 points in earlier visual rows across all three branches**; points in the same or later row cannot satisfy a gate. The selected detail states the exact unmet gate or parent. This supports focused paths plus a secondary specialization while the fixed 99-point budget prevents buying everything. Free refund resets only the inspected class. Spending/refunding stays blocked during an active saved expedition.

Three starter spells remain available without spending points. Permanent unlocks expand the random mission level-up pool; they do not grant a spell at the start of a mission or retain its temporary mission rank.

Universal effects use existing Profile stat fields. New combat effects use `stats.talent_effects`; Run, magic, structures and interaction code own their actual execution. These effects are capped independently before use:

| Effect | Talent cap |
|---|---:|
| Basic attack damage | +20% |
| All spell damage | +15% |
| Individual spell damage | +25% |
| Global + individual spell damage | +35% combined |
| Structure damage / HP / repair | +25% / +30% / +30% |
| Dodge / class skill cooldown reduction | 20% / 20% |
| Shield strength | +20% |
| Interaction speed | +25% |
| Individual spell cooldown reduction | 15% |
| HP / armor | +20% / +18 |
| Movement / pickup | +10% / +30% |
| Universal cooldown reduction | +8 percentage points |
| Medkit healing | +5 percentage points |
| Pack / secure storage | +1 slot / +1 slot |

Shield talents strengthen existing shield grants; they do not create a starting shield. Storage talents are one-rank choices. Current combined equipment/class caps still apply (speed 1.15, pickup 1.50, permanent cooldown reduction 0.15). Universal power is not added by the new tree. Training skill effects remain separate: crit up to 10%, Strength plus Ranged physical bonus up to 40%, Magic up to 30%, Defence reduction up to 15%, and Vitality HP up to 30%. Training XP and talent trees are separate from equipment eligibility, which uses the selected class's actual skill levels rather than bonus-adjusted stats.

## Save compatibility

Profile version 6, talent revision 2, adds `class_combat[class] = {xp, training_style, talent_ranks, legacy_entitlement, inherited}`. `combat_xp` and `training_style` remain synchronized aliases for the selected class so existing menu and mission interfaces can read them.

Version 1–5 saves migrate once. Previous global combat training goes only to the previously selected class. Each old stat's level and fractional progress through its level are mapped to the new curve, preserving level gains even though raw XP changes. Other classes start with fresh XP. Previously owned spell unlocks retain rank 1 and are exempted from the new prerequisite gates until a voluntary refund. Their previous costs become a bounded retained entitlement, so a prior nine-point spell build now has five allocated ranks and four retained spendable points. Those retained points count toward the same 99-point lifetime ceiling; they do not add 99 more points. A saved migration notice explains this.

Old active mission checkpoints contain pending XP earned at old rates. Run owns their separate snapshot-curve migration; Profile does not convert pending awards a second time. Banking always credits the class recorded in the attempt. Unknown/corrupt legacy XP or unlock data is rejected so normal backup recovery can run instead of silently discarding it.

The earlier unreleased version-6 generic grid draft is handled separately: known generic ranks are explicitly refunded to their original class, while spell unlock IDs, XP, trained levels and the 99-point entitlement remain. The saved notice states the refund. Unknown node data is rejected instead of silently deleted. This is a draft migration within the unreleased version6, not a new release schema version.

New presentation settings `damage_numbers` and `health_bars` default to true, migrate to true and accept booleans only.

## Verification

Focused checks cover independent class pools/focuses, all 99 points spendable, rank and earlier-tier gates, stat caps, legacy level preservation, retained spell builds/refunds, migration idempotence, save rollback, actual menu spending/refunding, and locked/active-run states. Visual fixtures cover all four classes at 320 and 430 widths. Captures live under `artifacts/nightfall-godot/branch-talents` and `class-training-v6`.

The ranked-node and spend-gate direction was informed by the user's requested [World of Warcraft talent-system overview](https://worldofwarcraft.blizzard.com/en-us/news/23818247). The parent also reviewed the official Dragonflight preview and its illustrated tree reference. Nightfall uses the principles of branching choices, directed prerequisites, ranked nodes and spend gates; its artwork, definitions and balance are original rather than a reproduction of Blizzard assets.
