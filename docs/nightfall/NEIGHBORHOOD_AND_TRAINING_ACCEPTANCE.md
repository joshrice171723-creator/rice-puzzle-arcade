# Neighborhood, class training and equipment acceptance

Implementation record, October 19, 2026. This records tested behavior and remaining limits; it is not a claim that the full twenty-zone game is finished.

## Delivered behavior

- The battlefield is 2400 × 2400 world units with a 1860 × 1860 playable region, four times the former playable area. The Blackout Outskirts neighborhood includes garages, houses, vans, street details and warm lighting. Fourteen solid scenery footprints govern player/enemy movement and defense placement. Shrines have larger grounded artwork, collision and an accessible charge circle.
- Hero movement is 80 units/second. WASD and arrow keys move the hero. A touch or held mouse press creates a floating joystick at that position; release removes it. A second touch cannot steal its owner. Dodge remains the manual combat action.
- Five ordinary enemy families have distinct continuous gait, attack and death motion: Drifter, Runner, Spitter, Bulwark and Hexer. Bulwarks telegraph a cleave and mitigate frontal physical damage; Hexers telegraph a three-bolt fan. Existing bosses retain their individual attacks.
- Wave arrival rate smoothly reaches five times its opening value. Newly spawned enemies scale to +65% HP, +40% speed and +35% damage by the end of the survival phase. Existing enemies are not healed when pressure rises. Mission One retains pressure 0.85; the suggested alternative 0.45 tuning was not adopted. Crowd limits prevent unbounded accumulation. The boss arrives at the end of survival and must die for victory; there is no second countdown.
- Physical weapon presentation uses continuous recoil and weapon geometry. Pistol, scattergun and crossbow shots start at a shared weapon muzzle transform and converge onto their authoritative collision trajectory. This preserves range and point-blank hit behavior.
- Damage numbers animate above hits, and health bars identify damaged enemies. Separate settings control numbers and health bars. Disabling either does not alter combat damage.
- Expedition side arrows browse all twenty planned zone entries. Only Zone One is playable; later entries remain clearly unavailable.
- Each class owns six permanent training skills, its focus, combat level and talent allocation. All skills cap at 99. Exactly 99 lifetime talent points are available per class. Three branching specializations replace the generic grid; ranks, parents and spend gates are visible. Talent Preview inspects the same definitions without spending.
- Permanent damage-training awards are ten times slower than the previous 24/240-per-enemy budgets. Fresh classes start Ranged focus for the starter pistol; existing saved focus choices remain intact. Mission XP, spell acquisition and permanent training remain separate systems.
- Real combat hooks apply bounded talent effects to weapons, spells, shields, structures, repair, dodge/class cooldowns and shrine charging. Effects survive a saved expedition. They do not create an unearned starting shield.
- Equipment checks the selected class's trained level: armor uses Defence, melee uses Strength, ranged weapons use Ranged, magic weapons use Magic, and current accessories/medkit use Vitality. Upgrade levels 1–5 require skill levels 1/3/5/7/9. Rarity and temporary buffs cannot bypass requirements. UI, equip, loadout, merge, upgrade and final stat assembly share the check.
- Class switching keeps all inventory and selects eligible owned replacements. If no eligible weapon remains, one immutable level-one training pistol prevents a training deadlock. It cannot be upgraded, merged or salvaged, and repeated switching cannot generate spare copies.

## Verification evidence

Focused suites exercise the actual Godot model and controls rather than only checking labels:

| Verification | Result |
|---|---:|
| Class-specific equipment eligibility and recovery | 33 checks, 0 failures |
| Profile / equipment workshop / item popup / daily progress / expedition | 237 checks, 0 failures |
| Keyboard, floating touch ownership, Dodge, settings, zone arrows | 32 checks, 0 failures |
| Neighborhood geometry, wave escalation, enemy attacks and checkpoint migration | 107 checks, 0 failures |
| Actual talent damage, cooldown, shield, repair and interaction effects | 19 checks, 0 failures |
| Weapon muzzle and collision-path agreement | 5,458 checks, 0 failures |
| Ranked class talents | 361 checks, 0 failures |
| Branching talent UI | 1,605 checks, 0 failures |
| Combat progression / training UI / progression tools | 3,717 checks, 0 failures |
| Enemy animation | 356 checks, 0 failures |
| Read-only migration of the real pre-change version-5 profile | 19 checks, 0 failures |

The full test command initially stopped on old untrained equipment fixtures. Those fixtures now explicitly earn or supply the relevant trained level; the restrictions remain asserted in their own suite. The remaining suites were run in a separate continuation, not represented as a single uninterrupted all-green command. Existing combat, magic, reward, UI, defenses, salvage, preparation and mastery checks also passed. Some headless UI fixtures report ObjectDB shutdown cleanup warnings; these are distinct from script errors and failed assertions.

The real saved-profile migration probe preserves inventory, equipment IDs, currencies, mission progress, training levels, focus and the active checkpoint without writing the source file. Old coordinates migrate once to the expanded world, and pending old-rate XP converts once. Already active expeditions retain their recorded equipment effects until settlement; new attempts reconcile eligibility.

Review found a boundary projection that could place an old left-edge checkpoint inside the garage after world clamping. Collision now chooses the nearest escape that is also inside playable bounds. Added coverage exercises every scenery corner, movement against the boundary and the actual old `(135,150)` checkpoint case.

An automated collision-aware starter route (seed 41, actual damage, automatic attacks, earned spells and normal Dodge) cleared Mission One at 316.6 seconds with 218 kills and 32.2 HP. Simpler steering strategies failed before the boss. This proves a starter clear is possible; it does not estimate a human success rate or establish that campaign difficulty is finished. Three starter Salvage seeds also completed with actual incoming damage. The longer starter route is an opt-in test, `tests/starter_survival_test.gd`, rather than part of every quick test run.

## Visual and device evidence

Actual Godot renders, rather than generated target mockups, were inspected for the battlefield, enemy attacks, weapon motion, locked-item popup and talent branches at 320/430 widths. Evidence is in `artifacts/nightfall-godot/neighborhood-pass`, `branch-talents`, `equipment-requirements`, and the committed weapon-muzzle visual iteration folder.

Native 1080 × 1920 captures confirmed the Expedition arrows, branching talent menu and live battlefield. The first native capture revealed insufficient ground texture density; the final floor pass replaces the stretched floor with original modular asphalt/paver materials, four times the source density, continuous mirrored joins and mipmaps. Its final 1080 × 1920 actual Arena render is ground-only, with HUD hidden; see `visual-iterations/world-art/GROUND_MATERIALS.md`.

The final Android export completed successfully and was installed on `emulator-5554` (Android 11, 1080 × 1920) using `adb install -r`. The normal game was reopened after installation. Installation waited until the current run had ended. The profile was byte-equivalent before and after replacement, retaining 1,014 credits, 20 parts, 10 gems and the existing training/talent allocations.

- APK: `artifacts/nightfall-godot/nightfall-proof.apk`
- APK SHA256: `431D3A204E5E499652284FDA68EA909080F01BC232EC72DE7C8C6C852263F727`
- Preserved profile SHA256 (UTF-8 backup representation): `874320E8EDC2410A0D2C9CFDDC14FB8D351AAB1B2CE52670BC68AA0137ACCB2B`
- Export log: `artifacts/nightfall-godot/neighborhood-pass/android-final-build.log`

The final APK includes equipment popup eligibility refinements, ineligible gadget-effect suppression, the boundary collision fix and the sharper modular ground. It is newer than the first native battlefield/talent captures. No new full mission was started in the user's profile solely to verify that replacement.

## Practical limits

- Zones 2–20, future equipment template floors and future upgrade caps remain authored proposals, not playable content. Current catalog templates use level-one base requirements; stronger future families must receive explicit reviewed catalog floors.
- Balance math documents cap effects and compare gear power. They cannot substitute for human playtesting, retention data or long-session performance measurements.
- Native screenshots and focused controls tests do not certify every phone or sustained five-times-wave performance. Physical-phone performance and extended manual balance testing remain open.
- This work changes no ad SDK integration and makes no new claim about production ad fill, purchases or revenue.
