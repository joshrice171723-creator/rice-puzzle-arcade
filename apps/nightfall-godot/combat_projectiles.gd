extends RefCounted
## Swept collision prevents fast projectiles tunneling through targets between ticks.

static func hit_time(from: Vector2, to: Vector2, center: Vector2, radius: float) -> float:
	var offset := from - center
	if offset.length_squared() <= radius * radius:
		return 0.0
	var path := to - from
	var a := path.length_squared()
	if a < 0.000001:
		return INF
	var b := offset.dot(path)
	var c := offset.length_squared() - radius * radius
	var discriminant := b * b - a * c
	if discriminant < 0:
		return INF
	var t := (-b - sqrt(discriminant)) / a
	return t if t >= 0 and t <= 1 else INF

static func hit(run: RefCounted, shot: Dictionary, enemy: Dictionary) -> void:
	var basic: bool = shot.get("basic", shot.get("kind", "pistol") == "pistol")
	var amount: float = run.talents.basic_damage(run, shot, shot.get("damage", run.damage * run.field.damage_multiplier()))
	var critical: bool = basic and run.training_bonuses.crit > 0 and run.rng.randf() < run.training_bonuses.crit
	if critical:
		amount *= 1.5
	var elemental: bool = shot.get("elemental", not basic)
	if basic and elemental and run.class_id == "arcanist":
		amount *= 1.08
	run.damage_enemy(enemy, amount, shot.pos - shot.velocity.normalized() * 40, elemental, critical)
	if basic:
		run.add_vfx("wand_hit" if elemental else "bullet_hit", enemy.pos, shot.velocity.normalized(), 0.26)
	elif shot.get("kind", "") == "blade":
		run.add_vfx("blade_hit", enemy.pos, shot.velocity.normalized(), 0.24)
	if shot.get("kind", "") == "ember":
		enemy.burn = maxf(enemy.burn, 2.0)
		enemy.burn_dps = maxf(enemy.burn_dps, shot.burn_dps)
		run.add_effect("ember", enemy.pos, enemy.pos)
		if shot.get("splash", 0.0) > 0:
			for nearby: Dictionary in run.enemies:
				if nearby.id != enemy.id and nearby.pos.distance_to(enemy.pos) <= 65:
					run.damage_enemy(nearby, shot.splash, enemy.pos, true)

static func friendly(run: RefCounted, delta: float) -> void:
	for shot: Dictionary in run.shots:
		if shot.life <= 0:
			continue
		var active_time := minf(delta, shot.life)
		var start: Vector2 = shot.pos
		shot.life = maxf(0.0, shot.life - delta)
		if shot.get("kind", "") == "sabre":
			shot.delay -= active_time
			if shot.delay <= 0 and not shot.get("struck", false):
				shot.struck = true
				var candidates: Array[Dictionary] = []
				for enemy: Dictionary in run.enemies:
					var offset: Vector2 = enemy.pos - start
					if enemy.hp > 0 and offset.length() <= shot.radius + (12 if enemy.boss else 0) and (offset.length() < 12 or offset.normalized().dot(shot.direction) >= 0.42):
						candidates.append(enemy)
				candidates.sort_custom(func(a: Dictionary, b: Dictionary): return a.pos.distance_squared_to(start) < b.pos.distance_squared_to(start))
				for index in mini(3 + run.passive_rank("pierce"), candidates.size()):
					hit(run, shot, candidates[index])
			continue
		var finish: Vector2 = start + shot.velocity * active_time
		var collisions: Array[Dictionary] = []
		for enemy: Dictionary in run.enemies:
			if enemy.hp <= 0 or enemy.id in shot.get("hits", []):
				continue
			var t := hit_time(start, finish, enemy.pos, 32.0 if enemy.boss else 17.0)
			if t != INF:
				collisions.append({"enemy":enemy, "time":t})
		collisions.sort_custom(func(a: Dictionary, b: Dictionary): return a.time < b.time)
		var stopped := false
		for collision: Dictionary in collisions:
			if collision.enemy.hp <= 0:
				continue
			shot.pos = start.lerp(finish, collision.time)
			hit(run, shot, collision.enemy)
			if not shot.has("hits"):
				shot.hits = []
			shot.hits.append(collision.enemy.id)
			if shot.get("pierce", 0) <= 0:
				shot.life = 0.0
				stopped = true
				break
			shot.pierce -= 1
		if not stopped:
			shot.pos = finish
	run.shots = run.shots.filter(func(shot: Dictionary): return shot.life > 0)

static func hostile(run: RefCounted, delta: float) -> void:
	for shot: Dictionary in run.hostile_shots:
		if shot.life <= 0:
			continue
		var start: Vector2 = shot.pos
		var finish: Vector2 = start + shot.velocity * minf(delta, shot.life)
		shot.life = maxf(0, shot.life - delta)
		var t := hit_time(start, finish, run.player, 15.0)
		var cover := {}
		for structure: Dictionary in run.defenses.structures:
			if structure.hp <= 0 or structure.kind == "trap":
				continue
			var cover_t := hit_time(start,finish,structure.pos,run.Defenses.TYPES[structure.kind].radius)
			if cover_t < t:
				t = cover_t
				cover = structure
		shot.pos = finish if t == INF else start.lerp(finish, t)
		if not cover.is_empty():
			cover.hp = maxf(0,cover.hp-shot.damage)
			run.add_vfx("structure_hit",shot.pos,shot.velocity.normalized(),0.30)
			shot.life = 0.0
			continue
		if t != INF:
			var hits_before: int = run.damage_taken
			run.hurt(shot.damage)
			if run.damage_taken > hits_before:
				run.talents.slow_left = maxf(run.talents.slow_left, shot.get("slow", 0.0))
			run.add_vfx("hostile_hit", shot.pos, shot.velocity.normalized(), 0.32)
			shot.life = 0.0
	run.hostile_shots = run.hostile_shots.filter(func(shot: Dictionary): return shot.life > 0)
