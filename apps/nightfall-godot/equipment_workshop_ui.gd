extends RefCounted
const Content = preload("res://haven_content.gd")

static func merge(home: Control) -> void:
	var profile: RefCounted = home.profile
	var item: Dictionary = profile.item_by_id(home.selected_item)
	if item.is_empty():
		home.navigate("gear")
		return
	home.text_line("Merge · " + item.name, 22)
	if Content.RARITIES.find(item.rarity) >= Content.RARITIES.find(Content.MERGE_MAX_RARITY):
		home.text_line("Maximum merge rarity for this zone.")
		home.button("Back to item", func(): home.page = "gear"; home.rebuild())
		return
	var next_rarity: String = Content.RARITIES[Content.RARITIES.find(item.rarity) + 1]
	home.text_line("3 matching %s items → 1 %s. Choose two copies to consume. No currency cost." % [item.rarity.capitalize(), next_rarity.capitalize()], 13)
	home.text_line("Keeps this item's substats and their ranks, plus the highest item level. New substat slots are filled automatically.", 12)
	var candidates: Array = profile.merge_candidates(item.id)
	var eligible: Array = candidates.map(func(candidate: Dictionary): return candidate.id)
	home.merge_donors = home.merge_donors.filter(func(id: int): return id in eligible)
	var result_level: int = item.level
	for id in home.merge_donors:
		result_level = maxi(result_level, profile.item_by_id(id).level)
	home.text_line("Result: %s · Level %d · %d/2 copies selected" % [next_rarity.capitalize(), result_level, home.merge_donors.size()], 16, Color("ffd27c"))
	var scroll := ScrollContainer.new()
	scroll.name = "MergeCopies"
	scroll.custom_minimum_size.y = 180
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	home.body.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
			home.rebuild(), list, 52)
		node.name = "Donor%d" % candidate.id
		node.add_theme_font_size_override("font_size", 12)
		node.disabled = not profile.can_change_loadout() or (not selected and home.merge_donors.size() == 2)
	if candidates.is_empty():
		var empty := Label.new()
		empty.text = "No eligible matching copies."
		list.add_child(empty)
	home.text_line("Equipped, locked and saved-build items cannot be consumed. Donor substats are lost.", 12)
	var merge_button: Button = home.button("Merge 3 → " + next_rarity.capitalize(), func(): home.refresh(func():
		var success: bool = profile.merge_items(item.id, home.merge_donors)
		if success:
			home.merge_donors = []
			home.page = "gear"
		return success, "Merged into " + next_rarity.capitalize() + "."))
	merge_button.name = "ConfirmMerge"
	merge_button.disabled = home.merge_donors.size() != 2 or not profile.can_change_loadout()
	home.button("Back to item", func(): home.page = "gear"; home.rebuild())

static func substats(home: Control) -> void:
	var profile: RefCounted = home.profile
	var item: Dictionary = profile.item_by_id(home.selected_item)
	if item.is_empty():
		home.navigate("gear")
		return
	home.text_line("Substats · " + item.name, 22)
	var affixes: Array = item.get("affixes", [])
	if affixes.is_empty():
		home.text_line("Merge to Uncommon to gain your first substat.", 14)
	else:
		if home.selected_affix not in affixes:
			home.selected_affix = affixes[0]
		for affix: String in affixes:
			var node: Button = home.button(Content.affix_text(item, affix), func(): home.selected_affix = affix; home.confirmation = ""; home.rebuild())
			node.add_theme_font_size_override("font_size", 12)
			node.add_theme_color_override("font_color", Color("ffd27c") if affix == home.selected_affix else Color("d6daea"))
		var selected: String = home.selected_affix
		var cost: Dictionary = profile.substat_cost(item.id, selected)
		var improve: Button = home.button("Substat at maximum rank" if cost.is_empty() else "Upgrade · %d credits + %d Parts" % [cost.credits, cost.parts], func(): home.refresh(func(): return profile.upgrade_substat(item.id, selected), "Substat upgraded."))
		improve.disabled = cost.is_empty() or not profile.can_change_loadout() or profile.data.credits < cost.get("credits", 0) or profile.data.parts < cost.get("parts", 0)
		var options: Array = profile.substat_options(item.id, selected)
		var names := PackedStringArray()
		for option: String in options:
			names.append(Content.AFFIXES[option].name)
		home.text_line("Reroll changes only this substat and keeps its rank. Equal chance of: " + ", ".join(names) + ".", 12)
		var reroll: Button = home.button(("Confirm reroll" if home.confirmation == "reroll" else "Reroll") + " · 100 credits + 5 Parts", func():
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
					return success, "Substat changed."))
		reroll.disabled = not profile.can_change_loadout() or options.is_empty() or profile.data.credits < 100 or profile.data.parts < 5
		home.text_line("Ranks improve a substat to 1.5× then 2× its base value. Overall speed and cooldown caps still apply.", 12)
	home.button("Back to item", func(): home.page = "gear"; home.rebuild())

static func sets(home: Control) -> void:
	home.text_line("Equipment sets", 24)
	home.text_line("Equip Rare or better pieces. Each slot counts once; the 2- and 3-piece bonuses stack. Armor chests can contain all three sets.", 13)
	var counts: Dictionary = home.profile.set_counts()
	for id: String in Content.SETS:
		var definition: Dictionary = Content.SETS[id]
		home.text_line("%s · %d/4 equipped" % [definition.name, counts[id]], 20, Color("ffd27c"))
		for threshold in [2, 3]:
			var active: bool = counts[id] >= threshold
			home.text_line("%d pieces: %s%s" % [threshold, definition.two if threshold == 2 else definition.three, " · Active" if active else ""], 13, Color("78adff") if active else Color("b8c5df"))
	home.text_line("Common and Uncommon pieces can be merged toward Rare. Substats do not change which set an item belongs to.", 12)
	home.button("Back to equipment", func(): home.navigate("gear"))
