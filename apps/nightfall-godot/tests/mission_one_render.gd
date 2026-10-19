extends SceneTree
## Disposable, frozen Mission One scenes. Never reads or writes the player save.
var destination := ""
var phone_size := Vector2i(430,760)

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			destination = arg.trim_prefix("--capture-dir=")
		if arg == "--small":
			phone_size = Vector2i(320,568)
	call_deferred("capture")

func save_frame(name: String) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(destination.path_join(name + ".png"))
	if result != OK:
		push_error("Capture failed: " + name)
		quit(1)

func capture() -> void:
	if destination.is_empty() or not DirAccess.dir_exists_absolute(destination):
		quit(1)
		return
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	root.size = phone_size
	arena.home.hide()
	arena.run.configure(1,arena.profile.stats())
	arena.run.paused = false
	arena.run.player = Vector2(830,1110)
	arena.run.elapsed = 2
	await save_frame("garage-arrival")
	arena.run.player = Vector2(1200,1120)
	arena.run.elapsed = 135
	arena.run.level = 7
	arena.run.xp = 17
	arena.run.kills = 98
	arena.run.spells = {"frost":{"rank":2,"wait":1.0},"ember":{"rank":2,"wait":2.0},"wisp":{"rank":1,"wait":0.0},"ground":{"rank":1,"wait":3.0}}
	for n in 15:
		arena.run.spawn_enemy(false,["drifter","runner","spitter","bulwark","hexer"][n % 5])
		arena.run.enemies.back().pos = arena.run.player + Vector2.from_angle(n * TAU / 15) * (125 if n % 2 else 180)
		arena.run.enemies.back().face = -1.0 if n % 2 else 1.0
	arena.run.damage_enemy(arena.run.enemies[0],12,arena.run.player)
	arena.run.damage_enemy(arena.run.enemies[2],8,arena.run.player,true)
	arena.run.zones.assign([{"kind":"ground","pos":arena.run.player,"life":2.0,"dps":8.0,"radius":100.0}])
	await save_frame("crossfire")
	arena.run.phase = "upgrade"
	arena.run.make_offers()
	arena.last_screen = ""
	arena.update_modal()
	await save_frame("level-up")
	arena.run.phase = "boss"
	arena.run.elapsed = 245
	arena.run.enemies.clear()
	arena.run.feedback.clear()
	arena.run.zones.clear()
	arena.run.spawn_enemy(true)
	var boss: Dictionary = arena.run.enemies.back()
	boss.pos = Vector2(1280,1050)
	boss.target = arena.run.player
	boss.attack = "rush"
	boss.tell = 0.55
	arena.last_screen = ""
	arena.update_modal()
	await save_frame("mauler-rush")
	boss.target = boss.pos
	boss.attack = "slam"
	await save_frame("mauler-slam")
	arena.profile.data.settings.reduced_effects = true
	await save_frame("reduced-effects")
	arena.queue_free()
	await process_frame
	print("Six Mission One captures saved; isolated fixture, no player save.")
	quit()
