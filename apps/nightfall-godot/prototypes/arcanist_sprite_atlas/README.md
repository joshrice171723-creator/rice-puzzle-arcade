# Arcanist gameplay sprite review

`assets/arcanist-gameplay-draft.png` and `assets/arcanist-motion-reactions-draft.png` are AI-generated transparent 4x4 atlases created with ChatGPT image generation from Nightfall's existing Scavenger gameplay artwork and approved Arcanist class art in this project.

The first atlas provides idle, walk, wand-cast, and dodge poses. The second adds turns, start/stop transitions, hit reactions, and defeat. The `--arcanist-review` preview draws the sprite at 3x its normal visual size for close inspection; its collision and combat values remain unchanged. Normal gameplay keeps the original scale. The flattened PNGs are review drafts, not layered source art. They do not provide equipment-swap variants, and this is a 2D sprite character rather than a skinned 3D model.

[`in-game-review.png`](in-game-review.png) captures the character in the actual Godot arena with normal enemy AI, automatic attacks, map props, and dodge. [`in-game-review-3x.png`](in-game-review-3x.png) is a fresh 3x visual review capture; the review harness uses a clear road position so the house does not cover the enlarged sprite. The captures use the disposable combat-review profile, so no campaign progress was saved. [`QUALITY_RESEARCH.md`](QUALITY_RESEARCH.md) records the researched art and mobile-performance direction.

Both sheets were generated in ChatGPT's signed-in image tool from the game's own references. No marketplace or third-party art is included. Keep the pilot until it passes visual review; do not treat these drafts as the final roster standard.
