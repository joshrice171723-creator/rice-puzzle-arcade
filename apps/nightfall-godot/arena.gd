extends Node2D

const Run = preload("res://run.gd")
const FieldUI = preload("res://field_ui.gd")
const Profile = preload("res://profile.gd")
const HavenUI = preload("res://haven_ui.gd")
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
var boss_bar: ProgressBar
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
var pack_button: Button
var pack_page := 0
var pending_discard := -1
var field_status: Label
var profile = Profile.new()
var home: Control
var testing := false
var attempt_id := 0
var checkpoint_wait := 0.0
var reward_receipt: Dictionary = {}
var diagnostics := false
var class_button: Button
var last_checkpoint_key := ""

func _ready() -> void:
	if not testing:
		profile.load_save()
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
	else:
		home.hide()
	update_modal()

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		if benchmark_seconds <= 0.0:
			run.paused = true
			clear_input()
			save_checkpoint()

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
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.custom_minimum_size.y = 10
	var boss_style := StyleBoxFlat.new()
	boss_style.bg_color = GOLD
	boss_bar.add_theme_stylebox_override("fill", boss_style)
	boss_bar.visible = false
	box.add_child(boss_bar)
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
	pack_button = make_button("PACK", func(): run.open_pack(), layer, 44)
	pack_button.position = Vector2(14, 552)
	pack_button.size.x = 90
	field_status = Label.new()
	field_status.position = Vector2(16, 205)
	field_status.size = Vector2(335, 65)
	field_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	field_status.add_theme_font_size_override("font_size", 13)
	field_status.add_theme_color_override("font_color", GOLD)
	layer.add_child(field_status)
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
	class_button = make_button("PHASE", func(): run.class_ability(), layer, 54)
	class_button.position = Vector2(330, 594)
	class_button.size.x = 88
	home = HavenUI.new()
	home.profile = profile
	home.mission_requested.connect(start_campaign)
	home.resume_requested.connect(resume_campaign)
	home.abandon_requested.connect(abandon_campaign)
	home.practice_requested.connect(begin_practice)
	home.diagnostics_requested.connect(begin_diagnostics)
	layer.add_child(home)
	if testing:
		home.hide()

func show_haven() -> void:
	run.paused = true
	clear_input()
	save_checkpoint()
	home.show()
	home.rebuild()
	modal.hide()
	last_screen = ""

func start_campaign(mission_number: int) -> void:
	var attempt: Dictionary = profile.start_attempt(mission_number)
	if attempt.is_empty():
		home.rebuild()
		return
	attempt_id = attempt.id
	run = Run.new(attempt.seed)
	run.configure(mission_number, profile.stats())
	reward_receipt = {}
	diagnostics = false
	checkpoint_wait = 0.0
	save_checkpoint()
	home.hide()
	last_screen = ""
	clear_input()

func resume_campaign() -> void:
	if profile.data.active_attempt.is_empty():
		return
	var attempt: Dictionary = profile.data.active_attempt
	var resumed = Run.new(attempt.seed)
	resumed.configure(attempt.mission, profile.stats())
	var snapshot: Dictionary = profile.saved_run()
	if not snapshot.is_empty() and not resumed.restore(snapshot):
		profile.error = "This expedition checkpoint is incompatible. End the expedition from Haven to start a new one."
		home.rebuild()
		return
	run = resumed
	run.paused = true
	attempt_id = attempt.id
	diagnostics = false
	reward_receipt = {}
	home.hide()
	last_screen = ""
	clear_input()

func abandon_campaign() -> void:
	if profile.data.active_attempt.is_empty():
		return
	var attempt: Dictionary = profile.data.active_attempt
	var abandoned = Run.new(attempt.seed)
	abandoned.configure(attempt.mission, profile.stats())
	var snapshot: Dictionary = profile.saved_run()
	if not snapshot.is_empty():
		abandoned.restore(snapshot)
	abandoned.phase = "defeat"
	var result: Dictionary = profile.finish_attempt(attempt.id, abandoned.result())
	if not result.is_empty():
		attempt_id = 0
		home.message = "Expedition ended. %d credits and protected loot returned to Haven." % result.credits
	home.rebuild()

func save_checkpoint() -> void:
	if testing or attempt_id == 0 or profile.data.active_attempt.is_empty():
		return
	if profile.checkpoint(run.snapshot()):
		last_checkpoint_key = run.phase + str(run.field.revision)

func begin_practice() -> void:
	attempt_id = 0
	diagnostics = false
	restart()
	run.start_boss_practice()
	home.hide()
	last_screen = ""

func begin_diagnostics() -> void:
	attempt_id = 0
	diagnostics = true
	restart()
	run.paused = true
	home.hide()
	last_screen = ""

func bank_result() -> void:
	if attempt_id > 0 and reward_receipt.is_empty():
		reward_receipt = profile.finish_attempt(attempt_id, run.result())
		if not reward_receipt.is_empty():
			attempt_id = 0

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
	if is_instance_valid(home) and home.visible:
		modal.hide()
		return
	var screen: String = "pause" if run.paused else run.phase
	var screen_key := screen + (str(run.field.revision) if screen in ["shrine", "pack"] else "")
	if screen_key == last_screen:
		return
	last_screen = screen_key
	modal.visible = screen in ["pause", "upgrade", "victory", "defeat", "shrine", "pack"]
	if not modal.visible:
		return
	clear_input()
	for child in modal_body.get_children():
		if child != modal_title:
			modal_body.remove_child(child)
			child.queue_free()
	modal.size.y = 0
	match screen:
		"shrine": FieldUI.shrine(self)
		"pack": FieldUI.pack(self)
		"pause":
			modal_title.text = "Nightfall\nBlackout Outskirts"
			var description := Label.new()
			description.text = "Survive the waves. Defeat %s.\nHold shrine rings to gain temporary powers.\nProtect valuable loot in your field pack.\nMove: WASD / drag left side\nDodge: Space  •  Ability: Q" % run.boss_name
			description.add_theme_font_size_override("font_size", 14)
			modal_body.add_child(description)
			make_button("Enter courtyard" if run.elapsed == 0.0 else "Resume", func(): run.paused = false, modal_body)
			make_button("Save & return to Haven", show_haven, modal_body)
			if diagnostics:
				var row := HBoxContainer.new()
				modal_body.add_child(row)
				for count in [30, 60, 120]:
					var b := make_button("%d foes" % count, func(): run.set_benchmark(count); run.paused = false, row)
					b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if ad_bridge and diagnostics:
				make_button("Test rewarded video", func(): ad_bridge.testRewarded(), modal_body)
				make_button("Ad privacy options", func(): ad_bridge.privacyOptions(), modal_body, 40)
			ad_label = Label.new()
			ad_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			ad_label.add_theme_font_size_override("font_size", 12)
			modal_body.add_child(ad_label)
			refresh_ad_label()
		"upgrade":
			modal_title.text = "Level %d • Choose your power" % run.level
			if run.offers.is_empty():
				run.make_offers()
			for index in run.offers.size():
				var offer: Dictionary = run.offers[index]
				make_button(offer.name, func(): run.choose_offer(index), modal_body)
				var description := Label.new()
				description.text = offer.description
				description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				description.add_theme_font_size_override("font_size", 13)
				modal_body.add_child(description)
		"victory", "defeat":
			bank_result()
			modal_title.text = "Boss defeated" if screen == "victory" else "The night claimed you"
			if run.practice:
				modal_title.text = "Practice complete" if screen == "victory" else "Practice • try another approach"
			var result := Label.new()
			result.text = "%d enemies defeated • Level %d\n%.0f seconds survived" % [run.kills, run.level, run.elapsed]
			modal_body.add_child(result)
			if not reward_receipt.is_empty():
				FieldUI.label(self, "Banked: %d credits • %d parts • %d gems\n+%d Survivor XP • +%d Mastery XP" % [reward_receipt.credits, reward_receipt.parts, reward_receipt.gems, reward_receipt.survivor_xp, reward_receipt.mastery_xp])
				if not reward_receipt.new_medals.is_empty():
					FieldUI.label(self, "New medals: " + ", ".join(reward_receipt.new_medals))
				if not reward_receipt.gear.is_empty():
					FieldUI.label(self, "Equipment: " + ", ".join(reward_receipt.gear))
				if reward_receipt.lost > 0:
					FieldUI.label(self, "%d unprotected loot bundles lost." % reward_receipt.lost)
			if attempt_id > 0:
				FieldUI.label(self, profile.error)
				make_button("Retry saving rewards", func(): last_screen = "", modal_body)
			else:
				make_button("Practice again" if run.practice else "Try again", replay, modal_body)
			make_button("Return to Haven", show_haven, modal_body)

func restart() -> void:
	run = Run.new()
	frames.clear()
	clear_input()

func replay() -> void:
	var repeat_practice: bool = run.practice
	if not repeat_practice and run.mission > 0:
		start_campaign(run.mission)
		return
	restart()
	if repeat_practice:
		run.start_boss_practice()

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
	if home.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			run.paused = not run.paused
			clear_input()
		elif event.keycode == KEY_SPACE:
			run.dodge()
		elif event.keycode == KEY_E:
			run.pulse()
		elif event.keycode == KEY_Q:
			run.class_ability()
		elif event.keycode == KEY_TAB:
			run.open_pack()
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
	if home.visible:
		return
	var direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if direction == Vector2.ZERO:
		direction = stick
	if automated:
		direction = Vector2.from_angle(run.elapsed * 0.7)
		if run.phase == "upgrade":
			run.choose_offer(0)
	moving = direction.length_squared() > 0.01
	var start := Time.get_ticks_usec()
	run.tick(delta, direction)
	physics_ms = maxf(physics_ms, (Time.get_ticks_usec() - start) / 1000.0)

func _process(delta: float) -> void:
	var in_field: bool = not home.visible
	for control in [hud.get_parent().get_parent(), metrics, dodge_button, pause_button]:
		control.visible = in_field
	pulse_button.visible = in_field and run.mission == 0
	class_button.visible = in_field and run.mission > 0
	class_button.text = "%.1fs" % run.class_wait if run.class_wait > 0 else ("PHASE" if run.class_id == "scavenger" else "REPAIR")
	if in_field and attempt_id > 0:
		checkpoint_wait += delta
		if checkpoint_wait >= 10.0 or (run.phase in ["upgrade", "shrine", "pack"] and last_checkpoint_key != run.phase + str(run.field.revision)):
			save_checkpoint()
			checkpoint_wait = 0.0
	if not run.paused and run.phase in ["waves", "boss"]:
		anim_time += delta
	world_offset = Vector2(215, 380) - run.player.clamp(Vector2(215, 380), Vector2(985, 820))
	health_bar.value = run.health
	health_bar.max_value = run.max_health()
	pack_button.visible = in_field and not run.practice and run.benchmark_count == 0
	pack_button.text = "PACK %d/%d" % [run.field.bag.size(), run.field.capacity]
	field_status.visible = in_field and not run.practice and run.benchmark_count == 0 and not modal.visible
	field_status.text = "%d scrap  •  %d credits  •  %d/3 relics\n%s" % [run.field.scrap, run.field.credits, run.field.relics.size(), run.field.notice]
	xp_bar.max_value = run.level * 5
	xp_bar.value = run.xp
	var remaining := maxi(0, int(ceil(run.duration - run.elapsed)))
	var time_text := "%02d:%02d" % [remaining / 60, remaining % 60]
	if run.phase == "boss":
		time_text = run.boss_name.to_upper()
	if run.benchmark_count > 0:
		time_text = "CROWD TEST"
	hud.text = "%s  •  Lv %d   |   %d HP" % [time_text, run.level, run.health]
	boss_bar.visible = run.boss_id >= 0 and run.phase not in ["victory", "defeat"]
	for enemy in run.enemies:
		if enemy.boss:
			boss_bar.max_value = enemy.max_hp
			boss_bar.value = enemy.hp
	dodge_button.text = "%.1fs" % run.dodge_wait if run.dodge_wait > 0 else "DODGE"
	pulse_button.text = "%.1fs" % run.pulse_wait if run.pulse_wait > 0 else "PULSE"
	frames.append(delta * 1000.0)
	if frames.size() > 300:
		frames.pop_front()
	sample_time += delta
	if sample_time >= 0.5:
		var sorted := frames.duplicate()
		sorted.sort()
		if run.benchmark_count > 0:
			metrics.text = "%d FPS  •  p95 %.1f ms  •  %d enemies\nPhysics peak %.2f ms  •  %d shots  •  %d defeated" % [Engine.get_frames_per_second(), sorted[int((sorted.size() - 1) * 0.95)], run.enemies.size(), physics_ms, run.shots.size(), run.kills]
		else:
			var learned: PackedStringArray = []
			for id: String in run.spells:
				learned.append("%s %d" % [Run.Content.SPELLS[id].name, run.spells[id].rank])
			metrics.text = "%s  •  %d defeated\n%s" % ["Defeat The Breaker" if run.boss_id >= 0 else Run.Content.wave_at(run.elapsed).name, run.kills, "  /  ".join(learned) if not learned.is_empty() else "Collect violet XP to learn magic"]
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

func actor(pos: Vector2, enemy: bool, frame: int, scale_value: float, face: float = 1.0, tint: Color = Color.WHITE) -> void:
	# Generated atlas rows have different occupied bounds; exclude neighboring feet.
	var width := ACTORS.get_width() / 4.0
	var source := Rect2(frame * width, 535 if enemy else 20, width, 315 if enemy else 480)
	var size := Vector2(72, 52 if enemy else 80) * scale_value
	var at := pos + world_offset
	var rect := Rect2(at - Vector2(size.x / 2.0, size.y * 0.93), size)
	if face < 0:
		rect.position.x += rect.size.x
		rect.size.x = -rect.size.x
	draw_texture_rect_region(ACTORS, rect, source, tint)

func _draw() -> void:
	draw_texture_rect(FLOOR, Rect2(world_offset, Vector2(1200, 1200)), false)
	if not run.practice and run.benchmark_count == 0:
		draw_field_sites()
	for pickup in run.pickups:
		var at: Vector2 = pickup + world_offset
		draw_texture_rect(EXPERIENCE, Rect2(at - Vector2(6, 6), Vector2(12, 12)), false)
	for enemy in run.enemies:
		if enemy.tell > 0:
			var at: Vector2 = enemy.target + world_offset
			var from: Vector2 = enemy.pos + world_offset
			if enemy.attack == "slam":
				draw_circle(at, 80, Color(1, 0.25, 0.35, 0.15))
				draw_arc(at, 80, 0, TAU * (1.0 - enemy.tell / 0.95), 48, Color("ff7181"), 3)
			else:
				var direction := from.direction_to(at)
				if enemy.attack == "rush":
					draw_line(from, from + direction * 234, Color(1, 0.3, 0.35, 0.22), 60)
					draw_line(from, from + direction * 234, Color("ff7181"), 2)
				else:
					for angle in ([-0.22, 0.0, 0.22] if enemy.attack == "toss" else [0.0]):
						draw_line(from, from + direction.rotated(angle) * 210, Color("ffad7c"), 2)
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
			var scale_value := 1.7 if item.boss else (0.65 if item.kind == "runner" else 0.8)
			var tint := Color("ffac87") if item.kind == "runner" else (Color("b6c8ff") if item.kind == "spitter" else Color.WHITE)
			actor(item.pos, true, (int(anim_time * 7) + item.id) % 4, scale_value, item.face, tint)
	for item in run.enemies:
		var mark: Vector2 = item.pos + world_offset - Vector2(0, 42)
		if item.kind == "runner":
			draw_polyline(PackedVector2Array([mark + Vector2(-5, 0), mark + Vector2(0, -5), mark + Vector2(5, 0)]), GOLD, 2)
		elif item.kind == "spitter":
			draw_arc(mark, 5, 0, TAU, 12, Color("adceff"), 2)
		if item.hp < item.max_hp or item.boss:
			var at: Vector2 = item.pos + world_offset - Vector2(20, 57 if item.boss else 38)
			draw_rect(Rect2(at, Vector2(40, 4)), INK)
			draw_rect(Rect2(at, Vector2(40 * item.hp / item.max_hp, 4)), Color("e36d86"))
	for shot in run.shots:
		var at: Vector2 = shot.pos + world_offset - Vector2(0, 18)
		draw_line(at - shot.velocity.normalized() * 13, at, Color("ff875e") if shot.get("kind", "pistol") == "ember" else GOLD, 5 if shot.get("kind", "pistol") == "ember" else 3, true)
	for shot in run.hostile_shots:
		var at: Vector2 = shot.pos + world_offset - Vector2(0, 18)
		draw_circle(at, 6, Color("ff7181"))
		draw_arc(at, 8, 0, TAU, 12, Color("ffe1b0"), 1)
	for effect in run.effects:
		var from: Vector2 = effect.from + world_offset
		var to: Vector2 = effect.to + world_offset
		var fade: float = effect.life / effect.duration
		match effect.kind:
			"chain": draw_line(from - Vector2(0, 18), to - Vector2(0, 18), Color(0.75, 0.6, 1, fade), 3)
			"frost": draw_arc(from, 150 * (1.0 - fade), 0, TAU, 48, Color(0.6, 0.85, 1, fade), 4)
			"ember": draw_circle(from - Vector2(0, 18), 12 * (1.0 - fade), Color(1, 0.4, 0.2, fade))
			"slam": draw_arc(from, 80, 0, TAU, 48, Color(1, 0.35, 0.4, fade), 5)
	if run.pulse_flash > 0:
		draw_arc(run.player + world_offset, 145 * (1.0 - run.pulse_flash / 0.35), 0, TAU, 64, VIOLET, 4, true)
	if run.hurt_wait > 0.55:
		draw_rect(Rect2(0, 0, 430, 760), Color(0.7, 0.05, 0.15, 0.08))
	var origin := stick_origin if touch_id >= 0 or mouse_stick else Vector2(88, 650)
	draw_circle(origin, 48, Color(0.04, 0.05, 0.1, 0.6))
	draw_arc(origin, 48, 0, TAU, 48, Color(0.8, 0.8, 0.95, 0.25), 2, true)
	draw_circle(origin + stick * 32, 22, Color(0.55, 0.58, 0.72, 0.55))

func draw_field_sites() -> void:
	for site in run.field.sites:
		var at: Vector2 = site.pos + world_offset
		var color := GOLD if site.kind in ["shop", "cache"] else VIOLET
		if site.opened or (site.kind == "relic" and run.field.relics.size() >= 3):
			color = Color("59637b")
		draw_circle(at, 29, Color("0b1023"))
		draw_arc(at, 29, 0, TAU, 24, color.darkened(0.4), 3)
		if not site.opened:
			draw_circle(at, Run.Field.RADIUS, Color(color, 0.06))
			draw_arc(at, Run.Field.RADIUS, 0, TAU, 48, Color(color, 0.28), 1)
		if site.progress > 0 and not site.opened:
			draw_arc(at, Run.Field.RADIUS, -PI / 2, -PI / 2 + TAU * site.progress / site.duration, 48, color, 4)
		if site.kind == "cache":
			draw_style_box(panel_style(Color("503b38"), color), Rect2(at - Vector2(20, 26), Vector2(40, 27)))
			draw_line(at - Vector2(20, 16), at + Vector2(20, -16), color, 2)
			draw_rect(Rect2(at - Vector2(3, 19), Vector2(6, 10)), color)
		elif site.kind == "shop":
			draw_rect(Rect2(at - Vector2(21, 22), Vector2(42, 13)), color.darkened(0.25))
			draw_rect(Rect2(at - Vector2(8, 9), Vector2(16, 13)), Color("8b87a3"))
			draw_line(at + Vector2(-10, -27), at + Vector2(8, -44), GOLD, 5)
			draw_line(at + Vector2(2, -47), at + Vector2(14, -35), GOLD, 9)
		else:
			for offset in [-12.0, 12.0]:
				var crystal := at + Vector2(offset, -25)
				draw_colored_polygon(PackedVector2Array([crystal + Vector2(0, -19), crystal + Vector2(9, 0), crystal + Vector2(0, 10), crystal + Vector2(-9, 0)]), color)
				draw_line(crystal + Vector2(0, -16), crystal + Vector2(0, 6), Color("f2dfff"), 2)
		if site.cooldown > 0:
			draw_arc(at, 34, -PI / 2, -PI / 2 + TAU * (1.0 - site.cooldown / 45.0), 32, Color("929bb4"), 2)
	for drop in run.field.drops:
		var at: Vector2 = drop.pos + world_offset
		draw_circle(at, 5, GOLD)
		draw_arc(at, 6, 0, TAU, 12, Color("fff2bf"), 1)
