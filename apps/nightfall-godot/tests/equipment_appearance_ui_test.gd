extends SceneTree
const Profile=preload("res://profile.gd")
const Appearance=preload("res://equipment_appearance.gd")
const Rig=preload("res://layered_actor_rig.gd")
const Actor=preload("res://gear_actor.gd")
const Showcase=preload("res://class_showcase.gd")
const HeroCast=preload("res://hero_cast.gd")
const PATH="user://nightfall_equipped_actor_ui_fixture.json"
var checks:=0
var failures:=0
var capture_dir:=""
var owned: Dictionary={}
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):capture_dir=arg.trim_prefix("--capture-dir=")
	call_deferred("verify")
func settle() -> void:
	for frame in 7:await process_frame
func capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join(label+".png"))
func wear(profile: RefCounted, families: Array) -> void:
	for index in Appearance.ARMOR.size():
		var slot: String=Appearance.ARMOR[index]
		check(profile.equip(owned[families[index]+":"+slot]),"Fixture equips actual owned "+slot)
func verify_rendered_parts(profile: RefCounted) -> void:
	if DisplayServer.get_name()=="headless":return
	root.size=Vector2i(430,430)
	root.content_scale_size=Vector2i(430,430)
	var stage:=Node2D.new()
	root.add_child(stage)
	var actor:=Actor.new()
	actor.class_id="scavenger"
	actor.weapon_family="pistol"
	actor.reduced=true
	actor.position=Vector2(215,360)
	actor.scale=Vector2.ONE*3.2
	stage.add_child(actor)
	for slot in Appearance.ARMOR:profile.data.equipment[slot]=-1
	actor.appearance=Appearance.from_profile(profile)
	actor.queue_redraw()
	await settle()
	await RenderingServer.frame_post_draw
	var baseline: Image=root.get_texture().get_image()
	await capture("neutral-world-actor")
	for family in ["outrider","ironwatch","riftweaver"]:
		for slot in Appearance.ARMOR:
			for clear in Appearance.ARMOR:profile.data.equipment[clear]=-1
			check(profile.equip(owned[family+":"+slot]),"Equip isolated wearable "+family+" "+slot)
			actor.appearance=Appearance.from_profile(profile)
			actor.queue_redraw()
			await settle()
			await RenderingServer.frame_post_draw
			var rendered: Image=root.get_texture().get_image()
			var changed:=0
			for y in range(55,395,2):
				for x in range(70,360,2):
					var a:=baseline.get_pixel(x,y)
					var b:=rendered.get_pixel(x,y)
					if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.06:changed+=1
			check(changed>8,"Authored wearable changes real actor pixels: "+family+" "+slot)
			print("Wearable pixel delta ",family," ",slot,": ",changed)
			await capture("part-"+family+"-"+slot)
	stage.queue_free()
	await process_frame
	root.content_scale_size=Vector2i(430,760)
func verify() -> void:
	for family in ["outrider","ironwatch","riftweaver"]:
		check(not Rig.definition("gear_"+family).is_empty(),"Actual authored wearable asset present: "+family)
	if failures:
		print("Equipment appearance visual checks blocked: all three authored gear atlases are required.")
		quit(1)
		return
	var profile=Profile.new(PATH)
	profile.data.settings.reduced_effects=true
	for id in profile.Content.CLASSES:
		for stat in profile.Training.STATS:profile.combat_experience(id)[stat]=profile.Training.MAX_XP
	for family in ["outrider","ironwatch","riftweaver"]:
		for slot in Appearance.ARMOR:
			var item: Dictionary=profile.Loot.equipment(slot,"rare",profile.data.next_item,family)
			profile.data.next_item+=1
			profile.data.inventory.append(item)
			owned[family+":"+slot]=item.id
			check(Appearance.item_preview(item) is AtlasTexture,"Item preview uses the actual authored wearable "+family+" "+slot)
	profile.save()
	await verify_rendered_parts(profile)
	var arena=load("res://main.tscn").instantiate()
	arena.testing=true
	arena.profile=profile
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	var home: Control=arena.home
	root.size=Vector2i(430,760)
	for family in ["outrider","ironwatch","riftweaver","mixed"]:
		var combination: Array=[family,family,family,family] if family!="mixed" else ["ironwatch","riftweaver","outrider","ironwatch"]
		wear(profile,combination)
		var look: Dictionary=profile.stats().appearance
		for id in profile.Content.CLASSES:
			var definition:=Rig.definition_for_appearance(id,Appearance.from_profile(profile,id))
			check(definition.parts.head.region==Rig.definition(id).parts.head.region,"Armor preserves class face "+id)
			for slot in Appearance.ARMOR:
				var part: String={"helmet":"helmet","body":"torso","pants":"thigh","boots":"foot"}[slot]
				var gear:=Rig.definition("gear_"+look.slots[slot])
				check(definition.parts[part].region==gear.parts[part].region,"Real rig part substitution "+id+" "+slot)
		home.navigate("gear")
		await settle()
		var equipped: Node2D=home.find_child("EquippedHero",true,false)
		check(equipped.appearance==look,"Gear showcase receives actual equipped appearance")
		await capture("gear-"+family+"-430")
		home.inspected_class="scavenger"
		home.navigate("class")
		await settle()
		var hero: TextureRect=home.find_child("ClassCoverArt",true,false)
		var class_body:=hero.texture as AtlasTexture
		check(hero.get_meta("cover_class","")=="scavenger" and class_body != null and class_body.atlas==HeroCast.BODIES and class_body.region==HeroCast.BODIES_REGIONS.scavenger,"Class showcase reuses the approved Scavenger gameplay atlas")
		check(hero.find_child("ClassEquippedActor",true,false)==null and Showcase.hero_texture("scavenger") is AtlasTexture,"Scavenger class art is not loaded from the rejected portrait asset")
		await capture("class-"+family+"-430")
	for width in [430,320]:
		root.size=Vector2i(width,760 if width==430 else 568)
		for page in ["gear","class","haven"]:
			home.navigate(page)
			await settle()
			check(home.body.get_global_rect().end.y<=home.navigation.position.y,"Equipped "+page+" fits "+str(width))
			if page=="haven":
				check(home.find_child("BaseEquippedHero",true,false).appearance==profile.stats().appearance,"Base uses the current equipped actor")
			await capture(page+"-mixed-"+str(width))
	check(arena.attempt_id==0,"Visual fixtures never start a real expedition")
	arena.queue_free()
	await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	print("Equipment appearance UI: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
