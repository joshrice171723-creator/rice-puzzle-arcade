extends SceneTree
const Profile = preload("res://profile.gd")
const Training = preload("res://combat_progression.gd")
const PATH := "user://nightfall_combat_training_ui_test.json"
var checks := 0
var failures := 0
var capture_dir := ""

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	call_deferred("verify")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func settle() -> void:
	for tick in 9:
		await process_frame

func verify() -> void:
	cleanup()
	var profile = Profile.new(PATH)
	check(profile.save(), "Disposable training fixture saves")
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	arena.profile = profile
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	var home: Control = arena.home
	home.navigate("class")
	home.find_child("OpenCombatTraining", true, false).pressed.emit()
	await settle()
	check(home.page == "combat_training" and home.active_tab() == "class", "Class Training button opens the Class training destination")
	check(home.find_child("TrainingStyle", true, false).item_count == 6, "All six training focuses are available")
	for stat in Training.STATS:
		check(home.find_child("CombatLevel_" + stat, true, false).text == "1 / 99", "Fresh " + stat + " starts at level 1")
	for index in Training.STYLES.size():
		var style: String = Training.STYLES.keys()[index]
		var choose: OptionButton = home.find_child("TrainingStyle", true, false)
		choose.item_selected.emit(index)
		await settle()
		check(profile.data.training_style == style, "Choosing " + style + " saves the actual training focus")
		var reloaded = Profile.new(PATH)
		check(reloaded.load_save() and reloaded.data.training_style == style, "Training focus " + style + " survives restart")
	profile.data.active_attempt = {"id": 404}
	home.rebuild()
	await settle()
	var choose: OptionButton = home.find_child("TrainingStyle", true, false)
	check(choose.disabled, "A saved expedition disables training focus changes")
	var before: Dictionary = profile.data.duplicate(true)
	choose.item_selected.emit(0)
	await settle()
	check(profile.data == before, "A stale style signal cannot change an active expedition")
	profile.data.active_attempt = {}
	profile.path = "user://missing-training-ui-folder/save.json"
	home.rebuild()
	await settle()
	before = profile.data.duplicate(true)
	home.find_child("TrainingStyle", true, false).item_selected.emit(0)
	await settle()
	check(profile.data == before, "A failed focus save rolls back the selected style")
	profile.path = PATH
	check(profile.save(), "Training fixture recovers from the simulated write failure")
	for dimensions in [Vector2i(430,760), Vector2i(320,568)]:
		root.size = dimensions
		for maximum in [false, true]:
			for stat in Training.STATS:
				profile.data.combat_xp[stat] = Training.MAX_XP if maximum else 0.0
			profile.data.class_combat[profile.data["class"]].training_style = "accurate"
			profile.sync_training_alias()
			home.navigate("combat_training")
			await settle()
			check(home.body.get_global_rect().end.y <= home.navigation.position.y, "Training fits above phone navigation at " + str(dimensions))
			for stat in Training.STATS:
				check(home.find_child("CombatLevel_" + stat, true, false).text == ("99 / 99" if maximum else "1 / 99"), "Actual " + stat + " level reflects the " + ("max" if maximum else "fresh") + " fixture")
				check(home.find_child("CombatXP_" + stat, true, false).text == "MAX" if maximum else home.find_child("CombatXP_" + stat, true, false).text.begins_with("0 / "), "Actual " + stat + " XP progress reflects the fixture")
			for node in home.body.find_children("*", "Control", true, false):
				if node.is_visible_in_tree():
					check(root.get_visible_rect().encloses(node.get_global_rect()), "Training control stays inside " + str(dimensions) + ": " + node.name)
			if not capture_dir.is_empty() and DisplayServer.get_name() != "headless":
				DirAccess.make_dir_recursive_absolute(capture_dir)
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png(capture_dir.path_join("combat-training-%s-%dx%d.png" % ["max" if maximum else "fresh", dimensions.x, dimensions.y]))
	profile.data.class_combat[profile.data["class"]].xp = Training.fresh()
	profile.sync_training_alias()
	home.navigate("talents")
	await settle()
	home.find_child("TalentPreviewOpenMastery", true, false).pressed.emit()
	await settle()
	check(home.page == "mastery", "Permanent class mastery remains reachable through Talent Preview")
	check(arena.attempt_id == 0, "UI fixtures never start a real expedition")
	arena.queue_free()
	await process_frame
	cleanup()
	print("Nightfall combat training UI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
