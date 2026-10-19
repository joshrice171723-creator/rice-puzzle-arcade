# Class talent branches: design and balance contract

October 19, 2026 replacement for the rejected repeated-stat grid. This document and [TALENT_BRANCH_DESIGN.json](TALENT_BRANCH_DESIGN.json) define the proposed class-specific nodes, exact rank effects, links and limits. [TALENT_BRANCH_BUILD_EXAMPLES.json](TALENT_BRANCH_BUILD_EXAMPLES.json) contains sixteen calculated legal allocations at Combat Levels 1, 25, 50 and 99. These are design calculations, not runtime or visual acceptance.

## What changes

The inspected implementation has five one-point spell unlocks plus twenty-five five-rank generic stat nodes: **130 ranks per class**. The earlier survival document's **129** was a different unimplemented proposal; neither number describes this replacement. Repeating a tiny movement/HP/Power allocation in five vertically forced columns made purchases feel interchangeable and concealed class identity.

The replacement keeps **99 normal earned points per class**, including one starting point, with three thematic branches and genuine fork/merge prerequisites. Each class has 36 named passive nodes and five one-point spell availability nodes. Scavenger has **136** possible purchases, including two one-rank storage choices. Engineer, Warden and Arcanist each have **140**. A normally capped character leaves respectively **37 or 41 ranks unpurchased**. No extra entitlement is created by opening another branch tab.

Blizzard's [Dragonflight talent preview](https://news.blizzard.com/en-us/article/23797209/world-of-warcraft-dragonflight-talent-preview) supports the structural direction: readable paths express dependencies, arrows connect prerequisites, deeper sections have spent-point gates, and choices reinforce class identity. Its described rule allows access through a fully purchased incoming prerequisite. Nightfall borrows those structural ideas while retaining its own 99-point budget; it does not copy WoW's point totals, abilities or balance.

## Three branches per class

| Class | First branch | Second branch | Third branch |
|---|---|---|---|
| Scavenger | **Precision:** basic weapon damage, Blades/Lance support and Chain follow-through | **Scavenge:** supply reach, shrine interaction, medkit value, one extra bag slot and one protected slot | **Mobility:** movement, dodge recharge, Phase Step frequency and Frost/Gravity support |
| Engineer | **Machines:** turret damage, structure durability, repair strength and supporting steel spells | **Energy:** Repair Swarm frequency, electrical/frost spell tuning and efficient casting | **Fortification:** personal durability, shield strength, escape recharge and worksite supplies |
| Warden | **Guard:** armor, HP, Aegis amount/frequency and defensive structures | **Retribution:** weapon pressure and Lance/Blades/Chain attacks | **Sanctuary:** Ground/Wisp support, medical supplies, repair and collection |
| Arcanist | **Fire:** Ember damage/cadence with Chain support | **Frost:** Frost/Lance/Ground specialization, shields and durability | **Arcane:** efficient casting, Wisp/Gravity/Blades, Rift Pulse cadence and expedition utility |

These names describe the actual supported effects. Retribution does not pretend to reflect incoming damage; Fire does not apply a new burn system; Mobility does not promise teleportation. No unsupported proc or conditional behavior is hidden behind a dramatic label. A spell damage bonus improves damage only: it does not lengthen Frost control, increase Ground healing, improve Wisp pickup or add targets.

The data contains every node's name, branch, index, maximum rank and **per-rank** effect. Read effects such as `spell_damage_by_id: {ember: 0.04}` as +4 percentage points to Ember's talent damage multiplier per rank, not 4% global spell power. Storage nodes have one rank and grant one actual slot; there are no fractional invisible slot purchases. Existing spell IDs are retained so a saved unlock remains identifiable.

## Readable topology and legal spending

Show **three branch tabs**, with one full-width branching constellation at a time. Keep the class, Combat Level, spent/available points and selected-node details visible while scrolling. Draw connectors from the same prerequisite data used by purchasing. A grey/active/available distinction must correspond to actual eligibility; locked nodes should state the missing prerequisite or gate.

Each branch uses this graph, where letters correspond to indices 0–11:

```text
                 A
              /     \
             B       C
             |       |
             D       E
              \     /
                 F       (D OR E fully purchased)
              /     \
             G       H
             |       |
             I       J
             |       |
             K       L
```

Default maximum ranks are `[5,5,5,4,4,4,4,3,3,3,3,2]`, totaling 45 per branch. Scavenger's Expanded Satchel and Hidden Compartment replace their respective three-rank slots with one-rank nodes, lowering its total by four. Nodes K/L are terminal investments, not fabricated new triggered abilities. Five spell unlocks supply qualitative changes to the eligible expedition draft pool.

Visual rows are `[0,1,1,2,2,3,4,4,5,5,6,6]`. Spending gates open row 2 at **15**, row 4 at **35**, and row 6 at **60** points in **earlier visual rows across all three branches**. Count only earlier rows, not the node being purchased or lower nodes, so an invalid late allocation cannot support its own gate after a refund. Every connected passive requires any one of its incoming passive prerequisites to be fully ranked; F never requires both D and E.

Insert each nonstarter spell unlock **before** its first specialization passive. The spell node inherits that passive's incoming path/gate; the specialization passive additionally requires the spell unlock. This prevents buying a damage bonus for an unavailable spell and avoids the circular mistake of putting the unlock after that bonus. Starter spells need no unlock purchase. Spell availability remains distinct from expedition spell ranks.

The first point has a useful uncoupled choice among the three branch roots. For example, Scavenger can start with +2% basic weapon damage, +4% pickup reach or +1% movement. The later gate is an investment requirement, not a demand to buy the same stat in every column. Spell nodes and any inherited exceptions must use the same graph in the UI and validator.

## Effect interface and limits

`Skills.bonuses` supplies existing profile adjustments separately from `stats.talent_effects`. Do not add these effects to permanent training bonuses: training stats can already reach their own ceilings, and silently merging the two would make talent purchases ineffective at stat 99. Configure an expedition from a copied, validated effect dictionary and preserve it in its snapshot. Mid-run profile changes must not mutate an existing expedition.

| Effect group | Talent-only maximum | Combination rule |
|---|---:|---|
| Basic weapon damage | +20% | Multiply eligible direct basic damage once; spell-only bonuses do not apply merely because a wand projectile is elemental. |
| Global spell damage | +15% | Add to the selected spell's specific talent damage contribution. |
| Specific spell damage | +25% per spell | Global + specific talent contribution capped at +35%; apply once to that spell's eligible damage, including its existing damage over time. |
| Structure damage / HP / repair | +25% / +30% / +30% | Independent multipliers on structure damage, spawned HP and actual repair amount. No cost/refund change. |
| Dodge recharge / class ability recharge | 20% / 20% reduction | Multiply recharge duration by `1-bonus`; do not modify invulnerability, distance, attack tells or time already elapsed. |
| Granted shield amount | +20% | Scale newly granted amount once; preserve source refresh rules and 30%-of-max-HP concurrent cap. |
| Shrine interaction speed | +25% | Required time `base_time/(1+bonus)`; does not affect spell casting, paid costs or shop prices. |
| Specific spell cooldown | 15 percentage points | Sum with existing permanent and run cooldown reductions; retain the final 30% combined reduction cap. |
| Direct profile HP / armor | +20% / +18 flat | Apply HP once and armor once; retain existing armor/overall mitigation ceilings. |
| Direct profile movement / pickup | +10% / +30% | Permanent profile speed multiplier caps at **1.15**, including class, gear and talents. Run/field movement modifiers are separate. Respect existing pickup caps and report effective marginal gain when gear already consumes headroom. |
| Direct profile spell cooldown | 8 percentage points | Part of the same final spell cooldown calculation, never a second multiplicative reduction. |
| Medkit recovery | +5 percentage points | Add to the existing finite once-per-expedition heal fraction, not continuous regeneration. |
| Bag / protected slots | +1 / +1 | Whole-slot one-rank purchases; validate existing storage ceilings. |
| Generic Power | No talent contribution | Avoid a second generic multiplier on weapon, spells and structures simultaneously. |

The designed full-capacity sums stay within these talent-only envelopes even before the 99-point restriction. Arcanist's Ember reaches exactly +35% from +12% global and +23% specific; other maximum spell combinations remain lower. This avoids building a tree where completing its own nodes inherently causes hidden cap waste. Existing equipment or expedition effects can still consume shared cooldown/movement headroom; the UI must not describe a capped allocation as an unconditional improvement.

Use **one** spell scaling owner:

```text
talent_spell_damage_factor(id) = 1 + min(0.35, global_spell_damage + specific_damage[id])
spell_cooldown(id) = base_cooldown(id) * (1 - min(0.30, existing_CDR + specific_CDR[id]))
```

Here `existing_CDR` already includes the direct profile talent cooldown adjustment, equipment and current run effects; do not add that talent adjustment again. Wisp has no ordinary cast cooldown, so the data assigns it damage bonuses but **no Wisp cooldown nodes**. Structure damage does not receive basic/spell talent damage unless its own authored attack explicitly says so. All actual HP damage continues through normalized training XP accounting; talent damage cannot credit overkill or refill a reward budget.

## Calculated level 1/25/50/99 examples

These examples use the matching point budgets and a deterministic legal spending route. They are not optimal builds. Gear, training-stat bonuses, mastery and expedition upgrades are held constant when comparing talent-only effects. Spell DPS ratios below assume full target contact, unchanged damage per cast except the listed bonus, and no competing cooldown source.

| Class | Combat 1, one point | Combat 25, 25 points | Combat 50, 50 points | Combat 99, 99 points |
|---|---|---|---|---|
| Scavenger | Precision 1: +2% basic damage | Precision 25: +10% basic; Blades/Lance +20% damage and 8% cooldown reduction | Precision 42 + Mobility 8: +16% basic, +5% speed, 6% dodge recharge reduction | Precision 47 + Mobility 46 + Scavenge 6: +20% basic, +8% speed, 17.5% dodge recharge reduction, +20% pickup |
| Engineer | Machines 1: +3% structure damage | Machines 25: +16.5% structure damage, +20% structure HP, +16% repair | Machines 42 + Fortification 8: +21% structure damage, +29% structure HP, +10% HP and +6 armor | Machines 47 + Fortification 46 + Energy 6: +25% structure damage, +29% structure HP, +28% repair, +16% HP and +16 armor |
| Warden | Guard 1: +2 armor | Guard 25: +10 armor, +10% HP, +14% shield amount, 12% Aegis recharge reduction | Guard 40 + Sanctuary 10: +16 armor, +16% HP, +18% shield, Ground +20% damage/10% cooldown reduction | Guard 45 + Sanctuary 47 + Retribution 7: +16 armor, +16% HP, +18% shield, 18% Aegis recharge reduction and +5 percentage points medkit recovery |
| Arcanist | Fire 1: +4% Ember damage | Fire 25: Ember +22% combined damage and 10% cooldown reduction | Fire 41 + Frost 9: Ember +31% combined damage/10% cooldown reduction; Frost +28% combined damage/8% cooldown reduction | Fire 46 + Frost 47 + Arcane 6: Ember +35% combined damage with 15% total talent cooldown reduction; +14% HP, +8 armor, +19% shield |

The complete rank allocations and all effects, including secondary effects omitted from this compact table, are in the examples JSON. Every example spends exactly its budget, satisfies prior-row gates and full-parent OR prerequisites, and purchases a nonstarter spell before its specialization. Scavenger's final Precision node strengthens already available Chain rather than an unrelated locked Ground spell.

Specific arithmetic checks:

- **Scavenger:** 3-second base dodge recharge becomes `3*(1-.175)=2.475s` at the displayed 99-point build. Its 12-second Phase Step cycle becomes `12*(1-.18)=9.84s`. Invulnerability duration does not change. Blades/Lance at 25 points have talent-only ideal DPS factor `1.20/.92=1.30435`.
- **Engineer:** final structure factors are damage **1.25**, HP **1.29**, repair **1.28**. The Repair Swarm's 24-second base cycle with this route's 10% class reduction becomes **21.6s**. A stronger repair is capped by missing structure HP, so it cannot be treated as guaranteed effective HP every cast.
- **Warden:** at a fixed baseline of 35 armor, the 25-point route's +10 armor/+10% HP gives physical effective-health factor `1.10*(150+45)/(150+35)=1.15946`. The 50/99-point routes' +16 armor/+16% HP give **1.26032**. These exclude shields/healing. Aegis's 22-second base cycle at 18% reduction becomes **18.04s**.
- **Arcanist:** the ideal Ember talent-only DPS ratios at 1/25/50/99 points are **1.04**, `1.22/.90=1.35556`, `1.31/.90=1.45556`, and `1.35/.85=1.58824`. Existing gear/run cooldown caps can lower the marginal benefit. These are ratios for Ember, not all outgoing character damage.

Upper-bound screening with existing permanent stats remains bounded: +20% talent basic damage on the prior 1.47 mean basic stat factor gives **1.764** before unchanged gear/run effects. A +35% spell talent layer on the 1.30 Magic stat factor gives **1.755** per eligible spell hit. Adding the maximum existing combined 30% cooldown reduction gives **2.50714** relative to a zero-stat/zero-CDR reference for that spell; it is not a talent-only gain. The distinction matters when comparing builds with the same permanent progress.

The numbers establish boundedness and legal spending, not overall play balance. A class can invest in damage, escape, storage or durability; no single one-dimensional DPS table captures all those benefits. Test alternative branch priorities at the same budget and gear before concluding that one branch dominates. In particular, a protected loot slot can be valuable without raising DPS, while a structure build needs reachable scrap and placement time to realize its numerical benefit.

## Migration and scope

Retain existing spell IDs and owned spell availability explicitly. The old generic `hp_1`, `power_1`, and similar repeated-grid IDs must not be silently relabeled into unrelated class mechanics. Perform a **free respec/refund** of those draft passive allocations, preserve the player's legitimate point entitlement, and explain the reset once. New semantic IDs are intentional because the path/effect changed.

The feature task retains the unreleased profile version 6 and uses a **talent revision 2** marker. Its migration must be idempotent and must not award another allowance every load. Existing legacy entitlement remains within the normal 99-point lifetime cap, as the current profile model specifies; refunding spent points does not add points on top of earned entitlement. Validate inherited spell exceptions explicitly rather than letting an exception bypass every new gate.

This redesign changes talent nodes, effects and presentation. It does not change the selected 211,706-XP stat cap, 2.4/24 enemy focus XP budgets, per-class XP ownership, world size, wave curves or the point-per-Combat-Level rule. Active expeditions retain their snapshotted old effects until settlement; a new expedition uses the new legal allocation.

## Acceptance evidence still required

Check every node against its actual effect hook and tooltip, including nonstarter spell prerequisites, Wisp's non-cooldown behavior, storage integer slots and medkit percentage points. Check a rank-1/partially ranked/max-ranked/locked selection on each branch and verify all arrows match purchase rules. Check the 15/35/60 gates, OR merge, refunds, reload and each saved build example against runtime validation.

Run meaningful fixed-seed combat comparisons at 1/25/50/99 point budgets for each class, holding gear and permanent stats constant. Measure total damage by source, effective healing/repair/shield absorption, cooldown cadence, damage taken, survival, resource availability and frame time. Verify hit/proc accounting remains once-only and save/reload cannot repeat a class effect. Rendering a handsome tree is insufficient if its effects are inert; a passing effect test is insufficient if paths are unreadable.

Documentation-only work: no runtime code or Git operations were performed for this design task.
