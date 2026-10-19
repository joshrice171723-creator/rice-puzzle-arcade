extends SceneTree

const Run = preload("res://run.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	var r = Run.new(1)
	r.paused = true
	r.tick(1.0, Vector2.RIGHT)
	check(r.elapsed == 0.0 and r.player == Run.World.CENTER, "Pause freezes movement and time")
	check(not r.dodge() and not r.class_ability(), "Pause rejects active abilities")
	r.paused = false
	r.elapsed = Run.DURATION - 0.01
	for i in Run.MAX_ENEMIES:
		r.spawn_enemy()
	r.tick(1.0 / 60, Vector2.ZERO)
	check(r.phase == "boss" and r.boss_id >= 0, "Timer starts boss even at enemy cap; never grants victory")
	check(r.enemies.size() <= Run.MAX_ENEMIES, "Boss reserves a bounded enemy slot")
	r.elapsed = 1000.0
	r.tick(1.0 / 60, Vector2.ZERO)
	check(r.phase == "boss", "Boss has no second deadline")
	for enemy in r.enemies:
		if enemy.boss:
			enemy.hp = 0.0
	r.tick(1.0 / 60, Vector2.ZERO)
	check(r.phase == "victory", "Boss kill while alive grants victory")
	var elapsed: float = r.elapsed
	r.tick(1.0, Vector2.RIGHT)
	check(r.elapsed == elapsed and not r.dodge(), "Terminal result cannot keep simulating")
	r = Run.new()
	r.phase = "boss"
	r.spawn_enemy(true)
	r.enemies[0].hp = 0.0
	r.health = 0.0
	r.tick(1.0 / 60, Vector2.ZERO)
	check(r.phase == "defeat", "Simultaneous death uses documented player-alive precedence")
	r = Run.new()
	check(r.dodge(), "Dodge can start")
	r.hurt(30.0)
	check(r.health == 120.0 and not r.dodge(), "Dodge grants temporary protection and respects cooldown")
	r.dodge_left = 0.0
	r.hurt(30.0)
	r.hurt(30.0)
	check(r.health == 90.0, "Contact invulnerability prevents same-tick damage pileup")
	r.phase = "upgrade"
	r.upgrade(0)
	check(r.damage == 28.0 and r.phase == "waves", "Upgrade applies once and resumes correct phase")
	r.upgrade(0)
	check(r.damage == 28.0, "Repeated upgrade tap cannot duplicate boost")
	var a = Run.new(88)
	var b = Run.new(88)
	a.set_benchmark(120)
	b.set_benchmark(120)
	for i in 600:
		a.tick(1.0 / 60, Vector2.RIGHT)
		b.tick(1.0 / 60, Vector2.RIGHT)
	check(a.player == b.player and a.kills == b.kills and a.enemies[0].pos == b.enemies[0].pos, "Seeded scenarios reproduce rules")
	check(a.enemies.size() <= 120 and a.shots.size() <= 64 and a.pickups.size() <= 40, "Crowds/projectiles/pickups remain bounded")
	check(a.player.x <= Run.BOUNDS.end.x, "Movement stays inside walkable area")
	check(a.health == 120.0, "Diagnostic crowd mode is explicitly invulnerable")
	print("Nightfall rules: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
