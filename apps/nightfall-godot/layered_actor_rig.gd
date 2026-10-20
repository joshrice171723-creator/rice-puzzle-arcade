extends RefCounted
## Independent painted parts attached to rigid bones. No complete-body texture warp.
const Gait = preload("res://jointed_gait.gd")
const ORDER := ["cape","coat","upper_arm_l","forearm_l","hand_l","thigh_l","shin_l","foot_l","thigh_r","shin_r","foot_r","hips","upper_arm_r","torso","tabard","head","helmet","forearm_r","weapon","hand_r"]
const BONES := {
	"cape":["neck","cape_end"],"torso":["neck","pelvis"],"hips":["pelvis","hips_end"],"head":["neck","head"],
	"weapon":["wrist_r","weapon_end"],
	"helmet":["neck","head"],
	"coat":["neck","pelvis"],"tabard":["neck","pelvis"],
	"upper_arm_l":["shoulder_l","elbow_l"],"forearm_l":["elbow_l","wrist_l"],"hand_l":["wrist_l","hand_l"],
	"upper_arm_r":["shoulder_r","elbow_r"],"forearm_r":["elbow_r","wrist_r"],"hand_r":["wrist_r","hand_r"],
	"thigh_l":["hip_l","knee_l"],"shin_l":["knee_l","ankle_l"],"foot_l":["ankle_l","foot_l"],
	"thigh_r":["hip_r","knee_r"],"shin_r":["knee_r","ankle_r"],"foot_r":["ankle_r","foot_r"]}
const DEFAULT_JOINTS := {
	"neck":Vector2(0,-0.72),"head":Vector2(0,-1.0),"pelvis":Vector2(0,-0.46),"hips_end":Vector2(0,-0.40),"cape_end":Vector2(0,-0.28),
	"weapon_end":Vector2(0.37,-0.73),
	"shoulder_l":Vector2(-0.18,-0.67),"elbow_l":Vector2(-0.24,-0.51),"wrist_l":Vector2(-0.23,-0.35),"hand_l":Vector2(-0.22,-0.30),
	"shoulder_r":Vector2(0.18,-0.67),"elbow_r":Vector2(0.25,-0.51),"wrist_r":Vector2(0.26,-0.35),"hand_r":Vector2(0.27,-0.30),
	"hip_l":Vector2(-0.065,-0.46),"knee_l":Vector2(-0.085,-0.285),"ankle_l":Vector2(-0.09,-0.14),"foot_l":Vector2(0.02,-0.14),
	"hip_r":Vector2(0.065,-0.46),"knee_r":Vector2(0.085,-0.285),"ankle_r":Vector2(0.09,-0.14),"foot_r":Vector2(0.20,-0.14)}
static var manifests: Dictionary = {}
static var enemy_atlas_attempted := false
static var enemy_atlas_ready := false
static var hero_atlas_ready := false
static var composed_definitions: Dictionary={}
const ENEMIES := ["drifter","runner","spitter","bulwark","hexer"]
const HEROES := ["scavenger","engineer","warden","arcanist"]
const GEAR := ["gear_outrider","gear_ironwatch","gear_riftweaver"]

static func definition(id: String) -> Dictionary:
	if id in ENEMIES and not enemy_atlas_attempted:
		enemy_atlas_attempted=true
		prepare_enemy_atlas()
	if manifests.has(id): return manifests[id]
	var path := "res://assets/actor-rigs/"+id+".json"
	if not FileAccess.file_exists(path): path="res://assets/actor-parts/enemies/"+id+".json"
	if not FileAccess.file_exists(path): return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary or not parsed.has("parts") or not parsed.has("texture"): return {}
	var result: Dictionary = parsed
	if not ResourceLoader.exists(result.texture): return {}
	result.texture = load(result.texture)
	if not result.texture is Texture2D: return {}
	result.id=id
	manifests[id] = result
	return result

static func prepare_enemy_atlas() -> void:
	if enemy_atlas_ready: return
	enemy_atlas_attempted=true
	# Bounded engine texture packing: one 3072x2048 RGBA8 atlas, generated once.
	# The original source files are unchanged. Local image buffers die after upload.
	for id in ENEMIES:
		if not FileAccess.file_exists("res://assets/actor-rigs/"+id+".json"): return
	for id in ENEMIES:
		if definition(id).is_empty(): return
	var atlas := Image.create(3072,2048,false,Image.FORMAT_RGBA8)
	for n in ENEMIES.size():
		var data := definition(ENEMIES[n])
		var image_data: Image=data.texture.get_image()
		if image_data.is_compressed(): image_data.decompress()
		image_data.convert(Image.FORMAT_RGBA8)
		var original_size := Vector2(image_data.get_width(),image_data.get_height())
		var factor := minf(1024.0/original_size.x,1024.0/original_size.y)
		var packed_size := Vector2i(roundi(original_size.x*factor),roundi(original_size.y*factor))
		image_data.resize(packed_size.x,packed_size.y,Image.INTERPOLATE_LANCZOS)
		var origin := Vector2i((n%3)*1024,(n/3)*1024)
		atlas.blit_rect(image_data,Rect2i(Vector2i.ZERO,packed_size),origin)
		for key in data.parts:
			var region: Array=data.parts[key].region
			data.parts[key].region=[region[0]*factor+origin.x,region[1]*factor+origin.y,region[2]*factor,region[3]*factor]
	atlas.fix_alpha_edges()
	atlas.generate_mipmaps()
	var texture := ImageTexture.create_from_image(atlas)
	for id in ENEMIES:
		manifests[id].texture=texture
		manifests[id].erase("prepared_parts")
		manifests[id].erase("uv")
		manifests[id].erase("indices")
	enemy_atlas_ready=true

static func warmup(mission: int = 0) -> void:
	prepare_enemy_atlas()
	prepare_hero_atlas()
	for id in ["scavenger","engineer","warden","arcanist"]+ENEMIES:
		var data := definition(id)
		if not data.is_empty(): prepare_parts(data)
	if mission>0:
		var boss := definition("boss_"+str(clampi(mission,1,5)))
		if not boss.is_empty(): prepare_parts(boss)

static func prepare_hero_atlas() -> void:
	if hero_atlas_ready: return
	var ids: Array=HEROES+GEAR
	for id in ids:
		if not FileAccess.file_exists("res://assets/actor-rigs/"+id+".json"): return
	for id in ids:
		if definition(id).is_empty(): return
	var atlas:=Image.create(4096,2048,false,Image.FORMAT_RGBA8)
	for n in ids.size():
		var data:=definition(ids[n])
		var pixels: Image=data.texture.get_image()
		if pixels.is_compressed(): pixels.decompress()
		pixels.convert(Image.FORMAT_RGBA8)
		var factor:=minf(1024.0/pixels.get_width(),1024.0/pixels.get_height())
		var size:=Vector2i(roundi(pixels.get_width()*factor),roundi(pixels.get_height()*factor))
		pixels.resize(size.x,size.y,Image.INTERPOLATE_LANCZOS)
		var origin:=Vector2i((n%4)*1024,(n/4)*1024)
		atlas.blit_rect(pixels,Rect2i(Vector2i.ZERO,size),origin)
		for key in data.parts:
			var region: Array=data.parts[key].region
			data.parts[key].region=[region[0]*factor+origin.x,region[1]*factor+origin.y,region[2]*factor,region[3]*factor]
	atlas.fix_alpha_edges()
	atlas.generate_mipmaps()
	var texture:=ImageTexture.create_from_image(atlas)
	for id in ids:
		manifests[id].texture=texture
		manifests[id].erase("prepared_parts")
		manifests[id].erase("uv")
		manifests[id].erase("indices")
	hero_atlas_ready=true

static func definition_for_appearance(class_id: String, appearance: Dictionary = {}) -> Dictionary:
	var base:=definition(class_id)
	if appearance.is_empty() or base.is_empty(): return base
	if not hero_atlas_ready: prepare_hero_atlas()
	if not hero_atlas_ready: return base
	var slots: Dictionary=appearance.get("slots",{})
	var key:=class_id
	for slot in ["body","pants","boots","helmet"]: key+="|"+str(slots.get(slot,"none"))
	if composed_definitions.has(key): return composed_definitions[key]
	var result: Dictionary={"id":class_id,"texture":base.texture,"parts":base.parts.duplicate(true),"joints":base.get("joints",{})}
	for slot in ["body","pants","boots","helmet"]:
		var set_id: String=slots.get(slot,"none")
		if set_id not in ["outrider","ironwatch","riftweaver"]: continue
		var gear:=definition("gear_"+set_id)
		var names: Array={"body":["torso","cape","upper_arm","forearm"],"pants":["thigh","hips"],"boots":["shin","foot"],"helmet":["helmet"]}[slot]
		for part_name in names:
			if part_name=="thigh" and gear.parts.has("thigh_l") and gear.parts.has("thigh_r"):
				result.parts.erase("thigh")
				for side in ["l","r"]:
					result.parts["thigh_"+side]=gear.parts["thigh_"+side].duplicate(true)
				continue
			if gear.parts.has(part_name):
				result.parts.erase(part_name+"_l")
				result.parts.erase(part_name+"_r")
				result.parts[part_name]=gear.parts[part_name].duplicate(true)
				if part_name=="torso":
					result.parts.erase("coat")
					result.parts.erase("tabard")
				if part_name=="forearm":
					result.parts.erase("hand_l")
					result.parts.erase("hand_r")
				if part_name=="helmet" and result.parts.head.has("face_polygon"):
					result.parts.head.polygon=result.parts.head.face_polygon
	if composed_definitions.size()>=64: composed_definitions.erase(composed_definitions.keys()[0])
	composed_definitions[key]=result
	return result

static func prepare_parts(definition_data: Dictionary) -> void:
	if definition_data.has("prepared_parts"): return
	var prepared: Array=[]
	var uv := PackedVector2Array()
	var indices := PackedInt32Array()
	var texture: Texture2D=definition_data.texture
	var texture_size := Vector2(texture.get_width(),texture.get_height())
	for key in ORDER:
		var part := part_definition(definition_data.parts,key)
		if part.is_empty(): continue
		var region_array: Array=part.region
		var region := Rect2(region_array[0],region_array[1],region_array[2],region_array[3])
		var pivot_array: Array=part.get("pivot",[0.5,0.1])
		var end_array: Array=part.get("end",[0.5,0.9])
		var pivot := Vector2(pivot_array[0],pivot_array[1])*region.size
		var end := Vector2(end_array[0],end_array[1])*region.size
		var corners := PackedVector2Array()
		var axis := (end-pivot).normalized()
		var across := axis.orthogonal()
		var width: float=part.get("width_scale",1.0)
		var first := uv.size()
		var outline := PackedVector2Array()
		for value: Array in part.get("polygon",[[0,0],[1,0],[1,1],[0,1]]): outline.append(Vector2(value[0],value[1]))
		for corner: Vector2 in outline:
			var source_point := corner*region.size-pivot
			corners.append(axis*source_point.dot(axis)+across*source_point.dot(across)*width)
			uv.append((region.position+corner*region.size)/texture_size)
		for index in Geometry2D.triangulate_polygon(outline): indices.append(first+index)
		prepared.append({"from":BONES[key][0],"to":BONES[key][1],"length":maxf(1,pivot.distance_to(end)),"angle":(end-pivot).angle(),"corners":corners})
	definition_data.prepared_parts=prepared
	definition_data.uv=uv
	definition_data.indices=indices

static func rest_joints(definition_data: Dictionary, height: float) -> Dictionary:
	if not definition_data.has("joint_cache"): definition_data.joint_cache={}
	if definition_data.joint_cache.has(height): return definition_data.joint_cache[height]
	var joints := {}
	var authored: Dictionary = definition_data.get("joints",{})
	for key in DEFAULT_JOINTS:
		var value: Variant = authored.get(key,DEFAULT_JOINTS[key])
		joints[key] = (Vector2(value[0],value[1]) if value is Array else value)*height
	definition_data.joint_cache[height]=joints
	return joints

static func bend_toward(from: Vector2, hinge: Vector2, to: Vector2) -> float:
	return 1.0 if (hinge-from).dot((to-from).orthogonal())>=0 else -1.0

static func pose(definition_data: Dictionary, height: float, phase: float, blend: float, direction: Vector2, options: Dictionary = {}) -> Dictionary:
	var rest := rest_joints(definition_data,height)
	var joints := rest.duplicate()
	var death: float = options.get("death",0.0)
	blend *= 1.0-smoothstep(0,0.18,death)
	var stride_length: float = options.get("cycle_distance",36.0)*0.55
	var foot_lift: float=options.get("foot_lift",height*0.075)
	var travel := direction.normalized()
	if travel.length_squared()<0.001: travel=Vector2.RIGHT
	var pelvis := Gait.torso(phase,blend,height)+Vector2(0,height*0.025*blend)
	var anticipate: float = pow(clampf(options.get("windup",0.0),0,1),2)
	var follow: float = sin(pow(clampf(options.get("strike",0.0),0,1),0.55)*PI)
	var attack: String = options.get("attack","")
	var body_delta := Vector2.ZERO
	var arm_delta := Vector2.ZERO
	if options.get("rush",false): body_delta+=Vector2(height*0.08,height*0.035)
	if attack in ["slam","cleave"]:
		body_delta = Vector2((follow-anticipate)*height*0.075,(follow*0.09-anticipate*0.035)*height)
		arm_delta = Vector2((follow-anticipate)*height*0.10,(-anticipate*0.34+follow*0.14)*height)
	elif attack in ["hex","hex_bolt","summon","bolt"]:
		arm_delta=Vector2(0,(-anticipate*0.30+follow*0.10)*height)
	elif attack in ["swipe","pounce","rush","spit","toss"]:
		body_delta=Vector2((follow-anticipate)*height*0.10,anticipate*height*0.025)
		arm_delta=Vector2((follow-anticipate)*height*0.20,-anticipate*height*0.09)
	var fold := smoothstep(0,0.48,death)
	pelvis += Vector2(0,height*0.22*fold)
	# Lower the shared pelvis just enough for both planted ankles to remain within
	# rigid leg reach. The knee solution never stretches a shin to meet the floor.
	for side in ["l","r"]:
		var offset_phase: float=phase+(PI if side=="r" else 0)
		var ankle: Vector2=rest["ankle_"+side]+Gait.foot(offset_phase,travel,stride_length,foot_lift)*blend
		var hip: Vector2=rest["hip_"+side]+body_delta
		var reach: float=(rest["hip_"+side].distance_to(rest["knee_"+side])+rest["knee_"+side].distance_to(rest["ankle_"+side]))*0.995
		var horizontal: float=ankle.x-hip.x
		var vertical := sqrt(maxf(0.0001,reach*reach-horizontal*horizontal))
		pelvis.y=maxf(pelvis.y,ankle.y-vertical-hip.y)
	for key in joints:
		if key.begins_with("ankle") or key.begins_with("foot") or key.begins_with("knee"): continue
		joints[key] += pelvis+body_delta
	for side in ["l","r"]:
		var offset_phase: float = phase+(PI if side=="r" else 0)
		var foot_delta := Gait.foot(offset_phase,travel,stride_length,foot_lift)*blend
		var ankle: Vector2 = rest["ankle_"+side]+foot_delta
		var hip: Vector2 = joints["hip_"+side]
		var knee_bend := bend_toward(rest["hip_"+side],rest["knee_"+side],rest["ankle_"+side])
		if options.get("forward_knees",false): knee_bend=1.0 if (ankle-hip).orthogonal().x>=0 else -1.0
		var knee := Gait.knee(hip,ankle,rest["hip_"+side].distance_to(rest["knee_"+side]),rest["knee_"+side].distance_to(rest["ankle_"+side]),knee_bend)
		joints["knee_"+side]=knee
		joints["ankle_"+side]=ankle
		var cycle := fposmod(offset_phase/TAU,1.0)
		var pitch := -sin((cycle-0.55)/0.45*PI)*0.14*blend if cycle>0.55 else 0.0
		joints["foot_"+side]=ankle+(rest["foot_"+side]-rest["ankle_"+side]).rotated(pitch)
		var shoulder: Vector2 = joints["shoulder_"+side]
		var swing := sin(offset_phase)*blend*height*0.105
		var wrist: Vector2 = rest["wrist_"+side]+pelvis+body_delta+Vector2(swing,-absf(swing)*0.25)+arm_delta
		if side=="r" and options.has("grip"):
			wrist=options.grip
		var upper_length: float=rest["shoulder_"+side].distance_to(rest["elbow_"+side])
		var lower_length: float=rest["elbow_"+side].distance_to(rest["wrist_"+side])
		wrist=shoulder+(wrist-shoulder).limit_length((upper_length+lower_length)*0.995)
		var elbow := Gait.knee(shoulder,wrist,upper_length,lower_length,bend_toward(rest["shoulder_"+side],rest["elbow_"+side],rest["wrist_"+side]))
		if side=="r" and options.has("grip"):
			# A supported gun arm folds BELOW the grip. Choosing the neutral
			# hanging-arm IK branch here raises the elbow above the shoulder.
			var alternative := Gait.knee(shoulder,wrist,upper_length,lower_length,-bend_toward(rest["shoulder_"+side],rest["elbow_"+side],rest["wrist_"+side]))
			if alternative.y>elbow.y: elbow=alternative
		joints["elbow_"+side]=elbow
		joints["wrist_"+side]=wrist
		var forearm_angle: float=(wrist-elbow).angle()-(rest["wrist_"+side]-rest["elbow_"+side]).angle()
		joints["hand_"+side]=wrist+(rest["hand_"+side]-rest["wrist_"+side]).rotated(forearm_angle)
	var weapon_angle: float=(joints.wrist_r-joints.elbow_r).angle()-(rest.wrist_r-rest.elbow_r).angle()
	joints.weapon_end=joints.wrist_r+(rest.weapon_end-rest.wrist_r).rotated(weapon_angle)
	if death>0:
		var fall := smoothstep(0.10,0.88,death)
		var sign_side: float = options.get("fall_side",1.0)
		for key in joints:
			var point: Vector2 = joints[key].rotated(sign_side*fall*1.2)
			point.y=minf(height*0.035,point.y*(1-fall*0.42))
			joints[key]=point
	return joints

static func part_definition(parts: Dictionary, key: String) -> Dictionary:
	if parts.has(key): return parts[key]
	var shared := key.trim_suffix("_l").trim_suffix("_r")
	return parts.get(shared,{})

static func build(definition_data: Dictionary, joints: Dictionary, origin: Vector2 = Vector2.ZERO, face: float = 1.0) -> Dictionary:
	prepare_parts(definition_data)
	var vertices := PackedVector2Array()
	var texture: Texture2D = definition_data.texture
	vertices.resize(definition_data.uv.size())
	var n := 0
	for part: Dictionary in definition_data.prepared_parts:
		var from: Vector2 = joints[part.from]
		var to: Vector2 = joints[part.to]
		var scale_factor: float = from.distance_to(to)/part.length
		var angle: float = (to-from).angle()-part.angle
		for corner: Vector2 in part.corners:
			var point: Vector2 = from+corner.rotated(angle)*scale_factor
			vertices[n]=origin+Vector2(point.x*face,point.y)
			n+=1
	return {"vertices":vertices,"uv":definition_data.uv,"indices":definition_data.indices,"texture":texture}
