extends SceneTree
const Profile = preload("res://profile.gd")
const Loot = preload("res://loot.gd")
const Run = preload("res://run.gd")
const PATH := "user://nightfall_loot_test.json"
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func _initialize() -> void:
	cleanup()
	var p = Profile.new(PATH)
	p.load_save()
	check(p.open_cache("supply").is_empty() and p.data.inventory.size() == 8, "No key cannot create equipment")
	var attempt: Dictionary = p.start_attempt(1)
	var result: Dictionary = p.finish_attempt(attempt.id, {"victory": true})
	check(result.get("keys") == 1 and p.data.cache_keys == 1, "First clear grants one persistent chest key")
	attempt = p.start_attempt(1)
	p.finish_attempt(attempt.id, {"victory": true})
	check(p.data.cache_keys == 1, "Repeating a clear does not repeat first-clear keys")
	var receipt: Dictionary = p.open_cache("armor")
	check(receipt.item.slot in ["helmet", "body", "boots", "pants"] and p.data.cache_keys == 0 and p.data.cache_opened == 1, "Targeted locker consumes exactly one key and adds armor")
	check(p.data.inventory.back().id == receipt.item.id and p.valid(p.data), "Chest item is a valid owned inventory record")
	p.data.cache_keys = 2
	p.data.rare_misses = 9
	receipt = p.open_cache("weapons")
	check(receipt.item.rarity in ["rare", "epic"] and receipt.item.slot == "weapon" and p.data.rare_misses == 0, "Tenth-opening guarantee follows the player across categories")
	p.data.epic_misses = 29
	receipt = p.open_cache("engineer")
	check(receipt.item.rarity == "epic" and receipt.item.slot in ["charm", "gadget", "ring"] and p.data.epic_misses == 0 and p.data.rare_misses == 0, "Epic guarantee satisfies both counters and targeted slot")
	check(receipt.item.affixes.size() == 2 and receipt.item.affixes[0] != receipt.item.affixes[1], "Epic gear receives two distinct eligible affixes")
	var fresh = Profile.new(PATH)
	check(fresh.load_save() and fresh.data.last_cache == p.data.last_cache and fresh.data.cache_opened == 3, "Receipt and guarantee counters survive relaunch")
	fresh.data.cache_keys = 1
	fresh.path = "user://missing-nightfall-loot-folder/save.json"
	var before: Dictionary = fresh.data.duplicate(true)
	check(fresh.open_cache("supply").is_empty() and fresh.data == before, "Write failure returns the key and restores RNG progression and inventory")
	fresh.path = PATH
	attempt = fresh.start_attempt(1)
	check(fresh.open_cache("supply").is_empty() and fresh.data.cache_keys == 1, "Cannot alter armory while an expedition is active")
	var counts := {"common": 0, "uncommon": 0, "rare": 0, "epic": 0}
	for seed_value in 4000:
		var roll: Dictionary = Loot.roll("supply", seed_value * 31, 0, 0, seed_value)
		counts[roll.item.rarity] += 1
	for entry in [["common", 0.55], ["uncommon", 0.30], ["rare", 0.13], ["epic", 0.02]]:
		check(absf(counts[entry[0]] / 4000.0 - entry[1]) < 0.025, "Seeded sample agrees with disclosed %s base odds" % entry[0])
	var rare_misses := 0
	var epic_misses := 0
	for opening in 120:
		var category: String = Loot.CATEGORIES.keys()[opening % 4]
		var roll: Dictionary = Loot.roll(category, opening * 317, rare_misses, epic_misses, opening)
		rare_misses = roll.rare_misses
		epic_misses = roll.epic_misses
		check(rare_misses <= 9 and epic_misses <= 29, "Guarantee never exceeds advertised number of openings")
	p = Profile.new(PATH)
	p.data.inventory[0].rarity = "epic"
	p.data.inventory[0].affixes = ["tempered", "attuned"]
	check(is_equal_approx(p.stats().power, 44.8 * 1.03) and is_equal_approx(p.stats().cooldown, 0.02), "Power and cooldown affixes affect the equipped build")
	var r = Run.new()
	r.configure(1, p.stats())
	check(is_equal_approx(r.spell_cooldown("frost"), 7.84), "Permanent cooldown bonus reaches actual automatic spell schedule")
	r.permanent_cooldown = 0.15
	r.passives.channel = 3
	check(is_equal_approx(r.spell_cooldown("frost"), 5.6), "Equipment and run cooldown bonuses share the thirty-percent cap")
	p.data.inventory[0].affixes = ["tempered", "tempered"]
	check(not p.valid(p.data), "Save validation rejects duplicate affixes")
	p.data.inventory[0].affixes = ["reinforced"]
	check(not p.valid(p.data), "Save validation rejects affixes for the wrong slot")
	cleanup()
	print("Nightfall loot: %d checks, %d failures; sample %s" % [checks, failures, counts])
	quit(1 if failures else 0)
