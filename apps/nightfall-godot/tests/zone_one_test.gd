extends SceneTree
const Profile = preload("res://profile.gd")
const ZoneOne = preload("res://zone_one.gd")
const Loot = preload("res://loot.gd")
const Field = preload("res://field.gd")
const Content = preload("res://haven_content.gd")
const Run = preload("res://run.gd")
const Workshop = preload("res://equipment_workshop_ui.gd")
const PATH := "user://nightfall_zone_one_test.json"
var checks := 0
var failures := 0

func check(value: bool, words: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(words)

func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func settle() -> void:
	for frame in 6:
		await process_frame

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	cleanup()
	var catalog := ZoneOne.catalog()
	var families: Array = []
	check(catalog.size() == 8, "Zone 1 authors one family for every equipped slot")
	for record in catalog:
		check(record.family not in families and record.family == ZoneOne.family_for_slot(record.slot), "Every local family has a unique stable content ID")
		families.append(record.family)
		var item := Loot.equipment(record.slot, "common", 100)
		check(item.name == record.name and Content.item_stats(item) == record.base_stats and item.level == record.drop_level, "Catalog budgets agree with generated equipment")
		check(record.level_cap == 5 and record.first_zone == 1, "Local equipment has explicit early-game boundaries")
	check(ZoneOne.family_for_slot("invalid").is_empty(), "Unknown slots have no authored family")
	for category: String in Loot.CATEGORIES:
		var valid_pool := true
		for seed_value in 256:
			var roll := Loot.roll(category, seed_value * 317, 0, 0, seed_value)
			valid_pool = valid_pool and roll.item.name in Content.STARTER_NAMES and roll.item.level == 1 and roll.item.rarity in ["common", "uncommon", "rare", "epic"] and roll.item.slot in Loot.CATEGORIES[category].slots
		check(valid_pool, "New " + category + " chest items stay within the playable zone's source pool")
	var field_slots: Dictionary = {}
	for seed_value in 512:
		var field := Field.new(seed_value)
		for cache in [3, 4, 6]:
			field.open_cache(cache)
		for item in field.bag:
			if item.kind == "gear":
				field_slots[item.slot] = true
	check(field_slots.size() == 8, "Field scavenging can find every local equipment family, including ring and pants")
	var p = Profile.new(PATH)
	p.load_save()
	p.data.credits = 10000
	p.data.parts = 1000
	p.data.breaker_plates = 20
	var before: Dictionary = p.data.duplicate(true)
	check(p.craft_zone_item("weapon").is_empty() and p.data == before, "Funds alone cannot bypass the finale crafting unlock")
	p.data.breaker_plates = 0
	for mission in range(1, 6):
		var attempt: Dictionary = p.start_attempt(mission)
		var run := Run.new(attempt.seed)
		run.configure(mission, p.stats())
		run.elapsed = run.duration - 0.01
		run.tick(0.02, Vector2.ZERO)
		check(run.phase == "boss" and run.boss_name == Content.MISSIONS[mission - 1].boss and run.enemies.back().hp == Content.MISSIONS[mission - 1].health, "Mission %d spawns its authored boss after timed waves" % mission)
		run.phase = "victory"
		run.damage_taken = 9
		var result: Dictionary = p.finish_attempt(attempt.id, run.result())
		check(result.keys == 1 and result.new_medals == ["clear"] and p.mission_unlocked(mini(5, mission + 1)), "Boss clear unlocks next mission without requiring bonus objectives")
	check(ZoneOne.craft_unlocked(p.data.missions) and p.data.breaker_plates == 1, "The finale unlocks crafting and earns the first Plate")
	check(p.data.credits == 11403 and p.data.parts == 1017 and p.data.gems == 80 and p.data.cache_keys == 5 and p.data.survivor_xp == 468 and p.data.mastery.scavenger == 248, "A clear-only first pass funds the documented earned progression budget")
	for replay in 7:
		var attempt: Dictionary = p.start_attempt(5)
		p.finish_attempt(attempt.id, {"victory": true})
	check(p.data.breaker_plates == 8, "Eight earned finale clears fund one Rare recipe without ads")
	before = p.data.duplicate(true)
	check(p.craft_zone_item("unknown").is_empty() and p.data == before, "Invalid recipe cannot spend materials")
	var result: Dictionary = p.craft_zone_item("pants")
	check(result.name == "Outrider Trousers" and result.rarity == "rare" and result.level == 1 and result.affixes.size() == 1, "Crafting creates the chosen local family with its actual Rare budget")
	check(p.data.breaker_plates == 0 and p.data.credits == before.credits - 330 and p.data.parts == before.parts - 5 and p.data.inventory.size() == before.inventory.size() + 1, "Crafting charges the exact three-resource cost once and consumes no owned gear")
	var loaded = Profile.new(PATH)
	check(loaded.load_save() and loaded.data == p.data, "Crafted ownership and material spending survive reload")
	before = p.data.duplicate(true)
	check(p.craft_zone_item("pants").is_empty() and p.data == before, "Insufficient Plates cannot grant a second item")
	p.data.breaker_plates = 8
	for currency: String in ZoneOne.CRAFT_COST:
		var funded: Dictionary = p.data.duplicate(true)
		p.data[currency] = ZoneOne.CRAFT_COST[currency] - 1
		before = p.data.duplicate(true)
		check(p.craft_zone_item("ring").is_empty() and p.data == before, "Insufficient " + currency + " rejects the whole recipe")
		p.data = funded
	var active: Dictionary = p.start_attempt(1)
	before = p.data.duplicate(true)
	check(p.craft_zone_item("ring").is_empty() and p.data == before, "Saved expeditions lock crafting like other equipment mutations")
	p.finish_attempt(active.id, {"victory": false})
	p.data.breaker_plates = 8
	before = p.data.duplicate(true)
	p.path = "user://missing-zone-one-craft-dir/save.json"
	check(p.craft_zone_item("ring").is_empty() and p.data == before, "Failed save rolls back item, identity and every currency")
	p.path = PATH
	p.error = ""
	for slot: String in Content.SLOTS:
		p.data.breaker_plates = 8
		var item: Dictionary = p.craft_zone_item(slot)
		check(not item.is_empty() and item.slot == slot and p.valid(p.data), "Every local slot has a valid craft recipe")
	var legacy := Loot.equipment("helmet", "rare", p.data.next_item, "ironwatch")
	p.data.next_item += 1
	p.data.inventory.append(legacy)
	check(p.equip(legacy.id) and p.valid(p.data) and p.item_by_id(legacy.id).name == "Ironwatch Helm", "Previously owned future-family equipment remains valid and equippable")
	# Use a disposable profile and paused arena; the emulator's save is never opened.
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	arena.profile = p
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	var home: Control = arena.home
	p.data.breaker_plates = 16
	p.data.credits = 10000
	p.data.parts = 1000
	home.navigate("craft")
	await settle()
	check(home.body.find_child("CraftSlot_ring", true, false) != null, "Workshop route exposes the eight selectable recipes")
	home.body.find_child("CraftSlot_ring", true, false).pressed.emit()
	await settle()
	before = p.data.duplicate(true)
	home.body.get_node("ConfirmCraft").pressed.emit()
	await settle()
	check(p.data == before and home.confirmation == "craft", "First craft tap reviews the cost without spending")
	home.body.get_node("ConfirmCraft").pressed.emit()
	await settle()
	check(p.data.inventory.back().slot == "ring" and p.data.breaker_plates == 8, "Confirmed UI action creates the selected real item")
	for viewport in [Vector2i(320, 568), Vector2i(430, 760)]:
		root.size = viewport
		home.navigate("craft")
		await settle()
		check(home.body.get_global_rect().end.y < home.navigation.position.y and home.body.size.x <= 386, "Craft controls and navigation fit phone " + str(viewport))
	arena.queue_free()
	await process_frame
	cleanup()
	print("Nightfall Zone 1 content: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
