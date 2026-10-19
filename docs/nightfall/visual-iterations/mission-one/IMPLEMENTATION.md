# Mission One: Garage Lights presentation and combat pass

## Shipped behavior

- Original painted garage courtyard for campaign Mission One, with warm garage lighting, cool open paving and boundary scenery. Scenery remains decorative; the existing movement bounds remain authoritative.
- Distinct Drifter, Runner and Spitter silhouettes from one transparent atlas. Explicit crops prevent neighboring artwork leaking into a sprite. Procedural gait, breathing and recoil complement the existing hero frames and two boss poses; these are not skeletal animations.
- Small damage numbers, critical markers, impact sparks, defeat fragments, pickup accents and dodge trails. Rapid hits on one enemy coalesce. Feedback is capped at 48 events, pauses with simulation and never grants XP or enters the checkpoint schema.
- Player HP uses pale cyan; hostile HP and attack warnings use coral. The action area stays clear. Blue-and-gold controls and modal panels match the approved menu styling; choice panels dim the paused arena behind them.
- The Mauler's slam shows its complete danger boundary and a separate filling windup arc. Rush and rubble-toss aim warnings remain tied to the existing locked attack targets.
- Brief wave announcements introduce runners and crossfire. They disappear during normal combat.
- Automatic basic fire selects a living enemy inside the projectile's 425-unit travel range. It does not fire at corpses or empty space. All attacks remain automatic; dodge and movement remain manual combat controls.
- Gentle, bounded separation improves ordinary enemy readability in campaign Mission One. Bosses, charging enemies and active windups are not displaced. Other missions and Salvage retain their previous spacing.
- Reduced Effects disables the added ambient movement, gait/recoil flashes and decorative particles while preserving small damage labels and necessary danger warnings.

## Rules retained

Four-minute survival summons Garage Mauler. Defeating it is required to clear the mission; no second timer or automatic survival win. Performance and collection still govern bonus rewards. Permanent stat XP, damage credit, talent points, equipment values, chest rules and reward banking are unchanged.

## Verification

- Final regression suite: 28 suites, 7,539 checks passed, including 19 Mission One checks. The only later source correction keeps mirrored enemy art centered over its collision position; it was visually recaptured. Existing shutdown warnings about two leaked UI ObjectDB instances remain and are not claimed fixed by this pass.
- Three seeded, real starter-stat Mission One simulations cleared at 282.0, 285.5 and 274.4 seconds. Each killed 245 enemies and reached run level 5 or 6. No HP, damage, immunity or outcome overrides. This is a deterministic smoke test, not a measured player win-rate claim.
- Added checks cover coalescing, damage/XP preservation, pause/expiry, bounded events, crowd separation, fixed tells/bosses, living-target selection, no phantom firing, boss arrival and required boss kill.
- Graphics fixtures cover arrival, crossfire, level-up, rush, slam and reduced effects at 430×760 and 320×568. They use disposable profiles and never load the player's save.
- Graphics stress: legacy 120-actor scene uses 30 draw calls (budget 60); Mission One with 120 authored enemies, 40 pickups and 12 hits uses 89 (budget 100), down from 225 before batching. Physics peaks in the three starter simulations were 1.18�2.50 ms on this host; these are not Android FPS measurements.
- Android debug APK exported, installed successfully on emulator-5554, launched and restored the existing Mission One checkpoint into its paused screen. Full saved profile JSON before install and after resume-to-pause is identical. No live run was advanced on the player save. APK SHA-256: `98382c58e036d5c45f7fed1e8e2cd250d255380a181e6ed391d2ed253db069f2`.
- Independent source/screenshot review found no blocking defect. Actual mobile performance and long-term difficulty still require device/playtesting data.

Local evidence lives under `artifacts/nightfall-godot/mission-one/`. Artwork prompts, source paths, geometry notes and atlas crop coordinates are recorded in `ART.md` and `enemies-regions.json`.
