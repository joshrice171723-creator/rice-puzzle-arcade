extends SceneTree

const Profile = preload("res://profile.gd")
const Run = preload("res://run.gd")
const PATH := "user://nightfall_profile_test.json"
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

func write_raw(value: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(value)
	file.close()

func _initialize() -> void:
	cleanup()
	var p = Profile.new(PATH)
	check(p.load_save() and p.valid(p.data), "Fresh profile is valid and saved")
	check(p.data.inventory.size() == 8 and p.stats().hp == 210 and p.stats().armor == 35, "Starter loadout aggregates actual slot stats")
	check(p.mission_unlocked(1) and not p.mission_unlocked(2) and not p.mission_unlocked(6), "Campaign unlocks only valid completed prerequisites")
	check(p.class_unlocked("scavenger") and not p.class_unlocked("engineer"), "Engineer starts locked")
	check(not p.upgrade_item(0), "Insufficient upgrade funds do not mutate gear")
	p.data.credits = 1000
	p.data.parts = 100
	# This fixture tests purchasing, not the separate class equipment eligibility gate.
	p.data.class_combat.scavenger.xp.ranged = float(p.Training.threshold(3))
	p.sync_training_alias()
	check(p.upgrade_item(0) and p.item_by_id(0).level == 2 and p.data.credits == 960 and p.data.parts == 98, "Equipment upgrade deducts exact costs once")
	check(is_equal_approx(p.stats().power, 42), "Equipment upgrade changes real Power")
	var copies: Array = []
	for index in 2:
		copies.append(p.data.next_item)
		p.data.inventory.append(p.Loot.equipment("weapon", "common", p.data.next_item))
		p.data.next_item += 1
	check(p.merge_items(0, copies) and p.item_by_id(0).rarity == "uncommon" and p.item_by_id(0).level == 2, "Three-copy merge increases rarity and preserves level")
	check(not p.salvage(0), "Equipped item cannot be salvaged")
	check(p.upgrade_facility("quartermaster") and p.stats().capacity == 9 and p.stats().secure == 2, "Quartermaster adds pack capacity without inventing protected slots")
	check(not p.upgrade_facility("quartermaster"), "Facility rank cap rejects repeat upgrade")
	var attempt: Dictionary = p.start_attempt(1)
	check(not attempt.is_empty() and not p.can_change_loadout() and p.start_attempt(1).is_empty(), "Only one expedition can be active")
	check(not p.upgrade_item(0) and not p.equip(0) and not p.select_class("scavenger"), "Equipment and class cannot change underneath an active run")
	var r = Run.new(attempt.seed)
	r.configure(1, p.stats())
	r.field.add_loot("parts", "Parts", 4)
	r.field.add_loot("gear", "Outrider Boots", 1, "rare", "boots")
	r.field.set_secure(0, true)
	r.field.credits = 17
	r.survivor_xp = 8
	r.mastery_xp = 3
	r.field.scrap = 50
	r.field.active_site = 1
	r.field.sites[1].offers = ["emberleaf", "obsidian"]
	r.field.reroll()
	r.phase = "shrine"
	check(p.checkpoint(r.snapshot()), "Active run checkpoint saves")
	var loaded = Profile.new(PATH)
	check(loaded.load_save(), "Saved profile reloads")
	var resumed = Run.new()
	check(resumed.restore(loaded.saved_run()), "Checkpoint restores typed combat state")
	check(resumed.phase == "shrine" and resumed.paused and resumed.field.scrap == 40 and resumed.field.sites[1].rerolls == 1, "Resume preserves paid reroll state and opens paused")
	check(resumed.field.sites[1].offers == r.field.sites[1].offers and resumed.field.bag == r.field.bag, "Resume keeps pending offers and protected loot")
	check(resumed.rng.randi() == r.rng.randi() and resumed.field.rng.randi() == r.field.rng.randi(), "Resume preserves both independent random streams")
	resumed.phase = "defeat"
	var receipt: Dictionary = loaded.finish_attempt(attempt.id, resumed.result())
	check(receipt.credits == 17 and receipt.parts == 4 and receipt.lost == 1 and receipt.gems == 0, "Defeat banks collected credits and protected materials only")
	check(receipt.survivor_xp == 8 and receipt.mastery_xp == 3 and loaded.data.missions.is_empty(), "Defeat keeps earned XP but grants no completion rewards")
	var banked_credits: int = loaded.data.credits
	check(loaded.finish_attempt(attempt.id, resumed.result()).is_empty() and loaded.data.credits == banked_credits, "Repeated reward callback cannot duplicate result")
	p = loaded
	attempt = p.start_attempt(1)
	var won := {"victory": true, "credits": 12, "survivor_xp": 3, "mastery_xp": 1, "loot": [], "damage_taken": 7, "caches": 3}
	receipt = p.finish_attempt(attempt.id, won)
	check(receipt.new_medals.size() == 3 and receipt.gems == 10 and receipt.credits == 287, "First victory banks base reward, first-clear gems, and earned mastery medals")
	check(p.mission_unlocked(2) and not p.mission_unlocked(3), "Boss clear unlocks exactly next mission")
	attempt = p.start_attempt(1)
	receipt = p.finish_attempt(attempt.id, won)
	check(receipt.new_medals.is_empty() and receipt.gems == 0 and receipt.credits == 177, "Replay earns normal rewards without first-clear/medal duplication")
	for mission in range(2, 6):
		attempt = p.start_attempt(mission)
		p.finish_attempt(attempt.id, won)
	check(p.total_medals() == 15 and p.data.zone_claims == [5, 10, 15], "Zone medal milestones claim exactly once")
	check(p.data.breaker_plates == 1 and "Garage Lantern" in p.data.cosmetics, "Finale and mastery grant distinct zone rewards")
	check(p.class_unlocked("engineer") and p.select_class("engineer"), "Mission four unlocks selectable Engineer")
	check(p.data.rare_choices == 1 and p.claim_rare_choice("weapon").get("rarity") == "rare", "Ten-medal milestone grants the player's chosen Rare equipment")
	check(p.claim_rare_choice("boots").is_empty(), "Rare choice can be claimed only once")
	var save_copy: Dictionary = p.data.duplicate(true)
	var after = Profile.new(PATH)
	check(after.load_save() and after.data == save_copy, "Inventory, facilities, class and progression survive reload")
	# Failed transactions cannot spend resources in memory or disk.
	after.path = "user://missing-nightfall-test-directory/profile.json"
	var credits_before: int = after.data.credits
	var parts_before: int = after.data.parts
	check(not after.upgrade_item(0) and after.data.credits == credits_before and after.data.parts == parts_before, "Write failure rolls back a purchase")
	p.save()
	write_raw("{ interrupted")
	var recovered = Profile.new(PATH)
	check(recovered.load_save() and recovered.data == p.data and not recovered.error.is_empty(), "Interrupted JSON write recovers last complete backup")
	var future: Dictionary = p.data.duplicate(true)
	future.version = 999
	write_raw(JSON.stringify(future))
	check(not recovered.load_save() and recovered.blocked, "Newer save version is preserved, never silently downgraded")
	check(not recovered.save(), "Blocked save cannot overwrite unrecognized data")
	var legacy: Dictionary = p.data.duplicate(true)
	legacy.erase("settings")
	write_raw(JSON.stringify(legacy))
	check(recovered.load_save() and recovered.data.settings.music == 0.30, "Pre-settings saves migrate without losing progress")
	check(recovered.set_setting("music", 0.0) and recovered.set_setting("reduced_effects", true), "Settings persist independently of equipment")
	check(not recovered.set_setting("sound", 2.0) and not recovered.set_setting("haptics", "yes"), "Settings reject invalid volume and boolean values")
	check(recovered.load_save() and recovered.data.settings.music == 0 and recovered.data.settings.reduced_effects, "Saved accessibility and audio preferences reload")
	cleanup()
	print("Nightfall Haven: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
