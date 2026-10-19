extends RefCounted
## Fixed-step combat and attempt-local exploration rules.

const DURATION := 240.0
const Content = preload("res://combat_content.gd")
const Field = preload("res://field.gd")
const Haven = preload("res://haven_content.gd")
const Defenses = preload("res://defenses.gd")
const Magic = preload("res://magic.gd")
const Salvage = preload("res://salvage.gd")
const MAX_ENEMIES := 120
const MAX_SHOTS := 64
const BOUNDS := Rect2(135, 135, 930, 930)
var rng := RandomNumberGenerator.new()
var player := Vector2(600, 600)
var facing := Vector2.RIGHT
var health := 120.0
var elapsed := 0.0
var phase := "waves"
var paused := false
var kills := 0
var shots: Array[Dictionary] = []
var hostile_shots: Array[Dictionary] = []
var effects: Array[Dictionary] = []
var spells: Dictionary = {}
var offers: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var pickups: Array[Vector2] = []
var xp := 0
var level := 1
var damage := 24.0
var fire_interval := 0.35
var fire_wait := 0.0
var spawn_wait := 0.0
var hurt_wait := 0.0
var dodge_wait := 0.0
var dodge_left := 0.0
var pulse_wait := 0.0
var pulse_flash := 0.0
var benchmark_count := 0
var boss_id := -1
var next_id := 0
var practice := false
var field: RefCounted
var base_health := 120.0
var damage_taken := 0
var last_damage_at := -100.0
var wisp_wait := 0.0
var survivor_xp := 0
var mastery_xp := 0
var mission := 0
var duration := DURATION
var boss_name := "The Breaker"
var armor := 0.0
var speed_multiplier := 1.0
var pickup_multiplier := 1.0
var spell_multiplier := 1.0
var medkit_fraction := 0.0
var medkit_used := false
var class_id := "scavenger"
var class_wait := 0.0
var shield := 0.0
var shield_left := 0.0
var ability_notice := ""
var defenses = Defenses.new()
var build_revision := 0
var blueprints: Array[String] = ["barricade", "trap"]
var mastery_level := 0
var rescued := false
var passives: Dictionary = {}
var offer_rng := RandomNumberGenerator.new()
var zones: Array[Dictionary] = []
var wisp_hits: Dictionary = {}
var permanent_cooldown := 0.0
var reinforcements_spawned := 0
var offer_back: Array[Dictionary] = []
var mode := "campaign"
var extract_progress := 0.0
var target_slot := "weapon"

const SNAPSHOT_KEYS := ["player", "facing", "health", "elapsed", "phase", "kills", "shots", "hostile_shots", "effects", "spells", "offers", "enemies", "pickups", "xp", "level", "damage", "fire_interval", "fire_wait", "spawn_wait", "hurt_wait", "dodge_wait", "dodge_left", "pulse_wait", "pulse_flash", "boss_id", "next_id", "base_health", "damage_taken", "last_damage_at", "wisp_wait", "survivor_xp", "mastery_xp", "mission", "duration", "boss_name", "armor", "speed_multiplier", "pickup_multiplier", "spell_multiplier", "medkit_fraction", "medkit_used", "class_id", "class_wait", "shield", "shield_left"]
const FIELD_KEYS := ["sites", "scrap", "credits", "bag", "capacity", "secure_capacity", "traits", "relics", "active_site", "caches_opened", "notice", "revision", "drops", "next_loot_id"]

func _init(seed_value: int = 41) -> void:
	rng.seed = seed_value
	field = Field.new(seed_value)
	offer_rng.seed = seed_value + 3217

func configure(mission_number: int, stats: Dictionary) -> void:
	mission = clampi(mission_number, 1, Haven.MISSIONS.size())
	var definition: Dictionary = Haven.MISSIONS[mission - 1]
	duration = definition.duration
	boss_name = definition.boss
	base_health = stats.hp
	health = max_health()
	damage = stats.power * 0.6
	fire_interval = 0.6
	armor = stats.armor
	speed_multiplier = stats.speed
	pickup_multiplier = stats.pickup
	spell_multiplier = stats.power / 40.0
	field.capacity = stats.capacity
	field.secure_capacity = stats.secure
	medkit_fraction = stats.medkit
	class_id = stats["class"]
	blueprints.assign(stats.get("blueprints", ["barricade", "trap"]))
	mastery_level = stats.get("mastery", 0)
	permanent_cooldown = clampf(stats.get("cooldown", 0.0), 0, 0.15)

func configure_contract(stats: Dictionary, slot: String) -> void:
	configure(1, stats)
	mode = "salvage"
	target_slot = slot
	duration = Salvage.DURATION
	boss_name = "Salvage Contract"

func snapshot() -> Dictionary:
	var values := {}
	for key in SNAPSHOT_KEYS:
		values[key] = get(key)
	var exploration := {}
	for key in FIELD_KEYS:
		exploration[key] = field.get(key)
	return {"version": 1, "combat": values.duplicate(true), "field": exploration.duplicate(true), "rng": rng.state, "field_rng": field.rng.state, "rescued": rescued,
		"defenses": defenses.structures.duplicate(true), "next_structure": defenses.next_id, "blueprints": blueprints.duplicate(), "mastery": mastery_level,
		"passives": passives.duplicate(true), "offer_rng": offer_rng.state, "zones": zones.duplicate(true), "wisp_hits": wisp_hits.duplicate(), "permanent_cooldown": permanent_cooldown,
		"reinforcements_spawned": reinforcements_spawned, "offer_back": offer_back.duplicate(true),
		"mode": mode, "extract_progress": extract_progress, "target_slot": target_slot}

func restore(saved: Dictionary) -> bool:
	if saved.get("version") != 1 or not saved.get("combat") is Dictionary or not saved.get("field") is Dictionary:
		return false
	for key in SNAPSHOT_KEYS:
		if not saved.combat.has(key) or typeof(saved.combat[key]) != typeof(get(key)):
			return false
	for key in FIELD_KEYS:
		if not saved.field.has(key) or typeof(saved.field[key]) != typeof(field.get(key)):
			return false
	if saved.combat.phase not in ["waves", "boss", "upgrade", "shrine", "pack", "build", "victory", "defeat"] or saved.combat.mission not in range(1, 6):
		return false
	if saved.combat.enemies.size() > MAX_ENEMIES or saved.combat.shots.size() > MAX_SHOTS or saved.field.sites.size() != 7 or saved.field.bag.size() > 12:
		return false
	if saved.get("mode", "campaign") not in ["campaign", "salvage"] or saved.get("target_slot", "weapon") not in Haven.SLOTS:
		return false
	for key in SNAPSHOT_KEYS:
		set(key, saved.combat[key])
	for key in FIELD_KEYS:
		field.set(key, saved.field[key])
	rng.state = saved.rng
	field.rng.state = saved.field_rng
	defenses.structures.assign(saved.get("defenses", []))
	defenses.next_id = saved.get("next_structure", 0)
	blueprints.assign(saved.get("blueprints", ["barricade", "trap"]))
	mastery_level = saved.get("mastery", 0)
	rescued = saved.get("rescued", false)
	passives = saved.get("passives", {}).duplicate(true)
	offer_rng.state = saved.get("offer_rng", offer_rng.state)
	zones.assign(saved.get("zones", []))
	wisp_hits = saved.get("wisp_hits", {}).duplicate()
	permanent_cooldown = saved.get("permanent_cooldown", 0.0)
	reinforcements_spawned = saved.get("reinforcements_spawned", 0)
	offer_back.assign(saved.get("offer_back", []))
	mode = saved.get("mode", "campaign")
	extract_progress = saved.get("extract_progress", 0.0)
	target_slot = saved.get("target_slot", "weapon")
	paused = true
	return true

func result() -> Dictionary:
	var won := phase == "victory"
	var loot: Array = field.banked_loot(won)
	return {"victory": won, "credits": field.credits, "survivor_xp": survivor_xp,
		"mastery_xp": mastery_xp, "loot": loot, "damage_taken": damage_taken,
		"caches": field.caches_opened, "lost": field.bag.size() - loot.size(), "rescued": rescued}

func rescue() -> bool:
	if phase != "defeat" or rescued or practice or benchmark_count > 0 or (mode == "salvage" and elapsed >= duration):
		return false
	rescued = true
	health = max_health() * 0.5
	hurt_wait = 2.5
	hostile_shots.clear()
	for enemy in enemies:
		if player.distance_to(enemy.pos) < 100:
			var direction := player.direction_to(enemy.pos)
			if direction == Vector2.ZERO:
				direction = Vector2.RIGHT
			enemy.pos = clamp_position(player + direction * 145)
		enemy.tell = 0.0
		enemy.rush_left = 0.0
		enemy.attack_wait = maxf(enemy.attack_wait, 2.5)
	phase = "boss" if boss_id >= 0 else "waves"
	paused = true
	return true

func class_ability() -> bool:
	if paused or phase not in ["waves", "boss"] or class_wait > 0:
		return false
	match class_id:
		"scavenger":
			return false # Phase Step empowers Dodge instead of moving automatically.
		"warden":
			if nearest_enemy(player, 120).is_empty() and not hostile_shots.any(func(s: Dictionary): return s.pos.distance_to(player) < 100):
				return false
			shield = max_health() * 0.2
			shield_left = 4.0
		"arcanist":
			if nearest_enemy(player, 145).is_empty():
				return false
			for enemy in enemies:
				if player.distance_to(enemy.pos) <= 145:
					damage_enemy(enemy, 48 * spell_scale(), player, true)
			pulse_flash = 0.35
		"engineer":
			if not defenses.repair_nearest(player, 1.0 + 0.1 * passive_rank("mechanic")):
				return false
		_:
			return false
	ability_notice = Haven.CLASSES[class_id].ability
	class_wait = Haven.CLASSES[class_id].cooldown
	return true

func open_build() -> void:
	if not paused and phase in ["waves", "boss"]:
		phase = "build"
		defenses.notice = "Structures are placed ahead of your facing direction."
		build_revision += 1

func close_build() -> void:
	if phase == "build":
		phase = "boss" if boss_id >= 0 else "waves"

func build_cost(kind: String) -> int:
	if kind not in Defenses.TYPES:
		return -1
	return ceili(Defenses.TYPES[kind].cost * (0.9 if class_id == "engineer" and mastery_level >= 5 else 1.0))

func place_structure(kind: String) -> bool:
	if paused or phase != "build" or kind not in blueprints or field.scrap < build_cost(kind):
		return false
	var position := player + facing * 90.0
	build_revision += 1
	if not defenses.can_place(kind, position, field.sites, player):
		return false
	defenses.place(kind, position, spell_multiplier * 40.0, class_id == "engineer")
	field.scrap -= build_cost(kind)
	field.revision += 1
	return true

func damage_enemy(enemy: Dictionary, amount: float, source: Vector2, elemental: bool = false) -> void:
	if enemy.hp <= 0:
		return
	var mitigation := 1.0
	if mission == 4 and enemy.boss and not elemental:
		var forward: Vector2 = enemy.get("forward", Vector2.RIGHT)
		if (source - enemy.pos).normalized().dot(forward) > 0.3:
			mitigation = 0.5
	enemy.hp -= amount * mitigation

func max_health() -> float:
	return base_health * (field.health_multiplier() + 0.08 * passive_rank("vital"))

func passive_rank(id: String) -> int:
	return int(passives.get(id, 0))

func spell_scale() -> float:
	return spell_multiplier * (1.0 + 0.06 * passive_rank("focus")) * (1.08 if "cinder" in field.relics else 1.0)

func spell_cooldown(id: String) -> float:
	return Content.SPELLS[id].cooldown * (1.0 - minf(0.3, permanent_cooldown + 0.06 * passive_rank("channel")))

func spell_mod(id: String, key: String, fallback: float = 1.0) -> float:
	var branch: String = spells.get(id, {}).get("branch", "")
	return float(Content.BRANCHES.get(id, {}).get(branch, {}).get(key, fallback))

func spell_name(id: String) -> String:
	if spells.get(id, {}).get("evolved", false):
		return Content.EVOLUTIONS[id].name
	var branch: String = spells.get(id, {}).get("branch", "")
	return Content.BRANCHES[id][branch].name if not branch.is_empty() else Content.SPELLS[id].name

func return_to_offers() -> void:
	if paused or phase != "upgrade" or offer_back.is_empty():
		return
	offers = offer_back.duplicate(true)
	offer_back.clear()

func buy_trait(id: String) -> bool:
	if paused or phase != "shrine":
		return false
	var previous := max_health()
	if not field.buy_trait(id):
		return false
	health = minf(max_health(), health + max_health() - previous)
	return true

func choose_relic(index: int) -> bool:
	if paused or phase != "shrine":
		return false
	var previous := max_health()
	if field.choose_relic(index).is_empty():
		return false
	health = minf(max_health(), health + max_health() - previous)
	phase = "boss" if boss_id >= 0 else "waves"
	return true

func leave_shrine() -> void:
	if phase == "shrine":
		field.leave()
		phase = "boss" if boss_id >= 0 else "waves"

func open_pack() -> void:
	if not paused and phase in ["waves", "boss"]:
		phase = "pack"

func close_pack() -> void:
	if phase == "pack":
		phase = "boss" if boss_id >= 0 else "waves"

func start_boss_practice() -> void:
	practice = true
	phase = "boss"
	spawn_enemy(true)
	for id: String in ["ember", "frost", "chain"]:
		spells[id] = {"rank": 1, "wait": 1.0}

func spawn_enemy(boss: bool = false, kind: String = "drifter") -> void:
	if enemies.size() >= MAX_ENEMIES:
		return
	var angle := rng.randf_range(0.0, TAU)
	var pos := clamp_position(player + Vector2.from_angle(angle) * 330.0)
	if pos.distance_to(player) < 180.0:
		pos = clamp_position(Vector2(1200, 1200) - player)
	if boss:
		kind = "breaker"
	var stats: Dictionary = Content.ENEMIES[kind]
	var hp: float = stats.hp
	if boss and mission > 0:
		hp = Haven.MISSIONS[mission - 1].health
	enemies.append({"id": next_id, "pos": pos, "hp": hp, "max_hp": hp,
		"speed": stats.speed, "boss": boss, "kind": kind, "contact": stats.contact,
		"tell": 0.0, "attack_wait": 2.0, "target": pos, "face": 1.0,
		"forward": Vector2.LEFT, "windup": 0.95,
		"attack": "", "cycle": 0, "rush_left": 0.0, "rush_direction": Vector2.ZERO,
		"recover": 0.0, "chill": 0.0, "burn": 0.0, "burn_dps": 0.0})
	if boss:
		boss_id = next_id
	next_id += 1

func clamp_position(pos: Vector2) -> Vector2:
	return pos.clamp(BOUNDS.position, BOUNDS.end)

func set_benchmark(count: int) -> void:
	benchmark_count = clampi(count, 0, MAX_ENEMIES)
	enemies.clear()
	shots.clear()
	hostile_shots.clear()
	effects.clear()
	spells.clear()
	offers.clear()
	pickups.clear()
	phase = "waves"
	elapsed = 0.0
	health = 120.0
	for i in benchmark_count:
		spawn_enemy()

func dodge() -> bool:
	if paused or phase not in ["waves", "boss"] or dodge_wait > 0.0:
		return false
	dodge_wait = 3.0 * (0.85 if "feather" in field.relics else 1.0)
	dodge_left = 0.18
	if class_id == "scavenger" and class_wait <= 0:
		dodge_left = 0.30
		class_wait = Haven.CLASSES.scavenger.cooldown
		ability_notice = "Phase Step"
	return true

func upgrade(choice: int) -> void:
	if phase != "upgrade" or choice not in [0, 1, 2]:
		return
	apply_passive(["rounds", "quick", "heal"][choice])
	phase = "boss" if boss_id >= 0 else "waves"
	offers.clear()

func apply_passive(id: String) -> bool:
	if id == "heal":
		health = minf(max_health(), health + 35)
		return true
	if id not in Content.PASSIVES or passive_rank(id) >= Content.PASSIVES[id].max_rank or (not passives.has(id) and passives.size() >= 3):
		return false
	var previous := max_health()
	passives[id] = passive_rank(id) + 1
	if id == "rounds":
		damage = minf(maxf(48.0, damage), damage + 4.0)
	elif id == "quick":
		fire_interval = maxf(0.18, fire_interval - 0.025)
	health = minf(max_health(), health + max_health() - previous)
	refresh_evolutions()
	return true

func refresh_evolutions() -> void:
	for id: String in spells:
		if spells[id].rank == 3 and Content.EVOLUTIONS.has(id) and passive_rank(Content.EVOLUTIONS[id].pair) > 0:
			spells[id].evolved = true

func make_offers() -> void:
	offers.clear()
	if level == 2:
		for id in ["ember", "frost", "chain"]:
			offers.append(spell_offer(id))
		return
	var pool: Array[Dictionary] = []
	var learned: Array[Dictionary] = []
	for id: String in Content.SPELLS:
		if spells.has(id) and spells[id].rank < 3:
			learned.append(spell_offer(id))
		elif not spells.has(id) and spells.size() < 3:
			pool.append(spell_offer(id))
	# At least one current spell upgrade when possible; the other slots vary.
	if not learned.is_empty():
		var index := offer_rng.randi_range(0, learned.size() - 1)
		offers.append(learned[index])
		learned.remove_at(index)
	pool.append_array(learned)
	for id: String in Content.PASSIVES:
		if passive_rank(id) >= Content.PASSIVES[id].max_rank or (not passives.has(id) and passives.size() >= 3):
			continue
		if (id == "rounds" and damage >= 48) or (id == "quick" and fire_interval <= 0.18):
			continue
		pool.append({"id": id, "name": "%s • Rank %d/%d" % [Content.PASSIVES[id].name, passive_rank(id) + 1, Content.PASSIVES[id].max_rank], "description": Content.PASSIVES[id].description})
	if health < max_health():
		pool.append({"id": "heal", "name": "Field Dressing", "description": "Recover 35 HP now, up to %.0f. Does not use a passive slot." % max_health()})
	while offers.size() < 3 and not pool.is_empty():
		var index := offer_rng.randi_range(0, pool.size() - 1)
		offers.append(pool[index])
		pool.remove_at(index)

func spell_offer(id: String, current_rank: int = 0) -> Dictionary:
	var rank := current_rank if current_rank > 0 else (int(spells[id].rank) + 1 if spells.has(id) else 1)
	var info: Dictionary = Content.SPELLS[id]
	var scale := (1.0 + 0.25 * (rank - 1)) * spell_scale() * spell_mod(id, "damage")
	var detail := ""
	match id:
		"ember": detail = "%d bolt(s), each %.0f impact + %.0f burn over 2s." % [int(spell_mod(id, "count", 1)), 36 * scale, 12 * scale * spell_mod(id, "burn") / spell_mod(id, "damage")]
		"frost": detail = "%.0f damage within %.0f radius. Chill for 3s; bosses resist." % [26 * scale, spell_mod(id, "radius", 150)]
		"chain": detail = "%d chained targets; %.0f first hit, then %.0f / %.0f damage; extra jumps %.0f." % [int(spell_mod(id, "count", 3)) + (1 if spells.get(id, {}).get("evolved", false) else 0), 28 * scale * spell_mod(id, "first_damage"), 18 * scale, 12 * scale, 6 * scale]
		"wisp": detail = "%d wisp(s), %.0f contact damage. Shared per-enemy limit: once every 1.1s." % [int(spell_mod(id, "count", 1)), 10 * scale]
		"lance": detail = "%.0f damage through up to %d targets in a line." % [56 * scale, int(spell_mod(id, "hits", 3)) + (2 if spells.get(id, {}).get("evolved", false) else 0)]
		"ground": detail = "%.0f damage per second for 4s. Fixed circle, %.0f radius." % [8 * scale, spell_mod(id, "radius", 90)]
		"blades": detail = "%d blades each deal %.0f damage." % [int(spell_mod(id, "count", 2)) + (1 if spells.get(id, {}).get("evolved", false) else 0), 22 * scale]
		"gravity": detail = "%.0f damage within %.0f radius, plus pull. Bosses resist displacement." % [16 * scale, spell_mod(id, "radius", 130)]
	if rank == 3 and Content.EVOLUTIONS.has(id) and passive_rank(Content.EVOLUTIONS[id].pair) > 0:
		return {"id": id, "name": Content.EVOLUTIONS[id].name + (" • Evolved" if current_rank > 0 else " • Evolve"), "description": detail + "\n" + Content.EVOLUTIONS[id].description}
	if rank == 2 and current_rank == 0:
		return {"id": id, "name": info.name + " • Specialize", "description": "Choose one path: %s or %s. Preview both before committing." % [Content.BRANCHES[id].focus.name, Content.BRANCHES[id].spread.name]}
	return {"id": id, "name": "%s  •  Rank %d/3" % [spell_name(id), rank],
		"description": "%s\n%s • %s" % [detail, "Learn" if rank == 1 else "Upgrade", "continuous orbit" if id == "wisp" else "every %.1fs" % spell_cooldown(id)]}

func choose_offer(index: int) -> void:
	if paused or phase != "upgrade" or index < 0 or index >= offers.size():
		return
	var id: String = offers[index].id
	if spells.has(id) and spells[id].rank == 1 and not offers[index].has("branch"):
		offer_back = offers.duplicate(true)
		offers.clear()
		for branch: String in Content.BRANCHES[id]:
			var info: Dictionary = Content.BRANCHES[id][branch]
			offers.append({"id": id, "branch": branch, "name": info.name + " • Rank 2/3", "description": info.description + "\nIncludes the rank-2 base damage increase."})
		return
	if id == "heal" or Content.PASSIVES.has(id):
		if not apply_passive(id):
			return
	elif Content.SPELLS.has(id):
		if spells.has(id):
			if offers[index].has("branch"):
				spells[id].branch = offers[index].branch
			spells[id].rank = mini(3, spells[id].rank + 1)
			if spells[id].rank == 3 and Content.EVOLUTIONS.has(id) and passive_rank(Content.EVOLUTIONS[id].pair) > 0:
				spells[id].evolved = true
		elif spells.size() < 3:
			spells[id] = {"rank": 1, "wait": 0.25}
		else:
			return
	else:
		return
	refresh_evolutions()
	offer_back.clear()
	phase = "boss" if boss_id >= 0 else "waves"
	offers.clear()

func nearest_enemy(from: Vector2, radius: float, excluded: Array[int] = []) -> Dictionary:
	var found: Dictionary = {}
	var distance := radius * radius
	for enemy in enemies:
		var next_distance := from.distance_squared_to(enemy.pos)
		if enemy.hp > 0 and enemy.id not in excluded and next_distance <= distance:
			found = enemy
			distance = next_distance
	return found

func add_effect(kind: String, from: Vector2, to: Vector2, duration: float = 0.3) -> void:
	if effects.size() < 64:
		effects.append({"kind": kind, "from": from, "to": to, "life": duration, "duration": duration})

func cast_spell(id: String) -> bool:
	if paused or phase not in ["waves", "boss"] or not spells.has(id):
		return false
	var target := nearest_enemy(player, 425.0 if id != "frost" else spell_mod(id, "radius", 150.0))
	if target.is_empty():
		return false
	var multiplier := (1.0 + 0.25 * (int(spells[id].rank) - 1)) * spell_scale() * spell_mod(id, "damage")
	match id:
		"ember":
			var count := int(spell_mod(id, "count"))
			if shots.size() > MAX_SHOTS - count:
				return false
			for index in count:
				var angle := (index - (count - 1) / 2.0) * 0.14
				shots.append({"pos": player, "velocity": player.direction_to(target.pos).rotated(angle) * 500.0,
					"life": 0.85, "kind": "ember", "damage": 36.0 * multiplier,
					"burn_dps": 6.0 * multiplier * spell_mod(id, "burn") / spell_mod(id, "damage"),
					"pierce": int(spell_mod(id, "pierce", 0)), "hits": [],
					"splash": 8.0 * spell_scale() if spells[id].get("evolved", false) else 0.0})
		"frost":
			for enemy in enemies:
				if enemy.hp > 0 and player.distance_to(enemy.pos) <= spell_mod(id, "radius", 150.0):
					damage_enemy(enemy, 26.0 * multiplier, player, true)
					enemy.chill = maxf(enemy.chill, 1.5 if enemy.boss else 3.0)
			add_effect("frost", player, player + Vector2(spell_mod(id, "radius", 150.0), 0), 0.45)
			if spells[id].get("evolved", false):
				shield = maxf(shield, max_health() * 0.08)
				shield_left = maxf(shield_left, 3.0)
		"chain":
			var hit: Array[int] = []
			var from := player
			var amounts: Array[float] = [28.0 * spell_mod(id, "first_damage"), 18.0, 12.0]
			if int(spell_mod(id, "count", 3)) > 3:
				amounts.append(6.0)
			if spells[id].get("evolved", false):
				amounts.append(6.0)
			for amount in amounts:
				if target.is_empty():
					break
				damage_enemy(target, amount * multiplier, from, true)
				hit.append(target.id)
				add_effect("chain", from, target.pos)
				from = target.pos
				target = nearest_enemy(from, spell_mod(id, "range", 180.0), hit)
		_:
			return Magic.cast(self, id, multiplier, target)
	return true

func hostile_projectile(from: Vector2, direction: Vector2, amount: float, speed: float = 170.0) -> void:
	if hostile_shots.size() < 32:
		hostile_shots.append({"pos": from, "velocity": direction * speed, "damage": amount, "life": 3.0})

func tick_enemy(enemy: Dictionary, delta: float) -> void:
	if enemy.hp <= 0:
		return
	if enemy.burn > 0:
		enemy.hp -= enemy.burn_dps * minf(delta, enemy.burn)
		enemy.burn = maxf(0, enemy.burn - delta)
	if enemy.hp <= 0:
		return
	var pos: Vector2 = enemy.pos
	enemy.face = -1.0 if player.x < pos.x else 1.0
	if enemy.tell <= 0 and enemy.rush_left <= 0 and enemy.recover <= 0:
		enemy.forward = pos.direction_to(player)
	enemy.chill = maxf(0, enemy.chill - delta)
	enemy.attack_wait -= delta
	if enemy.rush_left > 0:
		enemy.rush_left = maxf(0, enemy.rush_left - delta)
		var rush_speed := 410.0 if mission == 2 else (280.0 if mission == 1 else 360.0)
		enemy.pos = clamp_position(pos + enemy.rush_direction * rush_speed * delta)
		if enemy.rush_left == 0:
			enemy.recover = 1.35 if mission == 2 else 1.1
	elif enemy.recover > 0:
		enemy.recover = maxf(0, enemy.recover - delta)
	elif enemy.tell > 0:
		enemy.tell = maxf(0, enemy.tell - delta)
		if enemy.tell == 0:
			match enemy.attack:
				"rush":
					enemy.rush_direction = pos.direction_to(enemy.target)
					enemy.forward = enemy.rush_direction
					enemy.rush_left = 0.65
				"slam":
					add_effect("slam", enemy.target, enemy.target)
					if player.distance_to(enemy.target) < 80.0:
						hurt(30.0)
				"toss":
					for angle in [-0.22, 0.0, 0.22]:
						hostile_projectile(pos, pos.direction_to(enemy.target).rotated(angle), 16.0, 190.0)
				"spit": hostile_projectile(pos, pos.direction_to(enemy.target), 12.0)
				"summon":
					for count in 4:
						if reinforcements_spawned >= 24 or enemies.filter(func(e: Dictionary): return e.hp > 0 and e.get("reinforcement", false)).size() >= 6:
							break
						var previous_count := enemies.size()
						spawn_enemy(false, "drifter")
						if enemies.size() > previous_count:
							reinforcements_spawned += 1
							enemies.back().reinforcement = true
							var summon_pos := clamp_position(pos + Vector2.from_angle(count * PI / 2) * 110)
							if summon_pos.distance_to(player) >= 80:
								enemies.back().pos = summon_pos
					add_effect("summon", pos, pos, 0.6)
			enemy.attack_wait = (1.6 if enemy.hp < enemy.max_hp * 0.5 else 2.4) if enemy.boss else 4.0
			if mission == 5 and enemy.attack == "rush" and enemy.hp < enemy.max_hp * 0.5:
				enemy.attack_wait = 1.8
	else:
		if enemy.attack_wait <= 0 and (enemy.boss or (enemy.kind == "spitter" and pos.distance_to(player) < 360.0)):
			enemy.target = player
			var attacks: Array = Haven.MISSIONS[mission - 1].attacks if mission > 0 else ["rush", "slam", "toss"]
			enemy.attack = attacks[enemy.cycle % attacks.size()] if enemy.boss else "spit"
			if enemy.attack == "slam":
				enemy.target = pos
			enemy.cycle += 1
			enemy.windup = (1.15 if mission == 1 else (0.8 if mission == 2 else 0.95)) if enemy.boss else 0.65
			enemy.tell = enemy.windup
		else:
			var slow := (0.9 if enemy.boss else 0.6) if enemy.chill > 0 else 1.0
			if enemy.kind != "spitter" or pos.distance_to(player) > 210.0:
				enemy.pos = clamp_position(pos.move_toward(player, enemy.speed * slow * delta))
	if player.distance_squared_to(enemy.pos) < pow(30.0 if enemy.boss else 17.0, 2):
		hurt(enemy.contact)

func tick(delta: float, direction: Vector2) -> void:
	if paused or phase not in ["waves", "boss"]:
		return
	elapsed += delta
	if "emberleaf" in field.relics and elapsed - last_damage_at >= 4.0:
		health = minf(max_health(), health + max_health() * 0.0015 * delta)
	wisp_wait = maxf(0, wisp_wait - delta)
	if "lantern" in field.relics and wisp_wait == 0:
		var target := nearest_enemy(player, 220.0)
		if not target.is_empty():
			damage_enemy(target, 12.0, player, true)
			add_effect("chain", player, target.pos)
			wisp_wait = 3.0
	for key in ["fire_wait", "spawn_wait", "hurt_wait", "dodge_wait", "dodge_left", "pulse_wait", "pulse_flash", "class_wait", "shield_left"]:
		set(key, maxf(0.0, float(get(key)) - delta))
	if shield_left == 0:
		shield = 0.0
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	var move := facing if dodge_left > 0.0 else direction.limit_length()
	var speed := 125.0 * minf(1.3, speed_multiplier * (1.0 + 0.05 * passive_rank("fleet"))) * (0.95 if "obsidian" in field.relics else 1.0)
	player = clamp_position(player + move * (520.0 if dodge_left > 0.0 else speed) * delta)
	if benchmark_count == 0 and phase == "waves" and elapsed >= duration:
		if mode == "salvage":
			phase = "defeat"
			return
		phase = "boss"
		# Reserve a slot: the crowd cap must never prevent mandatory boss arrival.
		if enemies.size() == MAX_ENEMIES:
			enemies.pop_back()
		spawn_enemy(true)
	if benchmark_count > 0:
		while enemies.size() < benchmark_count:
			spawn_enemy()
	elif phase == "waves" and spawn_wait <= 0.0:
		var wave := Content.wave_at(elapsed * (1.6 if mode == "salvage" else 1.0))
		var roll := rng.randf()
		spawn_enemy(false, "runner" if roll < wave.runner else ("spitter" if roll < wave.runner + wave.spitter else "drifter"))
		spawn_wait = wave.interval / (1.1 if mode == "salvage" else (Haven.MISSIONS[mission - 1].pressure if mission > 0 else 1.0))
	for effect in effects:
		effect.life -= delta
	effects = effects.filter(func(effect: Dictionary) -> bool: return effect.life > 0)
	class_ability()
	for id: String in spells:
		if id == "wisp":
			continue
		spells[id].wait = maxf(0, spells[id].wait - delta)
		if spells[id].wait == 0 and cast_spell(id):
			spells[id].wait = spell_cooldown(id)
	Magic.tick(self, delta)
	if fire_wait <= 0.0 and not enemies.is_empty() and shots.size() < MAX_SHOTS:
		var nearest: Dictionary = enemies[0]
		for enemy in enemies:
			if player.distance_squared_to(enemy.pos) < player.distance_squared_to(nearest.pos):
				nearest = enemy
		shots.append({"pos": player, "velocity": player.direction_to(nearest.pos) * 500.0, "life": 0.85, "pierce": passive_rank("pierce"), "hits": []})
		fire_wait = fire_interval
	for enemy in enemies:
		tick_enemy(enemy, delta)
	defenses.tick(delta, self)
	for shot in hostile_shots:
		shot.life -= delta
		shot.pos += shot.velocity * delta
		if shot.pos.distance_to(player) < 15.0:
			hurt(shot.damage)
			shot.life = 0.0
	hostile_shots = hostile_shots.filter(func(shot: Dictionary) -> bool: return shot.life > 0)
	for shot in shots:
		shot.life -= delta
		shot.pos += shot.velocity * delta
		for enemy in enemies:
			if enemy.hp > 0.0 and enemy.id not in shot.get("hits", []) and shot.pos.distance_squared_to(enemy.pos) < pow(32.0 if enemy.boss else 17.0, 2):
				damage_enemy(enemy, shot.get("damage", damage * field.damage_multiplier()), shot.pos - shot.velocity.normalized() * 40, shot.get("kind", "pistol") != "pistol")
				if shot.get("kind", "pistol") == "ember":
					enemy.burn = maxf(enemy.burn, 2.0)
					enemy.burn_dps = maxf(enemy.burn_dps, shot.burn_dps)
					add_effect("ember", enemy.pos, enemy.pos)
					if shot.get("splash", 0.0) > 0:
						for nearby in enemies:
							if nearby.id != enemy.id and nearby.pos.distance_to(enemy.pos) <= 65:
								damage_enemy(nearby, shot.splash, enemy.pos, true)
				if shot.get("pierce", 0) > 0:
					shot.pierce -= 1
					shot.hits.append(enemy.id)
				else:
					shot.life = 0.0
				break
	shots = shots.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		if enemy.hp > 0.0:
			continue
		kills += 1
		if not practice and benchmark_count == 0:
			survivor_xp += 1
			mastery_xp += 1 if kills % 3 == 0 else 0
			field.add_drop(enemy.pos, 3 if enemy.boss else 1, 12 if enemy.boss else (2 if kills % 3 == 0 else 0))
		if pickups.size() < 40:
			pickups.append(enemy.pos)
		if enemy.boss and health > 0.0:
			phase = "victory"
		enemies.remove_at(i)
	if health <= 0.0:
		phase = "defeat"
	elif phase == "victory":
		field.collect_drops(player, 160.0)
	if phase not in ["waves", "boss"]:
		return
	for i in range(pickups.size() - 1, -1, -1):
		if pickups[i].distance_to(player) < 70.0 * field.pickup_multiplier() * pickup_multiplier * (1.0 + 0.2 * passive_rank("magnet") + (0.2 if spells.get("wisp", {}).get("evolved", false) else 0.0)):
			pickups[i] = pickups[i].move_toward(player, 220.0 * delta)
		if pickups[i].distance_to(player) < 14.0:
			xp += 1
			pickups.remove_at(i)
	if benchmark_count == 0 and xp >= level * 5 and level < 12:
		xp -= level * 5
		level += 1
		phase = "upgrade"
		make_offers()
	if phase in ["waves", "boss"] and not practice and benchmark_count == 0:
		if field.tick(delta, player):
			phase = "shrine"
		if mode == "salvage":
			Salvage.tick(self, delta)

func hurt(amount: float) -> void:
	if benchmark_count > 0 or hurt_wait > 0.0 or dodge_left > 0.0:
		return
	if amount <= 0:
		return
	var reduced := amount * maxf(0.35, (1.0 - minf(0.5, armor / (armor + 150.0))) * (0.9 if "obsidian" in field.relics else 1.0) * (1.0 - defenses.mitigation(player)))
	var absorbed := minf(shield, reduced)
	shield -= absorbed
	health = maxf(0.0, health - (reduced - absorbed))
	if reduced > absorbed:
		damage_taken += 1
		last_damage_at = elapsed
	hurt_wait = 0.8
	if health > 0 and health <= max_health() * 0.25 and medkit_fraction > 0 and not medkit_used:
		medkit_used = true
		health = minf(max_health(), health + max_health() * medkit_fraction)
		ability_notice = "Field Medkit restored health."
