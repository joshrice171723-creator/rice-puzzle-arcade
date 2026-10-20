extends SceneTree
const Hero=preload("res://hero_cast.gd")
const Rig=preload("res://layered_actor_rig.gd")
const IDS=["scavenger","engineer","warden","arcanist"]
var directory:=""
var frames:=120
class Actor extends Node2D:
	var actor_id:="scavenger"
	var reference:=false
	var face:=1.0
	var clock:=0.0
	func _draw() -> void:
		if reference:
			var source: Rect2=Hero.BODIES_REGIONS[actor_id]
			var size:=Vector2(source.size.x/source.size.y*80,80)
			draw_texture_rect_region(Hero.BODIES,Rect2(Vector2(-size.x*0.46,-size.y*0.99)+Vector2(0,5.6),size),source)
			return
		for n in 12:
			var x:=fposmod(n*18-clock*80*face,216)-108
			draw_line(Vector2(x,5),Vector2(x+8,5),Color("63748e"),0.65)
		Hero.draw_motion(self,Vector2.ZERO,Vector2.ZERO,face,clock,clock*80*TAU/36,1,99,0,false,false,actor_id,0,"","pistol",Vector2(face,0),99,Vector2(face,0))
class Board extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0,0,1080,720),Color("17253c"))
		for row in 3:
			for col in 4:
				var label: String=["Original painted proportions","Layered walk: right","Layered walk: left"][row]
				draw_string(ThemeDB.fallback_font,Vector2(col*270+12,row*240+24),IDS[col]+" / "+label,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("dceaff"))
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): directory=arg.trim_prefix("--capture-dir=")
		if arg.begins_with("--frames="): frames=int(arg.trim_prefix("--frames="))
	call_deferred("capture")
func capture() -> void:
	if directory.is_empty():quit(1);return
	Rig.warmup()
	for id in IDS:
		if Rig.definition(id).is_empty():push_error("Missing layeredhero: "+id);quit(1);return
	DirAccess.make_dir_recursive_absolute(directory)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1080,720)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var board:=Board.new()
	board.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	viewport.add_child(board)
	for row in 3:
		for col in 4:
			var actor:=Actor.new()
			actor.actor_id=IDS[col]
			actor.reference=row==0
			actor.face=-1.0 if row==2 else 1.0
			actor.position=Vector2(col*270+135,row*240+220)
			actor.scale=Vector2.ONE*2.1
			board.add_child(actor)
	for frame in frames:
		for actor in board.get_children():actor.clock=frame/60.0;actor.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		if viewport.get_texture().get_image().save_png(directory.path_join("frame-%03d.png"%frame))!=OK:quit(1);return
	print("Hero anatomy comparison: originalpaintedreference,actualright/leftcontinuousrigwalk")
	quit()
