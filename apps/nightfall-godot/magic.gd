extends RefCounted
## Automatic area/orbit attacks. Fixed budgets; no input handlers or independent timers.

static func wisp_position(run: RefCounted, index: int = 0) -> Vector2:
	var radius: float = run.spell_mod("wisp", "radius", 75.0) + (15 if run.spells.get("wisp", {}).get("evolved", false) else 0)
	return run.player + Vector2.from_angle(run.elapsed * 2.0 + index * PI) * radius

static func cast(run: RefCounted, id: String, scale: float, target: Dictionary) -> bool:
	match id:
		"lance":
			var direction: Vector2 = run.player.direction_to(target.pos)
			var candidates: Array[Dictionary] = []
			for enemy in run.enemies:
				var offset: Vector2 = enemy.pos - run.player
				if enemy.hp > 0 and offset.dot(direction) >= 0 and offset.dot(direction) <= 425 and absf(offset.cross(direction)) <= run.spell_mod(id, "width", 20.0) + (12 if enemy.boss else 0):
					candidates.append(enemy)
			candidates.sort_custom(func(a: Dictionary, b: Dictionary): return run.player.distance_squared_to(a.pos) < run.player.distance_squared_to(b.pos))
			var limit: int = int(run.spell_mod(id, "hits", 3)) + (2 if run.spells[id].get("evolved", false) else 0)
			for index in mini(limit, candidates.size()):
				run.damage_enemy(candidates[index], 56 * scale, run.player, true)
			run.add_effect("lance", run.player, run.player + direction * 425, 0.25)
		"ground":
			if run.zones.size() >= 3:
				return false
			run.zones.append({"pos": run.player, "life": 4.0, "dps": 8 * scale, "radius": run.spell_mod(id, "radius", 90.0), "healing": run.spells[id].get("evolved", false)})
		"blades":
			var count: int = int(run.spell_mod(id, "count", 2)) + (1 if run.spells[id].get("evolved", false) else 0)
			if run.shots.size() > run.MAX_SHOTS - count:
				return false
			var direction: Vector2 = run.player.direction_to(target.pos)
			var speed: float = run.spell_mod(id, "speed", 500.0)
			for index in count:
				var side := index - (count - 1) / 2.0
				var angle := side * 0.18 if run.spells[id].get("branch", "") == "spread" else 0.0
				run.shots.append({"pos": run.player + direction.orthogonal() * 14 * side, "velocity": direction.rotated(angle) * speed, "life": 425.0 / speed, "kind": "blade", "damage": 22 * scale})
		"gravity":
			var center: Vector2 = target.pos
			var radius: float = run.spell_mod(id, "radius", 130.0)
			for enemy in run.enemies:
				if enemy.hp > 0 and enemy.pos.distance_to(center) <= radius:
					run.damage_enemy(enemy, 16 * scale, center, true)
					enemy.pos = run.clamp_position(enemy.pos.move_toward(center, 8 if enemy.boss else run.spell_mod(id, "pull", 80.0)))
			run.add_effect("gravity", center, center + Vector2(radius, 0), 0.5)
			if run.spells[id].get("evolved", false) and run.zones.size() < 3:
				run.zones.append({"kind": "collapse", "pos": center, "life": 0.6, "dps": 0.0, "damage": 8 * run.spell_scale(), "radius": radius})
		_:
			return false
	return true

static func tick(run: RefCounted, delta: float) -> void:
	var healing_time := 0.0
	for zone in run.zones:
		var active_time := minf(delta, zone.life)
		var collapse: bool = zone.get("kind", "ground") == "collapse"
		for enemy in run.enemies:
			if enemy.hp > 0 and enemy.pos.distance_to(zone.pos) <= zone.radius:
				if not collapse:
					run.damage_enemy(enemy, zone.dps * active_time, zone.pos, true)
				elif zone.life <= delta:
					run.damage_enemy(enemy, zone.damage, zone.pos, true)
		if collapse and zone.life <= delta:
			run.add_effect("gravity", zone.pos, zone.pos + Vector2(zone.radius, 0), 0.35)
		if zone.get("healing", false) and run.player.distance_to(zone.pos) <= zone.radius:
			healing_time = maxf(healing_time, active_time)
		zone.life = maxf(0, zone.life - delta)
	if run.health > 0:
		run.health = minf(run.max_health(), run.health + run.max_health() * 0.005 * healing_time)
	run.zones = run.zones.filter(func(zone: Dictionary): return zone.life > 0)
	if not run.spells.has("wisp"):
		return
	var scale: float = (1.0 + 0.25 * (run.spells.wisp.rank - 1)) * run.spell_scale() * run.spell_mod("wisp", "damage")
	var alive: Array[int] = []
	for enemy in run.enemies:
		if enemy.hp <= 0:
			continue
		alive.append(enemy.id)
		for index in int(run.spell_mod("wisp", "count", 1)):
			var position := wisp_position(run, index)
			if enemy.pos.distance_to(position) <= (35 if enemy.boss else 22) and run.elapsed >= run.wisp_hits.get(enemy.id, 0.0):
				run.damage_enemy(enemy, 10 * scale, position, true)
				run.wisp_hits[enemy.id] = run.elapsed + 1.1
	for id in run.wisp_hits.keys():
		if id not in alive:
			run.wisp_hits.erase(id)
