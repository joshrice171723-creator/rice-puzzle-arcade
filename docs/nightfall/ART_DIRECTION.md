# Nightfall Art Direction Review

October 18, 2026. Joshua selected Direction B (Beaconbound): "i like B lets go with that style." Concept exploration only; no game code, assets in a runtime, or layouts have been implemented in this pass.

## Main design

The [Nightfall Main Design Plan](NIGHTFALL_MAIN_PLAN.md) is the canonical gameplay plan. Its complete latest conversation version is preserved verbatim beneath the document header. The [earlier design archive](archive/2026-10-18-earlier-objective-design.md) preserves earlier detailed proposals without making its superseded campaign rules current.

The campaign is graphical mobile survival: survive timed waves, then kill the boss without a second timer. Extra rewards depend on performance and collection. These images do not alter that rule.

## Shared visual requirements

- Portrait phone layout, with the whole combat HUD and controls on screen.
- Original stylized characters, visible equipment, magical salvage machinery, a welcoming home refuge, and readable top-down action.
- Navy, slate/cobalt blue, violet, ivory, and amber. Avoid green as the default interface or terrain palette.
- The Scavenger, rune pistol, magic staff, coat, boots, charm, and repair drone appear alongside a Haven home concept and combat layout.
- Equipment needs clear silhouettes at small inventory sizes. Combat effects must leave enemy attacks visible.
- The boards are raster concept illustrations, not final sprites, 3D models, animated assets, or functional screenshots. UI labels, sample statistics, and currency counters are illustrative. Actual navigation and rewards follow the main plan until separately revised.

## Direction A — Emberglass

Detailed sculpted fantasy treatment, weathered materials, taller hero proportions, warm beacon light, and a more cinematic environment. Strong atmosphere; fine detail would need simplification for actual mobile sprites and performance.

![Direction A: Emberglass character, equipment, Haven, and combat concepts](art-concepts/nightfall-a-emberglass.png)

## Direction B — Beaconbound

Selected visual direction. Chunkier illustrated/cel-shaded treatment, broader shapes, cleaner item silhouettes, larger boots and hands, stronger contours, and a more compact home diorama. Small-screen readability and performance still require actual device testing.

![Direction B: Beaconbound character, equipment, Haven, and combat concepts](art-concepts/nightfall-b-beaconbound.png)

## Review status

Direction B is approved as the visual style; A is retained as an unselected exploration. A and B are working style labels, not competing game titles. The expanded class, enemy, boss, map, and inventory concepts below are awaiting review of their individual designs. Character identities and cosmetic details are proposals, not new gameplay requirements. Standalone assets, animation, runtime UI, collisions, and camera behavior are not implemented.

## Classes

Engineer with repair drones, Warden with Aegis, and Arcanist with Rift Pulse. Front/rear views and ability vignettes explore consistent silhouettes beside the existing Scavenger. The Warden's shield is an ability effect, not a seventh equipment slot.

![Engineer, Warden, and Arcanist concepts](art-concepts/nightfall-b-classes.png)

## Enemies

Drifter, Skitter, Gnawer, Spitter, Bulwark, and Hexcaller. Larger silhouettes show role differences; miniature top-down views explore readability. Fine surface details will need simplification at real gameplay scale.

![Six Hollow enemy concepts](art-concepts/nightfall-b-enemies.png)

## Bosses

The Breaker (Zone 1), The Forge Warden (Zone 5), The Pale Howler (Zone 8), and The Night Sovereign (Zone 20), with illustrative attack-warning vignettes. These do not establish final hitboxes or encounter balance.

![Four campaign boss concepts](art-concepts/nightfall-b-bosses.png)

## Blackout Outskirts arena

Full arena overview and a proposed portrait gameplay camera view. An open central courtyard and connecting paths provide space for movement, collection detours, and optional building. The boss entrance leads into the same arena; there is no separate boss-room objective or extraction exit. Labels and build circles are design annotations, not required final UI.

The full-map overview is for review; the phone follows the player at a closer scale. Scrolling the camera through the world is distinct from scrolling a webpage to reach controls. The HUD and controls remain within the phone viewport. Collision clearance, enemy navigation, roof occlusion, and safe dodge distances remain to be validated in a future authorized prototype.

![Blackout Outskirts map and phone camera concept](art-concepts/nightfall-b-blackout-map.png)

## Equipment and inventory

Six equipped slots, a paged inventory, item details, and twelve catalog objects. The final board corrects the initial generated preview: a level upgrade increases Power but not the critical-chance affix, uses Credits and Parts rather than Gems, and uses amber instead of green for the improvement indicator. The medkit uses a heart emblem.

Sample numbers and inventory contents illustrate the layout, not a saved player state. Power 58.3 for a level-8 Rare pistol and next-level 60.5 match the proposed primary-stat formula to one decimal. The page has not been built or tested at a phone viewport. The catalog panel is an art sheet, not an extra in-game screen column.

![Equipment, inventory, item details, and item catalog](art-concepts/nightfall-b-inventory.png)

## Shrines and run interface concepts

The latest visual set covers proximity charging for the fast shop and slow Relic shrine, their choice screens, new abilities versus upgrades, mission rewards, and rescue choices. See [Shrines and run interface concepts](SHRINES_AND_RUN_UI.md) for all four images and the working rules. These are proposed designs, not functional UI. The three-Relic limit is shared across both buff shrines; shop purchases can repeat within funds, ranks, and caps.

![Two shrine types and their charging rings](art-concepts/nightfall-b-shrine-charging.png)

![Shop traits and two-choice Relics](art-concepts/nightfall-b-shrine-choices.png)

![New abilities and upgrades](art-concepts/nightfall-b-level-up-choices.png)

![Mission preview and rescue](art-concepts/nightfall-b-mission-rescue.png)

## Current target: simpler Haven and equipment layout

Joshua supplied simpler home/equipment references after the detailed courtyard concepts below. This steering supersedes the elaborate scenic presentation: use a clean cobalt background, a compact central base model or character, large readable icons, short labels, and four bottom tabs. Keep Nightfall's original characters and magical scavenger identity. Do not reproduce the reference game's shop clutter or green interface.

![Simplified Haven and equipment concept](art-concepts/nightfall-b-simple-haven-gear.png)

Haven: one compact diorama containing Workshop, Infirmary, Storehouse, beacon and selected character; four shortcuts; a mission selector and Venture out action. Gear: large selected-character preview with six equipped slots, Power/HP summary, and eight visible inventory tiles per page. The two-by-four grid is a presentation target; page count must come from actual inventory. Costs, rarities, wallet values and sample inventory in the image are illustrative, not new economy rules.

Build this simpler composition first. Layered 2D scenery, selectable buildings and character idle animation still apply; no sprawling scenic castle or free-roaming home map is required. Upgrades can change a building's visible roof/equipment while retaining the compact layout. Keep details behind taps and inventory paginated. The detailed earlier Workshop panel is a functional reference only and should be restyled to this simpler interface. Only the Base tab rename is implemented so far; the visual overhaul remains a concept awaiting implementation.

## Haven as a physical base — October 18 revision

Joshua requested that Haven look like an inhabited base with buildings and the selected character, rather than a page of buttons. The navigation tab is now **Base**; **Haven** remains the settlement name. The following new images are implementation targets for review, not functional game screenshots. Only the tab label has been implemented in this pass.

![Haven courtyard home concept](art-concepts/nightfall-b-haven-base.png)

Build toward one fixed portrait courtyard scene: the selected character beside the fire, Workshop, Infirmary, Storehouse, Arcanum, Training Yard and the expedition gate. Buildings act as entrances to existing features. Storehouse is the visual name for the existing Quartermaster facility, not a new currency or progression system. Arcanum opens the existing ability guide; Training opens boss practice. The expedition gate opens mission selection. Gear and Class remain available from bottom navigation.

Use layered 2D scenery, separate building sprites and broad invisible touch areas. Keep the character, fire, lights, smoke and repair drone on separate animation layers. Fit the complete home view within the phone; do not require dragging or scrolling to reach a building. Choose legibility over copying every decorative detail in the concept. Small labels and tap targets need phone-size validation.

![Workshop selection and upgrade concept](art-concepts/nightfall-b-workshop-upgrade.png)

Tapping a building highlights it and opens one concise action panel while retaining the character and environment. Show current rank, exact benefit, costs and the resulting appearance. Workshop I to II uses the existing 400 Credits + 12 Parts cost and 10% reduction to equipment-upgrade Credit costs; Parts costs do not decrease. Upgrades should visibly restore or reinforce the relevant building. No construction timer is introduced. Other wallet numbers are illustrative.

Implementation order: (1) layered courtyard and selected-character idle pose; (2) building entry points connected to existing screens; (3) compact facility panels using the existing transactional purchases; (4) rank-specific building art and subtle ambient animation; (5) phone fit, touch targets, reduced effects, save/resume and performance checks. These images require isolated production assets before implementation; they are not a ready-made playable scene.

Both concepts were generated with built-in image_gen. Exact prompts are in [BEACONBOUND_PROMPTS.md](art-concepts/BEACONBOUND_PROMPTS.md); originals remain preserved in the Codex generated-images directory.

## Earlier generation provenance

Both boards were generated with the built-in image_gen tool. Exact generation prompts are preserved in [PROMPTS.md](art-concepts/PROMPTS.md). Originals remain in the Codex generated-images directory; workspace copies are versioned with this plan.

The five additional Beaconbound boards were generated with the built-in image_gen tool using the selected B board as their style reference. Their exact prompts and the inventory correction prompt are preserved in [BEACONBOUND_PROMPTS.md](art-concepts/BEACONBOUND_PROMPTS.md).

The four shrine and run-interface boards use the same built-in tool and selected B references. Their exact prompts and level-up label correction are preserved in [SHRINE_UI_PROMPTS.md](art-concepts/SHRINE_UI_PROMPTS.md).
