extends SceneTree
const Run = preload("res://run.gd")
const Profile = preload("res://profile.gd")
const Neighborhood = preload("res://neighborhood.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error(label)
func _initialize() -> void:
 var profile = Profile.new("user://neighborhood_rules_fixture.json")
 var run = Run.new(8)
 run.configure(1,profile.stats())
 check(Run.BOUNDS.get_area() == 4*930*930,"Walkable neighborhood is four times the original area")
 var start: Vector2 = run.player
 run.spawn_wait=10;run.fire_wait=10
 run.tick(0.25,Vector2.RIGHT)
 check(is_equal_approx(run.player.distance_to(start),Run.World.HERO_SPEED*profile.stats().speed*0.25),"Hero movement uses slower base speed and class modifiers")
 var initial: Dictionary = Run.Content.pressure_at(0)
 var middle: Dictionary = Run.Content.pressure_at(120)
 var final: Dictionary = Run.Content.pressure_at(240)
 check(initial.rate==1 and final.rate==5,"Final arrival rate is five times opening rate before crowd pressure cap")
 for key in ["rate","hp","speed","damage"]:
  check(initial[key]<middle[key] and middle[key]<final[key],"Continuous round ramp: "+key)
 check(is_equal_approx(Run.Content.spawn_interval(0,240,1)/Run.Content.spawn_interval(240,240,1),5),"Arrival interval uses pressure curve")
 run.elapsed=0;run.spawn_enemy()
 var early: Dictionary=run.enemies.back().duplicate()
 run.elapsed=240;run.spawn_enemy()
 var late: Dictionary=run.enemies.back()
 check(is_equal_approx(late.max_hp/early.max_hp,1.65) and is_equal_approx(late.speed/early.speed,1.4) and is_equal_approx(late.contact/early.contact,1.35),"New enemies gain health, speed and damage as the round progresses")
 run.damage_enemy(early,early.hp,run.player)
 var earned: float=run.combat_xp.ranged
 run.damage_enemy(late,late.hp,run.player)
 check(earned>0 and is_equal_approx(earned,run.combat_xp.ranged-earned),"Tougher late enemies cannot inflate permanent training per kill")
 run.spawn_enemy(true)
 check(run.enemies.back().max_hp==run.Haven.MISSIONS[0].health,"Boss health is not double-scaled by wave ramp")
 for kind in ["bulwark","hexer"]:
  run.spawn_enemy(false,kind)
  var foe: Dictionary=run.enemies.back()
  foe.pos=run.player+Vector2(35,0);foe.target=run.player;foe.forward=Vector2.LEFT
  foe.attack=Run.EnemyCombat.next_attack(run,foe)
  var before: float=run.health
  run.hurt_wait=0
  Run.EnemyCombat.strike(run,foe)
  check(foe.recover>0 and foe.attack_anim>0,"Attack commits to animation and recovery: "+kind)
  if kind=="bulwark":check(run.health<before,"Cleaver deals its real frontal damage")
  else:check(run.hostile_shots.size()==3 and run.hostile_shots[0].kind=="hex","Hexer launches three real projectiles")
 for entry: Dictionary in Neighborhood.entries():
  var solid: Rect2=entry.footprint
  var at: Vector2=solid.get_center()
  var resolved: Vector2=run.move_body(at,at,10)
  check(not solid.grow(10).has_point(resolved),"Actor cannot remain inside "+entry.kind)
  check(not run.defenses.can_place("barricade",at,run.field.sites,at-Vector2(90,0)),"Cannot build inside "+entry.kind)
  for corner in [solid.position,solid.end,Vector2(solid.position.x,solid.end.y),Vector2(solid.end.x,solid.position.y)]:
   var boundary: Vector2=corner.clamp(Run.BOUNDS.position,Run.BOUNDS.end)
   var escaped: Vector2=run.move_body(boundary,boundary,10)
   check(not solid.grow(10).has_point(escaped) and escaped==run.clamp_position(escaped),"Boundary projection stays outside solid and inside world: "+entry.kind)
 var edge_walk: Vector2=Vector2(270,280)
 for step in 50:
  edge_walk=run.move_body(edge_walk,edge_walk+Vector2(0,4),10)
 check(not Neighborhood.entries()[0].footprint.grow(10).has_point(edge_walk),"Boundary walking cannot enter the garage")
 var shrine: Dictionary=run.field.sites[0]
 var access: Vector2=Run.Field.interaction_center(shrine)+Vector2(0,90)
 check(run.move_body(access,access,10).is_equal_approx(access),"Large altar has a reachable charging approach")
 check(run.field.tick(shrine.duration,access),"Standing inside visible large ring activates shrine")
 var original = Run.new(9)
 original.configure(1,profile.stats())
 original.player=Vector2(600,600)
 original.combat_xp.attack=240.0
 var old: Dictionary=original.snapshot()
 old.erase("world_version");old.erase("exp_curve")
 for site: Dictionary in old.field.sites:site.pos*=0.5
 var resumed=Run.new()
 resumed.configure(1,profile.stats())
 check(resumed.restore(old),"Pre-expansion checkpoint resumes")
 check(resumed.player==Run.World.CENTER and is_equal_approx(resumed.combat_xp.attack,24),"Legacy world coordinates and pending XP migrate once")
 var again=Run.new()
 again.configure(1,profile.stats())
 check(again.restore(resumed.snapshot()) and again.player==resumed.player and again.combat_xp==resumed.combat_xp,"Repeated save/load cannot multiply coordinates or training")
 old.player=Vector2(135,150)
 var edge_resume=Run.new()
 edge_resume.configure(1,profile.stats())
 check(edge_resume.restore(old) and not Neighborhood.entries()[0].footprint.grow(10).has_point(edge_resume.player) and edge_resume.player==edge_resume.clamp_position(edge_resume.player),"Legacy left-edge checkpoint resolves into walkable space")
 profile.set_setting("damage_numbers",false)
 profile.set_setting("health_bars",false)
 var reloaded=Profile.new(profile.path)
 check(reloaded.load_save() and not reloaded.data.settings.damage_numbers and not reloaded.data.settings.health_bars,"Combat display toggles persist")
 for suffix in ["",".tmp",".bak"]:
  if FileAccess.file_exists(profile.path+suffix):DirAccess.remove_absolute(profile.path+suffix)
 print("Neighborhood rules: %d checks, %d failures" % [checks,failures])
 quit(1 if failures else 0)
