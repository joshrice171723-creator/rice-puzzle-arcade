extends RefCounted
## Fixed-step combat and attempt-local exploration rules.

const DURATION := 240.0
const Content = preload("res://combat_content.gd")
const Field = preload("res://field.gd")
const Haven = preload("res://haven_content.gd")
const Defenses = preload("res://defenses.gd")
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

const SNAPSHOT_KEYS := ["player", "facing", "health", "elapsed", "phase", "kills", "shots", "hostile_shots", "effects", "spells", "offers", "enemies", "pickups", "xp", "level", "damage", "fire_interval", "fire_wait", "spawn_wait", "hurt_wait", "dodge_wait", "dodge_left", "pulse_wait", "pulse_flash", "boss_id", "next_id", "base_health", "damage_taken", "last_damage_at", "wisp_wait", "survivor_xp", "mastery_xp", "mission", "duration", "boss_name", "armor", "speed_multiplier", "pickup_multiplier", "spell_multiplier", "medkit_fraction", "medkit_used", "class_id", "class_wait", "shield", "shield_left"]
const FIELD_KEYS := ["sites", "scrap", "credits", "bag", "capacity", "secure_capacity", "traits", "relics", "active_site", "caches_opened", "notice", "revision", "drops", "next_loot_id"]

func _init(seed_value: int = 41) -> void:
	rng.seed = seed_value
	field = Field.new(seed_value)

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

func snapshot() -> Dictionary:
	var values := {}
	for key in SNAPSHOT_KEYS:
		values[key] = get(key)
	var exploration := {}
	for key in FIELD_KEYS:
		exploration[key] = field.get(key)
	return {"version": 1, "combat": values.duplicate(true), "field": exploration.duplicate(true), "rng": rng.state, "field_rng": field.rng.state, "rescued": rescued,
		"defenses": defenses.structures.duplicate(true), "next_structure": defenses.next_id, "blueprints": blueprints.duplicate(), "mastery": mastery_level}

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
	paused = true
	return true

func result() -> Dictionary:
	var won := phase == "victory"
	var loot: Array = field.banked_loot(won)
	return {"victory": won, "credits": field.credits, "survivor_xp": survivor_xp,
		"mastery_xp": mastery_xp, "loot": loot, "damage_taken": damage_taken,
		"caches": field.caches_opened, "lost": field.bag.size() - loot.size(), "rescued": rescued}

func rescue() -> bool:
	if phase != "defeat" or rescued or practice or benchmark_count > 0:
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
			dodge_left = maxf(dodge_left, 0.30)
			ability_notice = "Phase Step"
		"warden":
			shield = max_health() * 0.2
			shield_left = 4.0
		"arcanist":
			for enemy in enemies:
				if player.distance_to(enemy.pos) <= 145:
					enemy.hp -= 48 * spell_multiplier
			pulse_flash = 0.35
		"engineer":
			if not defenses.repair_nearest(player):
				ability_notice = defenses.notice
				return false
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
	return base_health * field.health_multiplier()

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
	for id: String in Content.SPELLS:
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
	return true

func pulse() -> bool:
	if paused or phase not in ["waves", "boss"] or pulse_wait > 0.0:
		return false
	pulse_wait = 8.0
	pulse_flash = 0.35
	for enemy in enemies:
		if player.distance_to(enemy.pos) <= 145.0:
			damage_enemy(enemy, 55.0, player, true)
			if not enemy.boss:
				enemy.pos = clamp_position(enemy.pos + player.direction_to(enemy.pos) * 45.0)
	return true

func upgrade(choice: int) -> void:
	if phase != "upgrade" or choice not in [0, 1, 2]:
		return
	match choice:
		0: damage = minf(48.0, damage + 4.0)
		1: fire_interval = maxf(0.18, fire_interval - 0.025)
		2: health = minf(max_health(), health + 35.0)
	phase = "boss" if boss_id >= 0 else "waves"
	offers.clear()

func make_offers() -> void:
	offers.clear()
	var available: Array[String] = []
	for id: String in Content.SPELLS:
		if not spells.has(id) or spells[id].rank < 3:
			available.append(id)
	if level == 2:
		for id in available:
			offers.append(spell_offer(id))
		return
	if not available.is_empty():
		offers.append(spell_offer(available[(level - 3) % available.size()]))
	if damage < 48.0:
		offers.append({"id": "rounds", "name": "Heavy Rounds", "description": "+4 pistol damage this run (maximum 48)."})
	if health < max_health():
		offers.append({"id": "heal", "name": "Field Dressing", "description": "Recover 35 HP now, up to %.0f." % max_health()})
	if offers.size() < 3 and fire_interval > 0.18:
		offers.append({"id": "quick", "name": "Quick Hands", "description": "Fire 0.025s faster (minimum 0.18s)."})
	for id in available:
		if offers.size() >= 3:
			break
		if not offers.any(func(offer: Dictionary) -> bool: return offer.id == id):
			offers.append(spell_offer(id))
	# Level 12 allows only eleven selections, so upgrades cannot all be exhausted.
	offers = offers.slice(0, 3)

func spell_offer(id: String) -> Dictionary:
	var rank := int(spells[id].rank) + 1 if spells.has(id) else 1
	var info: Dictionary = Content.SPELLS[id]
	var scale := 1.0 + 0.25 * (rank - 1)
	var detail := ""
	match id:
		"ember": detail = "%.0f impact + %.0f burn over 2s. One target." % [36 * scale, 12 * scale]
		"frost": detail = "%.0f nearby damage. Chill foes for 3s; bosses resist." % (26 * scale)
		"chain": detail = "%.0f / %.0f / %.0f damage across 3 nearby foes." % [28 * scale, 18 * scale, 12 * scale]
	return {"id": id, "name": "%s  •  Rank %d/3" % [info.name, rank],
		"description": "%s\n%s • automatic, every %.0fs" % [detail,
			"Learn" if rank == 1 else "Upgrade", info.cooldown]}

func choose_offer(index: int) -> void:
	if paused or phase != "upgrade" or index < 0 or index >= offers.size():
		return
	var id: String = offers[index].id
	match id:
		"rounds": upgrade(0)
		"quick": upgrade(1)
		"heal": upgrade(2)
		_:
			if spells.has(id):
				spells[id].rank = mini(3, spells[id].rank + 1)
			else:
				spells[id] = {"rank": 1, "wait": 0.25}
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
	var target := nearest_enemy(player, 425.0 if id != "frost" else 150.0)
	if target.is_empty():
		return false
	var multiplier := (1.0 + 0.25 * (int(spells[id].rank) - 1)) * (1.08 if "cinder" in field.relics else 1.0) * spell_multiplier
	match id:
		"ember":
			if shots.size() >= MAX_SHOTS:
				return false
			shots.append({"pos": player, "velocity": player.direction_to(target.pos) * 500.0,
				"life": 0.85, "kind": "ember", "damage": 36.0 * multiplier, "burn_dps": 6.0 * multiplier})
		"frost":
			for enemy in enemies:
				if enemy.hp > 0 and player.distance_to(enemy.pos) <= 150.0:
					damage_enemy(enemy, 26.0 * multiplier, player, true)
					enemy.chill = maxf(enemy.chill, 1.5 if enemy.boss else 3.0)
			add_effect("frost", player, player, 0.45)
		"chain":
			var hit: Array[int] = []
			var from := player
			for amount in [28.0, 18.0, 12.0]:
				if target.is_empty():
					break
				damage_enemy(target, amount * multiplier, from, true)
				hit.append(target.id)
				add_effect("chain", from, target.pos)
				from = target.pos
				target = nearest_enemy(from, 180.0, hit)
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
						var previous_count := enemies.size()
						spawn_enemy(false, "drifter")
						if enemies.size() > previous_count:
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
	var speed := 125.0 * speed_multiplier * (0.95 if "obsidian" in field.relics else 1.0)
	player = clamp_position(player + move * (520.0 if dodge_left > 0.0 else speed) * delta)
	if benchmark_count == 0 and phase == "waves" and elapsed >= duration:
		phase = "boss"
		# Reserve a slot: the crowd cap must never prevent mandatory boss arrival.
		if enemies.size() == MAX_ENEMIES:
			enemies.pop_back()
		spawn_enemy(true)
	if benchmark_count > 0:
		while enemies.size() < benchmark_count:
			spawn_enemy()
	elif phase == "waves" and spawn_wait <= 0.0:
		var wave := Content.wave_at(elapsed)
		var roll := rng.randf()
		spawn_enemy(false, "runner" if roll < wave.runner else ("spitter" if roll < wave.runner + wave.spitter else "drifter"))
		spawn_wait = wave.interval / (Haven.MISSIONS[mission - 1].pressure if mission > 0 else 1.0)
	for effect in effects:
		effect.life -= delta
	effects = effects.filter(func(effect: Dictionary) -> bool: return effect.life > 0)
	for id: String in spells:
		spells[id].wait = maxf(0, spells[id].wait - delta)
		if spells[id].wait == 0 and cast_spell(id):
			spells[id].wait = Content.SPELLS[id].cooldown
	if fire_wait <= 0.0 and not enemies.is_empty() and shots.size() < MAX_SHOTS:
		var nearest: Dictionary = enemies[0]
		for enemy in enemies:
			if player.distance_squared_to(enemy.pos) < player.distance_squared_to(nearest.pos):
				nearest = enemy
		shots.append({"pos": player, "velocity": player.direction_to(nearest.pos) * 500.0, "life": 0.85})
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
			if enemy.hp > 0.0 and shot.pos.distance_squared_to(enemy.pos) < pow(32.0 if enemy.boss else 17.0, 2):
				damage_enemy(enemy, shot.get("damage", damage * field.damage_multiplier()), shot.pos - shot.velocity.normalized() * 40, shot.get("kind", "pistol") == "ember")
				if shot.get("kind", "pistol") == "ember":
					enemy.burn = maxf(enemy.burn, 2.0)
					enemy.burn_dps = maxf(enemy.burn_dps, shot.burn_dps)
					add_effect("ember", enemy.pos, enemy.pos)
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
	if phase not in ["waves", "boss"]:
		return
	for i in range(pickups.size() - 1, -1, -1):
		if pickups[i].distance_to(player) < 70.0 * field.pickup_multiplier() * pickup_multiplier:
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

func hurt(amount: float) -> void:
	if benchmark_count > 0 or hurt_wait > 0.0 or dodge_left > 0.0:
		return
	if amount <= 0:
		return
	var reduced := amount * maxf(0.35, (1.0 - minf(0.5, armor / (armor + 150.0))) * (0.9 if "obsidian" in field.relics else 1.0) * (1.0 - defenses.mitigation(player)))
	var absorbed := minf(shield, reduced)
	shield -= absorbed
	health = maxf(0.0, health - (reduced - absorbed))
	damage_taken += 1
	last_damage_at = elapsed
	hurt_wait = 0.8
	if health > 0 and health <= max_health() * 0.25 and medkit_fraction > 0 and not medkit_used:
		medkit_used = true
		health = minf(max_health(), health + max_health() * medkit_fraction)
		ability_notice = "Field Medkit restored health."
