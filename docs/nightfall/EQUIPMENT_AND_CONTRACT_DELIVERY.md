# Equipped weapons and Salvage Contracts — October 19, 2026

This follow-up makes weapon choice visible in combat and Gear, adds a reliable route to a chosen weapon, and reduces repeated spell geometry work. It builds on [first-zone combat delivery](COMBAT_MECHANICS_AND_PRESENTATION.md). This is a first-zone internal Android build; it does not finish the planned twenty-zone campaign.

## Player-facing changes

- Four original empty-handed class bodies replace the baked-in weapons in the combat illustrations. Pistol, scattergun, crossbow, wand and sabre attach to the moving hand. Guns recoil, the wand gestures, and the sabre swings. Muzzle flashes follow the held tip. A simultaneous spell cannot redirect the basic weapon's aim or restart its recoil.
- Gear displays the actual equipped weapon on that same character, with continuous idle motion. Its existing blue/gold hall, equipment tiles and fixed five-column inventory remain. Hidden Gear stops animation; Reduced Effects freezes it. Class keeps its approved showcase.
- Combat currency and kill counts use icons with numbers, removing the repeated words from the small HUD.
- Salvage Contracts let players select one of the five weapon families. The named selection is committed when the attempt starts, survives checkpoint/resume, controls the completion reward and remains selected on replay. A completed contract grants the promised item, not merely a random weapon slot.

## Rewards and compatibility

The side mode still requires the first campaign clear, three real cache openings, and a three-second extraction at the central beacon. The beacon becomes available at 90 seconds; the side-mode deadline is three minutes. Campaign missions remain four minutes of survival followed by a mandatory boss kill, with no second timer.

Contract weapons retain the existing starter-zone budget: level one, 75% Common / 25% Uncommon. Selection changes weapon identity, not rarity odds or damage scaling. Failed contracts do not grant completion equipment. Protected loot and the existing three-clear supply-key bonus remain unchanged. The saved attempt owns the reward; result input cannot substitute another family. Existing attempts/checkpoints without a target family default to the Service Pistol. Invalid saved families are rejected.

Supply/weapons chests still roll the existing five families. Field caches retain their existing starter-item naming. Dynamic equipped armor costumes and future-zone items are not added here.

## Renderer changes

Spell bodies, flame ribbons and sparks now reuse cached meshes; the existing shader continuously deforms their vertices. UV bands distinguish geometry roles while preserving ordinary material-only sprite UVs. Actual damage, timing and RNG stay in simulation. Joystick circles also use the existing cached shape renderer.

The body still uses continuously weighted 2D mesh deformation, not a rigged 3D character or alternating generated frames. [Asset provenance and attachment anchors](art-sources/EQUIPPED_HERO_BODIES.md) document the unchanged generated atlas and its runtime regions.

## Verification

Evidence is local under `artifacts/nightfall-godot/completion-pass/`. These files are not committed as product source.

- Full regression: 36 suites, 8,227 checks, zero failures and no script/engine errors (`tests-release.log`). Known ObjectDB fixture teardown warnings remain.
- The equipment graphics fixture covers twenty class/weapon combinations, left and right facing: 144 checks, zero failures. It verifies grip anchoring, aim, simultaneous spell/weapon independence and actual changed rendered pixels during motion.
- The spell shader graphics fixture passes 83 checks, including moving output, pause/reduced effects and reuse of cached meshes.
- The crowded graphics fixture uses 78 draw calls against a 100-call budget; the baseline fixture uses 31 against 60. Draw-call budgets are not frame-rate acceptance.
- Salvage checks cover selected reward identity, duplicate completion protection, legacy saves, controller wiring, replay, phone widths and three full starter-gear routes. Seeds 41, 73 and 109 clear at 93.90, 95.75 and 93.03 seconds, with 78, 81 and 78 kills and 158.1, 154.9 and 163.0 HP remaining. These routes walk to actual caches and extract while ordinary enemy AI attacks. They do not grant damage immunity or health.

## Debug-only native contract review

The native review reads `files/combat-preview.flag`: empty for the practice roster, `campaign` for starter Mission One, or `contract` for the real starter Salvage Contract. The contract route grants only its first-clear prerequisite in a disposable profile and chooses a Crossbow completion reward. It earns its combat XP, collects caches, extracts and invokes the actual reward transaction. The committed campaign profile is never used for those transactions.

The command-line equivalent is `-- --combat-contract --combat-quit`. Contract metrics include the actual reward receipt in `combat-contract-metrics.json`. Delete the debug flag before ordinary play. Review automation is isolated behind debug mode and does not steer a normal player run.

## Remaining acceptance

Sustained 60 FPS on the emulator, physical-device performance, human difficulty tuning, native rescue-ad playback and production billing/mediation remain separate acceptance work. Warden and Arcanist combat kits are implemented but retain their future-zone unlock gates. Zones 2–20 are design content, not shipped missions. Known fixture teardown warnings remain NF-006.

## Exact Android build and end-to-end reward proof

APK: `artifacts/nightfall-godot/nightfall-proof.apk`.
SHA-256: `C7B2095DEBD21DF259FEF0BD3FC304F6F957A74C78A7FB94980A7C69D3AD279C`.
Installed on `Arcade_QA_API30`, Android 11/API 30, Intel Iris Xe host graphics.

The native starter contract completed at 94.18 simulation seconds (96.12 wall seconds), 81 kills, 154.86 HP remaining, six enemy hits and two dodges. Its actual banked receipt contains **Common Salvager Crossbow**, 187 credits and 12 parts. The UI then opened that earned item's card, equipped it, and showed the Crossbow in the character's hand and equipped weapon slot. Evidence:

- `android-contract-metrics.json`: terminal state and banked receipt.
- `android-contract-live.png`, `android-contract-result.png`: gameplay and completion screen.
- `android-crossbow-card.png`, `android-crossbow-equipped.png`: real UI equip journey in the disposable review profile.
- `nightfall-contract-review.mp4`: native 540×960 recording beginning shortly after the run started, through completion; no captured audio. Screen recording and concurrent regression tests make this run unsuitable for frame-rate comparison.

The actual campaign file hash remained `d059dd0eae6b8c8d5d4f8d346d12e5a2199e3ecbfeacb49a55d96fbc02a41c52` before and after the contract and equip journey. Its save was not replaced or modified.

## Final native roster without screen recording

All ten stages completed on the exact APK above; all five bosses were defeated. This uses granted practice spell loadouts with live enemy AI and ordinary health/damage, not a campaign difficulty study. No build, regression suite or screen recording ran during this measurement.

| Segment | Class / weapon | Outcome | Mean FPS | Enemy hits |
|---|---|---|---:|---:|
| Waves | scavenger / pistol | waves | 40.7 | 0 |
| Waves | engineer / scattergun | waves | 36.2 | 2 |
| Waves | warden / sabre | waves | 35.6 | 2 |
| Waves | arcanist / wand | waves | 47.0 | 0 |
| Waves | scavenger / crossbow | waves | 36.3 | 2 |
| Boss 1 | scavenger / pistol | victory | 50.2 | 0 |
| Boss 2 | engineer / scattergun | victory | 53.7 | 3 |
| Boss 3 | warden / sabre | victory | 50.2 | 5 |
| Boss 4 | arcanist / wand | victory | 55.7 | 0 |
| Boss 5 | scavenger / crossbow | victory | 53.7 | 0 |

Evidence: `android-final-roster-metrics.json` and `android-final-roster-logcat.txt`. Waves range from 35.6–47.0 FPS and bosses from 50.2–55.7 FPS. Earlier-pass waves were 27.2–38.2 FPS and bosses 41.0–49.6 FPS on this emulator. These single-run observations support improvement but are not a controlled benchmark. Steady 60 FPS and physical-device performance remain open.
