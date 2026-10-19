# Leveling, skills and all combat-stat interactions

This document defines the proposed v1 numerical contract. Its tables are expanded arithmetic, not new runtime behavior. Current source anchors are `haven_content.gd`, `skill_tree.gd`, `combat_content.gd`, `run.gd`, `magic.gd` and `field.gd`; changes from those anchors are called out.

## Permanent Survivor and mastery XP

Survivor starts at level 1. Going from level `L` to `L+1` costs `120L` XP. Reaching level `L` therefore costs `60L(L−1)` total. Level 5 needs 1,200; 10 needs 5,400; 20 needs 22,800; 30 needs 52,200; 40 needs 93,600. Level 40 is the cap. Additional XP remains visible as lifetime progress but grants no additional HP. Base HP is 120 plus 4 for each completed level. No permanent damage multiplier is attached to Survivor level.

Class mastery starts at 0 independently for each class. Reaching rank `M` costs `50M(M+1)` cumulative XP; next rank costs `100(M+1)`. Ranks 5, 9, 10, 15 and 20 require 1,500 / 4,500 / 5,500 / 12,000 / 21,000 XP. Only the selected class earns that attempt's mastery. Switching class does not copy accumulated mastery or reset unlocked class abilities.

The complete first-clear plus field-XP economy forecast ends around Survivor 24 and one-class mastery 16 before optional contract XP. Thus the campaign does not require cap-40/cap-20 characters. Final mastery milestones are long-term goals. Splitting evenly among four classes produces lower mastery in each; no required campaign mechanic assumes all four mastery-20 passives.

Earn one skill point at each mastery rank 1–9, nine total. The five nodes cost 1, 1, 2, 2 and 3. Two first-tier branches each begin from an existing starter; their second nodes depend on their first nodes; the capstone needs both second nodes. One branch's second node is affordable at mastery 3, both branches at 6, and the capstone at 9. `class_skill_nodes.csv` lists the actual ability for every class and every edge. There are no negative point balances, prestige loops or temporary-respec refunds during an active attempt.

| Class | Starter draft pool | First nodes, one point each | Second nodes, two points each | Shared capstone, three points |
|---|---|---|---|---|
| Scavenger | Ember, Frost, Chain | Wisp; Blades | Lance after Wisp; Ground after Blades | Gravity after Lance and Ground |
| Engineer | Ember, Chain, Wisp | Frost; Lance | Ground after Frost; Blades after Lance | Gravity after Ground and Blades |
| Warden | Frost, Lance, Ground | Ember; Wisp | Blades after Ember; Chain after Wisp | Gravity after Blades and Chain |
| Arcanist | Ember, Frost, Wisp | Chain; Lance | Blades after Chain; Ground after Lance | Gravity after Blades and Ground |

Permanent availability is not automatic learning. A new attempt has zero learned spells. Training can expose a prescribed kit but grants no permanent eligibility. All baseline build recipes use starter pools, so their mathematical viability does not rely on class-switching immediately supplying nine mastery points.

## Temporary combat levels and XP delivery

Proposed cumulative XP thresholds for levels 1–12 are **0, 16, 40, 70, 108, 154, 208, 270, 340, 418, 504, 598**. Each level gained gives one selection, maximum eleven. This intentionally replaces the proof's `5×current level` next-level requirement when introducing weighted monster XP and six wave segments. Importing the new XP rewards with the old threshold formula would overlevel the player.

Ordinary XP is 1–3 by archetype. An elite conversion adds eight to that same body's normal XP, without adding an extra body. Multiply by zone-band XP scale: 1.00 Zone 1, 1.15 Zones 2–5, 1.35 thereafter. XP is not multiplied by HP, gear level or rarity. Boss reinforcements award at most the encounter's listed reward cap; after that they drop no XP, Credits, materials or scrap. Boss damage and elapsed boss time never produce XP.

`captureFraction` in the forecast is the fraction of all scheduled XP that is both spawned/killed **and** picked up before boss arrival. It includes missed packets, remaining enemies and uncollected drops. It is not merely pickup-radius efficiency. The 60%, 78% and 90% scenarios have no XP affix bonus. Permanent Combat XP bonuses cap at 10%, combined run bonuses at 25%; apply them after capture when constructing a separate scenario.

`mission_xp_forecast.csv` contains all 100 missions at all three capture levels, including the level at each segment's end. The modeled arrival-level range is 5–9 for minimum capture and 6–11 for typical/strong capture. Level 12 should be an exceptional collection/XP investment result, not a routine assumption. A typical late build gets roughly eight to ten choices; early missions fewer. All generated build recipes use the actual integer choice budget for that row.

To audit a schedule: sum each segment's `combat_xp_available`, multiply by capture and XP bonuses, find the highest reached threshold, subtract one for selections. Interpolate collection inside each five-second packet rather than granting a whole segment's XP immediately. First upgrade should occur around 15–30 seconds in initial testing; a faster or slower result is a tuning observation to compare with the actual first-segment kill distribution.

## Draft rules and opportunity cost

Three spell slots and three passive families; each rank costs one selection. Rank 2 chooses one branch; rank 3 preserves it. Evolution requires rank 3 and at least rank 1 of its paired passive. Evolution itself is automatic and does not consume a fourth spell rank or an extra choice. A pair must occupy a passive slot; it is not a free hidden talent.

Three fully ranked spells cost nine choices; three distinct paired passives cost another three, exceeding the eleven-choice ceiling. There is one deliberate shared-pair exception: Frost and Ground both use Vital Reserve. Those two plus any third spell can fully evolve in eleven choices using only two passive picks, if the class has unlocked all three and the draft supplies them. The six exact combinations are in `shared_evolution_combinations.csv`. Their repeated defensive pairing competes with single-target damage, mobility and collection. Merchant traits and relics never satisfy evolution pairs; permanent ownership still grants no starting ranks.

Offer three distinct legal choices. At the first level-up, offer three unlocked learnable starters. Later offers include eligible new spells, existing upgrades and eligible passives. The proposed anti-drought rule reserves one offer for an existing spell upgrade whenever one exists and the previous two drafts offered none. It does not guarantee a named spell or a complete recipe. Once all spell slots are occupied, unlearned spells stop appearing. Once all passive slots are occupied, offer only their legal ranks. A capped option never consumes an offer slot.

One free draft refresh per run is reasonable; preserve the seed across checkpoint/restart and do not reroll after reload. No paid refresh is needed for the minimum clear route. Healing is an alternative choice, not an additional free selection. If only two legal combat improvements remain, show two plus healing/Field Tokens rather than inventing a fourth spell slot. The fallback must not repeatably grant permanent currency by pausing, abandoning or reopening the same draft.

Target sequences in `build_recipes.csv` demonstrate legal combinations. They do not establish how often random offers permit them. Required next simulation: actual implemented offer generator across complete runs, measuring attainable DPS and legal fallback builds, not just uniform selection among all spells. Until then, the recipe DPS is conditional.

## Spell base coefficients and branches

All coefficients below multiply equipped Power. Rank multiplier is 1.00 / 1.25 / 1.50. Branch coefficients modify that rank result. Spell-only equipment bonus, Focus and Cinder Lens multiply afterward, once each. Arcanist's elemental modifier applies only to eligible elemental components. Structures inherit raw Power scaling, not spell-only bonuses.

| Spell | Rank-1 attack and interval | Focus branch | Spread branch | Proposed target limit |
|---|---|---|---|---:|
| Ember Bolt | 0.90 impact +0.30 burn over 2s; every 5s | Impact ×1.20, burn ×0.75; pierce one extra target | Two divergent bolts at ×0.65 each; cannot both damage the same target in one cast | 2 total per focused projectile; 2 distinct spread targets |
| Frost Ring | 0.65 in radius 4.5m; every 8s | Damage ×1.30, radius 3.45m | Damage ×0.80, radius 5.7m | 10 |
| Chain Spark | 0.70 / 0.45 / 0.30 across distinct targets; every 7s | First hit ×1.35; jump reach 4.2m | Every hit ×0.80; adds a 0.15 fourth hit; jump reach 5.4m | 3 or 4, plus evolution |
| Orbiting Wisp | 0.25 contact; shared per-enemy 1.1s interval | Damage ×1.35; orbit 1.8m | Two wisps ×0.65; orbit 2.25m; shared target interval remains | One hit per enemy per shared interval |
| Stone Lance | 1.40 through three targets; every 9s | Damage ×1.30, two targets, narrow line | Damage ×0.80, three targets, doubled line width | 2 or 3, plus evolution |
| Consecrated Ground | 0.20 each second for four ticks; every 12s; radius 2.7m | Damage ×1.25, radius 2.1m | Damage ×0.75, radius 3.6m | 8 per tick |
| Spectral Blades | Two blades at 0.55; every 6s | Two blades ×1.20 | Three blades ×0.70 in a wider fan | Two/three projectiles; each hits once |
| Gravity Knot | 0.40 in radius 3.9m; every 12s | Damage ×1.50, radius 3m, stronger ordinary pull | Damage ×0.75, radius 5.1m, weaker pull | 10 |

The forty-row ability table exposes the coefficient, range, cooldown and ideal single-target throughput of every branch/rank. Its `single_target_power_per_s_at_full_contact` excludes evolution, Focus, class/set modifiers and actual occupancy. For blades it assumes all same-cast projectiles hit one target; spread Ember explicitly does not shotgun. For Chain, only the first hit contributes to one-target DPS. For Ground, all four ticks are required. These distinctions prevent counting a three-target attack as three times its boss damage.

The cap on Wisp hits is shared among all wisps from that spell; adding a second visual wisp improves coverage, not double single-target throughput. Wisp is not a zero-cooldown spell that receives infinite benefit from Channel. Continuous Ground ticks, burn ticks and Wisp contacts do not independently proc basic-weapon critical or on-hit effects.

## Evolutions

| Evolution | Required pair | Exact addition at rank 3 |
|---|---|---|
| Wildfire Bolt | Arcane Focus | 0.20 Power splash per cast; maximum five nearby targets; the original target can receive it once; no recursive explosions |
| Winter Halo | Vital Reserve | Shield 8% maximum HP for 3s after a successful cast; refresh/replace by shield rules, never stack per enemy |
| Thunder Relay | Field Mechanic | One additional distinct jump at 0.15×rank multiplier×branch damage Power; no return to a previous target |
| Soul Lantern | Magnetic Harness | +20% pickup reach within the run's pickup formula; no extra damage tick or automatic collection across walls |
| Rift Spear | Piercing Shot | Two additional pierce targets; first-target damage unchanged |
| Sanctuary | Vital Reserve | Standing in one's Ground heals 0.5% max HP/s during its four-second life; one circle's heal at a time |
| Phantom Flurry | Quick Hands | One extra blade with the selected branch/rank damage; all projectiles still hit at most once each |
| Collapsed Star | Efficient Channel | One 0.20 Power burst after the pull; maximum ten targets; no second pull or recursion |

Damage additions use spell scaling but not an extra rank multiplier unless explicitly stated. Wildfire and Collapsed Star's added 0.20 are fixed relative to Power; Thunder Relay is another rank-scaled chain hit. Healing/shield percentages depend on maximum HP, not Power or critical damage. Pair bonuses apply normally even if an evolution is unavailable.

## Passives, merchant traits and relics

| Passive | Rank effect | Cap / distinction |
|---|---|---|
| Heavy Rounds | +4 basic pistol damage per rank in current proof | Future normalized weapons: +0.10 Power per attack-equivalent second, three ranks; do not add +4 to every repeater pellet |
| Quick Hands | Current pistol interval −0.025s/rank | Future all weapons: 4% attack-period reduction/rank, max 12%; separate from spell cooldown |
| Arcane Focus | +6% spell damage/rank | Three ranks; multiply once, no structure bonus |
| Vital Reserve | +8% profile HP/rank | Three; additive with other run HP percentages |
| Fleet Foot | +5% movement/rank | Three; final sustained speed ≤1.30×base |
| Field Mechanic | +6% structure damage, +10% repair strength/rank | Three; no spell damage unless an explicit spell's own evolution changes it |
| Magnetic Harness | +20% pickup reach/rank | Three; shares run pickup formula |
| Piercing Shot | One additional basic projectile target | One rank; second target 50% damage in future normalized weapon system |
| Efficient Channel | +6 percentage points spell CDR/rank | Three; combined CDR ≤30% |

The Heavy Rounds/Quick Hands generalized rules are future proposals. They must not silently inherit pistol-specific flat gains onto a four-shots-per-second repeater. The generated build recipes do not use those changed passives, so their baseline throughput does not rely on that unimplemented normalization.

The reusable Artificer shrine charges in 2s. Trait ranks cost 30 / 45 / 65 **Field Tokens** (new run-only currency), each trait max rank 3. Vitality grants +10% maximum HP/rank and heals only the newly added HP once. Steady Aim grants +6% basic attack damage/rank. Long Reach grants +25% pickup reach/rank. No trait grants a spell, passive slot or evolution prerequisite. A 90-token early budget can purchase three rank-1 traits or rank 2 plus leftover tokens; all three traits at rank 3 cost 420, deliberately impossible in one ordinary run.

Two Twinflame shrines take 7s to charge; at most three distinct relics total. Their choice UI pauses combat. Relic choices do not cost permanent currency and cannot bypass the three-relic limit after rescue/restart. Return visits require leaving the activation radius and an explicit cooldown; no repeated automatic menu reopening.

| Relic | Effect | Bound |
|---|---|---|
| Emberleaf | After 4s without damage, regenerate 0.15% max HP/s | Nonstacking; maximum 9% HP per uninterrupted minute |
| Obsidian Heart | 10% applicable damage reduction; 5% movement penalty | Multiplicative reduction; penalty after movement cap |
| Storm Feather | Dodge recharge 15% shorter; basic damage −5% | 3.0→2.55s; does not shorten class-power cooldown |
| Wisp Lantern | One nearby target takes 0.30 Power every 3s | 0.10 Power/s at full contact; spell bonus does not apply; no on-hit procs |
| Moonstone | +12% maximum HP; heal only new maximum-HP increment | Once when acquired; restore never repeats acquisition heal |
| Cinder Lens | +8% spell damage; pickup radius ×0.90 | Multiplies spell damage once; no structures |

## Class powers and mastery talents

Class powers autoactivate only when useful. Scavenger never moves without Dodge input. None receives spell CDR; they have their own explicit cooldowns.

| Class power | Activation and effect | Cooldown / cap |
|---|---|---|
| Phase Step | When ready, next manual Dodge uses 0.30s invulnerability instead of 0.18s; longer travel | 12s; no second Dodge charge |
| Repair Swarm | Damaged allied structure within 9m; repair 20% max structure HP over 4s | 24s; one primary target, no overheal |
| Aegis | Threat within 4.5m; shield 20% max HP for 4s | 22s; a failed no-threat check does not consume cooldown |
| Rift Pulse | Enemy within 4.5m; 1.20 Power elemental damage and ordinary-enemy push | 16s; up to ten targets; no boss displacement |

Mastery milestones preserve the main-plan identities: Scavenger reveals containers at 5, removes slows on Phase Step at 10, gets one +25% basic hit after Phase Step at 15 and one lethal-hit prevention at 20. Prevention leaves 1 HP, grants 0.75s protection and does not reset on rescue. Engineer gets −10% structure scrap costs at 5, +15% one-turret attack speed for 4s after Swarm at 10, 40% dismantle refund at 15, and 5% adjacent-structure healing at 20. Refund is based on paid cost and excludes free structures; repeated dismantle cannot create scrap.

Warden gets +10 armor within 3m of an owned structure at 5; Aegis prevents interaction interruption while shield remains at 10; one +50% next basic attack after absorbing damage at 15 (once per Aegis); and one nearby structure receives a 20%-of-its-own-HP shield at 20. Arcanist's elemental bonus becomes 12% at 5, Pulse echoes once for 25% of its own damage at 10, applying two distinct statuses grants +10% spell damage for 4s at 15 (10s internal cooldown), and Pulse cooldown becomes 14s at 20. Echoes cannot trigger another echo or another class-power proc.

These mastery benefits are not all included in the base build CSV; that table explicitly includes only class starting effects/pulse and its listed spell recipe. High mastery is a sensitivity upper bound, not required campaign power.

## Global caps, statuses and simultaneous events

| Quantity | Permanent / combined cap | Exact behavior |
|---|---|---|
| Movement | +15% / +30% sustained | Apply slows and Obsidian after cap; strongest slow only, never below 60% ordinary movement |
| Spell CDR | 15% / 30% | Cooldown `base×(1−CDR)`; max frequency gain 1/0.70=1.428571, not 30% |
| Pickup | 1.50 permanent multiplier | Final run reach capped at 4.0×base in proposed v1; current proof can exceed this |
| Critical chance | 25% / 40% | Basic weapon direct hit only; per-projectile roll, same shotgun cast one shared roll |
| Critical damage | 200% total | Max mean basic multiplier 1+0.40×1=1.40 |
| Elemental resistance | 25% / 40% per type | No armor stacking on elemental components |
| Overall reduction | 65% | Multiplicative remaining fractions, then cap; shields are separate |
| Concurrent shield | 30% max HP | Same source refreshes maximum remaining value, not sum; different sources sum only to cap |
| Continuous healing | 1% max HP/s | Excludes finite Medkit and acquisition HP increments; use actual elapsed time, not frames |
| Damage-triggered procs | One generation only | Proc damage cannot crit, produce another proc, or count as a new status application unless stated |

Proposed run pickup before final cap is `baseRadius × permanentPickup × (1+0.25×LongReach) × (1+0.20×Magnet+0.20 if SoulLantern) × (0.90 if CinderLens)`. With 1.5, Long Reach III and Magnet III plus Soul Lantern, it is 4.725× before the new 4.0 cap. This is explicitly lower than the current reachable 4.725; validate the reduced collection experience before implementation.

Burn uses a two-second per-source damage ledger. Reapplication preserves already owed damage but source damage throughput is capped by actual successful casts; it cannot add a full stack every rendering frame. Ordinary chill is 20% for 3s, boss chill 10% for 1.5s; Frost Bow's smaller chill never adds to it. Root/pull/stagger cannot displace bosses. Elite hard control is at most 0.5s with a 3s immunity window afterward. A slow is not hard control. Toxin pools tick at most once per second per hazard group, live at most 5s, and share the encounter's hazard-space cap.

The same attack ID can damage a player at most once per event. After a damaging hit, proposed global hurt protection is 0.45s; it applies to contact, projectiles and ground ticks and is not extended by shield-only absorption. Dodge invulnerability blocks the hit before shield/HP changes. Dodge has one charge, 3s recharge starting at activation, normal duration 0.18s; at most 6% theoretical time coverage, 7.06% with Feather, not continuous immunity. Phase Step's longer Dodge occurs only every 12s.

Simultaneous boss/player lethal hits resolve in the same fixed simulation tick: if the boss killing blow is committed before defeat finalization, clear wins. No HP refill at a boss phase transition, no invulnerable transition attack, no extra heal from saving/reloading an already granted maximum-HP upgrade.

## Quantitative extremes to retain in tests

An all-rank-3 Attuned loadout proposes 32% raw permanent CDR but grants only 15%; Riftweaver must not lift that cap. Adding Channel III reaches 30%, not 37%. Eight Lightweight rank-3 rolls plus Scavenger is 21% raw, capped to 15% permanent. A cap-saturated affix has zero marginal value and the comparison UI must say so.

Maximum run HP multiplier is 1+0.24+0.30+0.12=1.66 before optional class/set multipliers. It costs three Vital Reserve picks, 140 merchant tokens for Vitality III and one relic slot. Early runs have only 90 tokens; the formal full-HP extreme is not an early legal ordinary-run loadout. A low-tier formal upper-bound calculation is not an attainable build unless its currency and selection budgets also pass.

At 30% CDR, Focus III, Cinder Lens, Riftweaver and Arcanist's base bonus, the spell coefficient multiplier is `(1.18×1.08×1.03×1.08)/0.70≈2.025`, before rank/branch and contact. These bonuses do not also multiply weapon damage or turrets. Full mastery adds additional bounded windows; it is measured separately. One formula registry entry must own each multiplier so it cannot accidentally be applied in both profile stats and run spell damage.
