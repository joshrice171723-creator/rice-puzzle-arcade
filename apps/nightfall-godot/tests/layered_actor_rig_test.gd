extends SceneTree
const Rig=preload("res://layered_actor_rig.gd")
const Hero=preload("res://hero_cast.gd")
const Enemy=preload("res://enemy_motion.gd")
const Weapon=preload("res://equipped_weapon_art.gd")
var failures:=0
var checks:=0
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(label)
func _initialize() -> void:
	Rig.warmup()
	for id in ["scavenger","engineer","warden","arcanist","drifter","runner","spitter","bulwark","hexer","boss_1","boss_2","boss_3","boss_4","boss_5"]:
		var data:=Rig.definition(id)
		check(not data.is_empty(),id+" has real layered source parts; no whole-body fallback")
		if data.is_empty(): continue
		var height:=80.0 if id not in Rig.ENEMIES else 52.0
		if id.begins_with("boss_"): height=Enemy.body_height({"boss":true},int(id.trim_prefix("boss_")))
		var rest:=Rig.rest_joints(data,height)
		for phase in [0.0,0.3,0.9,1.7,2.5,3.2,4.1,5.2,6.2]:
			var pose:=Rig.pose(data,height,phase,1,Vector2.RIGHT)
			var built:=Rig.build(data,pose)
			check(built.vertices.size()>=48 and built.vertices.size()<=68,id+" draws independent limb quads with bounded vertex count")
			check(built.vertices.size()==built.uv.size() and built.indices.size()%3==0,id+" has complete triangle topology")
			var valid:=true
			for point: Vector2 in built.vertices: valid=valid and point.is_finite()
			for uv: Vector2 in built.uv: valid=valid and uv.x>=0 and uv.y>=0 and uv.x<=1 and uv.y<=1
			for index in built.indices: valid=valid and index>=0 and index<built.vertices.size()
			check(valid,id+" has finite geometry and valid atlas UV/index ranges")
			for side in ["l","r"]:
				var upper: float=rest["hip_"+side].distance_to(rest["knee_"+side])
				var lower: float=rest["knee_"+side].distance_to(rest["ankle_"+side])
				check(absf(pose["hip_"+side].distance_to(pose["knee_"+side])-upper)<0.02 and absf(pose["knee_"+side].distance_to(pose["ankle_"+side])-lower)<0.02,id+" walks with rigid thigh/shin lengths")
		var before:=Rig.pose(data,height,0.1,1,Vector2.RIGHT)
		var after:=Rig.pose(data,height,0.1+TAU*0.01,1,Vector2.RIGHT)
		check(absf((after.ankle_l-before.ankle_l).x+0.36)<0.001 and absf(after.ankle_l.y-before.ankle_l.y)<0.001,id+" stance foot cancels36unit/cycle world travel without vertical drift")
		var up_before:=Rig.pose(data,height,0.1,1,Vector2.UP)
		var up_after:=Rig.pose(data,height,0.1+TAU*0.01,1,Vector2.UP)
		check(absf((up_after.ankle_l-up_before.ankle_l).y-0.36)<0.001,id+" vertical stance cancels world movement at full speed")
		var idle_a:=Rig.pose(data,height,0.4,0,Vector2.RIGHT)
		var idle_b:=Rig.pose(data,height,4.8,0,Vector2.RIGHT)
		check(idle_a==idle_b,id+" idle has no clock-driven foot wobble")
		var attack:=Rig.pose(data,height,0,0,Vector2.RIGHT,{"windup":0.9,"attack":"cleave"})
		check(attack.wrist_r.distance_to(idle_a.wrist_r)>height*0.10,id+" attack anticipation uses articulated arm joints")
	for id in ["scavenger","engineer","warden","arcanist"]:
		var data:=Rig.definition(id)
		if data.is_empty(): continue
		for face in [-1.0,1.0]:
			for weapon in Weapon.SPECS:
				var aim:=Vector2(face,-0.2).normalized()
				var pose:=Hero.layered_pose(data,weapon,face,aim,1.2,0.8,0.04,0,weapon,0.04,Vector2.RIGHT)
				var attachment:=Hero.weapon_attachment(id,weapon,face,aim,0,1.2,0.8,0.04,0,weapon,0.04,Vector2.RIGHT)
				var grip: Vector2=attachment*Weapon.SPECS[weapon].grip
				check(grip.distance_to(Vector2(pose.wrist_r.x*face,pose.wrist_r.y+5.6))<0.001,id+" actual bone wrist and weapon grip stay attached")
				if weapon in ["pistol","scattergun","crossbow"]: check(pose.elbow_r.y>pose.wrist_r.y and pose.elbow_r.y>pose.shoulder_r.y,id+" supported firearm elbow folds below the wrist and shoulder")
	if Rig.enemy_atlas_ready:
		var shared: Texture2D=Rig.definition("drifter").texture
		for id in Rig.ENEMIES: check(Rig.definition(id).texture==shared,id+" shares one cached enemy atlas for sorted batching")
		Rig.warmup()
		check(Rig.definition("drifter").texture==shared,"Repeated warmup retains the same GPU atlas")
	check(Rig.hero_atlas_ready,"All four hero classes and three wearable sets preload into the shared hero atlas")
	if Rig.hero_atlas_ready:
		for id in Rig.HEROES:
			for style in ["outrider","ironwatch","riftweaver"]:
				for slot in ["body","pants","boots","helmet"]:
					var appearance:={"slots":{slot:style}}
					var composed:=Rig.definition_for_appearance(id,appearance)
					var gear:=Rig.definition("gear_"+style)
					var part_name: String={"body":"torso","pants":"thigh","boots":"foot","helmet":"helmet"}[slot]
					check(composed.parts[part_name].region==gear.parts[part_name].region,id+" selected"+slot+" uses the actual equipped set's atlas region")
					check(composed.texture==Rig.definition(id).texture,id+" mixed equipment retains one hero atlas texture")
		for n in 128:
			var styles:=["none","outrider","ironwatch","riftweaver"]
			Rig.definition_for_appearance("scavenger",{"slots":{"body":styles[n%4],"pants":styles[(n/4)%4],"boots":styles[(n/16)%4],"helmet":styles[(n/64)%4]}})
		check(Rig.composed_definitions.size()<=64,"Mixed equipment geometry cache stays bounded to64 variants")
	print("Layered actor rig: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
