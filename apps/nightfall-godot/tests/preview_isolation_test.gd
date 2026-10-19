extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	var arena = load("res://main.tscn").instantiate()
	root.add_child(arena)
	await process_frame
	check(arena.testing and arena.vfx_preview != null,"Preview explicitly runs a disposable journey")
	check(arena.profile.path == "user://vfx-preview-profile.json","Preview UI profile has a different save destination")
	check(arena.home.profile == arena.profile,"Home callbacks retain the isolated profile")
	if "--combat-contract" in OS.get_cmdline_user_args():
		check(arena.profile.data.active_attempt.get("mode","")=="salvage" and arena.run.target_weapon=="crossbow","Contract review uses a real attempt only in its disposable profile")
	else:
		check(arena.attempt_id == 0 and arena.profile.data.active_attempt.is_empty(),"Fixture cannot become an owned campaign attempt")
	arena.show_haven()
	check(arena.home.visible,"Preview can return to home safely")
	check(arena.profile.path != "user://haven.json","Home navigation cannot switch back to the real save")
	arena.vfx_preview.set_process(false)
	arena.queue_free()
	await process_frame
	print("Nightfall preview isolation: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
