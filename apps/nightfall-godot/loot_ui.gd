extends RefCounted
const Loot = preload("res://loot.gd")
const Content = preload("res://haven_content.gd")

static func show(home: Control) -> void:
	var data: Dictionary = home.profile.data
	home.text_line("SUPPLY CHESTS", 22, Color("ffd27c"))
	home.text_line("%d earned keys" % data.cache_keys, 18)
	if home.cache_receipt:
		var item: Dictionary = data.last_cache.get("item", {})
		if not item.is_empty():
			home.item_portrait(item.slot)
			home.text_line("Added to your armory", 14)
			home.text_line(item.name, 24, Color(Content.RARITY_COLORS[Content.RARITIES.find(item.rarity)]))
			home.text_line("%s • Level %d" % [item.rarity.capitalize(), item.level], 17)
			for affix in item.affixes:
				home.text_line(Content.AFFIXES[affix].description)
			home.button("Inspect equipment", func(): home.page = "gear"; home.selected_item = item.id; home.rebuild())
			home.button("Back to chests", func(): home.cache_receipt = false; home.rebuild())
	else:
		home.text_line("Each first mission clear earns a key. Choose the equipment category before spending it.", 13)
		home.text_line("Rare or better within %d • Epic within %d\nGuarantees are shared across all four chests." % [10 - data.rare_misses, 30 - data.epic_misses], 13, Color("ba92ff"))
		for id: String in Loot.CATEGORIES:
			var category: Dictionary = Loot.CATEGORIES[id]
			var description: String = "All eight slots" if id == "supply" else ", ".join(category.slots).capitalize()
			var button: Button = home.button(category.name + " • 1 key\n" + description, func():
				var result: Dictionary = home.profile.open_cache(id)
				home.cache_receipt = not result.is_empty()
				home.message = "Equipment saved." if home.cache_receipt else home.profile.error
				home.rebuild(), null, 56)
			button.disabled = data.cache_keys <= 0 or not home.profile.can_change_loadout()
			home.decorate_item_button(button, "chest")
		home.text_line("Base odds: Common 55%, Uncommon 30%, Rare 13%, Epic 2%. Guarantees can raise the minimum rarity. All items start at level 1; zone level caps apply.", 12)
	home.button("Back to Shop", func(): home.page = "shop"; home.selected_item = -1; home.rebuild(), null, 40)

static func rare_choice(home: Control) -> void:
	home.text_line("YOUR OUTSKIRTS REWARD", 21, Color("ffd27c"))
	home.text_line("Ten mastery medals earned a Rare equipment choice. Pick the slot your build needs. This is a guaranteed item, not a random chest.")
	var choices := GridContainer.new()
	choices.columns = 2
	home.body.add_child(choices)
	for slot in Content.SLOTS:
		var name_value: String = Content.STARTER_NAMES[Content.SLOTS.find(slot)]
		var button: Button = home.button("Rare " + name_value, func():
			var item: Dictionary = home.profile.claim_rare_choice(slot)
			if not item.is_empty():
				home.page = "gear"
				home.selected_item = item.id
				home.message = "Your chosen equipment is saved."
			home.rebuild(), choices, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 12)
		button.disabled = home.profile.data.rare_choices <= 0 or not home.profile.can_change_loadout()
		home.decorate_item_button(button, slot)
	home.button("Choose later", func(): home.page = "gear"; home.rebuild())

static func mission_rewards(home: Control) -> void:
	var mission: int = home.mission
	var base := Content.clear_rewards(mission)
	var medals: Array = home.profile.data.missions.get(str(mission), [])
	home.text_line(Content.MISSIONS[mission - 1].name, 22, Color("ffd27c"))
	home.text_line("EVERY CLEAR", 15, Color("ba92ff"))
	home.text_line("%d credits • %d Parts\n%d Survivor XP • %d Class Mastery XP" % [base.credits, base.parts, base.survivor_xp, base.mastery_xp])
	home.text_line("Guaranteed Uncommon Outrider Vest + 1 Breaker Plate." if mission == 5 else "35% chance of an extra equipment drop. All eight slots can drop; Common or Uncommon.", 13)
	home.text_line("FIRST CLEAR", 15, Color("ba92ff"))
	home.text_line("Already claimed." if "clear" in medals else "%d gems + 1 supply key." % (40 if mission == 5 else 10))
	home.text_line("EXTRA REWARDS", 15, Color("ba92ff"))
	home.text_line("Each new Combat or Scavenger medal: +55 credits. Gathered credits, carried equipment and Parts are added to your clear rewards.", 13)
	home.text_line("ZONE MASTERY • %d/15" % home.profile.total_medals(), 15, Color("ba92ff"))
	home.text_line("5 medals: 495 credits\n10 medals: 20 Parts + your choice of Rare gear\n15 medals: 35 gems + Garage Lantern cosmetic", 13)
	home.text_line("On defeat: gathered credits and earned XP remain; only protected backpack loot returns. No clear reward.", 13)
	home.button("Back to mission", func(): home.page = "mission"; home.rebuild())
