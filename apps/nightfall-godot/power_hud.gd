extends Control
## Compact attack inventory: inspection only, never an attack input.

signal inspect_requested(id: String)
const Content = preload("res://combat_content.gd")
const ORDER := ["ember", "frost", "chain", "wisp", "lance", "ground", "blades", "gravity"]
var slots: Array[Button] = []
var icons: Array[TextureRect] = []
var shades: Array[ColorRect] = []
var ranks: Array[Label] = []
var assigned: Array[String] = ["", "", ""]
var atlas: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists("res://assets/ability-icons.png"):
		atlas = load("res://assets/ability-icons.png")
	for index in 3:
		var button := Button.new()
		button.position = Vector2(index * 58, 0)
		button.size = Vector2(52, 54)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("141c35")
		style.border_color = Color("7a72a7")
		style.set_border_width_all(1)
		style.set_corner_radius_all(7)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("disabled", style)
		button.pressed.connect(func(): inspect_requested.emit(assigned[index]))
		add_child(button)
		slots.append(button)
		var icon := TextureRect.new()
		icon.position = Vector2(4, 0)
		icon.size = Vector2(44, 40)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		icons.append(icon)
		var shade := ColorRect.new()
		shade.color = Color(0.03, 0.04, 0.1, 0.65)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(shade)
		shades.append(shade)
		var rank := Label.new()
		rank.position = Vector2(2, 38)
		rank.size = Vector2(48, 14)
		rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rank.add_theme_font_size_override("font_size", 11)
		rank.add_theme_color_override("font_color", Color("ffd27c"))
		rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(rank)
		ranks.append(rank)
	var info := Button.new()
	info.text = "Powers"
	info.tooltip_text = "Inspect this run's attacks, passives and relics"
	info.position = Vector2(176, 4)
	info.size = Vector2(54, 46)
	info.add_theme_font_size_override("font_size", 12)
	info.pressed.connect(func(): inspect_requested.emit(""))
	add_child(info)

func update_run(run: RefCounted) -> void:
	var ids: Array = run.spells.keys()
	for index in 3:
		var id: String = ids[index] if index < ids.size() else ""
		if assigned[index] != id:
			assigned[index] = id
			icons[index].texture = null
			if atlas and not id.is_empty():
				var cell := Vector2(atlas.get_width() / 4.0, atlas.get_height() / 2.0)
				var texture := AtlasTexture.new()
				texture.atlas = atlas
				var n := ORDER.find(id)
				texture.region = Rect2(Vector2(n % 4, n / 4) * cell, cell)
				icons[index].texture = texture
		slots[index].disabled = id.is_empty()
		slots[index].tooltip_text = "Collect XP to learn an automatic attack" if id.is_empty() else Content.SPELLS[id].name + " • tap to inspect"
		ranks[index].text = "—" if id.is_empty() else ("EVOLVED" if run.spells[id].get("evolved", false) else "◆".repeat(run.spells[id].rank) + "◇".repeat(3 - run.spells[id].rank))
		var fraction := 0.0
		if not id.is_empty() and Content.SPELLS[id].cooldown > 0:
			var cooldown: float = Content.SPELLS[id].cooldown * (1.0 - minf(0.3, 0.06 * run.passive_rank("channel")))
			fraction = clampf(run.spells[id].wait / cooldown, 0, 1)
		shades[index].position = Vector2(3, 3)
		shades[index].size = Vector2(46, 36 * fraction)
		shades[index].visible = fraction > 0

static func describe(arena: Node) -> void:
	var run = arena.run
	arena.modal_title.text = "This expedition's build"
	arena.FieldUI.label(arena, "Attacks fire automatically. Powers below reset when the expedition ends.", 13)
	var tabs := HBoxContainer.new()
	arena.modal_body.add_child(tabs)
	for page in ["Attacks", "Passives", "Relics"]:
		var button: Button = arena.make_button(page, func(): arena.power_page = page; arena.last_screen = "", tabs, 40)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = page == arena.power_page
	if arena.power_page == "Attacks":
		if run.spells.is_empty():
			arena.FieldUI.label(arena, "Collect violet XP. Each level lets you choose an attack or improve your build. You can carry three attacks.")
		for id: String in run.spells:
			var rank: int = run.spells[id].rank
			var evolved: bool = run.spells[id].get("evolved", false)
			var name: String = Content.EVOLUTIONS[id].name if evolved else Content.SPELLS[id].name
			arena.FieldUI.label(arena, "%s • %d/3%s" % [name, rank, " • Evolved" if evolved else ""], 16)
			arena.FieldUI.label(arena, run.spell_offer(id, rank).description.get_slice("\n", 0), 13)
			if not evolved and Content.EVOLUTIONS.has(id):
				var pair: String = Content.EVOLUTIONS[id].pair
				arena.FieldUI.label(arena, "Evolution: rank 3 + " + Content.PASSIVES[pair].name, 12)
	elif arena.power_page == "Passives":
		arena.FieldUI.label(arena, "%d/3 passive slots" % run.passives.size())
		for id: String in run.passives:
			arena.FieldUI.label(arena, "%s • %d/%d" % [Content.PASSIVES[id].name, run.passives[id], Content.PASSIVES[id].max_rank], 16)
			arena.FieldUI.label(arena, Content.PASSIVES[id].description, 13)
		if run.passives.is_empty():
			arena.FieldUI.label(arena, "Passive upgrades appear among your level-up choices.")
	else:
		arena.FieldUI.label(arena, "%d/3 Twinflame relics" % run.field.relics.size())
		for id: String in run.field.relics:
			arena.FieldUI.label(arena, run.Field.RELICS[id].name, 16)
			arena.FieldUI.label(arena, run.Field.RELICS[id].description, 13)
		if run.field.relics.is_empty():
			arena.FieldUI.label(arena, "Hold a Twinflame shrine's ring to choose a relic.")
	arena.make_button("Back", arena.close_power_view, arena.modal_body)
