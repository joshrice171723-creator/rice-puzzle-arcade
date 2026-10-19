extends SceneTree
const Run = preload("res://run.gd")
const Profile = preload("res://profile.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func _initialize() -> void:
	var run = Run.new(62)
	run.mission = 1
	run.spawn_enemy()
	var enemy: Dictionary = run.enemies.back()
	enemy.pos = run.player + Vector2(100, 0)
	var start: float = enemy.hp
	run.damage_enemy(enemy, 3, run.player)
	run.damage_enemy(enemy, 4, run.player, false, true)
	check(run.feedback.size() == 1 and run.feedback[0].amount == 7 and run.feedback[0].critical, "Rapid hits coalesce without losing damage or critical status")
	check(enemy.hp == start - 7, "Presentation preserves actual damage")
	check(is_equal_approx(run.combat_xp.attack, 24.0 * 7.0 / start), "Feedback cannot multiply permanent XP")
	run.paused = true
	run.tick(1, Vector2.ZERO)
	check(run.feedback[0].life == 0.62, "Pause freezes feedback")
	run.paused = false
	run.fire_wait = 5
	run.spawn_wait = 5
	run.tick(0.7, Vector2.ZERO)
	check(run.feedback.is_empty(), "Feedback expires during active simulation")
	for n in 100:
		run.add_feedback("hit", run.player, Vector2.RIGHT, 1)
	check(run.feedback.size() == 48, "Large AOE events have bounded storage")
	run.feedback.clear()
	run.enemies.clear()
	for n in 2:
		run.spawn_enemy()
		run.enemies.back().pos = Vector2(500,500)
	run.spawn_enemy(true)
	run.enemies.back().pos = Vector2(500,500)
	var boss: Dictionary = run.enemies.back()
	for n in 60:
		run.separate_enemies(1.0 / 60)
	check(run.enemies[0].pos.distance_to(run.enemies[1].pos) > 15, "Overlapping regular enemies spread into readable silhouettes")
	check(boss.pos == Vector2(500,500), "Spacing cannot displace the boss or its tell")
	run.enemies[0].tell = 1
	var held: Vector2 = run.enemies[0].pos
	run.separate_enemies(1)
	check(run.enemies[0].pos == held, "Spacing leaves a telegraphing enemy fixed")
	run.mission = 2
	run.enemies[0].tell = 0
	run.enemies[0].pos = Vector2(500,500)
	run.enemies[1].pos = Vector2(500,500)
	run.separate_enemies(1)
	check(run.enemies[0].pos.distance_to(run.enemies[1].pos) > 15, "Readable crowd spacing also applies in later missions")
	run.mission = 1
	run.enemies.clear()
	run.spawn_enemy()
	run.enemies[0].hp = 0
	run.enemies[0].pos = run.player + Vector2(10,0)
	run.spawn_enemy()
	run.enemies[1].pos = run.player + Vector2(100,0)
	check(run.nearest_enemy(run.player,425).id == run.enemies[1].id, "Auto targeting ignores defeated enemies")
	run.fire_wait = 0
	run.tick(0.01,Vector2.ZERO)
	check(not run.shots.is_empty() and run.shots[0].velocity.x > 0, "Automatic attack still fires toward a living target")
	run.enemies.clear()
	run.shots.clear()
	run.fire_wait = 0
	run.spawn_wait = 5
	run.tick(0.01,Vector2.ZERO)
	check(run.shots.is_empty(), "No phantom firing without a target")
	run.elapsed = run.duration - 0.01
	run.tick(0.02,Vector2.ZERO)
	check(run.phase == "boss" and run.boss_id >= 0, "Survival timer summons the mandatory boss")
	run.tick(0.02,Vector2.ZERO)
	check(run.phase == "boss", "Timer expiry never wins the mission")
	for target in run.enemies:
		if target.boss:
			run.damage_enemy(target,99999,run.player)
	run.tick(0.01,Vector2.ZERO)
	check(run.phase == "victory", "Boss kill wins the mission without a second timer")
	# Real starter stats and automatic combat; no invulnerability or damage edits.
	var profile = Profile.new("user://unused_mission_one_fixture.json")
	for seed_value in [19,41,73]:
		var scenario = Run.new(seed_value)
		scenario.configure(1,profile.stats())
		var peak_usec := 0
		for frame in 60 * 480:
			if scenario.phase == "upgrade":
				scenario.choose_offer(0)
			if scenario.phase == "shrine":
				scenario.leave_shrine()
			var started := Time.get_ticks_usec()
			scenario.tick(1.0 / 60,Vector2.from_angle(scenario.elapsed * 0.65))
			peak_usec = maxi(peak_usec,Time.get_ticks_usec() - started)
			if scenario.phase in ["victory","defeat"]:
				break
		check(scenario.phase in ["victory","defeat"], "Starter Mission One reaches a real outcome, seed " + str(seed_value))
		print("Mission One seed %d: %s at %.1fs; %d kills; run level %d; peak simulation %.2fms" % [seed_value,scenario.phase,scenario.elapsed,scenario.kills,scenario.level,peak_usec / 1000.0])
	print("Mission One presentation: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
