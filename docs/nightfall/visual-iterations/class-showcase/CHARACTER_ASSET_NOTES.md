# Character asset integration notes

All coordinates are source pixels. Atlas rectangles are x, y, width, height; content bounds in `character-regions.json` are x0, y0, x1, y1 (exclusive).

| Asset | Dimensions | Intended region |
| --- | --- | --- |
| Arcanist | 1024 x 1536 | Full source |
| Scavenger | 1536 x 1024 roster | 20, 90, 490, 870 |
| Engineer | 1536 x 1024 roster | 550, 110, 400, 850 |
| Warden | 1536 x 1024 roster | 1000, 75, 520, 900 |

Use these explicit atlas rectangles rather than equal 512-wide columns: the Warden cloak reaches slightly left of the nominal third cell boundary. Each explicit rectangle contains one complete character with clear margin and no neighboring character.

## Approximate semantic anchors

Arcanist: staff crystal center (190, 173), staff head upper tip (180, 20), open palm center (843, 473), bottom boot plane y1483. Portrait head rectangle (405, 95, 265, 280). The rightmost coat edge is x1018, so keep the complete source aspect rather than filling/cropping a narrow frame.

Scavenger: portrait head rectangle (235, 100, 130, 150); floor y945. Engineer: portrait head rectangle (655, 125, 190, 175); floor y946. Warden: portrait head rectangle (1190, 90, 120, 160); floor y957. These head rectangles include hair and are meant as composition guides for portrait crops.

## Validation

Both final files are RGBA PNG. Alpha extrema are 0 to 254. All four corners are fully alpha 0. Alpha greater than 16 gives Arcanist content bounds (56,18) to (1018,1483), and roster content bounds (36,91) to (1498,957). Samples in the surrounding background and gaps are alpha 0. Generated RGB is retained under transparent pixels; a viewer that ignores alpha may show colored haze, but it does not render in an alpha-composited game.

Assets were inspected visually against the selected Hero Showcase reference. They contain full boots, weapons and head silhouettes with no UI, text or pedestal. The Arcanist preserves the approved purple-haired woman; the roster adapts her rendering style to actual game class names. Movement is provided by the game, not baked frame animation.
