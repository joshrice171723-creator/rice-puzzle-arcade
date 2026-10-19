extends RefCounted
## Small, destructible investments in positioning. Never a required objective.

const CAPACITY := 8
const TYPES := {
	"barricade": {"name": "Scrap Barricade", "cost": 20, "capacity": 1, "hp": 180.0, "radius": 25.0, "description": "Blocks approaching enemies. Bosses can smash it."},
	"turret": {"name": "Bolt Turret", "cost": 50, "capacity": 3, "hp": 100.0, "radius": 19.0, "description": "Fires one bolt every 0.8s at enemies within 240. Maximum two turrets."},
	"trap": {"name": "Ember Trap", "cost": 30, "capacity": 1, "hp": 1.0, "radius": 15.0, "description": "Triggers once: 48 fire damage within 80. Consumed when triggered."},
	"ward": {"name": "Ward Pylon", "cost": 40, "capacity": 2, "hp": 80.0, "radius": 18.0, "description": "Within 100, take 10% less damage. Multiple wards do not stack."}}
var structures: Array[Dictionary] = []
var next_id := 0
var notice := ""

func used_capacity() -> int:
	var total := 0
	for structure in structures:
		if structure.hp > 0:
			total += TYPES[structure.kind].capacity
	return total

func can_place(kind: String, position: Vector2, sites: Array, player: Vector2) -> bool:
	if kind not in TYPES or structures.size() >= 8 or used_capacity() + TYPES[kind].capacity > CAPACITY:
		notice = "Not enough field capacity."
		return false
	if kind == "turret" and structures.filter(func(s: Dictionary): return s.kind == "turret" and s.hp > 0).size() >= 2:
		notice = "Only two damaging turrets can be active."
		return false
	if not preload("res://world_geometry.gd").BOUNDS.grow(-35).has_point(position) or position.distance_to(player) < 45:
		notice = "Move away from the edge to place a structure."
		return false
	for site in sites:
		if position.distance_to(site.pos) < (90 if site.kind == "cache" else 200):
			notice = "Keep shrine and cache approaches clear."
			return false
	for entry: Dictionary in preload("res://neighborhood.gd").entries():
		if entry.footprint.grow(TYPES[kind].radius+8).has_point(position):
			notice = "Keep buildings and vehicle approaches clear."
			return false
	for structure in structures:
		if position.distance_to(structure.pos) < 80:
			notice = "Leave more space between structures."
			return false
	return true

func place(kind: String, position: Vector2, power: float, engineer: bool) -> void:
	var hp: float = TYPES[kind].hp * (1.1 if engineer else 1.0)
	structures.append({"id": next_id, "kind": kind, "pos": position, "hp": hp, "max_hp": hp,
		"wait": 0.4, "hurt_wait": 0.0, "repair_left": 0.0, "power": minf(2.5, power / 40.0), "target": position})
	next_id += 1
	notice = "%s placed." % TYPES[kind].name

func repair_nearest(position: Vector2, strength: float = 1.0, mastery: int = 0) -> bool:
	var target: Dictionary = {}
	var distance := 300.0
	for structure in structures:
		if structure.hp <= 0 or structure.hp >= structure.max_hp or structure.repair_left > 0:
			continue
		var next_distance: float = position.distance_to(structure.pos)
		if next_distance < distance:
			distance = next_distance
			target = structure
	if target.is_empty():
		notice = "No damaged structure within repair range."
		return false
	target.repair_left = 4.0
	target.repair_rate = 0.05 * strength
	if mastery >= 10 and target.kind == "turret":
		target.boost_left = 4.0
	if mastery >= 20:
		var adjacent := {}
		var adjacent_distance := 150.0
		for structure in structures:
			var distance_to_target: float = structure.pos.distance_to(target.pos)
			if structure.id != target.id and structure.hp > 0 and structure.hp < structure.max_hp and distance_to_target < adjacent_distance:
				adjacent = structure
				adjacent_distance = distance_to_target
		if not adjacent.is_empty():
			adjacent.hp = minf(adjacent.max_hp, adjacent.hp + adjacent.max_hp * 0.05)
	notice = "Repair Swarm is restoring %s." % TYPES[target.kind].name
	return true

func mitigation(position: Vector2) -> float:
	for structure in structures:
		if structure.hp > 0 and structure.kind == "ward" and structure.pos.distance_to(position) <= 100:
			return 0.10
	return 0.0

func nearest_structure(position: Vector2, range_value: float = 80.0) -> Dictionary:
	var found := {}
	var distance := range_value
	for structure in structures:
		var next_distance: float = position.distance_to(structure.pos)
		if structure.hp > 0 and next_distance < distance:
			found = structure
			distance = next_distance
	return found

func tick(delta: float, run: RefCounted) -> void:
	for structure in structures:
		if structure.hp <= 0:
			continue
		structure.wait = maxf(0, structure.wait - delta)
		structure.hurt_wait = maxf(0, structure.hurt_wait - delta)
		structure.boost_left = maxf(0, structure.get("boost_left", 0.0) - delta)
		if structure.repair_left > 0:
			structure.hp = minf(structure.max_hp, structure.hp + structure.max_hp * structure.get("repair_rate", 0.05) * minf(delta, structure.repair_left))
			structure.repair_left = maxf(0, structure.repair_left - delta)
		if structure.kind == "turret" and structure.wait == 0:
			var target: Dictionary = run.nearest_enemy(structure.pos, 240)
			if not target.is_empty():
				run.damage_enemy(target, 8 * structure.power * (1+run.talent_effects.structure_damage) * (1.0 + 0.06 * run.passive_rank("mechanic")), structure.pos)
				run.add_effect("turret", structure.pos, target.pos, 0.12)
				structure.target = target.pos
				structure.wait = 0.8 / (1.15 if structure.boost_left > 0 else 1.0)
		elif structure.kind == "trap":
			var target: Dictionary = run.nearest_enemy(structure.pos, 36)
			if not target.is_empty():
				for enemy in run.enemies:
					if enemy.hp > 0 and enemy.pos.distance_to(structure.pos) <= 80:
						run.damage_enemy(enemy, 48 * structure.power * (1+run.talent_effects.structure_damage) * (1.0 + 0.06 * run.passive_rank("mechanic")), structure.pos, true)
				run.add_effect("trap", structure.pos, structure.pos, 0.45)
				structure.hp = 0.0
		for enemy in run.enemies:
			if enemy.hp <= 0 or structure.hp <= 0 or structure.kind == "trap":
				continue
			var radius: float = TYPES[structure.kind].radius + (30 if enemy.boss else 17)
			var offset: Vector2 = enemy.pos - structure.pos
			if offset.length() < radius:
				enemy.pos = run.clamp_position(structure.pos + (offset.normalized() if offset.length() > 0.01 else Vector2.RIGHT) * radius)
	structures = structures.filter(func(s: Dictionary): return s.hp > 0)
