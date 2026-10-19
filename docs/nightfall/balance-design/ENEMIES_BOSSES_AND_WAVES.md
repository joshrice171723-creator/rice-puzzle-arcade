# Monsters, one hundred encounters and six hundred wave segments

The content identity remains the approved twenty zones and eighty captains plus twenty signatures. `zones.csv` preserves every name/material. `bosses.csv` binds each name to its mission and numerical budgets. `signature_attacks.csv` supplies sixty attack definitions. No alternate objective is introduced: survive the wave countdown, then kill the named boss.

## Seventeen monster archetypes

The archetype table contains base HP, raw damage, speed in m/s, range in meters, tell duration, full attack cycle, Combat XP, resistance, spawn cost and first zone. `zone_monsters.csv` expands those stats for each unlocked zone. For an actual mission use its multiplier on the unrounded base, then round once; do not multiply an already rounded zone-floor value and silently accumulate rounding error.

| Archetype | Base HP / hit / speed | Behavior and meaningful response |
|---|---|---|
| Drifter | 48 /10 /1.10 | Walks toward player; 0.35s windup before close contact strike, 1.4s cycle. Basic spacing target, never unavoidable proximity damage every frame. |
| Rift Runner | 32 /8 /2.80 | Approaches quickly, then locks a short lunge direction for0.55s. Cannot turn during its0.3s lunge. Miss creates0.7s recovery. |
| Ash Spitter | 40 /12 /0.80 | Stops at4–6m, shows0.9s tell, fires one4m/s projectile. Minimum3.4s cycle; cannot shoot from unshown offscreen positions. |
| Plateback | 95 /16 /0.85 | Front physical reduction30%, slow turn60degrees/s. Rear and elemental attacks avoid the front plate;0.85s heavy tell. |
| Hollow Wisp | 30 /10 /1.60 | Drifts to a visible marked point then fires. Ghost appearance never removes its damage tell.0.85s tell,3.2s cycle;10% arcane resistance only. |
| Canal Drowner | 58 /13 /1.00 | Short3.5m splash cone;1s tell. A hit applies10% slow for1.5s. Water patches expire3s and cannot stack slow. |
| Cinderling | 24 /20 /1.60 | Arms a1.3m explosion over1.2s; killing it cancels the explosion and yields normal XP. Cannot explode immediately on spawn or death. |
| Briarhound | 52 /14 /2.30 | Marks3.5m lunge,0.85s tell; miss recovery1.1s. Two hounds cannot reserve the same player-crossing lane within0.6s. |
| Harpoon Husk | 65 /16 /1.10 |1.1s line tell at6m, one hook. Pull at most1m; no stun or wall traversal;4.6s cycle. |
| Rime Stalker | 62 /14 /1.50 | Leaves visible tracks for1s before frost dash. No camouflage at attack commitment; applies15% slow1.5s. |
| Signal Siphoner | 50 /12 /1.00 | Supports one nearby ordinary enemy with10% outgoing-damage buff; no healing/armor aura. The tether is visible and breaks on death or distance>5m. One buff per target. |
| Shard Burrower | 80 /18 /1.30 | Marks a4.5m-reach emergence for1.2s. Unavailable underground at most1s; cannot burrow again for4.8s. |
| Blight Attendant | 60 /12 /0.90 | Lobs one1m toxin patch,5s lifetime,1s tell. Two active patches maximum; no permanent map contamination or healing loop. |
| Prism Pod | 55 /15 /0.55 | Fires one projectile that reflects once from a visibly marked surface.1.2s tell; second reflected path also visible. |
| Gutterwing Skirmisher | 48 /16 /2.10 | Marks a landing,1s tell, then0.8s exposed recovery. Never attacks from an inaccessible roof; ignores decorative ledge height only. |
| Hollow Trooper | 76 /17 /1.15 | One three-round fan every4.4s after1.1s tell; shared hit group means at most one listed hit per burst.10% physical resistance. |
| Veil Echo | 56 /18 /1.70 | Relocates to a marked destination then fires after1.1s. Destination at least2m from player; no invisible contact strike. |

Each resistance is only10–15% except directional Plateback armor. No ordinary archetype is immune to a damage type. Enemy speed/range/tell do not inflate by zone. Health/damage growth is `H(z)`, `D(z)`, then mission modifier. Elite conversions multiply ordinary HP2.2 and hit1.2, retain speed/tell, add eight XP and three spawn-budget points. Elite resistance gains at most five percentage points, never immunity. Elite attack cycles cannot be shorter than the ordinary version.

A zone may reuse earlier enemies. Its two defining specialist families are explicit in `zones.csv`; the wave counts in each phase decide what actually appears. An unlocked archetype's existence in `zone_monsters.csv` is not permission for a wave director to improvise it into every zone.

## Concrete zone progression

| Zone | Defining ecology | Signature / material | New pressure and safety constraint |
|---:|---|---|---|
|1 Blackout Outskirts|Drifters, Runners, Spitters|The Breaker / Breaker Plate|Teach tells and pickup; no elites; long final lull|
|2 Freight Yard|Platebacks, Runners|Chainjaw / Chainlink Core|Flanking in lanes; reserve3m bypass paths|
|3 Silent Suburbs|Wisps, Spitters|The Whisperer / Whisper Shard|Decoy recognition; real tells never hidden|
|4 Flooded Market|Drowners, Platebacks|The Drowned Bell / Tidal Brass|Short slow patches; strongest slow only|
|5 Ironworks|Cinderlings, Platebacks|The Forge Warden / Furnace Heart|Interruptible explosions; furnace patterns leave routes|
|6 Orchard County|Briarhounds, Wisps|The Rootmother / Heartwood Knot|One extra minute; separate lunge reservations|
|7 Coldwater Docks|Harpoon Husks, Drowners|Captain Undertow / Anchor Fragment|Hooks and lanes; no pull through terrain|
|8 Whiteout Village|Rime Stalkers, Briarhounds|The Pale Howler / Rime Fang|Slow control; ice barriers have openings/expiry|
|9 Dead Signal|Siphoners, Wisps|The Antenna Saint / Storm Coil|Visible support tethers; no stacked buff auras|
|10 Buried Transit|Harpoon Husks, Platebacks|The Railbreaker / Railbreaker Bearing|Alternating tracks; adjacent lane stays safe|
|11 Ashfall Quarry|Burrowers, Platebacks|The Stone Maw / Quarry Geode|Ground tell reading; burrow unavailability bounded|
|12 Quarantine Ward|Blight Attendants, Cinderlings|The Plague Matron / Purified Gland|Expiring hazard management; no permanent floor denial|
|13 Glasshouse Labs|Prism Pods, Briarhounds|The Glass Gardener / Prism Seed|Marked single reflections and temporary walls|
|14 Rustwater Refinery|Cinderlings, Drowners|The Oilbound / Refined Emberglass|Fuel warning before ignition; no instantaneous unseen fire|
|15 Rooftop District|Skirmishers, Harpoon Husks|The Sky Reaver / Reaver Pinion|Mobile target windows; decorative ledges cannot kill|
|16 Broken Reservoir|Drowners, Burrowers|The Dam Keeper / Pressure Crystal|Directional jets; no forced pushes into blocked areas|
|17 Hollow Bunker|Troopers, Siphoners|The Hollow Marshal / Command Seal|Stance reading; vulnerable transition every stance|
|18 Storm Coast|Siphoners, Skirmishers|The Tempest Colossus / Tempest Heart|Large patterns; fewer strikes during moving lanes|
|19 Nightfall Core|Echoes, Prism Pods|The Hollow Regent / Regent Shard|Combine known mechanics, no new immunity puzzle|
|20 Last Beacon|Echoes, Troopers|The Night Sovereign / Sovereign Ember|Three finite phases, no refill or late enrage|

## How to read and schedule all 600 wave rows

Each mission is divided into six equal segments:40s in Zone1,50s in Zones2–5,60s later. Row start/end values are contiguous and cover the entire countdown. Total planned bodies are the sum of the seventeen enemy count columns; `spawn_count` repeats that sum as an integrity check. An elite conversion replaces one of the listed specialist bodies; it is **not an extra spawn**.

Spawn budget is `sum(count[archetype]×spawnCost[archetype]) + 3×eliteConversions`. XP budget is `[sum(count×normalXP)+8×eliteConversions]×zoneXPScale`. Both costs are authored screening units, not damage multipliers. The first two segments deliberately omit or greatly reduce specialist mixes. Mission2 shifts bodies toward Runners, Mission3 toward ranged/support, Mission4 toward tougher specialist bodies. Segment5 peaks; segment6 reduces density to allow cleanup before the boss.

Emit a packet every5s starting at the segment start. For a segment with `K=segmentDuration/5` packets and `N` bodies of one archetype, packet `j` receives `floor((j+1)N/K)−floor(jN/K)`. This conserves exactly N scheduled bodies and distributes them evenly; phase/mission count tables therefore fully determine the packet schedule. If several archetypes emit on the same packet, rotate their first eligible edge by a seeded permutation; never use a fresh random count to override the authored totals. Mark an elite on the last eligible specialist body of phase3 or5.

Spawn minimum5.5m from the player, maximum8m where arena geometry permits, after a1.2s entry tell. At least two independently reachable movement corridors must remain. A spawn whose legal position cannot be found is canceled, not teleported under the player. Do not spawn a projectile already in flight at the arena boundary.

Alive caps are28 in Zones1–5,32 in6–10,36 in11–15,40 in16–20. Ranged caps are4 early,6 later; elites max1 early,2 later. Caps count bodies, including summons during waves. Boss-phase total caps include remaining wave enemies, boss and adds. A failed cap-limited packet is discarded: no backlog, no end-of-timer debt burst. Actual XP therefore depends on cap pressure, included in the capture forecast.

Director attack reservations additionally permit at most two ordinary ranged attacks committing inside the same0.5s window early, three late; at most two simultaneous lunge lanes; and at most24 hostile projectiles alive. Heavy boss geometry gets priority over ordinary attacks in its response corridor. These constraints require spatial testing; a body cap alone does not ensure dodgeable patterns.

No normal packet may start at or after the countdown boundary. The final ten seconds display the boss warning. Existing enemies remain. Boss arrival itself causes no damage, clear, heal or loot banking; the boss becomes active after a2s entrance warning. A lower last-segment count should allow an attentive player to enter the boss with fewer remaining threats, but clearing every normal enemy is not required.

## Four captain foundations, eighty named variations

`bosses.csv` preserves each approved captain's authored variation text: Railhook pulls, Windowshade repositions behind cover, Furnace Tender calls explosive minions, and so forth. The following shared numerical contracts turn those descriptions into bounded attacks. Where a variation changes geometry, use the corresponding zone signature's geometry vocabulary; damage still uses the captain's listed standard/heavy budget.

| Foundation | Attack cycle and geometry | Phase below50% |
|---|---|---|
| Bruiser / Mission1 |6s cycle:1.1s told120degree swing,3m radius, heavy damage; alternate with1.2s told1.5m-wide8m charge;2.2s recovery|A swing may follow a missed charge only after a fresh0.9s tell; preserve2.2s final recovery|
| Hunter / Mission2 |5.5s cycle:0.95s marked1m dash/hook lane to8m, standard hit; alternate with three-shot fan18degree gaps;1.8s recovery|Two dashes/hooks separated by a fresh1s tell; second targets prior position, never tracks mid-dash|
| Caller / Mission3 |8s cycle:1.2s summon tell, four weak ordinary adds at safe entrances; alternate with1.1s told2m ground circle, standard hit;2.4s recovery|Two sequential circles, never simultaneous full-arena coverage; same total add cap|
| Guardian / Mission4 |7s cycle: front physical reduction30%, turn45degrees/s;1.3s told150degree3m slam, heavy hit;2.5s exposed recovery|Alternates shield direction before tell; never invulnerable; exposed recovery maintained|

All four use the exact HP/hit/contact/cycle/phase values in `bosses.csv`. Contact damage is a separate low hit with the global hurt interval; standing inside a boss cannot multiply it per frame. Variations may add short slows, hooks, decoys, explosive summons or delayed patches already taught in the zone, never an undocumented damage multiplier. A captain that needs a genuinely different timing must get its own row revision and boundary test rather than an untracked code exception.

Summoners have four adds alive and twelve total in Zones1–5, six alive and eighteen total afterward. Reinforcement XP totals are capped12 early,18 later, shared across phase transitions. Normal enemy remnants do not refill the summon budget. Once total adds are exhausted, the summon animation becomes an ordinary attack/recovery opportunity; it does not reset, heal the boss or create endless XP.

## Twenty signature encounters

The sixty-row signature table specifies three attacks per boss, actual raw hit, damage type, tell, geometry, response, projectile cap and phase behavior. Attack order is deterministic enough to learn: A→B→A→C, with at least3s between attack starts and recovery windows in the table. An attack may extend its start gap to preserve its stated tell/active/recovery duration; do not truncate a recovery to force a fixed cadence.

Below50% HP, all signatures except the finale combine two familiar attacks with separate tells and at least one preserved route. Their health does not refill. The Night Sovereign uses100–70%,70–35%,below35% thresholds, with explicit absolute HP in `bosses.csv`. Final phase does not ramp damage indefinitely; a cautious player can keep fighting as long as they can survive.

Maximum concurrent persistent-hazard coverage is15% of walkable arena area, including ordinary-enemy pools, boss trails and blocking walls' effective denial zones. Every pattern must preserve a corridor at least3m wide after accounting for the player's collision radius. Canceled illegal geometry does not bank a stronger future attack. Boss summons/copies/pylons share relevant caps; their destruction can ease movement but is never a second required campaign objective.

Late bosses are not balanced around owning their own reward. The Forge Warden cannot require Cinderweave; the Hollow Regent has no elemental immunity; the Night Sovereign must fall without its Mythic core. Players may win through sustained damage, positioning and repeated safe windows. No paid resurrection, exact element, structure, class or random evolution is mandatory.

## Geometry acceptance before importing content

At minimum phone viewport, show every heavy tell and its safe response without relying on color alone. Validate from arena center, edges, corners, shrine approaches and behind placed barricades. A player moving4m/s needs0.75s to cross3m before collision margin; a1.2s tell is not automatically safe if a second hazard blocks that corridor. Test slow effects at the60% movement floor and with Dodge unavailable.

Record actual attack contact rate, forced overlaps, ordinary body accumulation, killed/scheduled XP fraction, time-to-kill, boss contact fraction and frame cost. The current CSV checks prove count/identity arithmetic, not geometry. If the slowest legal movement state cannot escape, change the geometry/tell; do not assume the player should have bought movement gear.
