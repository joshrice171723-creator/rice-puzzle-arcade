extends SceneTree
const Effects = preload("res://combat_effects.gd")
const Run = preload("res://run.gd")
const MenuSkin = preload("res://menu_skin.gd")
const FLOOR = preload("res://assets/mission-one/garage-yard.png")
var checks := 0
var failures := 0
var destination := ""
class EffectCanvas extends Node2D:
	var run: RefCounted
	var clock := 0.15
	var reduced := false
	var title := ""
	func _draw() -> void:
		draw_texture_rect_region(FLOOR,Rect2(0,0,430,760),Rect2(350,200,430,760))
		Effects.draw_ground(self,run,Vector2.ZERO,clock,reduced)
		Effects.draw_projectiles(self,run,Vector2.ZERO,clock,reduced)
		Effects.draw_effects(self,run,Vector2.ZERO,clock,reduced)
		draw_string_outline(MenuSkin.DISPLAY,Vector2(20,35),title,HORIZONTAL_ALIGNMENT_LEFT,-1,21,3,Color("071228"))
		draw_string(MenuSkin.DISPLAY,Vector2(20,35),title,HORIZONTAL_ALIGNMENT_LEFT,-1,21,Color("fff2d8"))
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			destination = arg.trim_prefix("--capture-dir=")
	call_deferred("verify")
func configure_fixture(id: String) -> RefCounted:
	var run = Run.new(123)
	run.player = Vector2(215,255)
	run.elapsed = 0.2
	run.spells[id] = {"rank":2,"branch":"spread","evolved":false}
	match id:
		"ember":
			run.shots.append({"pos":Vector2(140,240),"velocity":Vector2(450,-30),"kind":"ember","life":0.7})
			run.effects.append({"kind":"ember","from":Vector2(295,240),"to":Vector2(295,240),"life":0.2,"duration":0.3})
		"frost": run.effects.append({"kind":"frost","from":run.player,"to":run.player + Vector2(125,0),"life":0.32,"duration":0.45})
		"chain": run.effects.append({"kind":"chain","from":Vector2(90,290),"to":Vector2(300,210),"life":0.22,"duration":0.3})
		"lance": run.effects.append({"kind":"lance","from":Vector2(25,280),"to":Vector2(400,230),"life":0.2,"duration":0.25})
		"ground": run.zones.append({"pos":run.player,"radius":110.0,"life":3.2,"dps":8.0})
		"blades":
			for index in 3:
				run.shots.append({"pos":Vector2(150+index*60,230+index*12),"velocity":Vector2(450,-40),"kind":"blade","life":0.7})
		"gravity": run.effects.append({"kind":"gravity","from":run.player,"to":run.player + Vector2(120,0),"life":0.35,"duration":0.5})
	return run
func verify() -> void:
	root.size = Vector2i(430,760)
	check(Effects.ATLAS.get_width() > 1000 and Effects.ATLAS.get_image().detect_alpha() != Image.ALPHA_NONE,"Authored spell atlas has transparent pixels at useful resolution")
	for region: Rect2 in Effects.FRAMES:
		check(Rect2(Vector2.ZERO,Vector2(Effects.ATLAS.get_width(),Effects.ATLAS.get_height())).encloses(region),"Explicit VFX frame stays inside the authored atlas")
	for kind in ["chain","frost","ember","lance","gravity"]:
		check(Effects.handles_effect(kind),"Renderer handles the " + kind + " spell effect")
	for kind in ["slam","summon","trap","turret"]:
		check(not Effects.handles_effect(kind),"Renderer leaves " + kind + " telegraph to its existing owner")
	var canvas := EffectCanvas.new()
	root.add_child(canvas)
	for id in ["ember","frost","chain","wisp","lance","ground","blades","gravity"]:
		canvas.run = configure_fixture(id)
		canvas.title = id.capitalize() + " · visual fixture"
		var before: Dictionary = canvas.run.snapshot()
		for reduced in [false,true]:
			canvas.reduced = reduced
			canvas.queue_redraw()
			for tick in 5:
				await process_frame
			check(canvas.run.snapshot() == before,id + " rendering preserves simulation state")
			if not destination.is_empty() and DisplayServer.get_name() != "headless":
				DirAccess.make_dir_recursive_absolute(destination)
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(destination.path_join("%s-%s.png" % [id,"reduced" if reduced else "normal"]))
	canvas.queue_free()
	await process_frame
	print("Nightfall combat effects: %d checks, %d failures; eight spell families, normal and reduced" % [checks,failures])
	quit(1 if failures else 0)
