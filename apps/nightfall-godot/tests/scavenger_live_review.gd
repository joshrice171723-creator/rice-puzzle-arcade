extends SceneTree
## Opens the real arena with a disposable Scavenger practice run and exercises the
## actual keyboard path so a live capture can show idle, movement, turns, shots and dodge.
const ArenaScene = preload("res://main.tscn")
const HeroCast = preload("res://hero_cast.gd")
var checks := 0
var failures := 0
var attack_times: Dictionary = {}
var upgrades_resolved := 0
var unresolved_upgrades: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("start_review")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func wait_and_track(arena: Node, seconds: float) -> void:
	var deadline := Time.get_ticks_msec()+roundi(seconds*1000.0)
	while Time.get_ticks_msec()<deadline:
		if arena.run.phase == "upgrade":
			# Some debug launches inherit a pause; this disposable practice run owns
			# its state, so clear any such pause before using the live offer API.
			arena.run.paused = false
			if arena.run.offers.is_empty():
				arena.run.make_offers()
			arena.run.choose_offer(0)
			if arena.run.phase == "upgrade" and not arena.run.offer_back.is_empty():
				arena.run.choose_offer(0)
			if arena.run.phase == "upgrade":
				unresolved_upgrades.append({"paused":arena.run.paused,"offer_back":not arena.run.offer_back.is_empty(),
					"offers":arena.run.offers.size(),"first_offer":arena.run.offers[0].get("id","") if not arena.run.offers.is_empty() else ""})
			else:
				upgrades_resolved += 1
		elif arena.run.phase == "shrine":
			if arena.run.field.sites[arena.run.field.active_site].kind == "relic":
				arena.run.choose_relic(0)
			else:
				arena.run.leave_shrine()
		for event: Dictionary in arena.run.vfx_events:
			if event.kind != "weapon_cast":
				continue
			attack_times[event.serial] = true
		await process_frame

func start_review() -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Nightfall Scavenger Review")
	var arena: Node = ArenaScene.instantiate()
	arena.testing = true
	root.add_child(arena)
	await process_frame
	arena.profile.data["class"] = "scavenger"
	arena.home.hide()
	arena.run.configure(1,arena.profile.stats())
	arena.run.practice = true
	arena.run.weapon_id = "pistol"
	for spell in ["ember","frost","chain"]:
		arena.run.spells[spell] = {"rank":1,"branch":"","wait":4.5}
	arena.run.fire_wait = 0.0
	arena.run.spawn_wait = 0.5
	arena.run.paused = false
	for spec: Dictionary in [
		{"kind":"drifter","offset":Vector2(105,0)},
		{"kind":"runner","offset":Vector2(-120,18)},
		{"kind":"spitter","offset":Vector2(0,-145)}
	]:
		arena.run.spawn_enemy(false,spec.kind)
		arena.run.enemies.back().pos = arena.run.player+spec.offset
	await wait_and_track(arena,4.0)
	var idle_position: Vector2 = arena.run.player
	var idle_pose: Dictionary = HeroCast.layered_pose(
		HeroCast.LayeredRig.definition("scavenger"),"pistol",1,Vector2.RIGHT,
		0,0,99,0,"",99,Vector2.RIGHT,arena.anim_time)
	key(KEY_D,true)
	await wait_and_track(arena,0.95)
	var after_wasd: Vector2 = arena.run.player
	check(after_wasd.x>idle_position.x+20,"WASD D key moves the actual Scavenger in the arena")
	key(KEY_D,false)
	await wait_and_track(arena,0.45)
	var stopped_blend: float = arena.hero_move_blend
	key(KEY_LEFT,true)
	await wait_and_track(arena,0.95)
	var after_arrow: Vector2 = arena.run.player
	check(after_arrow.x<after_wasd.x-20,"Arrow key moves the actual Scavenger in the arena")
	check(arena.run.facing.x<0,"Changing direction turns the Scavenger to face left")
	key(KEY_LEFT,false)
	await wait_and_track(arena,0.35)
	key(KEY_W,true)
	await wait_and_track(arena,0.65)
	key(KEY_W,false)
	await wait_and_track(arena,0.3)
	key(KEY_RIGHT,true)
	await wait_and_track(arena,0.75)
	key(KEY_RIGHT,false)
	await wait_and_track(arena,0.35)
	arena.run.dodge_wait = 0.0
	key(KEY_SPACE,true)
	await wait_and_track(arena,0.08)
	var dodged: bool = arena.run.dodge_left>0.0
	key(KEY_SPACE,false)
	await wait_and_track(arena,0.65)
	# Keep the arena running after the input sequence so delayed level-up offers
	# are resolved by the same game rules before the review window is left open.
	await wait_and_track(arena,8.0)
	check(dodged,"Space remains a manual dodge action")
	check(stopped_blend<0.75,"Movement animation eases into a stop after key release")
	check(not attack_times.is_empty(),"The equipped pistol fires automatically at live enemies")
	check(not arena.modal.visible,"The live review ends with the character unobstructed by a level-up modal")
	check(upgrades_resolved>0 and unresolved_upgrades.is_empty(),"The live review resolves the actual power and specialization sequence")
	check(idle_pose.ankle_l.is_finite() and idle_pose.ankle_r.is_finite(),"The Scavenger idle pose is finite")
	var report := {"checks":checks,"failures":failures,"unique_auto_pistol_shots":attack_times.size(),
		"upgrades_resolved":upgrades_resolved,"unresolved_upgrades":unresolved_upgrades,
		"modal_clear":not arena.modal.visible,"run_level":arena.run.level,
		"movement_wasd":after_wasd-idle_position,"movement_arrow":after_arrow-after_wasd,
		"dodge_started":dodged,"practice_only":arena.run.practice,"class":arena.run.class_id,"weapon":arena.run.weapon_id}
	var file := FileAccess.open("user://scavenger-live-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("Scavenger live arena review: ",JSON.stringify(report))
	# Keep the disposable live arena open for visual review; it never saves progress.
	if DisplayServer.get_name() == "headless":
		arena.queue_free()
		await process_frame
		quit(1 if failures else 0)
