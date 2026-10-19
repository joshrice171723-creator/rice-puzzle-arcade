extends Control
## Read-only branching progression preview; all choices remain in normal buttons.
const Content = preload("res://combat_content.gd")
const ART = preload("res://assets/ability-icons.png")
const ORDER := ["ember", "frost", "chain", "wisp", "lance", "ground", "blades", "gravity"]
var ability := "ember"
var rank := 0
var branch := ""
var evolved := false

func _init() -> void:
	custom_minimum_size = Vector2(0, 150)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func caption(at: Vector2, value: String, color: Color, font_size: int = 11) -> void:
	var font := ThemeDB.fallback_font
	var width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	draw_string(font, Vector2(clampf(at.x - width / 2, 0, maxf(0, size.x - width)), at.y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func node_at(at: Vector2, active: bool, tint: Color) -> void:
	draw_style_box(panel(Color("2d2849") if active else Color("172139"), tint if active else Color("45516f")), Rect2(at - Vector2(20, 20), Vector2(40, 40)))
	var index := ORDER.find(ability)
	var cell := Vector2(ART.get_width() / 4.0, ART.get_height() / 2.0)
	draw_texture_rect_region(ART, Rect2(at - Vector2(17, 17), Vector2(34, 34)), Rect2(Vector2(index % 4, index / 4) * cell, cell), Color.WHITE if active else Color(0.7, 0.7, 0.8, 0.55))

func panel(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	return style

func _draw() -> void:
	if ability not in Content.BRANCHES:
		return
	var first := Vector2(size.x * 0.12, 67)
	var top := Vector2(size.x * 0.48, 29)
	var bottom := Vector2(size.x * 0.48, 105)
	var last := Vector2(size.x * 0.85, 67)
	var amber := Color("ffd27c")
	var violet := Color("ba92ff")
	var muted := Color("73809d")
	for entry in [["focus", top], ["spread", bottom]]:
		var chosen: bool = branch == entry[0]
		draw_line(first, entry[1], violet if chosen else muted.darkened(0.4), 3)
		draw_line(entry[1], last, amber if chosen and evolved else muted.darkened(0.4), 3)
		node_at(entry[1], chosen, violet)
		caption(entry[1] + Vector2(0, 33), Content.BRANCHES[ability][entry[0]].name, violet if chosen else Color("c0c7d9"))
	node_at(first, rank > 0, amber)
	node_at(last, evolved, amber)
	caption(first + Vector2(0, 34), "Learn • 1", Color("efe7d5"))
	caption(last + Vector2(0, 34), "Evolve • 3", amber if evolved else Color("c0c7d9"))
	caption(Vector2(size.x / 2, 149), "Choose one specialization at rank 2" if branch.is_empty() else "Specialization stays for this expedition", Color("c0c7d9"), 12)
