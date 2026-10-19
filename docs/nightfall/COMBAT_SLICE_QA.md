# Nightfall combat feature increment

October 18, 2026. First M1 increment in the isolated Godot project. Joshua requested feature/product development while existing bugs remain tracked for a later cleanup pass. This does not mark M0 or M1 fully accepted.

## Playable changes

- **Four wave phases:** Dusk Patrol starts with Drifters; Rift Runners enter at 45 seconds; Ash Spitters enter at 100 seconds; Last Stand increases pressure at 165 seconds. Timer expiry still summons a mandatory boss, never victory.
- **Three enemy behaviors:** Drifters pursue; smaller, faster Runners close gaps; Spitters stop at range, mark their aim for 0.65 seconds, then fire toward that locked position. Their shots can be dodged. Size, tint, and shape markers distinguish variants; production art is pending.
- **Three automatic spells:** Ember Bolt, Frost Ring, and Chain Spark. First level-up offers all three. Later choices offer spell ranks, pistol damage/fire speed, or healing when health is missing. Rank three is the cap. Selecting once consumes the offer and resumes combat.
- **The Breaker:** a marked charge lane with recovery, a circular slam around the boss, and three spreading projectiles. The attack interval shortens below half health. Gold HUD health bar; no second timer.
- **Boss practice:** separate no-reward encounter with three rank-one spells, fresh health, and a dedicated practice replay. It does not complete campaign missions.
- Ordinary gameplay displays wave, kills, and learned spells instead of profiling numbers. Crowd diagnostics retain frame-rate metrics.

## Starting balance values

These are prototype values for the combat slice, not a tuned 20-zone economy.

| System | Values |
|---|---|
| Drifter | 48 HP; 32 units/s; 10 contact damage |
| Rift Runner | 32 HP; 56 units/s; 8 contact damage |
| Ash Spitter | 40 HP; 24 units/s; 12 projectile damage; four-second firing cooldown |
| Breaker | 1,000 HP; 35 units/s; 18 contact damage; 30 slam damage; 16 per rubble projectile |
| Ember Bolt rank 1 | 36 impact + 12 burn over two seconds; five-second cooldown; burn refreshes rather than adding stacks |
| Frost Ring rank 1 | 26 damage within 150 units; 40% ordinary-enemy slow for three seconds; bosses receive only 10% slow for 1.5 seconds; eight-second cooldown |
| Chain Spark rank 1 | 28 / 18 / 12 damage; maximum three distinct targets; 180-unit jump range; seven-second cooldown |
| Spell ranks | Each rank adds 25% of base damage; maximum rank 3; cooldowns do not stack |
| Hard budgets | 120 enemies, 64 friendly shots, 32 hostile shots, 40 pickups, 64 brief visual effects |

All attack timers, projectiles, burns, effects, and spell cooldowns freeze during pause or level-up choices. Bosses resist Pulse knockback. Existing contact invulnerability and dodge protection still apply.

## Verification

- **59 checks passed:** 17 existing rule checks, 23 combat checks, 19 layout/replay checks.
- New combat checks cover wave unlocks, one-time offer selection, actual Ember impact/burn, pause, distinct chain targets, reduced boss control, spitter locked aim, the three boss windups, projectile/effect limits, capped offers, practice setup/replay, and a real-damage boss victory.
- A deterministic practice movement policy defeated the boss in 12.0 seconds with 102 HP remaining. A separate ordinary-run movement policy died after 231.3 seconds with 253 kills and one learned spell. These are regression scenarios, not evidence of balanced difficulty or a target win rate.
- The graphics regression still measured **21 draw calls** for 120 actors and 40 pickups, under its 60-call ceiling. That scenario does not measure peak mixed spell/projectile rendering.
- Desktop inspection confirmed the three spell cards and charge-lane presentation. Fixture captures: `magic-choices-desktop.png` and `boss-telegraph-desktop.png`.
- Android feature candidate installed and ran in the visible API 30 emulator. `combat-native-menu-ready.png` shows the full no-scroll menu. `combat-native-boss.png` shows real damage, the gold boss bar, three learned spells, and the slam warning. `combat-native-result.png` shows practice victory after 12 seconds with 86 HP. `nightfall-combat-preview.mp4` records the interaction. These captures precede the final practice-retry button adjustment.
- `combat-native-spell-menu.png` shows the actual level-three selection screen after ordinary play, with Chain Spark already learned and the next Ember/pistol choices visible. Wave UI progressed to Runners Arrive.

## Final internal exports

| Artifact | SHA256 |
|---|---|
| `artifacts/nightfall-godot/nightfall-proof.apk` | `C00B7E6F531049511E943148C7B7C7B04B9ED56EC3D6FE2F568555E342020C52` |
| `artifacts/nightfall-godot/NightfallProof.exe` | `3BA9C807E54310DCA30C558659F9F94A204E83E35832326B6C59B7759B9D538E` |

Both are internal debug exports, not store releases. Build logs: `android-combat-final.log` and `windows-combat-final.log`. Android export used the command-scoped `GRADLE_OPTS=-Dorg.gradle.daemon=false` workaround and returned normally.

Evidence is under Git-ignored `artifacts/nightfall-godot/`; this summary is versioned. The three puzzle games and original Expo Nightfall were unchanged.

## Remaining product work

The existing [bug log](KNOWN_ISSUES.md) remains open. Boss combat is still short and uses prototype art. Final difficulty requires player feedback, better enemy silhouettes, readable hit reactions, audio, class/ability alignment, and a broader set of play styles. No native full-wave-to-boss victory, physical-phone acceptance, campaign progression, inventory rewards, shrines, Haven, equipment, or purchases are claimed by this increment. Existing Google sample-ad integration is unchanged; no new production-revenue claim is made.
