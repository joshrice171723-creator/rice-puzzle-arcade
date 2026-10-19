extends RefCounted
## Attempt-local exploration. Money here cannot spend the Haven wallet.

const TRAITS := {
	"vitality": {"name": "Vitality", "description": "+10% maximum health per rank. Heal the added health."},
	"aim": {"name": "Steady Aim", "description": "+6% weapon damage per rank."},
	"reach": {"name": "Long Reach", "description": "+25% XP pickup reach per rank."}}
const RELICS := {
	"emberleaf": {"name": "Emberleaf", "description": "After 4 seconds without damage, recover 0.15% maximum HP per second."},
	"obsidian": {"name": "Obsidian Heart", "description": "Take 10% less damage. Move 5% slower."},
	"feather": {"name": "Storm Feather", "description": "Dodge recharges 15% faster. Weapon damage is 5% lower."},
	"lantern": {"name": "Wisp Lantern", "description": "A wisp strikes one nearby enemy for 12 damage every 3 seconds."},
	"moonstone": {"name": "Moonstone", "description": "+12% maximum health. Recover that added health immediately."},
	"cinder": {"name": "Cinder Lens", "description": "+8% spell damage. Your pickup reach is 10% smaller."}}
const TRAIT_COSTS := [30, 45, 65]
const RADIUS := 60.0
const Content = preload("res://haven_content.gd")
var rng := RandomNumberGenerator.new()
var sites: Array[Dictionary] = []
var scrap := 0
var credits := 0
var bag: Array[Dictionary] = []
var capacity := 8
var secure_capacity := 2
var traits := {"vitality": 0, "aim": 0, "reach": 0}
var relics: Array[String] = []
var active_site := -1
var caches_opened := 0
var notice := ""
var revision := 0
var drops: Array[Dictionary] = []
var next_loot_id := 0

func _init(seed_value: int = 41) -> void:
	rng.seed = seed_value + 7049
	for entry in [
		["shop", Vector2(600, 460), "Artificer's Shrine", 2.0],
		["relic", Vector2(310, 330), "Twinflame Shrine", 7.0],
		["relic", Vector2(890, 860), "Twinflame Shrine", 7.0],
		["cache", Vector2(385, 640), "Garage Supply Cache", 1.5],
		["cache", Vector2(810, 350), "Abandoned Tool Chest", 1.5],
		["cache", Vector2(320, 900), "Outrider's Pack", 1.5],
		["cache", Vector2(920, 620), "Sealed Supply Crate", 1.5]]:
		sites.append({"kind": entry[0], "pos": entry[1], "name": entry[2], "duration": entry[3],
			"progress": 0.0, "away": 0.0, "cooldown": 0.0, "opened": false,
			"must_leave": false, "offers": [], "rerolls": 0})

func available(site: Dictionary) -> bool:
	return not site.opened and site.cooldown <= 0.0 and not site.must_leave and not (site.kind == "relic" and relics.size() >= 3)

func tick(delta: float, position: Vector2) -> bool:
	if active_site >= 0:
		return false
	collect_drops(position, 36.0)
	for index in sites.size():
		var site := sites[index]
		site.cooldown = maxf(0, site.cooldown - delta)
		var close := position.distance_to(site.pos) <= RADIUS
		if not close:
			site.must_leave = false
			site.away += delta
			if site.away > 1.0:
				site.progress = maxf(0, site.progress - delta * site.duration / 3.0)
			continue
		if not available(site):
			continue
		site.away = 0.0
		site.progress = minf(site.duration, site.progress + delta)
		if site.progress < site.duration:
			continue
		if site.kind == "cache":
			open_cache(index)
			continue
		active_site = index
		notice = ""
		if site.kind == "relic" and site.offers.is_empty():
			site.offers = roll_relics()
		revision += 1
		return true
	return false

func collect_drops(position: Vector2, radius: float) -> void:
	for i in range(drops.size() - 1, -1, -1):
		if position.distance_to(drops[i].pos) <= radius:
			credits += drops[i].credits
			scrap += drops[i].scrap
			drops.remove_at(i)

func add_drop(position: Vector2, credit_value: int, scrap_value: int) -> void:
	# Merge nearby coins before applying a hard bound; never create hundreds of objects.
	for drop in drops:
		if drop.pos.distance_to(position) < 55.0:
			drop.credits += credit_value
			drop.scrap += scrap_value
			return
	if drops.size() < 48:
		drops.append({"pos": position, "credits": credit_value, "scrap": scrap_value})
	else:
		# Preserve earned loot when the rendering budget is full.
		var nearest: Dictionary = drops[0]
		for drop in drops:
			if drop.pos.distance_squared_to(position) < nearest.pos.distance_squared_to(position):
				nearest = drop
		nearest.credits += credit_value
		nearest.scrap += scrap_value

func add_loot(kind: String, name_value: String, amount: int = 1, rarity: String = "common", slot: String = "") -> bool:
	if bag.size() >= capacity:
		notice = "Backpack full. Secure or discard loot before opening another cache."
		return false
	bag.append({"id": next_loot_id, "kind": kind, "name": name_value, "amount": amount,
		"rarity": rarity, "slot": slot, "secure": false})
	next_loot_id += 1
	return true

func open_cache(index: int) -> void:
	var site := sites[index]
	if site.opened or site.kind != "cache":
		return
	if bag.size() >= capacity:
		site.must_leave = true
		site.progress = 0.0
		notice = "Backpack full. Open your pack to make room."
		return
	# Cache rewards are rolled once, on collection; reopening cannot reroll loot.
	if index == 5:
		add_loot("gear", "Outrider Boots", 1, "uncommon", "boots")
	elif rng.randf() < 0.25:
		var slot_index := rng.randi_range(0, Content.SLOTS.size() - 1)
		add_loot("gear", Content.STARTER_NAMES[slot_index], 1, "uncommon" if rng.randf() < 0.3 else "common", Content.SLOTS[slot_index])
	else:
		add_loot("parts", "Workshop Parts", rng.randi_range(2, 4))
	scrap += rng.randi_range(15, 24)
	credits += rng.randi_range(8, 15)
	site.opened = true
	caches_opened += 1
	notice = "%s opened. Loot is in your pack." % site.name
	revision += 1

func set_secure(loot_id: int, value: bool) -> bool:
	for item in bag:
		if item.id != loot_id:
			continue
		if value and not item.secure and secured_count() >= secure_capacity:
			return false
		item.secure = value
		revision += 1
		return true
	return false

func secured_count() -> int:
	var count := 0
	for item in bag:
		if item.secure:
			count += 1
	return count

func discard(loot_id: int) -> bool:
	for index in bag.size():
		if bag[index].id == loot_id and not bag[index].secure:
			bag.remove_at(index)
			revision += 1
			return true
	return false

func banked_loot(victory: bool) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in bag:
		if victory or item.secure:
			result.append(item.duplicate(true))
	return result

func trait_cost(id: String) -> int:
	if not traits.has(id) or traits[id] >= 3:
		return -1
	return TRAIT_COSTS[int(traits[id])]

func buy_trait(id: String) -> bool:
	if active_site < 0 or sites[active_site].kind != "shop":
		return false
	var cost := trait_cost(id)
	if cost < 0 or scrap < cost:
		return false
	scrap -= cost
	traits[id] += 1
	notice = "%s is now rank %d/3." % [TRAITS[id].name, traits[id]]
	revision += 1
	return true

func roll_relics(previous: Array = []) -> Array[String]:
	var pool: Array[String] = []
	for id: String in RELICS:
		if id not in relics and id not in previous:
			pool.append(id)
	if pool.size() < 2:
		for id: String in RELICS:
			if id not in relics and id not in pool:
				pool.append(id)
	var result: Array[String] = []
	while result.size() < 2 and not pool.is_empty():
		var index := rng.randi_range(0, pool.size() - 1)
		result.append(pool[index])
		pool.remove_at(index)
	return result

func reroll_cost() -> int:
	if active_site < 0 or sites[active_site].kind != "relic" or sites[active_site].rerolls >= 2:
		return -1
	return 10 * (int(sites[active_site].rerolls) + 1)

func reroll() -> bool:
	var cost := reroll_cost()
	if cost < 0 or scrap < cost:
		return false
	var site := sites[active_site]
	scrap -= cost
	site.rerolls += 1
	site.offers = roll_relics(site.offers)
	revision += 1
	return true

func choose_relic(index: int) -> String:
	if active_site < 0 or sites[active_site].kind != "relic" or relics.size() >= 3:
		return ""
	var site := sites[active_site]
	if index < 0 or index >= site.offers.size():
		return ""
	var id: String = site.offers[index]
	if id in relics:
		return ""
	relics.append(id)
	site.offers = []
	site.rerolls = 0
	site.cooldown = 45.0
	leave()
	return id

func leave() -> void:
	if active_site >= 0:
		sites[active_site].progress = 0.0
		sites[active_site].must_leave = true
	active_site = -1
	revision += 1

func health_multiplier() -> float:
	return 1.0 + 0.1 * traits.vitality + (0.12 if "moonstone" in relics else 0.0)

func damage_multiplier() -> float:
	return (1.0 + 0.06 * traits.aim) * (0.95 if "feather" in relics else 1.0)

func pickup_multiplier() -> float:
	return (1.0 + 0.25 * traits.reach) * (0.9 if "cinder" in relics else 1.0)
