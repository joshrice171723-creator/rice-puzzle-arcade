extends RefCounted
## Attack commitment, hit and recovery are simulation states shared by AI and animation.
const Projectiles = preload("res://combat_projectiles.gd")

static func rush_speed(run: RefCounted, enemy: Dictionary) -> float:
	if not enemy.boss:
		return 220.0
	return 410.0 if run.mission == 2 else (280.0 if run.mission == 1 else 360.0)

static func rush_duration(enemy: Dictionary) -> float:
	return 0.65 if enemy.boss else 0.18

static func tick(run: RefCounted, enemy: Dictionary, delta: float) -> void:
	if enemy.hp <= 0:
		return
	if enemy.burn > 0:
		run.damage_enemy(enemy, enemy.burn_dps * minf(delta, enemy.burn), enemy.pos, true)
		enemy.burn = maxf(0, enemy.burn - delta)
	if enemy.hp <= 0:
		return
	enemy.hit_visual_wait = maxf(0.0,enemy.get("hit_visual_wait",0.0)-delta)
	enemy.hit_flash = maxf(0.0, enemy.get("hit_flash", 0.0) - delta)
	enemy.attack_anim = maxf(0.0, enemy.get("attack_anim", 0.0) - delta)
	var pos: Vector2 = enemy.pos
	enemy.chill = maxf(0, enemy.chill - delta)
	enemy.attack_wait = maxf(0, enemy.attack_wait - delta)
	if enemy.rush_left > 0:
		var step: float = minf(delta, enemy.rush_left)
		enemy.pos = run.move_body(pos,pos + enemy.rush_direction * rush_speed(run, enemy) * step,24 if enemy.boss else 13)
		enemy.rush_left = maxf(0, enemy.rush_left - delta)
		if not enemy.get("rush_hit", false) and Projectiles.hit_time(pos, enemy.pos, run.player, 30 if enemy.boss else 21) != INF:
			run.hurt(enemy.contact)
			enemy.rush_hit = true
		if enemy.rush_left == 0:
			enemy.recover = (1.35 if run.mission == 2 else 1.1) if enemy.boss else 0.55
	elif enemy.recover > 0:
		enemy.recover = maxf(0, enemy.recover - delta)
	elif enemy.tell > 0:
		enemy.tell = maxf(0, enemy.tell - delta)
		if enemy.tell == 0:
			strike(run, enemy)
	else:
		var blocker: Dictionary = run.defenses.nearest_structure(pos, 80 if enemy.boss else 58)
		if not blocker.is_empty() and (blocker.kind == "trap" or pos.direction_to(blocker.pos).dot(pos.direction_to(run.player)) < -0.2):
			blocker = {}
		var goal: Vector2 = run.player if blocker.is_empty() else blocker.pos
		var distance := pos.distance_to(goal)
		var attack := next_attack(run, enemy) if blocker.is_empty() else "swipe"
		var reach := 300.0 if enemy.kind == "hexer" else (275.0 if enemy.kind == "spitter" else (72.0 if enemy.kind == "bulwark" else (58.0 if enemy.kind == "runner" else 38.0)))
		if enemy.boss:
			reach = 110.0 if attack == "slam" else 420.0
		if not blocker.is_empty():
			reach = run.Defenses.TYPES[blocker.kind].radius + (42 if enemy.boss else 29)
		if enemy.attack_wait <= 0 and distance <= reach:
			enemy.target = pos if attack == "slam" else goal
			enemy.structure_id = -1 if blocker.is_empty() else blocker.id
			enemy.forward = pos.direction_to(goal)
			enemy.face = -1.0 if enemy.forward.x < 0 else 1.0
			enemy.attack = attack
			if blocker.is_empty():
				enemy.cycle += 1
			enemy.windup = (1.15 if run.mission == 1 else (0.8 if run.mission == 2 else 0.95)) if enemy.boss else (1.0 if attack == "hex" else (0.85 if attack == "cleave" else (0.65 if attack == "spit" else (0.34 if attack == "pounce" else 0.42))))
			enemy.tell = enemy.windup
		else:
			enemy.forward = pos.direction_to(goal)
			enemy.face = -1.0 if enemy.forward.x < 0 else 1.0
			var slow := (0.9 if enemy.boss else 0.6) if enemy.chill > 0 else 1.0
			var direction: Vector2 = enemy.forward
			if enemy.kind in ["spitter","hexer"]:
				if distance < 130:
					direction = -direction
				elif distance <= 210:
					direction = Vector2.ZERO
			elif distance < 20:
				direction = Vector2.ZERO
			enemy.pos = run.move_body(pos,pos + direction * enemy.speed * slow * delta,24 if enemy.boss else 13,1.0 if enemy.id%2 else -1.0)
	enemy.motion = float(enemy.get("motion", 0.0)) + pos.distance_to(enemy.pos) * 0.16
	enemy.moving = pos.distance_squared_to(enemy.pos) > 0.001
	enemy.velocity = (enemy.pos-pos)/maxf(delta,0.0001)
	enemy.motion_blend = move_toward(float(enemy.get("motion_blend",0.0)),1.0 if enemy.moving else 0.0,delta*8.0)
	if enemy.moving:
		enemy.motion_direction = enemy.velocity.normalized()

static func next_attack(run: RefCounted, enemy: Dictionary) -> String:
	if enemy.boss:
		var attacks: Array = run.Haven.MISSIONS[run.mission - 1].attacks if run.mission > 0 else ["rush", "slam", "toss"]
		var next: String = attacks[enemy.cycle % attacks.size()]
		if next == "slam" and enemy.pos.distance_to(run.player) > 110:
			for option: String in attacks:
				if option != "slam":
					return option
		return next
	return {"spitter":"spit","runner":"pounce","bulwark":"cleave","hexer":"hex"}.get(enemy.kind,"swipe")

static func strike(run: RefCounted, enemy: Dictionary) -> void:
	var pos: Vector2 = enemy.pos
	enemy.attack_anim = 0.32
	run.add_vfx("enemy_attack", pos, enemy.forward, 0.20)
	run.vfx_events.back().attack = enemy.attack
	match enemy.attack:
		"rush", "pounce":
			enemy.rush_direction = pos.direction_to(enemy.target)
			if enemy.rush_direction == Vector2.ZERO:
				enemy.rush_direction = enemy.forward
			enemy.forward = enemy.rush_direction
			enemy.rush_left = rush_duration(enemy)
			enemy.rush_hit = false
		"swipe":
			if enemy.get("structure_id", -1) >= 0:
				for structure: Dictionary in run.defenses.structures:
					var reach: float = run.Defenses.TYPES[structure.kind].radius + (42 if enemy.boss else 29)
					if structure.id == enemy.structure_id and structure.hp > 0 and pos.distance_to(structure.pos) <= reach:
						structure.hp -= 36 if enemy.boss else enemy.contact
						run.add_vfx("structure_hit",structure.pos,enemy.forward,0.30)
			else:
				var offset: Vector2 = run.player - pos
				if offset.length() <= 42 and (offset.length() < 10 or offset.normalized().dot(enemy.forward) > 0.3):
					run.hurt(enemy.contact)
			run.add_vfx("enemy_swipe", pos, enemy.forward, 0.26)
			enemy.recover = 0.55
		"cleave":
			var offset: Vector2 = run.player-pos
			if offset.length() <= 80 and (offset.length()<10 or offset.normalized().dot(enemy.forward)>0.15):
				run.hurt(enemy.contact)
			run.add_vfx("enemy_cleave",pos,enemy.forward,0.55)
			enemy.recover = 0.95
		"hex":
			for angle in [-0.28,0.0,0.28]:
				run.hostile_projectile(pos,pos.direction_to(enemy.target).rotated(angle),9.0*enemy.get("damage_scale",1.0),145.0,0.0,"hex")
			enemy.recover = 0.75
		"slam":
			run.add_effect("slam", enemy.target, enemy.target, 0.65)
			if run.player.distance_to(enemy.target) <= 80:
				run.hurt(30.0)
			enemy.recover = 0.85
		"toss":
			for angle in [-0.22, 0.0, 0.22]:
				run.hostile_projectile(pos, pos.direction_to(enemy.target).rotated(angle), 16.0, 190.0, 0.0, "rubble")
			enemy.recover = 0.55
		"spit":
			run.hostile_projectile(pos, pos.direction_to(enemy.target), 12.0*enemy.get("damage_scale",1.0), 170.0, 2.0, "spit")
			enemy.recover = 0.45
		"summon":
			for count in 4:
				if run.reinforcements_spawned >= 24 or run.enemies.filter(func(e: Dictionary): return e.hp > 0 and e.get("reinforcement", false)).size() >= 6:
					break
				var previous_count: int = run.enemies.size()
				run.spawn_enemy(false, "drifter")
				if run.enemies.size() > previous_count:
					run.reinforcements_spawned += 1
					run.enemies.back().reinforcement = true
					var summon_pos: Vector2 = run.clamp_position(pos + Vector2.from_angle(count * PI / 2) * 110)
					if summon_pos.distance_to(run.player) >= 80:
						run.enemies.back().pos = run.move_body(summon_pos,summon_pos,13)
					run.add_vfx("spawn", run.enemies.back().pos, Vector2.UP, 0.55)
			run.add_effect("summon", pos, pos, 0.8)
			enemy.recover = 0.75
	enemy.attack_wait = (1.6 if enemy.hp < enemy.max_hp * 0.5 else 2.4) if enemy.boss else (4.2 if enemy.kind == "hexer" else (2.2 if enemy.kind == "bulwark" else (3.4 if enemy.kind == "spitter" else 1.15)))
	if run.mission == 5 and enemy.attack == "rush" and enemy.hp < enemy.max_hp * 0.5:
		enemy.attack_wait = 1.8
