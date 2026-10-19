extends RefCounted
const ICONS = preload("res://assets/haven-icons.png")
const BASE = preload("res://assets/haven-base.png")
const ACTORS = preload("res://assets/actors.png")
const ENGINEER = preload("res://assets/engineer.png")
const CLASSES = preload("res://assets/class-previews.png")
const HEROES = preload("res://assets/menu-heroes.png")
const ITEMS = preload("res://assets/menu-items.png")
const BACKDROP = preload("res://assets/menu-backdrop.png")
const OUTSKIRTS = preload("res://assets/menu-outskirts.png")
const MOON = preload("res://assets/menu-moon.svg")
const SWORD = preload("res://assets/menu-sword.svg")
const SHIELD = preload("res://assets/menu-shield.svg")
const GEAR_PLINTH = preload("res://assets/gear/stone-plinth.png")
const GEAR_HALO = preload("res://assets/gear/stage-halo.svg")
const CONTACT_SHADOW = preload("res://assets/gear/contact-shadow.svg")
const GEAR_FRAMES = [preload("res://assets/gear/frame-common.svg"), preload("res://assets/gear/frame-uncommon.svg"), preload("res://assets/gear/frame-rare.svg"), preload("res://assets/gear/frame-epic.svg"), preload("res://assets/gear/frame-legendary.svg"), preload("res://assets/gear/frame-mythic.svg")]
const CHROME = {
	"header": preload("res://assets/gear/nav-header.svg"),
	"wallet": preload("res://assets/gear/nav-wallet.svg"),
	"dock": preload("res://assets/gear/nav-dock.svg"),
	"tab": preload("res://assets/gear/nav-tab-rest.svg"),
	"selected": preload("res://assets/gear/nav-tab-active.svg"),
	"pressed": preload("res://assets/gear/nav-tab-pressed.svg"),
	"settings": preload("res://assets/gear/nav-settings.svg")}
const DISPLAY_FONT = preload("res://assets/fonts/LilitaOne-Regular.ttf")
const BODY_FONT = preload("res://assets/fonts/Nunito.ttf")
const ITEM_NAMES := ["weapon", "helmet", "body", "boots", "charm", "gadget", "ring", "pants", "credits", "parts", "gems", "hp"]
const NAMES := ["shop", "gear", "mission", "haven", "class", "ring", "pants", "workshop", "infirmary", "quartermaster", "training", "arcanum"]

static func icon(id: String) -> AtlasTexture:
	var index := maxi(0, NAMES.find(id))
	var cell := Vector2(ICONS.get_width() / 4.0, ICONS.get_height() / 3.0)
	var texture := AtlasTexture.new()
	texture.atlas = ICONS
	texture.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
	if id == "ring":
		texture.region.position.x += 38
		texture.region.size.x -= 46
	return texture

static func hero(id: String) -> Texture2D:
	if id == "arcanist":
		return preload("res://assets/class-showcase/arcanist.png")
	var regions := {"scavenger":Rect2(20,90,490,870), "engineer":Rect2(550,110,400,850), "warden":Rect2(1000,75,520,900)}
	var texture := AtlasTexture.new()
	texture.atlas = preload("res://assets/class-showcase/roster.png")
	texture.region = regions.get(id, regions.scavenger)
	texture.filter_clip = true
	return texture

static func item(id: String) -> AtlasTexture:
	var index := ITEM_NAMES.find(id)
	var cell := Vector2(ITEMS.get_width() / 4.0, ITEMS.get_height() / 3.0)
	var texture := AtlasTexture.new()
	texture.atlas = ITEMS
	texture.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
	return texture

static func pedestal(parent: Node, center: Vector2, width: float) -> void:
	var outline := PackedVector2Array()
	var top := PackedVector2Array()
	for index in 12:
		var angle := TAU * index / 12.0
		var point := Vector2(cos(angle) * width * 0.5, sin(angle) * width * 0.12)
		top.append(center + point)
		outline.append(center + point + Vector2(0, 12))
	for data in [[outline, Color("193c80")], [top, Color("5681b7")]]:
		var polygon := Polygon2D.new()
		polygon.polygon = data[0]
		polygon.color = data[1]
		parent.add_child(polygon)
	var edge := Line2D.new()
	edge.points = top
	edge.closed = true
	edge.width = 1.5
	edge.default_color = Color("a3c3f1")
	parent.add_child(edge)

static func picture(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.texture = texture
	node.position = rect.position
	node.size = rect.size
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func chrome_style(id: String) -> StyleBoxTexture:
	var face := StyleBoxTexture.new()
	face.texture = CHROME[id]
	face.set_texture_margin_all(7 if id in ["tab", "selected", "pressed", "dock"] else 5)
	face.set_content_margin_all(4 if id in ["tab", "selected", "pressed"] else 2)
	return face

static func strong_font() -> FontVariation:
	var font := FontVariation.new()
	font.base_font = BODY_FONT
	font.variation_opentype = {"wght": 800}
	return font
