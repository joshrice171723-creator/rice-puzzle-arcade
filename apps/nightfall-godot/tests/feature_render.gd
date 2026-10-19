extends SceneTree
## Static product captures. Never advances combat or reads the player's save.
var destination := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			destination = arg.trim_prefix("--capture-dir=")
	call_deferred("capture")

func save_frame(name: String) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(destination.path_join(name + ".png"))
	if result != OK:
		push_error("Could not save static feature capture: " + name)
		quit(1)

func capture() -> void:
	if destination.is_empty() or not DirAccess.dir_exists_absolute(destination):
		push_error("Pass an existing --capture-dir path")
		quit(1)
		return
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	root.size = Vector2i(430, 760)
	arena.home.show()
	arena.profile.data.seen_bosses = [1, 2, 3, 4, 5]
	arena.profile.data.missions = {"1": ["clear"], "2": ["clear"], "3": ["clear"], "4": ["clear"]}
	for entry in [["arcanum", "ability-guide"], ["training", "training-yard"], ["contracts", "salvage-contracts"], ["mastery", "class-mastery"]]:
		arena.home.page = entry[0]
		arena.home.training_mission = 5
		arena.home.guide_index = 1
		arena.home.rebuild()
		await save_frame(entry[1])
	arena.home.hide()
	arena.run.configure(5, arena.profile.stats())
	arena.run.start_boss_practice()
	arena.run.player = Vector2(600, 600)
	arena.run.enemies[0].pos = Vector2(710, 660)
	arena.run.enemies[0].face = -1.0
	arena.run.enemies[0].tell = 0.7
	arena.run.enemies[0].attack = "slam"
	arena.run.enemies[0].target = arena.run.enemies[0].pos
	arena.run.spells = {"frost": {"rank": 3, "wait": 2.0, "branch": "spread", "evolved": true}, "wisp": {"rank": 2, "wait": 0.0, "branch": "spread"}, "ground": {"rank": 2, "wait": 5.0, "branch": "spread"}}
	arena.run.zones.assign([{"kind": "ground", "pos": arena.run.player, "life": 3.0, "dps": 8.0, "radius": 120.0}])
	arena.run.phase = "boss"
	arena.run.paused = false
	arena.run.level = 9
	arena.run.elapsed = 252
	arena.last_screen = ""
	arena.update_modal()
	await save_frame("breaker-encounter")
	print("HUD geometry: HP ", arena.health_bar.size, " minimum ", arena.health_bar.get_combined_minimum_size(), " XP ", arena.xp_bar.size)
	arena.open_power_view("frost")
	arena.update_modal()
	await save_frame("ability-progression")
	arena.close_power_view()
	arena.run.practice = false
	arena.run.phase = "waves"
	arena.run.boss_id = -1
	arena.run.paused = false
	arena.run.elapsed = 135
	arena.run.xp = 35
	arena.run.health = 172
	arena.run.kills = 194
	arena.run.field.credits = 40
	arena.run.field.scrap = 65
	arena.run.enemies.clear()
	for index in 10:
		arena.run.spawn_enemy(false, "runner" if index % 3 == 0 else "drifter")
		arena.run.enemies.back().pos = arena.run.player + Vector2.from_angle(index * TAU / 10) * (150 if index % 2 == 0 else 210)
	arena.last_screen = ""
	arena.update_modal()
	await save_frame("compact-hud")
	arena.queue_free()
	await process_frame
	print("Seven static feature captures saved; no combat simulation or player save used.")
	quit()
