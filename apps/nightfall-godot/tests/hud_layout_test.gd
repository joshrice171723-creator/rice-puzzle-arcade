extends SceneTree

var checks := 0
var failures := 0

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

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
	arena.run.configure(1, arena.profile.stats())
	arena.run.elapsed = 135
	arena.run.level = 7
	arena.run.xp = 20
	arena.run.spells = {"ember": {"rank": 1, "wait": 0.0}, "frost": {"rank": 2, "wait": 3.0}, "wisp": {"rank": 3, "wait": 0.0}}
	for size_value in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 760)]:
		root.size = size_value
		arena.run.phase = "waves"
		arena.run.paused = false
		arena.last_screen = ""
		await settle()
		check(not arena.modal.visible, "Normal combat has no help or pause card blocking the arena")
		check(not arena.hud_root is PanelContainer and arena.hud_root.size.y <= 88, "Header is a compact transparent overlay")
		check(arena.hud.text == "01:45" and arena.level_label.text == "Lv. 7", "Timer and combat level occupy separate readable labels")
		check(arena.xp_bar.size.y <= 10 and arena.health_bar.size.y <= 7 and arena.boss_bar.size.y <= 7, "Live-themed meters stay thin instead of expanding into cards")
		check(arena.power_hud.get_global_rect().end.y <= 148, "Selected abilities stay directly below XP and leave the center clear")
		check(not arena.metrics.visible, "Debug and wave text do not clutter normal combat")
		for control in [arena.hud_root, arena.power_hud, arena.pause_button, arena.pack_button, arena.build_button, arena.dodge_button]:
			check(root.get_visible_rect().encloses(control.get_global_rect()), "Combat controls remain inside the phone screen")
		for position in [Vector2(135, 135), Vector2(600, 600), Vector2(1065, 1065)]:
			arena.run.player = position
			await settle()
			var health_rect: Rect2 = arena.health_bar.get_global_rect()
			check(health_rect.position.y > arena.power_hud.get_global_rect().end.y + 20, "Hero health stays below the ability strip at arena edges")
			check(root.get_visible_rect().encloses(health_rect) and health_rect.end.y < 620, "Hero health remains on-screen and above bottom controls")
		arena.pause_button.pressed.emit()
		await settle()
		check(arena.modal.visible and arena.modal_title.text == "Paused" and arena.modal.size.y <= 300, "Pause opens a compact deliberate menu")
		check(not is_instance_valid(arena.ad_label), "Internal ad diagnostics are absent from the ordinary pause menu")
		arena.run.paused = false
		arena.last_screen = ""
		await settle()
		check(not arena.modal.visible, "Resuming removes the pause card completely")
	arena.queue_free()
	await process_frame
	print("Nightfall compact HUD: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
