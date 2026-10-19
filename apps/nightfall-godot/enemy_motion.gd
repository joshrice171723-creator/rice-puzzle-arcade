extends RefCounted
## Distance-driven planted strides, committed attacks and staggered crumple dissolve.
const ART = preload("res://assets/mission-one/enemies.png")
const EXPANSION = preload("res://assets/enemy-expansion/bulwark-hexer.png")
const EXPANSION_REGIONS := {"bulwark":Rect2(20,60,930,800), "hexer":Rect2(1070,0,690,880)}
const BOSSES = preload("res://boss_art.gd")
const REGIONS := {"drifter":Rect2(15,223,617,566), "runner":Rect2(674,245,563,517), "spitter":Rect2(1245,246,519,516)}
const COLS := 6
const ROWS := 8
static var topology := PackedInt32Array()
static var uv_cache: Dictionary = {}

static var anchors := PackedVector2Array()
static var legs := PackedFloat32Array()
static var upper := PackedFloat32Array()
static var arms := PackedFloat32Array()
static var sides := PackedFloat32Array()
static var step_cos := PackedFloat32Array()
static var step_sin := PackedFloat32Array()
static var index_cache: Dictionary = {}
const GAITS := {
	"drifter": Vector3(0.82, 0.075, 0.055), "runner": Vector3(1.62, 0.13, 0.10),
	"spitter": Vector3(0.70, 0.055, 0.04), "bulwark": Vector3(0.52, 0.065, 0.035),
	"hexer": Vector3(0.90, 0.045, 0.025)}
const HEIGHTS := {"runner":46.0, "bulwark":66.0, "hexer":62.0}

static func prepare_weights() -> void:
	if not anchors.is_empty():
		return
	for row in ROWS+1:
		for col in COLS+1:
			var uv := Vector2(float(col)/COLS,float(row)/ROWS)
			anchors.append(Vector2(uv.x-0.5,uv.y-0.98))
			legs.append(smoothstep(0.60,0.88,uv.y))
			upper.append(1-smoothstep(0.62,0.91,uv.y))
			arms.append(smoothstep(0.15,0.38,absf(uv.x-0.5))*smoothstep(0.22,0.40,uv.y)*(1-smoothstep(0.70,0.82,uv.y)))
			var side := smoothstep(0.40,0.60,uv.x)*2-1
			sides.append(side)
			step_cos.append(cos(side*PI*0.5))
			step_sin.append(sin(side*PI*0.5))

static func geometry(enemy: Dictionary, size: Vector2, position: Vector2, clock: float, windup: float, strike: float, death: float) -> PackedVector2Array:
	prepare_weights()
	var kind: String = enemy.get("kind", "drifter")
	var gait: Vector3 = GAITS.get(kind, Vector3(0.64, 0.07, 0.045))
	var stride: float = float(enemy.get("motion",0.0)) * gait.x
	var sine := sin(stride)
	var cosine := cos(stride)
	var moving: bool = enemy.get("moving",false) and death <= 0
	var rush: bool = enemy.get("rush_left",0.0) > 0 and death < 0.25
	var attack: String = enemy.get("attack","")
	# A fast release and long recoil reads differently from the gradual windup.
	var follow := sin(pow(clampf(strike,0,1), 0.55)*PI)
	var anticipate := windup * windup
	var upper_offset := Vector2.ZERO
	var arm_offset := Vector2.ZERO
	var slam_side := 0.0
	if attack in ["slam", "cleave"]:
		arm_offset.y = -anticipate*size.y*0.27 + follow*size.y*0.16
		upper_offset = Vector2(-anticipate*size.x*0.10 + follow*size.x*0.20, follow*size.y*0.17-anticipate*size.y*0.07)
		slam_side = (anticipate-follow)*size.x*0.15
	elif attack in ["swipe","pounce","rush"]:
		upper_offset = Vector2(-anticipate*size.x*0.15+follow*size.x*0.23+(size.x*0.16 if rush else 0.0),(anticipate+(0.9 if rush else 0.0))*size.y*0.09)
		arm_offset.x = (follow-anticipate)*size.x*0.22
		arm_offset.y = -anticipate*size.y*0.07 + follow*size.y*0.04
	elif attack in ["spit", "toss"]:
		upper_offset = Vector2(-anticipate*size.x*0.12+follow*size.x*0.16,-anticipate*size.y*0.07+follow*size.y*0.035)
		arm_offset = Vector2((follow-anticipate)*size.x*0.12,-anticipate*size.y*0.12)
	elif attack in ["hex", "summon", "bolt", "hex_bolt"]:
		upper_offset.y = -anticipate*size.y*0.08 + follow*size.y*0.07
		arm_offset.y = -anticipate*size.y*0.24 + follow*size.y*0.12
		slam_side = (anticipate-follow)*size.x*0.20
	else:
		arm_offset.y = -windup*size.y*0.08
		upper_offset.x = (follow-windup)*size.x*0.06
	if death == 0:
		upper_offset.y -= sin(clock*2.4+enemy.get("id",0))*0.5
	if moving:
		upper_offset.x += cosine * size.x * (0.035 if kind != "runner" else 0.055)
		upper_offset.y += absf(sine) * size.y * (0.035 if kind != "bulwark" else 0.055)
		if kind == "runner":
			upper_offset += Vector2(size.x*0.10,size.y*0.045)
		elif kind == "hexer":
			upper_offset.y -= (0.5+0.5*sine)*size.y*0.065
	var face: float = enemy.get("face",1.0)
	var fall := smoothstep(0.05,0.84,death)
	var fold := smoothstep(0.0,0.43,death)
	var scatter := smoothstep(0.62,1.0,death)
	var fall_side := -1.0 if int(enemy.get("id",0)) % 2 else 1.0
	var death_transform := Transform2D(fall*fall_side*(1.12 if kind != "bulwark" else 0.72),Vector2.ZERO)
	var vertices := PackedVector2Array()
	vertices.resize(anchors.size())
	for n in anchors.size():
		var point: Vector2 = anchors[n]*size
		if moving:
			var step := sine*step_cos[n]+cosine*step_sin[n]
			var swing := maxf(0,step)
			# Negative half-cycle is the planted stance; only the swing foot lifts.
			point.x += legs[n]*step*size.x*gait.y
			point.y -= swing*swing*legs[n]*size.y*gait.z
			point.x -= upper[n]*step*size.x*0.015
		point += upper_offset*upper[n]+arm_offset*arms[n]
		point.x += slam_side*arms[n]*sides[n]
		if death > 0:
			# Knees buckle first, then the torso tips about the feet, then shards separate.
			point.y += upper[n]*fold*size.y*0.20
			point.x += sides[n]*legs[n]*fold*size.x*0.07
			point = death_transform*point
			point.y *= 1.0-fall*0.46
			point.y = minf(point.y, size.y*0.08)
			point += Vector2(sides[n]*size.x*0.12,-upper[n]*size.y*0.10)*scatter
		point.x *= face
		vertices[n] = position+point
	return vertices

static func body_height(enemy: Dictionary, mission: int) -> float:
	if enemy.get("boss",false):
		return BOSSES.SIZES[clampi(mission-1,0,4)].y
	return HEIGHTS.get(enemy.get("kind",""),52.0)

static func draw(canvas: Node2D, enemy: Dictionary, mission: int, offset: Vector2, clock: float, reduced: bool, death: float = 0.0, defer_draw: bool = false) -> void:
	var boss: bool = enemy.get("boss", false)
	var expanded: bool = not boss and enemy.kind in EXPANSION_REGIONS
	var texture: Texture2D = BOSSES.ART if boss else (EXPANSION if expanded else ART)
	var source: Rect2 = BOSSES.REGIONS[0][clampi(mission - 1, 0, 4)] if boss else (EXPANSION_REGIONS[enemy.kind] if expanded else REGIONS.get(enemy.kind, REGIONS.drifter))
	var height := body_height(enemy,mission)
	var size := Vector2(source.size.x / source.size.y * height, height)
	var flash := clampf(float(enemy.get("hit_flash", 0.0)) / 0.12, 0, 1)
	var settle := 1.0-smoothstep(0.0,0.4,death) if death > 0 else 1.0
	var recoil: Vector2 = enemy.get("hit_push", Vector2.ZERO) * flash if not reduced else Vector2.ZERO
	var position: Vector2 = enemy.pos + offset + recoil
	var windup := 1.0 - float(enemy.get("tell", 0.0)) / maxf(0.01, float(enemy.get("windup", 1.0))) if enemy.get("tell", 0.0) > 0 else 0.0
	var strike := 1.0 - float(enemy.get("attack_anim", 0.0)) / 0.32 if enemy.get("attack_anim", 0.0) > 0 else 0.0
	var vertices := geometry(enemy,size,position,clock,windup*settle,strike*settle,death)
	var key := str(source) + str(texture.get_instance_id())
	if not uv_cache.has(key):
		var uv := PackedVector2Array()
		var texture_size := Vector2(texture.get_width(), texture.get_height())
		for row in ROWS + 1:
			for col in COLS + 1:
				uv.append((source.position + Vector2(float(col) / COLS, float(row) / ROWS) * source.size) / texture_size)
		uv_cache[key] = uv
	if topology.is_empty():
		for row in ROWS:
			for col in COLS:
				var a := row * (COLS + 1) + col
				topology.append_array(PackedInt32Array([a,a+1,a+COLS+1,a+1,a+COLS+2,a+COLS+1]))
	var tint := Color.WHITE.lerp(Color(1.7,1.7,1.8), 0 if reduced else flash)
	if enemy.get("chill", 0.0) > 0:
		tint = tint.lerp(Color(0.58,0.78,1.0), 0.32)
	tint.a = 1.0 - smoothstep(0.38, 1.0, death)
	var batch: Dictionary = canvas.get_meta("enemy_batch", {})
	if not batch.is_empty() and batch.texture != texture:
		flush(canvas)
		batch = {}
	if batch.is_empty():
		batch = {"texture":texture,"vertices":PackedVector2Array(),"uv":PackedVector2Array(),"colors":PackedColorArray(),"indices":PackedInt32Array()}
	var first: int = batch.vertices.size()
	batch.vertices.append_array(vertices)
	batch.uv.append_array(uv_cache[key])
	var colors := PackedColorArray()
	colors.resize(vertices.size())
	if death <= 0:
		colors.fill(tint)
	else:
		for n in vertices.size():
			var shard := tint
			# Deterministic rows dissolve at staggered times, leaving grounded fragments last.
			var dissolve := smoothstep(0.36 + legs[n]*0.24, 0.88 + legs[n]*0.12, death)
			shard.a *= 1.0 - dissolve
			shard = shard.lerp(Color(0.35,0.29,0.43,shard.a),smoothstep(0.05,0.5,death)*0.65)
			colors[n] = shard
	batch.colors.append_array(colors)
	if not index_cache.has(first):
		var indices := PackedInt32Array()
		indices.resize(topology.size())
		for n in topology.size():
			indices[n] = first+topology[n]
		index_cache[first] = indices
	batch.indices.append_array(index_cache[first])
	canvas.set_meta("enemy_batch",batch)
	if not defer_draw:
		flush(canvas)

static func flush(canvas: Node2D) -> void:
	var batch: Dictionary = canvas.get_meta("enemy_batch", {})
	if batch.is_empty():
		return
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = batch.vertices
	arrays[Mesh.ARRAY_TEX_UV] = batch.uv
	arrays[Mesh.ARRAY_COLOR] = batch.colors
	arrays[Mesh.ARRAY_INDEX] = batch.indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var meshes: Array = canvas.get_meta("actor_meshes", [])
	meshes.append(mesh)
	canvas.set_meta("actor_meshes", meshes)
	canvas.draw_mesh(mesh,batch.texture)
	canvas.set_meta("enemy_batch",{})
