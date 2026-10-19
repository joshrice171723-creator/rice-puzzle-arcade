extends RefCounted
## Inventory tools share the profile's transactional equipment rules.
const Content = preload("res://haven_content.gd")

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
	home.text_line("Save your class and eight equipped items. Item upgrades carry over.", 13)
	var tabs := HBoxContainer.new()
	home.body.add_child(tabs)
	for slot: String in profile.BUILD_SLOTS:
		var node: Button = home.button("Build " + slot, func(): pick_build(home, slot), tabs, 38)
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		node.add_theme_color_override("font_color", Color("ffd27c") if slot == home.build_slot else Color("d6daea"))
	var name_input := LineEdit.new()
	name_input.name = "BuildName"
	name_input.placeholder_text = "Build name"
	name_input.max_length = 20
	name_input.text = home.build_name
	name_input.custom_minimum_size.y = 40
	name_input.editable = writable
	name_input.text_changed.connect(func(value: String): home.build_name = value)
	home.body.add_child(name_input)
	var class_id: String = build.get("class", profile.data["class"])
	home.text_line(("Saved: " if not build.is_empty() else "Current: ") + Content.CLASSES[class_id].name, 17)
	var grid := GridContainer.new()
	grid.name = "BuildEquipment"
	grid.columns = 4
	home.body.add_child(grid)
	var equipment: Dictionary = build.get("equipment", profile.data.equipment)
	for slot: String in Content.SLOTS:
		var item: Dictionary = profile.item_by_id(equipment[slot])
		var icon: Button = home.button("Lv.%d" % item.level, func(): pass, grid, 52)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.focus_mode = Control.FOCUS_NONE
		icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		home.decorate_item_button(icon, slot)
	home.text_line("Saved items are protected from salvage until you replace or clear the build.", 12)
	var actions := HBoxContainer.new()
	home.body.add_child(actions)
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
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.disabled = not writable
	var apply_button: Button = home.button("Equip build", func(): home.refresh(func(): return profile.apply_loadout(home.build_slot), "Saved class and equipment equipped."), actions)
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.disabled = not writable or build.is_empty()
	var bottom := HBoxContainer.new()
	home.body.add_child(bottom)
	var clear_button: Button = home.button("Confirm clear" if home.confirmation == "clear" else "Clear build", func():
		if home.confirmation != "clear":
			home.confirmation = "clear"
			home.message = "Tap again to clear this build. Your items stay in inventory."
			home.rebuild()
		else:
			home.refresh(func(): return profile.remove_loadout(home.build_slot), "Build cleared. Items kept."), bottom, 40)
	clear_button.disabled = not writable or build.is_empty()
	clear_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home.button("Back to equipment", func(): home.navigate("gear"), bottom, 40).size_flags_horizontal = Control.SIZE_EXPAND_FILL

static func filters(home: Control) -> void:
	home.text_line("Inventory filters", 24)
	home.text_line("Combine filters to find equipment. Your five-column inventory still scrolls vertically.", 13)
	home.text_line("Equipment slot", 16)
	var slot_picker := OptionButton.new()
	slot_picker.name = "SlotFilter"
	slot_picker.custom_minimum_size.y = 44
	slot_picker.add_item("All slots")
	for slot: String in Content.SLOTS:
		slot_picker.add_item(Content.SLOT_LABELS[slot])
	slot_picker.selected = Content.SLOTS.find(home.filter_slot) + 1
	slot_picker.item_selected.connect(func(index: int): home.filter_slot = "" if index == 0 else Content.SLOTS[index - 1]; home.inventory_scroll = 0; home.rebuild())
	home.body.add_child(slot_picker)
	home.text_line("Rarity", 16)
	var rarity_picker := OptionButton.new()
	rarity_picker.name = "RarityFilter"
	rarity_picker.custom_minimum_size.y = 44
	rarity_picker.add_item("All rarities")
	for rarity: String in Content.RARITIES:
		rarity_picker.add_item(rarity.capitalize())
	rarity_picker.selected = Content.RARITIES.find(home.filter_rarity) + 1
	rarity_picker.item_selected.connect(func(index: int): home.filter_rarity = "" if index == 0 else Content.RARITIES[index - 1]; home.inventory_scroll = 0; home.rebuild())
	home.body.add_child(rarity_picker)
	home.button("Locked only: " + ("On" if home.filter_locked else "Off"), func(): home.filter_locked = not home.filter_locked; home.inventory_scroll = 0; home.rebuild())
	home.text_line("%d matching items" % filtered_items(home).size(), 17)
	home.button("Reset filters", func(): home.filter_slot = ""; home.filter_rarity = ""; home.filter_locked = false; home.inventory_scroll = 0; home.rebuild())
	home.button("Show inventory", func(): home.navigate("gear"))
