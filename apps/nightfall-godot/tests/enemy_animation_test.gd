extends SceneTree
const Motion = preload("res://enemy_motion.gd")
var checks := 0
var failures := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(description)

func bounds(points: PackedVector2Array) -> Rect2:
	var box := Rect2(points[0],Vector2.ZERO)
	for point in points:
		box = box.expand(point)
	return box

func _initialize() -> void:
	var size := Vector2(60,60)
	var reference: PackedVector2Array
	for kind in ["drifter","runner","spitter","bulwark","hexer"]:
		var enemy := {"id":2,"kind":kind,"motion":1.3,"moving":true,"face":1.0,"attack":"swipe"}
		var before := enemy.duplicate(true)
		var walking := Motion.geometry(enemy,size,Vector2.ZERO,1.0,0,0,0)
		check(enemy == before,"Animation never mutates " + kind)
		check(walking == Motion.geometry(enemy,size,Vector2.ZERO,1.0,0,0,0),"Frozen time gives identical " + kind + " geometry")
		if not reference.is_empty():
			check(walking != reference,kind + " has a distinct distance-driven gait")
		reference = walking
		enemy.moving = false
		var still := Motion.geometry(enemy,size,Vector2.ZERO,1.0,0,0,0)
		check(walking != still,kind + " transitions between walk and planted stance")
		enemy.face = -1.0
		var mirrored := Motion.geometry(enemy,size,Vector2.ZERO,1.0,0,0,0)
		check(is_equal_approx(still[0].x,-mirrored[0].x) and is_equal_approx(still[0].y,mirrored[0].y),"Facing mirrors around grounded feet")
		enemy.face = 1.0
		var dying := Motion.geometry(enemy,size,Vector2.ZERO,1.0,0,0,0.65)
		check(bounds(dying).size.x > bounds(still).size.x*1.05,"Death tips/crumples the silhouette rather than uniformly shrinking")
		for point in dying:
			check(point.is_finite() and point.y <= size.y*0.08+0.01,"Death remains finite and grounded")
	for attack in ["swipe","pounce","rush","slam","cleave","spit","hex","summon"]:
		var enemy := {"id":0,"kind":"drifter","moving":false,"face":1.0,"attack":attack}
		check(Motion.geometry(enemy,size,Vector2.ZERO,1,1,0,0) != Motion.geometry(enemy,size,Vector2.ZERO,1,0,0.3,0),attack+" has readable anticipation and follow-through")
	var texture_size := Vector2(Motion.EXPANSION.get_width(),Motion.EXPANSION.get_height())
	check(Motion.EXPANSION.get_image().detect_alpha() != Image.ALPHA_NONE,"New enemy artwork has genuine transparency")
	check(Motion.EXPANSION.get_image().has_mipmaps(),"Dense authored enemy art has minification mipmaps for phone-size mesh rendering")
	for kind in Motion.EXPANSION_REGIONS:
		check(Rect2(Vector2.ZERO,texture_size).encloses(Motion.EXPANSION_REGIONS[kind]),kind+" atlas crop is valid")
	print("Enemy animation: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
