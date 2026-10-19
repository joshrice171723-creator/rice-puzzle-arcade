# Class showcase environment and controls

Generated using the built-in image generation tool. Approved visual reference: `C:/Users/joshr/.codex/generated_images/01a14d17-a754-75d2-b2d5-d0fc040447c7/exec-466040dd-d70a-4a0a-b757-07cf63f66e22.png`, specifically the left Hero Showcase hall and the Skill Tree/Mastery buttons.

## Hall

Runtime: `apps/nightfall-godot/assets/class-showcase/hall.png`, 1254 × 1254 RGB, opaque.

Generated source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-ae2296da-9e1b-4c8f-a0ff-85455896bf92.png`.

Prompt: `HALL_PROMPT.txt` in this directory. Inspected at full resolution: bright stone columns, blue/gold banners, softly distant castle, warm twin braziers, empty circular blue stone pedestal. No baked character or interface. Hero ground anchor approximately `(0.50, 0.75)` of the square source. The front of pedestal reaches about y0.91, but the standing surface is y0.74; place feet on the standing surface. Braziers are around x0.08/x0.91 and y0.47.

## Controls

Runtime: `apps/nightfall-godot/assets/class-showcase/controls.png`, 1254 × 1254 RGBA. True alpha verified with extrema 0–255. Hollow portrait center and inter-component space are transparent.

Generated source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-6ae5d88d-7ed1-42ea-b6d4-5b08bde329d6.png`.

Prompt: `CONTROLS_PROMPT.txt`. Inspected: sharp chamfered cobalt/silver button, honey-gold button, blue-steel/silver hollow portrait frame, angular blue title ribbon. Thin bevels and diagonal enamel stripes closely follow the approved mockup, with blank surfaces for real interface text.

Crop bounds `x, y, width, height`, based on alpha >32:

| Component | Bounds |
| --- | --- |
| Blue button | 40, 219, 559, 142 |
| Gold button | 657, 219, 560, 142 |
| Portrait frame | 82, 662, 480, 467 |
| Title ribbon | 627, 836, 606, 123 |

These exclude a few almost transparent glow pixels. `controls-regions.json` contains machine-readable bounds. At mobile size the blue/gold buttons work around 156 × 44, with text provided by Godot rather than painted into the asset. Buttons need hover, pressed, focus and disabled states supplied by the consuming UI.

Only asset files and provenance were created by this asset task; no gameplay, profile, source logic, commit or push was changed.
