extends SceneTree

const Run = preload("res://run.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func target(run, offset: Vector2, boss: bool = false) -> Dictionary:
	run.spawn_enemy(boss)
	var enemy: Dictionary = run.enemies.back()
	enemy.pos = run.player + offset
	enemy.hp = 1000.0
	enemy.max_hp = 1000.0
	enemy.speed = 0.0
	enemy.attack_wait = 1000.0
	return enemy

func quiet_run():
	var run = Run.new(12)
	run.spawn_wait = 1000.0
	run.fire_wait = 1000.0
	return run

func _initialize() -> void:
	var run = quiet_run()
	var enemy := target(run, Vector2(80, 0))
	for frame in 60:
		run.tick(1.0 / 60, Vector2.ZERO)
	check(run.dodge_left == 0 and run.class_wait == 0 and run.player == Run.World.CENTER, "Scavenger never dodges or moves without input")
	check(run.dodge() and run.dodge_left == 0.30 and run.class_wait == 12, "Phase Step automatically enhances requested Dodge")
	run.dodge_wait = 0
	check(run.dodge() and run.dodge_left == 0.18, "Normal dodge remains usable while Phase Step recharges")
	run = quiet_run()
	run.class_id = "arcanist"
	run.tick(0.01, Vector2.ZERO)
	check(run.class_wait == 0, "Automatic pulse waits for a valid nearby enemy")
	enemy = target(run, Vector2(100, 0))
	run.tick(0.01, Vector2.ZERO)
	check(enemy.hp == 952 and run.class_wait == 16, "Arcanist pulse fires itself once enemies enter range")
	run.tick(0.01, Vector2.ZERO)
	check(enemy.hp == 952, "Automatic pulse respects cooldown")
	run = quiet_run()
	run.class_id = "engineer"
	run.defenses.place("turret", run.player + Vector2(100, 0), 40, true)
	run.tick(0.01, Vector2.ZERO)
	check(run.class_wait == 0, "Repair does not waste cooldown on a healthy structure")
	run.defenses.structures[0].hp = 50
	run.tick(0.01, Vector2.ZERO)
	check(run.class_wait == 24 and run.defenses.structures[0].repair_left > 0, "Engineer repairs damage without an ability button")
	run = quiet_run()
	run.class_id = "warden"
	run.tick(0.01, Vector2.ZERO)
	check(run.shield == 0, "Warden preserves shield until threatened")
	run.hostile_projectile(run.player + Vector2(50, 0), Vector2.LEFT, 10)
	run.tick(0.01, Vector2.ZERO)
	check(run.shield == 24 and run.class_wait == 22, "Incoming projectile triggers automatic Aegis")
	run.hurt(10)
	check(run.health == 120 and run.damage_taken == 0, "Fully shielded contact does not count as health damage")
	for id: String in Run.Content.SPELLS:
		run = quiet_run()
		enemy = target(run, Vector2(65 if id == "wisp" else 60, 0))
		run.spells[id] = {"rank": 1, "wait": 0.0}
		for frame in 15:
			run.tick(1.0 / 60, Vector2.ZERO)
		check(enemy.hp < 1000, "%s inflicts damage automatically without attack input" % id)
	run = quiet_run()
	var line: Array[Dictionary] = []
	for index in 6:
		line.append(target(run, Vector2(50 + index * 55, 0)))
	run.spells.lance = {"rank": 1, "wait": 0.0}
	run.cast_spell("lance")
	check(line[2].hp == 944 and line[3].hp == 1000, "Stone Lance stops at its three-target damage budget")
	run.spells.lance.rank = 3
	run.apply_passive("pierce")
	check(run.spells.lance.get("evolved", false), "Evolution works when paired passive is obtained after rank three")
	run.cast_spell("lance")
	check(line[4].hp == 916 and line[5].hp == 1000, "Rift Spear reaches exactly five targets")
	run = quiet_run()
	enemy = target(run, Vector2(30, 0))
	run.spells.ground = {"rank": 1, "wait": 0.0}
	run.cast_spell("ground")
	run.Magic.tick(run, 5.0)
	check(enemy.hp == 968 and run.zones.is_empty(), "Ground deals exactly four seconds of damage even with a long tick")
	run = quiet_run()
	enemy = target(run, Vector2(75, 0))
	run.spells.wisp = {"rank": 1, "wait": 0.0}
	run.Magic.tick(run, 0.01)
	run.Magic.tick(run, 0.01)
	check(enemy.hp == 990 and run.wisp_hits.size() == 1, "Wisp cannot repeatedly hit a target every frame")
	enemy.hp = 0
	run.Magic.tick(run, 0.01)
	check(run.wisp_hits.is_empty(), "Wisp memory removes dead targets")
	run = quiet_run()
	var near := target(run, Vector2(70, 0))
	enemy = target(run, Vector2(150, 0), true)
	run.spells.gravity = {"rank": 1, "wait": 0.0}
	run.cast_spell("gravity")
	check(near.hp == 984 and enemy.hp == 984 and enemy.pos == run.player + Vector2(150,0), "Gravity damage does not teleport enemies")
	run.Magic.tick(run,0.3)
	check(enemy.pos.is_equal_approx(run.player+Vector2(146,0)), "Gravity delivers half its displacement halfway through the pull")
	run.Magic.tick(run,0.3)
	check(enemy.pos.is_equal_approx(run.player+Vector2(142,0)), "Gravity boss displacement stays capped at eight over its full duration")
	run = quiet_run()
	check(run.apply_passive("focus") and run.apply_passive("vital") and run.apply_passive("channel"), "Three distinct passives fit a build")
	check(not run.apply_passive("fleet"), "A fourth passive cannot overflow build slots")
	run.apply_passive("focus")
	run.apply_passive("focus")
	check(not run.apply_passive("focus") and is_equal_approx(run.spell_scale(), 1.18), "Passive ranks and damage bonus are bounded")
	check(is_equal_approx(run.max_health(), 129.6), "Vital Reserve uses base HP rather than multiplicative compounding")
	run.spells.ember = {"rank": 2, "wait": 0.0}
	run.phase = "upgrade"
	run.offers.assign([{"id": "ember"}])
	run.choose_offer(0)
	check(run.spells.ember.evolved, "Choosing rank three with an existing pair also evolves")
	run = quiet_run()
	run.spells = {"ember": {"rank": 3, "wait": 0.0}, "frost": {"rank": 3, "wait": 0.0}, "chain": {"rank": 3, "wait": 0.0}}
	run.level = 10
	var combat_rng: int = run.rng.state
	for iteration in 20:
		run.make_offers()
		check(not run.offers.any(func(offer): return Run.Content.SPELLS.has(offer.id)), "Full attack slots never offer a fourth spell")
	check(run.rng.state == combat_rng, "Choosing upgrades cannot manipulate enemy-spawn RNG")
	run.mission = 1
	run.passives = {"magnet": 2}
	run.zones.assign([{"pos": run.player, "life": 2.5, "dps": 8.0, "radius": 90.0}])
	run.wisp_hits = {12: 4.0}
	var restored = Run.new()
	check(restored.restore(run.snapshot()) and restored.passives == run.passives and restored.zones == run.zones and restored.wisp_hits == run.wisp_hits, "Checkpoint preserves attacks, passive ranks and active AoE timers")
	run.make_offers()
	restored.make_offers()
	check(run.offers == restored.offers, "Checkpoint resumes the same future upgrade choices")
	print("Nightfall automatic magic: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

