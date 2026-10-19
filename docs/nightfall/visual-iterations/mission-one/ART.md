# Mission One artwork

Generated with the built-in image generation tool; no game source changes or Git operations in this asset task.

## Garage yard floor

Runtime file: `apps/nightfall-godot/assets/mission-one/garage-yard.png`.

Original generated source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-2e772c7c-a61b-4b25-ad87-626d43d60c4a.png`.

Reference files inspected before generation: existing `assets/courtyard.png` for the open floor and overhead camera; `assets/menu-outskirts.png` for Blackout Outskirts garage/truck, slate/blue/amber palette and painted material identity.

Full prompt: `FLOOR_PROMPT.txt` alongside this report.

Inspected output: 1254 × 1254 opaque square. Full bleed blue slate/asphalt and pavers, subdued cracks and faded parking dashes, amber garage facade along upper edge, cropped abandoned truck on far right edge. No baked characters, UI, pickups, shrines or interactive objects. Center is open walkable ground.

Geometry note: most tall boundary objects remain outside the 9% inset. A few lower wall corner fragments extend inward to about 88% of image height. For a world whose playable bounds are 135..1065 within 1200, a slight expansion of the floor image to approximately world -35..1235 keeps lower edge detail outside the playable square. Check the rendered collision boundary before acceptance. Existing courtyard remains untouched, so this floor can be scoped to Mission One.

## Mission One enemy atlas

Runtime: `apps/nightfall-godot/assets/mission-one/enemies.png`, 1774 × 887 RGBA with true alpha extrema 0–255. Original source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-98fcc614-a986-4bea-bdb7-f8113f9ee25e.png`. Exact prompt: `ENEMIES_PROMPT.txt`.

Inspected against existing `assets/actors.png`: same topdown three-quarter painted chunky stone family. Three original silhouettes: stout violet-core Drifter, slim amber-cracked Runner with long forelimbs, blue crystal-back Spitter. All face lower-right, full bodies and feet visible, no baked labels or background. Spitter has a triangular crystal cluster rather than an exactly smooth bell; still distinctly readable from the others.

The generator did not respect equal cell width perfectly. **Use individual sprite rectangles rather than dividing into exact thirds**, which would cut Drifter and Runner arms. Alpha threshold >32 measurements, `(x, y, width, height)`:

| Sprite | Crop |
| --- | --- |
| Drifter | 19, 227, 609, 558 |
| Runner | 678, 249, 555, 509 |
| Spitter | 1249, 250, 511, 508 |

For safe alpha fringes, expand each rectangle by 4 pixels on all sides. Align sprites at bottom center after cropping. These crops normalize the varying baseline heights while preserving the original unedited image and alpha. `enemies-regions.json` includes both the imperfect nominal cell measurements and recommended occupied sprite bounds.
