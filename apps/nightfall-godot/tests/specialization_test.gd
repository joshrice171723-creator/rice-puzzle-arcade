extends SceneTree
const Run = preload("res://run.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func branch_run(id: String, branch: String):
	var run = Run.new()
	run.spawn_wait = 1000.0
	run.fire_wait = 1000.0
	run.spells[id] = {"rank": 2, "branch": branch, "wait": 0.0}
	return run

func target(run, offset: Vector2) -> Dictionary:
	run.spawn_enemy()
	var enemy: Dictionary = run.enemies.back()
	enemy.pos = run.player + offset
	enemy.hp = 10000.0
	enemy.speed = 0.0
	return enemy

func _initialize() -> void:
	for id: String in Run.Content.SPELLS:
		var run = Run.new()
		run.mission = 1
		run.phase = "upgrade"
		run.spells[id] = {"rank": 1, "wait": 0.0}
		run.offers.assign([run.spell_offer(id), {"id": "heal", "name": "Field Dressing", "description": "Heal"}])
		var originals: Array = run.offers.duplicate(true)
		var random_state: int = run.offer_rng.state
		run.choose_offer(0)
		check(run.phase == "upgrade" and run.spells[id].rank == 1 and run.offers.size() == 2, "%s previews two specializations before spending the level" % id)
		run.return_to_offers()
		check(run.offers == originals and run.offer_rng.state == random_state, "Returning from %s keeps original offers without a free reroll" % id)
		run.choose_offer(0)
		var resumed = Run.new()
		check(resumed.restore(run.snapshot()) and resumed.offer_back == originals, "%s branch choice survives saving midway" % id)
		resumed.paused = false
		resumed.choose_offer(1)
		check(resumed.spells[id].rank == 2 and resumed.spells[id].branch == "spread" and resumed.phase == "waves" and resumed.offer_back.is_empty(), "%s chosen branch uses one rank and resumes automatic combat" % id)
		resumed.choose_offer(0)
		check(resumed.spells[id].rank == 2, "Repeated tap cannot advance %s again" % id)
		resumed.apply_passive(Run.Content.EVOLUTIONS[id].pair)
		resumed.phase = "upgrade"
		resumed.offers.assign([resumed.spell_offer(id)])
		resumed.choose_offer(0)
		check(resumed.spells[id].rank == 3 and resumed.spells[id].evolved and resumed.spells[id].branch == "spread", "%s evolution retains specialization and requires its passive" % id)
		for branch in ["focus", "spread"]:
			var cast = branch_run(id, branch)
			var enemy := target(cast, Vector2(60, 0))
			for frame in 24:
				cast.tick(1.0 / 60, Vector2.ZERO)
			check(enemy.hp < 10000, "%s / %s deals damage automatically" % [id, branch])
	var wide = branch_run("frost", "spread")
	var narrow = branch_run("frost", "focus")
	var wide_foe := target(wide, Vector2(170, 0))
	var narrow_foe := target(narrow, Vector2(170, 0))
	wide.cast_spell("frost")
	narrow.cast_spell("frost")
	check(wide_foe.hp < 10000 and narrow_foe.hp == 10000, "Frost branches change real coverage")
	wide = branch_run("frost", "spread")
	narrow = branch_run("frost", "focus")
	wide_foe = target(wide, Vector2(70, 0))
	narrow_foe = target(narrow, Vector2(70, 0))
	wide.cast_spell("frost")
	narrow.cast_spell("frost")
	check(is_equal_approx(10000 - wide_foe.hp, 26) and is_equal_approx(10000 - narrow_foe.hp, 42.25), "Frost damage tradeoff agrees with rank and specialization")
	wide = branch_run("lance", "spread")
	narrow = branch_run("lance", "focus")
	target(wide, Vector2(70, 0))
	target(narrow, Vector2(70, 0))
	wide_foe = target(wide, Vector2(140, 30))
	narrow_foe = target(narrow, Vector2(140, 30))
	wide.cast_spell("lance")
	narrow.cast_spell("lance")
	check(wide_foe.hp < 10000 and narrow_foe.hp == 10000, "Stone Fan hits off-axis enemies that Obsidian Needle misses")
	var run = branch_run("wisp", "spread")
	check(run.Magic.wisp_position(run, 0).distance_to(run.Magic.wisp_position(run, 1)) == 150, "Twin Wisps orbit opposite sides")
	run = branch_run("ground", "spread")
	run.spells.ground.evolved = true
	run.health = 50
	target(run, Vector2(70, 0))
	run.cast_spell("ground")
	run.cast_spell("ground")
	run.Magic.tick(run, 1.0)
	check(is_equal_approx(run.health, 50.6), "Overlapping Sanctuary circles cannot stack healing")
	run.player += Vector2(200, 0)
	run.Magic.tick(run, 1.0)
	check(is_equal_approx(run.health, 50.6), "Sanctuary healing requires staying in its circle")
	run = branch_run("gravity", "focus")
	run.spells.gravity.evolved = true
	var foe := target(run, Vector2(70, 0))
	run.cast_spell("gravity")
	var after_pull: float = foe.hp
	run.Magic.tick(run, 0.6)
	check(foe.hp == after_pull - 8 and run.zones.is_empty(), "Collapsed Star grants one delayed burst")
	run.Magic.tick(run, 1.0)
	check(foe.hp == after_pull - 8, "Collapsed Star cannot recurse or burst again")
	run = branch_run("blades", "spread")
	run.spells.blades.evolved = true
	target(run, Vector2(100, 0))
	run.cast_spell("blades")
	check(run.shots.size() == 4, "Evolved fan launches four bounded blades")
	for index in 100:
		run.cast_spell("blades")
	check(run.shots.size() == Run.MAX_SHOTS, "Multi-projectile upgrades respect the shared shot budget")
	print("Nightfall specialization: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
