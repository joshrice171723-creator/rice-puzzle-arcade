extends RefCounted
## Shared painted materials and typography for the out-of-combat interface.
const Art = preload("res://haven_art.gd")
const ATLAS = preload("res://assets/polish-v2/ui-kit.png")
const CONTROLS = preload("res://assets/class-showcase/controls.png")
const PANELS = {"panel": preload("res://assets/class-showcase/panel-main.png"), "inset": preload("res://assets/class-showcase/panel-inset.png")}
const CONTROL_REGIONS = {"blue": Rect2i(40,219,559,142), "gold": Rect2i(657,219,560,142), "ribbon": Rect2i(627,836,606,123)}
const DISPLAY = preload("res://assets/fonts/LilitaOne-Regular.ttf")
const BODY = preload("res://assets/fonts/Nunito.ttf")
const REGIONS = {
	"panel": Rect2i(46,98,420,315), "inset": Rect2i(558,95,420,322),
	"gold": Rect2i(1095,171,370,170), "blue": Rect2i(71,683,370,170),
	"violet": Rect2i(583,683,369,170), "disabled": Rect2i(1098,683,364,170),
	"medallion": Rect2i(96,1122,320,316), "selected": Rect2i(608,1122,320,316),
	"ribbon": Rect2i(1070,1197,420,166)}
static var textures: Dictionary = {}

static func texture(kind: String) -> Texture2D:
	if textures.has(kind):
		return textures[kind]
	var source_kind := "blue" if kind in ["violet", "disabled"] else kind
	var modern := CONTROL_REGIONS.has(source_kind)
	var region: Rect2i = CONTROL_REGIONS[source_kind] if modern else REGIONS.get(kind, REGIONS.panel)
	var pixels: Image = PANELS[kind].get_image() if PANELS.has(kind) else (CONTROLS if modern else ATLAS).get_image().get_region(region)
	var width := 256 if modern else 128
	pixels.resize(width, roundi(pixels.get_height() * float(width) / pixels.get_width()), Image.INTERPOLATE_LANCZOS)
	var result := ImageTexture.create_from_image(pixels)
	textures[kind] = result
	return result

static func surface(kind: String = "panel") -> StyleBoxTexture:
	var face := StyleBoxTexture.new()
	face.texture = texture(kind)
	face.set_texture_margin_all(12 if kind == "panel" else (7 if kind == "inset" else 14))
	face.set_content_margin_all(9)
	if kind == "disabled":
		face.modulate_color = Color("7a8ca6")
	return face

static func panel(parent: Node, kind: String = "panel", padding: int = 10) -> VBoxContainer:
	var shell := PanelContainer.new()
	shell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var face := surface(kind)
	face.set_content_margin_all(maxi(14, padding))
	shell.add_theme_stylebox_override("panel", face)
	parent.add_child(shell)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 5)
	shell.add_child(column)
	return column

static func label(parent: Node, text: String, size: int = 16, color: Color = Color("edf4ff"), center: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.autowrap_mode = TextServer.AUTOWRAP_OFF if parent is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_override("font", DISPLAY if size >= 20 else body_font())
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	if size >= 20:
		node.add_theme_color_override("font_outline_color", Color("122654"))
		node.add_theme_constant_override("outline_size", 4)
		node.add_theme_constant_override("shadow_offset_y", 2)
		node.add_theme_color_override("font_shadow_color", Color("10234a"))
	if center:
		node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func body_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = BODY
	font.variation_opentype = {"wght": 750}
	font.variation_embolden = 1.0
	return font

static func icon(parent: Node, image: Texture2D, size: Vector2 = Vector2(40,40)) -> TextureRect:
	var node := TextureRect.new()
	node.texture = image
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func action(button: Button, kind: String = "blue") -> void:
	var normal := surface(kind)
	normal.set_content_margin_all(5)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.modulate_color = Color(1.12,1.12,1.12)
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.modulate_color = Color("a8bcdf")
	button.add_theme_stylebox_override("pressed", pressed)
	var disabled := surface("disabled")
	disabled.set_content_margin_all(5)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_override("font", DISPLAY)
	button.add_theme_font_size_override("font_size", 18)
	button.add_theme_color_override("font_color", Color("fff9e9"))
	button.add_theme_color_override("font_outline_color", Color("24335a"))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_color_override("font_disabled_color", Color("b4bfd5"))
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color("ffe8a0")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(4)
	button.add_theme_stylebox_override("focus", focus)

static func progress(bar: ProgressBar) -> void:
	bar.show_percentage = false
	var background := StyleBoxFlat.new()
	background.bg_color = Color("142e61")
	background.border_color = Color("6f96ce")
	background.set_border_width_all(1)
	background.set_corner_radius_all(4)
	bar.add_theme_stylebox_override("background", background)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("eeb950")
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)

static func cost_row(parent: Node, profile: RefCounted, cost: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)
	for currency in ["credits", "parts", "gems", "cache_keys"]:
		if not cost.has(currency):
			continue
		var group := HBoxContainer.new()
		group.add_theme_constant_override("separation", 3)
		row.add_child(group)
		var image: Texture2D
		if currency == "cache_keys":
			var atlas := AtlasTexture.new()
			atlas.atlas = preload("res://assets/equipment-icons.png")
			var cell := Vector2(atlas.atlas.get_width()/4.0, atlas.atlas.get_height()/2.0)
			atlas.region = Rect2(Vector2(3,1)*cell, cell)
			image = atlas
		else:
			image = Art.item(currency)
		icon(group, image, Vector2(23,25))
		var amount := label(group, str(cost[currency]), 15, Color("ffe4a4") if int(profile.data.get(currency,0)) >= int(cost[currency]) else Color("ffb5bd"))
		amount.autowrap_mode = TextServer.AUTOWRAP_OFF
		amount.tooltip_text = "%s owned: %s" % [currency.replace("_", " ").capitalize(), profile.data.get(currency,0)]
	return row
