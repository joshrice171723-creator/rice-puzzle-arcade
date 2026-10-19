extends RefCounted
## Presentation only. The caller draws grounds first and sorts bodies with actor feet.
const Shapes = preload("res://draw_shapes.gd")
const SHADOW = preload("res://assets/shadow.svg")
const Field = preload("res://field.gd")
const ASPHALT = preload("res://assets/world/asphalt-material.png")
const PAVERS = preload("res://assets/world/paver-material.png")
const SCENERY_ART = preload("res://assets/world/neighborhood-scenery.png")
const DETAILS = preload("res://assets/world/district-details.png")
const Neighborhood = preload("res://neighborhood.gd")
const ALTAR_SIZE := Vector2(348, 304)
const SCENERY_RECTS := [Rect2(4,88,732,678), Rect2(751,7,598,764), Rect2(1365,216,653,547)]
const DETAIL_RECTS := [Rect2(130,10,415,494),Rect2(575,124,670,402),Rect2(196,506,286,470),Rect2(595,567,600,387),Rect2(29,942,680,288),Rect2(720,985,500,245)]
const ALTARS = preload("res://assets/world/altars.png")
const PROPS = preload("res://assets/field-props.png")
const ALTAR_RECTS := [Rect2(30, 350, 725, 630), Rect2(775, 350, 730, 630)]
const CRYSTAL_RECTS := [Rect2(308, 20, 190, 325), Rect2(1048, 25, 190, 320)]
const CACHE_RECTS := [Rect2(915, 45, 390, 400), Rect2(1350, 0, 420, 455)]
const AMBER := Color("ffca75")
const VIOLET := Color("c99aff")
const DORMANT := Color("7e88a5")
const MATERIAL_SPAN := 600.0
const SIDEWALKS := [
	[Vector2(320,0),Vector2(2080,0),Vector2(1232,848),Vector2(1168,848)],
	[Vector2(0,320),Vector2(848,1168),Vector2(848,1232),Vector2(0,2080)],
	[Vector2(2400,320),Vector2(2400,2080),Vector2(1552,1232),Vector2(1552,1168)],
	[Vector2(1168,1552),Vector2(1232,1552),Vector2(2080,2400),Vector2(320,2400)]
]
static var ground_patches: Array[Dictionary] = []

static func prepare_ground() -> void:
	if not ground_patches.is_empty():
		return
	# Exact mirrored edges make material joins continuous without upscaling a map.
	for material in 2:
		for y in 4:
			for x in 4:
				var tile := Rect2(Vector2(x,y)*MATERIAL_SPAN,Vector2.ONE*MATERIAL_SPAN)
				var corners := PackedVector2Array([tile.position,tile.position+Vector2(tile.size.x,0),tile.end,tile.position+Vector2(0,tile.size.y)])
				var polygons: Array[PackedVector2Array] = [corners]
				if material == 1:
					polygons.clear()
					for sidewalk in SIDEWALKS:
						polygons.append_array(Geometry2D.intersect_polygons(corners,PackedVector2Array(sidewalk)))
				for polygon in polygons:
					var uv := PackedVector2Array()
					for point in polygon:
						var local := (point-tile.position)/MATERIAL_SPAN
						var sample_uv := Vector2(1-local.x if x%2 else local.x,1-local.y if y%2 else local.y)
						# Cut through brick interiors rather than doubling the atlas edge grout.
						uv.append(sample_uv*0.964+Vector2.ONE*0.018 if material==1 else sample_uv)
					ground_patches.append({"points":polygon,"uv":uv,"material":material})

static func draw_floor(canvas: Node2D, offset: Vector2) -> void:
	prepare_ground()
	for patch in ground_patches:
		canvas.draw_set_transform(offset)
		canvas.draw_polygon(patch.points,PackedColorArray([Color.WHITE]),patch.uv,ASPHALT if patch.material==0 else PAVERS)
	canvas.draw_set_transform(Vector2.ZERO)
	for sidewalk in SIDEWALKS:
		var edge := PackedVector2Array()
		for point: Vector2 in sidewalk:
			edge.append(point+offset)
		edge.append(sidewalk[0]+offset)
		canvas.draw_polyline(edge,Color("263445"),10,true)
		canvas.draw_polyline(edge,Color("8893aa"),6,true)
		canvas.draw_polyline(edge,Color("bac0d0"),1.5,true)
	var paint := PackedVector2Array()
	for diagonal in [-1,1]:
		for distance in [-1120,-1000,-880,-760,-640,-520,520,640,760,880,1000,1120]:
			var at := Vector2(1200,1200)+Vector2(distance,distance*diagonal)+offset
			var direction := Vector2(1,diagonal).normalized()
			paint.append(at-direction*14)
			paint.append(at+direction*14)
	canvas.draw_multiline(paint,Color(0.88,0.86,0.79,0.35),4,true)
	for point: Vector2 in Neighborhood.GROUNDCOVER:
		canvas.draw_texture_rect_region(DETAILS,Rect2(point+offset-Vector2(64,32),Vector2(128,64)),DETAIL_RECTS[5],Color(0.88,0.92,1,0.9))

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
	var shadow_size := Vector2(42,19) if cache else Vector2(358,164)
	canvas.draw_texture_rect(SHADOW,Rect2(at+Vector2(0,8)-shadow_size*0.5,shadow_size),false)
	if not cache:
		var foundation := PackedVector2Array([at+Vector2(0,-75),at+Vector2(174,0),at+Vector2(0,82),at+Vector2(-174,0)])
		canvas.draw_colored_polygon(foundation,Color(0.17,0.19,0.24,0.8))
	if opened:
		return
	# Chests show a ring only while opening; the permanent landmarks are altars.
	if cache and float(site.get("progress",0.0)) <= 0:
		return
	# Match the simulation-supplied interaction geometry exactly.
	at += site.get("interaction_offset", Vector2.ZERO)
	var radius := float(site.get("radius", Field.RADIUS))
	Shapes.circle(canvas,at,radius,Color(color,0.035))
	Shapes.ring(canvas,at,radius,1.4,Color(color,0.28 if dormant else 0.48))
	var duration := maxf(0.01, float(site.get("duration", 1.0)))
	var charge := clampf(float(site.get("progress", 0.0)) / duration, 0.0, 1.0)
	if charge > 0:
		canvas.draw_arc(at, radius, -PI / 2, -PI / 2 + TAU * charge, 64, color, 3.0, true)
		if not reduced and not dormant:
			for index in 3:
				var angle := time * 0.8 + float(index) * TAU / 3
				var spark := at + Vector2(cos(angle), sin(angle)) * radius
				canvas.draw_circle(spark, 1.5 + charge, Color(color, 0.7))
	var cooldown := float(site.get("cooldown", 0.0))
	if cooldown > 0:
		canvas.draw_arc(at, radius - 5.0, -PI / 2, -PI / 2 + TAU * clampf(1.0 - cooldown / 45.0, 0, 1), 64, Color(DORMANT, 0.65), 2.0, true)

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
	var size := ALTAR_SIZE
	canvas.draw_texture_rect_region(ALTARS, Rect2(at - Vector2(size.x / 2, 229), size), ALTAR_RECTS[index], tint)
	var bob := 0.0 if reduced or dormant else sin(time * 1.7 + float(index) * 1.2) * 2.5
	var crystal_size := Vector2(68, 116)
	var crystal_at := at + Vector2(0, -265 + bob)
	canvas.draw_texture_rect_region(ALTARS, Rect2(crystal_at - crystal_size / 2, crystal_size), CRYSTAL_RECTS[index], tint)

static func site_sort_y(site: Dictionary) -> float:
	return float(site.pos.y) + (0.0 if site.get("kind", "") == "cache" else 75.0)

static func draw_scenery_ground(canvas: Node2D, entry: Dictionary, offset: Vector2) -> void:
	var solid: Rect2 = entry.footprint
	canvas.draw_texture_rect(SHADOW, Rect2(solid.position + offset - Vector2(12,8), solid.size + Vector2(24,16)), false, Color(1,1,1,0.7))
	if entry.kind in ["streetlamp","fence"]:
		var at: Vector2 = entry.pos+offset
		Shapes.circle(canvas,at,65,Color(1,0.64,0.24,0.035))
		Shapes.circle(canvas,at,42,Color(1,0.72,0.35,0.055))

static func draw_scenery_body(canvas: Node2D, entry: Dictionary, offset: Vector2) -> void:
	var size: Vector2 = entry.draw_size
	var at: Vector2 = entry.pos + offset
	if entry.has("detail_index"):
		canvas.draw_texture_rect_region(DETAILS,Rect2(at-Vector2(size.x/2,size.y-25),size),DETAIL_RECTS[int(entry.detail_index)])
	else:
		canvas.draw_texture_rect_region(SCENERY_ART, Rect2(at-Vector2(size.x/2,size.y-40),size), SCENERY_RECTS[int(entry.atlas_index)])
