extends RefCounted
## Automatic area/orbit attacks. Fixed budgets; no input handlers or independent timers.

static func wisp_position(run: RefCounted) -> Vector2:
	return run.player + Vector2.from_angle(run.elapsed * 2.0) * (90.0 if run.spells.get("wisp", {}).get("evolved", false) else 75.0)

static func cast(run: RefCounted, id: String, scale: float, target: Dictionary) -> bool:
	match id:
		"lance":
			var direction: Vector2 = run.player.direction_to(target.pos)
			var candidates: Array[Dictionary] = []
			for enemy in run.enemies:
				var offset: Vector2 = enemy.pos - run.player
				if enemy.hp > 0 and offset.dot(direction) >= 0 and offset.dot(direction) <= 425 and absf(offset.cross(direction)) <= (32 if enemy.boss else 20):
					candidates.append(enemy)
			candidates.sort_custom(func(a: Dictionary, b: Dictionary): return run.player.distance_squared_to(a.pos) < run.player.distance_squared_to(b.pos))
			var limit := 5 if run.spells[id].get("evolved", false) else 3
			for index in mini(limit, candidates.size()):
				run.damage_enemy(candidates[index], 56 * scale, run.player, true)
			run.add_effect("lance", run.player, run.player + direction * 425, 0.25)
		"ground":
			if run.zones.size() >= 3:
				return false
			run.zones.append({"pos": run.player, "life": 4.0, "dps": 8 * scale, "radius": 90.0})
		"blades":
			if run.shots.size() > run.MAX_SHOTS - 2:
				return false
			var direction: Vector2 = run.player.direction_to(target.pos)
			for side in [-1, 1]:
				run.shots.append({"pos": run.player + direction.orthogonal() * 10 * side, "velocity": direction * 500, "life": 0.85, "kind": "blade", "damage": 22 * scale})
		"gravity":
			var center: Vector2 = target.pos
			for enemy in run.enemies:
				if enemy.hp > 0 and enemy.pos.distance_to(center) <= 130:
					run.damage_enemy(enemy, 16 * scale, center, true)
					enemy.pos = run.clamp_position(enemy.pos.move_toward(center, 8 if enemy.boss else 80))
			run.add_effect("gravity", center, center, 0.5)
		_:
			return false
	return true

static func tick(run: RefCounted, delta: float) -> void:
	for zone in run.zones:
		var active_time := minf(delta, zone.life)
		for enemy in run.enemies:
			if enemy.hp > 0 and enemy.pos.distance_to(zone.pos) <= zone.radius:
				run.damage_enemy(enemy, zone.dps * active_time, zone.pos, true)
		zone.life = maxf(0, zone.life - delta)
	run.zones = run.zones.filter(func(zone: Dictionary): return zone.life > 0)
	if not run.spells.has("wisp"):
		return
	var position := wisp_position(run)
	var scale: float = (1.0 + 0.25 * (run.spells.wisp.rank - 1)) * run.spell_scale()
	var alive: Array[int] = []
	for enemy in run.enemies:
		if enemy.hp <= 0:
			continue
		alive.append(enemy.id)
		if enemy.pos.distance_to(position) <= (35 if enemy.boss else 22) and run.elapsed >= run.wisp_hits.get(enemy.id, 0.0):
			run.damage_enemy(enemy, 10 * scale, position, true)
			run.wisp_hits[enemy.id] = run.elapsed + 1.1
	for id in run.wisp_hits.keys():
		if id not in alive:
			run.wisp_hits.erase(id)
