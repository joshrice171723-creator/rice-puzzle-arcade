extends SceneTree
var destination := ""
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			destination = arg.trim_prefix("--capture-dir=")
	call_deferred("capture")
func screenshot(file: String) -> void:
	for tick in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(destination.path_join(file+".png")) == OK)
func capture() -> void:
	assert(not destination.is_empty())
	DirAccess.make_dir_recursive_absolute(destination)
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	var original: Dictionary = arena.profile.data.duplicate(true)
	for dimensions in [Vector2i(430,760),Vector2i(320,568)]:
		root.size = dimensions
		for id in ["scavenger","warden","arcanist","engineer"]:
			arena.home.inspected_class = id
			arena.home.navigate("class")
			await screenshot("class-"+id+"-%dx%d" % [dimensions.x,dimensions.y])
	root.size = Vector2i(430,760)
	arena.home.inspected_class = "arcanist"
	arena.home.navigate("class")
	await screenshot("motion-start")
	await create_timer(1.2).timeout
	await screenshot("motion-next")
	arena.profile.data.settings.reduced_effects = true
	arena.home.rebuild()
	await screenshot("reduced-effects")
	arena.profile.data.settings.reduced_effects = original.settings.reduced_effects
	assert(arena.profile.data == original and arena.attempt_id == 0)
	print("Class showcase: 11 disposable captures saved; player state unchanged")
	quit()
