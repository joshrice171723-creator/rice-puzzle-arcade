extends RefCounted
## Local, versioned Haven profile. A failed write rolls the transaction back.

const Content = preload("res://haven_content.gd")
const VERSION := 1
var path := "user://haven.json"
var data: Dictionary = {}
var error := ""
var blocked := false

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
		"mastery": {"scavenger": 0, "engineer": 0, "warden": 0, "arcanist": 0}, "class": "scavenger",
		"inventory": items, "equipment": equipment, "next_item": 6, "missions": {}, "zone_claims": [],
		"facilities": {"workshop": 1, "quartermaster": 1, "infirmary": 1},
		"next_attempt": 1, "active_attempt": {}, "last_result": {}, "last_banked": 0,
		"breaker_plates": 0, "cosmetics": [], "tutorial_seen": false}

func valid(candidate: Variant) -> bool:
	if not candidate is Dictionary or candidate.get("version") != VERSION:
		return false
	var defaults := fresh()
	for key: String in defaults:
		if not candidate.has(key):
			return false
	for key in ["credits", "parts", "gems", "survivor_xp", "next_item", "next_attempt", "last_banked", "breaker_plates"]:
		if not (candidate[key] is int or candidate[key] is float) or candidate[key] < 0 or candidate[key] != floor(candidate[key]):
			return false
	if candidate["class"] not in Content.CLASSES or not candidate.inventory is Array or not candidate.equipment is Dictionary or not candidate.missions is Dictionary or not candidate.facilities is Dictionary or not candidate.mastery is Dictionary:
		return false
	if not candidate.active_attempt is Dictionary or not candidate.last_result is Dictionary or not candidate.zone_claims is Array or not candidate.cosmetics is Array or not candidate.tutorial_seen is bool:
		return false
	var ids: Array = []
	for item in candidate.inventory:
		if not item is Dictionary or not item.get("id") is float and not item.get("id") is int:
			return false
		if item.id in ids or item.id < 0 or item.id >= candidate.next_item or item.get("slot") not in Content.SLOTS or item.get("rarity") not in Content.RARITIES:
			return false
		if not item.get("name") is String or not (item.get("level") is int or item.get("level") is float) or item.level < 1 or item.level > 30:
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
	return normalize_numbers(parser.data)

func normalize_numbers(value: Variant) -> Variant:
	# JSON numbers load as floats. Stable integer IDs are needed for Array.has
	# and once-only milestone claims after a restart.
	if value is float and value == floor(value):
		return int(value)
	if value is Dictionary:
		for key in value:
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

func salvage(id: int) -> bool:
	var item := item_by_id(id)
	if not can_change_loadout() or item.is_empty() or id in data.equipment.values():
		return false
	var previous := data.duplicate(true)
	data.parts += 2 + Content.RARITIES.find(item.rarity) + int(item.level) - 1
	data.inventory.erase(item)
	return commit(previous)

func promotion_cost(id: int) -> Dictionary:
	var item := item_by_id(id)
	if item.is_empty() or item.rarity not in ["common", "uncommon"]:
		return {}
	var tier := Content.RARITIES.find(item.rarity)
	return {"credits": 180 * (tier + 1), "parts": 10 * (tier + 1), "rarity": Content.RARITIES[tier + 1]}

func promote(id: int) -> bool:
	var cost := promotion_cost(id)
	if not can_change_loadout() or cost.is_empty() or data.credits < cost.credits or data.parts < cost.parts:
		return false
	var previous := data.duplicate(true)
	data.credits -= cost.credits
	data.parts -= cost.parts
	item_by_id(id).rarity = cost.rarity
	return commit(previous)

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

func stats() -> Dictionary:
	var result := {"hp": 120.0 + 4.0 * (Content.survivor_level(data.survivor_xp) - 1), "power": 0.0, "armor": 0.0,
		"speed": 1.05 if data["class"] == "scavenger" else 1.0, "pickup": 1.15 if data["class"] == "scavenger" else 1.0,
		"capacity": 8 + int(data.facilities.quartermaster) - 1, "secure": 2,
		"medkit": 0.25 if data.facilities.infirmary >= 2 else 0.20, "class": data["class"]}
	var outrider := 0
	for slot: String in Content.SLOTS:
		var item := item_by_id(data.equipment[slot])
		var values := Content.item_stats(item)
		for stat in ["hp", "power", "armor"]:
			result[stat] += values[stat]
		if item.name.begins_with("Outrider") and Content.RARITIES.find(item.rarity) >= 2:
			outrider += 1
	if outrider >= 2:
		result.pickup += 0.15
	if outrider >= 3:
		result.secure += 1
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
	var previous := data.duplicate(true)
	var attempt: Dictionary = data.active_attempt
	var mission: int = attempt.mission
	var victory: bool = outcome.get("victory", false)
	var reward := {"victory": victory, "mission": mission, "credits": int(outcome.get("credits", 0)), "parts": 0, "gems": 0,
		"survivor_xp": int(outcome.get("survivor_xp", 0)), "mastery_xp": int(outcome.get("mastery_xp", 0)), "gear": [], "new_medals": [], "lost": int(outcome.get("lost", 0))}
	for loot in outcome.get("loot", []):
		if loot.kind == "parts":
			reward.parts += int(loot.amount)
		elif loot.kind == "gear":
			var item := {"id": int(data.next_item), "slot": loot.slot, "name": loot.name, "rarity": loot.rarity, "level": 1}
			data.next_item += 1
			data.inventory.append(item)
			reward.gear.append(item.name)
	if victory:
		var scale := 1.5 if mission == 5 else 1.0
		reward.credits += roundi(165 * scale)
		reward.parts += roundi(3 * scale)
		reward.survivor_xp += roundi(85 * scale)
		reward.mastery_xp += roundi(45 * scale)
		var earned: Array = ["clear"]
		if outcome.get("damage_taken", 999) <= 8 and not outcome.get("rescued", false):
			earned.append("combat")
		if outcome.get("caches", 0) >= 3:
			earned.append("scavenger")
		var medals: Array = data.missions.get(str(mission), [])
		if "clear" not in medals:
			reward.gems += 40 if mission == 5 else 10
		for medal in earned:
			if medal not in medals:
				medals.append(medal)
				reward.new_medals.append(medal)
				if medal != "clear":
					reward.credits += 55
		data.missions[str(mission)] = medals
		if mission == 5:
			data.breaker_plates += 1
			var item := {"id": int(data.next_item), "slot": "body", "name": "Outrider Vest", "rarity": "uncommon", "level": 1}
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
					var item := {"id": int(data.next_item), "slot": "weapon", "name": "Service Pistol", "rarity": "rare", "level": 1}
					data.next_item += 1
					data.inventory.append(item)
					reward.gear.append("Rare Service Pistol")
				else:
					reward.gems += 35
					data.cosmetics.append("Garage Lantern")
	data.credits += reward.credits
	data.parts += reward.parts
	data.gems += reward.gems
	data.survivor_xp += reward.survivor_xp
	data.mastery[attempt["class"]] += reward.mastery_xp
	data.last_banked = id
	data.last_result = reward
	data.active_attempt = {}
	if not commit(previous):
		return {}
	return reward.duplicate(true)

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
	return commit(previous)

func saved_run() -> Dictionary:
	var encoded: String = data.active_attempt.get("checkpoint", "")
	if encoded.is_empty():
		return {}
	var decoded: Variant = Marshalls.base64_to_variant(encoded, false)
	return decoded if decoded is Dictionary else {}
