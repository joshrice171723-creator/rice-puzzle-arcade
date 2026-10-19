extends Control

signal mission_requested(mission: int)
signal resume_requested
signal abandon_requested
signal practice_requested
signal diagnostics_requested

const Content = preload("res://haven_content.gd")
const LootUI = preload("res://loot_ui.gd")
const ACTORS = preload("res://assets/actors.png")
const FLOOR = preload("res://assets/courtyard.png")
const EQUIPMENT_ART = preload("res://assets/equipment-icons.png")
var profile: RefCounted
var page := "mission"
var mission := 1
var inventory_page := 0
var selected_item := -1
var confirmation := ""
var message := ""
var body: VBoxContainer
var wallet: Label
var title: Label
var navigation: HBoxContainer
var status_label: Label
var cache_receipt := false

func _ready() -> void:
	size = Vector2(430, 760)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.04, 0.09, 0.94)
	shade.size = size
	add_child(shade)
	var heading := Label.new()
	heading.text = "NIGHTFALL"
	heading.position = Vector2(24, 18)
	heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", Color("ffd27c"))
	add_child(heading)
	var subtitle := Label.new()
	subtitle.text = "HAVEN  /  BEACONBOUND"
	subtitle.position = Vector2(26, 56)
	subtitle.add_theme_font_size_override("font_size", 12)
	subtitle.add_theme_color_override("font_color", Color("b9a7de"))
	add_child(subtitle)
	var settings := button("Settings", func(): page = "settings"; message = ""; rebuild(), self, 40)
	settings.position = Vector2(317, 22)
	settings.size.x = 95
	wallet = Label.new()
	wallet.position = Vector2(24, 86)
	wallet.add_theme_font_size_override("font_size", 15)
	add_child(wallet)
	var panel := PanelContainer.new()
	panel.position = Vector2(18, 126)
	panel.size = Vector2(394, 545)
	panel.add_theme_stylebox_override("panel", style(Color("131e38"), Color("514774")))
	add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	panel.add_child(body)
	status_label = Label.new()
	status_label.position = Vector2(25, 648)
	status_label.size = Vector2(380, 38)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.max_lines_visible = 2
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.add_theme_color_override("font_color", Color("ffd27c"))
	add_child(status_label)
	navigation = HBoxContainer.new()
	navigation.position = Vector2(18, 691)
	navigation.size = Vector2(394, 52)
	navigation.add_theme_constant_override("separation", 5)
	add_child(navigation)
	for entry in [["mission", "Venture"], ["gear", "Gear"], ["haven", "Haven"], ["class", "Class"]]:
		var tab := button(entry[1], func(): page = entry[0]; selected_item = -1; confirmation = ""; message = ""; rebuild(), navigation)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rebuild()

func style(fill: Color, border: Color = Color("354568")) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(1)
	box.set_corner_radius_all(12)
	box.set_content_margin_all(12)
	return box

func button(text_value: String, action: Callable, parent: Node = null, height: int = 44) -> Button:
	var node := Button.new()
	node.text = text_value
	node.custom_minimum_size.y = height
	node.add_theme_font_size_override("font_size", 15)
	node.add_theme_color_override("font_color", Color("f5e9d8"))
	node.add_theme_stylebox_override("normal", style(Color("243456")))
	node.add_theme_stylebox_override("hover", style(Color("344467"), Color("ffd27c")))
	node.add_theme_stylebox_override("pressed", style(Color("46375f"), Color("ba92ff")))
	node.pressed.connect(action)
	(parent if parent != null else body).add_child(node)
	return node

func text_line(value: String, font_size: int = 14, color: Color = Color("d6daea")) -> Label:
	var node := Label.new()
	node.text = value
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	body.add_child(node)
	return node

func item_texture(slot: String) -> AtlasTexture:
	var index: int = (Content.SLOTS + ["chest", "key"]).find(slot)
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
	wallet.text = "%d credits   /   %d parts   /   %d gems" % [profile.data.credits, profile.data.parts, profile.data.gems]
	match page:
		"mission": mission_page()
		"gear": gear_page()
		"haven": haven_page()
		"class": class_page()
		"settings": settings_page()
		"cache": LootUI.show(self)
		"rewards": LootUI.mission_rewards(self)
		"rare_choice": LootUI.rare_choice(self)
	status_label.text = profile.error if not profile.error.is_empty() else message
	for index in navigation.get_child_count():
		var tab: Button = navigation.get_child(index)
		tab.add_theme_color_override("font_color", Color("ffd27c") if ["mission", "gear", "haven", "class"][index] == page else Color("d6daea"))
	queue_redraw()

func mission_page() -> void:
	text_line("01  BLACKOUT OUTSKIRTS", 21, Color("ffd27c"))
	text_line("%d / 15 mastery medals" % profile.total_medals(), 14, Color("ba92ff"))
	var map := Control.new()
	map.custom_minimum_size.y = 100
	map.draw.connect(func():
		map.draw_line(Vector2(22, 50), Vector2(327, 50), Color("5a4a75"), 3)
		for index in 5:
			var at := Vector2(26 + index * 75, 50)
			var unlocked: bool = profile.mission_unlocked(index + 1)
			map.draw_circle(at, 22, Color("614977") if index + 1 == mission else Color("263552"))
			map.draw_arc(at, 23, 0, TAU, 32, Color("ffd27c") if unlocked else Color("596075"), 2)
			map.draw_string(ThemeDB.fallback_font, at + Vector2(-5, 6), str(index + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("f5e9d8"))
			if "clear" in profile.data.missions.get(str(index + 1), []):
				map.draw_circle(at + Vector2(0, 34), 4, Color("ffd27c")))
	body.add_child(map)
	var definition: Dictionary = Content.MISSIONS[mission - 1]
	text_line("%d. %s" % [mission, definition.name], 22)
	text_line(definition.intro)
	text_line("Survive %.0f minutes, then defeat %s.\nThe boss fight has no time limit." % [definition.duration / 60, definition.boss])
	var medals: Array = profile.data.missions.get(str(mission), [])
	text_line("%s Defeat the boss\n%s At most 8 damaging hits, no rescue\n%s Clear after opening 3 caches" % ["◆" if "clear" in medals else "◇", "◆" if "combat" in medals else "◇", "◆" if "scavenger" in medals else "◇"], 13)
	var row := HBoxContainer.new()
	body.add_child(row)
	button("‹ Previous", func(): mission = maxi(1, mission - 1); rebuild(), row).disabled = mission == 1
	button("Rewards", func(): page = "rewards"; rebuild(), row)
	button("Next ›", func(): mission = mini(5, mission + 1); rebuild(), row).disabled = mission == 5
	if not profile.data.active_attempt.is_empty():
		button("Resume saved expedition", func(): resume_requested.emit())
		button("End expedition & keep protected loot", func():
			if confirmation == "abandon":
				abandon_requested.emit()
			else:
				confirmation = "abandon"; message = "Tap again to abandon this expedition. Unprotected loot will be lost."; rebuild(), null, 40)
	else:
		var unlocked: bool = profile.mission_unlocked(mission)
		var start := button("Enter the Outskirts" if unlocked else "Clear the previous mission to unlock", func(): mission_requested.emit(mission), null, 50)
		start.disabled = not unlocked or profile.blocked
		var base := Content.clear_rewards(mission)
		text_line("Clear: %d credits + %d parts. First clear adds gems and a key." % [base.credits, base.parts], 12)

func gear_page() -> void:
	if selected_item >= 0:
		item_page()
		return
	text_line("ARMORY", 22, Color("ffd27c"))
	var stats: Dictionary = profile.stats()
	text_line("%.0f HP   •   %.1f Power   •   %.0f Armor" % [stats.hp, stats.power, stats.armor], 16)
	text_line("Choose equipment before entering. Upgrades persist; shrine traits and combat levels do not.")
	button("Claim Rare equipment choice" if profile.data.rare_choices > 0 else "Supply chests • %d keys" % profile.data.cache_keys, func(): page = "rare_choice" if profile.data.rare_choices > 0 else "cache"; cache_receipt = false; rebuild(), null, 40)
	var pages := maxi(1, ceili(profile.data.inventory.size() / 3.0))
	inventory_page = clampi(inventory_page, 0, pages - 1)
	for index in range(inventory_page * 3, mini(profile.data.inventory.size(), inventory_page * 3 + 3)):
		var item: Dictionary = profile.data.inventory[index]
		var equipped: bool = profile.data.equipment[item.slot] == item.id
		var node := button("%s%s • Lv %d\n%s %s" % ["◆ " if equipped else "", item.name, item.level, item.rarity.capitalize(), item.slot], func(): selected_item = item.id; message = ""; rebuild(), null, 61)
		decorate_item_button(node, item.slot)
		node.add_theme_color_override("font_color", Color(Content.RARITY_COLORS[Content.RARITIES.find(item.rarity)]))
	if pages > 1:
		button("Next page • %d/%d" % [inventory_page + 1, pages], func(): inventory_page = (inventory_page + 1) % pages; rebuild(), null, 40)

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
		text_line(Content.AFFIXES[affix].description, 13, Color("ba92ff"))
	if profile.data.equipment[item.slot] != item.id:
		var current: Dictionary = Content.item_stats(profile.item_by_id(profile.data.equipment[item.slot]))
		text_line("Compared with equipped: Power %+.1f / HP %+.0f / Armor %+.1f" % [stats.power - current.power, stats.hp - current.hp, stats.armor - current.armor], 12)
	if item.slot == "gadget":
		text_line("Once per expedition: automatically restore 20% maximum HP when a nonlethal hit leaves you at 25% HP or lower. Infirmary II raises this to 25%.")
	elif item.name.begins_with("Outrider"):
		text_line("Rare Outrider set: 2 pieces +15% XP reach; 3 pieces +1 protected slot.", 13)
	var equipped: bool = profile.data.equipment[item.slot] == item.id
	button("Equipped" if equipped else "Equip", func(): refresh(func(): return profile.equip(item.id), "Equipment changed.")).disabled = equipped or not profile.can_change_loadout()
	var cost: Dictionary = profile.upgrade_cost(item.id)
	var upgrade := button("Upgrade • %d credits + %d parts" % [cost.credits, cost.parts] if not cost.is_empty() else "Level cap reached for this zone", func(): refresh(func(): return profile.upgrade_item(item.id), "Equipment upgraded."))
	upgrade.disabled = cost.is_empty() or not profile.can_change_loadout() or profile.data.credits < cost.get("credits", 0) or profile.data.parts < cost.get("parts", 0)
	var promotion: Dictionary = profile.promotion_cost(item.id)
	if not promotion.is_empty():
		var promote := button("Promote to %s • %dc / %dp" % [promotion.rarity.capitalize(), promotion.credits, promotion.parts], func(): refresh(func(): return profile.promote(item.id), "Rarity increased. Item level preserved."))
		promote.disabled = not profile.can_change_loadout() or profile.data.credits < promotion.credits or profile.data.parts < promotion.parts
	if not equipped:
		button("Salvage for %d parts" % (2 + Content.RARITIES.find(item.rarity) + int(item.level) - 1), func():
			if confirmation == "salvage":
				refresh(func(): return profile.salvage(item.id), "Item salvaged.")
			else:
				confirmation = "salvage"; message = "Tap salvage again to permanently dismantle this item."; rebuild()).disabled = not profile.can_change_loadout()
	button("Back to equipment", func(): selected_item = -1; confirmation = ""; message = ""; rebuild())

func haven_page() -> void:
	text_line("REBUILD HAVEN", 22, Color("ffd27c"))
	text_line("Spend scavenged materials on lasting improvements. No construction timers.")
	for id: String in Content.FACILITIES:
		var facility: Dictionary = Content.FACILITIES[id]
		text_line("%s  •  Rank %d/2" % [facility.name, profile.data.facilities[id]], 17, Color("ba92ff"))
		text_line(facility.description, 13)
		var complete: bool = profile.data.facilities[id] >= 2
		var node := button("Built" if complete else "Improve • %d credits + %d parts" % [facility.credits, facility.parts], func(): refresh(func(): return profile.upgrade_facility(id), "%s improved." % facility.name), null, 40)
		node.disabled = complete or not profile.can_change_loadout() or profile.data.credits < facility.credits or profile.data.parts < facility.parts
	button("Training yard • boss practice", func(): practice_requested.emit(), null, 40)

func class_page() -> void:
	text_line("YOUR SURVIVOR", 22, Color("ffd27c"))
	text_line("Survivor level %d / 40  •  %d earned XP" % [Content.survivor_level(profile.data.survivor_xp), profile.data.survivor_xp], 15)
	for id: String in Content.CLASSES:
		var info: Dictionary = Content.CLASSES[id]
		var unlocked: bool = profile.class_unlocked(id)
		var selected: bool = profile.data["class"] == id
		text_line("%s%s  •  Mastery %d/20" % ["◆ " if selected else "", info.name, Content.mastery_level(profile.data.mastery[id])], 17, Color("ba92ff"))
		text_line(info.description if unlocked else info.unlock, 13)
		var node := button("Selected" if selected else ("Select %s" % info.name if unlocked else "Locked"), func(): refresh(func(): return profile.select_class(id), "Class changed."), null, 40)
		node.disabled = selected or not unlocked or not profile.can_change_loadout()

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
