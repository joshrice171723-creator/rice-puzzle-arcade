extends Control

signal mission_requested(mission: int)
signal resume_requested
signal abandon_requested
signal practice_requested
signal diagnostics_requested

const Content = preload("res://haven_content.gd")
const ACTORS = preload("res://assets/actors.png")
const FLOOR = preload("res://assets/courtyard.png")
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
	var settings := button("Settings", func(): diagnostics_requested.emit(), self, 40)
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
	text_line("%s Defeat the boss\n%s Clear with 8 or fewer damaging hits\n%s Clear after opening 3 caches" % ["◆" if "clear" in medals else "◇", "◆" if "combat" in medals else "◇", "◆" if "scavenger" in medals else "◇"], 13)
	var row := HBoxContainer.new()
	body.add_child(row)
	button("‹ Previous", func(): mission = maxi(1, mission - 1); rebuild(), row).disabled = mission == 1
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
		text_line("Clear: %d credits + %d parts. First clear adds gems." % [248 if mission == 5 else 165, 5 if mission == 5 else 3], 12)

func gear_page() -> void:
	if selected_item >= 0:
		item_page()
		return
	text_line("ARMORY", 22, Color("ffd27c"))
	var stats: Dictionary = profile.stats()
	text_line("%.0f HP   •   %.1f Power   •   %.0f Armor" % [stats.hp, stats.power, stats.armor], 16)
	text_line("Choose equipment before entering. Upgrades persist; shrine traits and combat levels do not.")
	var pages := maxi(1, ceili(profile.data.inventory.size() / 4.0))
	inventory_page = clampi(inventory_page, 0, pages - 1)
	for index in range(inventory_page * 4, mini(profile.data.inventory.size(), inventory_page * 4 + 4)):
		var item: Dictionary = profile.data.inventory[index]
		var equipped: bool = profile.data.equipment[item.slot] == item.id
		var node := button("%s%s • Lv %d\n%s %s" % ["◆ " if equipped else "", item.name, item.level, item.rarity.capitalize(), item.slot], func(): selected_item = item.id; message = ""; rebuild(), null, 61)
		node.add_theme_color_override("font_color", Color(Content.RARITY_COLORS[Content.RARITIES.find(item.rarity)]))
	if pages > 1:
		button("Next page • %d/%d" % [inventory_page + 1, pages], func(): inventory_page = (inventory_page + 1) % pages; rebuild(), null, 40)

func item_page() -> void:
	var item: Dictionary = profile.item_by_id(selected_item)
	if item.is_empty():
		selected_item = -1
		gear_page()
		return
	text_line(item.name, 24, Color(Content.RARITY_COLORS[Content.RARITIES.find(item.rarity)]))
	text_line("%s %s  •  Level %d/5" % [item.rarity.capitalize(), item.slot.capitalize(), item.level])
	var stats: Dictionary = Content.item_stats(item)
	text_line("Power %.1f   HP %.0f   Armor %.1f" % [stats.power, stats.hp, stats.armor], 16)
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
