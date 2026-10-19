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

## Class mastery and boss presentation

- Scavenger mastery milestones now reveal nearby caches, cleanse Spitter slows with Phase Step, empower the next basic hit, and survive one lethal hit at 1 HP. Engineer milestones discount construction, overclock a repairing turret, reclaim 40% of actual paid scrap, and heal one adjacent structure. Proc state survives checkpoints and rescue; bonuses apply only to the selected class.
- Spitter damage now slows walking by 20% for two seconds. Dodge keeps its movement speed; fully shielded/dodged hits do not apply the slow. A visible ring and SLOWED label communicate it.
- Thirty focused mastery checks pass. The runner now treats Godot script errors or missing passing summaries as failures even when Godot returns exit code zero.
- Five original boss silhouettes with neutral/wind-up poses replace enlarged ordinary-enemy art. Training pages use the same boss portraits. These are two poses, not complete directional animation sets.
- Static captures cover the Arcanum, Training Yard, contract preparation, class mastery and in-run ability path. No manual play or physical-device acceptance.

## Requested compact combat HUD

- Removed the opaque top card. Centered timer, separate combat-level label, nine-pixel XP bar, compact upper-left ability icons, and upper-right Credits/kills follow Joshua's reference layout.
- Six-pixel HP bar follows the character. Boss HP is a separate six-pixel bar. Camera framing keeps the hero and HP below the HUD at the northern boundary and above bottom controls at the southern boundary.
- Pack/Build moved beside the bottom controls. Resource notices expire after three seconds; branding/footer and ordinary debug/ad text were removed from combat.
- Pause is an explicit compact menu. Instructions are behind How to play; level-up/shrine choices still pause and display when needed.
- 63 new layout/interaction checks cover three phone viewports and arena edges. Static populated capture: `artifacts/nightfall-godot/compact-hud.png`. Native rendering remains a separate acceptance step.

## Final presentation increment

- Engineer now uses its own original four-pose brass-goggle/tool-backpack atlas. Right/left static captures verify the centered ground pivot. The original source is preserved and its prompt recorded in ASSET_SOURCES.md.
- Pause > Progress shows current damaging-hit count, rescue eligibility for the combat medal, and opened-cache count. Practice and Salvage Contracts show their own goals. This is an explicit paused screen; combat stays clear of objective cards.
- Final rules/UI suite: 1,774 checks, zero failures across 17 suites. `final-feature-tests.log` records the run. The compact HUD/progress suite contributes 81 checks across three phone viewports; these are assertions, not 1,774 human play sessions.
- Static graphical fixture: 120 enemies plus 40 pickups used 24 draw calls against the 60-call limit. `final-render-budget.log` records the result. This is rendering evidence, not a physical-phone FPS claim.
- Eleven static product captures generated without advancing combat or loading/writing the player's save. Final combat preview: `artifacts/nightfall-godot/compact-hud-final.png`. Engineer left/right, pause, progress, abilities, mastery, contracts and boss captures are alongside it.
- Deferred ObjectDB teardown warnings remain in the bug log. No manual emulator gameplay or actual rewarded video playback was performed during this feature-only session.

## Packaged build receipt

Runtime source: `27c1133` (`feat(nightfall): add mission progress and engineer presentation`). Later changes to this record and the static viewport-capture script do not change exported runtime resources; `tests/*` and source documentation are excluded by both export presets.

| Artifact | Size | SHA256 |
|---|---:|---|
| `artifacts/nightfall-godot/nightfall-proof.apk` | 178,688,713 bytes | `066FE27401156165B3626010AAE49A3DAE1A9ED6B65433F0BCB82805FD9593EE` |
| `artifacts/nightfall-godot/NightfallProof.exe` | 114,242,280 bytes | `D2C2E4907C64708B0719C3AF7834DEE1540ADE4ACE45D5C0BBD1EDC85FBC6827` |

Android export completed October 19 at 02:15:40 UTC; Windows completed at 02:16:18 UTC. Android signature verification passed with APK Signature Scheme v2. Package `com.joshuarice.nightfallproof`, minimum Android API 24, target API 36, arm64-v8a and x86_64. Exported assets include the Engineer and five-boss atlases, compact HUD controller, class talents and Salvage Contracts. This is a debug/internal build, not a signed store release.

Logs: `android-final-features.log`, `windows-final-features.log`, `final-feature-tests.log`, `final-feature-render.log`, `final-render-budget.log`. Machine-readable hashes/evidence: `artifacts/nightfall-godot/feature-build-receipt.json`.

Static fixture windows were also rendered at 320×568 and 390×844. Their captures live in `phone-320/` and `phone-390/`; the canvas preserves its aspect ratio and taller windows letterbox. Render texture captures contain the game canvas, not the operating system's outer window or letterbox bars. No scrolling was required in combat, pause or mission progress. This does not replace a physical-device safe-area/touch-target check.

At the final device-discovery check, `emulator-5554` was offline. No APK installation, manual emulator play, native video delivery or physical-device acceptance was performed in this feature-only session. Existing rendering defects remain in KNOWN_ISSUES.md.

## Next delivery gates

1. Human review of the compact combat layout and branching ability choices, using this exact build.
2. Resume the deferred bug-cleanup pass when requested; reproduce the missing Android button labels and ordinary-actor mirror issue before changing them.
3. Validate native rewarded rescue on a reachable emulator/device: no fill, early close, earned completion, repeated callbacks and background/resume. Production publisher IDs, mediation and purchases are separate work.
4. Play the five campaign missions with starter and upgraded gear to tune human difficulty and boss readability. Automated assertions do not establish fun, player failure rates or long-term progression balance.
5. Complete the next content milestone: a second zone using the same rules/content structure, then broaden classes and animation. Do not label twenty zones complete based on this one-zone prototype.
