extends RefCounted
const Content = preload("res://haven_content.gd")
const UI = preload("res://armory_ui.gd")
const ZoneOne = preload("res://zone_one.gd")
const Loot = preload("res://loot.gd")

static func crafting(home: Control) -> void:
	var profile: RefCounted = home.profile
	var unlocked := ZoneOne.craft_unlocked(profile.data.missions)
	home.text_line("Breaker Forge", 24)
	var scroll := ScrollContainer.new()
	scroll.name = "CraftRecipes"
	scroll.custom_minimum_size.y = 80
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	home.body.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	UI.label(column, "Defeat The Breaker to earn Plates. Choose your next piece.", 13)
	if not unlocked:
		UI.label(column, "Clear The Last Street to unlock crafting.", 15, Color("ffdb95"))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)
	for slot: String in Content.SLOTS:
		var item_preview := Loot.equipment(slot, "rare", int(profile.data.next_item))
		var choose := UI.item_tile(home, grid, item_preview, 76)
		choose.text = Content.SLOT_LABELS[slot]
		choose.name = "CraftSlot_" + slot
		choose.pressed.connect(func(): home.contract_slot = slot; home.confirmation = ""; home.rebuild())
		choose.add_theme_constant_override("icon_max_width", 47)
		if slot == home.contract_slot:
			var selected_frame := choose.get_theme_stylebox("normal").duplicate()
			selected_frame.modulate_color = Color("ffe4a4")
			choose.add_theme_stylebox_override("normal", selected_frame)
			choose.tooltip_text += " · Selected recipe"
	var preview := Loot.equipment(home.contract_slot, "rare", int(profile.data.next_item))
	var selected := UI.panel(column)
	UI.item_heading(home, selected, preview, "Chosen equipment · Not a random slot")
	for affix: String in preview.affixes:
		UI.label(selected, Content.affix_text(preview, affix), 12)
	UI.label(selected, "Breaker Plates  %d / %d" % [profile.data.breaker_plates, ZoneOne.CRAFT_COST.breaker_plates], 15, Color("ffdb95"))
	UI.cost(home, selected, {"credits": ZoneOne.CRAFT_COST.credits, "parts": ZoneOne.CRAFT_COST.parts})
	UI.label(selected, "Rare · Level 1 · Upgrades to Level 5. Does not consume existing equipment.", 12)
	var confirm: Button = home.button("Confirm craft" if home.confirmation == "craft" else "Craft Rare equipment", func():
		if home.confirmation != "craft":
			home.confirmation = "craft"
			home.message = "Tap Confirm craft to spend 8 Plates, 330 Credits and 5 Parts."
			home.rebuild()
		else:
			home.refresh(func(): return not profile.craft_zone_item(home.contract_slot).is_empty(), preview.name + " forged."))
	confirm.name = "ConfirmCraft"
	home.MenuSkin.action(confirm, "gold")
	confirm.disabled = not unlocked or not profile.can_change_loadout()
	for currency: String in ZoneOne.CRAFT_COST:
		if profile.data[currency] < ZoneOne.CRAFT_COST[currency]:
			confirm.disabled = true
	home.button("Back to Workshop", func(): home.facility = "workshop"; home.navigate("facility"), null, 40)

static func merge(home: Control) -> void:
	var profile: RefCounted = home.profile
	var item: Dictionary = profile.item_by_id(home.selected_item)
	if item.is_empty():
		home.navigate("gear")
		return
	home.text_line("Merge equipment", 24)
	UI.item_heading(home, home.body, item, "This is the piece you keep.")
	if Content.RARITIES.find(item.rarity) >= Content.RARITIES.find(Content.MERGE_MAX_RARITY):
		var complete := UI.panel(home.body)
		UI.label(complete, "Maximum merge rarity", 21, Color("ffdb95"))
		UI.label(complete, "This zone supports merges up to Epic. Your equipment is already there.", 14)
		home.button("Back to item", func(): home.page = "gear"; home.rebuild())
		return
	var next_rarity: String = Content.RARITIES[Content.RARITIES.find(item.rarity) + 1]
	var candidates: Array = profile.merge_candidates(item.id)
	var eligible: Array = candidates.map(func(candidate: Dictionary): return candidate.id)
	home.merge_donors = home.merge_donors.filter(func(id: int): return id in eligible)
	var result_level: int = item.level
	for id in home.merge_donors:
		result_level = maxi(result_level, profile.item_by_id(id).level)
	var result := UI.panel(home.body, Color(Content.RARITY_COLORS[Content.RARITIES.find(next_rarity)]))
	var summary := UI.row(result)
	var result_item: Dictionary = item.duplicate(true)
	result_item.rarity = next_rarity
	result_item.level = result_level
	var portrait := UI.item_tile(home, summary, result_item, 65)
	portrait.custom_minimum_size.x = 65
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var summary_words := VBoxContainer.new()
	summary_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary.add_child(summary_words)
	UI.label(summary_words, "%s · Level %d" % [next_rarity.capitalize(), result_level], 20, Color("ffdb95"))
	UI.label(summary_words, "%d/2 copies selected · No currency cost" % home.merge_donors.size(), 13)
	UI.label(result, "Keeps this piece's substats and ranks, plus the highest level. New substat slots fill automatically.", 12)
	var merge_eligible: bool = profile.data.equipment[item.slot] != item.id or profile.equipment_eligible(result_item)
	if not merge_eligible:
		UI.label(result,profile.equipment_requirement_reason(result_item)+". Equip another piece before merging.",13,Color("ffca88"))
	var scroll := ScrollContainer.new()
	scroll.name = "MergeCopies"
	scroll.custom_minimum_size.y = 100
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	home.body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 6)
	scroll.add_child(list)
	for candidate: Dictionary in candidates:
		var selected: bool = candidate.id in home.merge_donors
		var details := PackedStringArray()
		for affix: String in candidate.get("affixes", []):
			details.append("%s %d/3" % [Content.AFFIXES[affix].name, Content.affix_rank(candidate, affix)])
		var caption := ("Selected · " if selected else "") + "Level %d\n" % candidate.level + (", ".join(details) if not details.is_empty() else "No substats")
		var node: Button = home.button(caption, func():
			if selected:
				home.merge_donors.erase(candidate.id)
			elif home.merge_donors.size() < 2:
				home.merge_donors.append(candidate.id)
			home.rebuild(), list, 64)
		node.name = "Donor%d" % candidate.id
		home.decorate_item_button(node, candidate.slot, candidate)
		node.add_theme_font_size_override("font_size", 13)
		if selected:
			home.MenuSkin.action(node, "gold")
		node.add_theme_font_size_override("font_size", 13)
		node.disabled = not profile.can_change_loadout() or (not selected and home.merge_donors.size() == 2)
	if candidates.is_empty():
		var empty := UI.panel(list)
		UI.label(empty, "No matching copies yet", 19, Color("ffdb95"))
		UI.label(empty, "Find two more %s %s pieces in chests or expeditions." % [item.rarity.capitalize(), item.name], 13)
	home.text_line("Equipped, locked and saved-build copies are protected. Selected copies and their substats are consumed.", 12)
	var merge_button: Button = home.button("Merge 3 → " + next_rarity.capitalize(), func(): home.refresh(func():
		var success: bool = profile.merge_items(item.id, home.merge_donors)
		if success:
			home.merge_donors = []
			home.page = "gear"
		return success, "Merged into " + next_rarity.capitalize() + "."))
	merge_button.name = "ConfirmMerge"
	home.MenuSkin.action(merge_button, "gold")
	merge_button.disabled = not merge_eligible or home.merge_donors.size() != 2 or not profile.can_change_loadout()
	home.button("Back to item", func(): home.page = "gear"; home.rebuild(), null, 38)

static func substats(home: Control) -> void:
	var profile: RefCounted = home.profile
	var item: Dictionary = profile.item_by_id(home.selected_item)
	if item.is_empty():
		home.navigate("gear")
		return
	home.text_line("Tune substats", 24)
	UI.item_heading(home, home.body, item, "Choose a trait to improve or change.")
	var affixes: Array = item.get("affixes", [])
	if affixes.is_empty():
		var empty := UI.panel(home.body)
		UI.picture(empty, home.Art.icon("workshop"), 80, 86)
		UI.label(empty, "No substats yet", 21, Color("ffdb95"))
		UI.label(empty, "Merge this piece to Uncommon to gain its first trait.", 14)
	else:
		if home.selected_affix not in affixes:
			home.selected_affix = affixes[0]
		var scroll := ScrollContainer.new()
		scroll.name = "SubstatWorkbench"
		scroll.custom_minimum_size.y = 100
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		home.body.add_child(scroll)
		var workbench := VBoxContainer.new()
		workbench.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		workbench.add_theme_constant_override("separation", 8)
		scroll.add_child(workbench)
		var selection := UI.panel(workbench)
		for affix: String in affixes:
			var node: Button = home.button(Content.affix_text(item, affix), func(): home.selected_affix = affix; home.confirmation = ""; home.rebuild(), selection, 44)
			node.add_theme_font_size_override("font_size", 13)
			if affix == home.selected_affix:
				home.MenuSkin.action(node, "gold")
			node.add_theme_font_size_override("font_size", 13)
		var selected: String = home.selected_affix
		var cost: Dictionary = profile.substat_cost(item.id, selected)
		var tuning := UI.panel(workbench)
		var rank: int = Content.affix_rank(item, selected)
		UI.label(tuning, "Rank %d / 3" % rank, 18, Color("ffdb95"))
		var progress := ProgressBar.new()
		progress.max_value = 3
		progress.value = rank
		progress.show_percentage = false
		progress.custom_minimum_size.y = 8
		home.MenuSkin.progress(progress)
		tuning.add_child(progress)
		if not cost.is_empty():
			UI.cost(home, tuning, cost)
		var improve: Button = home.button("Substat at maximum rank" if cost.is_empty() else "Upgrade · Rank " + str(rank + 1), func(): home.refresh(func(): return profile.upgrade_substat(item.id, selected), "Substat upgraded."), tuning, 48)
		home.MenuSkin.action(improve, "gold")
		improve.custom_minimum_size = Vector2(260, 48)
		improve.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		improve.disabled = cost.is_empty() or not profile.can_change_loadout() or profile.data.credits < cost.get("credits", 0) or profile.data.parts < cost.get("parts", 0)
		var options: Array = profile.substat_options(item.id, selected)
		var names := PackedStringArray()
		for option: String in options:
			names.append(Content.AFFIXES[option].name)
		var reroll_card := UI.panel(workbench)
		UI.label(reroll_card, "Replace trait · Keep rank %d" % rank, 17)
		UI.label(reroll_card, "Equal chance: " + ", ".join(names) + ".", 12)
		UI.cost(home, reroll_card, {"credits": 100, "parts": 5})
		var reroll: Button = home.button("Confirm reroll" if home.confirmation == "reroll" else "Reroll · Selected trait", func():
			if home.confirmation != "reroll":
				home.confirmation = "reroll"
				home.message = "Tap again to replace this substat. Its upgrade rank is kept."
				home.rebuild()
			else:
				var index := affixes.find(selected)
				home.refresh(func():
					var success: bool = profile.reroll_substat(item.id, selected)
					if success:
						home.selected_affix = item.affixes[index]
					return success, "Substat changed."), reroll_card, 48)
		reroll.custom_minimum_size = Vector2(260, 48)
		reroll.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		reroll.disabled = not profile.can_change_loadout() or options.is_empty() or profile.data.credits < 100 or profile.data.parts < 5
		UI.label(workbench, "Ranks: 1× / 1.5× / 2× base effect. Speed and cooldown caps still apply.", 12)
	home.button("Back to item", func(): home.page = "gear"; home.rebuild(), null, 38)

static func sets(home: Control) -> void:
	home.text_line("Equipment sets", 24)
	home.text_line("Rare or better pieces activate bonuses. Each equipped slot counts once.", 13)
	var counts: Dictionary = home.profile.set_counts()
	for id: String in Content.SETS:
		var definition: Dictionary = Content.SETS[id]
		var card := UI.panel(home.body, Color("7057ab") if counts[id] >= 2 else Color("4269a3"))
		var heading := UI.row(card)
		var equipped_art: String = "body" if id == "outrider" else ("helmet" if id == "ironwatch" else "charm")
		UI.picture(heading, home.item_texture(equipped_art), 53, 55)
		var words := VBoxContainer.new()
		words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(words)
		UI.label(words, definition.name, 21, Color("fff0d4"))
		UI.label(words, "%d/4 qualifying pieces equipped" % counts[id], 12, Color("ffdb95"))
		for threshold in [2, 3]:
			var active: bool = counts[id] >= threshold
			UI.label(card, "%d pieces  %s%s" % [threshold, definition.two if threshold == 2 else definition.three, " · Active" if active else ""], 13, Color("93caff") if active else Color("c6d5ed"))
	home.text_line("Both bonuses stack. New Outskirts chests contain Outrider armor. Existing Ironwatch and Riftweaver gear keeps its bonuses.", 12)
	home.button("Back to equipment", func(): home.navigate("gear"), null, 40)
