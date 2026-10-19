# Equipment eligibility and power budget

October 19, 2026 design contract for selected-class permanent-skill requirements. This document extends the combat and talent balance documents; its future-zone table is a proposal, not a statement that Zones 2–20 are implemented. The current runtime catalog starts items at upgrade level 1, permits upgrades through level 5, and rolls up to Epic rarity. Calculations below use inspected item formulas and do not establish gameplay difficulty by themselves.

## Skill ownership and requirement formula

An item's required skill is checked against the **selected class's permanent trained stat**, not account-wide progress, Survivor level, class mastery, overall Combat Level, equipment bonuses, talent effects or temporary expedition buffs.

```text
upgrade_requirement(L) = 1 + 2*(L-1), for upgrade level L in [1,30]
required_skill_level(item) = max(template_base_requirement, upgrade_requirement(item.level))
eligible = selected_class_permanent_level(required_skill) >= required_skill_level(item)
```

Invalid item levels must fail validation rather than being silently clamped into a legal item. Current, explicitly known Zone 1 templates have base requirement 1. Preserve an authored `base_requirement` or equivalent validated catalog field for future templates. Its default is not permission for an unknown high-powered item family to become skill-1 equipment.

| Slot or family | Required permanent skill | Reason |
|---|---|---|
| Head, Chest, Boots, Pants | **Defence** | All four are armor slots regardless of rarity or set. |
| Sabre and other melee weapons | **Strength** | A melee weapon's availability follows physical strength. |
| Pistol, Scattergun, Crossbow and other ranged weapons | **Ranged** | Includes guns and projectile bows. |
| Wand, staff and other magic weapons | **Magic** | Weapon family determines the requirement, not whether a temporary effect makes a hit elemental. |
| Current Ring and Pendant | **Vitality** | Existing templates provide small HP/utility bonuses rather than an exclusively magical function. |
| Current Field Medkit gadget | **Vitality** | Universal sustain follows the automatically trained survival stat. |
| Future specialized accessory/gadget | Explicit authored skill | A spell-focus item may use Magic or a defensive relic Defence, but its catalog entry must say so. No inference from a decorative name. |

At upgrade levels 1/2/3/4/5, the upgrade-derived requirements are **1/3/5/7/9**. Levels 10/20/30 require **19/39/59** before any higher template floor. The formula preserves usable starter items for a new class while keeping maximum upgrade gear below a mandatory level-99 grind. Weapon training focus remains selectable: wearing a ranged weapon can still train Defence or Strength under the existing focus rules.

The UI should show, for example, “Requires Ranged 9 — Engineer has 4,” not simply “Level 9 required.” Upgrade level, required skill level and rarity are different values and need different labels.

## Template tiers and future zones

Use a template's first legitimately available zone to author its initial skill floor:

```text
proposed_template_floor(first_zone z) = 1 + 2*(z-1)
future_upgrade_cap(highest_unlocked_zone z) = min(30, 4 + z + floor(z/3))
```

The equipment cap follows the highest legitimately unlocked zone, not the currently selected replay or a purchased preview. These are two independent controls: a high-tier template can still require a high skill when its own upgrade level is 1, and an early template gains requirements as it is upgraded. Acquiring a future family also requires its campaign/source gate; training a stat alone cannot unlock that family in an early shop or paid crate.

| First/unlocked zone | New template's base skill floor | Proposed upgrade cap | Skill requirement at that cap, for a template first available in this zone |
|---:|---:|---:|---:|
| 1 | 1 | 5 | 9 |
| 2 | 3 | 6 | 11 |
| 3 | 5 | 8 | 15 |
| 4 | 7 | 9 | 17 |
| 5 | 9 | 10 | 19 |
| 6 | 11 | 12 | 23 |
| 7 | 13 | 13 | 25 |
| 8 | 15 | 14 | 27 |
| 9 | 17 | 16 | 31 |
| 10 | 19 | 17 | 33 |
| 11 | 21 | 18 | 35 |
| 12 | 23 | 20 | 39 |
| 13 | 25 | 21 | 41 |
| 14 | 27 | 22 | 43 |
| 15 | 29 | 24 | 47 |
| 16 | 31 | 25 | 49 |
| 17 | 33 | 26 | 51 |
| 18 | 35 | 28 | 55 |
| 19 | 37 | 29 | 57 |
| 20 | 39 | 30 | 59 |

Example: a Zone 20 staff at upgrade level 1 requires **Magic 39**, not Magic 1. If its authored power exceeds the normalized Zone 20 family budget, its catalog floor must be raised and its power reviewed; the table is not blanket approval for arbitrary base stats. Upgrading that staff to 30 requires at least Magic 59. Its Common and Legendary versions share the same skill floor, while acquisition gates and rarity power multipliers remain separate.

Prefer normalized family base budgets: a new weapon family changes range, cadence, spread and target coverage while retaining the existing 40-Power baseline. Do not multiply a larger future template baseline by the full upgrade and rarity curves without reviewing the resulting power. As a screening calculation, a hypothetical 80-base-Power weapon already equals a level-21 standard weapon's pre-rarity power because `40*(1+.05*20)=80`; authoring it at level 1 and treating it as skill-1 equipment would bypass twenty upgrades. If higher-base templates are introduced, catalog validation must account for that equivalent power tier, not only their display upgrade number.

Future zone floors must be checked against actual class-training pace and minimum viable gear. The selected custom XP curve requires 1,128 XP for skill 9 and 63,974 for skill 59. At a focused 100–200 XP/minute those take about **5.64–11.28 minutes** and **5.33–10.66 hours**, respectively. Automatic Vitality receives only one third of the pool; Balanced Defence also receives one third. Those skills can therefore take three times the focused time at the same total earned rate. This makes the future table a campaign pacing proposal requiring validation, not a ready-made mandatory full-gear prescription.

## Rarity, upgrades, merging and substats

**Rarity is quality, not an equipment-level shortcut.** Current rarity multipliers are Common 1.00, Uncommon 1.04, Rare 1.08, Epic 1.12, Legendary 1.16 and Mythic 1.20. Current normal acquisition/merge ceilings do not make Legendary/Mythic Zone 1 rewards. The same eligible low-tier family can have a better rarity without gaining a higher skill requirement, provided its base/upgrade power budget remains valid. A future high-tier family cannot enter an early crate simply because its item upgrade level is 1.

**Item upgrades** add 5% of the item's baseline per level through `1 + .05*(L-1)`. Before spending currency, compute the upgraded item's full requirement. An equipped item must not silently become invalid: stop a single or bulk upgrade before the first unaffordable skill requirement and explain the next threshold. An inventory item may be prepared for another class or future training, if the UI clearly shows it is currently unusable. Do not spend all bulk-upgrade currency and then discover the equipped result cannot be worn.

**Merging** retains its existing quality change and takes the maximum upgrade level among its inputs. Skill requirement must be calculated for that resulting level and preserved template floor before any donors or currency are consumed. If a worn target would become ineligible, block that operation or require an explicit alternative equipped item first. Merging an unworn future item can remain legal, with the resulting requirement shown. Never lower a template's floor because a lower-level donor was used; incompatible families remain incompatible.

**Substats** retain their existing slot/rank limits and do not raise or lower the equipment skill requirement. Rank-3 Tempered adds 6% item Power; rank-3 Reinforced/Plated add 8% item HP/armor, respectively. These are item-local multipliers. They do not grant trained skill levels, unlock stronger equipment, apply to unequipped items or count a locked armor piece toward a set bonus. Tuning a substat is an investment inside the permitted item budget, not a bypass of it.

Paid/free crate paths must both use the same eligible source catalog and family/tier restrictions. Do not grant a high-base future template from an early paid source, and do not let rarity add an unbounded independent power multiplier. Eligibility and acquisition should be enforced in the authoritative profile/catalog path, not solely by a disabled Equip button.

## Strongest current level-1 and level-5 gear comparison

To isolate gear, hold class, Survivor, permanent combat stats, talents and expedition upgrades constant. The unmodified starter baseline is **40 Power, 210 HP and 35 armor**, yielding physical effective HP `210*(1+35/150)=259`.

The strong scenario uses eight Epic pieces, all at the indicated upgrade level, with every included substat at its existing rank-3 cap. Weapon carries Tempered and Attuned; the four armor slots carry Reinforced and Plated; Ring/Pendant carry Reinforced and Attuned; Gadget carries Attuned and Seeking. This respects Epic's two-affix-per-item limit. Four rank-3 Attuned allocations sum to 16%, but the permanent cooldown cap grants only 15%. This is an earned theoretical upper build, not the contents of a single new-account crate.

```text
Q(L, Epic) = (1 + .05*(L-1))*1.12
Power = 40*Q*1.06
HP = 120 + 90*Q*1.08
Armor = 35*Q*1.08
physical_EHP = HP*(1 + Armor/150)
```

| Gear scenario | Power | HP | Armor | Physical EHP | Power vs starter | EHP vs starter |
|---|---:|---:|---:|---:|---:|---:|
| Common starter, level 1, no affixes | 40.000 | 210.000 | 35.000 | 259.000 | 1.000 | 1.000 |
| Epic level 1, strong legal substats | 47.488 | 228.864 | 42.336 | 293.459 | **1.1872** | **1.1330** |
| Epic level 5, same substats | 56.986 | 250.637 | 50.803 | 335.524 | **1.4246** | **1.2955** |

For a cooldown-based spell whose damage scales with Power, the level-1 gear scenario's ideal damage-throughput ratio is `1.1872/.85 = 1.3967` before unchanged class/spell effects. At level 5 it is `1.42464/.85 = 1.6760`. Wisp's fixed shared contact interval does not receive this ordinary cooldown-frequency gain. Area target occupancy, weapon type, hit rate and overkill prevent interpreting these as exact whole-character DPS ratios.

The level-5 row is a **gear-only comparison**, not a claim that stat-1 characters can wear it. Its Ranged/Defence/Vitality requirements are 9 for a full pistol/armor/accessory kit, and those trained levels add their own modest effects in a real character. At stat 9, Vitality adds about 2.45% HP, Defence reduces incoming damage by about 1.22%, and Ranged adds about 1.63% non-elemental damage when Strength remains 1. Keep those contributions separate when checking eligibility and measuring balance.

These bounded ratios do not show an enormous early rarity jump, but **do not prove Zone 1 remains challenging**. The level-1 cooldown-spell improvement is nearly 40% in this ideal scenario. Validate starter versus strong earned Epic gear through the actual wave, boss and survival journey. If early high-rarity/substat access trivializes it, tune acquisition costs/source gates or specific affix budgets; do not secretly raise rarity's skill requirement after purchase or inflate enemy stats based on the player's gear.

## Enforcement and recovery rules

Check eligibility in Equip, saved-loadout application, class switching, automatic reward equipping, upgrade/merge results and final stat assembly. The same predicate must govern the UI and those writes. Ineligible armor contributes no HP, armor, affixes or set count; an ineligible weapon cannot retain its attack family, damage or special projectile behavior through a partial stat filter.

Saved-loadout application is atomic: either its class and all required items pass, or the existing class/equipment remain unchanged with a concrete reason. For a class switch, an eligible owned fallback can be selected per slot and reported. Preserve every owned item; nothing is destroyed merely because the new class cannot wear it.

Do not create a class-switch deadlock when the player has upgraded or salvaged every low-level item. A class at skill 1 must still be able to start training. If no owned eligible fallback exists, provide an explicitly nonowned, nonsellable, nonsalvageable level-1 training kit, or preserve an immutable starter reserve. Repeated switching must not mint salvageable free items. Merely blocking every switch without a usable starter recovery path does not satisfy the training journey.

Apply newly introduced requirements on a new expedition/loadout transaction. An already active expedition retains its snapshotted class and gear effects until it settles, following existing transaction semantics. Validate unknown metadata without erasing inventory. Template floors and identity must survive loot creation, crafting, upgrades, merging, saves and loadouts; unknown future content must not silently inherit a skill-1 floor just because an old save lacks the field.

## Required checks

Verify exact threshold/below-threshold cases for every mapped skill; class-specific isolation; same-family rarity equivalence; a future high-floor level-1 template; whole and bulk upgrades; a higher-level merge donor; ineligible set/affix suppression; automatic reward equip; atomic saved builds; class-switch fallback with no owned low-level gear; repeated switching without item duplication; and persistence/reload. Compare strong legal level-1 and level-5 builds against starter runs, reporting gear-only arithmetic separately from runtime survival evidence.

Documentation and calculations only: this task changed no runtime code and performed no Git operations.
