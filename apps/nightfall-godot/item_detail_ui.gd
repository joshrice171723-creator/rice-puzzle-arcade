extends RefCounted
const Art = preload("res://haven_art.gd")
const Content = preload("res://haven_content.gd")
const MenuSkin = preload("res://menu_skin.gd")
static func label(parent: Node, text: String, font_size: int = 15, color: Color = Color("f2f2ff")) -> Label:
	var node := MenuSkin.label(parent, text, font_size, color)
	if font_size < 20:
		var body := MenuSkin.body_font()
		body.variation_embolden = 1.1
		node.add_theme_font_override("font", body)
	return node

static func section(home: Control, parent: Node, heading: String, lines: Array) -> void:
	var shell := PanelContainer.new()
	var material := MenuSkin.surface("inset")
	material.set_content_margin_all(3)
	shell.add_theme_stylebox_override("panel", material)
	parent.add_child(shell)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	shell.add_child(column)
	var header := PanelContainer.new()
	var header_face: StyleBoxFlat = home.style(Color("17396d"), Color("17396d"))
	header_face.set_corner_radius_all(4)
	header_face.set_content_margin_all(6)
	header.add_theme_stylebox_override("panel", header_face)
	column.add_child(header)
	label(header, heading, 15).add_theme_font_override("font", MenuSkin.DISPLAY)
	for index in lines.size():
		var row := PanelContainer.new()
		var row_face: StyleBoxFlat = home.style(Color("d1d3ef") if index % 2 == 0 else Color("bec3e2"), Color("b6bfdc"))
		row_face.set_border_width_all(0)
		row_face.set_corner_radius_all(0)
		row_face.set_content_margin_all(6)
		row.add_theme_stylebox_override("panel", row_face)
		column.add_child(row)
		label(row, lines[index], 14, Color("273453"))

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
	var surface := MenuSkin.surface("panel")
	panel.add_theme_stylebox_override("panel", surface)
	overlay.add_child(panel)
	var rank: int = Content.RARITIES.find(item.rarity)
	var ribbon := Panel.new()
	ribbon.position = Vector2(26, 126)
	ribbon.size = Vector2(378, 62)
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ribbon.add_theme_stylebox_override("panel", MenuSkin.surface("ribbon"))
	overlay.add_child(ribbon)
	var name_label := label(overlay, item.name, 26)
	name_label.position = Vector2(49, 139)
	name_label.size = Vector2(332, 35)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_outline_color", Color("142145"))
	name_label.add_theme_constant_override("outline_size", 4)
	var rarity := PanelContainer.new()
	rarity.position = Vector2(160, 179)
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
	close_button.position = Vector2(366, 151)
	close_button.custom_minimum_size = Vector2(44, 44)
	close_button.size = Vector2(44, 44)
	MenuSkin.action(close_button)
	close_button.add_theme_font_size_override("font_size", 28)
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
	art_panel.custom_minimum_size = Vector2(132, 136)
	var art_frame := StyleBoxTexture.new()
	art_frame.texture = Art.GEAR_FRAMES[rank]
	art_frame.set_texture_margin_all(12)
	art_frame.set_content_margin_all(8)
	art_panel.add_theme_stylebox_override("panel", art_frame)
	summary.add_child(art_panel)
	var portrait := TextureRect.new()
	portrait.texture = home.item_texture(item.slot, item)
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
		var stat_face: StyleBoxFlat = home.style(Color("c9c8eb"), Color("aebbe0"))
		stat_face.set_corner_radius_all(6)
		stat_face.set_content_margin_all(7)
		stat_row.add_theme_stylebox_override("panel", stat_face)
		stats_column.add_child(stat_row)
		label(stat_row, text, 18, Color("30334d")).add_theme_font_override("font", MenuSkin.DISPLAY)
	var equipped: bool = home.profile.data.equipment[item.slot] == item.id
	var set_id := Content.set_id(item)
	if not set_id.is_empty():
		var definition: Dictionary = Content.SETS[set_id]
		var count: int = home.profile.set_counts()[set_id]
		var set_lines: Array = []
		for threshold in [2, 3]:
			set_lines.append("%d pieces (%d/%d) · %s%s" % [threshold, mini(count, threshold), threshold, definition.two if threshold == 2 else definition.three, " · Active" if count >= threshold else ""])
		section(home, content, "%s set · %d Rare+ pieces" % [definition.name, count], set_lines)
	else:
		section(home, content, "Equipment effect", ["Once per expedition: restore %d%% maximum HP when a nonlethal hit leaves you at 25%% HP or below." % (25 if home.profile.data.facilities.infirmary == 2 else 20)] if item.slot == "gadget" else [Content.SLOT_LABELS[item.slot] + " · " + ("Currently equipped" if equipped else "Ready to equip")])
	if item.slot == "weapon":
		var weapons = preload("res://weapons.gd")
		var attack: Dictionary = weapons.TYPES[weapons.family(item)]
		section(home, content, "Automatic attack", [attack.description, "%.0f damage × %d · %.2fs · %s" % [stats.power * 0.6 * attack.scale, attack.count, attack.interval, "Elemental" if attack.elemental else "Physical"]])
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
	var cost_face: StyleBoxFlat = home.style(Color("0a2864"), Color("1a4d95"))
	cost_face.set_content_margin_all(3)
	cost_strip.add_theme_stylebox_override("panel", cost_face)
	overlay.add_child(cost_strip)
	if cost.is_empty():
		label(cost_strip, "Level cap reached · Level 5 / 5", 15)
	else:
		var costs := MenuSkin.cost_row(cost_strip, home.profile, cost)
		costs.add_theme_constant_override("separation", 12)
		var index := 0
		for currency in ["credits", "parts"]:
			var group: HBoxContainer = costs.get_child(index)
			group.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var amount: Label = group.get_child(1)
			amount.text = "%s / %d" % [home.compact_amount(home.profile.data[currency]), cost[currency]]
			amount.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var amount_font := MenuSkin.body_font()
			amount_font.variation_embolden = 1.1
			amount.add_theme_font_override("font", amount_font)
			amount.add_theme_font_size_override("font_size", 17)
			index += 1
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
		MenuSkin.action(action, ["blue", "gold", "gold" if home.confirmation == "quick_upgrade" else "blue"][index])
	var notice := label(overlay, home.profile.error if not home.profile.error.is_empty() else ("Finish your saved expedition to change equipment." if not home.profile.can_change_loadout() else home.message), 12, Color("ffd27c"))
	notice.position = Vector2(36, 605)
	notice.size = Vector2(358, 20)
	notice.clip_text = true
