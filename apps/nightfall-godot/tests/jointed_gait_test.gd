extends SceneTree
const Gait = preload("res://jointed_gait.gd")
const Motion = preload("res://enemy_motion.gd")
const Hero = preload("res://hero_cast.gd")
var checks := 0
var failures := 0
func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)
func _initialize() -> void:
	var previous := Vector2.ZERO
	for n in 60:
		var phase := (0.1+float(n)/100.0)*TAU
		var at := Gait.foot(phase,Vector2.RIGHT,19.8,5)
		if n>0 and n<44:
			check(is_equal_approx(at.x-previous.x,-0.36) and at.y==0,"Stance cancels the matching world translation without lifting")
		previous = at
	var actor := {"id":0,"motion":1.0,"moving":true,"face":1.0,"attack":"swipe"}
	var first := Motion.geometry(actor,Vector2(55,52),Vector2.ZERO,1,0,0,0)
	actor.motion += 0.08
	var second := Motion.geometry(actor,Vector2(55,52),Vector2.ZERO,1.016,0,0,0)
	var largest := 0.0
	var index := 0
	for n in first.size():
		if first[n].distance_to(second[n])>largest:
			largest = first[n].distance_to(second[n])
			index = n
	print("Maximum enemy vertex displacement: ",largest," at ",index)
	check(largest<1,"Adjacent gait frames remain continuous")
	print("Jointed gait: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
