# Original game briefs

## Shared arena prototype
- 1 enclosed rectangular arena; top-down movement, walls and obstacles; camera stays readable.
- Player has health, invulnerability frames after hit, joystick and optional accessibility controls.
- Six configurable archetypes: walker, sprinter, tank, ranged, exploder, boss; begin with walker/sprinter.
- Configurable spawn budget, enemy cap, hitboxes, projectiles, pooling, damage numbers, sound/haptics.
- 5-minute prototype run with three upgrade decisions, local best score, restart, pause and resume.
- Prototype acceptance: complete run without crash, input remains responsive under measured enemy load, collision and damage tested, no softlocks.

## Nightfall Arena — first release candidate
- Core: survive waves in a boxed-in zombie arena; movement and auto-target shooting.
- Distinctive mechanic: safe zones shift after each wave, requiring positional planning; collectible scrap powers one temporary defense per run.
- Meta: unlock weapon choices and cosmetic arena variants through play; no paywall.
- MVP: 2 maps, 4 enemy archetypes, 3 weapons, 8 upgrades, 1 boss, tutorial, results screen.

## Arcane Run
- Core: magic survival with movement, spell casts/auto-casts and elemental combinations.
- Distinctive mechanic: combine elements (e.g. chill + lightning = chain stun with bounded balance), manage mana or cooldowns.
- MVP: 2 environments, 4 enemy archetypes with altered behaviors, 5 spells, 8 upgrades, 1 boss, objective-based rounds.
- Avoid merely swapping zombie sprites for fantasy sprites.

## Bullet Rush Arena
- Core: short arena firefights with guns and positional tactics.
- Distinctive mechanic: cover can be destroyed; weapons have reload, range and recoil trade-offs; score through extraction objectives rather than only surviving a timer.
- MVP: 2 maps, 4 enemy archetypes, 4 weapons, 2 cover types, 1 boss, upgrade screen.

## Last Stand Workshop — hybrid defense
- Core: move and fight inside an arena; earn scrap to place walls, turrets, traps, repair stations between waves.
- Distinctive mechanic: finite build tiles and line-of-sight; defensive layout is the central strategy, player still fights.
- MVP: 1 map, 3 tower/structure types, 4 enemies, 6 waves, upgrade economy, loss/win conditions.
- Test whether building phase is fun before adding complex crafting.

## Kingdom Path Defense — optional later project
- Core: fixed-path strategy, place/upgrade towers, resource economy and target priorities.
- Distinctive mechanic: path modifiers and elemental tower combinations.
- MVP: 2 paths/maps, 4 towers, 6 enemies, 10 waves, 1 boss.

## Product design constraints
- Make mechanics, level objectives, art direction and progression meaningfully different per game.
- No manipulative difficulty spikes to force ad viewing. No paid currency or IAP in first version.
- Early design hypothesis: polished 2D/2.5D visuals and portrait orientation; validate with user tests, not assumed market superiority.
- Build a data-driven enemy/weapon/map catalog, but keep gameplay tuning per game.
