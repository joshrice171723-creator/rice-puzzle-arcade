extends SceneTree
const Motion = preload("res://enemy_motion.gd")
var output := ""
class PoseCanvas extends Node2D:
	var font: Font = ThemeDB.fallback_font
	func _draw() -> void:
		set_meta("actor_meshes",[])
		draw_rect(Rect2(0,0,1200,690),Color("18263f"))
		var kinds := ["drifter","runner","spitter","bulwark","hexer","boss1","boss2","boss3","boss4","boss5"]
		for col in kinds.size():
			var kind: String = kinds[col]
			var boss := kind.begins_with("boss")
			var mission := col-4 if boss else 1
			draw_string(font,Vector2(col*120+12,25),kind,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color.WHITE)
			for row in 5:
				var attack: String = ["swipe","pounce","spit","cleave","hex","slam","rush","toss","summon","rush"][col]
				var enemy := {"id":col,"kind":kind,"boss":boss,"face":1.0,"attack":attack,"motion":1.8,"moving":row==0,"pos":Vector2(col*120+60,row*125+139),"tell":0.12 if row==1 else 0.0,"windup":0.8,"attack_anim":0.24 if row==2 else 0.0}
				var death := 0.38 if row==3 else (0.76 if row==4 else 0.0)
				draw_line(enemy.pos-Vector2(40,0),enemy.pos+Vector2(40,0),Color("59617a"),1)
				Motion.draw(self,enemy,mission,Vector2.ZERO,1.0,false,death)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="):
			output = arg.trim_prefix("--output=")
	call_deferred("capture")

func capture() -> void:
	root.content_scale_size = Vector2i(1200,690)
	root.size = Vector2i(1200,690)
	var canvas := PoseCanvas.new()
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	root.add_child(canvas)
	for n in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	if not output.is_empty():
		var result := root.get_texture().get_image().save_png(output)
		if result != OK:
			push_error("Enemy pose capture failed")
			quit(1)
			return
	print("Enemy animation contact sheet: walk, anticipation, strike, buckle, dissolve")
	quit()
