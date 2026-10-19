extends RefCounted
## Equipment rewards use a separate deterministic stream from combat and offers.
const Content = preload("res://haven_content.gd")
const CATEGORIES := {
	"supply": {"name": "Supply Crate", "slots": Content.SLOTS},
	"weapons": {"name": "Weapons Cache", "slots": ["weapon"]},
	"armor": {"name": "Armor Locker", "slots": ["helmet", "body", "boots", "pants"]},
	"engineer": {"name": "Engineer's Case", "slots": ["charm", "gadget", "ring"]}}

static func affixes(slot: String, rarity: String, identity: int) -> Array:
	var count: int = [0, 1, 1, 2, 3, 3][Content.RARITIES.find(rarity)]
	var pool: Array = []
	for id: String in Content.AFFIXES:
		if slot in Content.AFFIXES[id].slots:
			pool.append(id)
	var rng := RandomNumberGenerator.new()
	rng.seed = identity * 7937 + 631
	var result: Array = []
	for index in mini(count, pool.size()):
		var choice := rng.randi_range(0, pool.size() - 1)
		result.append(pool[choice])
		pool.remove_at(choice)
	return result

static func equipment(slot: String, rarity: String, identity: int, armor_set: String = "outrider") -> Dictionary:
	var name: String = Content.STARTER_NAMES[Content.SLOTS.find(slot)]
	if slot in Content.ARMOR_SLOTS and armor_set in Content.SETS:
		name = Content.SETS[armor_set].pieces[Content.ARMOR_SLOTS.find(slot)]
	return {"id": identity, "slot": slot, "name": name,
		"rarity": rarity, "level": 1, "affixes": affixes(slot, rarity, identity)}

static func roll(category: String, seed_value: int, rare_misses: int, epic_misses: int, identity: int) -> Dictionary:
	if category not in CATEGORIES:
		return {}
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var roll_value := rng.randf()
	var rarity := "common" if roll_value < 0.55 else ("uncommon" if roll_value < 0.85 else ("rare" if roll_value < 0.98 else "epic"))
	if epic_misses >= 29:
		rarity = "epic"
	elif rare_misses >= 9 and Content.RARITIES.find(rarity) < 2:
		rarity = "rare"
	var slots: Array = CATEGORIES[category].slots
	var slot: String = slots[rng.randi_range(0, slots.size() - 1)]
	# Future-zone sets remain valid in owned saves, but are not new Outskirts drops.
	var item := equipment(slot, rarity, identity)
	return {"item": item, "rare_misses": 0 if Content.RARITIES.find(rarity) >= 2 else rare_misses + 1,
		"epic_misses": 0 if Content.RARITIES.find(rarity) >= 3 else epic_misses + 1}

