# Nightfall Main Design Plan

**Visual quality amendment, October 18, 2026:** [Nightfall Visual Quality Plan](VISUAL_QUALITY_PLAN.md) defines the next presentation work: faithfully realize the approved Beaconbound concepts, prove Gear first, then carry the accepted treatment through all five menus. Current functionality is not visual acceptance. This saved plan changes no gameplay, economy or build authorization.

Saved October 18, 2026. Canonical planning baseline approved for preservation by Joshua. Planning and visual exploration only; this document does not authorize game implementation. Numerical balance values are proposals requiring playtesting.

## Decision precedence

**Latest delivery direction, October 18–19, 2026:** Joshua delegated implementation sequencing to the lead engineer, authorized parallel art production beginning with Gear, and requested item details as a popup over the dimmed inventory, preserving the underlying view. Daily objectives and the seven-claim calendar now implement the earlier daily-play proposal. Item Quick Upgrade buys only affordable steps within the existing level cap in one save transaction. The dedicated Astra/high designer owns the [full campaign mathematics and future content package](balance-design/DESIGN_INDEX.md). Internal S–E quality grades are separate from visible rarity, skill rank and drop odds; their distribution is a balancing recommendation, not a fixed percentage quota. These latest instructions supersede the earlier art deferral and fixed-grade-percentage suggestion. Future design data must still be implemented and playtested before it can describe live behavior.

**Permanent skills and equipment amendment, October 18, 2026:** Joshua requested a class skill tree that permanently unlocks the abilities eligible for random in-run level-up offers, three matching items merged into the next rarity even when their substats differ, independently upgradeable/rerollable substats, and equipment set bonuses. Permanent availability is separate from temporary spell ranks, branches and evolutions. The implemented first pass gives each class three starter abilities and five unlock nodes costing nine earned mastery points total. Current playable-zone merging ends at Epic; future Legendary/Mythic progression remains subject to the later-zone design. Merging retains the selected item's substats/ranks and the highest item level from the three copies. Saved builds, locked items and equipped items protect potential donor copies from consumption. See [progression feature QA](PROGRESSION_FEATURES_QA.md) for exact rules, and the dedicated [equipment balance ledger](EQUIPMENT_BALANCE_LEDGER.md) for item values, acquisition sources, current gates and remaining tuning risks. These additions supersede unrestricted spell availability and currency-only rarity promotion in older implementation notes. The visual overhaul is deferred until the feature work is complete.

**Home implementation amendment, October 18, 2026:** Joshua requested five tabs with Expedition in the middle, then authorized building the non-combat product. The implemented order is Shop, Gear, Expedition, Base, Class. Expedition replaces Venture; the Base shortcut uses the same name and destination. The first home pass now includes illustrated Haven facilities, eight equipped slots with vertical five-column inventory, class portraits/mastery, existing mission selection and side-mode entrances, and a Shop with earned-currency purchases and token-matched rewarded-video keys. Ring/Pants share the starter budget: body is 40 HP/15 armor, pants 10 HP/5 armor, pendant 5 HP and ring 5 HP; total starter HP/Power/armor remain 210/40/35. Real-money billing and later zones are still unimplemented. See [home product QA](HOME_PRODUCT_QA.md). This amendment supersedes the older six-slot and implementation-status statements preserved below.

**Equipment and home-layout amendment, October 18, 2026:** Joshua approved the simpler central-model Haven/equipment direction, requested a five-column inventory grid with vertical up/down scrolling instead of horizontal pages, and added Ring and Pants as equipment items. The target loadout now has eight slots: Weapon, Head, Chest, Pants, Boots, Ring, Pendant, Gadget. Four slots flank each side of the character. Character, equipped slots, stats and navigation remain fixed while only the inventory panel scrolls. This explicitly supersedes six-slot and paginated-inventory text preserved below, and permits inventory scrolling while combat controls still fit without scrolling. Haven remains the settlement name; the navigation tab is Base. See the latest [art concept](ART_DIRECTION.md). The runtime still has six slots until an implementation pass updates item definitions, drops/chests, comparisons, save migration and UI together. New slots must be included in the overall stat budget rather than simply adding uncapped power; exact Ring/Pants stats remain to be balanced.

**Combat input amendment, October 18, 2026:** Joshua requested automatic attacks and Dodge as the only manually activated combat ability. Weapons, learned spells, turrets, and offensive/support class powers activate automatically when appropriate. Scavenger Phase Step enhances the player's next Dodge when ready; it never moves the character without input. Movement, upgrade selections, equipment, shrine choices, and construction remain player decisions. This supersedes earlier manual class-power controls. The upper-left attack strip displays selected abilities, ranks/evolutions and cooldowns; tapping inspects a paused run-build panel. Area attacks must communicate their coverage visually.

**Ability-path amendment, October 18, 2026:** Joshua requested visible ability progression inspired by a branching skill-tree reference. The implemented first pass uses rank 1 Learn → rank 2 choose one of two specializations → rank 3 with paired passive evolves. All eight attacks have two behavior-changing specializations with coverage/damage tradeoffs. Chosen paths and pending choices persist inside the active expedition, then reset with the run. Sanctuary, Phantom Flurry and Collapsed Star extend the original five evolution examples. Exact initial values live in `combat_content.gd` and remain balance proposals.

Implementation status, October 18, 2026: Joshua authorized starting the engineering plan. The isolated Godot proof is underway; see [engine proof verification](ENGINE_PROOF_QA.md) for what is built and tested. Historical planning-only statements preserved below describe the design discussion at the time, not a reversal of this later authorization.

The [Nightfall engineering and delivery plan](BUILD_PLAN.md) defines the proposed toolchain, first playable milestone, production order, and acceptance gates. It is planning only; its Godot evaluation is a proposed architecture revision, not an implemented migration.

Later working design discussion and visual concepts for proximity-charged shrines, temporary Relics, level-up choices, mission previews, and rescue screens are preserved in [Shrines and run interface concepts](SHRINES_AND_RUN_UI.md). They extend the plan for review; numerical tuning and individual screen designs are not implemented or playtested.

Art decision, October 18, 2026: Joshua selected Direction B (Beaconbound). Use the chunky illustrated/cel-shaded style shown in [the art review](ART_DIRECTION.md) for continued concept exploration. Individual new designs remain subject to review. This selection does not authorize game implementation or change the campaign rules below.

The campaign rule is: survive timed waves, then kill the boss. No second timer and no survival-only clear. Extra rewards come from performance and collection. This plan supersedes the earlier extraction/objective campaign and the Nightfall prototype brief in ../expansion-brief/GAME_DESIGNS.md. Existing code is not evidence that this plan has been implemented.

The complete approved conversation plan is preserved below without abridgment. Earlier detailed proposals are preserved separately in [the historical design archive](archive/2026-10-18-earlier-objective-design.md); its campaign and extraction requirements are superseded. Read [the art concept brief](ART_DIRECTION.md) for the pending visual review.

---

**Nightfall’s main campaign is now locked around one repeatable loop: survive the timed waves, then kill the boss.** There is no second timer, extraction requirement, or alternative survival victory. Equipment, temporary upgrades, scavenging, and optional defenses help you reach that kill.

This replaces the earlier campaign objectives involving escorts, generators, and extraction. Those ideas belong in separate modes.

The following is the updated full working plan. All numbers remain proposed starting values for future balancing; nothing is being built yet.

---

**1. The main campaign loop**

Before entering, the player chooses a class, six equipment pieces, and an optional preparation item.

During the round:

1. Fight increasingly dangerous enemy waves.
2. Collect Combat XP and choose temporary abilities.
3. Gather supplies, discover equipment, and secure valuable finds.
4. Spend Field Scrap on optional defenses.
5. When the wave timer reaches zero, the boss appears.
6. Kill the boss to clear the mission and unlock the next one.

**The boss fight continues until the boss dies or the player is defeated.**

There is no automatic victory from surviving long enough, no sudden timer-based death, and no hidden requirement to purchase enough damage.

| Campaign section | Normal-wave duration | Expected boss-fight duration* |
|---|---:|---:|
| Zone 1 | 4 minutes | 45–90 seconds |
| Zones 2–5 | 5 minutes | 45–120 seconds |
| Zones 6–20 | 6 minutes | 60–150 seconds |

*Boss durations are balancing targets, not countdowns or restrictions.*

Skilled players with strong builds finish sooner. A defensive player can take longer, provided they can keep surviving and dealing damage.

**Boss arrival rules**

- A visible warning appears during the final ten seconds.
- Normal timed spawning stops when the boss arrives.
- Existing enemies remain, so preparing the battlefield matters.
- Bosses can summon limited reinforcements through specific attacks.
- Your health, Combat Level, spells, cooldowns, and surviving structures carry into the fight.
- Boss reinforcements have capped numbers and rewards, preventing unlimited farming.
- Killing the boss immediately ends combat and collects remaining nearby drops.
- A simultaneous player-and-boss death counts as a clear if the killing blow registered before the defeat state.

**Possible outcomes**

| Outcome | Result |
|---|---|
| Boss killed | Mission cleared; next mission unlocked; carried loot banked |
| Player defeated, then successfully rescued | Continue the same fight; boss health stays where it was |
| Player defeated without rescue | Mission failed; secure-stash rules apply |
| Player abandons the attempt | No clear or completion rewards; only already secured rewards persist |

Optional buildings can be destroyed without failing the mission. **The only required campaign victory condition is killing the final boss.**

---

**2. How the five missions in each zone differ**

Every zone follows a familiar progression:

| Mission | Wave emphasis | Final encounter |
|---|---|---|
| **1 — Arrival** | Introduces the zone’s enemies and terrain | Bruiser captain |
| **2 — Pressure** | More flankers and movement pressure | Hunter captain |
| **3 — Infestation** | Mixed enemies and support units | Caller captain |
| **4 — Stronghold** | Tougher combinations and fewer easy positions | Guardian captain |
| **5 — Dominion** | The zone’s strongest wave composition | Signature zone boss |

These are encounter patterns, not different game modes.

All five still mean: **survive waves, kill boss, collect rewards.**

The first four bosses use shared behavior foundations with distinctive appearances and zone-specific variations. Mission 5 gets a more elaborate signature encounter. That gives us 100 named encounters without requiring 100 completely separate combat systems.

| Boss foundation | Core behavior | What the player learns |
|---|---|---|
| **Bruiser** | Heavy swings, charges, recovery windows | Dodge deliberately and punish missed attacks |
| **Hunter** | Dashes, repositioning, ranged attacks | Keep moving and control distance |
| **Caller** | Summons, area attacks, fragile support units | Prioritize threats and preserve damage windows |
| **Guardian** | Directional defenses, slow pressure, exposed flanks | Positioning and attack timing |
| **Signature boss** | Combines the zone’s established mechanics | Apply what the previous missions taught |

No boss requires a particular class, purchased item, or exact elemental weapon. Matching a build to the encounter should help without becoming an absolute gate.

---

**3. Permanent progression versus the build inside a round**

| System | Persists? | Purpose |
|---|---:|---|
| Survivor Level | Yes | Base health and feature progression |
| Class Mastery | Yes | Class-specific talents |
| Equipment levels and rarity | Yes | Permanent combat strength and specialization |
| Haven facilities | Yes | Crafting, storage, preparation, and research |
| Mission clears and mastery medals | Yes | Campaign access and milestone rewards |
| Combat Level | No | Temporary spells and upgrades |
| Field Scrap | No | Construction and repairs during the attempt |
| Field structures | No | Support for that attempt |
| Newly found unsecured loot | Only after victory | Risk and reward during the attempt |

Proposed caps:

- **Survivor Level:** 40.
- **Class Mastery:** 20 per class.
- **Equipment Level:** 30.
- **Combat Level:** 12 per attempt.

Survivor Level starts at **120 base HP**, adding **4 HP per level**, reaching **276 base HP** at level 40.

Most permanent damage growth comes from equipment. Survivor levels do not also multiply weapon damage, spell damage, and every other offensive statistic.

A typical round should offer approximately:

- Zone 1: 5–7 temporary upgrade selections.
- Later zones: 8–11 selections.

XP already earned is retained on defeat. Temporary combat upgrades are not.

---

**4. Classes**

All four classes share inventory and campaign progress. Switching classes at Haven is free.

| Class | Starting strengths | Class ability | Unlock |
|---|---|---|---|
| **Scavenger** | +5% movement speed; +15% pickup radius | **Phase Step:** short invulnerable dash; 12-second cooldown | Starting class |
| **Engineer** | +20% repair speed; personal structures gain +10% HP | **Repair Swarm:** restores 20% of one structure’s HP over four seconds; 24-second cooldown | Clear Zone 1, Mission 4 |
| **Warden** | +10% maximum HP; +18 armor | **Aegis:** shield worth 20% maximum HP for four seconds; 22-second cooldown | Clear Zone 2 |
| **Arcanist** | +8% elemental damage | **Rift Pulse:** nearby enemies take 120% of Power; ordinary enemies are pushed back; 16-second cooldown | Clear Zone 3, Mission 3 |

**Class mastery milestones**

| Class | Mastery 5 | Mastery 10 | Mastery 15 | Mastery 20 |
|---|---|---|---|---|
| Scavenger | Reveal containers within 8 m | Phase Step removes slows | First hit after Phase Step deals +25% damage | Survive one lethal hit at 1 HP per attempt |
| Engineer | Construction costs 10% less scrap | Repair Swarm briefly increases one turret’s attack speed by 15% | Dismantling returns 40% of construction cost | Repair Swarm also restores 5% HP to one adjacent structure |
| Warden | +10 armor near your deployed structures | Aegis prevents interaction interruption | Absorbing a hit empowers the next basic attack by 50% | Aegis also shields one nearby structure |
| Arcanist | Elemental bonus increases to 12% | Rift Pulse echoes once at 25% strength | Applying two elemental statuses grants +10% spell damage for four seconds | Rift Pulse cooldown becomes 14 seconds |

Only the selected class’s talents apply. A rescue does not reset once-per-attempt talents.

Each class should have multiple viable builds. Engineer should remain capable of winning without a perfect turret setup, and Arcanist should not be the only class that benefits from magic.

---

**5. Equipment and combat statistics**

Six slots:

**Weapon · Helmet · Body Armor · Boots · Charm · Gadget**

**Baseline statistics**

| Stat | Starting value | Proposed limit |
|---|---:|---|
| Critical chance | 5% | 25% permanent; 40% including combat upgrades |
| Critical damage | 150% | 200% total |
| Movement speed | 4.0 m/s | +15% permanent; +30% sustained total |
| Cooldown reduction | 0% | 15% permanent; 30% total |
| Elemental resistance | 0% | 25% permanent; 40% total |
| Dodge | One charge | Six-second recharge |
| Combat XP bonus | 0% | +10% permanent; +25% total |

Physical damage reduction:

`Armor ÷ (Armor + 150)`

Armor-based reduction caps at 50%. Additional applicable reductions combine multiplicatively, with an overall 65% ceiling before shields.

Elemental attacks use their applicable resistance; they do not automatically receive both physical armor reduction and elemental resistance.

**Starting defensive equipment**

| Slot | Level 1 Common stats |
|---|---|
| Helmet | +20 HP, +10 armor |
| Body armor | +50 HP, +20 armor |
| Boots | +10 HP, +5 armor |
| Charm | +10 HP |
| Gadget | Its specific utility effect |

**Rarities**

| Rarity | Color | Primary-stat multiplier | Affix slots |
|---|---|---:|---:|
| Common | Gray | ×1.00 | 0 |
| Uncommon | Blue-gray | ×1.04 | 1 |
| Rare | Blue | ×1.08 | 1 |
| Epic | Violet | ×1.12 | 2 |
| Legendary | Amber | ×1.16 | 3 |
| Mythic | Crimson | ×1.20 | 3 plus a selectable signature effect |

Primary-stat scaling:

`Base stat × [1 + 0.05 × (equipment level − 1)] × rarity multiplier`

A weapon with 40 starting Power reaches **117.6 Power at level 30 Mythic** before other bonuses.

The equipment-level ceiling rises with campaign progress:

`Minimum of 30 and [4 + highest unlocked zone + floor(zone ÷ 3)]`

That allows useful farming while preventing a player from purchasing level-30 strength during Zone 1.

**Weapon roster**

| Weapon | Starting basic damage | Role |
|---|---|---|
| Service Pistol | 24 damage every 0.60 seconds | Reliable general-purpose weapon |
| Pump Shotgun | Five 14-damage pellets every 1.75 seconds | Close-range burst |
| Hunting Rifle | 72 damage every 1.80 seconds | Long-range precision |
| Salvage Repeater | 10 damage every 0.25 seconds | Continuous pressure |
| Runeblade | 40 damage every second, up to three targets | Close-range sweeping attacks |
| Ember Staff | 32 impact plus 8 burn damage every second | Fire specialization |
| Frost Bow | 48 damage every 1.20 seconds | Slower attacks with control |
| Storm Scepter | 28 primary plus 12 secondary damage every second | Groups and chained attacks |

All have a starting **Power of 40** for scaling spells and gadgets. Their real effectiveness varies with range, accuracy, coverage, and enemy arrangement.

**Equipment improvements**

- Upgrading is guaranteed.
- Promotion preserves item level.
- Reforging changes a selected affix.
- Salvage converts unwanted equipment into materials.
- Transferring investment to another item in the same slot returns 80% of spent upgrade Credits and Parts.
- Mythic equipment is crafted from chosen Legendary equipment and earned endgame components.

Affixes remain modest: generally +2–4% damage, +1–2% critical chance, +2–4% HP, or +1–3% cooldown reduction per eligible affix.

---

**6. Sets, charms, and gadgets**

Each armor set contains a helmet, body piece, and boots.

| Set | Two-piece benefit | Three-piece benefit |
|---|---|---|
| **Outrider** | +15% pickup radius | +1 secure-stash slot |
| **Ironwatch** | +12 armor | Dodge or Aegis grants a small shield; 12-second internal cooldown |
| **Scrapwright** | +10% repair speed | One turret gains +10% damage |
| **Cinderweave** | +6% fire damage | Burning kills cause a small explosion, at most once per second |
| **Rimebound** | +8% frost resistance | Chilled enemies deal 5% less damage to you |
| **Stormrunner** | +5% movement speed | Dodging empowers the next hit with lightning; eight-second cooldown |
| **Graveward** | +6% maximum HP | Health pickups also provide a small temporary shield |
| **Eclipse** | +5% elemental damage | Three distinct elemental statuses empower the next class ability; 12-second cooldown |

Named charms:

- **Beacon Pendant:** general survival.
- **Hunter’s Sigil:** precision and critical attacks.
- **Ember Locket:** fire.
- **Clockwork Seal:** gadgets and cooldowns.
- **Wayfinder Coin:** collection and Combat XP.
- **Hollow Prism:** elemental combinations.

Named gadgets:

| Gadget | Effect |
|---|---|
| **Field Medkit** | Once per attempt, restores 20% HP when health falls below 25% |
| **Survey Lantern** | Reveals nearby containers and hidden enemies |
| **Repair Drone** | Slowly repairs structures outside nearby combat |
| **Shock Mine Kit** | A dodge periodically leaves a damaging mine |
| **Ward Projector** | Grants a 10%-HP shield when the boss arrives |
| **Decoy Beacon** | Once per attempt, distracts ordinary enemies at low health; bosses ignore it |

The Ward Projector now triggers on **boss arrival**, replacing its previous extraction-based trigger.

---

**7. Temporary magic and combat builds**

Every class can use magic.

Each attempt supports:

- Equipped weapon.
- Class ability.
- Up to three learned automatic abilities.
- Up to three passive upgrade types.

| Ability | Rank 1 effect | Cooldown |
|---|---|---:|
| **Ember Bolt** | 90% Power impact plus 30% Power burn | 5 sec |
| **Frost Ring** | 65% Power nearby damage and brief chill | 8 sec |
| **Chain Spark** | Three hits at 70%, 45%, and 30% Power | 7 sec |
| **Orbiting Wisp** | 25% Power contact damage; per-target hit limit | Continuous |
| **Stone Lance** | 140% Power through up to three targets | 9 sec |
| **Consecrated Ground** | 20% Power per second for four seconds | 12 sec |
| **Spectral Blades** | Two blades, each dealing 55% Power | 6 sec |
| **Gravity Knot** | Pulls ordinary enemies together; 40% Power damage | 12 sec |

Passive options include:

- **Heavy Rounds:** basic damage.
- **Quick Hands:** attack speed.
- **Arcane Focus:** spell damage.
- **Vital Reserve:** maximum HP.
- **Fleet Foot:** movement.
- **Field Mechanic:** repairs and structure damage.
- **Magnetic Harness:** pickup radius.
- **Steady Breathing:** stronger health pickups.
- **Piercing Shot:** one additional penetration.
- **Efficient Channel:** cooldown reduction.

Abilities generally have three ranks. An evolution replaces the third rank when its pairing requirement is met.

Examples:

- Ember Bolt + Arcane Focus → **Wildfire Bolt**.
- Frost Ring + Vital Reserve → **Winter Halo**.
- Chain Spark + Field Mechanic → **Thunder Relay**.
- Orbiting Wisp + Magnetic Harness → **Soul Lantern**.
- Stone Lance + Piercing Shot → **Rift Spear**.

Bosses resist hard crowd control. Freeze and pull effects contribute to a short stagger opportunity rather than permanently disabling them.

Secondary attacks cannot recursively trigger themselves. Burns and shields have explicit stacking limits.

---

**8. Scavenging, the secure stash, and optional building**

The arena contains supplies, containers, destructible props, and optional elite encounters.

These are opportunities rather than required objectives.

**Inventory**

- Starting backpack: eight slots.
- Two of those slots are secure.
- Campaign upgrades expand the backpack to twelve.
- Zone 10 unlocks an earned third secure slot.
- Outrider’s set bonus can add one more secure slot.

**On victory:** bank all carried loot.

**On defeat:** keep previously owned equipment, secured new items, earned Survivor XP, Class Mastery XP, and collected Credits. Lose unsecured new equipment and material bundles. No mission-completion bonus is awarded.

**Optional field structures**

| Structure | Scrap | Capacity | Function |
|---|---:|---:|---|
| Scrap Barricade | 20 | 1 | Blocks enemies and buys time |
| Bolt Turret | 50 | 3 | Consistent single-target damage |
| Ember Trap | 30 | 1 | Periodic area damage |
| Ward Pylon | 40 | 2 | Small protective shield pulses |
| Repair Station | 45 | 2 | Limited structure-repair charges |
| Arc Conduit | 55 | 3 | Damage across several enemies |
| Signal Lantern | 25 | 1 | Reveals concealed enemies and improves local visibility |

Typical construction capacity is eight, rising to twelve in selected arenas. At most two damaging turrets can be active.

Structures remain through the boss fight. Boss attacks can destroy them, so placing everything together is risky.

A player can win through a mobile build with no construction. An Engineer can invest heavily in a defensive position. Both should be legitimate approaches.

**Haven remains persistent**

- Beacon Core: campaign and settlement progression.
- Armory: inventory and loadouts.
- Workshop: upgrading, promotion, salvage.
- Training Yard: class mastery and boss practice.
- Arcanum: spell and evolution research.
- Quartermaster: backpack, stash, contracts.
- Infirmary: preparation items and rescue-token storage.

No offline attacks destroy Haven, and no construction timers are required in the initial design.

---

**9. Mastery and extra rewards**

Every mission has **three permanent medals**.

| Medal | Requirement | Reward |
|---|---|---|
| **Clear** | Kill the boss | Next mission, standard rewards, first-clear bonus |
| **Combat Mastery** | Clear without rescue and stay within the displayed damaging-hit limit | One-time combat reward |
| **Scavenger Mastery** | Clear after collecting the displayed number of supply caches | One-time collection reward |

Starting mastery targets:

| Zones | Combat Mastery hit allowance | Supply-cache target |
|---|---:|---:|
| 1–5 | At most 8 damaging hits | 3 caches |
| 6–10 | At most 7 damaging hits | 4 caches |
| 11–15 | At most 6 damaging hits | 4 caches |
| 16–20 | At most 5 damaging hits | 5 caches |

These numbers need testing. They are **extra-reward challenges**, never mission-clear conditions.

A continuous damage effect counts as one damage incident over a short defined window rather than ten separate hits. Fully absorbed shield hits do not count.

Medals can be earned across different successful attempts. Once earned, they remain earned.

**Rewards during a run**

- Ordinary enemies: XP, Credits, occasional scrap.
- Elites: better material bundles and a chance of equipment.
- Supply caches: Parts, Credits, equipment, or preparation materials.
- Captains: standard boss rewards and a chance at a zone item.
- Signature zone bosses: guaranteed equipment plus a zone crafting material.

Starting repeat-drop proposal:

- Mission 1–4 boss: **35% chance of a zone equipment item**.
- Mission 5 boss: **one guaranteed equipment item and one zone material**.
- Optional elite equipment chances are lower and limited by the number of elites in the round.

**Standard successful-clear reward targets**

| Zone | Credits | Parts | Survivor XP | Class Mastery XP |
|---:|---:|---:|---:|---:|
| 1 | 165 | 3 | 85 | 45 |
| 5 | 345 | 5 | 145 | 65 |
| 10 | 570 | 8 | 220 | 90 |
| 15 | 795 | 10 | 295 | 115 |
| 20 | 1,020 | 13 | 370 | 140 |

Mission 5 receives approximately 50% more baseline rewards.

**Zone milestone rewards**

Each zone has fifteen medals.

- **5 medals:** Credits equal to roughly three standard clears.
- **10 medals:** the zone’s targeted equipment or blueprint choice, plus materials.
- **15 medals:** Gems and the zone’s named cosmetic.

A player who clears all five missions earns at least five medals and can move on. Better performance and more thorough collection unlock the rest.

First clears award 10 Gems per mission, plus 30 additional Gems for the zone finale. A full-mastery zone awards `30 + 5 × zone` Gems.

---

**10. The twenty zones: bosses and extra rewards**

The captain names below correspond to Missions 1–4, in order: **Bruiser, Hunter, Caller, Guardian**. Mission 5 ends with the signature boss.

All bosses are defeated through combat. Any environmental effect described below is part of fighting and positioning, not a separate puzzle or mission objective.

### Zone 1 — Blackout Outskirts

**Arena:** garages, broken roads, abandoned yards.  
**Theme:** learn movement, collection, and simple defenses.

**Captains**
1. **Garage Mauler:** slow overhead strike and a short charge.
2. **Fence Runner:** a clearly marked straight dash followed by recovery.
3. **Porchcaller:** summons small Drifter groups.
4. **Scrapback:** protected front and exposed rear.

**Signature boss: The Breaker**
- **Rush:** marks a straight lane before charging.
- **Ground Slam:** close circular attack.
- **Rubble Toss:** throws three clearly marked projectiles.
- Below 50% HP, a charge can be followed by a slam, with a visible pause between them.
- Missing a charge creates its longest damage window.

**Extra rewards**
- Zone material: **Breaker Plate**.
- Equipment pool: Outrider set, Service Pistol, Field Medkit.
- Ten-medal reward: choose a Rare pistol, Outrider piece, or medkit.
- Fifteen-medal cosmetic: **Garage Lantern** decoration.
- Progression: Bolt Turret blueprint; Engineer unlock after Mission 4.

### Zone 2 — Freight Yard

**Arena:** container lanes and open loading areas.  
**Theme:** flanking armored targets.

**Captains**
1. **Dockhammer:** heavy swings through narrow lanes.
2. **Railhook:** pulls toward a marked impact point.
3. **Manifest Keeper:** summons enemies from visible container entrances.
4. **Container Guard:** directional shield with a slow turning rate.

**Signature boss: Chainjaw**
- **Chain Sweep:** broad arc; safe space close behind it.
- **Hook Cast:** straight pull attack that can be dodged.
- **Anchor Drop:** delayed impact on the player’s previous position.
- Below 50%, performs two hook attacks before recovery.

**Extra rewards**
- Material: **Chainlink Core**.
- Pool: Ironwatch set, Hunting Rifle, Hunter’s Sigil.
- Ten medals: choose a Rare Ironwatch piece or Hunting Rifle.
- Fifteen medals: **Freight Hauler** backpack appearance.
- Progression: Warden class and expanded contracts.

### Zone 3 — Silent Suburbs

**Arena:** streets and garden walls; movement remains continuous outdoors.  
**Theme:** identifying real threats among distractions.

**Captains**
1. **Doorbreaker:** a short forward burst followed by a wide swing.
2. **Windowshade:** repositions behind cover before firing.
3. **Hearth Whisper:** summons Wisps and fragile decoys.
4. **Pale Watchman:** guard stance interrupted by attacks from its flank.

**Signature boss: The Whisperer**
- **False Company:** creates weak copies with a visibly different outline.
- **Whisper Fan:** spreads slow projectiles with gaps.
- **Hollow Step:** relocates after a marked destination appears.
- Below 50%, copies accompany attacks but never conceal the real boss’s tell.

**Extra rewards**
- Material: **Whisper Shard**.
- Pool: Ember Staff, Beacon Pendant, Survey Lantern.
- Ten medals: choose a Rare staff, pendant, or lantern.
- Fifteen medals: **Twilight Hood** appearance.
- Progression: Arcanist after Mission 3; Arcanum and introductory spell research.

### Zone 4 — Flooded Market

**Arena:** shallow water, stalls, and raised paths.  
**Theme:** choosing safe routes while controlling groups.

**Captains**
1. **Siltbreaker:** splashing slams leave brief slow patches.
2. **Gutter Skater:** dashes along marked water lanes.
3. **Canal Cantor:** summons enemies from fixed drains.
4. **Stallwarden:** shielded advance with an exposed turning animation.

**Signature boss: The Drowned Bell**
- **Bell Wave:** expanding rings with visible openings.
- **Undertow:** pulls toward a marked center before a delayed burst.
- **Floodcall:** summons a capped group of small enemies.
- Below 50%, alternates ring directions rather than merely making them faster.

**Extra rewards**
- Material: **Tidal Brass**.
- Pool: Scrapwright pieces, Pump Shotgun, Repair Drone.
- Ten medals: choose a Rare Scrapwright piece or Repair Drone.
- Fifteen medals: **Market Fountain** decoration.
- Progression: Repair Station and Infirmary.

### Zone 5 — Ironworks

**Arena:** foundry floor with clearly timed furnace hazards.  
**Theme:** armor, positioning, and more demanding boss combinations.

**Captains**
1. **Hammerbound:** two heavy swings with different directions.
2. **Spark Chaser:** dash followed by a short projectile burst.
3. **Furnace Tender:** calls explosive minions.
4. **Plate Sentinel:** armored front with glowing rear vents.

**Signature boss: The Forge Warden**
- **Hammer Arc:** wide melee attack.
- **Furnace Breath:** directional cone that rotates slowly.
- **Molten Steps:** temporary hazards at its recent positions.
- Below 50%, exposes its core after a two-attack combination.
- All builds can damage it; attacking exposed vents improves efficiency.

**Extra rewards**
- Material: **Furnace Heart**.
- Pool: Cinderweave set, Ember Staff, Ember Locket.
- Ten medals: choose a Rare Cinderweave piece or Ember Locket.
- Fifteen medals: **Foundry Glow** weapon appearance.
- Progression: equipment-promotion recipes and Haven Siege.

### Zone 6 — Orchard County

**Arena:** open orchard rows and scattered barns.  
**Theme:** limited cover and controlling space.

**Captains**
1. **Orchard Stomper:** stomps create short root lines.
2. **Briarhound:** fast lunges with a long miss recovery.
3. **Scarecrow Hexer:** calls enemies into marked patches.
4. **Barkbound:** protected stance broken by repositioning.

**Signature boss: The Rootmother**
- **Root Paths:** lines emerge after visible ground cracks.
- **Seed Volley:** slow spreading projectiles.
- **Briar Children:** a limited group of fragile summons.
- Below 50%, combines root lines with projectiles, preserving escape routes.

**Extra rewards**
- Material: **Heartwood Knot**.
- Pool: Wayfinder Coin, Outrider pieces, Runeblade.
- Ten medals: choose an Epic Wayfinder Coin or Outrider piece.
- Fifteen medals: **Harvest Cloak** appearance.
- Progression: higher-tier Salvage Contracts.

### Zone 7 — Coldwater Docks

**Arena:** piers, ship decks, and broad cargo platforms.  
**Theme:** lane control and maintaining escape space.

**Captains**
1. **Bilge Mauler:** heavy directional strikes.
2. **Hookrunner:** fast hook attacks with narrow lanes.
3. **Deck Cantor:** calls enemies from marked boarding points.
4. **Anchor Guard:** slow shielded advance and an anchor sweep.

**Signature boss: Captain Undertow**
- **Anchor Sweep:** punishes staying beside it.
- **Harpoon Line:** marks a straight path before firing.
- **Deck Surge:** sends waves across portions of the arena.
- Below 50%, follows a surge with a harpoon aimed at the player’s earlier location.

**Extra rewards**
- Material: **Anchor Fragment**.
- Pool: Shock Mine Kit, Salvage Repeater, Hunter’s Sigil.
- Ten medals: choose an Epic mine kit or repeater.
- Fifteen medals: **Harbor Lantern** decoration.
- Progression: backpack expansion and Bounty Hunts.

### Zone 8 — Whiteout Village

**Arena:** snowy streets with localized ice patches.  
**Theme:** managing slows without introducing a separate survival meter.

**Captains**
1. **Icebreaker:** delayed frost slam.
2. **Snowstalker:** visible tracks precede a dash.
3. **Rime Caller:** summons fragile frost creatures.
4. **Frostplate:** directional armor and a slow cone attack.

**Signature boss: The Pale Howler**
- **Frozen Breath:** marked cone.
- **Ice Ridge:** creates temporary barriers with navigable gaps.
- **White Leap:** leaps toward a marked landing area.
- Below 50%, breaks its own barriers during a charge, reopening space.

**Extra rewards**
- Material: **Rime Fang**.
- Pool: Rimebound set and Frost Bow.
- Ten medals: choose an Epic Frost Bow or Rimebound piece.
- Fifteen medals: **Snowbound Mantle** appearance.
- Progression: frost-focused crafting.

### Zone 9 — Dead Signal

**Arena:** communications platforms and broken antenna fields.  
**Theme:** moving through alternating attack lanes.

**Captains**
1. **Coilbreaker:** charged melee strikes.
2. **Static Runner:** dash leaves a short-lived lightning trail.
3. **Relay Hexer:** summons capped Siphoner groups.
4. **Mast Sentinel:** shields one direction while charging a ranged attack.

**Signature boss: The Antenna Saint**
- **Crossed Signals:** lightning lines with marked safe lanes.
- **Charged Ground:** delayed strikes at old player positions.
- **Relay Burst:** temporary attack pylons that can be destroyed for easier movement, but are not required objectives.
- Below 50%, combines two line patterns with sufficient warning.

**Extra rewards**
- Material: **Storm Coil**.
- Pool: Stormrunner set, Storm Scepter, Clockwork Seal.
- Ten medals: choose an Epic scepter or Stormrunner piece.
- Fifteen medals: **Signal Halo** appearance.
- Progression: Arc Conduit.

### Zone 10 — Buried Transit

**Arena:** a wide station floor divided by marked tracks.  
**Theme:** planning movement around predictable lanes.

**Captains**
1. **Platform Crusher:** slams across a broad front.
2. **Railstalker:** follows tracks before dashing.
3. **Tunnel Caller:** summons through visible tunnel entrances.
4. **Turnstile Guard:** alternates shield direction.

**Signature boss: The Railbreaker**
- **Express Charge:** rushes along a marked track.
- **Brake Burst:** radial debris attack after stopping.
- **Track Sweep:** traverses one lane while adjacent lanes remain safe.
- Below 50%, performs two charges with a longer recovery afterward.

**Extra rewards**
- Material: **Railbreaker Bearing**.
- Pool: Runeblade, Ironwatch pieces, Ward Projector materials.
- Ten medals: choose an Epic Runeblade or Ironwatch piece.
- Fifteen medals: **Midnight Express** weapon appearance.
- Progression: third secure slot and early-zone Nightmare Expeditions.

### Zone 11 — Ashfall Quarry

**Arena:** quarry shelves connected within one continuous combat area.  
**Theme:** reading ground attacks and exploiting slow enemies.

**Captains**
1. **Quarry Fist:** powerful but slow impacts.
2. **Shard Prowler:** leaps between marked positions.
3. **Dust Speaker:** summons creatures through cracking ground.
4. **Granite Guard:** frontal plates and exposed sides.

**Signature boss: The Stone Maw**
- **Stone Fan:** throws spreading rock projectiles.
- **Fault Line:** delayed straight ground rupture.
- **Burrow Rise:** marked emergence followed by a vulnerable pause.
- Plate breaks expose weak spots but are achieved through ordinary attacks.

**Extra rewards**
- Material: **Quarry Geode**.
- Pool: Stone Lance research materials, defensive gear.
- Ten medals: choose an Epic defensive piece with an armor-focused affix pool.
- Fifteen medals: **Quarry Monument** decoration.
- Progression: advanced promotion catalysts.

### Zone 12 — Quarantine Ward

**Arena:** hospital courtyard and broad treatment corridors.  
**Theme:** avoiding persistent hazards while preserving room to move.

**Captains**
1. **Wardbreaker:** slams leave small contamination pools.
2. **Fever Hound:** lunges followed by a brief exhaustion window.
3. **Blight Nurse:** summons and supports weak enemies.
4. **Isolation Guard:** protected front and a narrow spray attack.

**Signature boss: The Plague Matron**
- **Blight Lob:** throws slow projectiles that leave temporary pools.
- **Spore Burst:** delayed ring attack.
- **Infected Brood:** limited summons.
- Below 50%, pools appear more strategically, but old pools expire so the arena cannot become permanently unusable.

**Extra rewards**
- Material: **Purified Gland**.
- Pool: Graveward set, Field Medkit.
- Ten medals: choose an Epic Graveward piece or medkit.
- Fifteen medals: **Field Medic** appearance.
- Progression: improved preparation-item recipes.

### Zone 13 — Glasshouse Labs

**Arena:** broad greenhouse chambers and garden lanes.  
**Theme:** navigating temporary obstacles.

**Captains**
1. **Vine Mauler:** sweeping vine arms.
2. **Thorn Skipper:** marked leaps and scattered thorns.
3. **Seed Speaker:** summons fragile seed pods.
4. **Glass Sentinel:** rotates a directional protective shell.

**Signature boss: The Glass Gardener**
- **Thorn Lattice:** temporary root walls with openings.
- **Prism Shot:** projectiles refract once from marked surfaces.
- **Bloom Burst:** visible pods explode after a delay.
- Below 50%, alternates open movement phases with short constrained phases.

**Extra rewards**
- Material: **Prism Seed**.
- Pool: elemental charms and reforge materials.
- Ten medals: choose an Epic charm from the unlocked elemental pool.
- Fifteen medals: **Glassflower** decoration.
- Progression: targeted affix crafting.

### Zone 14 — Rustwater Refinery

**Arena:** industrial platforms with clearly marked fuel patches.  
**Theme:** anticipating delayed hazards.

**Captains**
1. **Pipehammer:** long, sweeping melee attacks.
2. **Spark Hound:** quick movement followed by delayed ignition.
3. **Fume Caller:** summons small explosive enemies.
4. **Tank Sentinel:** frontal shielding and slow side attacks.

**Signature boss: The Oilbound**
- **Fuel Cast:** lays visible fuel trails.
- **Ignition:** ignites existing trails after an obvious windup.
- **Pressure Burst:** close attack that discourages remaining underneath it.
- Below 50%, changes trail patterns rather than filling the arena permanently.

**Extra rewards**
- Material: **Refined Emberglass**.
- Pool: Ember Staff, Ember Locket, Cinderweave.
- Ten medals: choose an Epic fire weapon or set piece.
- Fifteen medals: **Refinery Flare** appearance.
- Progression: reinforced barricade research.

### Zone 15 — Rooftop District

**Arena:** connected rooftops with generous walkable surfaces.  
**Theme:** handling mobile bosses and temporary danger zones.

**Captains**
1. **Roofbreaker:** heavy landing attacks.
2. **Gutterwing:** rapid repositioning and short dives.
3. **Rooftop Caller:** summons from visible ledges.
4. **Parapet Guard:** slow pressure with directional protection.

**Signature boss: The Sky Reaver**
- **Marked Dive:** large landing indicator.
- **Feather Blades:** spaced projectile fans.
- **Wing Sweep:** close-range attack after landing.
- Grounded recovery periods provide reliable damage opportunities.
- Below 50%, two dives precede a longer grounded phase.

**Extra rewards**
- Material: **Reaver Pinion**.
- Pool: precision weapons, Hunter’s Sigil, Stormrunner.
- Ten medals: choose an Epic precision item.
- Fifteen medals: **Skyline Cape** appearance.
- Progression: Legendary crafting and advanced class trials.

### Zone 16 — Broken Reservoir

**Arena:** turbine decks and broad spillway platforms.  
**Theme:** reading directional environmental attacks.

**Captains**
1. **Spillway Brute:** heavy directional slams.
2. **Current Runner:** fast sweeps along marked lanes.
3. **Turbine Caller:** summons near inactive machinery.
4. **Gate Sentinel:** shielded stance followed by a vulnerable overhead strike.

**Signature boss: The Dam Keeper**
- **Pressure Jet:** marked directional beam.
- **Spillway Surge:** a moving water hazard with safe routes.
- **Gate Slam:** heavy close attack.
- Below 50%, alternates jet direction before committing.

**Extra rewards**
- Material: **Pressure Crystal**.
- Pool: Ward Projector and defensive equipment.
- Ten medals: choose a Legendary defensive item or Ward Projector.
- Fifteen medals: **Reservoir Beacon** decoration.
- Progression: advanced defensive recipes.

### Zone 17 — Hollow Bunker

**Arena:** a spacious bunker chamber with cover and firing lanes.  
**Theme:** recognizing changing attack stances.

**Captains**
1. **Breach Hammer:** close-range assault attacks.
2. **Redline Scout:** dashes between firing positions.
3. **Command Echo:** calls coordinated reinforcement groups.
4. **Blastdoor Guard:** defensive stance and slow artillery shots.

**Signature boss: The Hollow Marshal**
- **Assault Stance:** close attacks and a short charge.
- **Ranged Stance:** aimed bursts with gaps.
- **Guard Stance:** frontal protection and slower movement.
- Stance changes have distinct animations.
- Below 50%, transitions more frequently, with a punishable pause each time.

**Extra rewards**
- Material: **Command Seal**.
- Pool: Salvage Repeater, Ironwatch, Clockwork Seal.
- Ten medals: choose a Legendary repeater or Ironwatch piece.
- Fifteen medals: **Bunker Veteran** appearance.
- Progression: specialized Legendary recipes.

### Zone 18 — Storm Coast

**Arena:** coastal fort platforms and lighthouse grounds.  
**Theme:** reacting to large patterns while maintaining boss damage.

**Captains**
1. **Breaker of Tides:** heavy wave-shaped attacks.
2. **Stormstalker:** lightning-marked dashes.
3. **Squall Caller:** summons a small airborne group.
4. **Thunder Guard:** directional shield and delayed electric strike.

**Signature boss: The Tempest Colossus**
- **Storm Lanes:** moving electrical lines.
- **Thunderfall:** delayed strikes at marked locations.
- **Grounding Slam:** close impact followed by a vulnerable grounded phase.
- Below 50%, combines moving lanes with fewer, more deliberate strikes.

**Extra rewards**
- Material: **Tempest Heart**.
- Pool: Storm Scepter, Stormrunner, advanced gadget materials.
- Ten medals: choose a Legendary storm item.
- Fifteen medals: **Tempest Crown** appearance.
- Progression: Mythic-component contracts and final facility upgrades.

### Zone 19 — Nightfall Core

**Arena:** broken stone and Emberglass formations.  
**Theme:** combining familiar mechanics rather than introducing obscure new rules.

**Captains**
1. **Rift Mauler:** slams and marked ruptures.
2. **Veil Hunter:** telegraphed relocations and dashes.
3. **Echo Priest:** summons weaker echoes of familiar enemies.
4. **Eclipse Sentinel:** rotates protection and attacks through exposed lanes.

**Signature boss: The Hollow Regent**
- **Rift Fan:** spaced elemental projectiles.
- **Veil Step:** relocates to a clearly marked destination.
- **Echo Court:** limited supporting enemies.
- Below 50%, combines two established patterns.
- No complete elemental immunity; all weapon builds remain viable.

**Extra rewards**
- Material: **Regent Shard**.
- Pool: Eclipse set and Hollow Prism.
- Ten medals: choose a Legendary Eclipse piece or Hollow Prism.
- Fifteen medals: **Veilwalker** appearance.
- Progression: first Mythic equipment blueprint.

### Zone 20 — Last Beacon

**Arena:** the grounds surrounding Haven’s final beacon. The beacon is scenery and cover, not a separate failure objective.  
**Theme:** a final test of movement, build quality, and sustained combat.

**Captains**
1. **Dawn Crusher:** heavy attacks with changing directions.
2. **Last Shadow:** precision dashes and repositioning.
3. **Night Herald:** carefully limited mixed summons.
4. **Crown Sentinel:** directional defenses and combined ranged/melee attacks.

**Signature boss: The Night Sovereign**
- **Phase 1, 100–70% HP:** sweeping attacks and a readable charge.
- **Phase 2, 70–35% HP:** marked projectiles and limited summons.
- **Phase 3, below 35% HP:** combines previously taught attacks, with clear recovery windows.
- Phase transitions do not refill its health.
- No forced damage during transitions.
- No second timer or unavoidable late enrage.

**Extra rewards**
- Material: **Sovereign Ember**.
- Pool: all unlocked set families, weighted toward selected reward categories.
- Ten medals: choose a Legendary item from an unlocked family.
- Fifteen medals: **Dawnkeeper** appearance and final Haven monument.
- First finale clear: chosen Mythic crafting core.
- Progression: campaign completion and full endgame expeditions.

---

**11. How zone materials become useful**

The twenty named zone materials use one familiar crafting system rather than twenty different crafting interfaces.

For example:

- Eight **Rime Fangs** plus ordinary Parts can craft a chosen item from Whiteout Village’s unlocked pool.
- Eight **Storm Coils** can target a Stormrunner piece or Storm Scepter.
- Later promotion recipes also use the relevant zone material.

The exact material cost depends on the recipe and rarity. The eight-material figure is the starting target for an ordinary targeted zone craft.

This creates a dependable reason to replay a zone:

**Even if the desired item does not drop, each boss kill moves the player toward choosing it.**

Unneeded zone materials can eventually be exchanged at a loss through the Quartermaster. They should not become permanent inventory clutter.

---

**12. Difficulty and boss balance**

After Zone 5, unfamiliar frontier missions should be difficult enough that many players lose more attempts than they win.

Starting targets:

- Zones 1–5: approximately 50–85% early-attempt clear rates, with the opening missions easiest.
- Zones 6–10: approximately 35–45%.
- Zones 11–20: approximately 25–40%.
- Mastered farming content: approximately 80–95%.

These are targets for observed player groups, not probabilities assigned to individual runs.

Boss balancing starts from:

- Captain base HP: approximately **1,800**.
- Signature boss base HP: approximately **3,000**.
- Apply the zone health multiplier and a small mission-position multiplier.

Zone health multiplier:

`1 + 0.13(z−1) + 0.002(z−1)²`

Zone damage multiplier:

`1 + 0.16(z−1) + 0.003(z−1)²`

These formulas are starting scaffolding. If a boss becomes tedious, adjust its health and damage opportunities rather than preserving the formula at the expense of the game.

**Required encounter rules**

- Heavy attacks are clearly telegraphed.
- Boss attacks always leave a reachable response for an appropriately positioned player.
- Bosses do not heal indefinitely.
- Summons have caps.
- Persistent hazards expire.
- Defensive builds can finish, though more slowly.
- No specific paid item is required.
- Purchased progression does not change boss AI or secretly alter difficulty.

A player can remain challenged by a zone while improving equipment, learning attacks, or experimenting with builds. Full mastery and Nightmare tiers provide the longest pursuits.

---

**13. Side modes**

These sit outside the straightforward survival campaign.

| Mode | Purpose | Main rewards |
|---|---|---|
| **Salvage Contracts** | Short scavenging, collection, and extraction experiments | Credits, Parts, targeted categories |
| **Endless Night** | Long survival sessions with banking decisions | Materials and milestone caches |
| **Arcane Trials** | Elemental combinations and specialized combat challenges | Spell research and reforge materials |
| **Haven Siege** | Dedicated base-defense play with an objective to protect | Structure and settlement materials |
| **Bounty Hunts** | Replay boss encounters with focused rewards | Zone materials and targeted equipment |
| **Nightmare Expeditions** | Harder versions of cleared survival missions | Legendary progression, cosmetics, Mythic components |

Campaign boss practice should also be available through the Training Yard after encountering that boss. Practice grants no farmable rewards.

That gives a struggling player a way to improve without spending six minutes reaching the same unfamiliar attack every time.

---

**14. Chests, daily rewards, and monetization**

The existing chest categories remain:

- Supply Crate.
- Weapons Cache.
- Armor Locker.
- Engineer’s Case.

Equipment-cache base rarity odds, before guarantee rules:

| Progress | Common | Uncommon | Rare | Epic | Legendary |
|---|---:|---:|---:|---:|---:|
| Zones 1–5 | 55% | 30% | 13% | 2% | 0% |
| Zones 6–10 | 30% | 35% | 27% | 7% | 1% |
| Zones 11–20 | 15% | 30% | 38% | 14% | 3% |

Guarantees remain:

- Rare or better within ten equipment-cache openings.
- Epic or better within thirty.
- Legendary within eighty once unlocked.
- Shared progress across equipment-cache categories.
- Earned, ad-earned, and purchased openings count equally.
- Mythic equipment is crafted.

Daily play supports three activities:

- A seven-claim calendar that pauses when missed.
- A small contract list, with three completions sufficient for the main daily reward.
- One weekly project with combat, scavenging, or defense paths.

**Rewarded-ad placements**

- One optional rescue per attempt, whether obtained through an earned token or an ad.
- Optional +25% eligible Credits and Parts after victory.
- Limited Supply Crate claims at Haven.
- Optional preparation-item claims.

A rescue restores 50% HP and gives a brief safe recovery window. It does not reset boss health, cooldowns, or once-per-attempt effects.

A rescued victory still unlocks the next mission. It does not qualify for the no-rescue Combat Mastery medal.

**Between-round ads**

Initial spacing proposal:

- Eligible after every third completed campaign or contract round.
- At least eight minutes between interstitials.
- Suppress after a rewarded ad.
- Suppress immediately after defeat.
- Never interrupt combat or reward selection.

**Purchases**

- Remove automatic interstitials.
- Starter equipment choice.
- Gems.
- Expedition pass.
- Cosmetics.
- Clearly described equipment bundles.

Purchases can accelerate equipment collection and progression, while respecting campaign equipment-level ceilings. They do not directly grant mission clears or mastery medals.

---

**15. Presentation and what we would validate later**

Art remains stylized and readable: chunky characters, visible equipment, strong attack silhouettes, and original magical salvage machinery.

Palette:

- Charcoal and deep blue environments.
- Amber safe light and machinery.
- Violet unstable magic.
- Ice blue frost.
- Orange-red fire and danger.
- Ivory interface text.

Green is not the default interface color.

The combat screen always fits on the phone. The October 18 reference-layout revision uses a centered wave timer, thin Combat XP bar, chosen ability icons immediately beneath it, compact collection counters, and a small health bar over the character. There is no opaque header card. When the boss arrives, the centered label becomes its name and a thin boss-health bar appears beneath XP; the boss has no deadline. Progress details and instructions are opened deliberately from Pause. Upgrade and shrine choices pause combat and disappear after selection.

The future balance checks need to answer:

- Do all four classes clear the same content at comparable investment?
- Does an ordinary successful round fit the intended session length?
- Are boss deaths understandable?
- Can a player improve meaningfully after several failed attempts?
- Do targeted crafts prevent unreasonable loot droughts?
- Are mobile and defensive builds both viable?
- Are mastery rewards desirable without becoming mandatory?
- Do ad rewards grant exactly what was offered?
- Does equipment progression help without making later bosses irrelevant?

**The updated foundation is now consistent across all 100 campaign missions: prepare a build, survive the waves, kill the boss, and earn additional rewards through performance and scavenging.** Everything else supports that loop or lives in a separate mode.
