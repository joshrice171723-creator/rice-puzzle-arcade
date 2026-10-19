extends SceneTree
const Profile = preload("res://profile.gd")
const Run = preload("res://run.gd")
const Content = preload("res://haven_content.gd")
const PATH := "user://nightfall_equipment_workshop_test.json"
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func add_item(p: RefCounted, slot: String, rarity: String, armor_set: String = "outrider") -> Dictionary:
	var item: Dictionary = p.Loot.equipment(slot, rarity, p.data.next_item, armor_set)
	p.data.next_item += 1
	p.data.inventory.append(item)
	return item

func _initialize() -> void:
	call_deferred("verify")

func settle() -> void:
	for frame in 6:
		await process_frame

func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := find_button(child, prefix)
		if found != null:
			return found
	return null

func verify() -> void:
	cleanup()
	var p = Profile.new(PATH)
	p.data.credits = 10000
	p.data.parts = 1000
	var target := add_item(p, "weapon", "rare")
	target.affixes = ["tempered"]
	target.affix_levels = {"tempered": 2}
	target.level = 2
	var a := add_item(p, "weapon", "rare")
	a.affixes = ["attuned"]
	a.level = 4
	var b := add_item(p, "weapon", "rare")
	b.affixes = ["seeking"]
	var wrong := add_item(p, "ring", "rare")
	check(p.equip(target.id) and p.save_loadout("1", "Keep") and p.set_item_locked(target.id, true), "Target remains safely equipped and saved")
	check(not p.merge_items(target.id, [a.id, a.id]) and not p.merge_items(target.id, [target.id, b.id]) and not p.merge_items(target.id, [a.id, wrong.id]), "Merge rejects duplicate, self and wrong-type donors")
	check(p.set_item_locked(a.id, true) and not p.merge_items(target.id, [a.id, b.id]), "Locked donor cannot be consumed")
	p.set_item_locked(a.id, false)
	p.equip(a.id)
	p.save_loadout("2", "Other")
	check(not p.merge_items(target.id, [a.id, b.id]), "Equipped donor cannot be consumed")
	p.equip(target.id)
	check(not p.merge_items(target.id, [a.id, b.id]), "Unequipped saved-build donor cannot be consumed")
	p.remove_loadout("2")
	var before: Dictionary = p.data.duplicate(true)
	p.path = "user://missing-equipment-workshop-dir/save.json"
	check(not p.merge_items(target.id, [a.id, b.id]) and p.data == before, "Merge write failure restores donors and target")
	p.path = PATH
	p.error = ""
	check(p.merge_items(target.id, [a.id, b.id]), "Different substats still count as identical items for merging")
	target = p.item_by_id(target.id)
	check(target.rarity == "epic" and target.level == 4 and "tempered" in target.affixes and target.affix_levels.tempered == 2 and target.affixes.size() == 2, "Epic result preserves target substat ranks, highest level and fills new slot")
	check(p.item_by_id(a.id).is_empty() and p.item_by_id(b.id).is_empty() and p.data.inventory.size() == before.inventory.size() - 2, "Three copies become exactly one item")
	check(p.data.equipment.weapon == target.id and p.data.loadouts["1"].equipment.weapon == target.id and target.id in p.data.locked_items, "Upgrade preserves equipped/build references and target lock")
	check(p.data.credits == before.credits and p.data.parts == before.parts and not p.merge_items(target.id, [a.id, b.id]), "Merge costs no currency and cannot replay consumed donors")
	check(p.upgrade_substat(target.id, "tempered") and p.item_by_id(target.id).affix_levels.tempered == 3, "Substat upgrade advances one rank")
	target = p.item_by_id(target.id)
	check(is_equal_approx(Content.item_stats(target).power, 40 * 1.15 * 1.12 * 1.06), "Rank 3 tempered gives exactly 6% item power")
	check(not p.upgrade_substat(target.id, "tempered"), "Substat rank is capped at three")
	var untouched: String = target.affixes[1]
	before = p.data.duplicate(true)
	p.path = "user://missing-equipment-workshop-dir/save.json"
	check(not p.reroll_substat(target.id, "tempered") and p.data == before, "Failed reroll restores currency, RNG counter and substat")
	p.path = PATH
	check(p.reroll_substat(target.id, "tempered"), "Reroll changes selected substat")
	target = p.item_by_id(target.id)
	check(target.affixes[0] != "tempered" and target.affixes[0] != untouched and target.affixes[1] == untouched and Content.affix_rank(target, target.affixes[0]) == 3, "Reroll preserves rank and other affixes without duplicates")
	check(p.data.credits == before.credits - 100 and p.data.parts == before.parts - 5 and p.data.affix_rolls == before.affix_rolls + 1, "Reroll charges exactly displayed cost once")
	check(p.valid(p.data), "Merged and tuned inventory validates")
	var loaded = Profile.new(PATH)
	check(loaded.load_save() and loaded.data == p.data, "Merge/substat/build/lock data persist after restart")
	for tier in range(0, 3):
		var copies: Array = []
		for index in 3:
			copies.append(add_item(p, "gadget", Content.RARITIES[tier]))
		check(p.merge_items(copies[0].id, [copies[1].id, copies[2].id]) and p.item_by_id(copies[0].id).rarity == Content.RARITIES[tier + 1], "Three-copy transition works for " + Content.RARITIES[tier])
		check(p.valid(p.data), "Rarity transition retains valid distinct substats")
	var mythic := add_item(p, "ring", "mythic")
	check(p.merge_candidates(mythic.id).is_empty(), "Mythic is a terminal rarity")
	var epic_copies: Array = []
	for index in 3:
		epic_copies.append(add_item(p, "ring", "epic").id)
	check(not p.merge_items(epic_copies[0], epic_copies.slice(1)) and p.merge_candidates(epic_copies[0]).is_empty(), "Zone 1 cannot merge Epic loot into endgame rarities")
	var capped = Profile.new(PATH)
	for item: Dictionary in capped.data.inventory:
		item.rarity = "rare"
		item.affixes = ["seeking"]
		item.affix_levels = {"seeking": 3}
	check(is_equal_approx(capped.stats().pickup, 1.50), "Stacked pickup substats and class/set bonuses respect permanent cap")
	var extra := add_item(p, "helmet", "rare", "ironwatch")
	var different := add_item(p, "helmet", "rare", "riftweaver")
	check(different not in p.merge_candidates(extra.id), "Same slot and rarity but different named set piece cannot merge")
	for set_id: String in Content.SETS:
		var fixture = Profile.new(PATH)
		var base: Dictionary = fixture.stats()
		for index in 3:
			var item := add_item(fixture, Content.ARMOR_SLOTS[index], "rare", set_id)
			item.affixes = []
			fixture.data.equipment[item.slot] = item.id
			check(fixture.set_counts()[set_id] == index + 1, "Set counts distinct equipped qualifying slots")
		var stats: Dictionary = fixture.stats()
		if set_id == "outrider":
			check(is_equal_approx(stats.pickup, base.pickup + 0.15) and stats.secure == 3, "Outrider activates pickup and protected-slot bonuses")
		elif set_id == "ironwatch":
			check(is_equal_approx(stats.armor, 30 * 1.08 + 5 + 12) and is_equal_approx(stats.hp, (120 + 70 * 1.08 + 20) * 1.06), "Ironwatch adds 12 armor and 6% total HP once")
		else:
			var run = Run.new()
			run.configure(1, stats)
			check(is_equal_approx(run.spell_scale(), 1.03) and is_equal_approx(run.spell_cooldown("frost"), 7.68), "Riftweaver bonuses change actual spell damage and cooldown")
			check(is_equal_approx(run.spell_multiplier, 1.0), "Spell-only bonus does not increase structure power")
			var resumed = Run.new()
			check(resumed.restore(run.snapshot()) and is_equal_approx(resumed.spell_scale(), 1.03), "Spell-only set bonus survives a checkpoint")
		fixture.data.inventory.back().rarity = "uncommon"
		check(fixture.set_counts()[set_id] == 2, "Below-Rare gear does not activate third-piece bonus")
	var set_drops := {"outrider": 0, "ironwatch": 0, "riftweaver": 0}
	for seed_value in 600:
		var roll: Dictionary = p.Loot.roll("armor", seed_value, 0, 0, seed_value)
		set_drops[Content.set_id(roll.item)] += 1
	check(set_drops.outrider == 600 and set_drops.ironwatch == 0 and set_drops.riftweaver == 0, "New Outskirts armor drops stay local while legacy sets retain their effects")
	p.data.active_attempt = {"id": 100}
	before = p.data.duplicate(true)
	check(not p.reroll_substat(target.id, target.affixes[0]) and not p.upgrade_substat(target.id, untouched) and not p.merge_items(extra.id, []) and p.data == before, "Saved expeditions prevent workshop changes")
	p.data.active_attempt = {}
	p.error = ""
	# Exercise real menu signals with disposable inventory, never the player's save.
	var ui_target := add_item(p, "body", "rare")
	var ui_a := add_item(p, "body", "rare")
	var ui_b := add_item(p, "body", "rare")
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	arena.profile = p
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	var home: Control = arena.home
	home.page = "gear"
	home.selected_item = ui_target.id
	home.rebuild()
	await settle()
	find_button(home, "Merge copies").pressed.emit()
	await settle()
	var list: Node = home.body.get_node("MergeCopies").get_child(0)
	list.get_node("Donor%d" % ui_a.id).pressed.emit()
	await settle()
	list = home.body.get_node("MergeCopies").get_child(0)
	list.get_node("Donor%d" % ui_b.id).pressed.emit()
	await settle()
	check(not home.body.get_node("ConfirmMerge").disabled, "Selecting two donor copies enables reviewed merge")
	home.body.get_node("ConfirmMerge").pressed.emit()
	await settle()
	check(p.item_by_id(ui_target.id).rarity == "epic" and home.page == "gear", "Merge menu consumes chosen copies and returns result")
	find_button(home, "Substats").pressed.emit()
	await settle()
	var affix: String = home.selected_affix
	find_button(home, "Upgrade ·").pressed.emit()
	await settle()
	check(Content.affix_rank(p.item_by_id(ui_target.id), affix) == 2, "Substat menu upgrades selected stat")
	var credits: int = p.data.credits
	find_button(home, "Reroll ·").pressed.emit()
	await settle()
	check(p.data.credits == credits, "First reroll tap only confirms the cost")
	find_button(home, "Confirm reroll").pressed.emit()
	await settle()
	check(p.data.credits == credits - 100 and home.selected_affix != affix, "Confirmed reroll charges once and selects its replacement")
	for viewport in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 760)]:
		root.size = viewport
		for page in ["merge", "substats", "sets"]:
			home.page = page
			home.rebuild()
			await settle()
			check(home.body.get_global_rect().end.y <= home.navigation.position.y and home.body.size.x <= 386, page + " fits phone " + str(viewport))
		for rarity: String in Content.RARITIES:
			var item := add_item(p, "body", rarity, "riftweaver")
			home.selected_item = item.id
			home.page = "gear"
			home.rebuild()
			await settle()
			check(home.body.get_global_rect().end.y <= home.navigation.position.y, rarity + " item with all substats fits phone")
			home.selected_item = ui_target.id
	arena.queue_free()
	await process_frame
	cleanup()
	print("Nightfall equipment workshop: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
