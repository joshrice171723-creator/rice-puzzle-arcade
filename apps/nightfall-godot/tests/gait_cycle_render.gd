extends SceneTree
const Hero = preload("res://hero_cast.gd")
const Enemy = preload("res://enemy_motion.gd")
var directory := ""
var viewport: SubViewport
class Walker extends Node2D:
	var actor_kind := "scavenger"
	var hero := true
	var clock := 0.0
	func _draw() -> void:
		set_meta("actor_meshes",[])
		var speed := 80.0 if hero else (56.0 if actor_kind=="runner" else 32.0)
		for index in 10:
			var x := fposmod(index*24-clock*speed,240)-120
			draw_line(Vector2(x,5),Vector2(x+12,5),Color("506074"),0.8)
		if hero:
			Hero.draw_motion(self,Vector2.ZERO,Vector2.ZERO,1,clock,clock*speed*TAU/36,1,99,0,false,false,actor_kind,0,"","pistol",Vector2.RIGHT,99,Vector2.RIGHT)
		else:
			var enemy := {"id":2,"kind":actor_kind,"pos":Vector2.ZERO,"motion":clock*speed*0.16,"moving":true,"velocity":Vector2(speed,0),"face":1.0,"attack":"","boss":false}
			Enemy.draw(self,enemy,1,Vector2.ZERO,clock,false)

class Board extends Node2D:
	func _draw() -> void:
		draw_rect(Rect2(0,0,900,720),Color("17263c"))
		for n in get_child_count():
			var walker: Node2D = get_child(n)
			draw_string(ThemeDB.fallback_font,Vector2(n%3*300+18,n/3*240+25),walker.actor_kind+" / distance-driven",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d8e6fa"))

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="): directory = arg.trim_prefix("--capture-dir=")
	call_deferred("capture")

func capture() -> void:
	if directory.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(directory)
	viewport = SubViewport.new()
	viewport.size = Vector2i(900,720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var board := Board.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	viewport.add_child(board)
	var kinds := ["scavenger","engineer","warden","arcanist","drifter","runner","spitter","bulwark","hexer"]
	for n in kinds.size():
		var walker := Walker.new()
		walker.actor_kind = kinds[n]
		walker.hero = n<4
		walker.position = Vector2(n%3*300+130,n/3*240+210)
		walker.scale = Vector2.ONE*2
		board.add_child(walker)
	for frame in 120:
		for walker in board.get_children():
			walker.clock = frame/60.0
			walker.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var result := viewport.get_texture().get_image().save_png(directory.path_join("frame-%03d.png" % frame))
		if result != OK: push_error("Gait capture failed"); quit(1); return
	print("120 native gait frames: four heroes, five enemy types, planted ground reference")
	quit()
