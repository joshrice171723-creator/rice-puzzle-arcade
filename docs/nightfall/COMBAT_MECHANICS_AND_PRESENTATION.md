# Nightfall combat delivery — October 19, 2026

This pass covers the implemented first-zone combat: four class kits, eight spells and their existing branches/evolutions, five equipped weapon families, three ordinary enemy types and five mission bosses. Warden and Arcanist retain their future-content unlock gates. This is not implementation of the planned twenty-zone campaign.

## What the earlier recording could not establish

The old visual-effects demonstration used stationary targets with 50,000 HP and disabled attacks. That demonstrates effects but cannot demonstrate normal enemy death, AI, difficulty or combat balance. The new combat review uses live AI, ordinary health and damage. Its five loadout scenes deliberately grant spells for coverage and are labelled as practice loadouts. The separate campaign review starts the ordinary first mission with starter equipment, no granted spells and no damage immunity.

Both reviews use a separate profile and never bank campaign rewards. Performance evidence distinguishes desktop, Android emulator, recording overhead and headless simulation. No physical-phone acceptance is claimed.

## Equipped weapons

All weapon attacks fire automatically. Movement and Dodge remain player combat inputs. Weapon identity follows the equipment instance through equip, merge, inventory, checkpoint and restore. Old saves without a weapon family default to the Service Pistol.

Values below are at 40 Power, before training, affixes, critical hits, traits or temporary upgrades. Base damage is 60% of Power.

| Weapon | Attack | Interval | Reach | Damage | Maximum unmodified DPS to one target |
|---|---|---:|---:|---:|---:|
| Service Pistol | One brass projectile | 0.60 s | 225 | 24 | 40.0 |
| Scrap Scattergun | Three pellets, angled ±0.15 radians | 1.00 s | 170 | 12 each | 36.0 if all connect |
| Salvager Crossbow | One bolt, pierces a second enemy | 1.00 s | 290 | 38.4 | 38.4 |
| Beacon Wand | One elemental mote | 0.65 s | 210 | 22.8 | 35.1 |
| Outrider Sabre | Frontal sweep; up to three targets | 0.85 s | 80 | 30 each | 35.3 |

Multi-target attacks trade reach, timing or target access for their extra total damage. This table is an equal-tier starting budget, not a claim that five weapons have identical practical win rates. The sabre commits its direction and deals damage 0.10 seconds into a 0.24-second swing. A target behind the player is not struck. Piercing Shot adds one projectile penetration or one sabre target. Opening Shot and critical training apply to all basic families. Arcanist's 8% elemental bonus applies to the wand as well as spells.

The four additional families are available from the existing supply/weapons chest rolls, preserving slot and rarity probabilities. Their illustrated inventory icons are recorded in `art-sources/COMBAT_WEAPONS.md`. Field-cache and targeted-contract reward generation still use the starter item names. Character illustrations have baked-in held props; equipping a family changes live attack geometry, recoil/swing, projectile, sound and damage, not a fully interchangeable character weapon model.

## Spell and class presentation

Simulation owns damage timing, radius, targets, cooldown and lifetime. Visuals consume that state without advancing gameplay RNG or adding damage. Spell casts have a short anticipation gesture, launch/eruption, impact and decay. Each class uses its own transparent character art on continuously deformed geometry.

| Spell | Rank-one behavior | Presentation |
|---|---|---|
| Ember Bolt | 36 impact plus 12 burn over two seconds; 5 s cooldown | Forming fire in hand, deforming fire core, attached flame ribbons, impact plume and fading smoke |
| Frost Ring | 26 area damage, three-second ordinary chill; 8 s cooldown | Radial frost wave, growing ice facets, falling fragments and blue chill tint |
| Chain Spark | 28 / 18 / 12 across distinct targets; 7 s cooldown | Hand charge, moving arcs between actual struck targets and endpoint flashes |
| Orbiting Wisp | 10 contact damage; shared 1.1 s per-enemy hit limit | Continuous orbital motion, glowing core and curved trail, depth sorted around the hero |
| Stone Lance | 56 damage through up to three targets; 9 s cooldown | A narrow row of rising, rotating stone facets along the real damage line |
| Consecrated Ground | 8 damage/s for four seconds; 12 s cooldown | Persistent rune circle at its cast position, animated marks and fading edge |
| Spectral Blades | Two 22-damage projectiles; 6 s cooldown | Forming blades, continuously rotating faceted blades, trailing light and impact shards |
| Gravity Knot | 16 area damage; 12 s cooldown | Rotating vortex and debris, continuous 0.6 s pull, evolved collapse at the end |

Normal gravity pull budget is 80 units, while bosses move at most 8 units from one pull. Focus/spread variants retain their configured damage/radius/count tradeoffs. Ground/Gravity share a three-zone cap. Healing fields do not stack healing. Evolution changes use the existing prerequisites rather than bypassing the talent unlock system.

Class abilities remain automatic: Warden raises Aegis when threats approach, Arcanist pulses nearby enemies, and Engineer repairs a damaged nearby structure with Repair Swarm. Scavenger's Phase Step augments the user's next eligible Dodge. All four now have continuous movement, body/arm deformation, casting, hit and dodge presentation. No alternating generated pose frames are used for the live hero or enemies.

## Enemy attacks and counterplay

Ordinary enemies no longer damage the hero silently through body contact. Each attack has an acquisition condition, committed tell, actual strike and recovery. Moving away or dodging during the tell avoids the hit; enemies do not retarget a committed attack. Dead enemies cannot launch another attack. Already launched projectiles remain valid until collision/expiry.

| Enemy | HP / speed | Attack commitment | Actual strike | Recovery |
|---|---|---|---|---|
| Drifter | 48 / 32 | Acquires within 38; 0.42 s windup | Frontal swipe within 42; 10 base damage | 0.55 s |
| Rift Runner | 32 / 56 | Acquires within 58; 0.34 s windup | 220-unit/s, 0.18 s pounce; one swept hit for 8 | 0.55 s |
| Ash Spitter | 40 / 24 | Acquires within 275; 0.65 s windup | 170-unit/s projectile; 12 damage, two-second slow on a damaging hit | 0.45 s |

Spitters retreat inside 130 units and hold their ranged position up to 210. Attack cooldowns are 1.15 s for Drifters/Runners and 3.4 s for Spitters. Dodge immunity blocks both projectile damage and its slow. Cover intercepts hostile projectiles only when the cover is the first intersection; a barricade behind the hero cannot absorb a prior hit. Enemies visibly wind up and strike obstructing defenses rather than eroding them with silent contact damage.

Enemies and heroes collide with ground footprints of caches and shrine plinths. They slide around them; pursuing AI chooses a stable side. Shrine charge circles remain accessible from in front of the plinth. Crowd separation and gravity cannot push characters through these footprints. Hidden landmarks do not obstruct the boss-training arena.

## Five boss encounters

Every mission retains four minutes of survival followed by a mandatory boss kill. There is no second mission deadline. The review harness's timeout is a test limit, not a gameplay timer.

| Mission / boss | HP | Cycle | Windup |
|---|---:|---|---:|
| Garage Lights / Garage Mauler | 700 | Slam, rush | 1.15 s |
| Beyond the Fence / Fence Runner | 820 | Rush, rush, rubble toss | 0.80 s |
| Hollow Porches / Porchcaller | 900 | Summon, rubble toss, slam | 0.95 s |
| Scrapwall / Scrapback | 1,000 | Slam, rubble toss, rush | 0.95 s |
| The Last Street / The Breaker | 1,200 | Rush, slam, rubble toss | 0.95 s |

Slam acquires within 110, strikes an 80-unit radius for 30 before mitigation, then recovers for 0.85 s. A distant boss substitutes a ranged/rush/summon option for an unusable slam instead of spending the fight endlessly following the hero. Rush direction locks before launch, lasts 0.65 s and hits a given hero at most once per charge; speed is 280 for Mauler, 410 for Fence Runner and 360 for other bosses. Recovery is 1.1 s, or 1.35 s for Fence Runner. Rubble toss launches three 16-damage rocks at 190 speed. Porchcaller is limited to six live and twenty-four total reinforcements, preventing endless summon farming. Scrapback retains its 50% frontal physical mitigation and exposed rear; elemental damage bypasses that facing reduction.

Boss poses anticipate their actual attack: raised arms for slam, lean for rush, cast gesture for toss/summon, strike and recovery. The attack outline is redrawn over offensive spell effects to keep the threat readable. Health bars use each actual rendered body height. Death collapses and fades the same mesh from its current pose.

## Reliability and performance changes

- Friendly and hostile projectiles use swept segment/circle collision. Fast projectiles cannot skip targets between ticks; first intersection wins, and piercing can hit several targets in the same tick without hitting one twice.
- Automatic projectile weapons, Ember and Spectral Blades lead the target using its measured movement and a bounded intercept calculation. This changes the launch direction, not the projectile path; projectiles do not home after launch and can miss a changing target.
- Lifetime limits travel before collision checks. Expired shots cannot damage beyond their remaining range.
- XP and currency drop caps merge values instead of deleting earned rewards. Merged XP values survive checkpoints; old checkpoints without per-pickup values remain compatible.
- A preloaded full spell roster at level two and an exhausted upgrade pool no longer trap the player in an unusable level-up screen.
- Damage-over-time hit feedback is rate limited visually without suppressing real damage or XP.
- Repeated full circles and rings use cached mesh geometry; currency drops use the existing illustrated credits texture. Partial charge indicators still show their actual progress. The 120-enemy / 40-XP / 48-currency / 12-hit graphical fixture uses 77 draw calls against a budget of 100.
- Shared enemy textures batch into depth-ordered meshes. Precomputed rig weights, UVs and topology remove repeated animation setup while keeping continuous deformation.
- The eighteen short combat audio cues are synthesized from deterministic math/noise in `scripts/nightfall-combat-audio.py`. Six bounded combat voices, event serials, priorities and rate limits prevent replay or unlimited overlapping sounds. Mute, focus, pause and ad states are respected.
- Android export uses a command-scoped nonpersistent Gradle setting and restores the caller's environment afterward.

## Reproduction and evidence locations

`pwsh -NoProfile -File scripts/nightfall-godot.ps1 -Action Test` runs the regression suite, including both isolated preview modes. `tests/combat_mechanics_test.gd` exercises weapon collisions, AI tells/strikes, all five boss patterns, classes/spell branches, landmark collision, reward conservation and save compatibility. `tests/animated_vfx_test.gd` checks continuous deformation and synchronized damage/effect timing. Graphical render checks and native runs are additional evidence; passing headless checks alone does not establish visual quality.

Run the desktop project with `-- --combat-preview --combat-quit` for the roster, or `-- --combat-campaign --combat-quit` for normal starter Mission One. Optional `--combat-captures` records viewport snapshots. Debug Android uses `files/combat-preview.flag` in its own sandbox: empty for roster, `campaign` for starter mission. Delete the flag before returning to ordinary play. Both routes use `vfx-preview-profile.json`, leave campaign checkpoints alone and write explicit review metrics.

Local evidence is in `artifacts/nightfall-godot/combat-pass/`. Android metrics report wall-clock frame intervals, draw CPU time and physics peak time. High-resolution screen recording is a separate workload and is not used for the no-recording frame-rate comparison. See `KNOWN_ISSUES.md` for remaining acceptance gaps. Physical-device testing and human playtesting of difficulty remain necessary.

## Final build verification

- Android APK SHA-256: `60F21272828AAA0A62F9BD5D25BC9DE2AAA6E9574D9BCA546BCC71E960FDBA67`. Installed on the API 30 emulator.
- Full regression: 34 suites, 8003 checks, zero failures and no script/engine errors. Known fixture teardown ObjectDB warnings remain tracked as NF-006.
- Actual graphics checks: 33 shader-render checks passed; moving material output and reduced-effects behavior were checked. The final crowded render fixture passed at 77 draw calls. Six final static mission captures cover shrine, combat, level-up and boss danger markers.

Final native roster, no screen recording: all five boss stages ended in victory. The waves use deliberately granted practice loadouts, so these results verify combat behavior and presentation, not campaign difficulty. Each stage uses ordinary enemy HP/damage and can fail. Frame rates are actual wall-clock measurements on the API 30 / Iris Xe emulator.

| Segment | Class / weapon | Outcome | FPS | Enemy hits received |
|---|---|---|---:|---:|
| Waves | scavenger / pistol | waves | 38.2 | 0 |
| Waves | engineer / scattergun | waves | 27.2 | 4 |
| Waves | warden / sabre | waves | 30.3 | 5 |
| Waves | arcanist / wand | waves | 37.0 | 1 |
| Waves | scavenger / crossbow | waves | 31.9 | 2 |
| Boss 1 | scavenger / pistol | victory | 49.3 | 0 |
| Boss 2 | engineer / scattergun | victory | 44.3 | 2 |
| Boss 3 | warden / sabre | victory | 41.0 | 4 |
| Boss 4 | arcanist / wand | victory | 43.4 | 1 |
| Boss 5 | scavenger / crossbow | victory | 49.6 | 0 |

The first live wave segment improved from 28.1 FPS immediately before the cached-ring change to 38.2 FPS in the final build on the same emulator; these are single-run observations, not a controlled hardware benchmark. Final crowded spell stages range from 27.2 to 38.2 FPS and bosses from 41.0 to 49.6 FPS. Sustained 60 FPS remains open (NF-007). The native profile hash was unchanged after the roster review.

Final ordinary starter Mission One on the same APK: **victory at 272.12 simulation seconds**, 273.15 wall seconds, 245 kills, 39.57 HP remaining, 22 enemy hits and 6 dodges. Average 38.98 FPS; p95 frame time 41.44 ms. This is an automated steering run, not a human difficulty study. It begins with normal starter gear and earns its upgrades; no preloaded spells or immunity. Evidence: `android-campaign-v7-metrics.json`, `android-v7-campaign-logcat.txt`, and `android-v7-campaign-result.png`. The boss heading remains visible on the victory screen, closing NF-005's emulator acceptance.

`nightfall-combat-review.mp4` is the three-minute native recording (540x960, no captured audio) covering the five weapon loadouts and the start of boss review. It is a labelled practice-loadout showcase. The unrecorded complete-roster metrics above cover all five boss victories; do not present the shorter recording as containing every boss finish. The original Android profile SHA-256 remained `d059dd0eae6b8c8d5d4f8d346d12e5a2199e3ecbfeacb49a55d96fbc02a41c52` after both final reviews.
