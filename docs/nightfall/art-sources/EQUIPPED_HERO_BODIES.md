# Equipped character bodies — October 19, 2026

The live combat renderer now uses one empty-handed body per class, continuously deformed by the existing weighted mesh. A separate held weapon follows the deformed hand. These are four different characters in one atlas, not four animation frames. They are not rigged 3D models, and equipped armor does not yet change the costume.

- Committed asset: `apps/nightfall-godot/assets/hero-cast/equipment-bodies.png` (1774 × 887 RGBA).
- Tool: built-in image generation, transparent background enabled, reference-image editing.
- Selected source: `C:/Users/joshr/.codex/generated_images/01a14d17-a754-75d2-b2d5-d0fc040447c7/exec-df657623-7b15-4f97-bc6c-fc40ee7527ea.png`.
- First candidate: `exec-ad123c36-2d92-43b7-ae16-0ac2af59023d.png` in the same directory. The second pass increases separation between the characters.
- References: existing Nightfall `hero-cast/scavenger-casting.png`, `engineer.png`, and `class-previews.png`. No external game's art was used as generation input.
- The selected PNG is copied unchanged. Godot source rectangles select each character; no raster repainting, background removal or frame synthesis was performed outside the image tool. Import uses mipmaps and a 2048-pixel limit.

## Generation directions

Create a production transparent character-body atlas for Nightfall using the supplied project characters as identity and style references. Four full-body characters in a horizontal row: Scavenger, Engineer, Warden and Arcanist. Preserve the approved painterly fantasy game style, blue and violet clothing, brass/gold armor, white scarf and readable compact silhouettes. Neutral three-quarter stance facing right, consistent camera, light and scale. Hands must be empty so equipment can be attached separately in the engine. No weapons, magic, effects, text, borders, UI, floor or baked shadow. Each character needs generous transparent space around the entire silhouette. This is four distinct class bodies, not an animation sequence.

Revision direction: preserve those four characters and the rendering style, but increase the transparent gutters so each silhouette can be cropped independently. Keep empty hands, full feet and consistent character height. Do not introduce a held weapon or effects.

## Runtime regions and anchors

| Class | Source rectangle x, y, width, height | Local hand UV |
|---|---|---|
| Scavenger | 20, 110, 415, 720 | 0.92, 0.55 |
| Engineer | 460, 110, 410, 720 | 0.90, 0.55 |
| Warden | 870, 65, 460, 790 | 0.86, 0.57 |
| Arcanist | 1345, 115, 429, 735 | 0.88, 0.59 |

`hero_cast.gd` deforms each hand using the same rig as its body. `equipped_weapon_art.gd` aligns the artwork's grip with that hand and its barrel/blade axis with aim. A spell gesture and a simultaneous weapon shot keep separate directions and timings. The muzzle flash follows the transformed weapon tip. Pistol, scattergun, crossbow, wand and sabre share the same attachment path for all classes.

Graphical inspection covers all twenty class/weapon combinations, right and left facing, at `artifacts/nightfall-godot/completion-pass/equipped-weapons-{right,left}.png`. The fixture also checks grip anchoring through recoil/swing, directional alignment, continuous visible motion and concurrent spell/weapon aim.

The Gear screen uses `gear_actor.gd` to render this same body and actual equipped weapon over its existing showcase plinth. Idle movement is limited to 30 redraws per second, stops while hidden, and is disabled by Reduced Effects. Class retains its approved separate hero showcase. Gear captures cover all five weapon families in `completion-pass/gear/`.
