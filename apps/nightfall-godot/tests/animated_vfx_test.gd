extends SceneTree
const Run = preload("res://run.gd")
const Ember = preload("res://ember_vfx.gd")
const Hero = preload("res://hero_cast.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var run = Run.new(9)
	run.mission = 1
	run.spawn_wait = 999
	run.fire_wait = 999
	run.class_wait = 999
	run.spells = {"ember":{"rank":1,"wait":0.18}}
	run.spawn_enemy()
	var enemy: Dictionary = run.enemies[0]
	enemy.pos = run.player+Vector2(130,0)
	enemy.hp = 1000.0
	enemy.max_hp = 1000.0
	enemy.speed = 0
	enemy.attack_wait = 999
	var state: int = run.rng.state
	check(Ember.cast_pose(run).age < 0,"Cast anticipation uses the existing cooldown")
	check(run.shots.is_empty() and enemy.hp == 1000,"Anticipation cannot launch or damage early")
	var first_hit := false
	var flight_seen := false
	for n in 45:
		var before: float = enemy.hp
		run.tick(1.0/60,Vector2.ZERO)
		flight_seen = flight_seen or not run.shots.is_empty()
		if not first_hit and enemy.hp < before:
			first_hit = true
			check(is_equal_approx(before-enemy.hp,36),"Ember retains exact rank-one impact damage")
			check(run.vfx_events.any(func(e: Dictionary): return e.kind == "ember_hit" and e.pos == enemy.pos and is_equal_approx(e.life,0.72)),"Impact animation begins in the same tick and position as damage")
	check(flight_seen and first_hit,"Actual automatic cast, flight, and collision occurred")
	check(run.rng.state == state,"Visual events never advance gameplay RNG")
	check(run.effects.is_empty() and not run.vfx_events.is_empty(),"Smoke may outlive short legacy effect without adding damage")
	var saved := run.snapshot()
	check(not saved.combat.has("vfx_events"),"Transient graphics are excluded from player saves")
	var events: Array = run.vfx_events.duplicate(true)
	run.paused = true
	run.tick(1,Vector2.ZERO)
	check(run.vfx_events == events,"Pause freezes every animation event")
	run.paused = false
	run.spells.ember.wait = 999
	run.tick(1,Vector2.ZERO)
	check(run.vfx_events.is_empty(),"Resume ages and cleans up finished effects")
	for n in 80:
		run.add_vfx("ember_hit",run.player,Vector2.RIGHT,0.72)
	check(run.vfx_events.size() == 48,"Effect storage has a hard bound")
	check(run.restore(saved) and run.vfx_events.is_empty(),"Restore discards stale visual events")
	var foot := Vector2(0.25,0.95)
	check(Hero.deform_point(foot,Vector2(58,80),1,0,1,99,0) != Hero.deform_point(foot,Vector2(58,80),1,0.1,1,99,0),"Character feet articulate with continuous stride phase")
	check(Hero.deform_point(foot,Vector2(58,80),1,0,0,99,0) == Hero.deform_point(foot,Vector2(58,80),1,0,0,1,0),"Completed cast leaves no stuck deformation")
	var geometry := Ember.body_points(Vector2.ZERO,Vector2(20,17),0,0.2,0)
	var next_geometry := Ember.body_points(Vector2.ZERO,Vector2(20,17),0,0.2+1.0/60,0)
	check(geometry.size() == next_geometry.size() and geometry != next_geometry,"Continuous geometry moves between consecutive frames")
	var maximum_step := 0.0
	for n in geometry.size():
		maximum_step = maxf(maximum_step,geometry[n].distance_to(next_geometry[n]))
	check(maximum_step < 1.0,"Adjacent core frames deform smoothly without shape replacement")
	check(geometry == Ember.body_points(Vector2.ZERO,Vector2(20,17),0,0.2,0),"Identical simulation time freezes geometry")
	print("Nightfall animated VFX: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
