extends Node2D

const Shapes = preload("res://draw_shapes.gd")
const CombatEffects = preload("res://combat_effects.gd")
const WorldArt = preload("res://world_art.gd")
const Neighborhood = preload("res://neighborhood.gd")
const EnemyMotion = preload("res://enemy_motion.gd")
const CombatVFX = preload("res://combat_vfx.gd")
const HeroCast = preload("res://hero_cast.gd")
const Presentation = preload("res://mission_presentation.gd")
const Run = preload("res://run.gd")
const Cards = preload("res://reward_cards.gd")
const FieldUI = preload("res://field_ui.gd")
const Profile = preload("res://profile.gd")
const HavenUI = preload("res://haven_ui.gd")
const RewardFlow = preload("res://reward_flow.gd")
const Soundscape = preload("res://soundscape.gd")
const PowerHUD = preload("res://power_hud.gd")
const MenuSkin = preload("res://menu_skin.gd")
const MenuArt = preload("res://haven_art.gd")
const MENU_KEY = preload("res://assets/menu-key.svg")
const FLOOR = preload("res://assets/courtyard.png")
const SHADOW = preload("res://assets/shadow.svg")
const EXPERIENCE = preload("res://assets/experience.svg")
const PROPS = preload("res://assets/field-props.png")
const PROP_RECTS := [Rect2(0, 0, 440, 455), Rect2(455, 0, 435, 455), Rect2(915, 45, 390, 400), Rect2(1350, 0, 420, 455), Rect2(0, 475, 500, 410), Rect2(500, 475, 430, 410), Rect2(940, 520, 430, 350), Rect2(1430, 450, 330, 435)]
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
var hero_stride := 0.0
var hero_move_blend := 0.0
var hero_move_direction := Vector2.RIGHT
var hero_last_position := Run.World.CENTER
var field_was_visible := true
var hud_font_size := 30
var hud: Label
var hud_root: Control
var level_label: Label
var counters: VBoxContainer
var credit_count: Label
var kill_count: Label
var health_bar: ProgressBar
var xp_bar: ProgressBar
var boss_bar: ProgressBar
var metrics: Label
var dodge_button: Button
var pause_button: Button
var modal: PanelContainer
var modal_body: VBoxContainer
var modal_title: Label
var menu_shade: ColorRect
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
var last_checkpoint_key := ""
var build_button: Button
var reward_flow = RewardFlow.new()
var soundscape: Node
var previous_health := 0.0
var power_hud: Control
var power_view := false
var power_page := "Attacks"
var was_paused := false
var boss_warning: Label
var selected_power := ""
var help_view := false
var progress_view := false
var last_field_notice := ""
var notice_left := 0.0
var credit_drop: Texture2D = MenuArt.item("credits")
var draw_cpu_ms := 0.0
var draw_profile: Dictionary = {}
var vfx_preview: Node

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	HeroCast.LayeredRig.warmup(run.mission)
	var combat_requested := OS.is_debug_build() and ("--combat-preview" in OS.get_cmdline_user_args() or "--combat-campaign" in OS.get_cmdline_user_args() or "--combat-contract" in OS.get_cmdline_user_args() or FileAccess.file_exists("user://combat-preview.flag"))
	var preview_requested := OS.is_debug_build() and ("--vfx-preview" in OS.get_cmdline_user_args() or FileAccess.file_exists("user://vfx-preview.flag"))
	if preview_requested or combat_requested:
		testing = true
		profile = Profile.new("user://vfx-preview-profile.json")
	if not testing:
		profile.load_save()
	if Engine.has_singleton("NightfallAds"):
		ad_bridge = Engine.get_singleton("NightfallAds")
		ad_status = "Google sample ads only • rewards: 0"
		ad_bridge.connect("ad_state", func(value: String): ad_status = value; refresh_ad_label())
		ad_bridge.connect("reward_earned", func(): ad_rewards += 1; refresh_ad_label())
		ad_bridge.connect("reward_granted", earned_rescue)
		ad_bridge.connect("reward_finished", finished_rescue)
		ad_bridge.connect("reward_error", failed_rescue)
	build_ui()
	soundscape = Soundscape.new()
	add_child(soundscape)
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
	if preview_requested or combat_requested:
		vfx_preview = load("res://combat_preview.gd" if combat_requested else "res://vfx_preview.gd").new()
		vfx_preview.arena = self
		add_child(vfx_preview)

func _notification(what: int) -> void:
	if testing or vfx_preview != null:
		return # Automated debug recording owns its explicit pause/resume stage.
	if what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED]:
		if is_instance_valid(soundscape):
			soundscape.focused = false
		if benchmark_seconds <= 0.0:
			run.paused = true
			clear_input()
			save_checkpoint()
	elif what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED]:
		if is_instance_valid(soundscape):
			soundscape.focused = true

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
	hud_root = Control.new()
	hud_root.size = Vector2(430, 88)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)
	hud = Label.new()
	hud.position = Vector2(89, 9)
	hud.size = Vector2(252, 36)
	hud.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_theme_font_size_override("font_size", 30)
	hud.add_theme_color_override("font_color", Color("fff5e4"))
	hud.add_theme_color_override("font_outline_color", Color("101526"))
	hud.add_theme_constant_override("outline_size", 6)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(hud)
	level_label = Label.new()
	level_label.position = Vector2(140, 45)
	level_label.size = Vector2(150, 20)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 14)
	level_label.add_theme_color_override("font_outline_color", INK)
	level_label.add_theme_constant_override("outline_size", 5)
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(level_label)
	counters = VBoxContainer.new()
	counters.position = Vector2(325, 11)
	counters.size = Vector2(89, 44)
	counters.add_theme_constant_override("separation", 1)
	counters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_root.add_child(counters)
	for entry in [[MenuArt.item("credits"),"Credits collected"],[MenuArt.SWORD,"Enemies defeated"]]:
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 20
		row.tooltip_text = entry[1]
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		counters.add_child(row)
		var icon := TextureRect.new()
		icon.texture = entry[0]
		icon.custom_minimum_size = Vector2(20,20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(icon)
		var value := Label.new()
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value.add_theme_font_size_override("font_size",14)
		value.add_theme_color_override("font_color",GOLD)
		value.add_theme_color_override("font_outline_color",INK)
		value.add_theme_constant_override("outline_size",5)
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(value)
		if credit_count == null: credit_count = value
		else: kill_count = value
	health_bar = ProgressBar.new()
	health_bar.max_value = 120
	health_bar.size = Vector2(46, 6)
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hp_style := StyleBoxFlat.new()
	hp_style.bg_color = Color("8ce1ff")
	hp_style.set_corner_radius_all(2)
	health_bar.add_theme_stylebox_override("fill", hp_style)
	var bar_track := StyleBoxFlat.new()
	bar_track.bg_color = Color(0.025, 0.04, 0.08, 0.8)
	bar_track.set_corner_radius_all(2)
	health_bar.add_theme_stylebox_override("background", bar_track)
	health_bar.add_theme_font_size_override("font_size", 1)
	health_bar.size = Vector2(46, 6)
	layer.add_child(health_bar)
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(16, 68)
	xp_bar.size = Vector2(398, 9)
	xp_bar.show_percentage = false
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var xp_style := StyleBoxFlat.new()
	xp_style.bg_color = Color("9cd5ff")
	xp_style.set_corner_radius_all(2)
	xp_bar.add_theme_stylebox_override("fill", xp_style)
	xp_bar.add_theme_stylebox_override("background", bar_track)
	xp_bar.add_theme_font_size_override("font_size", 1)
	xp_bar.size = Vector2(398, 9)
	hud_root.add_child(xp_bar)
	boss_bar = ProgressBar.new()
	boss_bar.show_percentage = false
	boss_bar.position = Vector2(16, 81)
	boss_bar.size = Vector2(398, 6)
	boss_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var boss_style := StyleBoxFlat.new()
	boss_style.bg_color = Color("ed8a78")
	boss_style.set_corner_radius_all(2)
	boss_bar.add_theme_stylebox_override("fill", boss_style)
	boss_bar.add_theme_stylebox_override("background", bar_track)
	boss_bar.add_theme_font_size_override("font_size", 1)
	boss_bar.size = Vector2(398, 6)
	boss_bar.visible = false
	hud_root.add_child(boss_bar)
	metrics = Label.new()
	metrics.position = Vector2(16, 150)
	metrics.add_theme_font_size_override("font_size", 12)
	metrics.add_theme_color_override("font_color", Color("d9def0"))
	layer.add_child(metrics)
	power_hud = PowerHUD.new()
	power_hud.position = Vector2(16, 94)
	power_hud.size = Vector2(230, 54)
	power_hud.inspect_requested.connect(open_power_view)
	layer.add_child(power_hud)
	pause_button = make_button("II", func(): help_view = false; progress_view = false; run.paused = not run.paused; clear_input(), layer, 44)
	pause_button.position = Vector2(14, 12)
	pause_button.size.x = 48
	dodge_button = make_button("DODGE", func(): run.dodge(), layer, 64)
	dodge_button.position = Vector2(330, 655)
	dodge_button.size.x = 88
	pack_button = make_button("PACK", func(): run.open_pack(), layer, 44)
	pack_button.position = Vector2(128, 701)
	pack_button.size.x = 90
	build_button = make_button("BUILD", func(): run.open_build(), layer, 44)
	build_button.position = Vector2(228, 701)
	build_button.size.x = 84
	for control in [pause_button, pack_button, build_button, dodge_button]:
		MenuSkin.action(control, "gold" if control == dodge_button else "blue")
		control.add_theme_font_size_override("font_size", 13 if control != pause_button else 19)
	field_status = Label.new()
	field_status.position = Vector2(145, 637)
	field_status.size = Vector2(175, 58)
	field_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	field_status.add_theme_font_size_override("font_size", 12)
	field_status.add_theme_color_override("font_outline_color", INK)
	field_status.add_theme_constant_override("outline_size", 4)
	field_status.add_theme_color_override("font_color", GOLD)
	layer.add_child(field_status)
	boss_warning = Label.new()
	boss_warning.position = Vector2(15, 157)
	boss_warning.size = Vector2(400, 28)
	boss_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_warning.add_theme_font_size_override("font_size", 18)
	boss_warning.add_theme_color_override("font_color", GOLD)
	boss_warning.add_theme_color_override("font_outline_color", INK)
	boss_warning.add_theme_constant_override("outline_size", 6)
	layer.add_child(boss_warning)
	menu_shade = ColorRect.new()
	menu_shade.color = Color(0.015,0.025,0.075,0.68)
	menu_shade.size = Vector2(430,760)
	menu_shade.visible = false
	layer.add_child(menu_shade)
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
	home = HavenUI.new()
	home.profile = profile
	home.mission_requested.connect(start_campaign)
	home.resume_requested.connect(resume_campaign)
	home.abandon_requested.connect(abandon_campaign)
	home.practice_requested.connect(begin_practice)
	home.diagnostics_requested.connect(begin_diagnostics)
	home.contract_requested.connect(start_contract)
	home.ads_available = ad_bridge != null
	home.shop_video_requested.connect(func(token: String):
		if ad_bridge != null:
			ad_bridge.showRewarded(token)
		else:
			home.shop_failed(token, "Video unavailable on this platform."))
	home.shop_video_cancelled.connect(func(token: String):
		if ad_bridge != null:
			ad_bridge.cancelRewarded(token))
	layer.add_child(home)
	if testing:
		home.hide()

func show_haven() -> void:
	power_view = false
	run.paused = true
	clear_input()
	if not save_checkpoint():
		last_screen = ""
		update_modal()
		return
	home.show()
	home.rebuild()
	modal.hide()
	last_screen = ""

func start_campaign(mission_number: int) -> void:
	var attempt: Dictionary = profile.start_attempt(mission_number)
	activate_attempt(attempt)

func start_contract(slot: String, weapon_family: String = "pistol") -> void:
	var attempt: Dictionary = profile.start_contract(slot,weapon_family)
	activate_attempt(attempt)

func configured_run(attempt: Dictionary) -> RefCounted:
	var configured = Run.new(attempt.seed)
	if attempt.get("mode", "campaign") == "salvage":
		configured.configure_contract(profile.stats(), attempt.target_slot, attempt.get("target_weapon","pistol"))
	else:
		configured.configure(attempt.mission, profile.stats())
	HeroCast.LayeredRig.warmup(configured.mission)
	return configured

func activate_attempt(attempt: Dictionary) -> void:
	if attempt.is_empty():
		home.rebuild()
		return
	attempt_id = attempt.id
	run = configured_run(attempt)
	reward_flow = RewardFlow.new()
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
	var resumed = configured_run(attempt)
	var snapshot: Dictionary = profile.saved_run()
	if not snapshot.is_empty() and not resumed.restore(snapshot):
		profile.error = "This expedition checkpoint is incompatible. End the expedition from Haven to start a new one."
		home.rebuild()
		return
	run = resumed
	reward_flow = RewardFlow.new()
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
	var abandoned = configured_run(attempt)
	var snapshot: Dictionary = profile.saved_run()
	if not snapshot.is_empty():
		abandoned.restore(snapshot)
	if abandoned.phase != "victory":
		abandoned.phase = "defeat"
	var result: Dictionary = profile.finish_attempt(attempt.id, abandoned.result())
	if not result.is_empty():
		attempt_id = 0
		home.message = "Expedition ended. %d credits and protected loot returned to Haven." % result.credits
	home.rebuild()

func save_checkpoint() -> bool:
	if testing or attempt_id == 0 or profile.data.active_attempt.is_empty():
		return true
	if profile.checkpoint(run.snapshot()):
		last_checkpoint_key = run.phase + str(run.field.revision)
		return true
	return false

func begin_practice(mission: int = 1, build: String = "Balanced") -> void:
	if not profile.practice_unlocked(mission) or build not in home.Preparation.BUILDS:
		return
	attempt_id = 0
	diagnostics = false
	restart()
	run.configure(mission, profile.stats())
	HeroCast.LayeredRig.warmup(mission)
	run.start_boss_practice(home.Preparation.BUILDS[build])
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

func request_rescue() -> void:
	if ad_bridge == null:
		return
	var token: String = reward_flow.begin(attempt_id, run)
	if token.is_empty():
		return
	run.paused = false
	save_checkpoint()
	ad_bridge.showRewarded(token)
	last_screen = ""

func earned_rescue(token: String) -> void:
	if token.begins_with("shop-"):
		home.shop_earned(token)
		return
	if reward_flow.earned(token, attempt_id, run):
		save_checkpoint()
		last_screen = ""

func finished_rescue(token: String, _earned: bool) -> void:
	if token.begins_with("shop-"):
		home.shop_finished(token)
		return
	if reward_flow.finish(token):
		last_screen = ""

func failed_rescue(token: String, reason: String) -> void:
	if token.begins_with("shop-"):
		home.shop_failed(token, reason)
		return
	if reward_flow.fail(token, reason):
		last_screen = ""

func finish_to_haven() -> void:
	if attempt_id > 0 and run.phase in ["defeat", "victory"]:
		bank_result()
		if attempt_id > 0:
			last_screen = ""
			return
	show_haven()

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

func mission_progress() -> String:
	if run.practice:
		return "Defeat %s.\nPractice has no time limit and grants no loot or progression.\nTry different spell builds from the Training Yard." % run.boss_name
	if run.mode == "salvage":
		return "%s\nCaches opened: %d/3\nBeacon charge: %.1f/3 seconds\nGuaranteed equipment: %s\nExtract before the timer ends to keep your full pack." % [Run.Salvage.objective(run), mini(3, run.field.caches_opened), run.extract_progress, Run.Weapons.TYPES[run.target_weapon].name if run.target_slot == "weapon" else run.target_slot.capitalize()]
	var combat: String = "Still available" if run.damage_taken <= 8 and not run.rescued else "Missed this run"
	var collection: String = "Ready on victory" if run.field.caches_opened >= 3 else "Keep searching"
	return "Win: survive the waves, then defeat %s.\nThe boss fight has no second timer.\n\nCombat medal: %s\n%d damaging hits / maximum 8. No rescue.\n\nScavenger medal: %s\n%d/3 caches opened.\n\nExtra medals require a boss clear. Missing one does not block the next mission." % [run.boss_name, combat, run.damage_taken, collection, mini(3, run.field.caches_opened)]

func update_modal() -> void:
	if is_instance_valid(home) and home.visible:
		modal.hide()
		menu_shade.hide()
		return
	var screen: String = "ad" if not reward_flow.pending.is_empty() else ("powers" if power_view else ("pause" if run.paused and run.phase not in ["victory", "defeat"] else run.phase))
	var screen_key := screen + (str(run.field.revision) if screen in ["shrine", "pack"] else (str(run.build_revision) if screen == "build" else (str(run.offers.hash()) if screen == "upgrade" else "")))
	if screen_key == last_screen:
		return
	last_screen = screen_key
	modal.visible = screen in ["pause", "upgrade", "victory", "defeat", "shrine", "pack", "build", "ad", "powers"]
	menu_shade.visible = modal.visible
	if not modal.visible:
		return
	clear_input()
	for child in modal_body.get_children():
		if child != modal_title:
			modal_body.remove_child(child)
			child.queue_free()
	modal.size.y = 0
	match screen:
		"powers": PowerHUD.describe(self)
		"ad":
			modal_title.text = "Rescue video"
			FieldUI.label(self, reward_flow.message)
			FieldUI.label(self, "Test ads only in this internal build. No payment is required.")
			make_button("Cancel loading", func(): ad_bridge.cancelRewarded(reward_flow.pending), modal_body)
		"shrine": FieldUI.shrine(self)
		"pack": FieldUI.pack(self)
		"build": FieldUI.build(self)
		"pause":
			modal_title.text = "Mission progress" if progress_view else ("How to play" if help_view else "Paused")
			if progress_view:
				FieldUI.label(self, mission_progress(), 14)
				make_button("Back", func(): progress_view = false; last_screen = "", modal_body)
			elif help_view:
				var description := "Survive the waves, then defeat %s.\nAttacks and magic fire automatically.\nHold shrine rings to gain temporary powers.\nMove: drag the left side or WASD.\nDodge: button or Space." % run.boss_name
				if run.mode == "salvage":
					description = "Open 3 caches. The central beacon activates at 90 seconds. Hold its ring for 3 seconds to leave before the 3-minute deadline.\nAttacks fire automatically.\nMove: drag or WASD. Dodge: button or Space."
				FieldUI.label(self, description, 14)
				make_button("Back", func(): help_view = false; last_screen = "", modal_body)
			else:
				make_button("Resume", func(): run.paused = false, modal_body)
				var information := HBoxContainer.new()
				information.add_theme_constant_override("separation", 8)
				modal_body.add_child(information)
				make_button("Progress", func(): progress_view = true; last_screen = "", information, 40).size_flags_horizontal = Control.SIZE_EXPAND_FILL
				make_button("How to play", func(): help_view = true; last_screen = "", information, 40).size_flags_horizontal = Control.SIZE_EXPAND_FILL
				make_button("Save & return to Base", show_haven, modal_body)
				if not profile.error.is_empty():
					FieldUI.label(self, profile.error + " Your current expedition is still open; retry saving before leaving.", 13)
			if diagnostics:
				var row := HBoxContainer.new()
				modal_body.add_child(row)
				for count in [30, 60, 120]:
					var b := make_button("%d foes" % count, func(): run.set_benchmark(count); run.paused = false, row)
					b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			if ad_bridge and diagnostics:
				make_button("Test rewarded video", func(): ad_bridge.testRewarded(), modal_body)
				make_button("Ad privacy options", func(): ad_bridge.privacyOptions(), modal_body, 40)
			if diagnostics:
				ad_label = Label.new()
				ad_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				ad_label.add_theme_font_size_override("font_size", 12)
				modal_body.add_child(ad_label)
				refresh_ad_label()
		"upgrade":
			modal_title.text = "Choose a specialization" if not run.offer_back.is_empty() else "Level %d • Choose your power" % run.level
			if run.offers.is_empty():
				run.make_offers()
			if not run.offer_back.is_empty():
				PowerHUD.add_path(self, run.offers[0].id)
			Cards.upgrades(self)
			if not run.offer_back.is_empty():
				make_button("Back to upgrade choices", func(): run.return_to_offers(), modal_body, 40)
		"victory", "defeat":
			if screen == "victory":
				bank_result()
			modal_title.text = "Boss defeated" if screen == "victory" else "The night claimed you"
			if run.mode == "salvage":
				modal_title.text = "Contract completed" if screen == "victory" else ("Beacon window closed" if run.elapsed >= run.duration else "Contract failed")
			if run.practice:
				modal_title.text = "Practice complete" if screen == "victory" else "Practice • try another approach"
			result_stats()
			var details := result_details()
			if not reward_receipt.is_empty():
				MenuSkin.label(details, "REWARDS BANKED", 13, GOLD, true)
				var wallet_row := HBoxContainer.new()
				wallet_row.alignment = BoxContainer.ALIGNMENT_CENTER
				details.add_child(wallet_row)
				for currency in ["credits", "parts", "gems"]:
					MenuSkin.icon(wallet_row, MenuArt.item(currency), Vector2(25,27))
					MenuSkin.label(wallet_row, "+%d" % reward_receipt[currency], 17, GOLD)
				MenuSkin.label(details, "+%d Survivor XP · +%d Mastery XP" % [reward_receipt.survivor_xp, reward_receipt.mastery_xp], 14, VIOLET, true)
				var training_lines := PackedStringArray()
				for stat in reward_receipt.get("combat_xp", {}):
					if reward_receipt.combat_xp[stat] > 0:
						training_lines.append("%s +%.1f" % [stat.capitalize(), reward_receipt.combat_xp[stat]])
				if not training_lines.is_empty():
					MenuSkin.label(details, "Combat XP · " + " / ".join(training_lines), 12, VIOLET, true)
				if reward_receipt.get("talent_points", 0) > 0:
					MenuSkin.label(details, "Combat %d/99 · +%d talent points" % [reward_receipt.combat_after, reward_receipt.talent_points], 14, GOLD, true)
				if reward_receipt.get("keys", 0) > 0:
					var key_row := HBoxContainer.new()
					details.add_child(key_row)
					MenuSkin.icon(key_row, MENU_KEY, Vector2(25,27))
					MenuSkin.label(key_row, "+%d supply key · Open chests in Shop" % reward_receipt.keys, 14, GOLD)
				if not reward_receipt.new_medals.is_empty():
					MenuSkin.label(details, "New medals: " + ", ".join(reward_receipt.new_medals), 14, GOLD)
				if not reward_receipt.gear.is_empty():
					MenuSkin.label(details, "Equipment: " + ", ".join(reward_receipt.gear), 14)
				if reward_receipt.lost > 0:
					MenuSkin.label(details, "%d unprotected loot bundles lost." % reward_receipt.lost, 13, Color("efb9c2"))
			elif run.practice:
				MenuSkin.label(details, "Training complete", 20, GOLD, true)
				MenuSkin.label(details, "Practice grants no loot or progression. Try another build in the Training Yard.", 14, Color("dbe6ff"), true)
			else:
				MenuSkin.label(details, "Your secure stash is protected", 20, GOLD, true)
				MenuSkin.label(details, "Finish the expedition to bank the rewards you earned.", 14, Color("dbe6ff"), true)
			if attempt_id > 0:
				if screen == "defeat" and not run.rescued and ad_bridge and not (run.mode == "salvage" and run.elapsed >= run.duration):
					make_button("Watch test video • rescue at 50% HP", request_rescue, modal_body)
					MenuSkin.label(details, "One rescue per expedition. Gear and run powers stay. A rescue does not earn the combat mastery medal.", 13)
				if not reward_flow.message.is_empty():
					FieldUI.label(self, reward_flow.message, 13)
				if not profile.error.is_empty():
					FieldUI.label(self, profile.error, 13)
				make_button("Finish expedition & bank rewards", func(): bank_result(); last_screen = "", modal_body)
			else:
				make_button("Practice again" if run.practice else "Try again", replay, modal_body)
			make_button("Return to Base", finish_to_haven, modal_body)
	if screen in ["pause", "victory", "defeat", "ad", "upgrade", "shrine", "pack", "build", "powers"]:
		polish_menu_modal(screen)
	else:
		modal.add_theme_stylebox_override("panel", panel_style(Color("111b34"), Color("8d72b3")))
		modal_title.remove_theme_font_override("font")
		modal_title.add_theme_font_size_override("font_size", 22)
		modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		modal_title.remove_theme_color_override("font_outline_color")
		modal_title.remove_theme_constant_override("outline_size")
		modal_title.remove_theme_constant_override("shadow_offset_y")
		modal_title.remove_theme_color_override("font_shadow_color")

func result_stats() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	modal_body.add_child(row)
	for entry in [[MenuArt.SWORD, str(run.kills), "Defeated"], [EXPERIENCE, str(run.level), "Run level"], [MenuArt.MOON, "%d:%02d" % [int(run.elapsed)/60, int(run.elapsed)%60], "Survived"]]:
		var tile := MenuSkin.panel(row, "panel", 14)
		tile.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var line := HBoxContainer.new()
		line.alignment = BoxContainer.ALIGNMENT_CENTER
		tile.add_child(line)
		MenuSkin.icon(line, entry[0], Vector2(20,22))
		MenuSkin.label(line, entry[1], 20, GOLD, true)
		MenuSkin.label(tile, entry[2], 12, Color("b9cbe9"), true)

func result_details() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "ResultRewardsScroll"
	scroll.custom_minimum_size.y = 158
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	modal_body.add_child(scroll)
	var details := MenuSkin.panel(scroll, "panel", 14)
	details.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return details

func polish_menu_modal(screen: String) -> void:
	modal.add_theme_stylebox_override("panel", MenuSkin.surface("panel"))
	modal_title.add_theme_font_override("font", MenuSkin.DISPLAY)
	modal_title.add_theme_font_size_override("font_size", 26 if screen in ["victory","defeat"] else 25)
	modal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modal_title.add_theme_color_override("font_outline_color", Color("122654"))
	modal_title.add_theme_constant_override("outline_size", 4)
	modal_title.add_theme_constant_override("shadow_offset_y", 2)
	modal_title.add_theme_color_override("font_shadow_color", Color("10234a"))
	polish_menu_children(modal_body)

func polish_menu_children(parent: Node) -> void:
	for child in parent.get_children():
		if child.has_meta("reward_card"):
			continue
		if child is Button and not child.has_meta("reward_card_action"):
			var primary: bool = child.text in ["Resume", "Finish expedition & bank rewards"] or (child.text == "Return to Base" and attempt_id <= 0)
			MenuSkin.action(child, "gold" if primary else ("violet" if child.text.begins_with("Watch test video") else "blue"))
		elif child is Label and child != modal_title:
			child.add_theme_font_override("font", MenuSkin.body_font())
			child.autowrap_mode = TextServer.AUTOWRAP_OFF if child.get_parent() is HBoxContainer else TextServer.AUTOWRAP_WORD_SMART
		polish_menu_children(child)

func restart() -> void:
	power_view = false
	run = Run.new()
	reward_flow = RewardFlow.new()
	frames.clear()
	clear_input()

func replay() -> void:
	var repeat_practice: bool = run.practice
	if repeat_practice:
		var mission_number: int = run.mission
		var spells: Array = run.spells.keys()
		restart()
		run.configure(mission_number, profile.stats())
		HeroCast.LayeredRig.warmup(mission_number)
		run.start_boss_practice(spells)
		return
	if not repeat_practice and run.mode == "salvage":
		start_contract(run.target_slot,run.target_weapon)
		return
	if not repeat_practice and run.mission > 0:
		start_campaign(run.mission)
		return
	restart()

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
			if power_view:
				close_power_view()
			else:
				run.paused = not run.paused
			clear_input()
		elif event.keycode == KEY_SPACE:
			run.dodge()
		elif event.keycode == KEY_TAB:
			run.open_pack()
		elif event.keycode == KEY_B:
			run.open_build()
	if run.paused or run.phase not in ["waves", "boss"]:
		return
	if event is InputEventScreenTouch:
		if event.pressed and touch_id == -1 and not mouse_stick:
			touch_id = event.index
			stick_origin = event.position
		elif not event.pressed and event.index == touch_id:
			clear_input()
	elif event is InputEventScreenDrag and event.index == touch_id:
		stick = ((event.position - stick_origin) / 50.0).limit_length()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and touch_id == -1:
			mouse_stick = true
			stick_origin = event.position
		elif not event.pressed:
			clear_input()
	elif event is InputEventMouseMotion and mouse_stick:
		stick = ((event.position - stick_origin) / 50.0).limit_length()

func _physics_process(delta: float) -> void:
	if home.visible or not reward_flow.pending.is_empty():
		return
	var direction := Vector2(
		float(movement_key(KEY_D) or movement_key(KEY_RIGHT)) - float(movement_key(KEY_A) or movement_key(KEY_LEFT)),
		float(movement_key(KEY_S) or movement_key(KEY_DOWN)) - float(movement_key(KEY_W) or movement_key(KEY_UP)))
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

static func movement_key(key: Key) -> bool:
	# Android DPAD/external keyboards may supply a logical key without a physical code.
	return Input.is_physical_key_pressed(key) or Input.is_key_pressed(key)

func _process(delta: float) -> void:
	var in_field: bool = not home.visible
	soundscape.apply_settings(profile.data.settings)
	soundscape.tick(delta, run, home.visible, not reward_flow.pending.is_empty() or not home.shop_flow.pending.is_empty())
	if not in_field:
		for control in [hud_root,dodge_button,pause_button,power_hud,health_bar,boss_bar,pack_button,build_button,field_status,boss_warning,metrics]:
			control.hide()
		modal.hide()
		if field_was_visible:
			queue_redraw()
		field_was_visible = false
		hero_last_position = run.player
		return
	field_was_visible = true
	if run.health < previous_health and in_field and profile.data.settings.haptics and OS.get_name() == "Android":
		Input.vibrate_handheld(35)
	previous_health = run.health
	for control in [hud_root, dodge_button, pause_button]:
		control.visible = in_field
	metrics.visible = in_field and run.benchmark_count > 0
	pause_button.disabled = power_view or not reward_flow.pending.is_empty()
	power_hud.visible = in_field and not diagnostics and run.benchmark_count == 0
	power_hud.update_run(run)
	if in_field and attempt_id > 0:
		checkpoint_wait += delta
		if checkpoint_wait >= 10.0 or (run.phase in ["boss", "upgrade", "shrine", "pack", "build"] and last_checkpoint_key != run.phase + str(run.field.revision)):
			save_checkpoint()
			checkpoint_wait = 0.0
	if not run.paused and run.phase in ["waves", "boss"]:
		anim_time += delta
		var travel: float = run.player.distance_to(hero_last_position)
		if travel > 0.05 and travel < 30:
			hero_move_direction = hero_last_position.direction_to(run.player)
		hero_move_blend = move_toward(hero_move_blend,1.0 if travel > 0.05 else 0.0,delta*9)
		if travel < 30:
			hero_stride += travel*TAU/36.0
	hero_last_position = run.player
	world_offset = Vector2(215,400)-run.player.clamp(Vector2(215,400),Run.World.SIZE-Vector2(215,360))
	health_bar.value = run.health
	health_bar.max_value = run.max_health()
	# Reapply compact geometry after the controls inherit their live theme.
	health_bar.size = Vector2(46, 6)
	xp_bar.size = Vector2(398, 9)
	boss_bar.size = Vector2(398, 6)
	health_bar.position = run.player + world_offset - Vector2(23, 80)
	health_bar.visible = in_field and not modal.visible and profile.data.settings.get("health_bars",true)
	pack_button.visible = in_field and not run.practice and run.benchmark_count == 0
	build_button.visible = pack_button.visible
	pack_button.text = "PACK %d/%d" % [run.field.bag.size(), run.field.capacity]
	if run.field.notice != last_field_notice:
		last_field_notice = run.field.notice
		notice_left = 3.0
	notice_left = maxf(0, notice_left - delta)
	field_status.visible = in_field and not run.practice and run.benchmark_count == 0 and not modal.visible
	field_status.text = "%d scrap • %d/3 relics" % [run.field.scrap, run.field.relics.size()]
	if notice_left > 0 and not last_field_notice.is_empty():
		field_status.text += "\n" + last_field_notice
	xp_bar.max_value = run.level * 5
	xp_bar.value = run.xp
	var remaining := maxi(0, int(ceil(run.duration - run.elapsed)))
	boss_warning.visible = in_field and run.phase == "waves" and (remaining <= 10 or run.mode == "salvage") and not modal.visible and run.benchmark_count == 0
	boss_warning.text = run.Salvage.objective(run) if run.mode == "salvage" else "BOSS ARRIVES IN %d" % remaining
	if run.mission == 1 and run.mode == "campaign" and run.phase == "waves" and remaining > 10 and not modal.visible and in_field:
		var wave := Run.Content.wave_at(run.elapsed)
		if run.elapsed - wave.at < 2.8:
			boss_warning.visible = true
			boss_warning.text = "GARAGE LIGHTS" if wave.at == 0 else wave.name.to_upper()
	var time_text := "%02d:%02d" % [remaining / 60, remaining % 60]
	if run.boss_id >= 0:
		time_text = run.boss_name.to_upper()
	if run.benchmark_count > 0:
		time_text = "CROWD TEST"
	hud.text = time_text
	var next_font_size := 18 if run.boss_id >= 0 else 30
	if hud_font_size != next_font_size:
		hud_font_size = next_font_size
		hud.add_theme_font_size_override("font_size",hud_font_size)
	level_label.text = "Lv. %d" % run.level
	credit_count.text = str(run.field.credits)
	kill_count.text = str(run.kills)
	boss_bar.visible = run.boss_id >= 0 and run.phase not in ["victory", "defeat"] and profile.data.settings.get("health_bars",true)
	for enemy in run.enemies:
		if enemy.boss:
			boss_bar.max_value = enemy.max_hp
			boss_bar.value = enemy.hp
	dodge_button.text = "%.1fs" % run.dodge_wait if run.dodge_wait > 0 else "DODGE"
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
			metrics.text = "%s  •  %d defeated" % ["Defeat " + run.boss_name if run.boss_id >= 0 else Run.Content.wave_at(run.elapsed).name, run.kills]
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

func open_power_view(id: String = "") -> void:
	if home.visible or run.phase not in ["waves", "boss"] or not reward_flow.pending.is_empty():
		return
	if not power_view:
		was_paused = run.paused
	power_view = true
	power_page = "Attacks"
	selected_power = id
	run.paused = true
	clear_input()
	last_screen = ""

func close_power_view() -> void:
	power_view = false
	run.paused = was_paused
	last_screen = ""

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

func visible_world(position_value: Vector2) -> bool:
	# Includes tall altar tops, shadows, and hit labels beyond the viewport edge.
	return Rect2(-350,-100,1130,1230).has_point(position_value+world_offset)

func visible_actor(position_value: Vector2) -> bool:
	# Actor silhouettes need much less overscan than tall buildings and altars.
	return Rect2(-90,-25,610,985).has_point(position_value+world_offset)

func _draw() -> void:
	if is_instance_valid(home) and home.visible:
		return
	var draw_started := Time.get_ticks_usec()
	var enemy_usec := 0
	var hero_usec := 0
	var reduced: bool = profile.data.settings.reduced_effects
	set_meta("actor_meshes", [])
	var cleared_at := Time.get_ticks_usec()
	WorldArt.draw_floor(self,world_offset)
	WorldArt.draw_boundary(self,world_offset,false)
	Presentation.draw_ambience(self, run, world_offset, anim_time, reduced)
	var terrain_at := Time.get_ticks_usec()
	CombatEffects.draw_ground(self,run,world_offset,anim_time,reduced)
	CombatEffects.Ember.draw_ground(self,run,world_offset,reduced)
	var ground_fx_at := Time.get_ticks_usec()
	if not run.practice and run.benchmark_count == 0:
		for entry: Dictionary in Neighborhood.entries():
			if visible_world(entry.pos): WorldArt.draw_scenery_ground(self,entry,world_offset)
		draw_field_sites()
		draw_defenses()
	if run.mode == "salvage":
		var at: Vector2 = Run.Salvage.EXIT + world_offset
		var ready: bool = Run.Salvage.ready(run)
		draw_circle(at, Run.Salvage.RADIUS, Color(1, 0.8, 0.4, 0.08) if ready else Color(0.4, 0.45, 0.6, 0.06))
		draw_arc(at, Run.Salvage.RADIUS, 0, TAU, 48, GOLD if ready else Color("65718f"), 2)
		draw_arc(at, Run.Salvage.RADIUS + 4, -PI / 2, -PI / 2 + TAU * run.extract_progress / Run.Salvage.CHARGE, 48, GOLD, 4)
		draw_prop(7, at, Vector2(45, 65), Color.WHITE if ready else Color("858095"))
	var landmarks_at := Time.get_ticks_usec()
	for index in run.pickups.size():
		if not visible_world(run.pickups[index]): continue
		var at: Vector2 = run.pickups[index] + world_offset
		var value: int = run.pickup_xp[index] if index < run.pickup_xp.size() else 1
		var size := Vector2.ONE*(19+minf(9,sqrt(value-1)*2))
		Presentation.draw_collectible(self,EXPERIENCE,at,size,anim_time,index,Color("82dfff"),reduced,run.pickups[index].distance_to(run.player)<run.experience_pickup_radius(),run.player+world_offset)
	var pickups_at := Time.get_ticks_usec()
	CombatVFX.draw_telegraphs(self, run, world_offset, reduced)

	var world_done := Time.get_ticks_usec()
	var actors: Array[Dictionary] = []
	for enemy in run.enemies:
		if visible_actor(enemy.pos):
			actors.append(enemy)
	actors.append({"pos": run.player, "player": true})
	for shot in run.shots:
		if visible_world(shot.pos):
			actors.append({"pos":shot.pos,"shot":shot})
	if not run.practice and run.benchmark_count == 0:
		for entry: Dictionary in Neighborhood.entries():
			if visible_world(entry.pos):
				actors.append({"pos":entry.pos,"sort_y":entry.footprint.end.y,"scenery":entry})
		for site in run.field.sites:
			if not visible_world(site.pos):
				continue
			var visual: Dictionary = site.duplicate()
			visual.exhausted = site.kind == "relic" and run.field.relics.size() >= 3
			actors.append({"pos":site.pos,"sort_y":WorldArt.site_sort_y(site),"site":visual})
	actors.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.get("sort_y",a.pos.y) < b.get("sort_y",b.pos.y))
	# Consecutive shared textures batch; per-actor polygons/transforms do not.
	for item in actors:
		if item.has("site") or item.has("shot") or item.has("scenery"):
			continue
		var scale_value := 1.0 if item.has("player") else (1.7 if item.boss else 0.8)
		var size := Vector2(34, 12.92) * scale_value
		draw_texture_rect(SHADOW, Rect2(item.pos + world_offset - size / 2, size), false)
	Presentation.draw_player_ground(self, run, world_offset, anim_time, reduced)
	CombatEffects.draw_wisps(self,run,world_offset,anim_time,reduced,false)
	for item in actors:
		if item.has("shot") or item.has("site") or item.has("player") or item.has("scenery"):
			EnemyMotion.flush(self)
		if item.has("scenery"):
			WorldArt.draw_scenery_body(self,item.scenery,world_offset)
		elif item.has("shot"):
			CombatEffects.draw_shot(self,item.shot,world_offset,anim_time,reduced)
		elif item.has("site"):
			WorldArt.draw_site_body(self,item.site,world_offset,anim_time,reduced)
		elif item.has("player"):
			var hero_started := Time.get_ticks_usec()
			var pose := HeroCast.pose(run)
			var face := -1.0 if (run.facing.x if pose.is_empty() else pose.direction.x) < 0 else 1.0
			var weapon_pose := HeroCast.weapon_pose(run)
			HeroCast.draw_motion(self,run.player,world_offset,face,anim_time,hero_stride,hero_move_blend,99.0 if pose.is_empty() else pose.age,minf(1,run.dodge_left/0.12),run.class_id=="engineer",reduced,run.class_id,clampf((run.hurt_wait-0.65)/0.15,0,1),pose.get("weapon",pose.get("spell","")),run.weapon_id,weapon_pose.direction,weapon_pose.age,hero_move_direction,run.appearance)
			hero_usec += Time.get_ticks_usec()-hero_started
		else:
			var enemy_started := Time.get_ticks_usec()
			EnemyMotion.draw(self, item, run.mission, world_offset, anim_time, reduced,0.0,true)
			enemy_usec += Time.get_ticks_usec()-enemy_started
	EnemyMotion.flush(self)
	var actors_done := Time.get_ticks_usec()

	CombatEffects.draw_effects(self,run,world_offset,anim_time,reduced)
	CombatVFX.draw_effects(self,run,world_offset,anim_time,reduced)
	CombatVFX.draw_telegraphs(self,run,world_offset,reduced,true)
	for item in run.enemies:
		if not visible_actor(item.pos): continue
		var mark: Vector2 = item.pos + world_offset - Vector2(0, EnemyMotion.body_height(item,run.mission)+12)
		if item.boss and run.mission == 4:
			var angle: float = item.forward.angle()
			draw_arc(item.pos + world_offset, 42, angle - 1.2, angle + 1.2, 24, Color("92c2ff"), 5)
		if item.kind == "runner" and run.mission != 1:
			draw_polyline(PackedVector2Array([mark + Vector2(-5, 0), mark + Vector2(0, -5), mark + Vector2(5, 0)]), GOLD, 2)
		elif item.kind == "spitter" and run.mission != 1:
			draw_arc(mark, 5, 0, TAU, 12, Color("adceff"), 2)
		if visible_world(item.pos) and profile.data.settings.get("health_bars",true):
			var at: Vector2 = item.pos + world_offset - Vector2(20, EnemyMotion.body_height(item,run.mission)+5)
			draw_rect(Rect2(at, Vector2(40, 4)), INK)
			draw_rect(Rect2(at, Vector2(40 * item.hp / item.max_hp, 4)), Color("e36d86"))
	CombatEffects.draw_wisps(self,run,world_offset,anim_time,reduced,true)

	if run.talents.slow_left > 0:
		var at: Vector2 = run.player + world_offset
		draw_arc(at, 22, 0, TAU, 24, Color("b2a2ef"), 3)
		draw_string(ThemeDB.fallback_font, at + Vector2(-20, 24), "SLOWED", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ddd3ff"))

	WorldArt.draw_boundary(self,world_offset,true)
	var spells_done := Time.get_ticks_usec()
	Presentation.draw_feedback(self, run, world_offset, reduced,profile.data.settings.get("damage_numbers",true))

	if run.hurt_wait > 0.55 and not profile.data.settings.reduced_effects:
		draw_rect(Rect2(0, 0, 430, 760), Color(0.7, 0.05, 0.15, 0.08))
	if touch_id >= 0 or mouse_stick:
		Shapes.circle(self,stick_origin,48,Color(0.04,0.05,0.1,0.45))
		Shapes.ring(self,stick_origin,48,2,Color(0.8,0.8,0.95,0.3))
		Shapes.circle(self,stick_origin+stick*32,22,Color(0.55,0.68,0.85,0.6))

	var finished_draw := Time.get_ticks_usec()
	draw_cpu_ms = (finished_draw-draw_started)/1000.0
	draw_profile = {"retire_meshes":(cleared_at-draw_started)/1000.0,"terrain":(terrain_at-cleared_at)/1000.0,"ground_fx":(ground_fx_at-terrain_at)/1000.0,"landmarks":(landmarks_at-ground_fx_at)/1000.0,"pickups":(pickups_at-landmarks_at)/1000.0,"telegraphs":(world_done-pickups_at)/1000.0,"world":(world_done-draw_started)/1000.0,"actors":(actors_done-world_done)/1000.0,"spells":(spells_done-actors_done)/1000.0,"feedback":(finished_draw-spells_done)/1000.0,"enemy_mesh":enemy_usec/1000.0,"hero_mesh":hero_usec/1000.0}

func draw_field_sites() -> void:
	for site in run.field.sites:
		if not visible_world(site.pos):
			continue
		var visual: Dictionary = site.duplicate()
		visual.exhausted = site.kind == "relic" and run.field.relics.size() >= 3
		visual.radius = Run.Field.interaction_radius(site)
		visual.interaction_offset = Run.Field.interaction_center(site)-site.pos
		WorldArt.draw_site_ground(self,visual,world_offset,anim_time,profile.data.settings.reduced_effects)
	for drop in run.field.drops:
		if not visible_world(drop.pos):
			continue
		var at: Vector2 = drop.pos + world_offset
		Presentation.draw_collectible(self,credit_drop,at,Vector2(20,26),anim_time,int(drop.pos.x+drop.pos.y),GOLD,profile.data.settings.reduced_effects)
	for position in run.talents.cache_positions(run):
		var at: Vector2 = (position + world_offset - Vector2(0, 48)).clamp(Vector2(18, 188), Vector2(412, 610))
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -7), at + Vector2(6, 0), at + Vector2(0, 7), at + Vector2(-6, 0)]), GOLD)

func draw_defenses() -> void:
	for structure in run.defenses.structures:
		var at: Vector2 = structure.pos + world_offset
		match structure.kind:
			"barricade":
				draw_prop(4, at, Vector2(74, 61))
			"turret":
				draw_prop(5, at, Vector2(68, 65))
			"trap":
				draw_prop(6, at, Vector2(50, 40))
			"ward":
				draw_circle(at, 100, Color(0.45, 0.55, 1, 0.04))
				draw_arc(at, 100, 0, TAU, 48, Color(0.6, 0.6, 1, 0.25), 1)
				draw_prop(7, at, Vector2(52, 70))
		if structure.repair_left > 0:
			draw_arc(at, 28, anim_time, anim_time + PI * 1.5, 24, Color("acd6ff"), 2)
		if profile.data.settings.get("health_bars",true):
			draw_rect(Rect2(at - Vector2(20, 50), Vector2(40, 4)), INK)
			draw_rect(Rect2(at - Vector2(20, 50), Vector2(40 * structure.hp / structure.max_hp, 4)), GOLD)
	if run.phase == "build":
		var placement: Vector2 = run.player + run.facing * 90 + world_offset
		draw_arc(placement, 25, 0, TAU, 32, GOLD, 2)
		draw_line(placement - Vector2(8, 0), placement + Vector2(8, 0), GOLD, 2)
		draw_line(placement - Vector2(0, 8), placement + Vector2(0, 8), GOLD, 2)

func draw_prop(index: int, position_value: Vector2, size_value: Vector2, tint: Color = Color.WHITE) -> void:
	draw_texture_rect_region(PROPS, Rect2(position_value - Vector2(size_value.x / 2, size_value.y * 0.86), size_value), PROP_RECTS[index], tint)
