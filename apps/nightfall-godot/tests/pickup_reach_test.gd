extends SceneTree
const Run = preload("res://run.gd")
const Field = preload("res://field.gd")
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	var run=Run.new()
	run.spawn_wait=100;run.fire_wait=100
	check(is_equal_approx(run.experience_pickup_radius(),140),"Starting XP reach is twice the former 70")
	run.pickups.assign([run.player+Vector2(110,0),run.player+Vector2(141,0)])
	run.pickup_xp.assign([2,1])
	run.tick(0.1,Vector2.ZERO)
	check(run.pickups[0].distance_to(run.player)<110,"XP beyond old radius attracts immediately")
	check(is_equal_approx(run.pickups[1].distance_to(run.player),141),"XP outside new radius stays put")
	run.tick(0.3,Vector2.ZERO)
	check(run.xp==2 and run.pickups.size()==1,"Magnet conserves consolidated XP and collects only once")
	run.tick(0.3,Vector2.ZERO)
	check(run.xp==2,"Collected experience cannot be awarded twice")
	run.field.traits.reach=1;run.pickup_multiplier=1.2
	check(is_equal_approx(run.experience_pickup_radius(),210),"Existing trait and equipment reach stack on the new baseline")
	var field=Field.new()
	field.add_drop(Vector2(60,0),3,2)
	field.add_drop(Vector2(-73,0),5,4)
	field.tick(0.1,Vector2.ZERO)
	check(field.credits==3 and field.scrap==2 and field.drops.size()==1,"Loot collects at doubled 72 radius and preserves amounts")
	check(Field.RADIUS==60 and Field.SHRINE_RADIUS==145,"Auto-pickup does not expand chest or shrine activation")
	print("Pickup reach: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
