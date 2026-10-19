extends RefCounted
const Loot = preload("res://loot.gd")
const Content = preload("res://haven_content.gd")
const UI = preload("res://armory_ui.gd")
const CHESTS = preload("res://assets/polish-v2/chests.png")
const KEY_ICON = preload("res://assets/menu-key.svg")
const CHEST_REGIONS := {"supply": Rect2(87,135,593,505), "weapons": Rect2(853,185,598,455), "armor": Rect2(90,868,587,540), "engineer": Rect2(847,968,610,440)}

static func chest_texture(category: String) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = CHESTS
	texture.region = CHEST_REGIONS[category]
	return texture

static func reward_row(home: Control, parent: Node, rewards: Dictionary) -> void:
	var line := UI.row(parent)
	line.alignment = BoxContainer.ALIGNMENT_CENTER
	for currency: String in rewards:
		UI.picture(line, KEY_ICON if currency == "cache_keys" else home.item_texture(currency), 26, 28)
		var number := UI.label(line, str(rewards[currency]), 17, Color("ffe4a4"))
		number.autowrap_mode = TextServer.AUTOWRAP_OFF
		number.tooltip_text = "%s %s reward" % [rewards[currency], currency.replace("_", " ")]

static func vertical_padding(column: VBoxContainer, padding: int) -> void:
	var shell: PanelContainer = column.get_parent()
	var face: StyleBox = shell.get_theme_stylebox("panel").duplicate()
	face.set_content_margin(SIDE_TOP, padding)
	face.set_content_margin(SIDE_BOTTOM, padding)
	shell.add_theme_stylebox_override("panel", face)

static func compact_action(node: Button, width: int = 260, height: int = 48) -> void:
	node.custom_minimum_size = Vector2(width, height)
	node.size_flags_horizontal = Control.SIZE_SHRINK_CENTER


static func show(home: Control) -> void:
	var data: Dictionary = home.profile.data
	home.text_line("Supply chests", 24)
	if home.cache_receipt:
		var item: Dictionary = data.last_cache.get("item", {})
		if not item.is_empty():
			var reveal := UI.panel(home.body, Color(Content.RARITY_COLORS[Content.RARITIES.find(item.rarity)]))
			var name_label := UI.label(reveal, item.name, 25, Color("fff0d4"))
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var stage := UI.row(reveal)
			stage.alignment = BoxContainer.ALIGNMENT_CENTER
			var portrait := UI.item_tile(home, stage, item, 156)
			portrait.custom_minimum_size.x = 156
			portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
			portrait.focus_mode = Control.FOCUS_NONE
			UI.label(reveal, "%s · Level %d" % [item.rarity.capitalize(), item.level], 18, Color(Content.RARITY_COLORS[Content.RARITIES.find(item.rarity)])).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			UI.label(reveal, "Added to your armory", 13).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			for affix: String in item.affixes:
				UI.label(reveal, Content.affix_text(item, affix), 13)
			var inspect: Button = home.button("Inspect equipment", func(): home.page = "gear"; home.selected_item = item.id; home.rebuild())
			home.MenuSkin.action(inspect, "gold")
			home.button("Back to chests", func(): home.cache_receipt = false; home.rebuild())
	else:
		var guarantees := UI.panel(home.body)
		vertical_padding(guarantees, 10)
		var heading := UI.row(guarantees)
		UI.picture(heading, KEY_ICON, 29, 30)
		UI.label(heading, "%d earned keys" % data.cache_keys, 20, Color("ffdb95")).size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI.label(guarantees, "Rare within %d · Epic within %d opens" % [10 - data.rare_misses, 30 - data.epic_misses], 15, Color("edf4ff"))
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		home.body.add_child(grid)
		for id: String in Loot.CATEGORIES:
			var category: Dictionary = Loot.CATEGORIES[id]
			var card := UI.panel(grid, Color("4269a3"), 4)
			vertical_padding(card, 10)
			card.add_theme_constant_override("separation", 2)
			card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var title := UI.label(card, category.name, 16, Color("fff0d4"))
			title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var imagery := UI.row(card)
			imagery.alignment = BoxContainer.ALIGNMENT_CENTER
			UI.picture(imagery, chest_texture(id), 90, 64)
			var description: String = "All equipment" if id == "supply" else ("Weapon" if id == "weapons" else ("Four armor slots" if id == "armor" else "Pendant · Gadget · Ring"))
			UI.label(card, description, 12).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var button: Button = home.button("Open · 1 key", func():
				var result: Dictionary = home.profile.open_cache(id)
				home.cache_receipt = not result.is_empty()
				home.message = "Equipment saved." if home.cache_receipt else home.profile.error
				home.rebuild(), card, 44)
			button.name = "Open_" + id
			button.tooltip_text = category.name + " · 1 earned key"
			home.MenuSkin.action(button, "gold")
			compact_action(button, 150, 44)
			button.add_theme_font_size_override("font_size", 16)
			button.disabled = data.cache_keys <= 0 or not home.profile.can_change_loadout()
		home.text_line("Common 55% · Uncommon 30% · Rare 13% · Epic 2%\nShared guarantees · Lv.1 drops · First clears earn keys.", 12)
	home.button("Back to Shop", func(): home.page = "shop"; home.selected_item = -1; home.rebuild(), null, 38)

static func rare_choice(home: Control) -> void:
	home.text_line("Choose your Rare reward", 23)
	home.text_line("Ten mastery medals. One guaranteed equipment piece, chosen by you.", 13)
	var choices := GridContainer.new()
	choices.columns = 4
	choices.add_theme_constant_override("h_separation", 6)
	choices.add_theme_constant_override("v_separation", 8)
	home.body.add_child(choices)
	for slot: String in Content.SLOTS:
		var name_value: String = Content.STARTER_NAMES[Content.SLOTS.find(slot)]
		var preview: Dictionary = {"slot": slot, "name": name_value, "rarity": "rare", "level": 1}
		var card := UI.panel(choices, Color("498cda"))
		card.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		UI.label(card, Content.SLOT_LABELS[slot], 12).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var button := UI.item_tile(home, card, preview, 76)
		button.text = "Choose"
		button.tooltip_text = "Rare " + name_value
		button.name = "RareChoice_" + slot
		button.pressed.connect(func():
			var item: Dictionary = home.profile.claim_rare_choice(slot)
			if not item.is_empty():
				home.page = "gear"
				home.selected_item = item.id
				home.message = "Your chosen equipment is saved."
			home.rebuild())
		button.disabled = home.profile.data.rare_choices <= 0 or not home.profile.can_change_loadout()
	var details := UI.panel(home.body)
	UI.label(details, "A piece that fits your build", 20, Color("ffdb95"))
	UI.label(details, "Rare equipment has a substat and can qualify for a set bonus. Claiming adds it to your inventory; your current gear stays equipped.", 14)
	home.button("Choose later", func(): home.page = "gear"; home.rebuild())

static func mission_rewards(home: Control) -> void:
	var mission: int = home.mission
	var base := Content.clear_rewards(mission)
	var medals: Array = home.profile.data.missions.get(str(mission), [])
	home.text_line(Content.MISSIONS[mission - 1].name, 23)
	var standard := UI.panel(home.body)
	UI.label(standard, "Every clear", 20, Color("ffdb95"))
	reward_row(home, standard, {"credits": base.credits, "parts": base.parts})
	UI.label(standard, "%d Survivor XP · %d Class Mastery XP" % [base.survivor_xp, base.mastery_xp], 13).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label(standard, "Uncommon Outrider Vest + 1 Breaker Plate guaranteed." if mission == 5 else "35% extra equipment chance · All slots · Common or Uncommon", 12)
	var first := UI.panel(home.body, Color("7057ab"))
	UI.label(first, "First clear" + (" · Claimed" if "clear" in medals else ""), 20, Color("d5b9ff"))
	reward_row(home, first, {"gems": 40 if mission == 5 else 10, "cache_keys": 1})
	var mastery := UI.panel(home.body)
	UI.label(mastery, "Zone mastery · %d / 15" % home.profile.total_medals(), 19, Color("ffdb95"))
	UI.label(mastery, "5 medals   495 Credits\n10 medals   20 Parts + choose Rare gear\n15 medals   35 Gems + Garage Lantern", 13)
	home.text_line("Each new Combat or Scavenger medal adds 55 Credits. Gathered currency, carried loot and Parts are extra.", 12)
	home.text_line("Defeat keeps gathered Credits and earned XP. Only protected backpack loot returns; no clear reward.", 12)
	home.button("Back to mission", func(): home.page = "mission"; home.rebuild(), null, 38)
