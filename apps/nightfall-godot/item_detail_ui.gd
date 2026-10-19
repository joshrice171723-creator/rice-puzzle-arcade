extends RefCounted
const Art = preload("res://haven_art.gd")
const Content = preload("res://haven_content.gd")
const PANEL = preload("res://assets/gear/detail-panel.svg")
const ACTION_FACES = [preload("res://assets/gear/action-blue.svg"), preload("res://assets/gear/action-violet.svg"), preload("res://assets/gear/action-gold.svg")]
const ACTION_DISABLED = preload("res://assets/gear/action-disabled.svg")
const RIBBONS = [preload("res://assets/gear/ribbon-0.svg"), preload("res://assets/gear/ribbon-1.svg"), preload("res://assets/gear/ribbon-2.svg"), preload("res://assets/gear/ribbon-3.svg"), preload("res://assets/gear/ribbon-4.svg"), preload("res://assets/gear/ribbon-5.svg")]

static func label(parent: Node, text: String, font_size: int = 15, color: Color = Color("f2f2ff")) -> Label:
	var node := Label.new()
	node.text = text
	if font_size >= 15:
		var bold := FontVariation.new()
		bold.base_font = Art.BODY_FONT
		bold.variation_embolden = 0.8
		node.add_theme_font_override("font", bold)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func section(home: Control, parent: Node, heading: String, lines: Array) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	parent.add_child(column)
	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", home.style(Color("30395d"), Color("646a91")))
	column.add_child(header)
	label(header, heading, 15)
	for index in lines.size():
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", home.style(Color("d2d7ee") if index % 2 == 0 else Color("bac5e4"), Color("a4b5da")))
		column.add_child(row)
		label(row, lines[index], 14, Color("263456"))

static func close(home: Control) -> void:
	home.selected_item = -1
	home.confirmation = ""
	home.message = ""
	home.rebuild()

static func mute_background_focus(node: Node) -> void:
	if node is Control:
		node.set_meta("detail_previous_focus_mode", node.focus_mode)
		node.focus_mode = Control.FOCUS_NONE
	for child in node.get_children():
		mute_background_focus(child)

static func restore_background_focus(node: Node) -> void:
	if node is Control and node.has_meta("detail_previous_focus_mode"):
		node.focus_mode = node.get_meta("detail_previous_focus_mode")
		node.remove_meta("detail_previous_focus_mode")
	for child in node.get_children():
		restore_background_focus(child)

static func show_item(home: Control) -> void:
	var item: Dictionary = home.profile.item_by_id(home.selected_item)
	if item.is_empty():
		home.selected_item = -1
		return
	mute_background_focus(home)
	home.set_meta("detail_previous_back_quit", home.get_tree().quit_on_go_back)
	home.get_tree().quit_on_go_back = false
	var overlay := ColorRect.new()
	overlay.name = "ItemDetailOverlay"
	overlay.color = Color(0.005, 0.01, 0.04, 0.78)
	overlay.size = Vector2(430, 760)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	home.add_child(overlay)
	var panel := Panel.new()
	panel.name = "ItemDetailPopup"
	panel.position = Vector2(14, 148)
	panel.size = Vector2(402, 552)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var surface := StyleBoxTexture.new()
	surface.texture = PANEL
	surface.set_texture_margin_all(18)
	panel.add_theme_stylebox_override("panel", surface)
	overlay.add_child(panel)
	var rank: int = Content.RARITIES.find(item.rarity)
	Art.picture(overlay, RIBBONS[rank], Rect2(26, 126, 378, 55))
	var name_label := label(overlay, item.name, 25)
	name_label.position = Vector2(49, 134)
	name_label.size = Vector2(332, 35)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_outline_color", Color("142145"))
	name_label.add_theme_constant_override("outline_size", 4)
	var rarity := PanelContainer.new()
	rarity.position = Vector2(160, 174)
	rarity.size = Vector2(110, 26)
	var rarity_style: StyleBoxFlat = home.style(Color(Content.RARITY_COLORS[rank]).darkened(0.5), Color("70b8f1"))
	rarity_style.set_content_margin_all(2)
	rarity.add_theme_stylebox_override("panel", rarity_style)
	overlay.add_child(rarity)
	var rarity_label := label(rarity, item.rarity.capitalize(), 15)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var close_button: Button = home.button("×", func(): close(home), overlay, 44)
	close_button.name = "CloseItemDetail"
	close_button.tooltip_text = "Close item details"
	close_button.position = Vector2(359, 150)
	close_button.custom_minimum_size = Vector2(54, 54)
	close_button.size = Vector2(54, 54)
	close_button.add_theme_font_size_override("font_size", 30)
	var close_face: StyleBoxFlat = home.style(Color("198ed1"), Color("91dbff"))
	close_face.set_corner_radius_all(27)
	close_face.set_border_width_all(2)
	close_face.set_content_margin_all(0)
	close_button.add_theme_stylebox_override("normal", close_face)
	var close_pressed := close_face.duplicate()
	close_pressed.bg_color = Color("155eaa")
	close_button.add_theme_stylebox_override("hover", close_face)
	close_button.add_theme_stylebox_override("pressed", close_pressed)
	var close_focus := close_face.duplicate()
	close_focus.draw_center = false
	close_focus.border_color = Color("ffd27c")
	close_button.add_theme_stylebox_override("focus", close_focus)
	close_button.grab_focus()
	var scroll := ScrollContainer.new()
	scroll.name = "ItemDetailScroll"
	scroll.position = Vector2(36, 207)
	scroll.size = Vector2(358, 358)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	overlay.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 10)
	content.add_child(summary)
	var art_panel := PanelContainer.new()
	art_panel.custom_minimum_size = Vector2(123, 124)
	var art_frame := StyleBoxTexture.new()
	art_frame.texture = Art.GEAR_FRAMES[rank]
	art_frame.set_texture_margin_all(12)
	art_frame.set_content_margin_all(8)
	art_panel.add_theme_stylebox_override("panel", art_frame)
	summary.add_child(art_panel)
	var portrait := TextureRect.new()
	portrait.texture = home.item_texture(item.slot)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art_panel.add_child(portrait)
	var stats_column := VBoxContainer.new()
	stats_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_column.add_theme_constant_override("separation", 6)
	summary.add_child(stats_column)
	var stats: Dictionary = Content.item_stats(item)
	var stat_lines: Array = ["Lv: %d / 5" % item.level]
	for key in ["power", "hp", "armor"]:
		if stats[key] > 0:
			stat_lines.append("%s: %.1f" % [{"power": "Power", "hp": "HP", "armor": "Armor"}[key], stats[key]])
	if item.slot == "gadget":
		stat_lines.append("Field Medkit")
	for text: String in stat_lines:
		var stat_row := PanelContainer.new()
		var stat_face: StyleBoxFlat = home.style(Color("d2d7ee"), Color("9db5df"))
		stat_face.set_content_margin_all(6)
		stat_row.add_theme_stylebox_override("panel", stat_face)
		stats_column.add_child(stat_row)
		label(stat_row, text, 17, Color("273450"))
	var equipped: bool = home.profile.data.equipment[item.slot] == item.id
	var set_id := Content.set_id(item)
	if not set_id.is_empty():
		var definition: Dictionary = Content.SETS[set_id]
		var count: int = home.profile.set_counts()[set_id]
		var set_lines: Array = []
		for threshold in [2, 3]:
			set_lines.append("%d pieces (%d/%d): %s%s" % [threshold, mini(count, threshold), threshold, definition.two if threshold == 2 else definition.three, " · Active" if count >= threshold else " · Requires Rare+"])
		section(home, content, "%s set · %d qualifying pieces" % [definition.name, count], set_lines)
	else:
		section(home, content, "Equipment effect", ["Once per expedition: restore %d%% maximum HP when a nonlethal hit leaves you at 25%% HP or below." % (25 if home.profile.data.facilities.infirmary == 2 else 20)] if item.slot == "gadget" else [Content.SLOT_LABELS[item.slot] + " · " + ("Currently equipped" if equipped else "Ready to equip")])
	var substats: Array = []
	for affix: String in item.get("affixes", []):
		substats.append(Content.affix_text(item, affix))
	if substats.is_empty():
		substats.append("No substats · Merge to Uncommon to gain one.")
	section(home, content, "Sub Stats", substats)
	if not equipped:
		var current: Dictionary = Content.item_stats(home.profile.item_by_id(home.profile.data.equipment[item.slot]))
		section(home, content, "Compared with equipped", ["Power %+.1f  ·  HP %+.1f  ·  Armor %+.1f" % [stats.power - current.power, stats.hp - current.hp, stats.armor - current.armor]])
	var manage := HBoxContainer.new()
	manage.add_theme_constant_override("separation", 4)
	content.add_child(manage)
	var locked: bool = item.id in home.profile.data.locked_items
	var lock_button: Button = home.button("Unlock item" if locked else "Lock item", func(): home.refresh(func(): return home.profile.set_item_locked(item.id, not locked), "Item unlocked." if locked else "Item protected from salvage."), manage, 44)
	lock_button.disabled = not home.profile.can_change_loadout()
	lock_button.add_theme_font_size_override("font_size", 12)
	lock_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var merge: Button = home.button("Merge copies", func(): home.merge_donors = []; home.page = "merge"; home.confirmation = ""; home.rebuild(), manage, 44)
	merge.disabled = rank >= Content.RARITIES.find(Content.MERGE_MAX_RARITY) or not home.profile.can_change_loadout()
	merge.add_theme_font_size_override("font_size", 12)
	merge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var substat_button: Button = home.button("Substats", func(): home.page = "substats"; home.confirmation = ""; home.selected_affix = ""; home.rebuild(), manage, 44)
	substat_button.add_theme_font_size_override("font_size", 12)
	substat_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if not equipped:
		var protection: String = home.profile.salvage_block_reason(item.id)
		var salvage: Button = home.button(protection if not protection.is_empty() else "Salvage for %d parts" % (2 + rank + int(item.level) - 1), func():
			if home.confirmation == "salvage":
				home.refresh(func(): return home.profile.salvage(item.id), "Item salvaged.")
			else:
				home.confirmation = "salvage"; home.message = "Tap salvage again to permanently dismantle this item."; home.rebuild(), content, 44)
		salvage.disabled = not home.profile.can_change_loadout() or not protection.is_empty()
		if home.confirmation == "salvage":
			label(content, home.message, 13, Color("ffd27c"))
	var cost: Dictionary = home.profile.upgrade_cost(item.id)
	var cost_strip := PanelContainer.new()
	cost_strip.position = Vector2(36, 568)
	cost_strip.size = Vector2(358, 35)
	var cost_face: StyleBoxFlat = home.style(Color("08357c"), Color("1f62a8"))
	cost_face.set_content_margin_all(3)
	cost_strip.add_theme_stylebox_override("panel", cost_face)
	overlay.add_child(cost_strip)
	var costs := HBoxContainer.new()
	costs.add_theme_constant_override("separation", 12)
	cost_strip.add_child(costs)
	if cost.is_empty():
		label(costs, "Level cap reached · Level 5 / 5", 16)
	else:
		for currency in ["credits", "parts"]:
			var cost_row := HBoxContainer.new()
			cost_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			costs.add_child(cost_row)
			var currency_icon := Art.picture(cost_row, Art.item(currency), Rect2(0, 0, 25, 30))
			currency_icon.custom_minimum_size = Vector2(25, 30)
			label(cost_row, "%s / %d" % [home.compact_amount(home.profile.data[currency]), cost[currency]], 17, Color("f2f2ff") if home.profile.data[currency] >= cost[currency] else Color("ffafbd")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var actions := HBoxContainer.new()
	actions.position = Vector2(30, 625)
	actions.size = Vector2(370, 60)
	actions.add_theme_constant_override("separation", 6)
	overlay.add_child(actions)
	var equip: Button = home.button("Equipped" if equipped else "Equip", func(): home.refresh(func(): return home.profile.equip(item.id), "Equipment changed."), actions, 60)
	equip.name = "EquipItem"
	equip.disabled = equipped or not home.profile.can_change_loadout()
	var upgrade: Button = home.button("Upgrade", func(): home.refresh(func(): return home.profile.upgrade_item(item.id), "Equipment upgraded."), actions, 60)
	upgrade.name = "UpgradeItem"
	upgrade.disabled = cost.is_empty() or not home.profile.can_change_loadout() or home.profile.data.credits < cost.get("credits", 0) or home.profile.data.parts < cost.get("parts", 0)
	var quick_cost: Dictionary = home.profile.quick_upgrade_cost(item.id) if home.profile.has_method("quick_upgrade_cost") else {}
	var quick: Button = home.button("Confirm\nUpgrade" if home.confirmation == "quick_upgrade" else "Quick\nUpgrade", func():
		if home.confirmation == "quick_upgrade":
			home.refresh(func(): return home.profile.quick_upgrade_item(item.id), "Equipment upgraded.")
		else:
			home.confirmation = "quick_upgrade"
			home.message = "Upgrade %d levels · %d credits + %d parts" % [quick_cost.get("levels", 0), quick_cost.get("credits", 0), quick_cost.get("parts", 0)]
			home.rebuild(), actions, 60)
	quick.name = "QuickUpgradeItem"
	quick.disabled = quick_cost.get("levels", 0) <= 0 or not home.profile.can_change_loadout()
	for index in 3:
		var action: Button = actions.get_child(index)
		action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		action.add_theme_font_size_override("font_size", 17)
		action.add_theme_color_override("font_outline_color", Color("213055"))
		action.add_theme_constant_override("outline_size", 3)
		var action_style := StyleBoxTexture.new()
		action_style.texture = ACTION_FACES[index]
		action_style.set_texture_margin_all(13)
		action_style.set_content_margin_all(6)
		action.add_theme_stylebox_override("normal", action_style)
		var hover_face := action_style.duplicate()
		hover_face.modulate_color = Color(1.1, 1.1, 1.1)
		action.add_theme_stylebox_override("hover", hover_face)
		var pressed_face := action_style.duplicate()
		pressed_face.modulate_color = Color("c2cde1")
		action.add_theme_stylebox_override("pressed", pressed_face)
		var disabled_face := action_style.duplicate()
		disabled_face.texture = ACTION_DISABLED
		action.add_theme_stylebox_override("disabled", disabled_face)
		action.add_theme_color_override("font_disabled_color", Color("a8b6d0"))
	var notice := label(overlay, home.profile.error if not home.profile.error.is_empty() else ("Finish your saved expedition to change equipment." if not home.profile.can_change_loadout() else home.message), 12, Color("ffd27c"))
	notice.position = Vector2(36, 605)
	notice.size = Vector2(358, 20)
	notice.clip_text = true
