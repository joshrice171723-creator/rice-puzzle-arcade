extends RefCounted
## One textured body mesh per character, weighted around feet, hips and arms.
## Animation changes vertices continuously rather than switching generated poses.
const BODIES = preload("res://assets/hero-cast/equipment-bodies.png")
const EquipmentArt = preload("res://equipped_weapon_art.gd")
const Presentation = preload("res://mission_presentation.gd")
const Gait = preload("res://jointed_gait.gd")
const DynamicMesh = preload("res://dynamic_rig_mesh.gd")
const LayeredRig = preload("res://layered_actor_rig.gd")
const BODIES_REGIONS := {"scavenger":Rect2(20,110,415,720),"engineer":Rect2(460,110,410,720),"warden":Rect2(870,65,460,790),"arcanist":Rect2(1345,115,429,735)}
const HANDS := {"scavenger":Vector2(0.92,0.55),"engineer":Vector2(0.90,0.55),"warden":Vector2(0.86,0.57),"arcanist":Vector2(0.88,0.59)}
const COLS := 12
const ROWS := 18

static var weights: Array[PackedFloat32Array] = []
static var anchors := PackedVector2Array()
static var topology := PackedInt32Array()
static var uv_cache: Dictionary = {}

static func vertex_weights(uv: Vector2) -> PackedFloat32Array:
	return PackedFloat32Array([
		smoothstep(0.64,0.72,uv.y),smoothstep(0.43,0.55,uv.x),smoothstep(0.78,0.82,uv.y),smoothstep(0.84,0.93,uv.y),
		1-smoothstep(0.62,0.92,uv.y),
		(1-smoothstep(0.25,0.39,uv.x)+smoothstep(0.67,0.84,uv.x))*smoothstep(0.24,0.36,uv.y)*(1-smoothstep(0.59,0.72,uv.y)),
		smoothstep(0.59,0.83,uv.x)*smoothstep(0.23,0.38,uv.y)*(1-smoothstep(0.65,0.77,uv.y))])

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

static func geometry(size: Vector2, clock: float, stride: float, move_blend: float, cast_age: float, dodge: float, action: String = "", points: PackedVector2Array = PackedVector2Array(), movement_direction: Vector2 = Vector2.RIGHT) -> PackedVector2Array:
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
	var breathing := sin(clock*2.8)*0.15
	var travel := Vector2(movement_direction.x,movement_direction.y*0.28)
	var pelvis := Gait.torso(stride,move_blend,size.y)+Vector2(0,2.3*move_blend)
	var left_leg := Gait.leg_bones(Vector2(-0.08,-0.33)*size,Vector2(-0.19,-0.19)*size,Vector2(-0.21,-0.01)*size,pelvis,Gait.foot(stride,travel,19.8,5.0)*move_blend)
	var right_leg := Gait.leg_bones(Vector2(0.18,-0.33)*size,Vector2(0.26,-0.19)*size,Vector2(0.30,-0.01)*size,pelvis,Gait.foot(stride+PI,travel,19.8,5.0)*move_blend)
	var left_shoulder := Vector2(-0.28,-0.61)*size
	var right_shoulder := Vector2(0.28,-0.61)*size
	var left_arm := Transform2D(-sine*0.13*move_blend,left_shoulder-left_shoulder.rotated(-sine*0.13*move_blend))
	var right_arm := Transform2D(sine*0.09*move_blend,right_shoulder-right_shoulder.rotated(sine*0.09*move_blend))
	var cast := 0.0
	if cast_age >= -0.18 and cast_age < 0.30:
		cast = smoothstep(-0.18,0.0,cast_age)*(1-smoothstep(0.04,0.30,cast_age))
	var rotation := -0.48*cast
	var recoil := 0.0
	if action in ["pistol","scattergun","crossbow"]:
		recoil = EquipmentArt.kick(action,cast_age)*0.22
		rotation = -recoil*0.035
		cast = 0.0
	elif action == "sabre" and cast_age >= 0 and cast_age < 0.30:
		rotation = lerpf(-0.65,0.70,smoothstep(0.0,0.16,cast_age))*(1-smoothstep(0.16,0.30,cast_age))
	var shoulder := Vector2(size.x*0.12,-size.y*0.62)
	var turn := Transform2D(rotation,Vector2.ZERO)
	var vertices := PackedVector2Array()
	vertices.resize(vertex_anchors.size())
	for n in vertex_anchors.size():
		var w: PackedFloat32Array = vertex_weights_array[n]
		var point: Vector2 = vertex_anchors[n]*size
		var rest := point
		point += (pelvis-Vector2(recoil,breathing))*w[4]
		if move_blend > 0 and w[0] > 0:
			var left := (left_leg[0]*rest).lerp(left_leg[1]*rest,w[2])
			var right := (right_leg[0]*rest).lerp(right_leg[1]*rest,w[2])
			left = left.lerp(left_leg[2]*rest,w[3])
			right = right.lerp(right_leg[2]*rest,w[3])
			point = point.lerp(left.lerp(right,w[1]),w[0])
		var arm_motion: Vector2 = ((left_arm if vertex_anchors[n].x<0 else right_arm)*rest-rest)*w[5]
		point += arm_motion
		point = point.lerp(shoulder+turn*(point-shoulder),w[6])
		point += Vector2(cast*1.3+dodge*6,dodge*3)*w[4]
		vertices[n] = point
	return vertices

static func deform_point(uv: Vector2, size: Vector2, clock: float, stride: float, move_blend: float, cast_age: float, dodge: float, action: String = "", movement_direction: Vector2 = Vector2.RIGHT) -> Vector2:
	return geometry(size,clock,stride,move_blend,cast_age,dodge,action,PackedVector2Array([uv]),movement_direction)[0]

static func hand_offset(weapon: String, aim: Vector2, age: float) -> Vector2:
	if weapon not in ["pistol","scattergun","crossbow"]:
		return Vector2.ZERO
	var direction := aim.normalized() if aim.length_squared() > 0.01 else Vector2.RIGHT
	# Lift the forearm into a supported firing position and absorb the impulse at the wrist.
	return Vector2(-2.0,-6.0+direction.y*4.0) - direction*EquipmentArt.kick(weapon,age)

static func weapon_attachment(class_id: String, weapon: String, face: float, aim: Vector2, clock: float, stride: float = 0.0, move_blend: float = 0.0, cast_age: float = 0.0, dodge: float = 0.0, action: String = "", weapon_age: float = 0.0, movement_direction: Vector2 = Vector2.RIGHT, appearance: Dictionary = {}) -> Transform2D:
	var definition := LayeredRig.definition_for_appearance(class_id,appearance)
	if not definition.is_empty():
		var joints := layered_pose(definition,weapon,face,aim,stride,move_blend,cast_age,dodge,action,weapon_age,movement_direction)
		var body := Transform2D(Vector2(face,0),Vector2(0,1),Vector2(0,5.6))
		return body*EquipmentArt.mount(weapon,joints.wrist_r,Vector2(aim.x*face,aim.y),weapon_age,true)
	var source: Rect2 = BODIES_REGIONS.get(class_id,BODIES_REGIONS.scavenger)
	var size := Vector2(source.size.x/source.size.y*80,80)
	var local_aim := Vector2(aim.x*face,aim.y)
	var uv: Vector2 = HANDS.get(class_id,HANDS.scavenger)
	var hand := deform_point(uv,size,clock,stride,move_blend,cast_age,dodge,action,Vector2(movement_direction.x*face,movement_direction.y))
	hand += hand_offset(weapon,local_aim,weapon_age)*vertex_weights(uv)[6]
	var body := Transform2D(Vector2(face,0),Vector2(0,1),Vector2(0,5.6))
	return body*EquipmentArt.mount(weapon,hand,local_aim,weapon_age,true)

static func muzzle_offset(class_id: String, weapon: String, face: float, aim: Vector2, clock: float, stride: float = 0.0, move_blend: float = 0.0, cast_age: float = 0.0, dodge: float = 0.0, action: String = "", weapon_age: float = 0.0, movement_direction: Vector2 = Vector2.RIGHT, appearance: Dictionary = {}) -> Vector2:
	var attachment := weapon_attachment(class_id,weapon,face,aim,clock,stride,move_blend,cast_age,dodge,action,weapon_age,movement_direction,appearance)
	var spec: Dictionary = EquipmentArt.SPECS.get(weapon,EquipmentArt.SPECS.pistol)
	return attachment*spec.tip

static func layered_pose(definition: Dictionary, weapon: String, face: float, aim: Vector2, stride: float, move_blend: float, cast_age: float, dodge: float, action: String, weapon_age: float, movement_direction: Vector2) -> Dictionary:
	stride*=36.0/28.0
	var local_aim := Vector2(aim.x*face,aim.y).normalized()
	var pelvis := Gait.torso(stride,move_blend,80)+Vector2(0,80*0.018*move_blend)
	var grip := Vector2(27,-44)+pelvis+Vector2(0,local_aim.y*6)-local_aim*EquipmentArt.kick(weapon,weapon_age)
	if weapon=="sabre" and weapon_age>=0 and weapon_age<0.30:
		grip += Vector2(9,-5).rotated(lerpf(-1.0,1.0,smoothstep(0,0.18,weapon_age)))*(1-smoothstep(0.18,0.30,weapon_age))
	var joints := LayeredRig.pose(definition,80,stride,move_blend,Vector2(movement_direction.x*face,movement_direction.y),{"grip":grip,"cycle_distance":28.0,"forward_knees":true,"foot_lift":2.8})
	if cast_age>=-0.18 and cast_age<0.30 and action not in ["pistol","scattergun","crossbow","sabre"]:
		var gesture := smoothstep(-0.18,0,cast_age)*(1-smoothstep(0.04,0.30,cast_age))
		var shoulder: Vector2 = joints.shoulder_l
		var wrist: Vector2 = joints.wrist_l+Vector2(-7,-19)*gesture
		var rest := LayeredRig.rest_joints(definition,80)
		joints.elbow_l=Gait.knee(shoulder,wrist,rest.shoulder_l.distance_to(rest.elbow_l),rest.elbow_l.distance_to(rest.wrist_l),-1)
		joints.wrist_l=wrist
		joints.hand_l=wrist+Vector2(0,4)
	if dodge>0:
		for key in joints:
			if key.begins_with("ankle") or key.begins_with("foot"): continue
			joints[key] += Vector2(dodge*5,dodge*2)
	return joints

static func draw_motion(canvas: Node2D, pos: Vector2, offset: Vector2, face: float, clock: float, stride: float, move_blend: float, cast_age: float, dodge: float, engineer: bool, reduced: bool, class_id: String = "scavenger", hurt: float = 0.0, action: String = "", weapon: String = "pistol", aim: Vector2 = Vector2.RIGHT, weapon_age: float = 99.0, movement_direction: Vector2 = Vector2.RIGHT, appearance: Dictionary = {}) -> void:
	var definition := LayeredRig.definition_for_appearance(class_id,appearance)
	if not definition.is_empty():
		var joints := layered_pose(definition,weapon,face,aim,stride,move_blend,cast_age,dodge,action,weapon_age,movement_direction)
		var layered := LayeredRig.build(definition,joints)
		canvas.set_meta("layered_actor_id",class_id)
		var layered_mesh := DynamicMesh.update(canvas,"hero_layered_pool",0,layered.vertices,layered.uv,layered.indices)
		canvas.set_meta("hero_mesh",layered_mesh)
		var transform := Transform2D(Vector2(face,0),Vector2(0,1),pos+offset+Vector2(0,5.6))
		var tint := Color.WHITE.lerp(Color(1.7,1.35,1.25),hurt if not reduced else 0.0)
		var attachment := weapon_attachment(class_id,weapon,face,aim,clock,stride,move_blend,cast_age,dodge,action,weapon_age,movement_direction,appearance)
		attachment.origin += pos+offset
		EquipmentArt.draw(canvas,weapon,attachment,tint)
		if dodge>0 and not reduced:
			var trail := transform
			trail.origin.x-=face*14*dodge
			canvas.draw_mesh(layered_mesh,layered.texture,trail,Color(0.62,0.77,1,dodge*0.18))
		canvas.draw_mesh(layered_mesh,layered.texture,transform,tint)
		draw_accessories(canvas,joints,transform,appearance)
		EquipmentArt.mechanism(canvas,weapon,attachment,weapon_age,tint)
		if weapon in ["pistol","scattergun"] and weapon_age>=0 and weapon_age<0.24:
			var spec: Dictionary=EquipmentArt.SPECS[weapon]
			var muzzle: Vector2=attachment*spec.tip
			Presentation.muzzle_prongs(canvas,muzzle,(muzzle-attachment*spec.grip).normalized(),weapon_age/0.24,(0.45 if reduced else 1.0)*(1.35 if weapon=="scattergun" else 1.0))
		return
	var texture: Texture2D = BODIES
	var source: Rect2 = BODIES_REGIONS.get(class_id,BODIES_REGIONS.engineer if engineer else BODIES_REGIONS.scavenger)
	var size := Vector2(source.size.x/source.size.y*80,80)
	var vertices := geometry(size,clock,stride,move_blend,cast_age,dodge,action,PackedVector2Array(),Vector2(movement_direction.x*face,movement_direction.y))
	var local_aim := Vector2(aim.x*face,aim.y)
	var forearm := hand_offset(weapon,local_aim,weapon_age)
	for n in vertices.size():
		vertices[n] += forearm*weights[n][6]
	var key := str(source)
	if not uv_cache.has(key):
		var uvs := PackedVector2Array()
		var texture_size := Vector2(texture.get_width(),texture.get_height())
		for row in ROWS+1:
			for col in COLS+1:
				var uv := Vector2(float(col)/COLS,float(row)/ROWS)
				uvs.append((source.position+uv*source.size)/texture_size)
		uv_cache[key] = uvs
	var mesh := DynamicMesh.update(canvas,"hero_rig_pool",0,vertices,uv_cache[key],topology)
	canvas.set_meta("hero_mesh",mesh)
	var transform := Transform2D(Vector2(face,0),Vector2(0,1),pos+offset+Vector2(0,5.6))
	var tint := Color.WHITE.lerp(Color(1.7,1.35,1.25),hurt if not reduced else 0.0)
	var attachment := weapon_attachment(class_id,weapon,face,aim,clock,stride,move_blend,cast_age,dodge,action,weapon_age,movement_direction)
	attachment.origin += pos+offset
	# The body covers the grip, keeping the fingers in front of the held equipment.
	EquipmentArt.draw(canvas,weapon,attachment,tint)
	if dodge > 0 and not reduced:
		var trail := transform
		trail.origin.x -= face*14*dodge
		canvas.draw_mesh(mesh,texture,trail,Color(0.62,0.77,1,dodge*0.18))
	canvas.draw_mesh(mesh,texture,transform,tint)
	EquipmentArt.mechanism(canvas,weapon,attachment,weapon_age,tint)
	if weapon in ["pistol","scattergun"] and weapon_age >= 0 and weapon_age < 0.24:
		var spec: Dictionary = EquipmentArt.SPECS[weapon]
		var muzzle: Vector2 = attachment*spec.tip
		var direction: Vector2 = (muzzle-attachment*spec.grip).normalized()
		Presentation.muzzle_prongs(canvas,muzzle,direction,weapon_age/0.24,(0.45 if reduced else 1.0)*(1.35 if weapon == "scattergun" else 1.0))

static func draw_accessories(canvas: Node2D, joints: Dictionary, transform: Transform2D, appearance: Dictionary) -> void:
	var accessories: Dictionary=appearance.get("accessories",{})
	if accessories.is_empty(): return
	canvas.draw_set_transform_matrix(transform)
	var gold:=Color("e8bb63")
	if accessories.get("charm",false):
		var neck: Vector2=joints.neck
		var pendant: Vector2=neck.lerp(joints.pelvis,0.34)
		canvas.draw_polyline(PackedVector2Array([neck+Vector2(-4,1),pendant,neck+Vector2(4,1)]),gold,0.55,true)
		canvas.draw_colored_polygon(PackedVector2Array([pendant+Vector2(0,-1.6),pendant+Vector2(1.2,0),pendant+Vector2(0,1.6),pendant+Vector2(-1.2,0)]),Color("93c5eb"))
	if accessories.get("ring",false):
		canvas.draw_arc(joints.wrist_r+Vector2(0.8,0.7),0.85,0,TAU,12,gold,0.65,true)
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)

static func weapon_pose(run: RefCounted) -> Dictionary:
	for index in range(run.vfx_events.size()-1,-1,-1):
		var event: Dictionary = run.vfx_events[index]
		if event.kind == "weapon_cast" and event.life > 0:
			return {"age":event.duration-event.life,"direction":event.direction}
	return {"age":99.0,"direction":run.facing}

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
