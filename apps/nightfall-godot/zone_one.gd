extends RefCounted
## Authored acquisition rules for the five playable Blackout Outskirts missions.
const Content = preload("res://haven_content.gd")
const FAMILY_IDS := ["service_pistol", "outrider_hood", "outrider_vest", "outrider_boots", "beacon_pendant", "field_medkit", "beacon_ring", "outrider_trousers"]
const CRAFT_COST := {"breaker_plates": 8, "credits": 330, "parts": 5}

static func catalog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for index in Content.SLOTS.size():
		var slot: String = Content.SLOTS[index]
		var item := {"name": Content.STARTER_NAMES[index], "slot": slot}
		result.append({"family": FAMILY_IDS[index], "name": item.name, "slot": slot,
			"first_zone": 1, "drop_level": 1, "level_cap": 5, "set": Content.set_id(item),
			"field_rarity_max": "uncommon", "crate_rarity_max": "epic", "craft_rarity": "rare",
			"base_stats": Content.BASE_STATS[slot].duplicate(),
			"sources": ["starter", "field_cache", "captain", "supply_crate", "targeted_contract", "rare_choice", "breaker_craft"]})
	return result

static func family_for_slot(slot: String) -> String:
	var index := Content.SLOTS.find(slot)
	return FAMILY_IDS[index] if index >= 0 else ""

static func craft_unlocked(missions: Dictionary) -> bool:
	return "clear" in missions.get("5", [])
