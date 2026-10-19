# Ground fidelity at phone resolution

Native inspection identified the previous floor as a 1254-pixel map stretched over 2400 world units and approximately 6000 physical pixels. This made baked flowers and cobbles oversized and blurred relative to the characters and separately drawn buildings.

## Production correction

The floor now uses two newly generated original 1254-square opaque material images, each mapped over **600 world units**. This increases source texel density fourfold in both axes without upsampling an existing image. The existing large district image is preserved for provenance but is no longer preloaded or rendered by WorldArt.

- `assets/world/asphalt-material.png`: restrained blue-gray cracked asphalt material. Original built-in image generation source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-4ab6d749-e40f-46af-a28b-68896bbb5bc4.png`.
- `assets/world/paver-material.png`: small staggered beveled slate/lavender paving bricks. Original source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-e6098758-d0f3-4853-a8cd-7081b1014e63.png`.

Exact prompts are saved alongside this report. Approved original Outskirts art supplied material style guidance. Generated images were copied without pixel processing. Import files enable mipmaps so desktop downsampling remains stable while the native view uses near-source detail.

## Rendering and joins

`WorldArt.prepare_ground()` caches a bounded set of tile and clipped sidewalk polygon geometry once. World-anchored UVs preserve material registration during camera movement. Alternating mirrored tile edges reuse exactly the same texture boundary, preventing gaps and mismatched hard seams. Paver UVs trim 1.8% from each texture edge so the atlas edge grout does not double into a heavy stripe at mirrored joins.

Four authored sidewalk wedges frame the two diagonal streets and their central intersection. Narrow bevel bands draw clear low curbs; restrained dashed road paint establishes street direction. These are decorative flat ground and do not change movement collision. Existing fourteen tangible scenery descriptors, their footprints, twenty-two short groundcover placements, shrines and all gameplay values remain unchanged.

## Actual render acceptance evidence

`ground-materials-1080.png` is a **1080 × 1920 offscreen ground-only render of the actual main Arena scene** through the Godot OpenGL compatibility renderer, with a character, enemy, lamps, fence and van. HUD CanvasLayers are intentionally hidden in this fixture; it is not whole-app HUD or Android acceptance. The live emulator was not touched, no APK was installed, and the active player's run was left alone.

The actual render was inspected at native resolution. Ground detail is sharper and paving bricks are smaller relative to the hero. The initially heavy repeat grout line was corrected and the updated joins inspected. Render completed with `GROUND_NATIVE_PREVIEW_OK`; focused diff check passed. Parent owns final APK and integrated native validation after the active run ends.
