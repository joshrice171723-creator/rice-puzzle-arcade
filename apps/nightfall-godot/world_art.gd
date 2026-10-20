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
const World = preload("res://world_geometry.gd")
const PERIMETER = preload("res://assets/world/perimeter.png")
const PERIMETER_RECTS := [Rect2(24,150,600,330),Rect2(640,150,590,335),Rect2(180,495,285,540),Rect2(800,495,285,540)]
const ALTAR_SIZE := Vector2(348, 304)
const SCENERY_RECTS := [Rect2(4,88,732,678), Rect2(751,7,598,764), Rect2(1365,216,653,547)]
const DETAIL_RECTS := [Rect2(130,10,415,494),Rect2(575,124,670,402),Rect2(196,506,286,470),Rect2(595,567,600,387),Rect2(29,942,680,288),Rect2(720,985,500,245)]
const ALTARS = preload("res://assets/world/altars.png")
const PROPS = preload("res://assets/field-props.png")
const ALTAR_RECTS := [Rect2(30, 350, 725, 630), Rect2(775, 350, 730, 630)]
const CRYSTAL_RECTS := [Rect2(308, 20, 190, 325), Rect2(1048, 25, 190, 320)]
const CACHE_RECTS := [Rect2(929,121,358,316), Rect2(1368,43,387,393)]
const AMBER := Color("ffca75")
const VIOLET := Color("c99aff")
const DORMANT := Color("7e88a5")
const MATERIAL_SPAN := 600.0
const SIDEWALKS := [
	[Vector2(320,0),Vector2(5680,0),Vector2(3032,2648),Vector2(2968,2648)],
	[Vector2(0,320),Vector2(2648,2968),Vector2(2648,3032),Vector2(0,5680)],
	[Vector2(6000,320),Vector2(6000,5680),Vector2(3352,3032),Vector2(3352,2968)],
	[Vector2(2968,3352),Vector2(3032,3352),Vector2(5680,6000),Vector2(320,6000)]
]
static var ground_cells: Dictionary = {}
static var ground_batches: Dictionary = {}
static var curb_mesh: ArrayMesh

static func batch_ground(region: Rect2i) -> Array:
	if ground_batches.has(region):
		return ground_batches[region]
	var batches: Array = []
	for material in 2:
		var vertices := PackedVector2Array()
		var uvs := PackedVector2Array()
		var indices := PackedInt32Array()
		for y in range(region.position.y,region.end.y):
			for x in range(region.position.x,region.end.x):
				for patch in ground_cell(Vector2i(x,y)):
					if patch.material != material:
						continue
					var start := vertices.size()
					for index in Geometry2D.triangulate_polygon(patch.points):
						indices.append(start+index)
					vertices.append_array(patch.points)
					uvs.append_array(patch.uv)
		if vertices.is_empty():
			batches.append(null)
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_TEX_UV] = uvs
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		batches.append(mesh)
	if ground_batches.size() >= 64:
		ground_batches.erase(ground_batches.keys()[0])
	ground_batches[region] = batches
	return batches

static func curbs() -> ArrayMesh:
	if curb_mesh != null:
		return curb_mesh
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	for band in [{"width":10.0,"color":Color("263445")},{"width":6.0,"color":Color("8893aa")},{"width":1.5,"color":Color("bac0d0")}]:
		for sidewalk in SIDEWALKS:
			for n in sidewalk.size():
				var a: Vector2 = sidewalk[n]
				var b: Vector2 = sidewalk[(n+1)%sidewalk.size()]
				var side := (b-a).normalized().orthogonal()*float(band.width)*0.5
				vertices.append_array(PackedVector2Array([a-side,b-side,a+side,a+side,b-side,b+side]))
				for point in 6:
					colors.append(band.color)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	curb_mesh = ArrayMesh.new()
	curb_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return curb_mesh

static func ground_cell(cell: Vector2i) -> Array:
	if ground_cells.has(cell):
		return ground_cells[cell]
	var patches: Array[Dictionary] = []
	# Exact mirrored edges make material joins continuous without upscaling a map.
	for material in 2:
		for y in [cell.y]:
			for x in [cell.x]:
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
					patches.append({"points":polygon,"uv":uv,"material":material})
	ground_cells[cell] = patches
	return patches

static func draw_floor(canvas: Node2D, offset: Vector2, view: Rect2 = Rect2(0,0,430,760)) -> void:
	var visible := Rect2(view.position-offset,view.size).grow(24)
	var first := Vector2i(clampi(floori(visible.position.x/MATERIAL_SPAN),0,9),clampi(floori(visible.position.y/MATERIAL_SPAN),0,9))
	var last := Vector2i(clampi(floori(visible.end.x/MATERIAL_SPAN),0,9),clampi(floori(visible.end.y/MATERIAL_SPAN),0,9))
	var batches := batch_ground(Rect2i(first,last-first+Vector2i.ONE))
	var transform := Transform2D(0,offset)
	var calls := 0
	for material in 2:
		if batches[material] != null:
			canvas.draw_mesh(batches[material],ASPHALT if material==0 else PAVERS,transform)
			calls += 1
	canvas.draw_mesh(curbs(),null,transform)
	canvas.set_meta("ground_visible_patches",(last.x-first.x+1)*(last.y-first.y+1))
	canvas.set_meta("ground_material_draws",calls)
	var paint := PackedVector2Array()
	for diagonal in [-1,1]:
		for distance in range(-2760,2761,120):
			if absi(distance)<520:
				continue
			var world_at := World.CENTER+Vector2(distance,distance*diagonal)
			if not visible.has_point(world_at):
				continue
			var at := world_at+offset
			var direction := Vector2(1,diagonal).normalized()
			paint.append(at-direction*14)
			paint.append(at+direction*14)
	if not paint.is_empty():
		canvas.draw_multiline(paint,Color(0.88,0.86,0.79,0.35),4,true)
	for point: Vector2 in Neighborhood.groundcover():
		if not visible.grow(80).has_point(point):
			continue
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
	var shadow_size := Vector2(32,10) if cache else Vector2(268,78)
	var contact := at+Vector2(0,-4 if cache else 35)
	canvas.draw_texture_rect(SHADOW,Rect2(contact-shadow_size*0.5,shadow_size),false,Color(1,1,1,0.4))
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
		var size := Vector2(42, 37) if not opened else Vector2(42,43)
		canvas.draw_texture_rect_region(PROPS, Rect2(at - Vector2(size.x / 2, size.y), size), CACHE_RECTS[int(opened)], tint)
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

static func draw_scenery_ground(canvas: Node2D, entry: Dictionary, offset: Vector2, view: Rect2 = Rect2(0,0,430,760)) -> void:
	var solid: Rect2 = entry.footprint
	if not Rect2(solid.position+offset,solid.size).intersects(view.grow(96)):
		return
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

static func draw_boundary(canvas: Node2D, offset: Vector2, front: bool, view: Rect2 = Rect2(0,0,430,760)) -> void:
	var visible := Rect2(view.position-offset,view.size).grow(240)
	var bounds := World.BOUNDS
	var horizontal_y := bounds.end.y if front else bounds.position.y
	var vertical_x := bounds.end.x if front else bounds.position.x
	var drawn := 0
	# Derive only visible segment indices; never scan the full perimeter per frame.
	if horizontal_y >= visible.position.y and horizontal_y <= visible.end.y:
		var step := bounds.size.x/27.0
		var first := clampi(floori((visible.position.x-bounds.position.x)/step),0,26)
		var last := clampi(floori((visible.end.x-bounds.position.x)/step),0,26)
		for index in range(first,last+1):
			var at := Vector2(bounds.position.x+(index+0.5)*step,horizontal_y)+offset
			var source: Rect2 = PERIMETER_RECTS[1 if index==13 else 0]
			canvas.draw_texture_rect_region(PERIMETER,Rect2(at-Vector2(step*0.56,114),Vector2(step*1.12,126)),source)
			drawn += 1
	if vertical_x >= visible.position.x and vertical_x <= visible.end.x:
		var step := bounds.size.y/31.0
		var first := clampi(floori((visible.position.y-bounds.position.y)/step),0,30)
		var last := clampi(floori((visible.end.y-bounds.position.y)/step),0,30)
		for index in range(first,last+1):
			var at := Vector2(vertical_x,bounds.position.y+(index+0.5)*step)+offset
			canvas.draw_texture_rect_region(PERIMETER,Rect2(at-Vector2(50,115),Vector2(100,230)),PERIMETER_RECTS[3 if front else 2])
			drawn += 1
	canvas.set_meta("boundary_front_segments" if front else "boundary_back_segments",drawn)
