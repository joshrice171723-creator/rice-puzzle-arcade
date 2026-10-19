extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("verify")

func settle() -> void:
	for frame in 6:
		await process_frame

func verify() -> void:
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.hide()
	arena.run.spells = {"frost": {"rank": 3, "wait": 2.0, "evolved": true}, "wisp": {"rank": 2, "wait": 0.0}, "ground": {"rank": 2, "wait": 6.0}}
	arena.run.passives = {"magnet": 3, "vital": 3, "channel": 2}
	arena.run.field.relics.assign(["obsidian", "lantern", "cinder"])
	for size_value in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 760)]:
		root.size = size_value
		arena.run.paused = false
		arena.run.phase = "waves"
		arena.power_view = false
		await settle()
		check(root.get_visible_rect().encloses(arena.power_hud.get_global_rect()), "Ability strip fits phone viewport")
		check(not arena.power_hud.get_global_rect().intersects(arena.pause_button.get_global_rect()), "Ability strip stays clear of pause")
		for slot in arena.power_hud.slots:
			check(slot.size.x >= 44 and slot.size.y >= 44, "Ability inspection has a finger-sized target")
		for icon in arena.power_hud.icons:
			check(icon.texture != null, "Chosen spell displays its generated artwork")
		check(arena.power_hud.ranks[0].text == "EVOLVED" and arena.power_hud.ranks[1].text == "◆◆◇", "Evolution and rank are readable without relying on color")
		arena.power_hud.slots[0].pressed.emit()
		check(arena.power_view and arena.run.paused, "Inspecting an ability pauses the simulation")
		for page in ["Attacks", "Passives", "Relics"]:
			arena.power_page = page
			arena.last_screen = ""
			arena.update_modal()
			await settle()
			check(root.get_visible_rect().encloses(arena.modal.get_global_rect()), "Full %s panel fits without scrolling" % page)
		var saved_time: float = arena.run.elapsed
		arena.run.tick(1.0, Vector2.RIGHT)
		check(arena.run.elapsed == saved_time, "Build inspection never advances the mission timer")
		arena.close_power_view()
		check(not arena.run.paused, "Closing an inspection resumes a previously active run")
		arena.run.paused = true
		arena.open_power_view()
		arena.close_power_view()
		check(arena.run.paused, "Closing inspection preserves an already paused run")
		arena.run.paused = false
		var before: float = arena.run.class_wait
		for key in [KEY_E, KEY_Q]:
			var event := InputEventKey.new()
			event.keycode = key
			event.pressed = true
			arena._unhandled_input(event)
		check(arena.run.class_wait == before and arena.run.pulse_flash == 0, "Old attack keys do not manually trigger abilities")
	# Optional rendered fixture: static state, no gameplay or real save interaction.
	arena.run.phase = "waves"
	arena.run.paused = false
	arena.power_view = false
	arena.last_screen = ""
	arena.run.zones.assign([{"pos": arena.run.player, "life": 3.0, "dps": 8.0, "radius": 90.0}])
	arena.run.elapsed = 72.0
	arena.run.level = 7
	arena.run.kills = 48
	for index in 8:
		arena.run.spawn_enemy()
		arena.run.enemies.back().pos = arena.run.player + Vector2.from_angle(index * TAU / 8) * 135
	await settle()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(arg.trim_prefix("--capture="))
	print("Nightfall ability HUD: %d checks, %d failures" % [checks, failures])
	arena.queue_free()
	await process_frame
	quit(1 if failures else 0)
