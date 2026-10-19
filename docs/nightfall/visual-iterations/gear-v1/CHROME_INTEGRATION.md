# Shared header and dock material handoff

October 19, 2026. Bounded presentation-only asset pass. `haven_ui.gd` and `item_detail_ui.gd` were not edited by this pass. No save, emulator, gameplay or Git changes.

Seven original SVG assets in `apps/nightfall-godot/assets/gear/nav-*.svg` provide the header surface, currency tray, continuous dock, resting/active/pressed tab surfaces and settings face. Existing illustrated tab and currency icons remain the artwork. Midnight enamel, thin cool metal highlights, violet ambient light and an amber active underline match the Gear materials. The active tab keeps a clear word label and material/underline difference.

`haven_art.gd` adds `CHROME`, `chrome_style(id)` and `strong_font()`. The font helper emboldens the existing licensed Barlow Semi Condensed font without introducing another font dependency. Existing sizes can remain unchanged.

Parent integration is now complete in haven_ui.gd; the snippets below record the applied wiring. Final screenshots use that source implementation.

## Parent integration in haven_ui.gd

Immediately after creating the full-screen backdrop and before creating the moon/logo:

```gdscript
Art.picture(self, Art.CHROME.header, Rect2(0, 0, 430, 58))
```

Immediately before adding `navigation` to `self`:

```gdscript
Art.picture(self, Art.CHROME.dock, Rect2(8, 690, 414, 68))
```

Keep the existing navigation coordinates, five tab ordering and callbacks. During tab construction add:

```gdscript
tab.add_theme_font_override("font", Art.strong_font())
tab.add_theme_stylebox_override("pressed", Art.chrome_style("pressed"))
```

In `rebuild()`, replace the old flat `tab_style` block with:

```gdscript
tab.add_theme_stylebox_override("normal", Art.chrome_style("selected" if selected else "tab"))
tab.add_theme_stylebox_override("hover", Art.chrome_style("selected"))
tab.add_theme_stylebox_override("pressed", Art.chrome_style("pressed"))
```

Keep the existing selected label color and `tab.disabled` behavior. Retain the existing 13px tab label, 43px icon maximum, content geometry and hit areas to preserve layout. Existing focus behavior may remain, or use a quiet amber focus outline that follows the tab's cut corners.

For settings, replace its normal face and keep the existing icon/callback:

```gdscript
settings.add_theme_stylebox_override("normal", Art.chrome_style("settings"))
settings.add_theme_stylebox_override("hover", Art.chrome_style("settings"))
settings.add_theme_stylebox_override("pressed", Art.chrome_style("pressed"))
```

In the wallet rebuild loop, replace the old flat chip style creation/assignment with:

```gdscript
chip.add_theme_stylebox_override("panel", Art.chrome_style("wallet"))
```

After creating each amount label:

```gdscript
amount.add_theme_font_override("font", Art.strong_font())
```

Currency icons, amounts, accessible tooltips, compact number formatting and callbacks stay as currently implemented.

## Evidence and limits

Godot 4.7.2 imported all seven SVG assets and compiled the Art helper without script errors. A temporary graphics-backed runtime harness applied the proposed material overrides to the actual Gear nodes, using `arena.testing = true`. It produced these unaltered viewport outputs:

- [430×760 trial integration](chrome-preview-430x760.png)
- [320×568 trial integration](chrome-preview-320x568.png)

These are actual runtime trial styling, not a generated mockup and not proof that the parent has applied the final code. The trial includes the header, dock, currency trays and stronger labels. Settings state styling remains part of the parent integration. Final interaction/layout checks and native evidence belong to the parent after integration. No new image generation was needed.
