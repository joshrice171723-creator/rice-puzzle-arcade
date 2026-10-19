# Gear visual iteration 1

October 19, 2026. Local Godot implementation on base `4e30cb8da540afd39ca650d8001b2cf5d3080823`, alongside the coordinated daily-progression feature work. This is a review candidate, not a statement of visual acceptance or installed-build completion.

## Implemented

Gear now has a quiet midnight surface, a generated illustrated stone plinth with separate contact shadow, a restrained blue/violet stage halo, grounded breathing motion with reduced-effects support, compact labeled stat cards and a darker inventory well. Six original chamfered rarity frames use distinct accents/corner motifs and tier numerals. The eight actual starter items remain the entire fresh inventory; five columns, eight equipment positions and five navigation tabs remain intact.

The latest requested item composition is implemented as a popup over dimmed Gear: rarity ribbon/name/tag, close button, large item portrait left and actual level/stats right, set bonuses and substats in stacked rows, owned/required currency strip, and pinned Equip / Upgrade / Quick Upgrade. Upgrade colors follow Nightfall blue/violet/amber. Long details scroll inside the popup; close and actions stay fixed. Lock, merge, substat tuning and salvage remain accessible in that contained detail list. Actual runtime pointer input is blocked behind the popup. Escape and Android Back close it and restore inventory scroll and normal keyboard/back behavior. Quick Upgrade displays the exact aggregate levels/cost on its first tap and invokes the transactional profile method only after confirmation.

Daily objectives and calendar routes plus an Expedition shortcut are connected to the parent feature implementation.

## Actual runtime captures

All images are unaltered Godot viewport output from the disposable render harness. It sets `arena.testing = true`, never loads a player save, never advances combat, and never starts an expedition.

- [Fresh starter, 430×760](gear-starter-430x760.png)
- [Fresh starter, 320×568](gear-starter-320x568.png)
- [Desktop, 860×760](gear-starter-860x760.png)
- [Mixed rarity fixture](gear-mixed-rarity-fixture-430x760.png)
- [Epic boots popup fixture, 430×760](gear-popup-epic-boots-fixture-430x760.png)
- [Epic boots popup fixture, 320×568](gear-popup-epic-boots-fixture-320x568.png)
- [Quick Upgrade exact-total confirmation fixture](gear-popup-quick-confirm-fixture-430x760.png)
- [Mythic medkit / insufficient resources fixture](gear-inspection-430x760.png)

The funded Epic boots and mixed-rarity images are explicitly synthetic fixtures. They do not represent earned player equipment or balances. All displayed item stats/effects and the level-five cap come from actual game definitions.

## Verification

- `gear_popup_test.gd`: 22 checks, zero failures. Actual blocked background navigation click, full popup fit at 320×568 and 430×760, Escape/Android Back, scroll restoration, quick-upgrade confirmation/exact spending, level cap and active-expedition upgrade locks.
- `haven_ui_test.gd`: 1,852 checks, zero failures.
- `haven_product_test.gd`: 103 checks, zero failures; five tabs, real purchases, five-column full inventory and existing controls.
- `progression_tools_test.gd`: 3,142 checks, zero failures; saved builds, filters, item protection and class tree.
- `equipment_workshop_test.gd`: 83 checks, zero failures; actual merge/substat/set paths remain available.
- `gear_visual_render.gd`: graphics-backed Intel Iris Xe / Godot 4.7.2 Compatibility captures at both required phone sizes and desktop. Source and runtime asset metadata are in [manifest.json](manifest.json).

## Remaining gaps and review boundary

No native package was exported or installed by the art agent; the parent coordinates that gate. These captures establish local rendering, not Android density/safe-area acceptance, physical-device performance, release acceptance or Joshua's final visual approval. Some test processes, including some popup runs, emit ObjectDB exit-leak warnings; this iteration does not establish a leak-free native session.

The parent integrated the shared illustrated header, framed currency trays and beveled five-tab dock, plus beveled item-popup actions. Shop now has a chest feature card and two illustrated supply cards with readable disabled prices; its ad message uses player-facing language. Class shares the stone plinth and halo. Secondary workshop pages and full Base/Class content styling remain future visual work. Hero breathing is restrained whole-silhouette scaling anchored near the boots; separate cloth/weapon animation layers and a motion recording remain future visual work. The new stage is more grounded, but its generated stone has finer texture than the existing hero art and remains subject to review. An annotated reference comparison and motion recording remain future work. Native acceptance evidence is recorded below; final visual approval remains with Joshua.

The popup follows the supplied screenshot's layout, with actual Nightfall data: no fabricated poison effects, eighty-level progression, extra bonus sections or balances. The retained Nightfall art and typography have their own proportions. The popup headline and stat rows use a heavier variation of the existing licensed Barlow font; the close control is round. Set counts explicitly describe Rare+ qualifying pieces, so four equipped Common items are not misreported as missing equipment. The exact-total confirmation fits between the currency strip and pinned actions. Long names, localized labels and final physical-device touch sizing still require visual review.

## Reproduce

Use the Godot executable configured by `scripts/nightfall-godot.ps1`, project `apps/nightfall-godot`, script `tests/gear_visual_render.gd`, and pass `-- --capture-dir=<existing absolute directory>`. Run `tests/gear_popup_test.gd` headlessly for the popup gate. Both use disposable fixtures; the popup test writes only `user://nightfall_gear_popup_test.json` and cleans that file and its own backup/temp siblings.

## Shared menu review

Fresh-profile renders at 320�568 and 430�760 cover [Shop](menu-shop-430x760.png), [Expedition](menu-mission-430x760.png), [Base](menu-haven-430x760.png), and [Class](menu-class-430x760.png). They use the same header/dock as Gear. All are disposable fixtures, not the player save.

Native testing caught an Android Back ordering defect: restoring SceneTree quit behavior inside the notification allowed the same event to quit. Closing the modal is now deferred until that notification finishes; a regression assertion verifies Back remains consumed during dispatch. The final emulator check is recorded below.

## Final integrated validation — October 19, 2026

The full suite passed **22 suites / 5,998 checks / zero failures** after the shared menu and Shop/Class polish. Some existing test processes still report ObjectDB exit-leak warnings; the suite is not proof of leak-free operation. The daily graphics fixture separately passed 73 checks.

Android debug APK SHA-256: `335FB6981042F99D045237B02DEC2B0B4DA3D169C28041EB8EAC0241EF7C66A4`. Installed with `adb install -r` on emulator-5554. Actual native captures show [Gear](native-gear-final.png), [item popup](native-popup-final.png), and [Gear after Android Back](native-back-final.png). Back now closes only the popup; the app remains alive. The background navigation tap was blocked while the modal was open.

The original saved profile was compared before and after install/menu inspection and was identical in full, including the active expedition, eight items and wallet. No run was started/abandoned, purchase made, or reward claimed on that profile. Disabled upgrade actions in the native screenshot reflect the saved expedition and zero funds. The funded Epic boots screenshots use disposable fixtures to exercise enabled actions. This is emulator acceptance, not physical-device or final visual approval.
