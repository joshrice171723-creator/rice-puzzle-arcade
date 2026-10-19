# Shared menu panel assets

Two distinct production textures generated with the built-in image generation tool from the approved `assets/class-showcase/controls.png` style reference. Existing assets were preserved. Both textures were inspected full size and verified as RGBA 1254 × 1254. Edges touch the full canvas. The generator supplied slight alpha throughout (main 0–253, inset 9–251); sampled center alpha is shown in panel-regions.json. Render on a blue backing for stable color rather than assuming fully opaque pixels.

## Main panel

`apps/nightfall-godot/assets/class-showcase/panel-main.png`

Welcoming lighter royal blue with diagonal enamel stripes, thin silver/cyan edge and small gold corner studs. Generated source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-970f76f5-9d23-4c57-84b5-918bbfb444f8.png`. Exact prompt is `PANEL_MAIN_PROMPT.txt`.

Nine-patch recommendation: source corner slice 112 px each edge, because each gold corner fitting extends into that region. At runtime resize the texture to 256 square before creating a StyleBoxTexture, with source margins 23 px and destination border width around 12 px. Content inset 14 px. Central stretch region is deliberately free of ornaments; subtle diagonal stripe angles will vary with panel aspect ratio, which is acceptable for decorative enamel.

## Inset panel

`apps/nightfall-godot/assets/class-showcase/panel-inset.png`

Darker cobalt tone with subtle diagonal stripes, thinner cyan rim and plain silver chamfer corners. Generated source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-e6efb0e1-4863-4857-a9eb-4d625699b765.png`. Exact prompt is `PANEL_INSET_PROMPT.txt`.

Nine-patch recommendation: source slice 66 px each edge; at 256 square use source margins 14 px and destination border width around 7 px. Content inset 10–12 px. Suitable for rows, content cards and quiet control groups. Avoid stacking many inset borders within inset borders.

Both panels contain no writing, icons or baked interface content. Their relative brightness was visually checked against one another. This asset-only task made no game source edits or Git commits.
