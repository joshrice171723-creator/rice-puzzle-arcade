extends SceneTree
const Hero=preload("res://hero_cast.gd")
const Enemy=preload("res://enemy_motion.gd")
const Rig=preload("res://layered_actor_rig.gd")
const IDS=["scavenger","engineer","warden","arcanist","drifter","runner","spitter","bulwark","hexer","boss_1","boss_2","boss_3","boss_4","boss_5"]
var directory:=""
var frame_count:=240
var actor_ids: Array=IDS.duplicate()
class Actor extends Node2D:
	var actor_id:="scavenger"
	var time:=0.0
	func _draw() -> void:
		set_meta("actor_meshes",[])
		var mode:=int(time/2)%4
		var direction: Vector2=[Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN][mode]
		var face: float=-1 if mode==1 else 1
		var speed:=80.0 if actor_id in ["scavenger","engineer","warden","arcanist"] else 32.0
		var phase:=time*speed*TAU/36
		for n in 15:
			var x:=fposmod(n*20-time*speed*direction.x,300)-150
			draw_line(Vector2(x,5),Vector2(x+9,5),Color("5e718c"),0.7)
		if actor_id in ["scavenger","engineer","warden","arcanist"]:
			Hero.draw_motion(self,Vector2.ZERO,Vector2.ZERO,face,time,phase,1,99,0,false,false,actor_id,0,"","pistol",Vector2(face,0),99,direction)
		else:
			var boss:=actor_id.begins_with("boss_")
			var mission:=int(actor_id.trim_prefix("boss_")) if boss else 1
			var state:={"id":2,"kind":"drifter" if boss else actor_id,"boss":boss,"pos":Vector2.ZERO,"motion":time*speed*0.16,"moving":true,"motion_blend":1.0,"motion_direction":direction,"face":face,"attack":""}
			Enemy.draw(self,state,mission,Vector2.ZERO,time,false)
class Board extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0,0,1080,1150),Color("18263c"))
		for n in get_child_count():
			var actor: Node2D=get_child(n)
			draw_string(ThemeDB.fallback_font,Vector2(n%3*360+16,(n/3)*230+24),actor.actor_id+" / independent bone rig",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("dfebff"))
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): directory=arg.trim_prefix("--capture-dir=")
		if arg.begins_with("--frames="): frame_count=int(arg.trim_prefix("--frames="))
		if arg=="--core": actor_ids=IDS.slice(0,9)
	call_deferred("capture")
func capture() -> void:
	if directory.is_empty(): quit(1);return
	Rig.warmup()
	for id in actor_ids:
		if Rig.definition(id).is_empty(): push_error("Missing actual layered art: "+id);quit(1);return
	DirAccess.make_dir_recursive_absolute(directory)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(1080,1150)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var board:=Board.new()
	board.texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	viewport.add_child(board)
	for n in actor_ids.size():
		var actor:=Actor.new()
		actor.actor_id=actor_ids[n]
		actor.position=Vector2(n%3*360+180,(n/3)*230+211)
		actor.scale=Vector2.ONE*(1.45 if n>=9 else 1.8)
		board.add_child(actor)
	for frame in frame_count:
		for actor in board.get_children(): actor.time=frame/30.0;actor.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		for actor in board.get_children():
			if actor.get_meta("layered_actor_id","")!=actor.actor_id: push_error("Renderer fell back frompart rig: "+actor.actor_id);quit(1);return
		if viewport.get_texture().get_image().save_png(directory.path_join("frame-%03d.png"%frame))!=OK: quit(1);return
	print("Actual layered rigs captured:4hero+5enemy+5boss,continuousfour-directionwalk")
	quit()
