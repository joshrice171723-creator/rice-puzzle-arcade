# Shrine reward icon atlas

Runtime image: `apps/nightfall-godot/assets/shrine-cards/rewards.png`.

Generated with built-in image generation, original output preserved at `C:/Users/joshr/.codex/generated_images/01a152d8-09a6-7ef1-9334-338ba1d98bf9/exec-454c6f54-49b0-426a-a66d-d69fc44bc3cf.png`. Exact prompt is `PROMPT.txt` in this directory. References `assets/ability-icons.png` and `assets/menu-items.png` were viewed before generation to match Nightfall's painted magic and item materials.

Inspected image: 1254 × 1254 RGBA, alpha range 0–255. Nine distinct readable original icons, no writing or card borders. Palette uses blue, amber, violet, ruby and silver, with no default green. All bodies are readable within a three-by-three arrangement. A few wispy alpha fringes touch the cell boundaries; use nominal cells for consistent presentation, or occupied bounds for enlarged icon placement. Do not infer a gameplay effect from illustration details.

Nominal atlas cells are exactly 418 × 418 pixels. Row-major map:

| ID | Cell rectangle x, y, width, height |
| --- | --- |
| emberleaf | 0, 0, 418, 418 |
| obsidian_heart | 418, 0, 418, 418 |
| storm_feather | 836, 0, 418, 418 |
| wisp_lantern | 0, 418, 418, 418 |
| moonstone | 418, 418, 418, 418 |
| cinder_lens | 836, 418, 418, 418 |
| vitality | 0, 836, 418, 418 |
| steady_aim | 418, 836, 418, 418 |
| long_reach | 836, 836, 418, 418 |

`regions.json` additionally contains per-cell occupied alpha >32 bounding boxes. No image pixels were processed after generation. No source code or Git operations were performed by this task.
