extends SceneTree
const Run = preload("res://run.gd")
const Profile = preload("res://profile.gd")
const Weapons = preload("res://weapons.gd")
const Projectiles = preload("res://combat_projectiles.gd")
const Loot = preload("res://loot.gd")
var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func target(run: RefCounted, at: Vector2, kind: String = "drifter") -> Dictionary:
	run.spawn_enemy(kind == "breaker", kind)
	var enemy: Dictionary = run.enemies.back()
	enemy.pos = at
	return enemy

func _initialize() -> void:
	check(Projectiles.hit_time(Vector2.ZERO,Vector2(100,0),Vector2(50,0),10) == 0.4,"Swept hit finds first contact, not closest point")
	check(Projectiles.hit_time(Vector2.ZERO,Vector2(100,0),Vector2(50,11),10) == INF,"Near misses do not become hits")
	check(Projectiles.hit_time(Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,10) == 0,"Overlapping stationary shots have a valid contact")
	var r := Run.new()
	var far := target(r,r.player+Vector2(120,0))
	var near := target(r,r.player+Vector2(40,0))
	r.shots.append({"pos":r.player,"velocity":Vector2(1000,0),"life":1.0,"damage":20.0,"hits":[]})
	Projectiles.friendly(r,0.2)
	check(near.hp == 28 and far.hp == 48,"Fast nonpiercing projectile hits the nearest intersected enemy, regardless of array order")
	r.shots.append({"pos":r.player,"velocity":Vector2(1000,0),"life":1.0,"damage":10.0,"pierce":1,"hits":[]})
	Projectiles.friendly(r,0.2)
	check(near.hp == 18 and far.hp == 38 and r.shots.is_empty(),"Piercing hits two targets in one tick then stops")
	r.shots.append({"pos":r.player,"velocity":Vector2(1000,0),"life":0.01,"damage":10.0,"hits":[]})
	Projectiles.friendly(r,0.2)
	check(near.hp == 18,"Expiring projectile cannot hit beyond its remaining travel distance")
	r = Run.new()
	r.hostile_projectile(r.player-Vector2(80,0),Vector2.RIGHT,12,1000)
	Projectiles.hostile(r,0.2)
	check(r.health == 108 and r.hostile_shots.is_empty(),"Fast hostile projectile hits player along its path")
	r.hurt_wait = 0
	r.dodge()
	r.hostile_projectile(r.player-Vector2(80,0),Vector2.RIGHT,12,1000,2)
	Projectiles.hostile(r,0.2)
	check(r.health == 108 and r.talents.slow_left == 0,"Dodge prevents both projectile damage and its slow")
	r = Run.new()
	r.defenses.place("barricade",r.player-Vector2(60,0),40,true)
	var cover: Dictionary = r.defenses.structures[0]
	var cover_hp: float = cover.hp
	r.hostile_projectile(r.player-Vector2(130,0),Vector2.RIGHT,12,1000)
	Projectiles.hostile(r,0.2)
	check(r.health == 120 and cover.hp == cover_hp-12 and r.hostile_shots.is_empty(),"Cover intercepts the first projectile collision before the player")
	r = Run.new()
	r.defenses.place("barricade",r.player+Vector2(60,0),40,true)
	r.hostile_projectile(r.player-Vector2(130,0),Vector2.RIGHT,12,1000)
	Projectiles.hostile(r,0.2)
	check(r.health == 108 and r.defenses.structures[0].hp == r.defenses.structures[0].max_hp,"Cover behind the player cannot intercept a prior hit")
	r = Run.new()
	r.spells = {"ground":{"rank":2,"wait":1.0},"wisp":{"rank":2,"wait":1.0},"blades":{"rank":2,"wait":1.0}}
	r.level = 2
	r.phase = "upgrade"
	r.make_offers()
	r.choose_offer(0)
	check(r.phase == "waves","A preloaded full ability roster still receives a usable level-two upgrade")
	for id: String in Run.Content.SPELLS:
		r.spells[id] = {"rank":3,"wait":1.0}
	for id: String in Run.Content.PASSIVES:
		r.passives[id] = Run.Content.PASSIVES[id].max_rank
	r.phase = "upgrade"
	r.make_offers()
	r.choose_offer(0)
	check(r.phase == "waves","Exhausted upgrade pools never trap the player in an empty level-up screen")
	r = Run.new()
	r.field.sites.assign([r.field.sites[0]])
	r.player = Vector2(600,560)
	var stopped := r.move_body(r.player,Vector2(600,360),10)
	check(stopped.y >= 486.9 and stopped.distance_to(r.field.sites[0].pos) < r.Field.RADIUS,"Altar plinth blocks movement while leaving its charge ring accessible")
	var sliding := r.move_body(stopped,stopped+Vector2(90,-90),10)
	check(sliding.x > stopped.x+30,"Diagonal input slides around a landmark rather than sticking")
	r.player = Vector2(600,330)
	var pursuer := target(r,Vector2(600,580))
	for frame in 1200:
		r.tick_enemy(pursuer,1.0/60)
	check(pursuer.pos.distance_to(r.player) < 65,"Pursuing enemies route around an altar and can still reach the player")
	var front_edge := target(r,Vector2(600,490))
	target(r,Vector2(600,499))
	for frame in 60:
		r.separate_enemies(1.0/60)
	check(((front_edge.pos-Vector2(600,445))/Vector2(71,45)).length() >= 0.999,"Crowd separation cannot push an enemy into a solid shrine")
	r.practice = true
	check(r.move_body(Vector2(600,560),Vector2(600,360),10) == Vector2(600,360),"Hidden field landmarks never obstruct boss training")
	for kind in ["drifter","runner","spitter"]:
		r = Run.new()
		var e := target(r,r.player+Vector2(25 if kind != "spitter" else 180,0),kind)
		e.attack_wait = 0
		r.tick_enemy(e,0.01)
		check(e.tell > 0 and r.health == 120,"%s commits to a visible windup without contact damage" % kind)
		var locked: Vector2 = e.target
		r.player += Vector2(0,120)
		r.tick_enemy(e,e.tell)
		check(e.target == locked,"%s does not track the player after committing" % kind)
		for n in 30:
			r.tick_enemy(e,1.0/60)
			Projectiles.hostile(r,1.0/60)
		check(r.health == 120,"Moving off %s's committed attack avoids damage" % kind)
		r = Run.new()
		e = target(r,r.player+Vector2(25 if kind != "spitter" else 180,0),kind)
		e.attack_wait = 0
		for n in 120:
			r.tick_enemy(e,1.0/60)
			Projectiles.hostile(r,1.0/60)
		check(r.health < 120,"Standing still allows %s to deal real damage" % kind)
		e.hp = 0
		var before: float = r.health
		r.hostile_shots.clear()
		for n in 120:
			r.tick_enemy(e,1.0/60)
		check(r.health == before,"Dead %s cannot attack" % kind)
	for mission in range(1,6):
		r = Run.new()
		r.configure(mission,Profile.new().stats())
		var boss := target(r,r.player+Vector2(65,0),"breaker")
		for attack: String in r.Haven.MISSIONS[mission-1].attacks:
			boss.pos = r.player+Vector2(65,0)
			boss.tell = 0.0
			boss.recover = 0.0
			boss.rush_left = 0.0
			boss.attack_wait = 0.0
			r.tick_enemy(boss,0.01)
			check(boss.attack == attack and boss.tell > 0,"Mission %d telegraphs %s" % [mission,attack])
			r.tick_enemy(boss,boss.tell)
			check(boss.attack_anim > 0,"Mission %d attack animates at the actual strike" % mission)
	for mission in range(1,6):
		for attack: String in Run.Haven.MISSIONS[mission-1].attacks:
			r = Run.new()
			r.configure(mission,Profile.new().stats())
			var boss := target(r,r.player+Vector2(65,0),"breaker")
			boss.attack = attack
			boss.target = r.player if attack != "slam" else boss.pos
			boss.forward = boss.pos.direction_to(r.player)
			boss.tell = 0.01
			var before: float = r.health
			for frame in 100:
				r.tick_enemy(boss,1.0/60)
				Projectiles.hostile(r,1.0/60)
			check(r.enemies.size() > 1 if attack=="summon" else r.health < before,"Mission %d %s has a real gameplay consequence after its windup" % [mission,attack])
	for family: String in Weapons.TYPES:
		var profile := Profile.new()
		profile.data.inventory[0] = Loot.equipment("weapon","common",0,"outrider",family)
		check(profile.stats().weapon == family,"Equipped %s reaches combat configuration" % family)
		r = Run.new()
		r.configure(1,profile.stats())
		var enemy := target(r,r.player+Vector2(50,0))
		r.spawn_wait = 999
		check(Weapons.fire(r,enemy),"%s fires automatically" % family)
		var damage_before: float = enemy.hp
		for n in 60:
			Projectiles.friendly(r,1.0/60)
		check(enemy.hp < damage_before,"%s applies real damage" % family)
		var saved: Dictionary = r.snapshot()
		var restored := Run.new()
		check(restored.restore(saved) and restored.weapon_id == family,"%s survives checkpoint restore" % family)
		var spec: Dictionary = Weapons.TYPES[family]
		var raw_dps: float = 24.0*spec.scale*spec.count/spec.interval
		check(raw_dps >= 35 and raw_dps <= 41,"%s keeps equal-tier single-target damage inside 35-41 DPS" % family)
	for family in ["pistol","scattergun","crossbow","wand"]:
		r = Run.new()
		r.weapon_id = family
		var crossing := target(r,r.player+Vector2(150,0),"runner")
		crossing.velocity = Vector2(0,56)
		var before: float = crossing.hp
		Weapons.fire(r,crossing)
		for frame in 60:
			crossing.pos += crossing.velocity/60.0
			Projectiles.friendly(r,1.0/60)
		check(crossing.hp < before,"%s leads a crossing Runner instead of firing at a stale position" % family)
	var aim := Weapons.aim_direction(Vector2.ZERO,{"pos":Vector2(100,0),"velocity":Vector2(1000,0)},100,1)
	check(aim.is_finite() and aim == Vector2.RIGHT,"An impossible intercept falls back to a finite ordinary shot")
	# Class promises must match live loadout stats, including locked future classes.
	var p := Profile.new()
	var baseline: Dictionary = p.stats()
	p.data["class"] = "warden"
	check(is_equal_approx(p.stats().hp,baseline.hp*1.1) and p.stats().armor == baseline.armor+18,"Warden gets the advertised health and armor")
	p.data["class"] = "arcanist"
	r = Run.new()
	r.configure(1,p.stats())
	check(is_equal_approx(r.spell_scale(),1.08),"Arcanist's elemental bonus reaches spell damage")
	# All ranks, branches and evolutions must be usable in each class, without altering unlock gates.
	for hero: String in p.Content.CLASSES:
		for spell: String in Run.Content.SPELLS:
			for branch in ["", "focus", "spread"]:
				r = Run.new()
				r.class_id = hero
				r.spells[spell] = {"rank":1 if branch.is_empty() else 3,"branch":branch,"evolved":not branch.is_empty(),"wait":0.0}
				var e := target(r,r.player+Vector2(60,0))
				e.hp = 1000.0
				e.max_hp = 1000.0
				if spell == "wisp":
					e.pos = r.Magic.wisp_position(r)
				else:
					check(r.cast_spell(spell),"%s can cast %s/%s" % [hero,spell,branch])
				for frame in 60:
					r.elapsed += 1.0/60
					r.Magic.tick(r,1.0/60)
					Projectiles.friendly(r,1.0/60)
				check(e.hp < 1000,"%s %s/%s damages an in-range target" % [hero,spell,branch])
	r = Run.new()
	for index in 100:
		r.add_experience(Vector2(index*9,200))
	var sum_xp := 0
	for amount in r.pickup_xp:
		sum_xp += amount
	check(r.pickups.size() == 40 and sum_xp == 100,"Rendering cap combines XP without discarding earned rewards")
	r.mission = 1
	var copy := Run.new()
	check(copy.restore(r.snapshot()) and copy.pickup_xp == r.pickup_xp,"Combined XP amounts survive checkpoint restore")
	for index in 100:
		r.field.add_drop(Vector2(index*80,100),2,3)
	var credits := 0
	var scrap := 0
	for drop in r.field.drops:
		credits += drop.credits
		scrap += drop.scrap
	check(r.field.drops.size() == 48 and credits == 200 and scrap == 300,"Currency drop cap combines rather than discards loot")
	# A normal starter who refuses to move must face genuine pressure, not inert targets.
	r = Run.new(41)
	r.configure(1,Profile.new().stats())
	for frame in 18000:
		if r.phase == "upgrade":
			r.choose_offer(0)
		if r.phase == "shrine":
			r.leave_shrine()
		if r.phase in ["defeat","victory"]:
			break
		r.tick(1.0/60,Vector2.ZERO)
	check(r.phase == "defeat" and r.damage_taken > 5,"Standing still in a normal starter mission ends in defeat from actual enemy attacks")
	print("Nightfall combat mechanics: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
