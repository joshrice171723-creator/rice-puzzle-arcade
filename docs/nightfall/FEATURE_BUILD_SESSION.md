# Nightfall feature session — October 18–19, 2026

Joshua requested two hours of feature development starting **2026-10-19 00:27:19 UTC**, ending approximately **02:27:19 UTC**. No manual gameplay or emulator play during this session. Existing visual defects remain in `KNOWN_ISSUES.md`; automated checks cover new features.

## Current increment

- Four loot caches; eight backpack slots including two protected slots; collected credits and protected loot survive defeat.
- One two-second Artificer shrine with repeat Field Scrap purchases; two seven-second Twinflame shrines share three relic choices per attempt. Offers and paid rerolls survive leaving and saving.
- Six temporary relics, three shop traits, bounded effects wired into combat.
- Local Haven profile, atomic file replacement with backup, separate active-run checkpoint, typed state/RNG restoration, once-only result transactions.
- Equipment, common/uncommon/rare promotion, level 1–5 upgrades for the initial zone, salvage, three Haven facilities.
- Five Outskirts mission definitions, four-minute waves and mandatory boss defeat. Campaign clears, mastery medals, first-clear gems, milestone rewards, Engineer unlock.
- Paged phone UI for Venture, Gear, Haven and Class. Only Scavenger/Engineer unlock in the first zone; later classes remain visibly locked.

## Checks so far

- Rules: 17; combat: 23; exploration: 33; profile: 34; original layout: 19 — all passing.
- New Haven/shrine/pack layout fixtures: 334 geometry checks across 320×568, 390×844, and 430×760 — passing.
- No claim of physical-device acceptance, native video verification, completed production commerce, or balanced human difficulty in this session.

## Next

Field defenses and Engineer ability; distinguish the five boss encounters; finish active-run and UI integration checks; package the resulting feature build. Production ad work remains separate from these gameplay features.

## Second increment

- Four destructible defenses: barricade, turret, trap, ward. Shared eight-point capacity, maximum two turrets, blocked shrine approaches, no charge for rejected placement.
- Engineer Repair Swarm restores 20% structure health over four seconds. Blueprint unlocks after missions 1 and 3 give the first zone usable construction choices.
- Outskirts boss variants now include a faster charging Fence Runner, Porchcaller summons, and Scrapback frontal armor with rear/elemental counterplay.
- New original transparent prop atlas replaces primitive shrine/cache/defense drawings.
- Native Google sample-video bridge now uses request IDs and structured earned/finished/error signals. Attempt-local rescue restores 50% HP once, preserves the run, and prevents duplicate or unrelated callbacks from granting rewards. Defeat rewards wait until the player finishes or declines rescue. No production IDs were added.
- Automatic controller journey verifies saved shrine state, no-fill retry, simulated earned rescue, boss clear, correct mastery eligibility, persistent upgrade purchase, next mission stats, and protected loot on abandonment.
- Two original instrumental loops, nine effect cues, persistent volume/vibration/reduced-effects settings, and audio suspension during ads/background.
- Android exports succeeded before and after the request-ID native bridge change. These exports are intermediate builds; no manual native play or actual video playback was performed in this feature session.

Google's [rewarded-ad documentation](https://developers.google.com/admob/android/rewarded) states that Google-served ads deliver the earned callback before dismissal. This bridge uses Google's sample ad unit only. Mediation adapter ordering and production server verification remain separate acceptance work.

## Automatic combat and spell builds

- Latest user direction applied: Dodge is the sole manually triggered combat ability. Removed Pulse/class buttons and E/Q actions. Phase Step enhances a requested Dodge; other class powers trigger only with suitable nearby targets.
- Eight attacks: Ember Bolt, Frost Ring, Chain Spark, Orbiting Wisp, Stone Lance, Consecrated Ground, Spectral Blades, Gravity Knot. Three attack slots, three passive slots, bounded ranks, five paired evolutions, separate offer RNG, checkpointed area and orbit state.
- Upper-left artwork strip with rank diamonds, evolved label and cooldown shading; paused Attacks/Passives/Relics inspection pages. Original transparent eight-icon atlas, also used in world effects.
- 54 new automatic-combat checks, 51 populated phone HUD checks; full current suite 740 checks passing. Static rendered fixture: `artifacts/nightfall-godot/ability-hud.png`. No manual gameplay.

## Loot and preparation

- First campaign clears grant earned chest keys. Supply, Weapons, Armor and Engineer categories share rare-within-10 / epic-within-30 guarantees. Base odds are shown; no paid chest flow or real-money wallet is enabled.
- Common through Epic equipment now has bounded, slot-appropriate affixes. Actual Power, HP, armor, movement, pickup and spell cooldown use these bonuses; movement and cooldown remain capped.
- Original item artwork, comparison stats, saved chest receipts, transactional opening, mission reward previews and a selectable Rare ten-medal reward.
- Missions 1–4 have a separate seeded 35% equipment roll; mission 5 keeps its guaranteed Uncommon vest. First-clear and repeat rewards stay distinct.
- Ten-second boss warning, nearby drop collection on victory, six living / twenty-four total Caller reinforcement limits.

## Visible ability progression

- Each of eight attacks now has two rank-2 specializations: focused versus broader coverage, changed projectile counts, orbit counts, pierce limits or pull strength. Damage/coverage tradeoffs are applied to the simulation.
- Choosing an upgrade first previews both specializations without spending the level. Back restores the original choices without rerolling; pending branch selection survives saving.
- Eight paired rank-3 evolutions. New Sanctuary healing is position-dependent and nonstacking; Collapsed Star bursts once; Phantom Flurry respects the projectile cap.
- Read-only progression diagram appears in specialization selection and individual ability inspection. All attacks remain automatic.
- 74 specialization checks plus 99 populated HUD/path layout checks passed. Static path screenshot: `artifacts/nightfall-godot/ability-progression.png`.

## Salvage Contracts

- Separate three-minute material runs unlocked by Garage Lights. Open three caches, wait for the central beacon to power at 90 seconds, then remain inside its ring for three seconds to extract. No boss in this side mode; campaign rules are unchanged.
- Choose one equipment slot before departure. Completion grants 80 Credits, 2 Parts, 45 Survivor XP, 25 Mastery XP, and a Common (75%) or Uncommon (25%) item for that slot. Every third clear adds one earned supply key. Carried loot is additional; defeat retains protected loot.
- Save/resume, replay, loadout locks, targeted rewards and once-only banking use the existing expedition pipeline. Deadline failure cannot offer a video that would be unable to rescue the run.
- 33 new rules/controller checks and 754 Haven layout checks pass. Full suite: 1,353 checks, zero failures; known ObjectDB exit warnings remain logged separately.

## Preparation and boss learning

- Arcanum guide displays all eight ability trees, both specialization tradeoffs, and the paired passive needed for evolution. It is a preview, not a permanent spell grant.
- Training Yard offers each of the five encountered Outskirts bosses with equipped stats and three rank-one spell presets. Discovery persists even after defeat; older cleared saves migrate correctly. Practice grants no rewards and leaves an existing campaign checkpoint intact.
- Full suite: 1,573 passing checks, including 961 phone layout checks and 13 preparation journey checks. Updated the old practice-health expectation because practice now uses equipped health.
