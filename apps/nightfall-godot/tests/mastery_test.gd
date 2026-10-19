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
	var r = Run.new()
	r.mastery_level = 5
	var cache: Dictionary = r.field.sites.filter(func(site: Dictionary): return site.kind == "cache")[0]
	r.player = cache.pos + Vector2(249, 0)
	check(cache.pos in r.talents.cache_positions(r), "Scavenger mastery five reveals a nearby unopened cache")
	cache.opened = true
	check(cache.pos not in r.talents.cache_positions(r), "Opened caches stop displaying mastery markers")
	cache.opened = false
	r.player.x += 2
	check(cache.pos not in r.talents.cache_positions(r), "Cache Sense has a bounded reveal distance")
	r.class_id = "engineer"
	check(r.talents.cache_positions(r).is_empty(), "Selected class alone grants its mastery perks")
	r = Run.new()
	r.mastery_level = 9
	r.talents.slow_left = 2
	r.dodge()
	check(r.talents.slow_left == 2, "Slow removal remains locked before mastery ten")
	r.mastery_level = 10
	r.class_wait = 0
	r.dodge_wait = 0
	r.dodge()
	check(r.talents.slow_left == 0, "Phase Step removes slowing at mastery ten")
	r.talents.slow_left = 2
	r.dodge_wait = 0
	r.dodge()
	check(r.talents.slow_left == 2, "Ordinary Dodge does not reset Phase Step's cooldown or cleanse again")
	r.mastery_level = 15
	r.class_wait = 0
	r.dodge_wait = 0
	r.dodge()
	check(r.talents.opening_shot, "Mastery fifteen arms the next basic hit after a requested Phase Step")
	check(r.talents.basic_damage(r, {"kind": "ember"}, 40) == 40 and r.talents.opening_shot, "Automatic spell hits do not consume the basic-hit bonus")
	check(r.talents.basic_damage(r, {}, 40) == 50 and not r.talents.opening_shot, "Opening Shot adds twenty-five percent exactly once")
	check(r.talents.basic_damage(r, {}, 40) == 40, "Later hits and piercing targets receive normal damage")
	r = Run.new()
	r.mastery_level = 20
	r.medkit_fraction = 0.2
	r.hurt(500)
	check(r.health == 1 and r.talents.last_light_used and r.hurt_wait == 2, "Last Light survives a lethal hit at one HP with a short protection window")
	check(not r.medkit_used, "Last Light does not silently consume the Field Medkit")
	r.hurt(500)
	check(r.health == 1 and r.damage_taken == 1, "Protection prevents instant repeat death")
	var resumed = Run.new()
	r.mission = 1
	check(resumed.restore(r.snapshot()) and resumed.talents.last_light_used, "Last Light use persists in the active-run checkpoint")
	resumed.hurt_wait = 0
	resumed.hurt(500)
	check(resumed.health == 0, "Reload cannot earn a second Last Light")
	resumed.phase = "defeat"
	check(resumed.rescue() and resumed.talents.last_light_used, "Rewarded rescue does not reset the once-per-run talent")
	resumed.paused = false
	resumed.hurt_wait = 0
	resumed.hurt(500)
	check(resumed.health == 0, "Another lethal hit after rescue remains lethal")
	r = Run.new()
	r.spawn_wait = 100
	r.hostile_projectile(r.player, Vector2.ZERO, 12, 0, 2)
	r.tick(0.01, Vector2.ZERO)
	check(r.talents.slow_left == 2 and r.health == 108, "Spitter projectile applies its two-second slow only with damage")
	var from: Vector2 = r.player
	r.tick(0.5, Vector2.RIGHT)
	check(is_equal_approx(r.player.x - from.x, Run.World.HERO_SPEED*0.8*0.5), "Slow reduces walking speed by twenty percent")
	r.paused = true
	r.tick(1, Vector2.RIGHT)
	check(r.talents.slow_left == 1.5, "Pause freezes the temporary slow")
	r = Run.new()
	r.shield = 100
	r.shield_left = 5
	r.hostile_projectile(r.player, Vector2.ZERO, 12, 0, 2)
	r.tick(0.01, Vector2.ZERO)
	check(r.talents.slow_left == 0, "Fully shielded hits do not apply the slow")
	r = Run.new()
	r.class_id = "engineer"
	r.mastery_level = 20
	r.defenses.place("turret", r.player + Vector2(60, 0), 40, true)
	r.defenses.place("barricade", r.player + Vector2(140, 0), 40, true)
	r.defenses.place("barricade", r.player + Vector2(170, 0), 40, true)
	var turret: Dictionary = r.defenses.structures[0]
	turret.hp = 50
	r.defenses.structures[1].hp = 100
	r.defenses.structures[2].hp = 100
	check(r.class_ability() and turret.boost_left == 4, "Engineer repair grants its turret a bounded firing boost")
	check(is_equal_approx(r.defenses.structures[1].hp, 109.9) and r.defenses.structures[2].hp == 100, "Linked Repairs heals five percent of exactly one adjacent structure")
	r.spawn_enemy()
	r.enemies[0].pos = r.player + Vector2(200, 100)
	turret.wait = 0
	r.defenses.tick(0.01, r)
	check(is_equal_approx(turret.wait, 0.8 / 1.15), "Overclock raises firing rate fifteen percent, not damage")
	r.defenses.tick(4, r)
	check(turret.boost_left == 0, "Overclock expires instead of permanently improving the turret")
	r.enemies.clear()
	r.defenses.structures.clear()
	r.player = Run.World.CENTER+Vector2(0,80)
	r.facing = Vector2.RIGHT
	r.field.scrap = 100
	r.blueprints.assign(["turret"])
	r.open_build()
	check(r.place_structure("turret") and r.field.scrap == 55, "Engineer mastery charges the discounted construction cost")
	check(r.dismantle_structure() and r.field.scrap == 73 and r.defenses.used_capacity() == 0, "Reclaim refunds forty percent of forty-five spent, releases capacity and removes the structure")
	check(not r.dismantle_structure() and r.field.scrap == 73, "Repeated reclaim cannot duplicate scrap")
	r.mastery_level = 14
	r.defenses.place("turret", r.player + Vector2(60, 0), 40, true)
	check(not r.dismantle_structure(), "Reclaim remains locked below mastery fifteen")
	print("Nightfall class mastery: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
