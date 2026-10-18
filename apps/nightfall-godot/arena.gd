extends Node2D

const Run = preload("res://run.gd")
const ACTORS = preload("res://assets/actors.png")
const FLOOR = preload("res://assets/courtyard.png")
const SHADOW = preload("res://assets/shadow.svg")
const EXPERIENCE = preload("res://assets/experience.svg")
const INK := Color("101a32")
const GOLD := Color("ffd27c")
const VIOLET := Color("ba92ff")
var run = Run.new()
var world_offset := Vector2.ZERO
var stick := Vector2.ZERO
var stick_origin := Vector2(88, 650)
var touch_id := -1
var mouse_stick := false
var moving := false
var anim_time := 0.0
var hud: Label
var health_bar: ProgressBar
var xp_bar: ProgressBar
var metrics: Label
var dodge_button: Button
var pulse_button: Button
var pause_button: Button
var modal: PanelContainer
var modal_body: VBoxContainer
var modal_title: Label
var last_screen := ""
var frames: Array[float] = []
var sample_time := 0.0
var physics_ms := 0.0
var screenshot_path := ""
var benchmark_seconds := 0.0
var benchmark_elapsed := 0.0
var report_path := ""
var measured_frames: Array[float] = []
var automated := false
var ad_status := "Android sample-ad bridge unavailable on this platform."
var ad_rewards := 0
var ad_label: Label
var ad_bridge: Object

func _ready() -> void:
	if Engine.has_singleton("NightfallAds"):
		ad_bridge = Engine.get_singleton("NightfallAds")
		ad_status = "Google sample ads only • rewards: 0"
		ad_bridge.connect("ad_state", func(value: String): ad_status = value; refresh_ad_label())
		ad_bridge.connect("reward_earned", func(): ad_rewards += 1; refresh_ad_label())
	build_ui()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--crowd="):
			run.set_benchmark(int(arg.get_slice("=", 1)))
		elif arg.begins_with("--seconds="):
			benchmark_seconds = float(arg.get_slice("=", 1))
		elif arg.begins_with("--report="):
			report_path = arg.trim_prefix("--report=")
		elif arg.begins_with("--capture="):
			screenshot_path = arg.trim_prefix("--capture=")
		elif arg == "--autoplay":
			automated = true
	if benchmark_seconds == 0.0 and run.benchmark_count == 0:
		run.paused = true
	update_modal()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		if benchmark_seconds <= 0.0:
			run.paused = true
			clear_input()

func panel_style(color: Color, border: Color = Color("34456d")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(14)
	return style

func make_button(text_value: String, callback: Callable, parent: Node, height: float = 48) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size.y = height
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("f5e9d8"))
	button.add_theme_stylebox_override("normal", panel_style(INK))
	button.add_theme_stylebox_override("hover", panel_style(Color("24365c"), GOLD))
	button.add_theme_stylebox_override("pressed", panel_style(Color("43355e"), VIOLET))
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var top := PanelContainer.new()
	top.position = Vector2(12, 12)
	top.size = Vector2(406, 106)
	top.add_theme_stylebox_override("panel", panel_style(Color(0.04, 0.065, 0.13, 0.94)))
	layer.add_child(top)
	var box := VBoxContainer.new()
	top.add_child(box)
	hud = Label.new()
	hud.add_theme_font_size_override("font_size", 19)
	hud.add_theme_color_override("font_color", GOLD)
	box.add_child(hud)
	health_bar = ProgressBar.new()
	health_bar.max_value = 120
	health_bar.custom_minimum_size.y = 12
	health_bar.show_percentage = false
	var hp_style := StyleBoxFlat.new()
	hp_style.bg_color = Color("dd697e")
	hp_style.set_corner_radius_all(5)
	health_bar.add_theme_stylebox_override("fill", hp_style)
	box.add_child(health_bar)
	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size.y = 5
	xp_bar.show_percentage = false
	var xp_style := StyleBoxFlat.new()
	xp_style.bg_color = VIOLET
	xp_bar.add_theme_stylebox_override("fill", xp_style)
	box.add_child(xp_bar)
	metrics = Label.new()
	metrics.position = Vector2(16, 124)
	metrics.add_theme_font_size_override("font_size", 12)
	metrics.add_theme_color_override("font_color", Color("d9def0"))
	layer.add_child(metrics)
	pause_button = make_button("II", func(): run.paused = not run.paused; clear_input(), layer, 44)
	pause_button.position = Vector2(366, 157)
	pause_button.size.x = 48
	pulse_button = make_button("PULSE", func(): run.pulse(), layer, 64)
	pulse_button.position = Vector2(250, 600)
	pulse_button.size.x = 78
	dodge_button = make_button("DODGE", func(): run.dodge(), layer, 64)
	dodge_button.position = Vector2(330, 668)
	dodge_button.size.x = 88
	var footer := Label.new()
	footer.text = "NIGHTFALL  /  ENGINE PROOF  •  WASD / touch"
	footer.position = Vector2(14, 738)
	footer.add_theme_font_size_override("font_size", 11)
	layer.add_child(footer)
	modal = PanelContainer.new()
	modal.position = Vector2(28, 204)
	modal.size = Vector2(374, 0)
	modal.add_theme_stylebox_override("panel", panel_style(Color("111b34"), Color("8d72b3")))
	layer.add_child(modal)
	modal_body = VBoxContainer.new()
	modal_body.add_theme_constant_override("separation", 10)
	modal.add_child(modal_body)
	modal_title = Label.new()
	modal_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	modal_title.add_theme_font_size_override("font_size", 22)
	modal_title.add_theme_color_override("font_color", GOLD)
	modal_body.add_child(modal_title)
	modal_body.minimum_size_changed.connect(func(): fit_modal.call_deferred())

func fit_modal() -> void:
	var minimum := modal.get_combined_minimum_size()
	modal.size.y = minimum.y
	modal.position.y = maxf(12.0, (760.0 - minimum.y) / 2.0)

func clear_input() -> void:
	touch_id = -1
	mouse_stick = false
	stick = Vector2.ZERO

func refresh_ad_label() -> void:
	if is_instance_valid(ad_label):
		ad_label.text = "%s\nEarned callbacks: %d" % [ad_status.left(140), ad_rewards]

func update_modal() -> void:
	var screen: String = "pause" if run.paused else run.phase
	if screen == last_screen:
		return
	last_screen = screen
	modal.visible = screen in ["pause", "upgrade", "victory", "defeat"]
	if not modal.visible:
		return
	clear_input()
	for child in modal_body.get_children():
		if child != modal_title:
			modal_body.remove_child(child)
			child.queue_free()
	modal.size.y = 0
	match screen:
		"pause":
			modal_title.text = "Nightfall\nBlackout District"
			var description := Label.new()
			description.text = "Survive the waves. Defeat the boss.\nMove: WASD / drag left side\nDodge: Space  •  Pulse: E\nPrototype — progress is not saved."
			description.add_theme_font_size_override("font_size", 14)
			modal_body.add_child(description)
			make_button("Enter courtyard" if run.elapsed == 0.0 else "Resume", func(): run.paused = false, modal_body)
			var row := HBoxContainer.new()
			modal_body.add_child(row)
			for count in [30, 60, 120]:
				var b := make_button("%d foes" % count, func(): run.set_benchmark(count); run.paused = false, row)
				b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			make_button("New survival run", restart, modal_body)
			if ad_bridge:
				make_button("Test rewarded video", func(): ad_bridge.testRewarded(), modal_body)
				make_button("Ad privacy options", func(): ad_bridge.privacyOptions(), modal_body, 40)
			ad_label = Label.new()
			ad_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ad_label.add_theme_font_size_override("font_size", 12)
			modal_body.add_child(ad_label)
			refresh_ad_label()
		"upgrade":
			modal_title.text = "Level %d • Choose a boost" % run.level
			make_button("Rune rounds  •  +4 damage", func(): run.upgrade(0), modal_body)
			make_button("Quick chamber  •  faster fire", func(): run.upgrade(1), modal_body)
			make_button("Field dressing  •  heal 35 HP", func(): run.upgrade(2), modal_body)
		"victory", "defeat":
			modal_title.text = "Boss defeated" if screen == "victory" else "The night claimed you"
			var result := Label.new()
			result.text = "%d enemies defeated • Level %d\n%.0f seconds survived" % [run.kills, run.level, run.elapsed]
			modal_body.add_child(result)
			make_button("Try again", restart, modal_body)

func restart() -> void:
	run = Run.new()
	frames.clear()
	clear_input()

func _input(event: InputEvent) -> void:
	# Release the stick even when a drag ends over a GUI button.
	if event is InputEventScreenTouch and not event.pressed and event.index == touch_id:
		clear_input()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		clear_input()
	elif event is InputEventScreenDrag and event.index == touch_id:
		stick = ((event.position - stick_origin) / 50.0).limit_length()
	elif event is InputEventMouseMotion and mouse_stick:
		stick = ((event.position - stick_origin) / 50.0).limit_length()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			run.paused = not run.paused
			clear_input()
		elif event.keycode == KEY_SPACE:
			run.dodge()
		elif event.keycode == KEY_E:
			run.pulse()
	if run.paused or run.phase not in ["waves", "boss"]:
		return
	if event is InputEventScreenTouch:
		if event.pressed and event.position.x < 230 and event.position.y > 220 and touch_id == -1:
			touch_id = event.index
			stick_origin = event.position
		elif not event.pressed and event.index == touch_id:
			clear_input()
	elif event is InputEventScreenDrag and event.index == touch_id:
		stick = ((event.position - stick_origin) / 50.0).limit_length()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and event.position.x < 230 and event.position.y > 220:
			mouse_stick = true
			stick_origin = event.position
		elif not event.pressed:
			clear_input()
	elif event is InputEventMouseMotion and mouse_stick:
		stick = ((event.position - stick_origin) / 50.0).limit_length()

func _physics_process(delta: float) -> void:
	var direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if direction == Vector2.ZERO:
		direction = stick
	if automated:
		direction = Vector2.from_angle(run.elapsed * 0.7)
		if run.phase == "upgrade":
			run.upgrade(0)
	moving = direction.length_squared() > 0.01
	var start := Time.get_ticks_usec()
	run.tick(delta, direction)
	physics_ms = maxf(physics_ms, (Time.get_ticks_usec() - start) / 1000.0)

func _process(delta: float) -> void:
	if not run.paused and run.phase in ["waves", "boss"]:
		anim_time += delta
	world_offset = Vector2(215, 380) - run.player.clamp(Vector2(215, 380), Vector2(985, 820))
	health_bar.value = run.health
	xp_bar.max_value = run.level * 5
	xp_bar.value = run.xp
	var remaining := maxi(0, int(ceil(Run.DURATION - run.elapsed)))
	var time_text := "%02d:%02d" % [remaining / 60, remaining % 60]
	if run.phase == "boss":
		time_text = "DEFEAT THE BOSS"
	if run.benchmark_count > 0:
		time_text = "CROWD TEST"
	hud.text = "%s  •  Lv %d   |   %d HP" % [time_text, run.level, run.health]
	dodge_button.text = "%.1fs" % run.dodge_wait if run.dodge_wait > 0 else "DODGE"
	pulse_button.text = "%.1fs" % run.pulse_wait if run.pulse_wait > 0 else "PULSE"
	frames.append(delta * 1000.0)
	if frames.size() > 300:
		frames.pop_front()
	sample_time += delta
	if sample_time >= 0.5:
		var sorted := frames.duplicate()
		sorted.sort()
		metrics.text = "%d FPS  •  p95 %.1f ms  •  %d enemies\nPhysics peak %.2f ms  •  %d shots  •  %d defeated" % [Engine.get_frames_per_second(), sorted[int((sorted.size() - 1) * 0.95)], run.enemies.size(), physics_ms, run.shots.size(), run.kills]
		sample_time = 0.0
		physics_ms = 0.0
	update_modal()
	queue_redraw()
	benchmark_elapsed += delta
	if benchmark_seconds > 0.0 and benchmark_elapsed > 3.0:
		measured_frames.append(delta * 1000.0)
	if not screenshot_path.is_empty() and benchmark_elapsed >= 4.0:
		var destination := screenshot_path
		screenshot_path = ""
		capture_frame(destination)
	if benchmark_seconds > 0.0 and benchmark_elapsed >= benchmark_seconds:
		finish_report()

func capture_frame(destination: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(destination)

func finish_report() -> void:
	measured_frames.sort()
	var total := 0.0
	for value in measured_frames:
		total += value
	var report := {"engine": Engine.get_version_info().string, "renderer": RenderingServer.get_current_rendering_method(), "os": OS.get_name(), "seconds": benchmark_elapsed, "frames": measured_frames.size(), "mean_fps": 1000.0 * measured_frames.size() / maxf(1.0, total), "p95_ms": measured_frames[int((measured_frames.size() - 1) * 0.95)] if not measured_frames.is_empty() else 0, "enemies": run.enemies.size(), "shots": run.shots.size(), "memory_mb": OS.get_static_memory_usage() / 1048576.0, "automated": automated}
	print(JSON.stringify(report))
	if not report_path.is_empty():
		var file := FileAccess.open(report_path, FileAccess.WRITE)
		if file:
			file.store_string(JSON.stringify(report, "\t"))
	get_tree().quit()

func actor(pos: Vector2, enemy: bool, frame: int, scale_value: float, face: float = 1.0) -> void:
	# Generated atlas rows have different occupied bounds; exclude neighboring feet.
	var width := ACTORS.get_width() / 4.0
	var source := Rect2(frame * width, 535 if enemy else 20, width, 315 if enemy else 480)
	var size := Vector2(72, 52 if enemy else 80) * scale_value
	var at := pos + world_offset
	var rect := Rect2(at - Vector2(size.x / 2.0, size.y * 0.93), size)
	if face < 0:
		rect.position.x += rect.size.x
		rect.size.x = -rect.size.x
	draw_texture_rect_region(ACTORS, rect, source)

func _draw() -> void:
	draw_texture_rect(FLOOR, Rect2(world_offset, Vector2(1200, 1200)), false)
	for pickup in run.pickups:
		var at: Vector2 = pickup + world_offset
		draw_texture_rect(EXPERIENCE, Rect2(at - Vector2(6, 6), Vector2(12, 12)), false)
	for enemy in run.enemies:
		if enemy.tell > 0:
			var at: Vector2 = enemy.target + world_offset
			draw_circle(at, 72, Color(1, 0.25, 0.35, 0.15))
			draw_arc(at, 72, 0, TAU * (1.0 - enemy.tell), 48, Color("ff7181"), 3)
	var actors: Array[Dictionary] = []
	for enemy in run.enemies:
		actors.append(enemy)
	actors.append({"pos": run.player, "player": true})
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.pos.y < b.pos.y)
	# Consecutive shared textures batch; per-actor polygons/transforms do not.
	for item in actors:
		var scale_value := 1.0 if item.has("player") else (1.7 if item.boss else 0.8)
		var size := Vector2(34, 12.92) * scale_value
		draw_texture_rect(SHADOW, Rect2(item.pos + world_offset - size / 2, size), false)
	for item in actors:
		if item.has("player"):
			actor(run.player, false, int(anim_time * 8) % 4 if moving else 1, 1.0, -1.0 if run.facing.x < 0 else 1.0)
		else:
			actor(item.pos, true, (int(anim_time * 7) + item.id) % 4, 1.7 if item.boss else 0.8, item.face)
	for item in run.enemies:
		if item.hp < item.max_hp or item.boss:
			var at: Vector2 = item.pos + world_offset - Vector2(20, 57 if item.boss else 38)
			draw_rect(Rect2(at, Vector2(40, 4)), INK)
			draw_rect(Rect2(at, Vector2(40 * item.hp / item.max_hp, 4)), Color("e36d86"))
	for shot in run.shots:
		var at: Vector2 = shot.pos + world_offset - Vector2(0, 18)
		draw_line(at - shot.velocity.normalized() * 13, at, GOLD, 3, true)
	if run.pulse_flash > 0:
		draw_arc(run.player + world_offset, 145 * (1.0 - run.pulse_flash / 0.35), 0, TAU, 64, VIOLET, 4, true)
	if run.hurt_wait > 0.55:
		draw_rect(Rect2(0, 0, 430, 760), Color(0.7, 0.05, 0.15, 0.08))
	var origin := stick_origin if touch_id >= 0 or mouse_stick else Vector2(88, 650)
	draw_circle(origin, 48, Color(0.04, 0.05, 0.1, 0.6))
	draw_arc(origin, 48, 0, TAU, 48, Color(0.8, 0.8, 0.95, 0.25), 2, true)
	draw_circle(origin + stick * 32, 22, Color(0.55, 0.58, 0.72, 0.55))
