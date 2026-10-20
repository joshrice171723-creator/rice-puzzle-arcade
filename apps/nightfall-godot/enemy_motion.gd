extends RefCounted
## Distance-driven planted strides, committed attacks and staggered crumple dissolve.
const ART = preload("res://assets/mission-one/enemies.png")
const EXPANSION = preload("res://assets/enemy-expansion/bulwark-hexer.png")
const EXPANSION_REGIONS := {"bulwark":Rect2(20,60,930,800), "hexer":Rect2(1070,0,690,880)}
const BOSSES = preload("res://boss_art.gd")
const Gait = preload("res://jointed_gait.gd")
const DynamicMesh = preload("res://dynamic_rig_mesh.gd")
const LayeredRig = preload("res://layered_actor_rig.gd")
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
static var index_cache: Dictionary = {}
static var leg_blends := PackedFloat32Array()
static var knee_blends := PackedFloat32Array()
static var foot_sides := PackedFloat32Array()
static var boot_blends := PackedFloat32Array()
const HEIGHTS := {"runner":46.0, "bulwark":66.0, "hexer":62.0}

static func prepare_weights() -> void:
	if not anchors.is_empty():
		return
	for row in ROWS+1:
		for col in COLS+1:
			var uv := Vector2(float(col)/COLS,float(row)/ROWS)
			anchors.append(Vector2(uv.x-0.5,uv.y-0.98))
			leg_blends.append(smoothstep(0.63,0.73,uv.y)*(1.0-smoothstep(0.36,0.49,absf(uv.x-0.5))))
			knee_blends.append(smoothstep(0.77,0.83,uv.y))
			foot_sides.append(smoothstep(0.43,0.57,uv.x))
			boot_blends.append(smoothstep(0.80,0.88,uv.y))
			legs.append(smoothstep(0.60,0.88,uv.y))
			upper.append(1-smoothstep(0.62,0.91,uv.y))
			arms.append(smoothstep(0.15,0.38,absf(uv.x-0.5))*smoothstep(0.22,0.40,uv.y)*(1-smoothstep(0.70,0.82,uv.y)))
			var side := smoothstep(0.40,0.60,uv.x)*2-1
			sides.append(side)

static func geometry(enemy: Dictionary, size: Vector2, position: Vector2, clock: float, windup: float, strike: float, death: float) -> PackedVector2Array:
	prepare_weights()
	var kind: String = enemy.get("kind", "drifter")
	var cycle_distance := size.y*(0.60 if kind=="runner" else (0.48 if kind=="bulwark" else 0.46))
	var stride: float = float(enemy.get("motion",0.0)) * TAU/maxf(1.0,cycle_distance*0.16)
	var sine := sin(stride)
	var moving: bool = (enemy.get("moving",false) or enemy.get("motion_blend",0.0)>0) and death <= 0
	var move_blend: float = clampf(enemy.get("motion_blend",1.0 if moving else 0.0),0,1) if moving else 0.0
	var face: float = enemy.get("face",1.0)
	var velocity: Vector2 = enemy.get("motion_direction",enemy.get("velocity",Vector2(face,0)))
	var travel := velocity.normalized() if velocity.length_squared()>0.001 else Vector2(face,0)
	travel = Vector2(travel.x*face,travel.y*0.28)
	var pelvis := Gait.torso(stride,move_blend,size.y)+Vector2(0,size.y*0.04*move_blend)
	var left_leg := Gait.leg_bones(Vector2(-0.16,-0.36)*size,Vector2(-0.28,-0.19)*size,Vector2(-0.24,-0.02)*size,pelvis,Gait.foot(stride,travel,cycle_distance*0.55,size.y*0.055)*move_blend)
	var right_leg := Gait.leg_bones(Vector2(0.16,-0.36)*size,Vector2(0.28,-0.18)*size,Vector2(0.25,-0.02)*size,pelvis,Gait.foot(stride+PI,travel,cycle_distance*0.55,size.y*0.055)*move_blend)
	var arm_swing := sine*(0.16 if kind=="runner" else 0.10)*move_blend
	var left_shoulder := Vector2(-0.29,-0.58)*size
	var right_shoulder := Vector2(0.29,-0.58)*size
	var left_arm := Transform2D(arm_swing,left_shoulder-left_shoulder.rotated(arm_swing))
	var right_arm := Transform2D(-arm_swing,right_shoulder-right_shoulder.rotated(-arm_swing))
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
		upper_offset.y -= sin(clock*2.4+enemy.get("id",0))*0.15
	if moving:
		upper_offset += pelvis
		if kind == "runner":
			upper_offset += Vector2(size.x*0.04,size.y*0.02)*move_blend
		elif kind == "hexer":
			upper_offset.y -= (0.5+0.5*sine)*size.y*0.025*move_blend
	var fall := smoothstep(0.05,0.84,death)
	var fold := smoothstep(0.0,0.43,death)
	var scatter := smoothstep(0.62,1.0,death)
	var fall_side := -1.0 if int(enemy.get("id",0)) % 2 else 1.0
	var death_transform := Transform2D(fall*fall_side*(1.12 if kind != "bulwark" else 0.72),Vector2.ZERO)
	var vertices := PackedVector2Array()
	vertices.resize(anchors.size())
	for n in anchors.size():
		var point: Vector2 = anchors[n]*size
		var rest := point
		if moving and kind != "hexer" and leg_blends[n]>0:
			var left := (left_leg[0]*rest).lerp(left_leg[1]*rest,knee_blends[n])
			var right := (right_leg[0]*rest).lerp(right_leg[1]*rest,knee_blends[n])
			var boot := boot_blends[n]
			left = left.lerp(left_leg[2]*rest,boot)
			right = right.lerp(right_leg[2]*rest,boot)
			point = point.lerp(left.lerp(right,foot_sides[n]),leg_blends[n])
		if moving:
			point += ((left_arm if sides[n]<0 else right_arm)*rest-rest)*arms[n]
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
	var definition := LayeredRig.definition("boss_"+str(clampi(mission,1,5)) if boss else enemy.get("kind","drifter"))
	if not definition.is_empty():
		draw_layered(canvas,enemy,definition,body_height(enemy,mission),offset,reduced,death,defer_draw)
		return
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

static func layered_pose(enemy: Dictionary, definition: Dictionary, height: float, death: float = 0.0) -> Dictionary:
	var kind: String = enemy.get("kind","drifter")
	var cycle_distance := height*(0.60 if kind=="runner" else (0.48 if kind=="bulwark" else 0.46))
	var phase: float = float(enemy.get("motion",0))*TAU/maxf(1,cycle_distance*0.16)
	var blend: float = clampf(enemy.get("motion_blend",1.0 if enemy.get("moving",false) else 0.0),0,1)
	var face: float = enemy.get("face",1.0)
	var velocity: Vector2 = enemy.get("motion_direction",enemy.get("velocity",Vector2(face,0)))
	var direction := velocity.normalized() if velocity.length_squared()>0.001 else Vector2(face,0)
	direction.x *= face
	var windup := 1-float(enemy.get("tell",0))/maxf(0.01,float(enemy.get("windup",1))) if enemy.get("tell",0)>0 else 0.0
	var strike := 1-float(enemy.get("attack_anim",0))/0.32 if enemy.get("attack_anim",0)>0 else 0.0
	var settle := 1-smoothstep(0,0.4,death) if death>0 else 1.0
	return LayeredRig.pose(definition,height,phase,blend,direction,{"cycle_distance":cycle_distance,"windup":windup*settle,"strike":strike*settle,"attack":enemy.get("attack",""),"rush":enemy.get("rush_left",0)>0,"death":death,"fall_side":-1.0 if int(enemy.get("id",0))%2 else 1.0})

static func draw_layered(canvas: Node2D, enemy: Dictionary, definition: Dictionary, height: float, offset: Vector2, reduced: bool, death: float, defer_draw: bool) -> void:
	canvas.set_meta("layered_actor_id",definition.id)
	var flash := clampf(float(enemy.get("hit_flash",0))/0.12,0,1)
	var recoil: Vector2 = enemy.get("hit_push",Vector2.ZERO)*flash if not reduced else Vector2.ZERO
	var data := LayeredRig.build(definition,layered_pose(enemy,definition,height,death),enemy.pos+offset+recoil,enemy.get("face",1.0))
	var tint := Color.WHITE.lerp(Color(1.7,1.7,1.8),0 if reduced else flash)
	if enemy.get("chill",0)>0: tint=tint.lerp(Color(0.58,0.78,1),0.32)
	tint.a=1-smoothstep(0.38,1,death)
	if death>0: tint=tint.lerp(Color(0.35,0.29,0.43,tint.a),smoothstep(0.05,0.5,death)*0.65)
	var batch: Dictionary = canvas.get_meta("enemy_batch",{})
	if not batch.is_empty() and batch.texture!=data.texture:
		flush(canvas)
		batch={}
	if batch.is_empty(): batch={"texture":data.texture,"vertices":PackedVector2Array(),"uv":PackedVector2Array(),"colors":PackedColorArray(),"indices":PackedInt32Array()}
	var first: int=batch.vertices.size()
	batch.vertices.append_array(data.vertices)
	batch.uv.append_array(data.uv)
	var colors:=PackedColorArray()
	colors.resize(data.vertices.size())
	colors.fill(tint)
	batch.colors.append_array(colors)
	for index in data.indices: batch.indices.append(first+index)
	canvas.set_meta("enemy_batch",batch)
	if not defer_draw: flush(canvas)

static func flush(canvas: Node2D) -> void:
	var batch: Dictionary = canvas.get_meta("enemy_batch", {})
	if batch.is_empty():
		return
	var meshes: Array = canvas.get_meta("actor_meshes", [])
	var mesh := DynamicMesh.update(canvas,"enemy_rig_pool",meshes.size(),batch.vertices,batch.uv,batch.indices,batch.colors)
	meshes.append(mesh)
	canvas.set_meta("actor_meshes", meshes)
	canvas.draw_mesh(mesh,batch.texture)
	canvas.set_meta("enemy_batch",{})
