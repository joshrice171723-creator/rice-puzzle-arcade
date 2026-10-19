extends RefCounted
## Local, versioned Haven profile. A failed write rolls the transaction back.

const Content = preload("res://haven_content.gd")
const Loot = preload("res://loot.gd")
const Salvage = preload("res://salvage.gd")
const Skills = preload("res://skill_tree.gd")
const Daily = preload("res://daily_progress.gd")
const ZoneOne = preload("res://zone_one.gd")
const Training = preload("res://combat_progression.gd")
const VERSION := 5
const BUILD_SLOTS := ["1", "2", "3"]
const SHOP_OFFERS := {"key": {"name": "Supply key", "cost": 25, "currency": "gems", "grant": "cache_keys", "amount": 1}, "parts": {"name": "10 Workshop Parts", "cost": 200, "currency": "credits", "grant": "parts", "amount": 10}}
var path := "user://haven.json"
var data: Dictionary = {}
var error := ""
var blocked := false
var utc_now: Callable = func() -> int: return int(Time.get_unix_time_from_system())

func _init(save_path: String = "user://haven.json") -> void:
	path = save_path
	data = fresh()

func fresh() -> Dictionary:
	var items: Array = []
	var equipment: Dictionary = {}
	for index in Content.SLOTS.size():
		items.append({"id": index, "slot": Content.SLOTS[index], "name": Content.STARTER_NAMES[index], "rarity": "common", "level": 1})
		equipment[Content.SLOTS[index]] = index
	return {"version": VERSION, "credits": 0, "parts": 0, "gems": 0, "survivor_xp": 0,
		"combat_xp": Training.fresh(), "training_style": "accurate", "legacy_talent_points": 0,
		"mastery": {"scavenger": 0, "engineer": 0, "warden": 0, "arcanist": 0}, "class": "scavenger",
		"inventory": items, "equipment": equipment, "next_item": Content.SLOTS.size(), "missions": {}, "zone_claims": [],
		"loadouts": {}, "locked_items": [], "affix_rolls": 0, "daily": Daily.fresh(),
		"skill_unlocks": {"scavenger": [], "engineer": [], "warden": [], "arcanist": []},
		"facilities": {"workshop": 1, "quartermaster": 1, "infirmary": 1},
		"next_attempt": 1, "active_attempt": {}, "last_result": {}, "last_banked": 0,
		"breaker_plates": 0, "cosmetics": [], "tutorial_seen": false, "seen_bosses": [],
		"shop_day": "", "shop_videos": 0, "last_shop_reward": "",
		"cache_keys": 0, "cache_opened": 0, "rare_misses": 0, "epic_misses": 0, "cache_seed": randi(), "last_cache": {}, "rare_choices": 0, "contract_clears": 0,
		"settings": {"music": 0.30, "sound": 0.65, "haptics": true, "reduced_effects": false}}

func valid(candidate: Variant) -> bool:
	if not candidate is Dictionary or candidate.get("version") != VERSION:
		return false
	var defaults := fresh()
	for key: String in defaults:
		if not candidate.has(key):
			return false
	if not Training.valid(candidate.combat_xp) or candidate.training_style not in Training.STYLES:
		return false
	if not candidate.legacy_talent_points is int or candidate.legacy_talent_points < 0 or candidate.legacy_talent_points > 36:
		return false
	if not Daily.valid(candidate.daily):
		return false
	for key in ["credits", "parts", "gems", "survivor_xp", "next_item", "next_attempt", "last_banked", "breaker_plates", "cache_keys", "cache_opened", "rare_misses", "epic_misses", "cache_seed", "rare_choices", "contract_clears", "affix_rolls"]:
		if not (candidate[key] is int or candidate[key] is float) or candidate[key] < 0 or candidate[key] != floor(candidate[key]):
			return false
	if candidate["class"] not in Content.CLASSES or not candidate.inventory is Array or not candidate.equipment is Dictionary or not candidate.missions is Dictionary or not candidate.facilities is Dictionary or not candidate.mastery is Dictionary:
		return false
	if not candidate.active_attempt is Dictionary or not candidate.last_result is Dictionary or not candidate.zone_claims is Array or not candidate.cosmetics is Array or not candidate.tutorial_seen is bool:
		return false
	if not candidate.last_cache is Dictionary or candidate.rare_misses > 9 or candidate.epic_misses > 29:
		return false
	if not candidate.seen_bosses is Array:
		return false
	for boss in candidate.seen_bosses:
		if boss not in range(1, 6):
			return false
	if not candidate.settings is Dictionary:
		return false
	for key in ["music", "sound"]:
		var value: Variant = candidate.settings.get(key)
		if not (value is int or value is float) or value < 0 or value > 1:
			return false
	for key in ["haptics", "reduced_effects"]:
		if not candidate.settings.get(key) is bool:
			return false
	var ids: Array = []
	if not candidate.shop_day is String or not candidate.last_shop_reward is String or not candidate.shop_videos is int or candidate.shop_videos < 0 or candidate.shop_videos > 2:
		return false
	for item in candidate.inventory:
		if not item is Dictionary or not item.get("id") is float and not item.get("id") is int:
			return false
		if item.id in ids or item.id < 0 or item.id >= candidate.next_item or item.get("slot") not in Content.SLOTS or item.get("rarity") not in Content.RARITIES:
			return false
		if not item.get("name") is String or not (item.get("level") is int or item.get("level") is float) or item.level < 1 or item.level > 30:
			return false
		if not item.get("affixes", []) is Array or item.get("affixes", []).size() > [0, 1, 1, 2, 3, 3][Content.RARITIES.find(item.rarity)]:
			return false
		var seen_affixes: Array = []
		for affix in item.get("affixes", []):
			if affix not in Content.AFFIXES or affix in seen_affixes or item.slot not in Content.AFFIXES[affix].slots:
				return false
			seen_affixes.append(affix)
		if not item.get("affix_levels", {}) is Dictionary:
			return false
		for affix in item.get("affix_levels", {}):
			if affix not in seen_affixes or not item.affix_levels[affix] is int or item.affix_levels[affix] not in [1, 2, 3]:
				return false
		ids.append(item.id)
	for slot: String in Content.SLOTS:
		if not candidate.equipment.has(slot):
			return false
		var found := false
		for item in candidate.inventory:
			if item.id == candidate.equipment[slot] and item.slot == slot:
				found = true
		if not found:
			return false
	for id: String in Content.CLASSES:
		if not candidate.mastery.get(id) is float and not candidate.mastery.get(id) is int:
			return false
	if not candidate.skill_unlocks is Dictionary:
		return false
	for id: String in Content.CLASSES:
		var learned: Variant = candidate.skill_unlocks.get(id)
		if not learned is Array:
			return false
		var seen: Array = []
		for ability in learned:
			if ability not in Skills.BRANCHES[id] or ability in seen:
				return false
			seen.append(ability)
			if not Skills.prerequisites_met(id, ability, learned):
				return false
	if talent_spent(candidate) > Training.combat_level(candidate.combat_xp) - 1 + candidate.legacy_talent_points:
		return false
	if not candidate.loadouts is Dictionary or not candidate.locked_items is Array:
		return false
	var locked_ids: Array = []
	for id in candidate.locked_items:
		if not id is int or id not in ids or id in locked_ids:
			return false
		locked_ids.append(id)
	for slot in candidate.loadouts:
		var build: Variant = candidate.loadouts[slot]
		if slot not in BUILD_SLOTS or not build is Dictionary:
			return false
		if not build.get("name") is String or build.name.strip_edges().is_empty() or build.name.length() > 20:
			return false
		if build.get("class") not in Content.CLASSES or not build.get("equipment") is Dictionary or build.equipment.size() != Content.SLOTS.size():
			return false
		for equipment_slot in Content.SLOTS:
			var found := false
			for item in candidate.inventory:
				if item.id == build.equipment.get(equipment_slot, -1) and item.slot == equipment_slot:
					found = true
			if not found:
				return false
	for id: String in Content.FACILITIES:
		if int(candidate.facilities.get(id, 0)) not in [1, 2]:
			return false
	for key in candidate.missions:
		if not key is String or not key.is_valid_int() or int(key) not in range(1, 6) or not candidate.missions[key] is Array:
			return false
		for medal in candidate.missions[key]:
			if medal not in ["clear", "combat", "scavenger"]:
				return false
	return true

func read_candidate(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return null
	var parsed: Variant = normalize_numbers(parser.data)
	if parsed is Dictionary and parsed.get("version") in [1, 2, 3, 4, VERSION] and not parsed.has("settings"):
		parsed.settings = fresh().settings
	if parsed is Dictionary and parsed.get("version") in [1, 2, 3, 4, VERSION]:
		var defaults := fresh()
		if parsed.version < 4:
			parsed.daily = Daily.fresh()
		if parsed.version < 3:
			parsed.loadouts = {}
			parsed.locked_items = []
			parsed.skill_unlocks = defaults.skill_unlocks.duplicate(true)
			parsed.affix_rolls = 0
		if not parsed.has("seen_bosses"):
			parsed.seen_bosses = []
			for key in parsed.get("missions", {}):
				if "clear" in parsed.missions[key]:
					parsed.seen_bosses.append(int(key))
		for key in ["cache_keys", "cache_opened", "rare_misses", "epic_misses", "cache_seed", "last_cache", "rare_choices", "contract_clears", "shop_day", "shop_videos", "last_shop_reward"]:
			if not parsed.has(key):
				parsed[key] = defaults[key]
		if parsed.version == 1 and parsed.get("inventory") is Array and parsed.get("equipment") is Dictionary and parsed.get("next_item") is int:
			# Append new slots without renumbering owned items or changing saved runs.
			for slot in ["ring", "pants"]:
				if not parsed.equipment.has(slot):
					var item := Loot.equipment(slot, "common", parsed.next_item)
					parsed.next_item += 1
					parsed.inventory.append(item)
					parsed.equipment[slot] = item.id
		if parsed.version < 5:
			parsed.combat_xp = Training.fresh()
			parsed.training_style = "accurate"
			parsed.legacy_talent_points = talent_spent(parsed)
		parsed.version = VERSION
	return parsed

func normalize_numbers(value: Variant) -> Variant:
	# JSON numbers load as floats. Stable integer IDs are needed for Array.has
	# and once-only milestone claims after a restart.
	if value is float and value == floor(value):
		return int(value)
	if value is Dictionary:
		for key in value:
			if key == "combat_xp" and value[key] is Dictionary:
				for stat in value[key]:
					if value[key][stat] is int or value[key][stat] is float:
						value[key][stat] = float(value[key][stat])
			else:
				value[key] = normalize_numbers(value[key])
	elif value is Array:
		for index in value.size():
			value[index] = normalize_numbers(value[index])
	return value

func load_save() -> bool:
	error = ""
	blocked = false
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path + ".bak"):
		return save()
	var candidate: Variant = read_candidate(path)
	if valid(candidate):
		data = candidate
		return true
	# A future version must not be replaced by an older backup.
	if candidate is Dictionary and candidate.get("version", 0) > VERSION:
		blocked = true
		error = "This save was made by a newer Nightfall build. Install that build to continue."
		return false
	candidate = read_candidate(path + ".bak")
	if valid(candidate):
		data = candidate
		error = "Recovered the previous save after an interrupted write."
		return true
	blocked = true
	error = "Haven save could not be read. Your files were preserved; campaign changes are disabled."
	return false

func save() -> bool:
	if blocked:
		return false
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		error = "Could not save Haven. Free disk space and try again."
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		error = "Haven write failed. Your last save is intact."
		return false
	var absolute := ProjectSettings.globalize_path(path)
	var backup := absolute + ".bak"
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(backup) and DirAccess.remove_absolute(backup) != OK:
			error = "Could not rotate the Haven backup."
			return false
		if DirAccess.rename_absolute(absolute, backup) != OK:
			error = "Could not preserve the previous Haven save."
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), absolute) != OK:
		if FileAccess.file_exists(backup):
			DirAccess.rename_absolute(backup, absolute)
		error = "Could not finish saving Haven. Please retry."
		return false
	error = ""
	return true

func commit(previous: Dictionary) -> bool:
	if save():
		return true
	data = previous
	return false

func item_by_id(id: int) -> Dictionary:
	for item in data.inventory:
		if item.id == id:
			return item
	return {}

func can_change_loadout() -> bool:
	return not blocked and data.active_attempt.is_empty()

func item_in_build(id: int) -> bool:
	for build in data.loadouts.values():
		if id in build.equipment.values():
			return true
	return false

func salvage_block_reason(id: int) -> String:
	if id in data.equipment.values():
		return "Equipped item"
	if id in data.locked_items:
		return "Unlock item to salvage"
	if item_in_build(id):
		return "Saved in a build"
	return ""

func set_item_locked(id: int, locked: bool) -> bool:
	if not can_change_loadout() or item_by_id(id).is_empty():
		return false
	var previous := data.duplicate(true)
	data.locked_items.erase(id)
	if locked:
		data.locked_items.append(id)
	return commit(previous)

func save_loadout(slot: String, label: String) -> bool:
	var clean := label.strip_edges()
	if not can_change_loadout() or slot not in BUILD_SLOTS or clean.is_empty() or clean.length() > 20 or "\n" in clean or "\r" in clean:
		return false
	var previous := data.duplicate(true)
	data.loadouts[slot] = {"name": clean, "class": data["class"], "equipment": data.equipment.duplicate(true)}
	return commit(previous)

func apply_loadout(slot: String) -> bool:
	if not can_change_loadout() or slot not in BUILD_SLOTS or not data.loadouts.has(slot):
		return false
	var build: Dictionary = data.loadouts[slot]
	if not class_unlocked(build["class"]):
		return false
	# Validate every reference before replacing anything; never partially equip.
	for equipment_slot in Content.SLOTS:
		var item := item_by_id(int(build.equipment.get(equipment_slot, -1)))
		if item.is_empty() or item.slot != equipment_slot:
			return false
	var previous := data.duplicate(true)
	data["class"] = build["class"]
	data.equipment = build.equipment.duplicate(true)
	return commit(previous)

func remove_loadout(slot: String) -> bool:
	if not can_change_loadout() or not data.loadouts.has(slot):
		return false
	var previous := data.duplicate(true)
	data.loadouts.erase(slot)
	return commit(previous)

func equip(id: int) -> bool:
	var item := item_by_id(id)
	if not can_change_loadout() or item.is_empty():
		return false
	var previous := data.duplicate(true)
	data.equipment[item.slot] = id
	return commit(previous)

func upgrade_cost(id: int) -> Dictionary:
	var item := item_by_id(id)
	if item.is_empty() or item.level >= 5:
		return {}
	return {"credits": ceili(40 * item.level * (0.9 if data.facilities.workshop >= 2 else 1.0)), "parts": int(item.level) + 1}

func upgrade_item(id: int) -> bool:
	var cost := upgrade_cost(id)
	if not can_change_loadout() or cost.is_empty() or data.credits < cost.credits or data.parts < cost.parts:
		return false
	var previous := data.duplicate(true)
	data.credits -= cost.credits
	data.parts -= cost.parts
	item_by_id(id).level += 1
	return commit(previous)

func quick_upgrade_cost(id: int) -> Dictionary:
	var item := item_by_id(id)
	if item.is_empty():
		return {}
	var cost := {"levels": 0, "credits": 0, "parts": 0}
	for level in range(int(item.level), 5):
		var credits := ceili(40 * level * (0.9 if data.facilities.workshop >= 2 else 1.0))
		var parts := level + 1
		if cost.credits + credits > data.credits or cost.parts + parts > data.parts:
			break
		cost.levels += 1
		cost.credits += credits
		cost.parts += parts
	return cost if cost.levels > 0 else {}

func quick_upgrade_item(id: int) -> bool:
	var cost := quick_upgrade_cost(id)
	if not can_change_loadout() or cost.is_empty():
		return false
	var previous := data.duplicate(true)
	data.credits -= cost.credits
	data.parts -= cost.parts
	item_by_id(id).level += cost.levels
	return commit(previous)

func salvage(id: int) -> bool:
	var item := item_by_id(id)
	if not can_change_loadout() or item.is_empty() or not salvage_block_reason(id).is_empty():
		return false
	var previous := data.duplicate(true)
	data.parts += 2 + Content.RARITIES.find(item.rarity) + int(item.level) - 1
	data.inventory.erase(item)
	return commit(previous)

func merge_candidates(id: int) -> Array:
	var target := item_by_id(id)
	if target.is_empty() or Content.RARITIES.find(target.rarity) >= Content.RARITIES.find(Content.MERGE_MAX_RARITY):
		return []
	return data.inventory.filter(func(item: Dictionary): return item.id != id and item.slot == target.slot and item.name == target.name and item.rarity == target.rarity and salvage_block_reason(item.id).is_empty())

func merge_items(id: int, donors: Array) -> bool:
	if not can_change_loadout() or donors.size() != 2 or donors[0] == donors[1]:
		return false
	var eligible: Array = merge_candidates(id).map(func(item: Dictionary): return item.id)
	if donors[0] not in eligible or donors[1] not in eligible:
		return false
	var previous := data.duplicate(true)
	var target := item_by_id(id)
	for donor_id in donors:
		var donor := item_by_id(donor_id)
		target.level = maxi(target.level, donor.level)
		data.inventory.erase(donor)
	target.rarity = Content.RARITIES[Content.RARITIES.find(target.rarity) + 1]
	# Preserve the selected item's substats and their ranks, then fill new slots.
	var kept: Array = target.get("affixes", []).duplicate()
	var count: int = [0, 1, 1, 2, 3, 3][Content.RARITIES.find(target.rarity)]
	for affix: String in Loot.affixes(target.slot, target.rarity, id):
		if kept.size() < count and affix not in kept:
			kept.append(affix)
	target.affixes = kept
	return commit(previous)

func substat_cost(id: int, affix: String) -> Dictionary:
	var item := item_by_id(id)
	if item.is_empty() or affix not in item.get("affixes", []):
		return {}
	var rank := Content.affix_rank(item, affix)
	return {} if rank >= 3 else {"credits": rank * 50, "parts": rank * 3}

func upgrade_substat(id: int, affix: String) -> bool:
	var cost := substat_cost(id, affix)
	if not can_change_loadout() or cost.is_empty() or data.credits < cost.credits or data.parts < cost.parts:
		return false
	var previous := data.duplicate(true)
	var item := item_by_id(id)
	if not item.has("affix_levels"):
		item.affix_levels = {}
	item.affix_levels[affix] = Content.affix_rank(item, affix) + 1
	data.credits -= cost.credits
	data.parts -= cost.parts
	return commit(previous)

func substat_options(id: int, affix: String) -> Array:
	var item := item_by_id(id)
	if item.is_empty() or affix not in item.get("affixes", []):
		return []
	return Content.AFFIXES.keys().filter(func(candidate: String): return candidate not in item.affixes and item.slot in Content.AFFIXES[candidate].slots)

func reroll_substat(id: int, affix: String) -> bool:
	var options := substat_options(id, affix)
	if not can_change_loadout() or options.is_empty() or data.credits < 100 or data.parts < 5:
		return false
	var previous := data.duplicate(true)
	var item := item_by_id(id)
	var roll := RandomNumberGenerator.new()
	roll.seed = int(data.cache_seed) + int(data.affix_rolls) * 104729 + id * 7937
	var replacement: String = options[roll.randi_range(0, options.size() - 1)]
	var rank := Content.affix_rank(item, affix)
	item.affixes[item.affixes.find(affix)] = replacement
	if not item.has("affix_levels"):
		item.affix_levels = {}
	item.affix_levels.erase(affix)
	item.affix_levels[replacement] = rank
	data.credits -= 100
	data.parts -= 5
	data.affix_rolls += 1
	return commit(previous)

func set_counts() -> Dictionary:
	var result := {"outrider": 0, "ironwatch": 0, "riftweaver": 0}
	for slot: String in Content.SLOTS:
		var item := item_by_id(data.equipment[slot])
		var id := Content.set_id(item)
		if not id.is_empty() and Content.RARITIES.find(item.rarity) >= 2:
			result[id] += 1
	return result

func upgrade_facility(id: String) -> bool:
	if not can_change_loadout() or id not in Content.FACILITIES or data.facilities[id] >= 2:
		return false
	var cost: Dictionary = Content.FACILITIES[id]
	if data.credits < cost.credits or data.parts < cost.parts:
		return false
	var previous := data.duplicate(true)
	data.credits -= cost.credits
	data.parts -= cost.parts
	data.facilities[id] += 1
	return commit(previous)

func class_unlocked(id: String) -> bool:
	return id == "scavenger" or (id == "engineer" and "clear" in data.missions.get("4", []))

func select_class(id: String) -> bool:
	if not can_change_loadout() or not class_unlocked(id):
		return false
	var previous := data.duplicate(true)
	data["class"] = id
	return commit(previous)

func talent_spent(candidate: Dictionary) -> int:
	var spent := 0
	var trees: Variant = candidate.get("skill_unlocks", {})
	if not trees is Dictionary:
		return 0
	for id in Content.CLASSES:
		var unlocks: Variant = trees.get(id, [])
		if unlocks is Array:
			for ability in unlocks:
				if ability is String:
					spent += Skills.cost(id, ability)
	return spent

func skill_points(class_id: String) -> int:
	if class_id not in Content.CLASSES:
		return 0
	return maxi(0, Training.combat_level(data.combat_xp) - 1 + data.legacy_talent_points - talent_spent(data))

func set_training_style(id: String) -> bool:
	if id not in Training.STYLES or not can_change_loadout():
		return false
	var previous := data.duplicate(true)
	data.training_style = id
	return commit(previous)

func ability_pool(class_id: String) -> Array:
	return Skills.pool(class_id, data.skill_unlocks[class_id])

func unlock_skill(class_id: String, ability: String) -> bool:
	if not can_change_loadout() or not class_unlocked(class_id):
		return false
	var cost: int = Skills.cost(class_id, ability)
	if cost == 0 or ability in data.skill_unlocks[class_id] or skill_points(class_id) < cost:
		return false
	if not Skills.prerequisites_met(class_id, ability, data.skill_unlocks[class_id]):
		return false
	var previous := data.duplicate(true)
	data.skill_unlocks[class_id].append(ability)
	return commit(previous)

func stats() -> Dictionary:
	var result := {"hp": 120.0 + 4.0 * (Content.survivor_level(data.survivor_xp) - 1), "power": 0.0, "armor": 0.0,
		"speed": 1.05 if data["class"] == "scavenger" else 1.0, "pickup": 1.15 if data["class"] == "scavenger" else 1.0,
		"capacity": 8 + int(data.facilities.quartermaster) - 1, "secure": 2,
		"medkit": 0.25 if data.facilities.infirmary >= 2 else 0.20, "class": data["class"], "cooldown": 0.0}
	result.blueprints = ["barricade", "trap"]
	if "clear" in data.missions.get("1", []):
		result.blueprints.append("turret")
	if "clear" in data.missions.get("3", []):
		result.blueprints.append("ward")
	result.mastery = Content.mastery_level(data.mastery[data["class"]])
	result.ability_pool = ability_pool(data["class"])
	result.training_style = data.training_style
	result.training_bonuses = Training.bonuses(data.combat_xp)
	for slot: String in Content.SLOTS:
		var item := item_by_id(data.equipment[slot])
		var values := Content.item_stats(item)
		for stat in ["hp", "power", "armor"]:
			result[stat] += values[stat]
		for id: String in item.get("affixes", []):
			var affix: Dictionary = Content.AFFIXES[id]
			if affix.stat in ["speed", "pickup", "cooldown"]:
				result[affix.stat] += Content.affix_value(item, id)
	var sets := set_counts()
	if sets.outrider >= 2:
		result.pickup += 0.15
	if sets.outrider >= 3:
		result.secure += 1
	if sets.ironwatch >= 2:
		result.armor += 12
	if sets.ironwatch >= 3:
		result.hp *= 1.06
	result.spell_bonus = 0.03 if sets.riftweaver >= 2 else 0.0
	if sets.riftweaver >= 3:
		result.cooldown += 0.04
	result.hp *= 1.0 + result.training_bonuses.hp
	result.speed = minf(result.speed, 1.15)
	result.cooldown = minf(result.cooldown, 0.15)
	result.pickup = minf(result.pickup, 1.50)
	return result

func mission_unlocked(mission: int) -> bool:
	return mission in range(1, 6) and (mission == 1 or "clear" in data.missions.get(str(mission - 1), []))

func start_attempt(mission: int) -> Dictionary:
	if not can_change_loadout() or not mission_unlocked(mission):
		return {}
	var previous := data.duplicate(true)
	var attempt := {"id": int(data.next_attempt), "mission": mission, "class": data["class"], "seed": int(Time.get_unix_time_from_system()) + int(data.next_attempt) * 7919}
	data.next_attempt += 1
	data.active_attempt = attempt
	data.tutorial_seen = true
	if not commit(previous):
		return {}
	return attempt.duplicate(true)

func finish_attempt(id: int, outcome: Dictionary) -> Dictionary:
	if blocked or data.active_attempt.is_empty() or data.active_attempt.id != id or id <= data.last_banked:
		return {}
	var combat_earned: Variant = outcome.get("combat_xp", Training.fresh())
	if not Training.valid(combat_earned):
		return {}
	var previous := data.duplicate(true)
	var attempt: Dictionary = data.active_attempt
	var mission: int = attempt.mission
	var victory: bool = outcome.get("victory", false)
	var reward := {"victory": victory, "mission": mission, "credits": int(outcome.get("credits", 0)), "parts": 0, "gems": 0,
		"survivor_xp": int(outcome.get("survivor_xp", 0)), "mastery_xp": int(outcome.get("mastery_xp", 0)), "gear": [], "new_medals": [], "lost": int(outcome.get("lost", 0)), "keys": 0}
	for loot in outcome.get("loot", []):
		if loot.kind == "parts":
			reward.parts += int(loot.amount)
		elif loot.kind == "gear":
			var item := Loot.equipment(loot.slot, loot.rarity, int(data.next_item))
			data.next_item += 1
			data.inventory.append(item)
			reward.gear.append(item.name)
	if victory and attempt.get("mode", "campaign") == "salvage":
		for key in Salvage.REWARDS:
			reward[key] += Salvage.REWARDS[key]
		var contract_rng := RandomNumberGenerator.new()
		contract_rng.seed = int(attempt.seed) + 93841
		var rarity := "uncommon" if contract_rng.randf() < 0.25 else "common"
		var item := Loot.equipment(attempt.target_slot, rarity, int(data.next_item))
		data.next_item += 1
		data.inventory.append(item)
		reward.gear.append(rarity.capitalize() + " " + item.name)
		data.contract_clears += 1
		if data.contract_clears % 3 == 0:
			reward.keys += 1
	elif victory:
		if mission not in data.seen_bosses:
			data.seen_bosses.append(mission)
		var base := Content.clear_rewards(mission)
		for key in base:
			reward[key] += base[key]
		var earned: Array = ["clear"]
		if outcome.get("damage_taken", 999) <= 8 and not outcome.get("rescued", false):
			earned.append("combat")
		if outcome.get("caches", 0) >= 3:
			earned.append("scavenger")
		var medals: Array = data.missions.get(str(mission), [])
		if "clear" not in medals:
			reward.gems += 40 if mission == 5 else 10
			reward.keys += 1
		for medal in earned:
			if medal not in medals:
				medals.append(medal)
				reward.new_medals.append(medal)
				if medal != "clear":
					reward.credits += 55
		data.missions[str(mission)] = medals
		var boss_rng := RandomNumberGenerator.new()
		boss_rng.seed = int(attempt.seed) + 47777
		if mission < 5 and boss_rng.randf() < 0.35:
			var slot: String = Content.SLOTS[boss_rng.randi_range(0, Content.SLOTS.size() - 1)]
			var rarity := "uncommon" if boss_rng.randf() < 0.3 else "common"
			var item := Loot.equipment(slot, rarity, int(data.next_item))
			data.next_item += 1
			data.inventory.append(item)
			reward.gear.append(rarity.capitalize() + " " + item.name)
		if mission == 5:
			data.breaker_plates += 1
			var item := Loot.equipment("body", "uncommon", int(data.next_item))
			data.next_item += 1
			data.inventory.append(item)
			reward.gear.append(item.name)
		var medal_count := total_medals()
		for milestone in [5, 10, 15]:
			if medal_count >= milestone and milestone not in data.zone_claims:
				data.zone_claims.append(milestone)
				if milestone == 5:
					reward.credits += 495
				elif milestone == 10:
					reward.parts += 20
					data.rare_choices += 1
					reward.gear.append("Rare equipment choice • claim in your armory")
				else:
					reward.gems += 35
					data.cosmetics.append("Garage Lantern")
	data.credits += reward.credits
	data.parts += reward.parts
	data.gems += reward.gems
	data.cache_keys += reward.keys
	data.survivor_xp += reward.survivor_xp
	data.mastery[attempt["class"]] += reward.mastery_xp
	reward.combat_xp = Training.fresh()
	reward.combat_before = Training.combat_level(data.combat_xp)
	if outcome.get("progress_eligible", true):
		for stat in Training.STATS:
			var updated := minf(Training.MAX_XP, data.combat_xp[stat] + combat_earned[stat])
			reward.combat_xp[stat] = updated - data.combat_xp[stat]
			data.combat_xp[stat] = updated
	reward.combat_after = Training.combat_level(data.combat_xp)
	reward.talent_points = reward.combat_after - reward.combat_before
	data.daily = daily_state()
	Daily.record(data.daily, outcome)
	data.last_banked = id
	data.last_result = reward
	data.active_attempt = {}
	if not commit(previous):
		return {}
	return reward.duplicate(true)

func start_contract(slot: String) -> Dictionary:
	if not can_change_loadout() or not Salvage.unlocked(self) or slot not in Content.SLOTS:
		return {}
	var previous := data.duplicate(true)
	var attempt := {"id": int(data.next_attempt), "mission": 1, "class": data["class"],
		"seed": int(Time.get_unix_time_from_system()) + int(data.next_attempt) * 7919,
		"mode": "salvage", "target_slot": slot}
	data.next_attempt += 1
	data.active_attempt = attempt
	if not commit(previous):
		return {}
	return attempt.duplicate(true)

func open_cache(category: String) -> Dictionary:
	if not can_change_loadout() or category not in Loot.CATEGORIES or data.cache_keys <= 0:
		return {}
	var previous := data.duplicate(true)
	var roll := Loot.roll(category, int(data.cache_seed) + int(data.cache_opened) * 104729,
		int(data.rare_misses), int(data.epic_misses), int(data.next_item))
	data.cache_keys -= 1
	data.cache_opened += 1
	data.rare_misses = roll.rare_misses
	data.epic_misses = roll.epic_misses
	data.next_item += 1
	data.inventory.append(roll.item)
	data.last_cache = {"category": category, "item": roll.item.duplicate(true)}
	if not commit(previous):
		return {}
	return data.last_cache.duplicate(true)

func claim_rare_choice(slot: String) -> Dictionary:
	if not can_change_loadout() or data.rare_choices <= 0 or slot not in Content.SLOTS:
		return {}
	var previous := data.duplicate(true)
	var item := Loot.equipment(slot, "rare", int(data.next_item))
	data.next_item += 1
	data.rare_choices -= 1
	data.inventory.append(item)
	if not commit(previous):
		return {}
	return item.duplicate(true)

func craft_zone_item(slot: String) -> Dictionary:
	if not can_change_loadout() or slot not in Content.SLOTS or not ZoneOne.craft_unlocked(data.missions):
		return {}
	for currency: String in ZoneOne.CRAFT_COST:
		if data[currency] < ZoneOne.CRAFT_COST[currency]:
			return {}
	var previous := data.duplicate(true)
	var item := Loot.equipment(slot, "rare", int(data.next_item))
	for currency: String in ZoneOne.CRAFT_COST:
		data[currency] -= ZoneOne.CRAFT_COST[currency]
	data.next_item += 1
	data.inventory.append(item)
	if not commit(previous):
		return {}
	return item.duplicate(true)

func total_medals() -> int:
	var count := 0
	for medals in data.missions.values():
		count += medals.size()
	return count

func checkpoint(snapshot: Dictionary) -> bool:
	if blocked or data.active_attempt.is_empty():
		return false
	var previous := data.duplicate(true)
	data.active_attempt.checkpoint = Marshalls.variant_to_base64(snapshot, false)
	if data.active_attempt.get("mode", "campaign") == "campaign" and snapshot.get("combat", {}).get("boss_id", -1) >= 0:
		var mission: int = data.active_attempt.mission
		if mission not in data.seen_bosses:
			data.seen_bosses.append(mission)
	return commit(previous)

func practice_unlocked(mission: int) -> bool:
	return mission in data.seen_bosses or "clear" in data.missions.get(str(mission), [])

func saved_run() -> Dictionary:
	var encoded: String = data.active_attempt.get("checkpoint", "")
	if encoded.is_empty():
		return {}
	var decoded: Variant = Marshalls.base64_to_variant(encoded, false)
	return decoded if decoded is Dictionary else {}

func purchase_supply(offer: String) -> bool:
	if blocked or offer not in SHOP_OFFERS:
		return false
	var definition: Dictionary = SHOP_OFFERS[offer]
	if data[definition.currency] < definition.cost:
		error = "Not enough " + definition.currency + "."
		return false
	var previous := data.duplicate(true)
	data[definition.currency] -= definition.cost
	data[definition.grant] += definition.amount
	return commit(previous)

func shop_videos_left() -> int:
	var today := Time.get_date_string_from_system(true)
	return 2 - int(data.shop_videos) if data.shop_day == today else 2

func grant_shop_video(token: String) -> bool:
	# Called only by the token-matched earned callback, never by ad dismissal.
	if blocked or token.is_empty():
		return false
	if data.last_shop_reward == token:
		return true
	if shop_videos_left() <= 0:
		return false
	var previous := data.duplicate(true)
	var today := Time.get_date_string_from_system(true)
	if data.shop_day != today:
		data.shop_day = today
		data.shop_videos = 0
	data.shop_videos += 1
	data.cache_keys += 1
	data.last_shop_reward = token
	return commit(previous)

func set_setting(key: String, value: Variant) -> bool:
	if blocked or key not in data.settings:
		return false
	if key in ["music", "sound"]:
		if not (value is float or value is int) or value < 0 or value > 1:
			return false
	elif not value is bool:
		return false
	var previous := data.duplicate(true)
	data.settings[key] = value
	return commit(previous)

func daily_state() -> Dictionary:
	return Daily.at_day(data.daily, maxi(0, floori(float(utc_now.call()) / 86400.0)))

func claim_daily_bonus() -> bool:
	if blocked:
		return false
	var next := daily_state()
	var count := Daily.available_bonuses(next)
	if count <= 0:
		return false
	var previous := data.duplicate(true)
	for key in Daily.BONUS:
		data[key] += Daily.BONUS[key] * count
	next.pending_bonuses = 0
	next.claimed = Daily.completed(next) >= 3
	data.daily = next
	return commit(previous)

func claim_calendar() -> bool:
	if blocked:
		return false
	var next := daily_state()
	if next.day <= next.calendar_day:
		return false
	var reward: Dictionary = Daily.CALENDAR[next.calendar_count % Daily.CALENDAR.size()]
	var previous := data.duplicate(true)
	for key in reward:
		data[key] += reward[key]
	next.calendar_count += 1
	next.calendar_day = next.day
	data.daily = next
	return commit(previous)
