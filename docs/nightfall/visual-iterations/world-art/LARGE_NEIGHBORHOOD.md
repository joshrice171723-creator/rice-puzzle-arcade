# Large neighborhood, perimeter and ground contact

## World and authored sites

World size is now **6000 × 6000**, center (3000,3000), playable bounds Rect2(270,270,5460,5460). Hero speed stays 80 and dodge speed stays 360. Neither actor nor structure artwork is scaled with the map. Full playable width now takes approximately 68 seconds to traverse at base speed rather than approximately 23 seconds on the previous map.

The seven authored site positions are:

| Site | Position |
| --- | --- |
| Artificer shrine | 3000,2300 |
| Twinflame shrine | 1550,1650 |
| Twinflame shrine | 4450,4300 |
| Garage supply cache | 1925,3200 |
| Abandoned tool chest | 4050,1750 |
| Outrider pack | 1600,4500 |
| Sealed supply crate | 4600,3100 |

Neighborhood's fourteen prior prop positions move by 2.5 while keeping art and collision dimensions fixed. Six additional tangible props around the starting routes preserve detail near the hero: a house, van, lamp, fence, utility pole and crates. Total is twenty solid descriptors. Groundcover follows these foundations rather than remaining at old coordinates. Every tangible prop retains its shared absolute footprint for parent collision and y-sorting.

## Ground contact

The large opaque diamond and oversized detached altar shadow were removed. Altar structure stays fixed at 348 × 304; only its crystal intentionally floats. A subdued 268 × 78 contact shadow centers beneath the actual base at position +(0,35). No collision size change is introduced by this art correction.

Chest sprite crops now exclude empty atlas padding. Closed chest draws 42 × 37 and opened chest 42 × 43, with the actual lower edge anchored at site position. A small 32 × 10 subdued shadow sits directly underneath, rather than a detached oval. Charging geometry remains the parent's actual 145-radius shrine circle at +(0,70) and 60-radius cache circle at the cache.

## Physical perimeter

`assets/world/perimeter.png` contains four original production components: horizontal iron/stone fence, closed barred gate, left-running fence and right-running fence. Built-in generation referenced original Nightfall Outskirts art, not another game's asset. Source: `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-a2272ee8-3269-43fc-9346-e182ad661784.png`; exact prompt is `PERIMETER_PROMPT.txt`. True alpha preserved. All gate art is closed.

`WorldArt.draw_boundary(canvas, offset, front, view=Rect2(0,0,430,760))` draws north/west in the back pass and south/east in the front pass. Parent calls the back pass after floor and the front pass after actors. Fence baselines follow World.BOUNDS (270 through 5730). The same clamped bounds supply physical blocking; no visual gate implies an exit or an unimplemented unlocked path.

Only visible perimeter segment indices are computed and drawn, rather than scanning all segments. Five to eight segments appeared in the tested edge views; none appeared in interior views.

## Terrain performance

`draw_floor` accepts an optional logical viewport rectangle; its default remains 430 × 760. World-to-view culling selects only 600-unit cells intersecting the view plus a 24-unit margin. The test views submitted **two to six visible cells**, independent of total map dimensions.

Material polygons are lazily cached per cell. Visible-cell ranges are triangulated once into **at most two retained ArrayMesh batches**, one asphalt and one paving. No per-frame terrain `draw_polygon` calls remain. One retained colored mesh supplies all narrow curb bevels. The viewport-range cache is bounded to 64 entries. Small road-paint and visible groundcover draws remain separate. Scenery ground rendering has its own footprint/view cull.

This is a response to the measured native terrain bottleneck; it is not itself an Android frame-rate claim. Parent owns comparative device profiling.

## Render evidence

Eight actual Godot compatibility-renderer fixtures completed with `WORLD_LARGE_RENDER_OK`: altar, cache, closed north gate and east boundary, each at 430 × 760 and 1080 × 1920. Representative captures saved here:

- `large-altar-430.png`: fixed stone foundation contact without detached hard polygon.
- `large-cache-1080.png`: bottom-anchored compact chest and subtle contact shadow.
- `large-north-gate-1080.png`: closed gate joined to physical perimeter fence.
- `large-east-fence-430.png`: continuous repeated east boundary along the collision edge.

Images were inspected; geometry/props are drawn by actual WorldArt and HeroCast code. These are world-only fixtures with HUD omitted, not whole-app or Android acceptance. No emulator, APK, profile, arena, run or Git changes were made by this subtask. Parent owns snapshot migration and final integration.
