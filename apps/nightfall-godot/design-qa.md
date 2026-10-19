# Nightfall noncombat design QA — 2026-10-19

## Visual target and scope

The user approved the implemented Class Hero Showcase and explicitly requested that same style throughout the app outside combat. The selected original board is `docs/nightfall/visual-iterations/approved-choices/class-options.png` (left Hero Showcase). The implemented Class screen is the latest accepted target. No app scaffolding or runtime replacement: this is an existing native Godot Android game.

## Implementation

- One shared blue/gold control atlas, slim beveled frames, Lilita One headings and Nunito text across noncombat screens.
- Painted brighter blue diagonal-stripe panels, quieter inset panels, lavender item detail rows. Item details remain a modal with real equipment controls.
- Consistent title ribbons, wallet icons, Sharp Relic equipment frames, five-tab navigation with raised Expedition and gold active tab.
- Approved character artwork now used consistently in Class, Gear, Base and progression previews. Class idle breathing, hair/coat sway and magic; Gear/Base idle motion; island debris and background motes. Reduced effects disables decoration and hidden menus pause motion.
- Shop, Gear, Expedition, Base, Class, facilities, crafting, merge, substats, sets, builds, filters, chests, reward choices, missions, daily rewards, calendar, contracts, training, Arcanum, mastery, skills, settings and pause/result/ad dialogs use the shared visual system.
- Real transaction callbacks, unlock requirements, five-column inventory scrolling, save locking, ad reward receipts and active-attempt restrictions retained.

## Iterations resolved

1. Matched approved slim Class controls instead of old bulky menu atlas buttons.
2. Replaced older character portraits with the approved roster and used the Class hall behind the Gear hero.
3. Updated main and secondary headings to the same Class ribbon.
4. Added shared stripe panel assets; removed old popup brightening that made the new panel cyan.
5. Fixed Shop overflow when an earned rare choice and unavailable-video message coexist.
6. Fixed absolute Label wrapping in Class and Arcanum; placed skill point/check badges inside their frames instead of overlapping the next row.
7. Preserved square panel source aspect before nine-patch scaling.

## Evidence

- `artifacts/nightfall-godot/class-style-final-tests.log`: **25 suites, 6,771 checks, zero failures, zero script errors**, successful process exit. Existing ObjectDB teardown leak warnings remain and are not represented as fixed.
- `artifacts/nightfall-godot/class-style-catalog.log`: **85 rendered states, zero layout failures**, 430x760 and 320x568 viewports plus native result dialogs. Disposable fixtures only; populated inventory and purchase states do not modify a player save.
- `tests/haven_ui_test.gd` also checks 390x844 and visible control bounds. Semantic tests exercise crafting, merges, substats, progression, daily claims, popup actions and reward paths.
- Visual inspection: all five main tabs, populated gear and popup, Shop unavailable/loading/confirmation, skill tree, Arcanum and secondary-page catalogs. Representative exact renders are saved under `docs/nightfall/visual-iterations/class-showcase/implemented/`.
- Motion regression verifies advancing local clocks, grounded portraits, hidden pause/resume and Reduced effects without progression mutation.

## Acceptance and limits

The common visual-style implementation and local render/behavior checks pass. Art approval remains the user's judgment. Native installation and save comparison are recorded below after the final build. This pass does not prove production ad fill, store purchases, physical-device performance or all twenty zones' combat balance. Characters use layered portrait deformation/effects, not a newly rigged 3D skeleton.

## Android acceptance

- Rebuilt `artifacts/nightfall-godot/nightfall-proof.apk`, installed with `adb install -r` (Success), launched `com.joshuarice.nightfallproof` on `emulator-5554`.
- Inspected actual Shop, Gear, Expedition, Base and Class screens, opened/closed equipped boots popup. Active saved expedition and zero balances remained visible; no purchase, reward claim, equipment change or mission start was performed.
- Canonical JSON comparison of `class-showcase-profile-before.json` and `class-style-profile-after.json`: identical complete player save.
- Recorded `artifacts/nightfall-godot/class-style-catalog/native-gear-motion.mp4`; left emulator in Gear. Native overview copied into this iteration's evidence directory.
- Export reported `[ DONE ] export` and produced a working APK, but its Windows console process remained idle after export. Stopped that owned export process after successful install/launch and stopped its Gradle daemon. This cleanup issue remains logged; do not confuse it with a failed runtime or claim clean exporter shutdown.

APK SHA-256: `8e4ae21372336bb554b2d7ee8897c8562c22e40d77ae74175fbc138b144e58fa`.
