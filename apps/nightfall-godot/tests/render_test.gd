extends SceneTree

func _initialize() -> void:
	call_deferred("verify_batches")

func verify_batches() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Render check requires a graphics window; do not run headless.")
		quit(1)
		return
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
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
	var baseline_ok := calls > 0 and calls <= 60
	arena.run.benchmark_count = 0
	arena.run.mission = 1
	arena.home.hide()
	for n in arena.run.enemies.size():
		arena.run.enemies[n].kind = ["drifter","runner","spitter"][n % 3]
	for frame in 10:
		await RenderingServer.frame_post_draw
	print("Mission One without hits: ", int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	for n in 12:
		arena.run.add_feedback("hit",Vector2(450 + n * 20,500),Vector2.RIGHT,12)
	for frame in 10:
		await RenderingServer.frame_post_draw
	calls = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	print("Mission One render: 120 authored enemies + 40 pickups + 12 hits, %d draw calls (budget 100)" % calls)
	quit(0 if baseline_ok and calls > 0 and calls <= 100 else 1)
