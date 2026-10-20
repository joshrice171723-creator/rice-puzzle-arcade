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
	var r = Run.new()
	r.field.scrap = 500
	r.blueprints.assign(["barricade", "trap", "turret", "ward"])
	r.player = r.World.CENTER + Vector2(0, 100)
	r.facing = Vector2.RIGHT
	r.open_build()
	check(r.phase == "build" and r.elapsed == 0, "Build selection pauses the run")
	check(r.place_structure("turret") and r.field.scrap == 450 and r.defenses.used_capacity() == 3, "Turret costs fifty scrap and three capacity")
	check(not r.place_structure("barricade") and r.field.scrap == 450, "Overlapping placement cannot spend scrap")
	r.player = r.World.CENTER + Vector2(-200, 400)
	check(r.place_structure("turret") and r.defenses.used_capacity() == 6, "Second turret can be built in an open spot")
	r.player = r.World.CENTER + Vector2(200, 700)
	check(not r.place_structure("turret") and r.field.scrap == 400, "No third damaging turret")
	check(r.place_structure("ward") and r.defenses.used_capacity() == 8, "Ward fills remaining capacity")
	r.player = r.World.CENTER + Vector2(0, -600)
	check(not r.place_structure("barricade"), "Capacity prevents ninth point")
	r.defenses.structures[0].hp = 0
	r.defenses.tick(0, r)
	check(r.defenses.used_capacity() == 5, "Destroyed structures release capacity")
	r.player = r.field.sites[0].pos - r.facing * 90.0
	check(not r.place_structure("barricade"), "Structures cannot obstruct shrine activation rings")
	r.player = r.World.BOUNDS.end - Vector2(10, 0)
	check(not r.place_structure("barricade"), "Placement cannot leave arena bounds")
	r = Run.new()
	r.class_id = "engineer"
	r.defenses.place("turret", r.World.CENTER + Vector2(100, 0), 40, true)
	check(is_equal_approx(r.defenses.structures[0].max_hp, 110), "Engineer structures gain ten percent health")
	check(not r.class_ability() and r.class_wait == 0, "Repair with no damaged target does not waste cooldown")
	r.defenses.structures[0].hp = 50
	check(r.class_ability() and r.class_wait == 24, "Repair Swarm starts on a nearby damaged structure")
	r.defenses.tick(4, r)
	check(is_equal_approx(r.defenses.structures[0].hp, 72), "Repair restores exactly twenty percent maximum HP over four seconds")
	r.defenses.tick(4, r)
	check(is_equal_approx(r.defenses.structures[0].hp, 72), "Repair cannot continue healing after its duration")
	r = Run.new()
	r.defenses.place("ward", r.World.CENTER + Vector2(0, 0), 40, false)
	r.defenses.place("ward", r.World.CENTER + Vector2(100, 0), 40, false)
	r.hurt(20)
	check(is_equal_approx(r.health, 102), "Overlapping wards do not stack mitigation")
	r.hurt_wait = 0
	r.armor = 100000
	r.field.relics.assign(["obsidian"])
	r.hurt(100)
	check(r.health >= 61.5, "Armor, relic and ward preserve global mitigation cap")
	r = Run.new()
	r.spawn_enemy()
	r.enemies[0].pos = r.World.CENTER + Vector2(200, 0)
	r.defenses.place("turret", r.World.CENTER + Vector2(0, 0), 40, false)
	r.defenses.tick(0.8, r)
	check(r.enemies[0].hp == 40, "Turret deals its advertised eight damage")
	r.defenses.tick(0.1, r)
	check(r.enemies[0].hp == 40, "Turret respects its fire interval")
	r.defenses.place("trap", r.World.CENTER + Vector2(200, 0), 40, false)
	r.defenses.tick(0.1, r)
	check(r.enemies[0].hp <= 0 and r.defenses.structures.size() == 1, "Trap hits nearby enemies and consumes itself")
	r = Run.new()
	r.spawn_enemy()
	r.enemies[0].pos = r.World.CENTER + Vector2(0, 0)
	r.defenses.place("barricade", r.World.CENTER + Vector2(0, 0), 40, false)
	r.defenses.tick(0.1, r)
	check(r.enemies[0].pos.distance_to(r.World.CENTER + Vector2(0, 0)) >= 42, "Barricade pushes enemies outside its blocking radius")
	check(r.defenses.structures[0].hp == 180, "Enemy contact alone cannot silently damage barricades")
	r.enemies[0].attack_wait = 0.0
	r.tick_enemy(r.enemies[0],0.01)
	check(r.enemies[0].tell > 0,"Enemy telegraphs its attack against a barricade")
	r.tick_enemy(r.enemies[0],0.42)
	check(r.defenses.structures[0].hp == 170, "Enemy strike damages barricades after the windup")
	var p = Profile.new()
	r = Run.new()
	r.configure(4, p.stats())
	r.spawn_enemy(true)
	var boss: Dictionary = r.enemies[0]
	boss.pos = r.World.CENTER + Vector2(200, 0)
	boss.forward = Vector2.LEFT
	r.damage_enemy(boss, 100, r.World.CENTER + Vector2(0, 0))
	check(boss.hp == 950, "Scrapback blocks half of frontal physical damage")
	r.damage_enemy(boss, 100, r.World.CENTER + Vector2(400, 0))
	check(boss.hp == 850, "Scrapback rear receives full physical damage")
	r.damage_enemy(boss, 100, r.World.CENTER + Vector2(0, 0), true)
	check(boss.hp == 750, "Elemental builds offer another answer to Scrapback armor")
	r.configure(3, p.stats())
	boss.attack = "summon"
	boss.recover = 0.0
	boss.tell = 0.01
	r.tick_enemy(boss, 0.02)
	check(r.enemies.size() == 5, "Porchcaller summons four bounded ordinary enemies")
	for enemy in r.enemies:
		check(enemy.pos.distance_to(r.player) >= 80, "Summoned enemies cannot appear on top of the player")
	for cast in 12:
		boss.attack = "summon"
		boss.recover = 0.0
		boss.tell = 0.01
		r.tick_enemy(boss, 0.02)
	check(r.enemies.size() == 7 and r.reinforcements_spawned == 6, "Caller has at most six living reinforcements")
	for cast in 12:
		for enemy in r.enemies:
			if not enemy.boss:
				enemy.hp = 0
		boss.recover = 0.0
		boss.tell = 0.01
		r.tick_enemy(boss, 0.02)
	check(r.reinforcements_spawned == 24, "Total summoned rewards are bounded even in a prolonged boss fight")
	var copy = Run.new()
	check(copy.restore(r.snapshot()), "Defense-capable run snapshot restores")
	print("Nightfall defenses and bosses: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
