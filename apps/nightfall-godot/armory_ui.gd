extends RefCounted
## Inventory tools share the profile's transactional equipment rules.
const Content = preload("res://haven_content.gd")
const Art = preload("res://haven_art.gd")
const MenuSkin = preload("res://menu_skin.gd")
const ClassShowcase = preload("res://class_showcase.gd")

static func label(parent: Node, value: String, font_size: int = 14, color: Color = Color("d9e6ff")) -> Label:
	return MenuSkin.label(parent, value, font_size, color)

static func panel(parent: Node, _tint: Color = Color("4269a3"), padding: int = 8) -> VBoxContainer:
	return MenuSkin.panel(parent, "panel", padding)

static func row(parent: Node) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override("separation", 8)
	parent.add_child(node)
	return node

static func picture(parent: Node, texture: Texture2D, width: int, height: int) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.custom_minimum_size = Vector2(width, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func cost(home: Control, parent: Node, values: Dictionary) -> void:
	MenuSkin.cost_row(parent, home.profile, values)

static func item_tile(home: Control, parent: Node, item: Dictionary, height: int = 72) -> Button:
	var node: Button = home.button("Lv.%d" % item.level, func(): pass, parent, height)
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.icon = home.item_texture(item.slot)
	node.expand_icon = true
	node.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	node.add_theme_constant_override("icon_max_width", height - 22)
	node.add_theme_font_size_override("font_size", 12)
	var frame := StyleBoxTexture.new()
	frame.texture = Art.GEAR_FRAMES[maxi(0, Content.RARITIES.find(item.rarity))]
	frame.set_texture_margin_all(7)
	frame.set_content_margin_all(5)
	node.add_theme_stylebox_override("normal", frame)
	var hovered := frame.duplicate()
	hovered.modulate_color = Color(1.15, 1.15, 1.15)
	node.add_theme_stylebox_override("hover", hovered)
	var pressed := frame.duplicate()
	pressed.modulate_color = Color("bdd5f5")
	node.add_theme_stylebox_override("pressed", pressed)
	var disabled := frame.duplicate()
	disabled.modulate_color = Color("8b99b3")
	node.add_theme_stylebox_override("disabled", disabled)
	node.tooltip_text = "%s · %s · Level %d" % [item.name, item.rarity.capitalize(), item.level]
	return node

static func item_heading(home: Control, parent: Node, item: Dictionary, subtitle: String) -> void:
	var heading := row(parent)
	var portrait := item_tile(home, heading, item, 82)
	portrait.custom_minimum_size.x = 82
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.focus_mode = Control.FOCUS_NONE
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(words)
	label(words, item.name, 19, Color("fff0d4"))
	label(words, "%s · Level %d" % [item.rarity.capitalize(), item.level], 14, Color(Content.RARITY_COLORS[maxi(0, Content.RARITIES.find(item.rarity))]))
	label(words, subtitle, 12)

static func filtered_items(home: Control) -> Array:
	return home.profile.data.inventory.filter(func(item: Dictionary):
		return (home.filter_slot.is_empty() or item.slot == home.filter_slot) \
			and (home.filter_rarity.is_empty() or item.rarity == home.filter_rarity) \
			and (not home.filter_locked or item.id in home.profile.data.locked_items))

static func pick_build(home: Control, slot: String) -> void:
	home.build_slot = slot
	home.build_name = home.profile.data.loadouts.get(slot, {}).get("name", ["Scavenging", "Survival", "Boss hunting"][int(slot) - 1])
	home.confirmation = ""
	home.message = ""
	home.page = "builds"
	home.rebuild()

static func builds(home: Control) -> void:
	var profile: RefCounted = home.profile
	var build: Dictionary = profile.data.loadouts.get(home.build_slot, {})
	var writable: bool = profile.can_change_loadout()
	home.text_line("Equipment builds", 24)
	var tabs := row(home.body)
	for slot: String in profile.BUILD_SLOTS:
		var node: Button = home.button("Build " + slot, func(): pick_build(home, slot), tabs, 44)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		MenuSkin.action(node, "gold" if slot == home.build_slot else "blue")
	var class_id: String = build.get("class", profile.data["class"])
	var stage := panel(home.body)
	var stage_row := row(stage)
	picture(stage_row, ClassShowcase.portrait_texture(class_id), 82, 90)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage_row.add_child(identity)
	label(identity, Content.CLASSES[class_id].name, 22, Color("fff0d4"))
	label(identity, "Saved loadout" if not build.is_empty() else "Current equipment preview", 13, Color("ffdb95"))
	label(identity, "Class + eight equipment slots", 12)
	var name_input := LineEdit.new()
	name_input.name = "BuildName"
	name_input.placeholder_text = "Name your build"
	name_input.max_length = 20
	name_input.text = home.build_name
	name_input.custom_minimum_size.y = 40
	name_input.editable = writable
	name_input.add_theme_stylebox_override("normal", MenuSkin.surface("panel"))
	name_input.add_theme_font_override("font", MenuSkin.body_font())
	name_input.add_theme_font_size_override("font_size", 15)
	name_input.text_changed.connect(func(value: String): home.build_name = value)
	home.body.add_child(name_input)
	var grid := GridContainer.new()
	grid.name = "BuildEquipment"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	home.body.add_child(grid)
	var equipment: Dictionary = build.get("equipment", profile.data.equipment)
	for slot: String in Content.SLOTS:
		var item: Dictionary = profile.item_by_id(equipment[slot])
		var icon := item_tile(home, grid, item, 61)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.focus_mode = Control.FOCUS_NONE
	home.text_line("Saved pieces are protected from salvage. Upgrades carry over.", 12)
	var actions := row(home.body)
	var save_button: Button = home.button("Confirm replace" if home.confirmation == "replace" else ("Save current" if build.is_empty() else "Replace with current"), func():
		if not build.is_empty() and home.confirmation != "replace":
			home.confirmation = "replace"
			home.message = "Tap again to replace this saved class and equipment."
			home.rebuild()
		elif home.build_name.strip_edges().is_empty():
			home.message = "Give this build a name first."
			home.rebuild()
		else:
			home.refresh(func(): return profile.save_loadout(home.build_slot, home.build_name), "Equipment build saved."), actions)
	MenuSkin.action(save_button, "gold")
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.disabled = not writable
	var apply_button: Button = home.button("Equip build", func(): home.refresh(func(): return profile.apply_loadout(home.build_slot), "Saved class and equipment equipped."), actions)
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.disabled = not writable or build.is_empty()
	var bottom := row(home.body)
	var clear_button: Button = home.button("Confirm clear" if home.confirmation == "clear" else "Clear build", func():
		if home.confirmation != "clear":
			home.confirmation = "clear"
			home.message = "Tap again to clear this build. Your items stay in inventory."
			home.rebuild()
		else:
			home.refresh(func(): return profile.remove_loadout(home.build_slot), "Build cleared. Items kept."), bottom, 44)
	clear_button.disabled = not writable or build.is_empty()
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.button("Back to equipment", func(): home.navigate("gear"), bottom, 44).size_flags_horizontal = Control.SIZE_EXPAND_FILL

static func filters(home: Control) -> void:
	home.text_line("Find equipment", 24)
	var banner := panel(home.body)
	var heading := row(banner)
	picture(heading, Art.icon("gear"), 62, 67)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(words)
	label(words, "%d matching items" % filtered_items(home).size(), 23, Color("fff0d4"))
	label(words, "Combine slot, rarity and lock filters.", 13)
	home.text_line("Equipment slot", 16, Color("ffdb95"))
	var slot_picker := OptionButton.new()
	slot_picker.name = "SlotFilter"
	slot_picker.custom_minimum_size = Vector2(300, 48)
	slot_picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slot_picker.add_item("All slots")
	for slot: String in Content.SLOTS:
		slot_picker.add_item(Content.SLOT_LABELS[slot])
	slot_picker.selected = Content.SLOTS.find(home.filter_slot) + 1
	slot_picker.item_selected.connect(func(index: int): home.filter_slot = "" if index == 0 else Content.SLOTS[index - 1]; home.inventory_scroll = 0; home.rebuild())
	MenuSkin.action(slot_picker)
	slot_picker.alignment = HORIZONTAL_ALIGNMENT_LEFT
	home.body.add_child(slot_picker)
	home.text_line("Rarity", 16, Color("ffdb95"))
	var rarity_picker := OptionButton.new()
	rarity_picker.name = "RarityFilter"
	rarity_picker.custom_minimum_size = Vector2(300, 48)
	rarity_picker.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rarity_picker.add_item("All rarities")
	for rarity: String in Content.RARITIES:
		rarity_picker.add_item(rarity.capitalize())
	rarity_picker.selected = Content.RARITIES.find(home.filter_rarity) + 1
	rarity_picker.item_selected.connect(func(index: int): home.filter_rarity = "" if index == 0 else Content.RARITIES[index - 1]; home.inventory_scroll = 0; home.rebuild())
	MenuSkin.action(rarity_picker)
	rarity_picker.alignment = HORIZONTAL_ALIGNMENT_LEFT
	home.body.add_child(rarity_picker)
	home.button("Locked only: " + ("On" if home.filter_locked else "Off"), func(): home.filter_locked = not home.filter_locked; home.inventory_scroll = 0; home.rebuild())
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	home.body.add_child(spacer)
	home.button("Reset filters", func(): home.filter_slot = ""; home.filter_rarity = ""; home.filter_locked = false; home.inventory_scroll = 0; home.rebuild())
	home.button("Show inventory", func(): home.navigate("gear"))
