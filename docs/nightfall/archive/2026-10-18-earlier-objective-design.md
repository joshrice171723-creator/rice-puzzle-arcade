# Nightfall Earlier Design Archive

Historical proposal preserved October 18, 2026 to avoid losing detailed mechanics, equipment, stat, economic, and side-mode discussion. NOT the current campaign specification. The objective/extraction campaign and associated victory conditions are superseded by [the main plan](../NIGHTFALL_MAIN_PLAN.md). Where any values or rules conflict, the main plan takes precedence. Nothing in this archive authorizes implementation.

---

**Nightfall should be a graphical mobile action game where you build a survivor, explore a ruined magical world, scavenge equipment, fortify temporary refuges, and bring valuable loot home.** Your permanent character and settlement improve over time, while every mission gives you a fresh combat build through temporary experience and ability choices.

The central appeal is: **“One more expedition could give me the equipment, materials, or experience to beat the place that stopped me.”**

Everything below is a proposed design. The numbers form a consistent starting point for testing; they are not proven balance values. **This is planning only.**

---

**1. The world and the main gameplay loop**

Working title: **Nightfall: The Last Beacon**.

A magical disaster called **the Sundering** shattered the boundary between the living world and the Hollow. Towns lost power, enchanted machinery became unstable, and creatures began appearing after dark.

Survivors discovered that fragments of the disaster—**Emberglass**—can power weapons, protective wards, and fortified settlements. You lead expeditions from **Haven**, a settlement built around one surviving beacon.

This gives magic and scavenging a shared purpose. A broken generator, an enchanted rifle, a protective rune, and a monster’s crystalline heart all belong in the same world.

A normal session follows this sequence:

1. Choose a class and equip weapons, armor, a charm, and a gadget.
2. Select a mission and review its enemies, objectives, and known hazards.
3. Enter with an empty field backpack and a small secure stash.
4. Fight, collect temporary combat XP, and choose abilities.
5. Explore optional routes for materials and equipment.
6. Build or repair defenses at designated refuge sites.
7. Complete the objective and extract—or retreat with what you can secure.
8. Upgrade equipment, improve Haven, and prepare another expedition.

Most missions should last **5–8 minutes**, with introductory missions around four minutes and major finales around eight to ten.

A mission should involve decisions throughout: take a dangerous shortcut, repair the generator, search one more room, protect a resource carrier, or spend remaining scrap on a turret.

---

**2. How the player controls it**

Use a tilted, top-down view with readable characters, large weapons, clear enemy silhouettes, and bright spell effects against darker environments.

- **Left thumb:** movement through a floating joystick.
- **Automatic basic attack:** attacks an appropriate enemy in range.
- **Right-side buttons:** dodge and the equipped class ability.
- **Context button:** interact, repair, loot, rescue, or extract.
- **Temporary learned spells:** activate automatically according to their targeting rules.
- **Combat level-up:** pauses action while the player selects one of three upgrades.

For targeting, default to nearby threats, with a priority setting for closest enemy or lowest-health enemy. Tapping a boss can temporarily focus it.

The player should win through movement, positioning, choosing upgrades, and managing objectives—not through having to press six tiny skill buttons.

During combat, the phone screen contains only:

- Health and shield.
- Combat XP.
- Main objective.
- Compact refuge health when relevant.
- Movement and ability controls.
- A small backpack/stash indicator.

Inventory, crafting, and lengthy stat comparisons happen outside combat. The combat screen never requires scrolling.

---

**3. Permanent growth and mission growth must remain distinct**

| System | Persists after the mission? | What it changes |
|---|---:|---|
| Survivor level | Yes | Base health and feature progression |
| Class mastery | Yes | Talents for the selected class |
| Equipment | Yes | Weapon strength, protection, affixes, and set effects |
| Haven facilities | Yes | Crafting options, storage, training, and expedition preparation |
| Campaign progress | Yes | Zones, missions, first-clear rewards, and stars |
| Combat level | No | Temporary spells and stat upgrades |
| Field scrap | No | Construction and repairs within that mission |
| Temporary refuge | No | The defenses built during that expedition |
| Unsecured new loot | Only after extraction | Equipment and materials carried out successfully |

The interface should use the labels **Survivor Level**, **Class Mastery**, and **Combat Level** consistently.

An item that increases experience must say which one: **Combat XP +8%**, for example, rather than an ambiguous “XP bonus.”

**Survivor progression**

Proposed initial cap: **level 40**.

- Base health at level 1: **120 HP**.
- Gain **4 base HP per survivor level**.
- Base health at level 40: **276 HP**.
- Survivor level does not also multiply every source of damage.
- Equipment provides most permanent offensive growth.
- Kills and completed objectives award Survivor XP.
- Earned Survivor XP survives mission failure.

Keeping automatic damage growth out of survivor levels prevents weapon level, rarity, class level, and character level from multiplying into uncontrolled power.

**Class mastery**

Each class has **20 mastery levels**. Only the selected class’s talents apply.

Milestones at mastery levels **1, 5, 10, 15, and 20** unlock or improve its defining features. Other mastery levels contribute to the next milestone rather than silently adding another percentage bonus.

**Combat progression**

Every mission begins at **Combat Level 1**.

- Maximum combat level: **12**.
- Each level gained offers one choice from three upgrades.
- Short missions normally produce 5–7 choices.
- Longer missions normally produce 8–11.
- No combat levels or temporary abilities carry into the next mission.

---

**4. Four classes with different ways to solve the same mission**

All classes can use any weapon. Their strengths encourage different builds without making a particular class mandatory for a campaign mission.

Class switching is free at Haven. Equipment remains shared, and each class can save its own loadout.

| Class | Role | Starting passive | Active ability | Primary tradeoff |
|---|---|---|---|---|
| **Scavenger** | Movement, exploration, precision | +5% movement speed; +15% pickup radius | **Phase Step:** dash up to 4 m with a 0.25-second invulnerable window; 12-second cooldown | Limited direct protection |
| **Engineer** | Defenses, gadgets, controlled combat | Repairs 20% faster; personal deployed structures have +10% health | **Repair Swarm:** restores 20% of one structure’s maximum health over 4 seconds; 24-second cooldown | Needs time and positioning to establish defenses |
| **Warden** | Close combat, protection, objective holding | +10% maximum health; +18 armor | **Aegis:** gain a shield equal to 20% maximum health for 4 seconds; 22-second cooldown | Less mobility and lower offensive talent ceiling |
| **Arcanist** | Elemental combinations and area damage | +8% elemental damage | **Rift Pulse:** deal 120% of Power in a short-radius burst and push ordinary enemies back; 16-second cooldown | No starting defensive bonus |

**Power** is the standardized weapon-strength value explained below. It lets spells work sensibly with pistols, rifles, melee weapons, and staffs.

Suggested unlocks:

- Scavenger: available immediately.
- Engineer: rescue the mechanic in Zone 1, Mission 4.
- Warden: finish Zone 2.
- Arcanist: restore the shrine in Zone 3, Mission 3.

Players get access to magic before unlocking Arcanist. Arcanist specializes in it.

**Class mastery milestones**

| Mastery | Scavenger | Engineer | Warden | Arcanist |
|---|---|---|---|---|
| 1 | Starting passive and Phase Step | Starting passive and Repair Swarm | Starting passive and Aegis | Starting passive and Rift Pulse |
| 5 | **Trail Sense:** reveal unopened containers within 8 m | **Efficient Assembly:** structure construction costs 10% less scrap | **Hold Ground:** +10 armor while near the current defense objective | **Focused Channel:** elemental bonus improves from 8% to 12% |
| 10 | **Clean Escape:** Phase Step removes slowing effects | **Overclock:** one nearby turret gains 15% attack speed for 5 seconds after Repair Swarm | **Steady Guard:** Aegis prevents interruption while interacting | **Arcane Echo:** Rift Pulse repeats at 25% strength after 1 second |
| 15 | **Marked Prey:** first hit after Phase Step deals +25% damage | **Salvage Recovery:** destroying your own structure returns 40% of its original construction cost | **Counterstroke:** absorbing damage with Aegis empowers the next basic hit by 50% | **Elemental Study:** applying two different elemental statuses grants +10% spell damage for 4 seconds |
| 20 | **Second Wind:** taking lethal damage leaves 1 HP and grants a brief escape window; once per mission | **Field Network:** Repair Swarm also restores 5% health to one adjacent structure | **Last Bastion:** Aegis also shields the refuge core for 10% of its maximum health | **Controlled Surge:** Rift Pulse cooldown falls from 16 to 14 seconds |

These effects need internal limits. For example, Scavenger’s lethal-hit protection cannot reactivate through revival, and Arcanist’s Echo cannot trigger another Echo.

---

**5. Equipment slots and the underlying combat stats**

Use **six equipment slots**:

1. Weapon.
2. Helmet.
3. Body armor.
4. Boots.
5. Charm.
6. Gadget.

This gives players meaningful choices without requiring eight or ten different upgrade currencies.

**Baseline character stats**

| Stat | Starting value | Purpose and limit |
|---|---:|---|
| Base HP | 120 | Before equipment and class bonuses |
| Movement speed | 4.0 m/s | Permanent bonuses capped at +15%; total sustained bonus capped at +30% |
| Critical chance | 5% | Permanent cap 25%; total with combat upgrades 40% |
| Critical damage | 150% | Total cap 200% |
| Armor | 0 before gear | Reduces physical damage |
| Elemental resistance | 0% | Permanent cap 25%; total cap 40% |
| Cooldown reduction | 0% | Permanent cap 15%; total cap 30% |
| Dodge | One charge | 6-second recharge; short invulnerability window |
| Healing received | 100% | Bonus capped at +25% |
| Life steal | 0% | No unrestricted life-steal stat at launch |
| Combat XP bonus | 0% | Permanent bonus capped at +10%; total +25% |

The ordinary dodge and Scavenger’s Phase Step are separate abilities.

**Armor calculation**

A simple starting formula:

`Physical damage reduction = Armor ÷ (Armor + 150)`

Examples:

| Armor | Physical damage reduction |
|---:|---:|
| 30 | 16.7% |
| 60 | 28.6% |
| 100 | 40% |
| 150 | 50% |

Armor reduction is capped at **50%**. Additional damage-reduction effects combine multiplicatively, with a **65% overall reduction ceiling** before shields.

Magic attacks use their applicable elemental resistance instead of automatically benefiting from both armor and resistance. Mixed attacks divide their damage into physical and elemental portions.

**Stacking rules**

- Bonuses in the same category add together.
- Separate categories multiply only where explicitly intended.
- A damage-over-time effect cannot activate another on-hit effect.
- Extra projectiles cannot recursively create more extra projectiles.
- Identical shields refresh or replace one another rather than stacking indefinitely.
- Permanent percentage HP bonuses cap at +25%; combat upgrades can add another +40 percentage points.

These rules are essential to keeping a powerful build exciting without allowing an accidental infinite loop.

---

**6. Weapon identities and starting numbers**

All starter weapons have **Power 40**. Their attack patterns differ, but their single-target damage starts in roughly the same range.

Power determines spell and gadget scaling. It is not the damage of every individual shot.

| Weapon | Damage per hit | Attack interval | Approx. basic DPS | Range | Identity |
|---|---:|---:|---:|---:|---|
| **Service Pistol** | 24 | 0.60 sec | 40 | 7 m | Reliable, accurate, mobile |
| **Pump Shotgun** | 5 pellets × 14 | 1.75 sec | 40 if all pellets hit | 4 m | Strong close-range coverage |
| **Hunting Rifle** | 72 | 1.80 sec | 40 | 10 m | Long range; overkill and missed shots cost time |
| **Salvage Repeater** | 10 | 0.25 sec | 40 | 6 m | Consistent fire; limited stagger |
| **Runeblade** | 40 | 1.00 sec | 40 per target | 2 m arc | Hits up to three enemies; requires close positioning |
| **Ember Staff** | 32 impact + 8 burn | 1.00 sec | 40 against one target | 7 m | Fire damage; refreshed burns do not multiply without limit |
| **Frost Bow** | 48 | 1.20 sec | 40 | 8 m | Slower shots apply a brief chill |
| **Storm Scepter** | 28 primary + 12 secondary | 1.00 sec | 28 against one target; 40 across two | 6 m | Built for groups rather than bosses |

These are tier-neutral weapon identities. An uncommon Hunting Rifle remains a Hunting Rifle; rarity changes its quality and available affixes.

**Weapon upgrades**

Equipment levels range from **1–30**, unlocked gradually through campaign progress.

Starting scaling formula:

`Primary stat = Base stat × [1 + 0.05 × (item level − 1)] × rarity multiplier`

A level-30 Mythic weapon therefore has:

`40 × 2.45 × 1.20 = 117.6 Power`

That is substantial growth from 40 Power, while still leaving room for combat decisions and temporary builds to matter.

Upgrading a weapon increases both its attack damage and Power by the same factor. It does not independently multiply both again when calculating an ordinary shot.

---

**7. Rarity, armor, affixes, and sets**

| Rarity | Color | Primary-stat multiplier | Affix slots | Main purpose |
|---|---|---:|---:|---|
| **Common** | Gray | ×1.00 | 0 | Starter equipment and salvage |
| **Uncommon** | Blue-gray | ×1.04 | 1 | First useful specialization |
| **Rare** | Blue | ×1.08 | 1 | Dependable campaign builds |
| **Epic** | Violet | ×1.12 | 2 | Stronger customization and set combinations |
| **Legendary** | Amber | ×1.16 | 3 | Long-term specialized equipment |
| **Mythic** | Crimson | ×1.20 | 3 | Crafted endgame refinement and a selectable signature effect |

Mythic should not mean five times the strength of Rare. Its appeal is refinement, appearance, and build identity.

**Basic defensive equipment at level 1, Common quality**

| Slot | Primary stats | Example starter item |
|---|---|---|
| Helmet | +20 HP, +10 armor | **Outrider Hood** |
| Body | +50 HP, +20 armor | **Outrider Coat** |
| Boots | +10 HP, +5 armor | **Outrider Boots** |
| Charm | +10 HP | **Beacon Pendant** |
| Gadget | Its own active or automatic effect | **Field Medkit** |

HP and armor scale with item level and rarity. Affixes use their own bounded values.

A level-1 character wearing this basic defensive equipment has **210 HP and 35 armor**, before class bonuses.

**Affix pool**

| Affix | Suggested range per item | Eligible slots |
|---|---:|---|
| Weapon damage | +2–4% | Weapon, charm |
| Elemental damage | +2–4% | Weapon, charm |
| Critical chance | +1–2% | Weapon, charm |
| Critical damage | +3–6 percentage points | Weapon, charm |
| Maximum HP | +2–4% | Helmet, body |
| Armor | +4–8 | Helmet, body, boots |
| Elemental resistance | +2–4 percentage points | Helmet, body, charm |
| Movement speed | +1–2% | Boots |
| Cooldown reduction | +1–3% | Charm, gadget |
| Pickup radius | +5–10% | Boots, gadget |
| Repair speed | +5–10% | Gadget |
| Combat XP | +2–4% | Charm |
| Structure health | +3–6% | Gadget |

Do not roll the same affix twice on one item.

**Named armor sets**

Each set consists of a helmet, body piece, and boots. Set bonuses depend on the number of matching pieces, not on having all three at the same rarity.

| Set and pieces | Two-piece bonus | Three-piece bonus | First available |
|---|---|---|---|
| **Outrider:** Hood, Coat, Boots | +15% pickup radius | One extra secure-stash slot | Zone 1 |
| **Ironwatch:** Helm, Cuirass, Greaves | +12 armor | Aegis or dodge grants a 5%-HP shield; 12-second internal cooldown | Zone 2 |
| **Scrapwright:** Goggles, Workcoat, Treads | +10% repair speed | One turret gains +10% damage | Zone 4 |
| **Cinderweave:** Cowl, Mantle, Sandals | +6% fire damage | Defeating a burning enemy causes a small 20%-Power explosion; once per second | Zone 5 |
| **Rimebound:** Hood, Hauberk, Boots | +8% frost resistance | Chilled enemies deal 5% less damage to you | Zone 8 |
| **Stormrunner:** Visor, Jacket, Soles | +5% movement speed | Dodging charges the next hit with 30%-Power lightning; 8-second cooldown | Zone 9 |
| **Graveward:** Mask, Vestments, Sabatons | +6% maximum HP | Collecting a health pickup also grants a 5%-HP shield for 5 seconds | Zone 12 |
| **Eclipse:** Crown, Robe, Steps | +5% elemental damage | Applying three distinct elemental statuses empowers the next class ability by 20%; 12-second cooldown | Zone 19 |

The player chooses between a full set and mixing two pieces with a particularly good third item.

**Named charms**

- **Beacon Pendant:** balanced health and defensive affix options.
- **Hunter’s Sigil:** precision and critical affixes.
- **Ember Locket:** fire and elemental affixes.
- **Clockwork Seal:** cooldown and gadget affixes.
- **Wayfinder Coin:** pickup radius and Combat XP options.
- **Hollow Prism:** late-game elemental combinations.

Charm identity determines its affix pool; it does not add an extra hidden multiplier.

**Gadgets**

| Gadget | Effect | Limit |
|---|---|---|
| **Field Medkit** | Automatically restores 20% maximum HP when health falls below 25% | Once per mission |
| **Survey Lantern** | Reveals containers and hidden paths within 8 m | No damage benefit |
| **Repair Drone** | Repairs a nearby damaged structure for 2% maximum health every 2 seconds while out of combat | Stops when enemies approach; cannot repair the main objective indefinitely |
| **Shock Mine Kit** | Places a mine after a dodge: 60%-Power damage and a short slow | 18-second cooldown |
| **Ward Projector** | Grants a 10%-HP shield when beginning an extraction defense | Once per extraction event |
| **Decoy Beacon** | At low health, creates a decoy that attracts ordinary enemies for 3 seconds | Once per mission; bosses ignore it |

---

**8. Equipment improvement should give players dependable progress**

Four equipment actions:

- **Upgrade:** spend Credits and Parts to increase item level. Guaranteed success.
- **Reforge:** change one selected affix using a specific crafting material.
- **Promote:** improve rarity using duplicate salvage and a zone-earned catalyst.
- **Salvage:** dismantle unwanted equipment into Parts and promotion material.

Important rules:

- Equipped and favorited items cannot be accidentally included in bulk salvage.
- Upgrading an item never has a random failure chance.
- Replacing equipment should not erase weeks of investment.
- Allow **80% of spent upgrade Credits and Parts to transfer** to another item in the same slot.
- Promotion preserves item level.
- Reforging shows the possible affixes and their ranges.
- Mythic promotion requires a chosen Legendary item and endgame materials; it does not depend on an exceptionally rare chest roll.

A proposed item-level ceiling is:

`Minimum of 30 and [4 + highest unlocked zone + floor(zone ÷ 3)]`

That gives a ceiling of level 5 in Zone 1, level 10 in Zone 5, and level 30 by Zone 20. Players cannot buy their way to level-30 equipment during the tutorial.

---

**9. Magic and temporary combat builds**

Every class can learn magic during a mission.

A run supports:

- One equipped weapon.
- One class ability.
- Up to **three learned automatic abilities**.
- Up to **three passive combat upgrades**.

Most temporary abilities have three ranks. A player cannot maximize everything in one mission.

The following damage values are **Rank 1**:

| Ability | Effect | Cooldown | Role |
|---|---|---:|---|
| **Ember Bolt** | Hits one target for 90% Power and burns for another 30% Power over 3 seconds | 5 sec | Focused damage |
| **Frost Ring** | Deals 65% Power around the player and applies 25% chill for 2 seconds | 8 sec | Escape and crowd control |
| **Chain Spark** | Hits three targets for 70%, 45%, and 30% Power | 7 sec | Groups |
| **Orbiting Wisp** | Circles the player; deals 25% Power on contact | 1 sec per-target hit limit | Close defense |
| **Stone Lance** | Deals 140% Power along a narrow line, hitting up to three enemies | 9 sec | Positioning and piercing |
| **Consecrated Ground** | Creates a small zone dealing 20% Power per second for 4 seconds | 12 sec | Holding a location |
| **Spectral Blades** | Sends two blades outward, each dealing 55% Power | 6 sec | Directional coverage |
| **Gravity Knot** | Pulls ordinary enemies together and deals 40% Power | 12 sec | Setup and control |

Rank 2 generally improves one aspect by approximately **15–25%**. Rank 3 either improves it again or becomes an evolution if the required pairing is present.

Avoid doubling damage at every rank.

**Passive combat upgrades**

| Upgrade | Benefit per rank | Maximum ranks |
|---|---|---:|
| **Heavy Rounds** | +8% basic weapon damage | 3 |
| **Quick Hands** | +6% basic attack speed | 3 |
| **Arcane Focus** | +8% learned-spell damage | 3 |
| **Vital Reserve** | +10% maximum HP | 3 |
| **Fleet Foot** | +5% movement speed | 2 |
| **Field Mechanic** | +10% repair speed; +5% structure damage | 3 |
| **Magnetic Harness** | +20% pickup radius | 2 |
| **Steady Breathing** | Health pickups restore 10% more health | 2 |
| **Piercing Shot** | Basic projectiles penetrate one extra target | 1 |
| **Efficient Channel** | +5% cooldown reduction | 2 |

A maximum of three passive types means taking convenience, defense, and damage involves a tradeoff.

**Example evolutions**

| Evolution | Requirement | Result |
|---|---|---|
| **Wildfire Bolt** | Ember Bolt Rank 2 + Arcane Focus Rank 2 | Rank 3 bolt explodes for 30% Power around its target |
| **Winter Halo** | Frost Ring Rank 2 + Vital Reserve Rank 2 | Rank 3 ring leaves a short-lived slowing boundary |
| **Thunder Relay** | Chain Spark Rank 2 + Field Mechanic Rank 2 | Rank 3 chain can originate from your nearest turret |
| **Soul Lantern** | Orbiting Wisp Rank 2 + Magnetic Harness Rank 2 | Rank 3 wisp collects nearby XP and gains a second, weaker orbit |
| **Rift Spear** | Stone Lance Rank 2 + Piercing Shot | Rank 3 lance penetrates five targets |

An evolution replaces the normal Rank 3 choice. It does not grant a free additional upgrade.

**Status effects**

| Status | Starting effect | Anti-exploit rule |
|---|---|---|
| **Burn** | Damage over 3 seconds | Strongest application controls damage; refreshing does not create unlimited stacks |
| **Chill** | 25% movement slow | Total ordinary-enemy slow capped at 50% |
| **Freeze** | Briefly immobilizes an ordinary enemy | Elites receive reduced duration; bosses receive stagger buildup instead |
| **Shock** | Enables a small secondary arc through specific abilities | Secondary arcs cannot trigger more arcs |
| **Expose** | Target takes 8% increased damage for 3 seconds | Does not stack with itself |
| **Ward** | Temporary shield | Identical sources refresh rather than add indefinitely |
| **Blight** | Enemy-applied damage over time | Clearly visible; cleansed by designated pickups or abilities |

Bosses should resist hard crowd control without being immune to the entire purpose of a frost or control build.

---

**10. The secure stash and expedition risk**

The secure stash is central to the game’s identity.

**Starting capacities**

- Field backpack: **8 slots**.
- Secure stash: **2 slots within those eight**.
- Base upgrades can increase the backpack to 12 slots.
- A campaign-earned upgrade can increase the secure stash to 3.
- The Outrider set can add one more secure slot.

Resource bundles stack to a defined limit. Equipment takes one slot.

**On successful extraction**

- Keep all carried equipment and materials.
- Receive the objective completion reward.
- Record stars and first-clear progress.

**On defeat**

- Keep all equipment brought into the mission.
- Keep new items placed in secure slots.
- Lose unsecured newly collected equipment and material bundles.
- Keep earned Survivor XP, Class Mastery XP, and collected Credits.
- Do not receive the completion bonus.

**Voluntary retreat**

Some missions have an early extraction point. Retreat preserves the backpack but does not clear the mission or grant its completion rewards.

This creates a real decision: protect a good find or push toward the boss.

There should be no paid repair bill for dying and no loss of previously owned equipment.

---

**11. Haven: the persistent home base**

Haven should visually evolve from a boarded garage and failing lamp into an inhabited, fortified settlement.

It is a place the player walks around or views as a compact interactive diorama, with direct navigation buttons for convenience.

| Facility | What it does | Meaningful upgrades |
|---|---|---|
| **Beacon Core** | Campaign map and settlement progression | Unlocks facility ranks and new expedition regions |
| **Armory** | Equipment storage and saved loadouts | More saved loadouts, comparison tools, collection display |
| **Workshop** | Item upgrades, promotion, salvage | Higher crafting capability and targeted recipes |
| **Training Yard** | Class mastery and practice | Enemy practice encounters and class trials |
| **Arcanum** | Magic research and evolution recipes | Unlocks new spell choices and elemental crafting |
| **Quartermaster** | Backpack, secure stash, contracts | Backpack expansions and the earned secure-slot upgrade |
| **Infirmary** | Expedition preparation | Earned medkit recipes and rescue-token storage |

Facilities have up to five ranks. Important features unlock through missions; higher ranks require materials.

Suggested costs for upgrading an ordinary facility:

| Upgrade | Credits | Parts |
|---|---:|---:|
| Rank 1 | Quest unlock | — |
| Rank 2 | 800 | 20 |
| Rank 3 | 2,500 | 60 |
| Rank 4 | 6,000 | 120 |
| Rank 5 | 12,000 | 220 |

Special upgrades such as the extra secure slot also require a named quest component.

**No construction timers in the initial design.** The challenge is earning resources and choosing priorities. A player should see the improvement immediately after paying its cost.

Haven does not get destroyed while the player is offline.

---

**12. Field refuges: building during missions**

Field construction uses **Field Scrap**, which disappears when the mission ends.

Refuges have designated construction points around an objective, with limited choices. This is easier to control on a phone than unrestricted placement.

A typical refuge allows **8 construction capacity**, increasing to 12 in selected late missions.

| Structure | Scrap cost | Capacity | Starting function |
|---|---:|---:|---|
| **Scrap Barricade** | 20 | 1 | Blocks a route; 300 base HP |
| **Bolt Turret** | 50 | 3 | Deals damage equivalent to 25% of weapon Power per second |
| **Ember Trap** | 30 | 1 | Deals 100% Power in an area; 12-second rearm |
| **Ward Pylon** | 40 | 2 | Periodically grants a small shield to nearby players or the refuge |
| **Repair Station** | 45 | 2 | Provides three repair charges for structures |
| **Arc Conduit** | 55 | 3 | Damages several nearby enemies; weaker against one target |
| **Signal Lantern** | 25 | 1 | Reveals stealth enemies and suppresses a local darkness hazard |

Structure HP scales modestly with Survivor Level:

`Structure HP = base HP × [1 + 0.04 × (Survivor Level − 1)]`

Facility and equipment bonuses then apply within their caps.

Limit damaging turrets to two per refuge. Construction capacity prevents placing every useful support structure alongside them.

Each structure has two mission upgrade choices, such as:

- Barricade: **Reinforced Plating** or **Barbed Facing**.
- Turret: **Long Barrel** or **Rapid Feed**.
- Ward Pylon: **Wider Field** or **Stronger Pulse**.
- Ember Trap: **Larger Blast** or **Faster Rearm**.

Repairing costs scrap and requires standing near the structure. The player must decide whether it is safe to repair during an attack.

Not every mission needs a refuge. Some focus on exploration, pursuit, or extraction so the campaign does not feel like the same defense map 100 times.

---

**13. How difficulty should work**

After Zone 5, **new frontier missions should often take several attempts**. A useful initial target is a **25–45% clear rate for appropriately equipped players on their first few attempts**.

That target applies to unfamiliar frontier content—not to every replay.

| Content | Proposed clear-rate target |
|---|---:|
| Introductory missions | 80–95% |
| Zones 2–5, first attempts | 50–70% |
| Zones 6–10, first attempts | 35–45% |
| Zones 11–20, first attempts | 25–40% |
| Previously mastered farming missions | 80–95% |
| Optional high-tier challenges | 10–25% |

These are playtest targets, not an algorithm that chooses whether the player loses.

Difficulty comes from:

- Enemy combinations.
- Less forgiving positioning.
- Multiple competing objectives.
- Resource scarcity within the mission.
- Boss attack patterns.
- Choosing between defense, exploration, and damage.
- Bringing equipment suited to the mission.

**The player should be able to identify why they lost.**

Examples:

- “I left the turret exposed to Gnawers.”
- “I need a piercing weapon for that corridor.”
- “I spent my scrap before the second generator failed.”
- “I dodged the first attack too early and got caught by the follow-up.”
- “My build clears groups well but cannot finish the shield carrier.”

For the multi-week goals you want, I would put the longest pursuits in **three-star completion, Nightmare missions, Mythic crafting, and advanced dungeon tiers**. A normal campaign zone can still hold someone for days or longer depending on their play, but deliberately making everyone wait two weeks risks stopping the habit we want to build.

A stuck player should always have a useful next action: learn the encounter, change class, target a set piece, upgrade a weapon, or collect a crafting catalyst.

**Enemy scaling proposal**

For zone number `z`:

- Health multiplier: `1 + 0.13(z−1) + 0.002(z−1)²`
- Damage multiplier: `1 + 0.16(z−1) + 0.003(z−1)²`

| Zone | Health multiplier | Damage multiplier |
|---:|---:|---:|
| 1 | ×1.00 | ×1.00 |
| 5 | ×1.55 | ×1.69 |
| 10 | ×2.33 | ×2.68 |
| 15 | ×3.21 | ×3.83 |
| 20 | ×4.19 | ×5.12 |

Mission position adds a small multiplier from ×1.00 for Mission 1 to ×1.12 for Mission 5.

Most of the increased challenge should still come from encounter design. Simply increasing every enemy’s health makes combat tedious.

---

**14. Enemy families and readable threats**

These are baseline Zone 1-equivalent values before zone scaling. Not all enemies appear in Zone 1.

| Enemy | HP | Typical attack | Behavior and counter |
|---|---:|---:|---|
| **Drifter** | 80 | 12 damage | Slow melee; teach movement |
| **Skitter** | 45 | 10 damage | Fast flank; fragile |
| **Gnawer** | 100 | 18 to structures | Prioritizes defenses; intercept early |
| **Spitter** | 70 | 14 damage | Telegraphs a projectile; move between volleys |
| **Bulwark** | 260 | 24 damage | Frontal protection; flank or use piercing attacks |
| **Hexcaller** | 130 | Summons or buffs | High-priority support target |
| **Wisp** | 55 | 12 elemental damage | Passes through small obstacles |
| **Burster** | 90 | 30 explosion damage | Expands and flashes before exploding |
| **Stalker** | 110 | 22 damage | Brief concealment; revealed by lanterns and attacks |
| **Siphoner** | 160 | 16 damage | Drains refuge power until interrupted |
| **Brute** | 400 | 40 damage | Slow, clearly telegraphed heavy attacks |

Ordinary attacks should give the player useful warning. Severe attacks need stronger visual and audio signals.

A boss starts around **3,000 base HP**, with attacks ranging from **25 damage for a light hit to 80 for a heavily telegraphed strike**, then receives zone scaling and individual encounter adjustments.

Bosses should generally last about **60–100 seconds of an appropriately equipped attempt**, including movement and mechanic phases. Actual testing must determine whether the health numbers achieve that.

Encounter rules:

- Do not spawn enemies directly on the player.
- Do not combine unavoidable attacks into guaranteed damage.
- Maintain a visual-effect budget so spell effects do not hide warning markers.
- Limit simultaneous ranged attacks in early zones.
- Never require a purchased class or an ad-only effect to counter an enemy.

---

**15. The full campaign: 20 zones, five missions each**

Every zone introduces a recognizable environment, a gameplay idea, and a desirable reward.

Mission 5 is the zone finale. Clearing it unlocks the next zone; collecting all stars is optional.

**Zones 1–5 establish the game.**

| Zone | Five missions | Finale boss | Main progression reward |
|---|---|---|---|
| **1. Blackout Outskirts** | **1. A Light in the Garage:** recover a battery and defend the first refuge. **2. Supply Run:** retrieve three supply bundles and extract. **3. Keep It Running:** restore a generator while Gnawers attack. **4. Someone on the Radio:** rescue and escort the mechanic. **5. Hold Until Dawn:** prepare the garage and survive the Breaker’s assault. | **The Breaker:** charge, wall smash, long recovery window | Workshop, Engineer class, Bolt Turret blueprint, Rare equipment choice |
| **2. Freight Yard** | **1. Missing Manifest:** search containers for route information. **2. Through the Stack:** navigate shifting container lanes. **3. Cargo Under Siege:** defend a loading crane. **4. Last Freight:** escort a powered freight cart. **5. The Iron Gate:** open the yard exit during a heavy assault. | **Chainjaw:** pulls targets toward itself and sweeps a chain across lanes | Warden class, Ironwatch equipment, expanded contract board |
| **3. Silent Suburbs** | **1. Empty Windows:** search houses while avoiding ambushes. **2. The Cul-de-sac:** defend two connected streets. **3. The Sleeping Shrine:** restore an arcane shrine. **4. Neighbors in the Dark:** rescue three survivor groups in a chosen order. **5. House at the End:** destroy ward anchors and confront the source of the whispers. | **The Whisperer:** creates decoys and summons fragile support enemies | Arcanist class, Arcanum, Ember Bolt and Frost Ring research |
| **4. Flooded Market** | **1. High Ground:** cross raised walkways and restore pumps. **2. The Floating Pharmacy:** recover medical supplies. **3. Broken Crossing:** repair and defend a bridge. **4. Waterline:** operate pumps while defending the refuge. **5. Beneath the Stalls:** fight through a draining market square. | **The Drowned Bell:** sends visible water pulses through connected channels | Scrapwright set, Repair Station blueprint, Infirmary |
| **5. Ironworks** | **1. Cold Furnace:** restart machinery. **2. Steel Teeth:** defeat armored groups using positioning. **3. Pressure Rising:** release valves in a chosen sequence. **4. The Casting Floor:** move between safe platforms during furnace cycles. **5. Heart of the Foundry:** defend the shutdown mechanism and defeat the forge guardian. | **The Forge Warden:** armored front, exposed rear vents, furnace sweep | Cinderweave set, weapon promotion recipes, first major campaign milestone |

**Zones 6–10 require deliberate builds and better resource decisions.**

| Zone | Five missions | Finale boss | Main progression reward |
|---|---|---|---|
| **6. Orchard County** | **1. Open Fields:** cross exposed terrain using temporary cover. **2. The Last Harvest:** collect supplies before darkness spreads. **3. Barn Lights:** establish and defend a farm refuge. **4. Scarecrow Road:** identify and destroy hidden callers. **5. Roots Below:** protect three root-cutting devices. | **The Rootmother:** rooted hazards and summoned growth | Wayfinder Coin recipe, rare crafting materials, Survival Contracts |
| **7. Coldwater Docks** | **1. Missing Crew:** search moored ships. **2. Between the Cranes:** cross exposed cargo routes. **3. Power on the Pier:** defend a generator with narrow approaches. **4. Cast Off:** escort a launch crew and supplies. **5. The Sunken Captain:** board a grounded ship during the tide cycle. | **Captain Undertow:** hooked attacks and deck-wide directional waves | Backpack expansion quest, Shock Mine Kit |
| **8. Whiteout Village** | **1. First Frost:** move between heat sources. **2. Fuel for the Living:** scavenge fuel while managing exposure. **3. Frozen Relay:** restore a beacon under attack. **4. Tracks in the Snow:** follow a creature through reduced visibility. **5. Winter’s Jaw:** hold the central furnace during the final assault. | **The Pale Howler:** cone attacks and destructible ice barriers | Rimebound set, Frost Bow recipe |
| **9. Dead Signal** | **1. Static:** restore the first relay. **2. Blind Approach:** navigate without full map information. **3. Three Towers:** choose relay activation order. **4. Hold the Frequency:** defend a transmission against Siphoners. **5. Storm Above:** climb to and secure the main mast. | **The Antenna Saint:** telegraphed lightning lanes and charged pylons | Stormrunner set, Storm Scepter, Arc Conduit |
| **10. Buried Transit** | **1. Platform Zero:** reopen the station. **2. Wrong Track:** route power through narrow corridors. **3. Last Passenger:** escort survivors between platforms. **4. Signal Red:** manage switches while avoiding moving train hazards. **5. End of the Line:** defend the evacuation platform. | **The Railbreaker:** charges down marked tracks and exposes its flank after impact | Earned secure-stash expansion, advanced crafting, Nightmare access for cleared early zones |

**Zones 11–15 test preparation and combined mechanics.**

| Zone | Five missions | Finale boss | Main progression reward |
|---|---|---|---|
| **11. Ashfall Quarry** | **1. Loose Stone:** navigate falling-rock warnings. **2. Deep Cut:** recover drilling components. **3. The Lift:** defend an elevator while it powers up. **4. Black Powder:** use controlled demolition to open routes. **5. What the Drill Woke:** fight around unstable quarry walls. | **The Stone Maw:** armored plates that break through precise attacks | Stone Lance research, advanced promotion catalysts |
| **12. Quarantine Ward** | **1. Triage:** rescue survivors and collect medicine. **2. Sealed Rooms:** choose which contaminated rooms to enter. **3. Clean Air:** defend filtration machinery. **4. Patient Zero:** track a moving infestation source. **5. The Last Ward:** maintain safe areas while fighting the plague guardian. | **The Plague Matron:** spreading contamination and destructible sacs | Graveward set, improved medkit crafting |
| **13. Glasshouse Labs** | **1. Overgrowth:** cut paths through spreading roots. **2. Specimen Run:** collect samples from optional dangerous chambers. **3. Climate Control:** change greenhouse conditions. **4. The Seed Vault:** defend a fragile objective against Bursters. **5. Garden of Teeth:** destroy regrowing anchor plants. | **The Glass Gardener:** rotating vulnerabilities and summoned root walls | Targeted affix crafting, elemental catalyst conversions |
| **14. Rustwater Refinery** | **1. Fuel Line:** repair pipes and stop leaks. **2. Spark Hazard:** fight around volatile fuel pools. **3. Pressure Locks:** rotate between control points. **4. Burning Route:** escort a tanker through changing hazards. **5. Black Sun Furnace:** shut down the refinery’s corrupted core. | **The Oilbound:** leaves fuel trails that ignite after a warning | Ember Staff promotion recipe, reinforced barricades |
| **15. Rooftop District** | **1. Above the Streets:** cross connected rooftops. **2. Bridge Builders:** secure materials and repair crossings. **3. Signal Fires:** activate separated rooftop beacons. **4. Falling Skyline:** evacuate before sections collapse. **5. Crown of the City:** defend the last roof against aerial and ground attacks. | **The Sky Reaver:** landing zones, dive attacks, brief grounded damage windows | Legendary crafting access, advanced class trials |

**Zones 16–20 are the campaign’s hardest expeditions.**

| Zone | Five missions | Finale boss | Main progression reward |
|---|---|---|---|
| **16. Broken Reservoir** | **1. Spillway:** cross changing water routes. **2. Turbine Hall:** restart machinery while holding attack lanes. **3. Controlled Release:** redirect water to expose paths. **4. Flood Warning:** rescue workers and prepare the refuge. **5. The Dam Keeper:** manage gates during the boss battle. | **The Dam Keeper:** attacks change with water level | Ward Projector recipe, advanced defensive crafting |
| **17. Hollow Bunker** | **1. Access Denied:** recover security keys. **2. Red Corridor:** disable traps while under pressure. **3. Emergency Protocol:** defend a console against mixed enemy waves. **4. Containment Failure:** choose which containment doors to open. **5. The Old Commander:** break a fortified command room. | **The Hollow Marshal:** switches between ranged, shielded, and assault phases | Legendary equipment choice, bunker weapon appearances |
| **18. Storm Coast** | **1. Weather Window:** cross exposed ground between lightning cycles. **2. Broken Lighthouse:** restore rotating safe-light coverage. **3. Grounding Rods:** protect three rods in a chosen order. **4. Eye of the Storm:** scavenge while power fails intermittently. **5. The Tempest Gate:** maintain refuge power during a coastal siege. | **The Tempest Colossus:** moving electrical lanes and vulnerable grounded phases | Mythic component contracts, final facility-rank components |
| **19. Nightfall Core** | **1. Beyond the Veil:** enter shifting terrain. **2. Three Seals:** choose the order of elemental encounters. **3. Echoes of Haven:** fight distorted versions of familiar enemy formations. **4. The Broken Circle:** defend multiple ritual anchors. **5. Heart of the Hollow:** shut down the source’s protective network. | **The Hollow Regent:** combines previously taught mechanics with clear phase transitions | Eclipse set, Hollow Prism, first Mythic crafting blueprint |
| **20. Last Beacon** | **1. Gather the Living:** rescue remaining survivor groups. **2. The Final Convoy:** escort people and supplies to the beacon. **3. Build the Line:** prepare several defense positions. **4. Until First Light:** survive a multi-stage assault with brief repair intervals. **5. Dawn or Darkness:** protect the beacon and confront the source of the Sundering. | **The Night Sovereign:** three phases testing movement, target priority, and refuge defense | Campaign completion, chosen Mythic crafting core, endgame expeditions, Dawnkeeper cosmetic |

That is **100 named missions**, with a different central pressure in each zone.

---

**16. Zone 1 should demonstrate the entire game without overwhelming the player**

The first zone deserves especially careful pacing.

| Mission | Target duration | New lesson | Guaranteed first-clear reward |
|---|---:|---|---|
| A Light in the Garage | 4 min | Move, attack, dodge, construct one barricade | Service Pistol, access to Haven |
| Supply Run | 4–5 min | Backpack, secure slots, optional detour, extraction | Outrider Hood |
| Keep It Running | 5 min | Temporary upgrades and defending machinery | Bolt Turret blueprint, Outrider Coat |
| Someone on the Radio | 5–6 min | Escort positioning and repair decisions | Engineer unlock, Outrider Boots |
| Hold Until Dawn | 6–8 min | Prepare a refuge and learn a boss pattern | Choose a Rare weapon, body armor, or gadget |

A player finishes Zone 1 with:

- Two available classes.
- A complete introductory set.
- A chosen Rare item.
- A clear understanding of stash protection.
- Experience using both a weapon and magic.
- A home base worth returning to.

The first boss should be threatening, but the player should understand its charge after seeing it once.

---

**17. Stars, loot, and reward cadence**

Each mission awards up to three stars:

1. Complete the main objective.
2. Complete a mission-specific secondary objective.
3. Complete a mastery objective.

Examples:

- Extract both survivors.
- Keep the generator above 40% health.
- Defeat both optional elites.
- Clear without a rescue.
- Finish before an explicit time target.

Avoid making every third star a speed requirement; that would undermine scavenging and defensive classes.

Stars are permanent, and a player can improve them on later runs. Paid boosts do not directly award stars.

**Zone milestones**

Each zone has 15 possible stars.

| Stars | Reward |
|---:|---|
| 5 | Credits equal to roughly three standard clears of that zone |
| 10 | Parts bundle and one equipment-cache key |
| 15 | Gems plus a zone cosmetic or targeted crafting reward |

**Standard successful-mission reward targets**

Before optional loot and special events:

- Credits: approximately `120 + 45 × zone`.
- Parts: approximately `3 + floor(zone ÷ 2)`.
- Survivor XP: approximately `70 + 15 × zone`.
- Class Mastery XP: approximately `40 + 5 × zone`.
- Zone finales: approximately +50% to these baseline rewards.

That gives:

| Zone | Credits | Parts | Survivor XP | Class Mastery XP |
|---:|---:|---:|---:|---:|
| 1 | 165 | 3 | 85 | 45 |
| 5 | 345 | 5 | 145 | 65 |
| 10 | 570 | 8 | 220 | 90 |
| 15 | 795 | 10 | 295 | 115 |
| 20 | 1,020 | 13 | 370 | 140 |

These are successful-run economy targets, not a promise that every enemy drops the same amount. On failure, players keep only what the persistence rules allow; no completion bonus is awarded.

**First-clear equipment rewards**

- Zones 1–5 finales: chosen Rare item.
- Zones 6–15 finales: chosen Epic item.
- Zones 16–20 finales: chosen Legendary item.
- Zone 20 also grants the first chosen Mythic crafting core.

First-clear choices prevent a player from remaining blocked solely because the correct item never dropped.

**Gem rewards**

A starting campaign proposal:

- 10 Gems per first mission clear.
- An additional 30 Gems per first zone-finale clear.
- A 15-star zone reward of `30 + 5 × zone` Gems.

That totals **3,250 one-time campaign Gems** across all 100 missions and full zone completion.

Repeatable gem earnings come primarily from weekly goals and limited challenge rewards, not unlimited low-level farming.

---

**18. Chests and equipment targeting**

Four clear chest categories:

| Chest | Contents |
|---|---|
| **Supply Crate** | Credits and Parts |
| **Weapons Cache** | Weapon or charm |
| **Armor Locker** | Helmet, body armor, or boots |
| **Engineer’s Case** | Gadget, gadget materials, or known blueprint fragments |

Before opening, show the available pool, probabilities, and guarantee progress.

Suggested equipment-quality distributions:

| Campaign progress | Common | Uncommon | Rare | Epic | Legendary |
|---|---:|---:|---:|---:|---:|
| Zones 1–5 | 55% | 30% | 13% | 2% | 0% |
| Zones 6–10 | 30% | 35% | 27% | 7% | 1% |
| Zones 11–20 | 15% | 30% | 38% | 14% | 3% |

These distributions apply to the proposed standard equipment cache. Special rewards must clearly identify a different pool.

**Guarantees**

- At least one Rare-or-better result within 10 equipment-cache openings.
- At least one Epic-or-better within 30.
- Once Legendary rewards are unlocked, one within 80.
- Getting the relevant rarity early resets that rarity’s counter.
- Counters persist between sessions.
- Earned keys, ad-earned keys, and purchased openings count equally.
- Mythic equipment is crafted, not included in these random rolls.

Use a shared guarantee track across equipment caches so switching from weapons to armor does not discard progress.

Players also need targeted paths:

- Zone bosses favor their zone’s sets.
- Contracts advertise their equipment category.
- A weekly crafting project allows selection of a particular missing piece.
- Duplicates contribute toward promotion.

Random loot creates excitement; targeted progression ensures effort still matters.

---

**19. Other game modes that help a stuck player**

These modes should solve different needs instead of all being another version of the campaign.

| Mode | Unlock | Typical length | Main rewards | Challenge |
|---|---|---:|---|---|
| **Salvage Contracts** | Zone 1, Mission 3 | 3–5 min | Credits, Parts, targeted equipment categories | Short objectives with optional risks |
| **Endless Night** | Finish Zone 1 | 8–15 min or longer | Materials, milestone caches, weekly rewards | Escalating waves; bank or continue every five waves |
| **Arcane Trials** | Unlock Arcanist | 4–6 min | Spell research and reforge materials | Specific elemental or movement challenges |
| **Haven Siege** | Finish Zone 5 | 6–8 min | Structure blueprints and camp materials | Preparation and defense layouts |
| **Bounty Hunts** | Finish Zone 7 | 4–7 min | Boss catalysts and targeted set pieces | Mechanically demanding single-boss encounters |
| **Nightmare Expeditions** | Finish Zone 10 | 6–10 min | Legendary progression, cosmetics, later Mythic components | Replay cleared missions with explicit modifiers |

**Endless Night banking**

Every five waves, the player can:

- Extract and bank everything.
- Secure one additional carried reward and continue.
- Risk the remaining unsecured rewards for a higher-tier chest.

Previously banked rewards are safe.

**Nightmare modifiers**

Examples:

- **Blackout:** reduced visibility; lantern placement matters.
- **Armored Advance:** more armored enemies; fewer fast enemies.
- **Unstable Ground:** visible hazards periodically close routes.
- **Hungry Machines:** structures require more repairs.
- **Arcane Surge:** stronger elemental effects for both sides.
- **Relentless:** shorter gaps between waves.

Modifiers are visible before entry. Their purpose is to change preparation and play, not secretly invalidate the player’s equipment.

---

**20. Daily and weekly reasons to return**

Use a small number of understandable systems.

**Seven-claim supply calendar**

A proposed sequence:

1. Credits.
2. Parts.
3. Equipment key.
4. Reforge material.
5. Gems.
6. Targeted contract ticket.
7. Choose one of three equipment rewards.

Missing a day pauses progress rather than deleting the sequence.

**Daily contracts**

Offer five, with three needed for the full daily reward.

Examples:

- Complete two expeditions.
- Secure three loot items.
- Defeat two elites.
- Repair structures for a total amount.
- Clear a contract with a different class.
- Apply two elemental status types in one run.

Do not require buying an item or watching an ad to complete the normal daily track.

**Weekly project**

One substantial objective chosen from several paths:

- Combat path: bosses and elites.
- Scavenger path: recovered materials.
- Defender path: siege and structure objectives.

All paths award the same core weekly reward. The player chooses how to earn it.

This supports different preferences while keeping the economy manageable.

---

**21. Ads and purchases should fit the progression loop**

The business model can sell additional opportunities, faster collection, and attractive equipment progression.

The baseline campaign should have **unlimited attempts**. Repeated practice is important to both skill development and engagement.

**Rewarded ads**

| Placement | Reward | Limit and behavior |
|---|---|---|
| After defeat | One field rescue with 50% HP | Maximum one rescue per mission, regardless of whether it came from an earned token or ad |
| After successful extraction | +25% Credits and Parts from the eligible completion reward | No extra stars, gear rarity, or first-clear Gems |
| At Haven | A standard Supply Crate | Limited daily claims |
| Before deployment | One temporary preparation item, such as a field medkit | Cannot stack with another copy of the same preparation effect |

A rescue:

- Preserves the boss’s remaining health.
- Does not reset class abilities or once-per-mission gadgets.
- Gives a short safe recovery window.
- Does not restore a destroyed mission objective.
- Does not qualify for a “clear without rescue” star.
- Is granted only when the rewarded-ad completion event succeeds.

If an ad is unavailable, the player can retry or return to Haven normally.

**Between-mission ads**

Starting proposal:

- Eligible after every third completed campaign or contract mission.
- At least eight minutes between interstitials.
- No interstitial immediately after a rewarded ad.
- No interstitial immediately after defeat.
- No ads during combat, level-up selection, or equipment comparison.

These are initial product limits to test, not an instruction to show an ad whenever one becomes technically available.

**Purchase products**

| Product | What it provides |
|---|---|
| **Remove Interstitials** | Permanently removes automatic between-mission ads |
| **Starter Expedition Pack** | A chosen Rare item, modest Gems, and a cosmetic |
| **Gem Packs** | Currency for caches and selected convenience purchases |
| **Expedition Pass** | A free reward track and a paid track with cosmetics, keys, and capped materials |
| **Class Appearance Packs** | Outfits, spell appearances, and weapon skins |
| **Targeted Equipment Bundles** | A clearly identified item or choice, with stats visible before purchase |

Buying equipment can accelerate collection and improve build options. It should still respect the player’s current item-level ceiling.

A paid player must still dodge attacks, defend objectives, and understand bosses.

I would avoid selling unlimited stacking combat buffs. Those make encounter balancing nearly impossible and reduce the value of the classes and equipment choices.

Prices and pack sizes should be decided after measuring free earning rates. Otherwise we could accidentally sell either trivial rewards or enough resources to skip the whole game.

---

**22. What happens when someone gets stuck**

Imagine a player failing **Zone 8: Whiteout Village**.

The defeat screen should show useful evidence:

- Most damage received: frost projectiles.
- Furnace failed after fuel was exhausted.
- Two optional fuel caches remained unopened.
- The player’s weapon was below their available upgrade ceiling.

Then present practical options:

- Replay and follow a better fuel route.
- Equip Rimebound pieces.
- Upgrade the current weapon.
- Run a Salvage Contract for Parts.
- Practice the boss through an unlocked training encounter.
- Try Warden for more protection or Scavenger for safer movement.
- Use an earned preparation item.
- Take the optional rewarded rescue when appropriate.

This gives players reasons to return, improve, and sometimes spend. It also makes their eventual victory feel earned.

Do not automatically weaken a boss after exactly three losses or strengthen it because a valuable ad is ready. The encounter rules should remain stable enough for players to learn them.

---

**23. Art direction and presentation**

The reference images point toward:

- Chunky, stylized characters.
- Large, distinct weapons.
- Equipment visible on the character.
- Miniature zone dioramas.
- Strong rarity colors.
- Readable spell effects.
- Satisfying reward reveals.

For Nightfall, use an original **ruined-world arcane workshop** direction:

- Charcoal and deep blue environments.
- Violet for unstable magic.
- Amber for Haven, machinery, and safe light.
- Ice blue for frost.
- Orange-red for fire and danger.
- Ivory for important readable interface text.

Green should not be the default interface color.

Each zone gets a recognizable silhouette: freight cranes, flooded stalls, frozen rooftops, glasshouses, coastal towers, and the final beacon.

Home navigation can use five main destinations:

**Expedition · Equipment · Haven · Classes · Supplies**

Keep the screen cleaner than the reference game’s many competing side buttons. A player should immediately see their character, current destination, and next useful action.

---

**24. Balance checks before we could call this ready**

The plan needs testing against several kinds of player:

- New player with imperfect movement.
- Average player using sensible equipment.
- Skilled player with low-rarity gear.
- Defensive player.
- Aggressive damage-focused player.
- Paying player with faster equipment progression.
- Free player relying on earned upgrades.

Important measures include:

| Measure | What it tells us |
|---|---|
| Attempts to first clear by mission | Where progression becomes too easy or too frustrating |
| Clear rate by class and equipment level | Whether a class or gear requirement dominates |
| Damage source at defeat | Whether deaths are understandable |
| Refuge failure versus player death | Whether construction and combat are balanced |
| Time between meaningful upgrades | Whether progression feels rewarding |
| Time to obtain a targeted item | Whether randomness creates excessive blocks |
| Ability selection and success rates | Whether there are obvious mandatory choices |
| Ad acceptance, completion, and reward delivery | Whether the ad experience works |
| Return rate after repeated defeats | Whether challenge encourages improvement or drives players away |
| Clear rate before and after purchases | Whether purchases overwhelm encounter design |

Specific warning signs:

- One class clears comparable missions far more often than the others.
- One upgrade appears in almost every successful build.
- Players repeatedly die without seeing the attack.
- A required counter depends on a rare random item.
- Farming produces no meaningful improvement over several sessions.
- A revive usually leads to another unavoidable death.
- High-level equipment removes the need to interact with the mission.

**The intended Nightfall experience is a difficult expedition game with persistent rewards:** the player can lose the mission, protect a valuable find, improve their survivor, rethink their build, and return with a better plan. The 100-mission campaign supplies direction; the equipment hunt, class builds, base development, and harder side modes supply the long-term game.
