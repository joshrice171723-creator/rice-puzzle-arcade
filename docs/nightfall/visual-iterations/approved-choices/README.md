# Nightfall approved interface direction

The user approved the implemented Class Hero Showcase on 2026-10-19 and asked to apply that exact look to every noncombat screen.

## Current source of truth

- Class Hero Showcase: `apps/nightfall-godot/class_showcase.gd`.
- Shared controls, panel materials and typography: `apps/nightfall-godot/menu_skin.gd`.
- Character portraits, painted hall, controls and striped panels: `assets/class-showcase/`.
- Main tabs: Shop, Gear, Expedition, Base, Class. Expedition is raised; the active tab is gold.
- Slim blue and gold beveled buttons from the Class reference supersede the earlier Cut Stone action-button option.
- Sharp Relic equipment frames, quiet blue supporting controls, brighter blue subtly striped panels, pale lavender item-stat rows.
- Equipment remains a five-column vertical inventory with modal item details.
- Class and Gear show the same character artwork. Idle breathing/sway and atmospheric effects stop while hidden and respect Reduced effects.
- Keep the blue forest backdrop, real class names, actual saved progression, prices and availability. Mockup balances and fake unlocks are never inserted into player saves.

## References

The option boards in this directory preserve the visual decisions. `class-options.png` left-hand Hero Showcase is the selected Class composition; its Talent Preview concept informed the functional Skill Tree. The later implemented Class screen is the final style approval, not the unused options.

## Scope

Apply the visual system across Shop, equipment, item details, merge, substats, sets, builds, crafting, Expedition, zone/reward/daily/contract screens, Base and facilities, training, Arcanum, Class, mastery, skills, settings and noncombat result/pause/ad dialogs. Combat mechanics are outside this visual pass.
