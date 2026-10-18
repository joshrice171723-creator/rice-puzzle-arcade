# Beaconbound proof asset sources

October 18, 2026. Both PNGs were created with the built-in image generation tool for this project, copied into this directory's `assets/`, and visually inspected. Original outputs remain in the Codex generated-images folder. No external game's artwork was copied into the runtime.

`actors.png`: 1774×887 transparent prototype atlas, four Scavenger frames and four stone-imp frames. Style/character reference: the project's approved `docs/nightfall/art-concepts/nightfall-b-beaconbound.png`. The generator did not honor equal row occupancy; runtime texture regions explicitly exclude neighboring-row feet. This is not a production directional animation pack.

Prompt:

> Use case: stylized-concept. Create ONE production prototype sprite atlas, transparent PNG, exactly 4 columns by 2 rows equal cells, wide canvas aspect 2:1, ideally 1536x768. Reference image is STYLE AND CHARACTER reference only. NO text, NO grid lines, NO panels, NO scenery, no ground shadows. Top row: four sequential walk-cycle frames of the SAME Beaconbound male Scavenger in cobalt coat, ivory scarf, brass shoulder armor, dark hair, leather boots, holding a small amber rune pistol pointing toward lower right. Bottom row: four sequential walk-cycle frames of the SAME small hunched stone imp with violet glowing eyes, dark slate segmented body and claws. Isometric/top-down 3/4 game camera, faces toward lower right, consistent perspective. Each character is centered in its own cell with feet on same baseline at 85% of cell height, body fits within middle 70% of width and height, generous transparent spacing so each cell crops independently. All eight frames completely separated, no overlap. Chunky clean cel-shaded original mobile game art, distinct silhouette, not pixel art. Four poses per row: left step, passing, right step, passing. Scavenger weapon stays same size and hand across frames. This is a sprite animation sheet, not a UI mockup. Absolutely transparent background and no labels.

`courtyard.png`: opaque square floor/environment texture. Navigation uses an inner rectangle rather than assuming every illustrated doorway is traversable.

Prompt:

> Use case: stylized-concept. Production game environment texture for Nightfall Beaconbound, a square 1536x1536 overhead orthographic arena floor. Rich chunky cel shaded hand-painted mobile game style. Dark cobalt/navy slate cobblestone courtyard in ruined magical city at night, violet shadows, amber lantern pools near perimeter. Camera looks straight down, NOT perspective, NOT a floating island. Almost entire middle 80 percent is unobstructed walkable paving with subtle geometric circular rune in center, irregular stones and slight wear, muted contrast for readable characters. ONLY outer 8 percent rim has low stone edging and occasional tiny rubble with four open entrances, no tall obstacles, NO green, NO characters, NO monsters, NO text, NO HUD, NO menus, NO weapons, NO bright particle effects. Detailed enough to feel like a real fantasy game level, restrained and cohesive. Seamless coherent flat navigable arena, border extends fully to image edges.

`icon.svg`: original simple code-authored amber beacon mark for internal build identification, not a final store icon.

`shadow.svg` and `experience.svg`: original code-authored ellipse and violet pickup/glow textures. They preserve the prototype's primitive shapes while allowing shared-texture batches on Android; no third-party artwork is used.
