extends SceneTree
const Run = preload("res://run.gd")
const Profile = preload("res://profile.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func build(effects: Dictionary = {}, hero: String = "scavenger") -> RefCounted:
	var stats: Dictionary = Profile.new().stats()
	stats.talent_effects = effects
	stats.class_id = hero
	var run = Run.new(29)
	run.configure(1,stats)
	run.class_id = hero
	return run
func target(run: RefCounted, distance: float = 80) -> Dictionary:
	run.spawn_enemy(false,"drifter")
	var foe: Dictionary = run.enemies.back()
	foe.pos = run.player+Vector2(distance,0)
	foe.hp = 1000.0
	foe.max_hp = 1000.0
	return foe
func _initialize() -> void:
	var base = build()
	var enhanced = build({"basic_damage":0.2,"spell_damage":0.12,"spell_damage_by_id":{"ember":0.23},"spell_cooldown_by_id":{"ember":0.1}})
	base.Weapons.fire(base,target(base))
	enhanced.Weapons.fire(enhanced,target(enhanced))
	base.Projectiles.friendly(base,0.3)
	enhanced.Projectiles.friendly(enhanced,0.3)
	check(is_equal_approx(1000-enhanced.enemies[0].hp,(1000-base.enemies[0].hp)*1.2),"Basic talent applies once to real projectile damage")
	base.shots.clear();enhanced.shots.clear()
	for run in [base,enhanced]:
		run.spells={"ember":{"rank":1,"wait":0.0}}
		run.cast_spell("ember")
	check(is_equal_approx(enhanced.shots[0].damage/base.shots[0].damage,1.35),"Global plus named spell damage is capped at 35 percent")
	check(is_equal_approx(enhanced.spell_cooldown("ember")/base.spell_cooldown("ember"),0.9),"Named spell cooldown applies")
	check(is_equal_approx(enhanced.spell_scale("frost")/base.spell_scale("frost"),1.12),"Ember talent does not leak into Frost")
	enhanced.permanent_cooldown=0.3
	check(is_equal_approx(enhanced.spell_cooldown("ember"),enhanced.Content.SPELLS.ember.cooldown*0.7),"All spell cooldown sources share the 30 percent cap")
	var engineer = build({"structure_damage":0.25,"structure_hp":0.3,"repair":0.3},"engineer")
	engineer.field.scrap=100
	engineer.blueprints.assign(["turret"])
	engineer.player=engineer.World.CENTER+Vector2(0,100)
	engineer.facing=Vector2.RIGHT
	engineer.open_build()
	check(engineer.place_structure("turret"),"Engineer can place improved turret in a legal lane")
	var turret: Dictionary=engineer.defenses.structures[0]
	check(is_equal_approx(turret.max_hp,143) and engineer.field.scrap==50,"Structure talent increases HP once without changing cost")
	engineer.close_build()
	var foe=target(engineer,200)
	engineer.defenses.tick(0.8,engineer)
	check(is_equal_approx(1000-foe.hp,8*turret.power*1.25),"Turret damage receives its bounded talent once")
	turret.hp=10
	check(engineer.class_ability(),"Repair talent uses the actual automatic class ability")
	engineer.defenses.tick(4,engineer)
	check(is_equal_approx(turret.hp,10+143*0.2*1.3),"Repair throughput improves but duration stays four seconds")
	engineer.defenses.structures.clear()
	engineer.defenses.place("trap",engineer.player,40,false)
	foe.pos=engineer.player;foe.hp=1000
	engineer.defenses.tick(0.01,engineer)
	check(is_equal_approx(1000-foe.hp,60),"Trap talent is applied once, not squared")
	var warden=build({"shield":0.2,"class_cooldown":0.2},"warden")
	target(warden)
	check(warden.class_ability() and is_equal_approx(warden.shield,warden.max_health()*0.24),"Aegis scales within the 30 percent HP shield ceiling")
	check(is_equal_approx(warden.class_wait,warden.Haven.CLASSES.warden.cooldown*0.8),"Automatic ability uses talent cooldown")
	var scout=build({"dodge_cooldown":0.2,"interact_speed":0.25})
	check(scout.dodge() and is_equal_approx(scout.dodge_wait,2.4),"Dodge talent reduces recovery to 2.4 seconds")
	base.dodge()
	check(scout.dodge_left==base.dodge_left,"Dodge talent does not extend invulnerability")
	var altar: Dictionary=scout.field.sites[0]
	var approach: Vector2=scout.Field.interaction_center(altar)+Vector2(0,90)
	check(scout.field.tick(altar.duration/1.25,approach,1.25),"Interaction talent accelerates charging by the specified factor")
	var resumed=build()
	check(resumed.restore(enhanced.snapshot()) and resumed.talent_effects==enhanced.talent_effects,"A saved expedition retains its starting talent effects")
	var old: Dictionary=base.snapshot()
	old.erase("talent_effects")
	check(resumed.restore(old) and resumed.talent_effects.basic_damage==0,"Old checkpoints receive no unearned talent bonuses")
	var bad=Run.TalentEffects.normalized({"basic_damage":99,"shield":-2,"spell_damage":NAN,"spell_damage_by_id":{"ember":INF,"unknown":5}})
	check(bad.basic_damage==0.2 and bad.shield==0 and bad.spell_damage==0 and bad.spell_damage_by_id.ember==0 and not bad.spell_damage_by_id.has("unknown"),"Malformed bonuses cannot exceed the combat budget")
	print("Talent combat effects: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
