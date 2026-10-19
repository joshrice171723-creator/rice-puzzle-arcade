# World art: altars and quiet stone floor

Original production assets generated with built-in image generation. Visual reference viewed first: `docs/nightfall/visual-iterations/combat-animation-targets/frost-and-ember.png`. Only the art direction and landmark proportions informed these new assets; the reference screenshot is not used as game art.

## Assets

- `assets/world/altars.png`: 1536 × 1024 RGBA, true transparent background (alpha 0–254), two complete stepped stone landmarks with four corner pillars and detached floating crystals. Left amber/brass Artificer; right violet/silver Twinflame. Source `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-ad762ba3-8747-4dd6-a4c9-9b8c95d6651e.png`.
- `assets/world/flagstones.png`: 1254 × 1254 opaque smooth slate/lavender tiles, quiet broad faces with clean bevels. Actual output is approximately ten tiles per side; 1200-unit mapping gives approximately 120-unit tiles, larger than the requested nominal 90. No gravel, raised obstacles, characters or text. Source `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-c176cb2c-fcb4-4560-aa44-b9b212627ea1.png`.

Exact prompts are alongside this report. Existing assets remain preserved.

## Rendering API

`world_art.gd` provides static `draw_floor(canvas, offset)`, `draw_site(canvas, site, offset, time, reduced)`, `draw_site_ground(...)` and `draw_site_body(...)`.

Draw grounds before y-sorted actors and landmarks. Sort site bodies by `site.pos.y`; base anchors near that position. Ring radius uses actual `Field.RADIUS`, still 60. No gameplay or collision values change. Optional `site.exhausted` dims relic landmarks after the global relic cap.

Altars draw at 156 × 136 world units with detached crystals 32 × 55. Chests use existing field-props art at 42 × 40, preserving opened appearance. Crystal float and charge motes stop with reduced effects. No text is baked into world art.

Source rectangles separate altar bases and crystals. Temporary CanvasItem transforms reset before returning. Charge, cooldown and unavailable colors follow actual site fields.

Godot headless load check passed: `WORLD_ART_LOAD_OK`; asset import completed. Parent integration and final runtime camera/scale acceptance remain separate.
