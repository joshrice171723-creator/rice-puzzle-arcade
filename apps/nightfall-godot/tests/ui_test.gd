extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("verify_layout")

func verify_layout() -> void:
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	# Exercise the largest menu without requesting an ad in a UI layout test.
	arena.ad_bridge = RefCounted.new()
	arena.ad_status = "Consent request failed. Check your connection and try again."
	for window_size in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 760)]:
		root.size = window_size
		arena.last_screen = ""
		arena.update_modal()
		for frame in 8:
			await process_frame
		var bounds := root.get_visible_rect()
		for control in [arena.modal, arena.dodge_button, arena.build_button, arena.pause_button]:
			checks += 1
			if not bounds.encloses(control.get_global_rect()):
				failures += 1
				push_error("Control outside viewport %s: %s / %s" % [window_size, control.get_global_rect(), bounds])
		arena.run.paused = false
		arena.run.phase = "upgrade"
		arena.update_modal()
		for frame in 8:
			await process_frame
		checks += 1
		if not bounds.encloses(arena.modal.get_global_rect()):
			failures += 1
			push_error("Upgrade menu outside viewport")
		arena.run.paused = true
		arena.run.phase = "boss"
		arena.run.level = 12
		for frame in 8:
			await process_frame
		checks += 1
		var header: Control = arena.hud_root
		if not bounds.encloses(header.get_global_rect()):
			failures += 1
			push_error("Boss header outside viewport: %s" % header.get_global_rect())
		arena.run.phase = "waves"
	arena.run.start_boss_practice()
	arena.run.phase = "victory"
	arena.replay()
	checks += 1
	if not arena.run.practice or arena.run.phase != "boss" or arena.run.health != arena.profile.stats().hp:
		failures += 1
		push_error("Practice replay must restart with full health from equipped gear")
	print("Nightfall layout: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
