extends Control

signal mission_requested(mission: int)
signal resume_requested
signal abandon_requested
signal practice_requested(mission: int, build: String)
signal diagnostics_requested
signal contract_requested(slot: String, weapon_family: String)

const Art = preload("res://haven_art.gd")
const MenuSkin = preload("res://menu_skin.gd")
const MenuMotion = preload("res://menu_motion.gd")
const TalentPreview = preload("res://talent_preview.gd")
const ClassShowcase = preload("res://class_showcase.gd")
const Services = preload("res://haven_services_ui.gd")
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
const DailyUI = preload("res://daily_ui.gd")
const CombatTrainingUI = preload("res://combat_training_ui.gd")
const ItemDetail = preload("res://item_detail_ui.gd")
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
var zone_index := 0
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
var contract_weapon := "pistol"
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
	theme.default_font = MenuSkin.body_font()
	theme.default_font_size = 16
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var background := Art.picture(self, Art.BACKDROP, Rect2(Vector2.ZERO, size))
	background.stretch_mode = TextureRect.STRETCH_SCALE

	Art.picture(self, Art.MOON, Rect2(12, 14, 29, 34))
	var heading := Label.new()
	heading.text = "Nightfall"
	heading.position = Vector2(40, 18)
	heading.add_theme_font_override("font", MenuSkin.DISPLAY)
	heading.add_theme_font_size_override("font_size", 23)
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
	MenuSkin.action(settings)
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
	Art.picture(self, Art.CHROME.dock, Rect2(8, 690, 414, 68))
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
		tab.add_theme_font_override("font", MenuSkin.DISPLAY)
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
	if page in ["mission", "rewards", "contracts", "zones", "daily", "calendar"]:
		return "mission"
	if page in ["class", "mastery", "skills", "talents", "combat_training"]:
		return "class"
	return "gear" if page in ["gear", "builds", "filters", "merge", "substats", "sets"] else "haven"

func request_shop_video() -> void:
	if not ads_available:
		message = "Videos are unavailable right now. Please try again later."
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
	var face := MenuSkin.surface("blue")
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
	node.custom_minimum_size.y = maxi(44, height)
	MenuSkin.action(node)
	node.pressed.connect(action)
	var host: Node = parent if parent != null else body
	host.add_child(node)
	if host == body:
		node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		node.custom_minimum_size.x = 280
		node.custom_minimum_size.y = 56 if height >= 48 else 48
	return node

func text_line(value: String, font_size: int = 14, color: Color = Color("d6daea")) -> Label:
	if font_size >= 21:
		var ribbon := PanelContainer.new()
		ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		ribbon.custom_minimum_size.x = 310
		var face := MenuSkin.surface("ribbon")
		face.set_content_margin_all(3)
		ribbon.add_theme_stylebox_override("panel", face)
		body.add_child(ribbon)
		return MenuSkin.label(ribbon, value, mini(font_size,26), color, true)
	return MenuSkin.label(body, value, font_size, color)

func page_heading(parent: Node, text: String) -> void:
	var ribbon := PanelContainer.new()
	ribbon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var face := MenuSkin.surface("ribbon")
	face.set_content_margin_all(3)
	ribbon.add_theme_stylebox_override("panel", face)
	parent.add_child(ribbon)
	MenuSkin.label(ribbon, text, 25, Color.WHITE, true)

func item_texture(slot: String, equipment: Dictionary = {}) -> Texture2D:
	if slot == "weapon" and not equipment.is_empty():
		var family: String = preload("res://weapons.gd").family(equipment)
		if Art.WEAPON_ICONS.has(family):
			return Art.WEAPON_ICONS[family]
	if slot in Art.ITEM_NAMES:
		return Art.item(slot)
	var index: int = ["weapon", "helmet", "body", "boots", "charm", "gadget", "chest", "key"].find(slot)
	var cell := Vector2(EQUIPMENT_ART.get_width() / 4.0, EQUIPMENT_ART.get_height() / 2.0)
	var texture := AtlasTexture.new()
	texture.atlas = EQUIPMENT_ART
	texture.region = Rect2(Vector2(index % 4, index / 4) * cell, cell)
	return texture

func decorate_item_button(node: Button, slot: String, equipment: Dictionary = {}) -> void:
	node.icon = item_texture(slot, equipment)
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
	if has_meta("detail_previous_back_quit"):
		get_tree().quit_on_go_back = get_meta("detail_previous_back_quit")
		remove_meta("detail_previous_back_quit")
	var ambient := get_node_or_null("BackgroundMotion")
	if profile.data.settings.reduced_effects and ambient != null:
		remove_child(ambient)
		ambient.queue_free()
	elif not profile.data.settings.reduced_effects and ambient == null:
		ambient = MenuMotion.background(self)
		move_child(ambient, 1)
	ItemDetail.restore_background_focus(self)
	var old_detail := get_node_or_null("ItemDetailOverlay")
	if old_detail != null:
		remove_child(old_detail)
		old_detail.queue_free()
	for child in navigation.get_children():
		child.focus_mode = Control.FOCUS_ALL
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	frame_panel.position.y = 48 if page in ["class", "talents"] else 64
	body.add_theme_constant_override("separation", 5 if page == "arcanum" else 7)
	frame_panel.size = Vector2(402, 594)
	var surface := StyleBoxEmpty.new()
	surface.set_content_margin_all(8)
	frame_panel.add_theme_stylebox_override("panel", surface)
	for child in wallet.get_children():
		wallet.remove_child(child)
		child.queue_free()
	for currency in ["credits", "parts", "gems"]:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(68, 34)
		var chip_style := MenuSkin.surface("blue")
		chip_style.set_texture_margin_all(7)
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
		amount.add_theme_font_override("font", MenuSkin.DISPLAY)
		row.add_child(amount)
	match page:
		"mission": mission_page()
		"daily": DailyUI.show_page(self)
		"calendar": DailyUI.show_calendar(self)
		"zones": zones_page()
		"shop": shop_page()
		"facility": facility_page()
		"gear": gear_page()
		"builds": Armory.builds(self)
		"filters": Armory.filters(self)
		"merge": EquipmentWorkshop.merge(self)
		"craft": EquipmentWorkshop.crafting(self)
		"substats": EquipmentWorkshop.substats(self)
		"sets": EquipmentWorkshop.sets(self)
		"haven": haven_page()
		"class": class_page()
		"talents": TalentPreview.show_page(self)
		"combat_training": CombatTrainingUI.show_page(self)
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
		var tab_style := MenuSkin.surface("gold" if selected else "panel")
		tab_style.set_content_margin_all(4)
		tab.add_theme_stylebox_override("normal", tab_style)
		tab.add_theme_stylebox_override("hover", tab_style)
		tab.add_theme_stylebox_override("pressed", MenuSkin.surface("violet"))
		tab.add_theme_color_override("font_color", Color("fff5dc") if TABS[index][0] == active_tab() else Color("dce9ff"))
	ClassShowcase.decorate_navigation(self)
	queue_redraw()

func compact_amount(value: int) -> String:
	if value >= 1000000:
		return "%.1fM" % (value / 1000000.0)
	if value >= 10000:
		return "%.0fK" % (value / 1000.0)
	return str(value)

func mission_page() -> void:
	var heading := HBoxContainer.new()
	body.add_child(heading)
	page_heading(heading, "Expedition")
	button("Zones", func(): navigate("zones"), heading, 36).custom_minimum_size.x = 72
	MenuSkin.label(body, "%d · %s" % [zone_index+1,ZONES[zone_index]], 21, Color("ffe4a5"), true)
	var stage := Control.new()
	stage.custom_minimum_size.y = 138 if not profile.data.active_attempt.is_empty() else 194
	body.add_child(stage)
	stage.name = "ZoneMap"
	var island_rect := Rect2(46, -15, 294, stage.custom_minimum_size.y + 21)
	var island := Art.picture(stage, Art.OUTSKIRTS, island_rect)
	island.modulate = Color.WHITE if zone_index == 0 else Color(0.32,0.38,0.55)
	var previous := ClassShowcase.fixed_button(self,stage,"‹",Rect2(0,stage.custom_minimum_size.y*0.5-25,42,50),func(): browse_zone(-1),false,28)
	previous.name = "PreviousZone"
	previous.disabled = zone_index == 0
	previous.tooltip_text = "Previous zone"
	var next := ClassShowcase.fixed_button(self,stage,"›",Rect2(344,stage.custom_minimum_size.y*0.5-25,42,50),func(): browse_zone(1),false,28)
	next.name = "NextZone"
	next.disabled = zone_index == ZONES.size()-1
	next.tooltip_text = "Next zone"
	if zone_index != 0:
		MenuSkin.label(body,"Uncharted zone",24,Color("ffe4a5"),true)
		MenuSkin.label(body,"This region is planned. Its missions and map are not available yet.",16,Color("d7e6ff"))
		button("Return to Blackout Outskirts",func(): zone_index = 0; rebuild(),null,48)
		return
	if not profile.data.settings.reduced_effects:
		var motion = MenuMotion.island(stage, fitted_art_rect(Art.OUTSKIRTS, island_rect))
		motion.beacon_uv = Vector2(0.558,0.09)
		motion.warm_uv = [Vector2(0.28,0.45), Vector2(0.475,0.38)]
	var nodes := HBoxContainer.new()
	nodes.alignment = BoxContainer.ALIGNMENT_CENTER
	nodes.add_theme_constant_override("separation", 16)
	body.add_child(nodes)
	for number in range(1, 6):
		var medals: Array = profile.data.missions.get(str(number), [])
		var node := button(str(number), func(): mission = number; rebuild(), nodes, 48)
		node.custom_minimum_size.x = 48
		var face := StyleBoxTexture.new()
		face.texture = MenuSkin.texture("selected" if number == mission else "medallion")
		face.set_content_margin_all(0)
		node.add_theme_stylebox_override("normal", face)
		node.add_theme_stylebox_override("hover", face)
		node.add_theme_font_size_override("font_size", 24)
		node.modulate = Color.WHITE if profile.mission_unlocked(number) else Color("8493b4")
		node.tooltip_text = "%s · %d/3 mastery medals%s" % [Content.MISSIONS[number - 1].name, medals.size(), "" if profile.mission_unlocked(number) else " · Clear the previous mission"]
	var definition: Dictionary = Content.MISSIONS[mission - 1]
	MenuSkin.label(body, "%d. %s" % [mission, definition.name], 22, Color.WHITE, true)
	MenuSkin.label(body, "Survive 4 minutes · Defeat " + definition.boss, 13, Color("d7e6ff"), true)
	var modes := HBoxContainer.new()
	modes.add_theme_constant_override("separation", 8)
	body.add_child(modes)
	icon_button("Salvage contracts", "quartermaster", func(): navigate("contracts"), modes, 67).add_theme_constant_override("icon_max_width", 38)
	icon_button("Boss training", "training", func(): navigate("training"), modes, 67).add_theme_constant_override("icon_max_width", 38)
	var rewards := HBoxContainer.new()
	rewards.add_theme_constant_override("separation", 8)
	body.add_child(rewards)
	var chest := button("Rewards · %d/15" % profile.total_medals(), func(): navigate("rewards"), rewards, 44)
	chest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chest.icon = item_texture("chest")
	chest.expand_icon = true
	chest.add_theme_constant_override("icon_max_width", 35)
	button("Daily objectives", func(): navigate("daily"), rewards, 44).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not profile.data.active_attempt.is_empty():
		var resume := button("Resume expedition", func(): resume_requested.emit(), null, 48)
		MenuSkin.action(resume, "gold")
		button("End expedition", func():
			if confirmation == "abandon":
				abandon_requested.emit()
			else:
				confirmation = "abandon"; message = "Tap End expedition again. Only protected loot returns."; rebuild(), null, 32)
	else:
		var unlocked: bool = profile.mission_unlocked(mission)
		var start := button("Start expedition" if unlocked else "Clear the previous mission", func(): mission_requested.emit(mission), null, 52)
		MenuSkin.action(start, "gold")
		start.add_theme_font_size_override("font_size", 25)
		start.disabled = not unlocked or profile.blocked

func browse_zone(direction: int) -> void:
	zone_index = clampi(zone_index+direction,0,ZONES.size()-1)
	rebuild()

func zones_page() -> void:
	Services.zones(self)

func gear_page() -> void:
	var heading_row := HBoxContainer.new()
	body.add_child(heading_row)
	page_heading(heading_row, "Equipment")
	button("Sets", func(): navigate("sets"), heading_row, 32).custom_minimum_size.x = 54
	button("Builds", func(): Armory.pick_build(self, build_slot), heading_row, 32).custom_minimum_size.x = 70
	var stage := Control.new()
	stage.custom_minimum_size.y = 252
	body.add_child(stage)
	var hall_view := Control.new()
	hall_view.position = Vector2(72,0)
	hall_view.size = Vector2(242,245)
	hall_view.clip_contents = true
	hall_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(hall_view)
	var hall := Art.picture(hall_view, ClassShowcase.HALL, Rect2(-34,-26,310,300))
	hall.stretch_mode = TextureRect.STRETCH_SCALE
	Art.picture(stage, Art.GEAR_PLINTH, Rect2(85, 170, 216, 80))
	Art.picture(stage, Art.CONTACT_SHADOW, Rect2(122, 210, 143, 17))
	var hero := preload("res://gear_actor.gd").new()
	hero.name = "EquippedHero"
	hero.class_id = profile.data["class"]
	hero.weapon_family = profile.stats().weapon
	hero.reduced = profile.data.settings.reduced_effects
	hero.position = Vector2(183,211)
	hero.scale = Vector2.ONE*2.6
	stage.add_child(hero)
	var columns := [["weapon", "ring", "charm", "gadget"], ["helmet", "body", "pants", "boots"]]
	for column in 2:
		for index in 4:
			var slot: String = columns[column][index]
			var item: Dictionary = profile.item_by_id(profile.data.equipment[slot])
			var tile := equipment_tile(item, stage, Vector2(68, 59))
			tile.position = Vector2(4 if column == 0 else 312, index * 63)
	var stats: Dictionary = profile.stats()
	var stats_row := HBoxContainer.new()
	stats_row.custom_minimum_size.y = 36
	body.add_child(stats_row)
	for entry in [["Power", stats.power, Art.SWORD], ["HP", stats.hp, Art.item("hp")], ["Armor", stats.armor, Art.SHIELD]]:
		var stat_panel := PanelContainer.new()
		stat_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var stat_style := MenuSkin.surface("panel")
		stat_style.set_texture_margin_all(7)
		stat_style.content_margin_top = 1
		stat_style.content_margin_bottom = 1
		stat_style.content_margin_left = 5
		stat_style.content_margin_right = 4
		stat_panel.add_theme_stylebox_override("panel", stat_style)
		stats_row.add_child(stat_panel)
		var card := HBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = entry[0]
		stat_panel.add_child(card)
		var icon := Art.picture(card, entry[2], Rect2(0, 0, 30, 32))
		icon.custom_minimum_size = Vector2(30, 32)
		var amount := Label.new()
		amount.text = "%.0f" % entry[1]
		amount.add_theme_font_size_override("font_size", 25)
		card.add_child(amount)
		var stat_name := Label.new()
		stat_name.text = entry[0]
		stat_name.add_theme_font_size_override("font_size", 11)
		stat_name.add_theme_color_override("font_color", Color("b7c9e7"))
		card.add_child(stat_name)
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
	scroll.custom_minimum_size.y = 174
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var inventory_well := MenuSkin.surface("panel")
	inventory_well.set_texture_margin_all(12)
	inventory_well.set_content_margin_all(5)
	scroll.add_theme_stylebox_override("panel", inventory_well)
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
	if selected_item >= 0:
		ItemDetail.show_item(self)

func equipment_tile(item: Dictionary, parent: Node, dimensions: Vector2) -> Button:
	if item.is_empty():
		var empty := button("Empty",func(): pass,parent,int(dimensions.y))
		empty.custom_minimum_size = dimensions
		empty.size = dimensions
		empty.disabled = true
		return empty
	var tile := button("", func(): selected_item = item.id; message = ""; rebuild(), parent, int(dimensions.y))
	tile.custom_minimum_size = dimensions
	tile.size = dimensions
	tile.name = "Item%d" % item.id
	tile.tooltip_text = "%s · %s · Level %d" % [item.name, Content.SLOT_LABELS[item.slot], item.level]
	var rank: int = Content.RARITIES.find(item.rarity)
	var face := StyleBoxTexture.new()
	face.texture = Art.GEAR_FRAMES[rank]
	face.set_texture_margin_all(9)
	face.set_content_margin_all(4)
	tile.add_theme_stylebox_override("normal", face)
	var hover := face.duplicate()
	hover.modulate_color = face.modulate_color.lightened(0.18)
	tile.add_theme_stylebox_override("hover", hover)
	var pressed := face.duplicate()
	pressed.modulate_color = face.modulate_color.darkened(0.18)
	tile.add_theme_stylebox_override("pressed", pressed)
	tile.icon = item_texture(item.slot, item)
	tile.expand_icon = true
	tile.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tile.add_theme_constant_override("icon_max_width", int(dimensions.y - 8))
	var tier := Label.new()
	tier.text = Content.RARITIES[rank].left(1).to_upper()
	tier.tooltip_text = Content.RARITIES[rank].capitalize()
	tier.position = Vector2(5, 3)
	tier.add_theme_font_size_override("font_size", 9)
	tier.add_theme_color_override("font_color", Color("c4d6ef"))
	tier.add_theme_color_override("font_outline_color", Color("07152d"))
	tier.add_theme_constant_override("outline_size", 3)
	tier.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.add_child(tier)
	var caption := Label.new()
	caption.text = ("\u25C6 " if profile.data.equipment[item.slot] == item.id else "") + "Lv.%d" % item.level
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_outline_color", Color("0a1020"))
	caption.add_theme_constant_override("outline_size", 3)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.position = Vector2(5, dimensions.y - 17)
	caption.size = Vector2(dimensions.x - 10, 15)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tile.add_child(caption)
	if item.id in profile.data.locked_items:
		var lock_label := Label.new()
		lock_label.text = "LOCK"
		lock_label.position = Vector2(22, 1)
		lock_label.add_theme_font_size_override("font_size", 10)
		lock_label.add_theme_color_override("font_color", Color("ffd27c"))
		lock_label.add_theme_color_override("font_outline_color", Color("0a1020"))
		lock_label.add_theme_constant_override("outline_size", 3)
		lock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_child(lock_label)
	return tile

func item_page() -> void:
	ItemDetail.show_item(self)

func _unhandled_key_input(event: InputEvent) -> void:
	if page == "gear" and selected_item >= 0 and event.is_action_pressed("ui_cancel"):
		ItemDetail.close(self)
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and page == "gear" and selected_item >= 0:
		# Restore default Back behavior only after Android's current event finishes.
		# SceneTree checks quit_on_go_back after propagating this notification.
		ItemDetail.close.call_deferred(self)

func haven_page() -> void:
	text_line("Base", 30)
	var scene := Control.new()
	scene.custom_minimum_size.y = 328
	body.add_child(scene)
	Art.picture(scene, preload("res://assets/polish-v2/haven-island.png"), Rect2(-4, -13, 394, 343))
	var hero := Art.picture(scene, Art.hero(profile.data["class"]), Rect2(163, 162, 68, 86))
	hero.pivot_offset = Vector2(34, 80)
	if not profile.data.settings.reduced_effects:
		MenuMotion.island(scene, fitted_art_rect(preload("res://assets/polish-v2/haven-island.png"), Rect2(-4,-13,394,343)))
		MenuMotion.hero(hero)
	for entry in [["workshop", Vector2(67, 123)], ["infirmary", Vector2(279, 104)], ["quartermaster", Vector2(286, 245)]]:
		var id: String = entry[0]
		var node := button("II" if profile.data.facilities[id] == 2 else "I", func(): facility = id; page = "facility"; rebuild(), scene, 40)
		node.position = entry[1]
		node.custom_minimum_size = Vector2(40,40)
		node.size = Vector2(40,40)
		node.tooltip_text = Content.FACILITIES[id].name
		var face := StyleBoxTexture.new()
		face.texture = MenuSkin.texture("selected")
		face.set_content_margin_all(0)
		node.add_theme_stylebox_override("normal", face)
		node.add_theme_stylebox_override("hover", face)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 7)
	grid.add_theme_constant_override("v_separation", 7)
	body.add_child(grid)
	for entry in [["workshop", "Workshop"], ["infirmary", "Infirmary"], ["quartermaster", "Storehouse"], ["training", "Training"], ["arcanum", "Arcanum"], ["mission", "Expedition"]]:
		var id: String = entry[0]
		icon_button(entry[1], id, func():
			if id in Content.FACILITIES:
				facility = id; page = "facility"
			else:
				page = id
			rebuild(), grid, 86)

func facility_page() -> void:
	Services.facility(self)

func contracts_page() -> void:
	Services.contracts(self)

func class_page() -> void:
	ClassShowcase.show_page(self)

func settings_page() -> void:
	Services.settings(self)

func shop_page() -> void:
	text_line("Shop", 30)
	if not shop_flow.pending.is_empty():
		item_portrait("chest", 180)
		var pending_card := MenuSkin.panel(body)
		MenuSkin.label(pending_card, "Your supply reward", 24, Color.WHITE, true)
		MenuSkin.label(pending_card, shop_flow.message, 16, Color("dbe8ff"), true)
		if shop_flow.earned and not shop_flow.granted:
			MenuSkin.action(button("Retry saving earned reward", func(): shop_earned(shop_flow.pending)), "gold")
		elif not shop_flow.earned:
			button("Cancel loading", func(): shop_video_cancelled.emit(shop_flow.pending))
		return
	var stage := Control.new()
	stage.custom_minimum_size.y = 112 if profile.data.rare_choices > 0 else 166
	body.add_child(stage)
	Art.picture(stage, Art.GEAR_HALO, Rect2(70,-15,246,200))
	Art.picture(stage, Art.icon("shop"), Rect2(98,-7,190,stage.custom_minimum_size.y-4))
	var key_badge := HBoxContainer.new()
	key_badge.position = Vector2(166,stage.custom_minimum_size.y-30)
	stage.add_child(key_badge)
	MenuSkin.icon(key_badge, DailyUI.KEY_ICON, Vector2(29,30))
	MenuSkin.label(key_badge, str(profile.data.cache_keys), 24)
	var open := button("Open supply chests", func(): page = "cache"; cache_receipt = false; rebuild(), null, 48)
	MenuSkin.action(open, "gold")
	var video_card := MenuSkin.panel(body, "panel", 10)
	var remaining: int = profile.shop_videos_left()
	var video_row := HBoxContainer.new()
	video_card.add_child(video_row)
	MenuSkin.icon(video_row, DailyUI.KEY_ICON, Vector2(39,41))
	var video_text := VBoxContainer.new()
	video_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	video_row.add_child(video_text)
	MenuSkin.label(video_text, "A key on the house", 20)
	MenuSkin.label(video_text, "Optional video · %d / 2 available today" % remaining, 12)
	var video := button("Watch video · +1 key", request_shop_video, video_card, 40)
	MenuSkin.action(video, "blue")
	video.disabled = remaining <= 0 or profile.blocked or not ads_available
	video.tooltip_text = "Reward on completion. Resets daily at 00:00 UTC."
	if not ads_available:
		MenuSkin.label(video_card, "Videos are unavailable right now.", 12, Color("c9cbe7"), true)
	var offers := HBoxContainer.new()
	offers.add_theme_constant_override("separation", 8)
	body.add_child(offers)
	for id: String in profile.SHOP_OFFERS:
		var offer: Dictionary = profile.SHOP_OFFERS[id]
		var offer_content := MenuSkin.panel(offers, "panel", 8)
		MenuSkin.icon(offer_content, DailyUI.KEY_ICON if id == "key" else Art.item("parts"), Vector2(55,55))
		MenuSkin.label(offer_content, offer.name, 16, Color.WHITE, true)
		var buy := button("Confirm" if confirmation == id else str(offer.cost), func():
			if confirmation == id:
				refresh(func(): return profile.purchase_supply(id), offer.name + " added.")
			else:
				confirmation = id; message = "Tap again to confirm this purchase."; rebuild(), offer_content, 40)
		buy.name = "Purchase_" + id
		buy.disabled = profile.blocked or profile.data[offer.currency] < offer.cost
		buy.icon = Art.item(offer.currency)
		buy.expand_icon = true
		buy.add_theme_constant_override("icon_max_width", 26)
		buy.tooltip_text = "%s: %d %s" % [offer.name, offer.cost, offer.currency]
	if profile.data.rare_choices > 0:
		MenuSkin.action(button("Claim earned Rare equipment", func(): page = "rare_choice"; rebuild(), null, 36), "gold")

func fitted_art_rect(image: Texture2D, frame: Rect2) -> Rect2:
	var factor := minf(frame.size.x / image.get_width(), frame.size.y / image.get_height())
	var fitted := Vector2(image.get_width(), image.get_height()) * factor
	return Rect2(frame.position + (frame.size - fitted) * 0.5, fitted)
