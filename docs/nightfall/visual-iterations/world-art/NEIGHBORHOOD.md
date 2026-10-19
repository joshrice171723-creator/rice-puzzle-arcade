# Nightfall neighborhood world revision

The map direction returns to the original Blackout Outskirts garage/house/van neighborhood. The approved `assets/menu-outskirts.png` was viewed and used as style reference. New original assets use the same blue roofs, amber windows, slate materials, worn white van and painted fantasy finish. No other game's environment assets were extracted.

## New assets

- `assets/world/neighborhood-floor.png`: opaque 1254-square full bleed flat asphalt/sidewalk intersection. No buildings or vehicles are painted into walkable ground. Source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-7528be23-29d0-45a9-86a6-eef56d3588bc.png`.
- `assets/world/neighborhood-scenery.png`: 2018 × 779 RGBA, true alpha 0–255; three separate garage, house and delivery-van sprites. Source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-98431327-e9c6-4a00-9f2e-e1772fd8ff34.png`.

Exact prompts are saved in `NEIGHBORHOOD_FLOOR_PROMPT.txt` and `NEIGHBORHOOD_SCENERY_PROMPT.txt`. Original generated files were copied without pixel editing. Prior floor assets remain preserved.

## Shared geometry and parent integration

`neighborhood.gd` exposes `entries() -> Array`, returning six read-only descriptor dictionaries: `kind`, `pos`, `draw_size`, `atlas_index`, and absolute world `footprint: Rect2`. Simulation must block these exact footprints; presentation uses the same descriptors. All scenery centers are farther than 240 units from the seven supplied field-site positions and player spawn. Four larger landmarks sit near route edges. A smaller garage at (830,980), footprint 220 × 95, and smaller van at (1460,1400), footprint 190 × 82, establish the neighborhood around the starting route. Do not draw scenery unless its collision descriptors are also active.

`WorldArt.draw_floor()` now maps the street texture to 2400 × 2400 world units, four times the former 1200-square area. Parent owns world bounds, spawn, site placement and saved-position migration.

Call `draw_scenery_ground(canvas, entry, offset)` before actors. Include `draw_scenery_body(canvas, entry, offset)` in the same y-sort as characters, ordered by `entry.footprint.end.y`. Buildings and van have fixed positions and grounding shadows; they do not bob.

## Grounded larger altars

Altar body is now 348 × 304 compared with the prior 156 × 136: approximately five times the image footprint area (2.23 times each linear dimension). Foundation is a fixed paving diamond approximately 348 × 157 world units with a 358 × 164 soft contact shadow. The bottom of the body reaches approximately `site.pos.y + 75`; use `WorldArt.site_sort_y(site)` when sorting the body. Only the separate crystal floats intentionally. Foundation and body do not animate their positions.

Parent's shrine collision ellipse is half-width 130 and half-height 50 centered on `site.pos`. Parent's charging geometry is radius 145 centered on `site.pos + Vector2(0,70)`. Renderer reads optional `site.radius` and `site.interaction_offset`; populate those consistently with simulation. Caches remain 60-radius with zero offset and 42 × 40 art. No collision or charging logic was changed in this task.

## Verification

Godot compatibility renderer executed the actual new floor, garage, altar, foundation, crystal, charge ring and compact chest in a disposable preview scene: `WORLD_NEIGHBORHOOD_PREVIEW_OK`. Capture: `neighborhood-render-preview.png` in this directory. This is a real rendered asset integration preview, not a generated screenshot. It uses the existing 430 × 760 viewport and direct world coordinates; parent's final camera zoom, movement blocking and y-sort need integrated validation.

No arena, run, field, profile or Git changes were performed by this asset/render task.
