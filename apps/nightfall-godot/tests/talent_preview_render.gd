extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	var destination := ProjectSettings.globalize_path("res://").path_join("../../artifacts/nightfall-godot/talent-preview").simplify_path()
	DirAccess.make_dir_recursive_absolute(destination)
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	var before: Dictionary = arena.profile.data.duplicate(true)
	for dimensions in [Vector2i(430,760),Vector2i(320,568)]:
		root.size=dimensions
		for id in ["scavenger","arcanist","warden","engineer"]:
			arena.home.inspected_class=id
			arena.home.navigate("talents")
			for tick in 6:
				await process_frame
			await RenderingServer.frame_post_draw
			assert(arena.home.body.get_global_rect().end.y <= arena.home.navigation.position.y)
			assert(root.get_texture().get_image().save_png(destination.path_join(id+"-%d.png" % dimensions.x))==OK)
	assert(arena.profile.data==before)
	print("Talent preview: 8 captures; player state unchanged")
	quit()
