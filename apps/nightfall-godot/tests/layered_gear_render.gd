extends SceneTree
const Hero=preload("res://hero_cast.gd")
const Rig=preload("res://layered_actor_rig.gd")
const IDS=["scavenger","engineer","warden","arcanist"]
const SETS=["none","outrider","ironwatch","riftweaver"]
var directory:=""
var checks:=0
var failures:=0
class Actor extends Node2D:
	var actor_id:="scavenger"
	var family:="none"
	var clock:=0.0
	var face:=1.0
	var blend:=0.0
	func _draw() -> void:
		var appearance:={"slots":{"body":family,"pants":family,"boots":family,"helmet":family},"accessories":{"ring":family!="none","charm":family!="none","gadget":family!="none"}}
		var weapon: String={"scavenger":"pistol","engineer":"crossbow","warden":"sabre","arcanist":"wand"}[actor_id]
		Hero.draw_motion(self,Vector2.ZERO,Vector2.ZERO,face,clock,clock*80*TAU/36,blend,99,0,false,false,actor_id,0,"",weapon,Vector2(face,0),99,Vector2(face,0),appearance)
class Board extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0,0,1200,960),Color("17253b"))
		for row in 4:
			for col in 4:
				draw_string(ThemeDB.fallback_font,Vector2(col*300+15,row*240+24),IDS[row]+" / "+SETS[col],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("dce9ff"))
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(label)
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):directory=arg.trim_prefix("--capture-dir=")
	call_deferred("capture")
func capture() -> void:
	if directory.is_empty():quit(1);return
	Rig.warmup()
	check(Rig.hero_atlas_ready,"Fourclassesandthreewearablesets shareonepackedatlas")
	if not Rig.hero_atlas_ready:quit(1);return
	DirAccess.make_dir_recursive_absolute(directory)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1200,960)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var board:=Board.new()
	board.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	viewport.add_child(board)
	for row in 4:
		for col in 4:
			var actor:=Actor.new()
			actor.actor_id=IDS[row]
			actor.family=SETS[col]
			actor.position=Vector2(col*300+140,row*240+214)
			actor.scale=Vector2.ONE*2.1
			board.add_child(actor)
	for variant in ["standing","walking","left"]:
		for actor in board.get_children():
			actor.blend=0 if variant=="standing" else 1
			actor.clock=0.2 if variant=="standing" else 0.15
			actor.face=-1 if variant=="left" else 1
			actor.queue_redraw()
		for n in 3:await process_frame
		await RenderingServer.frame_post_draw
		var rendered:=viewport.get_texture().get_image()
		check(rendered.save_png(directory.path_join("gear-"+variant+".png"))==OK,"Nativegearboardwrites"+variant)
		for row in 4:
			var neutral:=rendered.get_region(Rect2i(30,row*240+35,240,190)).get_data()
			for col in range(1,4):check(neutral!=rendered.get_region(Rect2i(col*300+30,row*240+35,240,190)).get_data(),IDS[row]+" actualequippedsetchangesrenderedpixels")
	print("Layered gear native rendering: %d checks,%d failures"%[checks,failures])
	quit(1 if failures else 0)
