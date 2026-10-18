extends RefCounted
## Fixed-step rules for the isolated engine proof. No permanent progression.

const DURATION := 240.0
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

func _init(seed_value: int = 41) -> void:
	rng.seed = seed_value

func spawn_enemy(boss: bool = false) -> void:
	if enemies.size() >= MAX_ENEMIES:
		return
	var angle := rng.randf_range(0.0, TAU)
	var pos := clamp_position(player + Vector2.from_angle(angle) * 330.0)
	if pos.distance_to(player) < 180.0:
		pos = clamp_position(Vector2(1200, 1200) - player)
	var hp := 1000.0 if boss else 48.0
	enemies.append({"id": next_id, "pos": pos, "hp": hp, "max_hp": hp,
		"speed": 40.0 if boss else rng.randf_range(24.0, 44.0), "boss": boss,
		"tell": 0.0, "attack_wait": 2.0, "target": pos, "face": 1.0})
	if boss:
		boss_id = next_id
	next_id += 1

func clamp_position(pos: Vector2) -> Vector2:
	return pos.clamp(BOUNDS.position, BOUNDS.end)

func set_benchmark(count: int) -> void:
	benchmark_count = clampi(count, 0, MAX_ENEMIES)
	enemies.clear()
	shots.clear()
	pickups.clear()
	phase = "waves"
	elapsed = 0.0
	health = 120.0
	for i in benchmark_count:
		spawn_enemy()

func dodge() -> bool:
	if paused or phase not in ["waves", "boss"] or dodge_wait > 0.0:
		return false
	dodge_wait = 3.0
	dodge_left = 0.18
	return true

func pulse() -> bool:
	if paused or phase not in ["waves", "boss"] or pulse_wait > 0.0:
		return false
	pulse_wait = 8.0
	pulse_flash = 0.35
	for enemy in enemies:
		if player.distance_to(enemy.pos) <= 145.0:
			enemy.hp -= 55.0
			enemy.pos = clamp_position(enemy.pos + player.direction_to(enemy.pos) * 45.0)
	return true

func upgrade(choice: int) -> void:
	if phase != "upgrade" or choice not in [0, 1, 2]:
		return
	match choice:
		0: damage = minf(48.0, damage + 4.0)
		1: fire_interval = maxf(0.18, fire_interval - 0.025)
		2: health = minf(120.0, health + 35.0)
	phase = "boss" if boss_id >= 0 else "waves"

func tick(delta: float, direction: Vector2) -> void:
	if paused or phase not in ["waves", "boss"]:
		return
	elapsed += delta
	for key in ["fire_wait", "spawn_wait", "hurt_wait", "dodge_wait", "dodge_left", "pulse_wait", "pulse_flash"]:
		set(key, maxf(0.0, float(get(key)) - delta))
	if direction.length_squared() > 0.01:
		facing = direction.normalized()
	var move := facing if dodge_left > 0.0 else direction.limit_length()
	player = clamp_position(player + move * (520.0 if dodge_left > 0.0 else 125.0) * delta)
	if benchmark_count == 0 and phase == "waves" and elapsed >= DURATION:
		phase = "boss"
		# Reserve a slot: the crowd cap must never prevent mandatory boss arrival.
		if enemies.size() == MAX_ENEMIES:
			enemies.pop_back()
		spawn_enemy(true)
	if benchmark_count > 0:
		while enemies.size() < benchmark_count:
			spawn_enemy()
	elif phase == "waves" and spawn_wait <= 0.0:
		spawn_enemy()
		spawn_wait = maxf(0.30, 1.4 - elapsed / 240.0)
	if fire_wait <= 0.0 and not enemies.is_empty() and shots.size() < MAX_SHOTS:
		var nearest: Dictionary = enemies[0]
		for enemy in enemies:
			if player.distance_squared_to(enemy.pos) < player.distance_squared_to(nearest.pos):
				nearest = enemy
		shots.append({"pos": player, "velocity": player.direction_to(nearest.pos) * 500.0, "life": 0.85})
		fire_wait = fire_interval
	for enemy in enemies:
		var pos: Vector2 = enemy.pos
		enemy.face = -1.0 if player.x < pos.x else 1.0
		if enemy.boss:
			enemy.attack_wait -= delta
			if enemy.tell > 0.0:
				enemy.tell -= delta
				if enemy.tell <= 0.0 and player.distance_to(enemy.target) < 72.0:
					hurt(35.0)
			elif enemy.attack_wait <= 0.0:
				enemy.target = player
				enemy.tell = 1.0
				enemy.attack_wait = 3.5
		if enemy.tell <= 0.0:
			enemy.pos = clamp_position(pos.move_toward(player, enemy.speed * delta))
		if player.distance_squared_to(enemy.pos) < pow(30.0 if enemy.boss else 17.0, 2):
			hurt(18.0 if enemy.boss else 10.0)
	for shot in shots:
		shot.life -= delta
		shot.pos += shot.velocity * delta
		for enemy in enemies:
			if enemy.hp > 0.0 and shot.pos.distance_squared_to(enemy.pos) < pow(32.0 if enemy.boss else 17.0, 2):
				enemy.hp -= damage
				shot.life = 0.0
				break
	shots = shots.filter(func(s: Dictionary) -> bool: return s.life > 0.0)
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		if enemy.hp > 0.0:
			continue
		kills += 1
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
		if pickups[i].distance_to(player) < 70.0:
			pickups[i] = pickups[i].move_toward(player, 220.0 * delta)
		if pickups[i].distance_to(player) < 14.0:
			xp += 1
			pickups.remove_at(i)
	if benchmark_count == 0 and xp >= level * 5 and level < 12:
		xp -= level * 5
		level += 1
		phase = "upgrade"

func hurt(amount: float) -> void:
	if benchmark_count > 0 or hurt_wait > 0.0 or dodge_left > 0.0:
		return
	health = maxf(0.0, health - amount)
	hurt_wait = 0.8
