# Haven island production asset

Generated with the built-in imagegen tool on 2026-10-19. Reference: the LEFT panel of `../../art-concepts/nightfall-b-sharper-base-gear.png`; current `haven-base.png` supplied as composition reference. No code, save data, or gameplay changed by the asset task.

Runtime file: `../../../../apps/nightfall-godot/assets/polish-v2/haven-island.png`.

Preserved workspace source: `haven-island-source.png` beside this document.

Original built-in output: `C:/Users/joshr/.codex/generated_images/01a152a4-5965-7361-8a43-3e370bbbade7/exec-d8923f9a-003b-4f6b-9ad3-b15cf79f8de8.png`. The workspace runtime file is an unchanged byte-for-byte copy; generated alpha preserved.

## Inspection

- PNG RGBA, **1297 × 1213 pixels**.
- 525,657 pixels fully transparent; all four corners alpha zero. Genuine transparent perimeter; no rectangular night-sky backdrop.
- Alpha range 0–255. Main painted surface is alpha 252–253 (visually opaque); 1,013,602 pixels alpha 200 or greater.
- Alpha > 0 bounds: `(0, 0, 1297, 1213)`, including faint glow and antialias traces at the canvas edge. Alpha >= 128 bounds: `(10, 17, 1289, 1203)`.
- Workshop left, Infirmary upper-right, Storehouse lower-right, violet beacon rear-center, fire front-left. No baked character or labels.
- Suggested runtime hero foot anchor: **(0.51, 0.70)** of the image rectangle, about `(661, 849)` source pixels. This places feet in the open central courtyard between fire and storehouse; scale the hero separately and keep its floor shadow local.
- The island fills almost all the available width; allow runtime layout margins around the image Control rather than clipping its perimeter.

## Exact generation prompt

```text
Use case: stylized-concept
Asset type: production mobile game base-island sprite with genuine alpha transparency.
Input images: first image is the approved Nightfall art reference; use only its LEFT panel for style. Second image is current base art, a composition reference but its opaque square background is wrong.
Primary request: Create one polished original isometric floating stone courtyard island, in the sharp welcoming illustrated mobile fantasy game style of the reference LEFT panel. This is a runtime asset, NOT a UI mockup. Preserve exact recognizable architecture: blue-roof timber Workshop LEFT at x25% y40% with warm orange forge and gold anvil emblem; cream canvas Infirmary tent upper-RIGHT at x75% y35% with red heart banner; smaller blue-roof wooden Storehouse lower-RIGHT at x78% y65% with glowing crate emblem; violet crystal beacon on stone tower rear center. Small warm bonfire foreground left-center. Beautifully shaped stone pavement and cliff edge, subtle sparse ivy.
Composition: full island entirely visible with 6% transparent margin on every side, no clipped roof/beacon/cliff. Broad clean EMPTY central courtyard at x50% y65% for a separate runtime hero. No character, creatures or robots. Isometric angle as reference. Clear readable shapes at only 350 pixels wide, strong clean outlines, simplified broad material shapes, rich saturated royal blue roofs, cream fabric, warm golden lanterns, purple crystal.
Lighting: inviting warm forge/fire/lanterns against restrained cool blue stone shadows. Hand painted crisp cartoon game illustration, premium high polish, not photoreal, no noisy tiny details.
Constraints: transparent background outside the island, actual alpha, NO night sky, mountains, forest, vignette, colored square or background rectangle. Do not bake surrounding atmosphere. No labels, text, numbers, UI, buttons, level markers or framing. No green-heavy palette; ivy only subtle accents. Keep entire island and all buildings self-contained, outlined cleanly with opaque interior and anti-aliased edges.
```
