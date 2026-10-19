extends RefCounted
## Presentation only. The caller draws grounds first and sorts bodies with actor feet.
const Field = preload("res://field.gd")
const FLOOR = preload("res://assets/world/flagstones.png")
const ALTARS = preload("res://assets/world/altars.png")
const PROPS = preload("res://assets/field-props.png")
const ALTAR_RECTS := [Rect2(30, 350, 725, 630), Rect2(775, 350, 730, 630)]
const CRYSTAL_RECTS := [Rect2(308, 20, 190, 325), Rect2(1048, 25, 190, 320)]
const CACHE_RECTS := [Rect2(915, 45, 390, 400), Rect2(1350, 0, 420, 455)]
const AMBER := Color("ffca75")
const VIOLET := Color("c99aff")
const DORMANT := Color("7e88a5")

static func draw_floor(canvas: Node2D, offset: Vector2) -> void:
	# Project the authored square flags into 100x56 ground diamonds. UVs stay
	# anchored in world space, so camera motion cannot make the floor swim.
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for point: Vector2 in [Vector2(-300,-300),Vector2(1500,-300),Vector2(1500,1500),Vector2(-300,1500)]:
		points.append(point+offset)
		uv.append(Vector2(point.x+point.y*1.8,-point.x+point.y*1.8)/1000.0)
	canvas.draw_polygon(points,PackedColorArray([Color("c5c9e4")]),uv,FLOOR)

static func draw_site(canvas: Node2D, site: Dictionary, offset: Vector2, time: float, reduced: bool) -> void:
	draw_site_ground(canvas, site, offset, time, reduced)
	draw_site_body(canvas, site, offset, time, reduced)

static func draw_site_ground(canvas: Node2D, site: Dictionary, offset: Vector2, time: float, reduced: bool) -> void:
	var at: Vector2 = site.get("pos", Vector2.ZERO) + offset
	var opened: bool = site.get("opened", false)
	var color := AMBER if site.get("kind", "") in ["shop", "cache"] else VIOLET
	var dormant: bool = opened or site.get("cooldown", 0.0) > 0.0 or site.get("must_leave", false) or site.get("exhausted", false)
	if dormant:
		color = DORMANT
	var cache: bool = site.get("kind", "") == "cache"
	# Soft grounding is independent of the y-sorted structure.
	canvas.draw_set_transform(at + Vector2(0, 8), 0, Vector2(1, 0.45))
	canvas.draw_circle(Vector2.ZERO, 21.0 if cache else 66.0, Color(0.015, 0.025, 0.065, 0.24))
	canvas.draw_set_transform(Vector2.ZERO)
	if opened:
		return
	# Chests show a ring only while opening; the permanent landmarks are altars.
	if cache and float(site.get("progress",0.0)) <= 0:
		return
	# Preserve the exact gameplay proximity radius; visual size never changes it.
	canvas.draw_circle(at, Field.RADIUS, Color(color, 0.035))
	canvas.draw_arc(at, Field.RADIUS, 0, TAU, 64, Color(color, 0.28 if dormant else 0.48), 1.4, true)
	var duration := maxf(0.01, float(site.get("duration", 1.0)))
	var charge := clampf(float(site.get("progress", 0.0)) / duration, 0.0, 1.0)
	if charge > 0:
		canvas.draw_arc(at, Field.RADIUS, -PI / 2, -PI / 2 + TAU * charge, 64, color, 3.0, true)
		if not reduced and not dormant:
			for index in 3:
				var angle := time * 0.8 + float(index) * TAU / 3
				var spark := at + Vector2(cos(angle), sin(angle)) * Field.RADIUS
				canvas.draw_circle(spark, 1.5 + charge, Color(color, 0.7))
	var cooldown := float(site.get("cooldown", 0.0))
	if cooldown > 0:
		canvas.draw_arc(at, Field.RADIUS - 5.0, -PI / 2, -PI / 2 + TAU * clampf(1.0 - cooldown / 45.0, 0, 1), 64, Color(DORMANT, 0.65), 2.0, true)

static func draw_site_body(canvas: Node2D, site: Dictionary, offset: Vector2, time: float, reduced: bool) -> void:
	var at: Vector2 = site.get("pos", Vector2.ZERO) + offset
	var kind: String = site.get("kind", "cache")
	var opened: bool = site.get("opened", false)
	var dormant: bool = opened or site.get("cooldown", 0.0) > 0.0 or site.get("exhausted", false)
	var tint := Color(0.65, 0.68, 0.78) if dormant else Color.WHITE
	if kind == "cache":
		var size := Vector2(42, 40)
		canvas.draw_texture_rect_region(PROPS, Rect2(at - Vector2(size.x / 2, size.y * 0.86), size), CACHE_RECTS[int(opened)], tint)
		return
	var index := 0 if kind == "shop" else 1
	var size := Vector2(156, 136)
	canvas.draw_texture_rect_region(ALTARS, Rect2(at - Vector2(size.x / 2, 119), size), ALTAR_RECTS[index], tint)
	var bob := 0.0 if reduced or dormant else sin(time * 1.7 + float(index) * 1.2) * 2.5
	var crystal_size := Vector2(32, 55)
	var crystal_at := at + Vector2(0, -136 + bob)
	canvas.draw_texture_rect_region(ALTARS, Rect2(crystal_at - crystal_size / 2, crystal_size), CRYSTAL_RECTS[index], tint)
