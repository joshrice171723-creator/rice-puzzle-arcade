# Rich Blackout Outskirts district

This supersedes the sparse six-prop asphalt presentation. The original approved `assets/menu-outskirts.png` and `assets/haven-base.png` were inspected before generation. Their blue roofs, beveled slate, warm windows, ivy, toolboxes and lived-in scavenging detail informed the new original assets.

## Production assets

- `assets/world/district-floor.png`: opaque 1254-square flat ground, authored diagonal street intersection, paved sidewalks, curving low curbs, driveways, faded road paint, warm pools of light and short overgrowth. All regions remain walkable ground; no tall buildings or vehicles are painted into the floor. Source `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-c1807cf0-d4f2-4eee-85c3-9a92c69c8da7.png`.
- `assets/world/district-details.png`: 1254-square RGBA atlas, true alpha 0–255. Six original pieces: double amber streetlamp, iron fence with stone posts, utility pole, stacked crates/toolbox/tire, ruined low wall, and flat ivy/leaf groundcover. Source `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-84571e37-4ba9-4bc8-9e72-73a03510e117.png`.

Exact generation prompts saved alongside this report. Original image alpha and pixels were preserved. Explicit source crop rectangles in `world_art.gd` avoid relying on imperfect atlas cell spacing.

## Layout and integration

`neighborhood.gd` now contains **14 solid scenery entries**, each with the existing `kind`, `pos`, `draw_size`, `footprint` API. Building/van entries retain `atlas_index`; smaller details use `detail_index`. `WorldArt.draw_scenery_body` handles both without caller changes. Parent already consumes the shared `footprint` for collision and sorts by `footprint.end.y`.

New details intentionally frame the starting route: a full house near (1520,1110), double streetlamp near (960,1120), another lamp near (1260,1530), fence near (1030,1490), utility pole near (1620,1510), plus peripheral scavenging piles and low ruined wall. These supplement the existing garage and van rather than replacing them. Center spawn (1200,1200) remains clear, as do the supplied shrine/cache centers. All tangible objects have authored collision footprints; flat short groundcover does not block.

`WorldArt.draw_floor` draws 22 fixed low groundcover patches around foundations and route edges in addition to the full floor. `draw_scenery_ground` adds subdued amber light pools below lamps/fences. No new animation loop, physics nodes or per-frame random placement was introduced. The scene remains 2400-square and altar size remains 348 × 304.

## Actual rendered evidence

- `district-spawn-render.png`: actual Godot compatibility renderer at a 430 × 760 viewport, 0.72 world scale, centered around (1200,1200). Shows the shop altar, two lamps, iron fence, garage edge, full house side, van, diagonal sidewalks and a clear combat lane around the scale figure.
- `district-east-render.png`: same real renderer centered around (1550,1340), showing the complete warm-lit house, van and utility pole along the connected street.

Both rendered successfully with `WORLD_NEIGHBORHOOD_PREVIEW_OK` and were visually inspected. These are disposable rendering previews, not screenshots of active combat: no enemies, HUD or mission simulation were exercised. Parent must validate integrated camera, collision, y-sorting and crowd readability. The previews show the requested increased environmental richness without claiming a final user acceptance.

No arena, run, field motion or Git changes were made by this task.
