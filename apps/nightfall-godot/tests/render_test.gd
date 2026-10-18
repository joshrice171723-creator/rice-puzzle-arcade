extends SceneTree

func _initialize() -> void:
	call_deferred("verify_batches")

func verify_batches() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Render check requires a graphics window; do not run headless.")
		quit(1)
		return
	var arena = load("res://main.tscn").instantiate()
	root.add_child(arena)
	arena.run.set_benchmark(120)
	arena.run.paused = false
	arena.set_physics_process(false)
	for index in 40:
		arena.run.pickups.append(Vector2(450 + (index % 8) * 40, 450 + (index / 8) * 40))
	for frame in 10:
		await RenderingServer.frame_post_draw
	var calls := int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("Nightfall render: 120 actors + 40 pickups, %d draw calls (budget 60)" % calls)
	quit(0 if calls > 0 and calls <= 60 else 1)
