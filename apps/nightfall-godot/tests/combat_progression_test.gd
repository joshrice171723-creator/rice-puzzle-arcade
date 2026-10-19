extends SceneTree
const Progression = preload("res://combat_progression.gd")
const Profile = preload("res://profile.gd")
const Run = preload("res://run.gd")
const PATH := "user://nightfall_combat_progression_test.json"
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func enemy(run: RefCounted, hp: float = 48.0) -> Dictionary:
	run.spawn_enemy()
	var target: Dictionary = run.enemies.back()
	target.hp = hp
	target.max_hp = hp
	target.reward_hp = hp
	return target

func _initialize() -> void:
	cleanup()
	check(Progression.threshold(1) == 0 and Progression.threshold(2) == 13 and Progression.threshold(99) == 2172405, "Sixth-size curve has correct endpoints")
	for n in range(2, 100):
		check(Progression.threshold(n) > Progression.threshold(n - 1) and Progression.level(Progression.threshold(n)) == n and Progression.level(Progression.threshold(n) - 1) == n - 1, "Strict threshold " + str(n))
	check(Progression.level(1e12) == 99, "Stat level never exceeds 99")
	var p = Profile.new(PATH)
	check(p.load_save() and Progression.combat_level(p.data.combat_xp) == 1 and p.skill_points("scavenger") == 0, "Fresh level 1 yields no unearned points")
	var run = Run.new(97)
	run.configure(1, p.stats())
	var target := enemy(run)
	run.damage_enemy(target, 12, run.player)
	check(is_equal_approx(run.combat_xp.attack, 6) and is_equal_approx(run.combat_xp.vitality, 2), "Quarter of ordinary health earns quarter of budget")
	run.damage_enemy(target, 9999, run.player)
	run.damage_enemy(target, 9999, run.player)
	check(run.combat_xp.attack == 24 and run.combat_xp.vitality == 8, "Overkill and dead-target hits cannot multiply XP")
	target.hp = target.max_hp
	run.damage_enemy(target, 48, run.player)
	check(run.combat_xp.attack == 24, "Healing cannot refill enemy reward budget")
	target = enemy(run, 4800)
	run.damage_enemy(target, 4800, run.player)
	check(run.combat_xp.attack == 48, "Enemy HP inflation cannot inflate XP budget")
	run.training_style = "balanced"
	target = enemy(run)
	for i in 480:
		run.damage_enemy(target, 0.1, run.player, true)
	check(is_equal_approx(run.combat_xp.attack, 56) and is_equal_approx(run.combat_xp.strength, 8) and is_equal_approx(run.combat_xp.defence, 8), "Fractional ticks split XP without per-hit rounding loss")
	run.training_style = "arcane"
	target = enemy(run)
	target.burn = 1.0
	target.burn_dps = 12.0
	run.tick_enemy(target, 0.5)
	check(is_equal_approx(run.combat_xp.magic, 3.0), "Burn damage reaches permanent XP accounting")
	run.mission = 4
	target = enemy(run, 100)
	target.boss = true
	target.forward = Vector2.RIGHT
	run.damage_enemy(target, 20, target.pos + Vector2.RIGHT * 10)
	check(is_equal_approx(run.combat_xp.magic, 27.0), "Shield mitigation counts actual HP removed, boss budget 240")
	var before: Dictionary = run.combat_xp.duplicate()
	run.practice = true
	run.damage_enemy(enemy(run), 48, run.player)
	check(run.combat_xp == before and run.result().combat_xp == Progression.fresh(), "Practice cannot award permanent XP")
	run.practice = false
	run.benchmark_count = 1
	run.damage_enemy(enemy(run), 48, run.player)
	check(run.combat_xp == before and run.result().combat_xp == Progression.fresh(), "Benchmarks cannot award permanent XP")
	run.benchmark_count = 0
	var saved := run.snapshot()
	var resumed = Run.new()
	check(resumed.restore(saved) and resumed.combat_xp == before and resumed.training_style == "arcane", "Checkpoint preserves fractional XP and training focus")
	var legacy := saved.duplicate(true)
	for key in ["combat_xp", "training_style", "training_bonuses"]:
		legacy.erase(key)
	check(resumed.restore(legacy) and resumed.combat_xp == Progression.fresh(), "Legacy active expeditions resume without fabricated XP")
	saved.training_bonuses.magic = 9999
	check(not resumed.restore(saved), "Corrupt saved stat bonuses rejected")
	check(p.set_training_style("guarded") and not p.set_training_style("invalid"), "Training selection validates and persists")
	var attempt: Dictionary = p.start_attempt(1)
	check(not p.set_training_style("arcane"), "Active expedition freezes training focus")
	var outcome := run.result()
	outcome.victory = false
	for stat in Progression.STATS:
		outcome.combat_xp[stat] = float(Progression.threshold(10))
	var receipt: Dictionary = p.finish_attempt(attempt.id, outcome)
	check(receipt.talent_points == 9 and receipt.combat_after == 10 and p.skill_points("scavenger") == 9, "Defeat banks damage XP and every crossed combat level")
	before = p.data.duplicate(true)
	check(p.finish_attempt(attempt.id, outcome).is_empty() and p.data == before, "Result retry cannot duplicate XP or points")
	check(p.unlock_skill("scavenger", "wisp") and p.skill_points("engineer") == 8, "Class trees spend one shared global pool")
	var reloaded = Profile.new(PATH)
	check(reloaded.load_save() and reloaded.data == p.data, "Permanent levels and global spending persist exactly")
	var old: Dictionary = p.data.duplicate(true)
	old.version = 4
	old.erase("combat_xp")
	old.erase("training_style")
	old.erase("legacy_talent_points")
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	check(reloaded.load_save() and "wisp" in reloaded.ability_pool("scavenger") and reloaded.skill_points("scavenger") == 0 and reloaded.data.legacy_talent_points == 1, "Old earned unlocks survive with spent-only legacy allowance")
	p.path = "user://missing-combat-test-dir/save.json"
	before = p.data.duplicate(true)
	check(not p.set_training_style("arcane") and p.data == before, "Failed style save rolls back")
	p.path = PATH
	attempt = p.start_attempt(1)
	p.path = "user://missing-combat-test-dir/save.json"
	before = p.data.duplicate(true)
	check(p.finish_attempt(attempt.id, outcome).is_empty() and p.data == before, "Failed reward save rolls back XP and points together")
	for stat in Progression.STATS:
		p.data.combat_xp[stat] = Progression.MAX_XP
	check(Progression.combat_level(p.data.combat_xp) == 99 and p.skill_points("scavenger") == 97, "99 cap grants exactly 98 lifetime points less spending")
	var boosts := Progression.bonuses(p.data.combat_xp)
	check(is_equal_approx(boosts.physical, 0.4) and is_equal_approx(boosts.magic, 0.3) and is_equal_approx(boosts.reduction, 0.15), "Max stat bonuses respect defined limits")
	var max_run = Run.new()
	max_run.configure(1, p.stats())
	target = enemy(max_run, 1000)
	max_run.damage_enemy(target, 100, max_run.player)
	check(is_equal_approx(target.hp, 860), "Strength and Ranged add once to physical damage")
	max_run.damage_enemy(target, 100, max_run.player, true)
	check(is_equal_approx(target.hp, 730), "Magic applies once to elemental damage")
	max_run.armor = 0
	var hp: float = max_run.health
	max_run.hurt(100)
	check(is_equal_approx(hp - max_run.health, 85), "Defence reduces actual incoming damage")
	check(is_equal_approx(p.stats().hp, Profile.new().stats().hp * 1.3), "Vitality adds at most thirty percent starting HP")
	var capped: Dictionary = p.data.combat_xp.duplicate()
	Progression.award(capped, "arcane", 1000, 1000, true)
	check(capped == p.data.combat_xp, "No overflowing XP beyond level 99")
	var area = Run.new()
	area.configure(1, Profile.new().stats())
	area.training_style = "guarded"
	for index in 3:
		var victim := enemy(area)
		victim.pos = area.player + Vector2(10 + index * 10, 0)
	area.spells.frost = {"rank": 1, "wait": 0.0}
	area.cast_spell("frost")
	check(is_equal_approx(area.combat_xp.defence, 39), "Automatic area damage credits all three actual targets")
	var turret = Run.new()
	turret.configure(1, Profile.new().stats())
	turret.training_style = "ranged"
	target = enemy(turret)
	target.pos = Vector2(700, 600)
	turret.defenses.place("turret", Vector2(600, 600), 40, false)
	turret.defenses.tick(0.8, turret)
	check(is_equal_approx(turret.combat_xp.ranged, 4), "Turret damage credits selected training focus")
	var partial = Run.new()
	partial.configure(1, Profile.new().stats())
	target = enemy(partial)
	partial.damage_enemy(target, 12, partial.player)
	resumed = Run.new()
	resumed.restore(partial.snapshot())
	resumed.damage_enemy(resumed.enemies[0], 9999, resumed.player)
	check(resumed.combat_xp.attack == 24, "Resumed partially damaged enemy preserves remaining reward budget")
	p = Profile.new(PATH)
	p.save()
	attempt = p.start_attempt(1)
	p.checkpoint(resumed.snapshot())
	reloaded = Profile.new(PATH)
	check(reloaded.load_save(), "In-progress training reloads from disk")
	var recovered_run = Run.new()
	check(recovered_run.restore(reloaded.saved_run()) and recovered_run.combat_xp == resumed.combat_xp, "Disk checkpoint preserves exact pending fractional XP")
	recovered_run.phase = "defeat"
	receipt = reloaded.finish_attempt(attempt.id, recovered_run.result())
	check(receipt.combat_xp.attack == 24, "Ending a saved expedition banks its pending combat XP")
	var capped_focus := Progression.fresh()
	capped_focus.attack = Progression.MAX_XP
	Progression.award(capped_focus, "accurate", 48, 48, false)
	check(capped_focus.attack == Progression.MAX_XP and capped_focus.vitality == 8, "Capped focus cannot steal the uncapped Vitality share")
	cleanup()
	print("Nightfall combat progression: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
