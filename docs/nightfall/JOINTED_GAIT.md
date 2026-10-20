# Continuous jointed gait

The hero and enemy renderers deform one continuous textured mesh. They do not cut the body into separate sprite pieces or switch between generated poses. Hip and knee bones solve each ankle target; a separate ankle transform keeps the sole level. Narrow cuff blends join the rigid segments. The torso keeps its shape and transfers weight vertically; opposing shoulder rotations replace sideways sine-wave stretching.

The hero cycle consumes the existing distance phase (36 world units per cycle), with 55% stance and 45% swing. Stance targets move backward at matching world speed. Vertical travel uses a shorter projected step because the source characters are drawn from an elevated three-quarter camera. Enemy cycle distance scales with body height and runner/bulwark proportions. The robed Hexer retains a restrained floating gait instead of inventing visible knees under its robe.

`draw_motion`, `weapon_attachment`, and `muzzle_offset` accept an optional final `movement_direction` argument in world space. It is independent of aiming. Enemy dictionaries may provide `motion_blend` and retained `motion_direction`; older callers retain the original fallback behavior. The same hero deformation supplies the wrist position used by the equipped weapon and muzzle.

`dynamic_rig_mesh.gd` keeps a small surface pool per canvas and sorted draw slot. Vertex buffers use Godot's documented eight-byte 2D positions. UV/color attribute offsets and stride come from RenderingServer. Unchanged UV/color arrays do not upload again. Each slot retains up to four vertex-count variants; surfaces are recreated only on cache misses, not unconditionally every frame. Broad explicit bounds prevent old mesh bounds from culling a camera-relative batch after buffer updates. Existing texture flush order and scene depth remain owned by the arena.

Native verification checks mesh identity reuse, actual moved pixels, RGBA channel order, UV atlas changes, and vertex stride. Gait checks verify stance displacement and adjacent-frame continuity. `gait_cycle_render.gd` records 120 native frames covering all four hero classes and five ordinary enemy types with moving ground marks. The resulting GIF, MP4, and temporal strip live under `artifacts/nightfall-godot/gait-rig/`.

These are jointed deformations of existing painted poses. They preserve silhouettes and identity but cannot reveal hidden limbs or provide the occlusion changes of independently authored directional animation. Recorded cycles are visual evidence, not a claim of full skeletal or new directional artwork. Performance improvement must be measured in the same live AI/collision workload; mesh reuse alone is not a frame-rate result.

API references: [ArrayMesh region updates](https://docs.godotengine.org/en/stable/classes/class_arraymesh.html), [RenderingServer mesh formats](https://docs.godotengine.org/en/stable/classes/class_renderingserver.html).
