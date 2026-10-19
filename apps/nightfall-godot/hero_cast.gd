extends RefCounted
## One persistent textured mesh per character, weighted around feet, hips and arms.
## Animation changes vertices continuously rather than switching generated poses.
const SCAVENGER = preload("res://assets/hero-cast/scavenger-casting.png")
const ENGINEER = preload("res://assets/engineer.png")
const CLASSES = preload("res://assets/class-previews.png")
const COLS := 12
const ROWS := 18

static var weights: Array[PackedFloat32Array] = []
static var anchors := PackedVector2Array()
static var topology := PackedInt32Array()
static var uv_cache: Dictionary = {}

static func vertex_weights(uv: Vector2) -> PackedFloat32Array:
	var side := smoothstep(0.40,0.58,uv.x)*2-1
	return PackedFloat32Array([
		smoothstep(0.62,0.88,uv.y), side, cos(side*PI/2), sin(side*PI/2),
		1-smoothstep(0.62,0.92,uv.y),
		(1-smoothstep(0.25,0.39,uv.x)+smoothstep(0.67,0.84,uv.x))*smoothstep(0.24,0.36,uv.y)*(1-smoothstep(0.59,0.72,uv.y)),
		smoothstep(0.59,0.83,uv.x)*smoothstep(0.23,0.38,uv.y)*(1-smoothstep(0.65,0.77,uv.y)),
		(1-smoothstep(0.16,0.40,uv.x))*smoothstep(0.39,0.50,uv.y)*(1-smoothstep(0.64,0.76,uv.y)),
		cos(uv.y*6), sin(uv.y*6)])

static func prepare_weights() -> void:
	if not anchors.is_empty():
		return
	for row in ROWS+1:
		for col in COLS+1:
			var uv := Vector2(float(col)/COLS,float(row)/ROWS)
			anchors.append(Vector2(uv.x-0.46,uv.y-0.99))
			weights.append(vertex_weights(uv))
	for row in ROWS:
		for col in COLS:
			var a := row*(COLS+1)+col
			topology.append_array(PackedInt32Array([a,a+1,a+COLS+1,a+1,a+COLS+2,a+COLS+1]))

static func geometry(size: Vector2, clock: float, stride: float, move_blend: float, cast_age: float, dodge: float, action: String = "", points: PackedVector2Array = PackedVector2Array()) -> PackedVector2Array:
	prepare_weights()
	var vertex_anchors := anchors
	var vertex_weights_array := weights
	if not points.is_empty():
		vertex_anchors = PackedVector2Array()
		vertex_weights_array = []
		for uv in points:
			vertex_anchors.append(Vector2(uv.x-0.46,uv.y-0.99))
			vertex_weights_array.append(vertex_weights(uv))
	var sine := sin(stride)
	var cosine := cos(stride)
	var breathing := sin(clock*2.8)*0.45+absf(cosine)*1.1*move_blend
	var cloth_sine := sin(clock*7)
	var cloth_cosine := cos(clock*7)
	var cast := 0.0
	if cast_age >= -0.18 and cast_age < 0.30:
		cast = smoothstep(-0.18,0.0,cast_age)*(1-smoothstep(0.04,0.30,cast_age))
	var rotation := -0.48*cast
	var recoil := 0.0
	if action in ["pistol","scattergun","crossbow"]:
		recoil = (4.5 if action=="scattergun" else (2.8 if action=="crossbow" else 1.8))*cast
		rotation = -0.10*cast
	elif action == "sabre" and cast_age >= 0 and cast_age < 0.30:
		rotation = lerpf(-0.65,0.70,smoothstep(0.0,0.16,cast_age))*(1-smoothstep(0.16,0.30,cast_age))
	var shoulder := Vector2(size.x*0.12,-size.y*0.62)
	var turn := Transform2D(rotation,Vector2.ZERO)
	var vertices := PackedVector2Array()
	vertices.resize(vertex_anchors.size())
	for n in vertex_anchors.size():
		var w: PackedFloat32Array = vertex_weights_array[n]
		var point: Vector2 = vertex_anchors[n]*size
		var step := sine*w[2]+cosine*w[3]
		point.x += step*4.5*w[0]*move_blend+sine*1.4*w[4]*move_blend-sine*w[5]*move_blend*2.0-w[4]*recoil
		point.y += -maxf(0,step)*4.0*w[0]*move_blend-breathing*w[4]+cosine*w[5]*w[1]*move_blend*1.6
		point = point.lerp(shoulder+turn*(point-shoulder),w[6])
		point += Vector2(cast*1.3+dodge*6,dodge*3)*w[4]
		point.x += (cloth_sine*w[8]+cloth_cosine*w[9])*w[7]*(0.5+move_blend*1.8)
		vertices[n] = point
	return vertices

static func deform_point(uv: Vector2, size: Vector2, clock: float, stride: float, move_blend: float, cast_age: float, dodge: float, action: String = "") -> Vector2:
	return geometry(size,clock,stride,move_blend,cast_age,dodge,action,PackedVector2Array([uv]))[0]

static func draw_motion(canvas: Node2D, pos: Vector2, offset: Vector2, face: float, clock: float, stride: float, move_blend: float, cast_age: float, dodge: float, engineer: bool, reduced: bool, class_id: String = "scavenger", hurt: float = 0.0, action: String = "") -> void:
	var texture: Texture2D = ENGINEER if engineer else SCAVENGER
	var source := Rect2(15,70,510,580) if engineer else Rect2(1640,110,403,562)
	if class_id in ["warden", "arcanist"]:
		texture = CLASSES
		source = Rect2(25,0,780,880) if class_id == "warden" else Rect2(1000,0,750,880)
	var size := Vector2(source.size.x/source.size.y*80,80)
	var vertices := geometry(size,clock,stride,move_blend,cast_age,dodge,action)
	var key := str(source)
	if not uv_cache.has(key):
		var uvs := PackedVector2Array()
		var texture_size := Vector2(texture.get_width(),texture.get_height())
		for row in ROWS+1:
			for col in COLS+1:
				var uv := Vector2(float(col)/COLS,float(row)/ROWS)
				uvs.append((source.position+uv*source.size)/texture_size)
		uv_cache[key] = uvs
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv_cache[key]
	arrays[Mesh.ARRAY_INDEX] = topology
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	canvas.set_meta("hero_mesh",mesh)
	var transform := Transform2D(Vector2(face,0),Vector2(0,1),pos+offset+Vector2(0,5.6))
	if dodge > 0 and not reduced:
		var trail := transform
		trail.origin.x -= face*14*dodge
		canvas.draw_mesh(mesh,texture,trail,Color(0.62,0.77,1,dodge*0.18))
	canvas.draw_mesh(mesh,texture,transform,Color.WHITE.lerp(Color(1.7,1.35,1.25),hurt if not reduced else 0.0))

static func pose(run: RefCounted) -> Dictionary:
	# A spell gesture wins over a simultaneous basic shot, without changing its damage.
	var basic := {}
	for index in range(run.vfx_events.size() - 1, -1, -1):
		var event: Dictionary = run.vfx_events[index]
		if event.life <= 0:
			continue
		if event.kind in ["spell_cast", "class_cast", "ember_cast"]:
			return {"age":event.duration-event.life,"direction":event.direction,"spell":event.get("spell","ember" if event.kind=="ember_cast" else "")}
		if event.kind == "weapon_cast" and basic.is_empty():
			basic = {"age":event.duration-event.life,"direction":event.direction,"spell":"","weapon":event.get("weapon","pistol")}
	var charging := anticipation(run)
	return charging if not charging.is_empty() else basic

static func anticipation(run: RefCounted) -> Dictionary:
	var best := {}
	var soonest := 0.18
	for id: String in run.spells:
		if id == "wisp":
			continue
		var wait: float = run.spells[id].get("wait",1.0)
		if wait <= 0 or wait > soonest:
			continue
		var target: Dictionary = run.nearest_enemy(run.player,run.spell_mod(id,"radius",150) if id=="frost" else 425)
		if target.is_empty():
			continue
		soonest = wait
		best = {"age":-wait,"direction":run.player.direction_to(target.pos),"spell":id}
	return best
