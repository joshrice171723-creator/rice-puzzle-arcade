# Menu V2 raster UI material kit

Generated through built-in imagegen on October 19, 2026. Original Nightfall material kit based on the approved Venture and Class menu references. No code, save, emulator or Git changes.

The original generation is 1254 x 1254 RGBA. The production atlas is 1536 x 1536 RGBA, arranged in nine 512 x 512 cells. Every cell has at least 40px of fully transparent exterior gutter. Components were cropped from the original with six source pixels of padding, uniformly resized and centered; their painted appearance was not redrawn. Source and exact prompt are preserved beside this report.

- Runtime: `apps/nightfall-godot/assets/polish-v2/ui-kit.png`
- Original: [ui-kit-source.png](ui-kit-source.png)
- Exact prompt: [UI_KIT_PROMPT.txt](UI_KIT_PROMPT.txt)
- Machine-readable bounds: [ui-kit-atlas.json](ui-kit-atlas.json)
- Transparency checks: [light preview](ui-kit-light-preview.jpg), [dark preview](ui-kit-dark-preview.jpg)

All regions below use `[x, y, width, height]` in runtime atlas pixels. Bounds include transparent sampling padding; use these regions for AtlasTexture. Slice values are `[left, top, right, bottom]` measured in source region pixels. Circular medallions must scale uniformly.

| Element | Atlas region | Initial slice insets |
|---|---|---|
| blue_panel | `[46, 98, 420, 315]` | `[60, 60, 60, 60]` |
| lavender_inset | `[558, 95, 420, 322]` | `[60, 60, 60, 60]` |
| gold_button | `[1095, 171, 370, 170]` | `[56, 40, 56, 40]` |
| blue_button | `[71, 683, 370, 170]` | `[56, 40, 56, 40]` |
| violet_button | `[583, 683, 369, 170]` | `[56, 40, 56, 40]` |
| disabled_button | `[1098, 683, 364, 170]` | `[56, 40, 56, 40]` |
| blue_medallion | `[96, 1122, 320, 316]` | `None` |
| gold_medallion | `[608, 1122, 320, 316]` | `None` |
| title_ribbon | `[1070, 1197, 420, 166]` | `[82, 40, 82, 40]` |

Insets protect the painted corner radii. For Godot StyleBoxTexture at phone scale, downsample the extracted panel/button texture and its insets together before using it as a theme style; high-resolution source-pixel margins directly used as destination margins would produce oversized borders. For example, a panel normalized from 420px wide to 126px uses 18px corner margins instead of 60px. Retain the original atlas for high-resolution direct draws. Button centers and panel centers are intentionally plain so stretching does not distort symbols or text.

Visual inspection: all nine requested elements present, no baked text/numbers/icons, no missing components, genuine transparent exterior. Rich illustrated bevels/glints match the requested glossy raster direction, with greater metal-like sheen than the approved screenshots. Treat as production assets awaiting integrated visual review, not completion evidence for the menus. Only the raster source/atlas/metadata were delivered; no mockup or runtime integration was substituted for the asset request.
