extends SceneTree

const Run = preload("res://run.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func target_at(r, position: Vector2, kind: String = "drifter") -> Dictionary:
	r.spawn_enemy(kind == "breaker", kind)
	var enemy: Dictionary = r.enemies.back()
	enemy.pos = position
	return enemy

func _initialize() -> void:
	var r = Run.new()
	check(r.Content.wave_at(44).runner == 0 and r.Content.wave_at(45).runner > 0, "Runners enter at 45 seconds")
	check(r.Content.wave_at(99).spitter == 0 and r.Content.wave_at(100).spitter > 0, "Ranged enemies enter after the opening waves")
	r.phase = "upgrade"
	r.level = 2
	r.available_spells = ["ember", "frost", "chain"]
	r.make_offers()
	check(r.offers.size() == 3 and r.offers.all(func(offer): return offer.id in r.available_spells), "First level offers three available spells")
	r.choose_offer(0)
	r.choose_offer(0)
	check(r.spells.ember.rank == 1 and r.phase == "waves", "One selection grants one spell and resumes combat")
	var enemy := target_at(r, r.player + Vector2(60, 0))
	r.spawn_wait = 100
	r.fire_wait = 100
	r.spells.ember.wait = 0
	r.tick(1.0 / 60, Vector2.ZERO)
	check(r.shots.size() == 1 and r.spells.ember.wait == 5.0, "Ember starts a real projectile and five-second cooldown")
	for frame in 7:
		r.tick(1.0 / 60, Vector2.ZERO)
	check(enemy.hp < 12.1 and enemy.burn > 0 and enemy.burn_dps == 6.0, "Ember deals 36 impact then capped six-per-second burn")
	var saved_wait: float = r.spells.ember.wait
	var saved_burn: float = enemy.burn
	r.paused = true
	r.tick(1.0, Vector2.ZERO)
	check(r.spells.ember.wait == saved_wait and enemy.burn == saved_burn, "Pause freezes spells and damage-over-time")
	r = Run.new()
	var first := target_at(r, r.player + Vector2(50, 0))
	var second := target_at(r, r.player + Vector2(100, 0))
	var third := target_at(r, r.player + Vector2(150, 0))
	r.spells.chain = {"rank": 1, "wait": 0.0}
	r.cast_spell("chain")
	check(first.hp == 20 and second.hp == 30 and third.hp == 36 and r.effects.size() == 3, "Chain hits three distinct targets for 28/18/12")
	r = Run.new()
	first = target_at(r, r.player + Vector2(50, 0))
	var boss := target_at(r, r.player + Vector2(100, 0), "breaker")
	r.spells.frost = {"rank": 1, "wait": 0.0}
	r.cast_spell("frost")
	check(first.hp == 22 and first.chill == 3.0 and boss.hp == 974 and boss.chill == 1.5, "Frost damage matches Power and boss control duration is reduced")
	var before: Vector2 = boss.pos
	r.class_id = "arcanist"
	r.class_ability()
	check(boss.pos == before, "Automatic class pulse cannot push the boss")
	r = Run.new()
	var spitter := target_at(r, r.player + Vector2(200, 0), "spitter")
	spitter.attack_wait = 0
	r.tick_enemy(spitter, 0.01)
	var aim: Vector2 = spitter.target
	check(spitter.tell == 0.65 and r.hostile_shots.is_empty(), "Spitter visibly winds up before firing")
	r.player.y += 100
	r.tick_enemy(spitter, 0.65)
	check(r.hostile_shots.size() == 1 and r.hostile_shots[0].velocity.normalized().is_equal_approx(spitter.pos.direction_to(aim)), "Spitter locks its aim, allowing the shot to be dodged")
	r = Run.new()
	boss = target_at(r, r.player + Vector2(200, 0), "breaker")
	for attack in ["rush", "slam", "toss"]:
		boss.pos = r.player + Vector2(60,0)
		boss.attack_wait = 0
		boss.tell = 0
		boss.rush_left = 0
		boss.recover = 0
		r.tick_enemy(boss, 0.01)
		check(boss.attack == attack and boss.tell > 0 and r.hostile_shots.is_empty(), "Boss telegraphs %s before damage" % attack)
		r.tick_enemy(boss, 0.95)
		if attack == "rush":
			check(boss.rush_left == 0.65, "Rush is a bounded charge")
		if attack == "slam":
			check(boss.target == boss.pos, "Slam is centered on the boss")
	check(r.hostile_shots.size() == 3, "Rubble toss fires exactly three projectiles")
	for index in 100:
		r.hostile_projectile(Vector2.ZERO, Vector2.RIGHT, 12)
		r.add_effect("ember", Vector2.ZERO, Vector2.ZERO)
	check(r.hostile_shots.size() == 32 and r.effects.size() == 64, "Ranged attacks and effects have hard budgets")
	r = Run.new()
	r.spells.ember = {"rank": 3, "wait": 0.0}
	r.phase = "upgrade"
	r.level = 5
	r.damage = 48
	r.make_offers()
	check(r.offers.size() == 3 and not r.offers.any(func(offer): return offer.id in ["ember", "rounds", "heal"]), "Offers exclude capped ranks, capped damage, and full-health healing")
	r = Run.new()
	r.start_boss_practice()
	check(r.practice and r.phase == "boss" and r.boss_id >= 0 and r.spells.size() == 3, "Boss practice starts the encounter with three rank-one spells")
	for frame in 60 * 120:
		r.tick(1.0 / 60, Vector2.from_angle(r.elapsed * 0.65))
		if r.phase in ["victory", "defeat"]:
			break
	check(r.phase == "victory", "A moving rank-one spell loadout can defeat the boss using real damage")
	print("Nightfall boss practice: %s in %.1fs, %.0f HP remaining" % [r.phase, r.elapsed, r.health])
	# Exercise a complete unmodified run with a simple movement policy, not a balance claim.
	r = Run.new(41)
	for frame in 60 * 480:
		if r.phase == "upgrade":
			r.choose_offer(0)
		r.tick(1.0 / 60, Vector2.from_angle(r.elapsed * 0.65))
		if r.phase in ["victory", "defeat"]:
			break
	check(r.phase in ["victory", "defeat"], "Real combat reaches a terminal outcome without changing health or damage")
	print("Nightfall scenario: %s, %.1fs, %d kills, level %d, spells %s" % [r.phase, r.elapsed, r.kills, r.level, r.spells.keys()])
	print("Nightfall combat: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
