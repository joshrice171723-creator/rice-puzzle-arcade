# Scavenger casting animation

Current runtime uses only the consistent standing pose as a textured mesh. Legs, torso, coat and weapon deform continuously; the four-pose sequence described below is historical source documentation. See `../CONTINUOUS_COMBAT_VFX.md`.

Project asset: `apps/nightfall-godot/assets/hero-cast/scavenger-casting.png`.
Renderer: `apps/nightfall-godot/hero_cast.gd`.

Generated with the built-in image generation tool, using the project's existing `assets/actors.png` as the identity/style reference. Original retained at `C:/Users/joshr/.codex/generated_images/01a152a3-e512-7201-b56a-f15b881de84b/exec-33f269cf-43c3-4779-bc68-d76abc9d45b6.png`. No external game artwork was used as a generation reference. Original PNG copied unchanged, with its alpha channel preserved.

## Generation specification

Production sprite animation sheet, four distinct full-body poses of the same dark-haired Nightfall scavenger in a royal blue long coat, white scarf, brass shoulder armor, leather gloves/boots, satchel and brass pistol. One horizontal row, transparent background, isometric three-quarter view facing right. Consistent identity, scale, lighting and boot baseline. Windup with elbow back and shoulders twisted; gather with raised open palm; release with fully extended arm and forward lean; recovery with lowered arm. Real pose changes, not scaled duplicates. No magic, flames, particles, glows, ground shadows, circles, text, labels or borders. Requested 2048 by 768 canvas and generous transparent gutters. Source reference used only its human hero, excluding enemies.

## Inspection and geometry

Output is RGBA 2048 by 768. Sampled gutters have alpha zero; alpha range is 0–254. The four silhouettes have visibly different arms, stance and shoulders. The release frame lowers the pistol out of its silhouette; it is visible in the other three poses. No flames are baked into any pose.

The generator did not obey equal 512-pixel cells: the extended release hand reaches x1612. Explicit source regions avoid slicing it or including a neighboring pose. All sole baselines are y668. The following rectangles include a small transparent margin:

| Pose | Source x,y,w,h | Foot pivot in sheet pixels | Time |
|---|---|---|---|
| Windup | 20,118,465,554 | 230,668 | 0–0.09s |
| Gather | 568,122,429,550 | 770,668 | 0.09–0.16s |
| Release | 1041,142,576,530 | 1290,668 | 0.16–0.24s |
| Recovery | 1640,110,403,562 | 1825,668 | 0.24–0.36s |

The renderer uses one scale (80/550), preserving the crouch rather than stretching every crop to equal height. Its foot offset matches the current walking sprite's 5.6-pixel sole offset. Left-facing casts reflect around the same anatomical pivot. Reduced effects skips the initial windup transition and retains gather, release and recovery. It does not add screen shake, particles, fake motion scaling or hit timing.

## Integration

`HeroCast.draw(canvas, pos, offset, direction, cast_age, reduced) -> bool` returns false for negative, non-finite or >=0.36-second ages. Render the normal walking/idle sprite when false. Call this sheet only for the scavenger identity: engineer and other authored identities retain their existing renderer. Selection of an attack and cast timing remain outside this drawing helper.

Actual Godot drawing fixture: `artifacts/nightfall-godot/hero-cast-review.png`; normal right, mirrored left, and reduced effects reviewed. Temporary fixture reports 28 timing/boundary checks, zero failures in `hero-cast-test.log`. This validates the isolated renderer; the parent integrates it into the running mission and verifies the full Ember sequence.
