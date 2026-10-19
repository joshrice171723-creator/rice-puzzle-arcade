extends Control

signal mission_requested(mission: int)
signal resume_requested
signal abandon_requested
signal practice_requested(mission: int, build: String)
signal diagnostics_requested
signal contract_requested(slot: String)

const Art = preload("res://haven_art.gd")
const ShopReward = preload("res://shop_reward.gd")
const TABS := [["shop", "Shop"], ["gear", "Gear"], ["mission", "Expedition"], ["haven", "Base"], ["class", "Class"]]
const ZONES := ["Blackout Outskirts", "Freight Yard", "Silent Suburbs", "Flooded Market", "Ironworks", "Orchard County", "Coldwater Docks", "Whiteout Village", "Dead Signal", "Buried Transit", "Ashfall Quarry", "Quarantine Ward", "Glasshouse Labs", "Rustwater Refinery", "Rooftop District", "Broken Reservoir", "Hollow Bunker", "Storm Coast", "Nightfall Core", "Last Beacon"]
signal shop_video_requested(token: String)
signal shop_video_cancelled(token: String)
var shop_flow = ShopReward.new()
var ads_available := false
var facility := "workshop"
var inspected_class := ""
var inventory_scroll := 0
var inventory_sort := "Rarity"
var filter_slot := ""
var filter_rarity := ""
var filter_locked := false
var build_slot := "1"
var build_name := ""

const Content = preload("res://haven_content.gd")
const LootUI = preload("res://loot_ui.gd")
const Preparation = preload("res://preparation_ui.gd")
const Armory = preload("res://armory_ui.gd")
const SkillTreeUI = preload("res://skill_tree_ui.gd")
const EquipmentWorkshop = preload("res://equipment_workshop_ui.gd")
var merge_donors: Array = []
var selected_affix := ""
var tree_ability := ""
const ACTORS = preload("res://assets/actors.png")
const FLOOR = preload("res://assets/courtyard.png")
const EQUIPMENT_ART = preload("res://assets/equipment-icons.png")
var profile: RefCounted
var page := "mission"
var mission := 1
var selected_item := -1
var confirmation := ""
var message := ""
var body: VBoxContainer
var frame_panel: PanelContainer
var wallet: HBoxContainer
var title: Label
var navigation: HBoxContainer
var status_label: Label
var cache_receipt := false
var contract_slot := "weapon"
var training_mission := 1
var training_build := "Balanced"
var guide_index := 0

func _ready() -> void:
	# Godot Buttons need mouse emulation for native touch. Scope it to home
	# so the existing combat joystick continues to receive its original events.
	Input.emulate_mouse_from_touch = visible
	visibility_changed.connect(func(): Input.emulate_mouse_from_touch = visible)
	size = Vector2(430, 760)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Theme.new()
	theme.default_font = Art.BODY_FONT
	theme.default_font_size = 16
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var background := Art.picture(self, Art.BACKDROP, Rect2(Vector2.ZERO, size))
	background.stretch_mode = TextureRect.STRETCH_SCALE
	Art.picture(self, Art.MOON, Rect2(12, 14, 29, 34))
	var heading := Label.new()
	heading.text = "Nightfall"
	heading.position = Vector2(44, 18)
	heading.add_theme_font_override("font", Art.DISPLAY_FONT)
	heading.add_theme_font_size_override("font_size", 21)
	heading.add_theme_color_override("font_color", Color("e6efff"))
	heading.add_theme_color_override("font_shadow_color", Color("203586"))
	heading.add_theme_constant_override("shadow_offset_y", 2)
	add_child(heading)
	var settings := button("", func(): navigate("settings"), self, 36)
	settings.position = Vector2(385, 14)
	settings.size.x = 33
	settings.icon = Art.item("parts")
	settings.expand_icon = true
	settings.add_theme_constant_override("icon_max_width", 24)
	settings.tooltip_text = "Settings"
	wallet = HBoxContainer.new()
	wallet.position = Vector2(168, 15)
	wallet.size = Vector2(211, 34)
	wallet.add_theme_constant_override("separation", 3)
	add_child(wallet)
	var panel := PanelContainer.new()
	frame_panel = panel
	panel.position = Vector2(14, 80)
	panel.size = Vector2(402, 578)
	var panel_style := style(Color(0.02, 0.12, 0.35, 0.24), Color(0.30, 0.56, 0.95, 0.35))
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 7)
	panel.add_child(body)
	status_label = Label.new()
	status_label.position = Vector2(18, 659)
	status_label.size = Vector2(394, 31)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.max_lines_visible = 2
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color("ffd27c"))
	add_child(status_label)
	navigation = HBoxContainer.new()
	navigation.position = Vector2(10, 692)
	navigation.size = Vector2(410, 64)
	navigation.add_theme_constant_override("separation", 2)
	add_child(navigation)
	for entry in TABS:
		var tab := button(entry[1], func(): navigate(entry[0]), navigation, 64)
		tab.name = entry[0]
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 13)
		tab.icon = Art.icon(entry[0])
		tab.expand_icon = true
		tab.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tab.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		tab.add_theme_constant_override("icon_max_width", 43)
		tab.add_theme_constant_override("h_separation", 2)
	rebuild()

func navigate(destination: String) -> void:
	if not shop_flow.pending.is_empty():
		message = "Finish or cancel the current video request first."
		status_label.text = message
		return
	page = destination
	selected_item = -1
	confirmation = ""
	message = ""
	rebuild()

func active_tab() -> String:
	if page in ["cache", "rare_choice", "shop"]:
		return "shop"
	if page in ["mission", "rewards", "contracts", "zones"]:
		return "mission"
	if page in ["class", "mastery", "skills"]:
		return "class"
	return "gear" if page in ["gear", "builds", "filters", "merge", "substats", "sets"] else "haven"

func request_shop_video() -> void:
	if not ads_available:
		message = "Videos are available in the Android build when connected."
		rebuild()
		return
	var token: String = shop_flow.begin(profile)
	if token.is_empty():
		return
	rebuild()
	shop_video_requested.emit(token)

func shop_earned(token: String) -> void:
	if token != shop_flow.pending:
		return
	shop_flow.reward(token, profile)
	message = shop_flow.message
	rebuild()

func shop_finished(token: String) -> void:
	if shop_flow.finish(token):
		message = shop_flow.message
		rebuild()

func shop_failed(token: String, reason: String) -> void:
	if shop_flow.fail(token, reason):
		message = shop_flow.message
		rebuild()

func icon_button(label: String, art_id: String, action: Callable, parent: Node, height: int = 68) -> Button:
	var node := button(label, action, parent, height)
	node.icon = Art.icon(art_id)
	node.expand_icon = true
	node.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	node.add_theme_constant_override("icon_max_width", 60)
	node.add_theme_font_size_override("font_size", 14)
	var face := style(Color("082c60"), Color("468ed5"))
	face.set_content_margin_all(3)
	node.add_theme_stylebox_override("normal", face)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

func style(fill: Color, border: Color = Color("428ee0")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(5)
	box.set_content_margin_all(8)
	return box

func button(text_value: String, action: Callable, parent: Node = null, height: int = 44) -> Button:
	var node := Button.new()
	node.text = text_value
	node.clip_text = true
	node.tooltip_text = text_value
	node.custom_minimum_size.y = height
	node.add_theme_font_size_override("font_size", 15)
	node.add_theme_color_override("font_color", Color("f5e9d8"))
	node.add_theme_stylebox_override("normal", style(Color("123b79")))
	node.add_theme_stylebox_override("hover", style(Color("2259a4"), Color("ffd27c")))
	node.add_theme_stylebox_override("pressed", style(Color("453084"), Color("ba92ff")))
	node.pressed.connect(action)
	(parent if parent != null else body).add_child(node)
	return node

func text_line(value: String, font_size: int = 14, color: Color = Color("d6daea")) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	if font_size >= 21:
		node.add_theme_font_override("font", Art.DISPLAY_FONT)
		node.add_theme_color_override("font_color", Color("f3f5ff"))
		node.add_theme_color_override("font_shadow_color", Color("102451"))
		node.add_theme_constant_override("shadow_offset_y", 2)
	body.add_child(node)
	return node

func item_texture(slot: String) -> AtlasTexture:
	if slot in Art.ITEM_NAMES:
		return Art.item(slot)
	var index: int = ["weapon", "helmet", "body", "boots", "charm", "gadget", "chest", "key"].find(slot)
	var cell := Vector2(EQUIPMENT_ART.get_width() / 4.0, EQUIPMENT_ART.get_height() / 2.0)
	var texture := AtlasTexture.new()
	texture.atlas = EQUIPMENT_ART
	texture.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
	return texture

func decorate_item_button(node: Button, slot: String) -> void:
	node.icon = item_texture(slot)
	node.expand_icon = true
	node.add_theme_constant_override("icon_max_width", 44)
	node.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT

func item_portrait(slot: String, height: float = 84) -> void:
	var portrait := TextureRect.new()
	portrait.texture = item_texture(slot)
	portrait.custom_minimum_size.y = height
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	body.add_child(portrait)

func refresh(action: Callable, success: String) -> void:
	message = success if action.call() else (profile.error if not profile.error.is_empty() else "Not enough resources, or this upgrade is already complete.")
	confirmation = ""
	rebuild()

func rebuild() -> void:
	if not is_inside_tree():
		return
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	frame_panel.size = Vector2(402, 578)
	for child in wallet.get_children():
		wallet.remove_child(child)
		child.queue_free()
	for currency in ["credits", "parts", "gems"]:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(68, 34)
		var chip_style := style(Color("061e4c"), Color("285294"))
		chip_style.set_content_margin_all(2)
		chip.add_theme_stylebox_override("panel", chip_style)
		chip.tooltip_text = "%s: %d" % [currency.capitalize(), profile.data[currency]]
		wallet.add_child(chip)
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 1)
		chip.add_child(row)
		var icon := Art.picture(row, Art.item(currency), Rect2(0, 0, 25, 28))
		icon.custom_minimum_size = Vector2(25, 28)
		var amount := Label.new()
		amount.name = currency.capitalize() + "Amount"
		var value: int = profile.data[currency]
		amount.text = compact_amount(value)
		amount.add_theme_font_size_override("font_size", 17)
		row.add_child(amount)
	match page:
		"mission": mission_page()
		"zones": zones_page()
		"shop": shop_page()
		"facility": facility_page()
		"gear": gear_page()
		"builds": Armory.builds(self)
		"filters": Armory.filters(self)
		"merge": EquipmentWorkshop.merge(self)
		"substats": EquipmentWorkshop.substats(self)
		"sets": EquipmentWorkshop.sets(self)
		"haven": haven_page()
		"class": class_page()
		"skills": SkillTreeUI.show_tree(self)
		"settings": settings_page()
		"cache": LootUI.show(self)
		"rewards": LootUI.mission_rewards(self)
		"rare_choice": LootUI.rare_choice(self)
		"contracts": contracts_page()
		"training": Preparation.training(self)
		"arcanum": Preparation.arcanum(self)
		"mastery": Preparation.mastery(self)
	status_label.text = profile.error if not profile.error.is_empty() else message
	if status_label.text.is_empty() and not profile.can_change_loadout() and page in ["gear", "builds", "merge", "substats", "class", "skills", "facility", "cache", "rare_choice"]:
		status_label.text = "Finish your saved expedition to change equipment or upgrades."
	for index in navigation.get_child_count():
		var tab: Button = navigation.get_child(index)
		tab.disabled = not shop_flow.pending.is_empty()
		var selected: bool = TABS[index][0] == active_tab()
		var tab_style := style(Color("394990") if selected else Color("072451"))
		tab_style.set_content_margin_all(4)
		tab_style.border_color = Color("ffcd4f") if selected else Color("3068b2")
		tab_style.border_width_bottom = 3 if selected else 1
		tab.add_theme_stylebox_override("normal", tab_style)
		tab.add_theme_color_override("font_color", Color("ffd27c") if TABS[index][0] == active_tab() else Color("d6daea"))
	queue_redraw()

func compact_amount(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 10000:
		return "%.0fK" % (value / 1000.0)
	return str(value)

func mission_page() -> void:
	var top := HBoxContainer.new()
	body.add_child(top)
	var heading := Label.new()
	heading.text = "Blackout Outskirts"
	heading.add_theme_font_size_override("font_size", 20)
	heading.add_theme_font_override("font", Art.DISPLAY_FONT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	var zones := button("Zones", func(): page = "zones"; rebuild(), top, 36)
	zones.custom_minimum_size.x = 62
	zones.add_theme_font_size_override("font_size", 12)
	var stage := Control.new()
	stage.custom_minimum_size.y = 221
	body.add_child(stage)
	Art.picture(stage, Art.OUTSKIRTS, Rect2(20, -5, 346, 226))
	text_line("Zone 1 · %d / 15 mastery medals" % profile.total_medals(), 13, Color("ba92ff"))
	var nodes := HBoxContainer.new()
	nodes.add_theme_constant_override("separation", 5)
	body.add_child(nodes)
	for number in range(1, 6):
		var medals: Array = profile.data.missions.get(str(number), [])
		var node := button(str(number) + (" ◆" if "clear" in medals else ""), func(): mission = number; rebuild(), nodes, 44)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.add_theme_color_override("font_color", Color("ffd27c") if number == mission else Color("b8c5df"))
		node.tooltip_text = Content.MISSIONS[number - 1].name
	var definition: Dictionary = Content.MISSIONS[mission - 1]
	text_line("%d. %s" % [mission, definition.name], 21)
	text_line("4 min survival · Defeat %s" % definition.boss, 13)
	button("Rewards & mastery", func(): page = "rewards"; rebuild(), null, 32)
	if not profile.data.active_attempt.is_empty():
		button("Resume expedition", func(): resume_requested.emit())
		button("End expedition", func():
			if confirmation == "abandon":
				abandon_requested.emit()
			else:
				confirmation = "abandon"; message = "Tap End expedition again. Only protected loot returns."; rebuild(), null, 36)
	else:
		var unlocked: bool = profile.mission_unlocked(mission)
		var start := button("Start expedition" if unlocked else "Clear the previous mission", func(): mission_requested.emit(mission), null, 48)
		start.add_theme_stylebox_override("normal", style(Color("ffbe32"), Color("ffe38d")))
		start.add_theme_color_override("font_color", Color("33244b"))
		start.disabled = not unlocked or profile.blocked
		var modes := HBoxContainer.new()
		body.add_child(modes)
		button("Salvage contracts", func(): page = "contracts"; rebuild(), modes, 38).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button("Boss training", func(): page = "training"; rebuild(), modes, 38).size_flags_horizontal = Control.SIZE_EXPAND_FILL

func zones_page() -> void:
	text_line("Expedition zones", 24)
	text_line("Blackout Outskirts is playable. Later zones are planned.", 13)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 4)
	body.add_child(grid)
	for index in ZONES.size():
		var node := button("%02d  %s" % [index + 1, ZONES[index]], func(): page = "mission"; rebuild(), grid, 44)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.add_theme_font_size_override("font_size", 11)
		node.disabled = index > 0

func gear_page() -> void:
	if selected_item >= 0:
		item_page()
		return
	var heading_row := HBoxContainer.new()
	body.add_child(heading_row)
	var heading := Label.new()
	heading.text = "Equipment"
	heading.add_theme_font_size_override("font_size", 24)
	heading.add_theme_font_override("font", Art.DISPLAY_FONT)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading_row.add_child(heading)
	button("Sets", func(): navigate("sets"), heading_row, 32).custom_minimum_size.x = 54
	button("Builds", func(): Armory.pick_build(self, build_slot), heading_row, 32).custom_minimum_size.x = 70
	var stage := Control.new()
	stage.custom_minimum_size.y = 254
	body.add_child(stage)
	Art.pedestal(stage, Vector2(193, 236), 209)
	Art.picture(stage, Art.hero(profile.data["class"]), Rect2(77, -8, 232, 253))
	var columns := [["weapon", "ring", "charm", "gadget"], ["helmet", "body", "pants", "boots"]]
	for column in 2:
		for index in 4:
			var slot: String = columns[column][index]
			var item: Dictionary = profile.item_by_id(profile.data.equipment[slot])
			var tile := equipment_tile(item, stage, Vector2(68, 59))
			tile.position = Vector2(4 if column == 0 else 312, index * 64)
	var stats: Dictionary = profile.stats()
	var stats_row := HBoxContainer.new()
	stats_row.custom_minimum_size.y = 36
	body.add_child(stats_row)
	for entry in [["Power", stats.power, Art.SWORD], ["HP", stats.hp, Art.item("hp")], ["Armor", stats.armor, Art.SHIELD]]:
		var card := HBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = entry[0]
		stats_row.add_child(card)
		var icon := Art.picture(card, entry[2], Rect2(0, 0, 30, 32))
		icon.custom_minimum_size = Vector2(30, 32)
		var amount := Label.new()
		amount.text = "%.0f" % entry[1]
		amount.add_theme_font_size_override("font_size", 25)
		card.add_child(amount)
	var bar := HBoxContainer.new()
	body.add_child(bar)
	var label := Label.new()
	var items: Array = Armory.filtered_items(self)
	label.text = "Inventory · %d" % items.size()
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	bar.add_child(label)
	var filtered := not filter_slot.is_empty() or not filter_rarity.is_empty() or filter_locked
	var filter_button := button("Filter *" if filtered else "Filter", func(): navigate("filters"), bar, 36)
	filter_button.add_theme_font_size_override("font_size", 12)
	filter_button.custom_minimum_size.x = 62
	var sort_button := button("Sort: " + inventory_sort, func():
		inventory_sort = "Slot" if inventory_sort == "Rarity" else "Rarity"
		inventory_scroll = 0
		rebuild(), bar, 36)
	sort_button.add_theme_font_size_override("font_size", 12)
	sort_button.custom_minimum_size.x = 100
	var scroll := ScrollContainer.new()
	scroll.name = "InventoryScroll"
	scroll.custom_minimum_size.y = 166
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.add_child(scroll)
	var grid := GridContainer.new()
	grid.name = "InventoryGrid"
	grid.columns = 5
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	scroll.add_child(grid)
	items.sort_custom(func(a: Dictionary, b: Dictionary):
		var left: int = Content.RARITIES.find(a.rarity) if inventory_sort == "Rarity" else Content.SLOTS.find(a.slot)
		var right: int = Content.RARITIES.find(b.rarity) if inventory_sort == "Rarity" else Content.SLOTS.find(b.slot)
		return a.id < b.id if left == right else (left > right if inventory_sort == "Rarity" else left < right))
	for item in items:
		equipment_tile(item, grid, Vector2(66, 65)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if items.is_empty():
		var empty := Label.new()
		empty.text = "No matches. Change Filter."
		empty.add_theme_font_size_override("font_size", 14)
		grid.add_child(empty)
	scroll.set_deferred("scroll_vertical", inventory_scroll)
	scroll.get_v_scroll_bar().value_changed.connect(func(value: float): inventory_scroll = int(value))

func equipment_tile(item: Dictionary, parent: Node, dimensions: Vector2) -> Button:
	var tile := button("", func(): selected_item = item.id; message = ""; rebuild(), parent, int(dimensions.y))
	tile.custom_minimum_size = dimensions
	tile.size = dimensions
	tile.name = "Item%d" % item.id
	tile.tooltip_text = "%s · %s · Level %d" % [item.name, Content.SLOT_LABELS[item.slot], item.level]
	var rank: int = Content.RARITIES.find(item.rarity)
	var color := Color(["73adf4", "55c4ee", "707aff", "bc66ff", "ffbd48", "ff668d"][rank])
	var box := style(Color(["163c82", "104a77", "28369c", "50239e", "794817", "78294e"][rank]), color)
	box.set_border_width_all(2)
	box.set_corner_radius_all(6)
	box.shadow_color = Color(color, 0.18)
	box.shadow_size = 2
	box.set_content_margin_all(2)
	tile.add_theme_stylebox_override("normal", box)
	tile.icon = item_texture(item.slot)
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_theme_constant_override("icon_max_width", 57)
	var caption := Label.new()
	caption.text = ("◆ " if profile.data.equipment[item.slot] == item.id else "") + "Lv.%d" % item.level
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_outline_color", Color("0a1020"))
	caption.add_theme_constant_override("outline_size", 3)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.position = Vector2(4, dimensions.y - 16)
	caption.size = Vector2(dimensions.x - 8, 15)
	tile.add_child(caption)
	if item.id in profile.data.locked_items:
		var lock_label := Label.new()
		lock_label.text = "LOCK"
		lock_label.position = Vector2(3, 1)
		lock_label.add_theme_font_size_override("font_size", 10)
		lock_label.add_theme_color_override("font_color", Color("ffd27c"))
		lock_label.add_theme_color_override("font_outline_color", Color("0a1020"))
		lock_label.add_theme_constant_override("outline_size", 3)
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lock_label)
	return tile

func item_page() -> void:
	var item: Dictionary = profile.item_by_id(selected_item)
	if item.is_empty():
		selected_item = -1
		gear_page()
		return
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	body.add_child(header)
	var icon := TextureRect.new()
	icon.texture = item_texture(item.slot)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(icon)
	var name_label := Label.new()
	name_label.text = item.name
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color(Content.RARITY_COLORS[Content.RARITIES.find(item.rarity)]))
	header.add_child(name_label)
	text_line("%s %s  •  Level %d/5" % [item.rarity.capitalize(), item.slot.capitalize(), item.level])
	var stats: Dictionary = Content.item_stats(item)
	text_line("Power %.1f   HP %.0f   Armor %.1f" % [stats.power, stats.hp, stats.armor], 16)
	for affix in item.get("affixes", []):
		text_line(Content.affix_text(item, affix), 12, Color("ba92ff"))
	if profile.data.equipment[item.slot] != item.id:
		var current: Dictionary = Content.item_stats(profile.item_by_id(profile.data.equipment[item.slot]))
		text_line("Compared with equipped: Power %+.1f / HP %+.0f / Armor %+.1f" % [stats.power - current.power, stats.hp - current.hp, stats.armor - current.armor], 12)
	if item.slot == "gadget":
		text_line("Once per expedition: automatically restore 20% maximum HP when a nonlethal hit leaves you at 25% HP or lower. Infirmary II raises this to 25%.")
	var set_id := Content.set_id(item)
	if not set_id.is_empty():
		var definition: Dictionary = Content.SETS[set_id]
		text_line("%s set · Rare+: 2 pieces %s; 3 pieces %s." % [definition.name, definition.two, definition.three], 12)
	var equipped: bool = profile.data.equipment[item.slot] == item.id
	var actions := HBoxContainer.new()
	body.add_child(actions)
	var equip_button := button("Equipped" if equipped else "Equip", func(): refresh(func(): return profile.equip(item.id), "Equipment changed."), actions)
	equip_button.disabled = equipped or not profile.can_change_loadout()
	equip_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var locked: bool = item.id in profile.data.locked_items
	var lock_button := button("Unlock item" if locked else "Lock item", func(): refresh(func(): return profile.set_item_locked(item.id, not locked), "Item unlocked." if locked else "Item protected from salvage."), actions)
	lock_button.disabled = not profile.can_change_loadout()
	lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cost: Dictionary = profile.upgrade_cost(item.id)
	var upgrade := button("Upgrade • %d credits + %d parts" % [cost.credits, cost.parts] if not cost.is_empty() else "Level cap reached for this zone", func(): refresh(func(): return profile.upgrade_item(item.id), "Equipment upgraded."))
	upgrade.disabled = cost.is_empty() or not profile.can_change_loadout() or profile.data.credits < cost.get("credits", 0) or profile.data.parts < cost.get("parts", 0)
	var tuning := HBoxContainer.new()
	body.add_child(tuning)
	var merge := button("Merge copies", func(): merge_donors = []; page = "merge"; confirmation = ""; rebuild(), tuning, 40)
	merge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	merge.disabled = Content.RARITIES.find(item.rarity) >= Content.RARITIES.find(Content.MERGE_MAX_RARITY)
	merge.tooltip_text = "Maximum merge rarity for this zone" if merge.disabled else "Combine three matching items"
	button("Substats", func(): page = "substats"; confirmation = ""; selected_affix = ""; rebuild(), tuning, 40).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not equipped:
		var protection: String = profile.salvage_block_reason(item.id)
		button(protection if not protection.is_empty() else "Salvage for %d parts" % (2 + Content.RARITIES.find(item.rarity) + int(item.level) - 1), func():
			if confirmation == "salvage":
				refresh(func(): return profile.salvage(item.id), "Item salvaged.")
			else:
				confirmation = "salvage"; message = "Tap salvage again to permanently dismantle this item."; rebuild()).disabled = not profile.can_change_loadout() or not protection.is_empty()
	button("Back to equipment", func(): selected_item = -1; confirmation = ""; message = ""; rebuild())

func haven_page() -> void:
	text_line("Haven", 26)
	var scene := Control.new()
	scene.custom_minimum_size.y = 306
	body.add_child(scene)
	Art.picture(scene, Art.BASE, Rect2(0, -7, 386, 318))
	var hero := Art.picture(scene, Art.hero(profile.data["class"]), Rect2(157, 166, 82, 110))
	if not profile.data.settings.reduced_effects:
		var idle := hero.create_tween().set_loops()
		idle.tween_property(hero, "position:y", 164.0, 1.5)
		idle.tween_property(hero, "position:y", 166.0, 1.5)
	for entry in [["workshop", Vector2(93, 111)], ["infirmary", Vector2(306, 96)], ["quartermaster", Vector2(305, 233)]]:
		var id: String = entry[0]
		var node := button("II" if profile.data.facilities[id] == 2 else "I", func(): facility = id; page = "facility"; rebuild(), scene, 34)
		node.position = entry[1]
		node.size.x = 34
		node.tooltip_text = Content.FACILITIES[id].name
		node.add_theme_font_size_override("font_size", 20)
		node.add_theme_font_override("font", Art.DISPLAY_FONT)
		var plaque := style(Color(0.04, 0.08, 0.16, 0.78), Color("6c82a4"))
		plaque.set_content_margin_all(4)
		node.add_theme_stylebox_override("normal", plaque)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	body.add_child(grid)
	for entry in [["workshop", "Workshop"], ["infirmary", "Infirmary"], ["quartermaster", "Storehouse"], ["training", "Training"], ["arcanum", "Arcanum"], ["mission", "Expedition"]]:
		var id: String = entry[0]
		icon_button(entry[1], id, func():
			if id in Content.FACILITIES:
				facility = id
				page = "facility"
			else:
				page = id
			rebuild(), grid, 86)

func facility_page() -> void:
	var definition: Dictionary = Content.FACILITIES[facility]
	text_line(definition.name, 25)
	var art := Control.new()
	art.custom_minimum_size.y = 165
	body.add_child(art)
	Art.picture(art, Art.icon(facility), Rect2(90, 0, 200, 160))
	text_line("Rank %d / 2" % profile.data.facilities[facility], 18, Color("ffd27c"))
	text_line(definition.description, 15)
	var summary := "Upgrade costs: 100% → 90% credits; Parts unchanged."
	if facility == "infirmary":
		summary = "Medkit healing: 20% → 25% maximum HP. Once per run."
	elif facility == "quartermaster":
		summary = "Backpack: 8 → 9 slots. Secure stash: 2 slots."
	text_line(summary, 14, Color("ba92ff"))
	var complete: bool = profile.data.facilities[facility] >= 2
	var improve := button("Fully upgraded" if complete else "Upgrade · %d credits + %d Parts" % [definition.credits, definition.parts], func(): refresh(func(): return profile.upgrade_facility(facility), definition.name + " improved."))
	improve.disabled = complete or not profile.can_change_loadout() or profile.data.credits < definition.credits or profile.data.parts < definition.parts
	if facility == "workshop":
		button("Open equipment", func(): navigate("gear"))
	elif facility == "quartermaster":
		button("Find materials · Salvage contracts", func(): navigate("contracts"))
	button("Back to Base", func(): navigate("haven"))

func contracts_page() -> void:
	text_line("SALVAGE CONTRACTS", 22, Color("ffd27c"))
	text_line("A short material run for your next upgrade.")
	text_line("Open 3 caches, survive until the beacon powers up at 90 seconds, then hold its central ring for 3 seconds. Leave before the 3-minute deadline.", 15)
	text_line("There is no boss in this side mode. Campaign missions still require a boss kill.", 13, Color("ba92ff"))
	text_line("Choose your guaranteed equipment slot", 16)
	var target_button := button(contract_slot.capitalize() + " • tap to change", func(): contract_slot = Content.SLOTS[(Content.SLOTS.find(contract_slot) + 1) % Content.SLOTS.size()]; rebuild(), null, 58)
	decorate_item_button(target_button, contract_slot)
	text_line("Clear: 80 credits + 2 Parts, 45 Survivor XP, 25 Mastery XP, and equipment for this slot (75% Common / 25% Uncommon). Collected loot is extra.", 13)
	text_line("Every 3 contract clears: +1 supply key\nProgress: %d/3 • %d total clears" % [profile.data.contract_clears % 3, profile.data.contract_clears], 13, Color("ba92ff"))
	var unlocked: bool = profile.Salvage.unlocked(profile)
	var start := button("Start contract" if unlocked else "Clear Garage Lights to unlock", func(): contract_requested.emit(contract_slot))
	start.disabled = not unlocked or not profile.can_change_loadout()
	if not profile.data.active_attempt.is_empty():
		text_line("Finish or resume your saved expedition before starting another.", 13)
	button("Back to Base", func(): page = "haven"; rebuild(), null, 40)

func class_page() -> void:
	var id: String = inspected_class if not inspected_class.is_empty() else profile.data["class"]
	var info: Dictionary = Content.CLASSES[id]
	var unlocked: bool = profile.class_unlocked(id)
	text_line(info.name, 25)
	var stage := Control.new()
	stage.custom_minimum_size.y = 198
	body.add_child(stage)
	Art.pedestal(stage, Vector2(193, 179), 160)
	Art.picture(stage, Art.hero(id), Rect2(90, 0, 204, 193))
	var xp: int = profile.data.mastery[id]
	var level: int = Content.mastery_level(xp)
	text_line("Permanent mastery %d / 20" % level, 17, Color("ffd27c"))
	var progress := ProgressBar.new()
	progress.custom_minimum_size.y = 8
	progress.show_percentage = false
	progress.max_value = (level + 1) * 100
	progress.value = xp - level * (level + 1) * 50
	if level == 20:
		progress.value = progress.max_value
	progress.add_theme_stylebox_override("background", style(Color("0a1224")))
	progress.add_theme_stylebox_override("fill", style(Color("8d6be8")))
	body.add_child(progress)
	text_line(info.description, 13)
	var roster := HBoxContainer.new()
	body.add_child(roster)
	for class_id: String in Content.CLASSES:
		var node := button(Content.CLASSES[class_id].name, func(): inspected_class = class_id; rebuild(), roster, 54)
		node.add_theme_font_size_override("font_size", 12)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.icon = Art.hero(class_id)
		node.expand_icon = true
		node.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		node.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		node.add_theme_constant_override("icon_max_width", 27)
		node.add_theme_color_override("font_color", Color("ffd27c") if class_id == id else Color("bcc5dc"))
	var selected: bool = profile.data["class"] == id
	var choose := button("Selected" if selected else ("Select " + info.name if unlocked else info.unlock), func(): refresh(func(): return profile.select_class(id), info.name + " selected."))
	choose.disabled = selected or not unlocked or not profile.can_change_loadout()
	var progression := HBoxContainer.new()
	body.add_child(progression)
	button("Skill tree · %d points" % profile.skill_points(id), func(): page = "skills"; tree_ability = ""; rebuild(), progression, 40).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button("Mastery talents", func(): page = "mastery"; rebuild(), progression, 40).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_line("Survivor level %d / 40 · %d lifetime XP" % [Content.survivor_level(profile.data.survivor_xp), profile.data.survivor_xp], 12)

func settings_page() -> void:
	text_line("SETTINGS", 22, Color("ffd27c"))
	text_line("Original instrumental music and sound effects. Your preferences are saved on this device.")
	for key in ["music", "sound"]:
		text_line("%s volume • %.0f%%" % [key.capitalize(), profile.data.settings[key] * 100], 17)
		var row := HBoxContainer.new()
		body.add_child(row)
		for volume in [0.0, 0.25, 0.5, 1.0]:
			var node := button("Off" if volume == 0 else "%.0f%%" % (volume * 100), func(): refresh(func(): return profile.set_setting(key, volume), "Audio preference saved."), row)
			node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for entry in [["haptics", "Vibration"], ["reduced_effects", "Reduced effects"]]:
		var enabled: bool = profile.data.settings[entry[0]]
		button("%s: %s" % [entry[1], "On" if enabled else "Off"], func(): refresh(func(): return profile.set_setting(entry[0], not enabled), "Preference saved."))
	text_line("Reduced effects hides screen flashes and softens spell effects. Attack warnings remain visible.", 13)
	button("Internal test tools & ad privacy", func(): diagnostics_requested.emit())
	button("Back to Haven", func(): page = "haven"; message = ""; rebuild())
func shop_page() -> void:
	text_line("Shop", 25)
	if not shop_flow.pending.is_empty():
		item_portrait("chest", 110)
		text_line(shop_flow.message, 16)
		if shop_flow.earned and not shop_flow.granted:
			button("Retry saving earned reward", func(): shop_earned(shop_flow.pending))
		elif not shop_flow.earned:
			button("Cancel loading", func(): shop_video_cancelled.emit(shop_flow.pending))
		return
	var card := Control.new()
	card.custom_minimum_size.y = 105
	body.add_child(card)
	Art.picture(card, Art.icon("shop"), Rect2(4, 0, 100, 100))
	var heading := Label.new()
	heading.position = Vector2(115, 20)
	heading.text = "Supply chests\nKeys · %d" % profile.data.cache_keys
	heading.add_theme_font_size_override("font_size", 20)
	card.add_child(heading)
	button("Open chests", func(): page = "cache"; cache_receipt = false; rebuild())
	var remaining: int = profile.shop_videos_left()
	var video := button("Watch video · earn 1 supply key  (%d/2 left)" % remaining, request_shop_video)
	video.disabled = remaining <= 0 or profile.blocked or not ads_available
	video.tooltip_text = "Optional video. Reward on completion. Resets daily at 00:00 UTC."
	text_line("Complete a video to claim your key.", 12, Color("a9b9d4"))
	if not ads_available:
		text_line("Video unavailable on this platform. Android supports test ads.", 12, Color("ba92ff"))
	for id: String in profile.SHOP_OFFERS:
		var offer: Dictionary = profile.SHOP_OFFERS[id]
		var caption := "%s · %d" % [offer.name, offer.cost]
		var buy := button(("Confirm: " if confirmation == id else "") + caption, func():
			if confirmation == id:
				refresh(func(): return profile.purchase_supply(id), offer.name + " added.")
			else:
				confirmation = id; message = "Tap again to confirm this purchase."; rebuild())
		buy.disabled = profile.blocked or profile.data[offer.currency] < offer.cost
		buy.icon = Art.item(offer.currency)
		buy.expand_icon = true
		buy.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		buy.add_theme_constant_override("icon_max_width", 27)
		buy.tooltip_text = "%s: %d %s" % [offer.name, offer.cost, offer.currency]
	if profile.data.rare_choices > 0:
		button("Claim earned Rare equipment", func(): page = "rare_choice"; rebuild(), null, 36)
