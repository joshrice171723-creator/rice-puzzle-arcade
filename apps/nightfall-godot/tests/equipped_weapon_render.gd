extends SceneTree
const Hero = preload("res://hero_cast.gd")
const Weapon = preload("res://equipped_weapon_art.gd")
const Run = preload("res://run.gd")
var failures := 0
var checks := 0
var viewport: SubViewport
class Board extends Node2D:
	var age := 0.07
	var face := 1.0
	var sequence := false
	func _draw() -> void:
		draw_rect(Rect2(0,0,1200,920),Color("101c36"))
		var font := ThemeDB.fallback_font
		for index in get_child_count():
			get_child(index).visible = not sequence or index < 18
		for row in (3 if sequence else 4):
			var character: String = ["scavenger","engineer","warden","arcanist"][row]
			for col in (6 if sequence else 5):
				var weapon: String = "pistol" if sequence else ["pistol","scattergun","crossbow","wand","sabre"][col]
				var shown_age := age
				if sequence:
					weapon = ["pistol","scattergun","crossbow"][row]
					character = "scavenger"
					shown_age = [0.0,0.02,0.05,0.10,0.16,0.24][col]
				var origin := Vector2(col*240+120,row*230+200)
				if sequence:
					origin.x = col*200+90
				draw_string(font,Vector2(col*(200 if sequence else 240)+20,row*230+24),weapon+" / %.2fs" % shown_age if sequence else character+" / "+weapon,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("b7d4f5"))
				# Child canvases preserve the same draw transforms as the arena.
				var probe: Node2D = get_child(row*(6 if sequence else 5)+col)
				probe.position = origin
				probe.scale = Vector2.ONE*2.1
				probe.set_meta("character",character)
				probe.set_meta("weapon",weapon)
				probe.set_meta("age",shown_age)
				probe.set_meta("moving",not sequence)
				probe.set_meta("face",face)
				probe.queue_redraw()
class Actor extends Node2D:
	func _draw() -> void:
		var weapon: String = get_meta("weapon","pistol")
		var face: float = get_meta("face",1.0)
		var age: float = get_meta("age",0.07)
		Hero.draw_motion(self,Vector2.ZERO,Vector2.ZERO,face,age,age*9,0.7 if get_meta("moving",true) else 0.0,age,0,false,false,get_meta("character","scavenger"),0,weapon,weapon,Vector2(face,0),age)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func capture(board: Node2D) -> Image:
	board.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1200,920)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	check(Weapon.kick("scattergun",0)>Weapon.kick("pistol",0) and Weapon.kick("pistol",0)>Weapon.kick("crossbow",0),"Weapon impulses reflect shotgun mass and the crossbow's low kick")
	for family in ["pistol","scattergun","crossbow"]:
		check(Weapon.kick(family,0)>Weapon.kick(family,0.03) and Weapon.kick(family,0.03)>Weapon.kick(family,0.12) and Weapon.kick(family,0.24)==0,"Recoil settles smoothly without a repeated body oscillation")
		var foot := Vector2(0.5,0.99)
		check(Hero.deform_point(foot,Vector2(58,80),0,0,0,0,0,family)==Hero.deform_point(foot,Vector2(58,80),0,0,0,0.16,0,family),"Weapon firing keeps the feet planted")
		check(Hero.hand_offset(family,Vector2.RIGHT,0).x<Hero.hand_offset(family,Vector2.RIGHT,0.24).x,"The forearm absorbs backward recoil along the aim axis")
	for family in Weapon.SPECS:
		for facing in [Vector2.RIGHT,Vector2.LEFT,Vector2.UP,Vector2.DOWN]:
			for age in [0.0,0.07,0.16,0.24,1.0]:
				var hand := Vector2(13,-35)
				var mount := Weapon.mount(family,hand,facing,age,true)
				check((mount*Weapon.SPECS[family].grip).distance_to(hand)<0.001,"Grip stays anchored through recoil, swing and every aim direction")
				if age>=0.24:
					var axis: Vector2 = (mount*Weapon.SPECS[family].tip-hand).normalized()
					check(axis.dot(facing)>0.999,"Weapon artwork aims along actual projectile direction")
	var run := Run.new()
	run.add_vfx("weapon_cast",run.player,Vector2.LEFT,0.24)
	run.vfx_events.back().weapon = "scattergun"
	run.add_vfx("spell_cast",run.player,Vector2.UP,0.30)
	run.vfx_events.back().spell = "frost"
	check(Hero.pose(run).direction==Vector2.UP and Hero.weapon_pose(run).direction==Vector2.LEFT,"Concurrent spell gesture cannot redirect the equipped gun")
	run.vfx_events[0].life = 0
	check(Hero.weapon_pose(run).age==99.0 and Hero.weapon_pose(run).direction==run.facing,"Expired attacks stop recoil and muzzle animation")
	if DisplayServer.get_name()=="headless":
		finish()
		return
	var board := Board.new()
	board.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	for n in 20:
		board.add_child(Actor.new())
	viewport.add_child(board)
	var image: Image = await capture(board)
	var output := ProjectSettings.globalize_path("res://../../artifacts/nightfall-godot/completion-pass/")
	DirAccess.make_dir_recursive_absolute(output)
	image.save_png(output+"equipped-weapons-right.png")
	board.age = 0.15
	var moved: Image = await capture(board)
	check(image.get_data()!=moved.get_data(),"Visible body and held weapon move continuously")
	board.face = -1
	var mirrored: Image = await capture(board)
	mirrored.save_png(output+"equipped-weapons-left.png")
	check(mirrored.get_data()!=moved.get_data(),"Left facing changes rendered body and equipment")
	board.face = 1
	board.sequence = true
	var sequence: Image = await capture(board)
	sequence.save_png(output+"gun-action-sequence.png")
	finish()
func finish() -> void:
	print("Nightfall equipped weapon render: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
