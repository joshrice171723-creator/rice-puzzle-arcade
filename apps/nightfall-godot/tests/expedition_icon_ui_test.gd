extends SceneTree
const Profile=preload("res://profile.gd")
const Haven=preload("res://haven_ui.gd")
var checks:=0
var failures:=0
var capture_dir:=""
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):capture_dir=arg.trim_prefix("--capture-dir=")
	call_deferred("verify")
func check(value: bool,message: String) -> void:
	checks+=1
	if not value:
		failures+=1
		push_error(message)
func settle() -> void:
	for frame in 8:await process_frame
func capture(label: String) -> void:
	if capture_dir.is_empty() or DisplayServer.get_name()=="headless":return
	DirAccess.make_dir_recursive_absolute(capture_dir)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir.path_join(label+".png"))
func borderless(control: Button) -> void:
	check(control.text.is_empty() and control.icon!=null,"Shortcut is art only: "+control.name)
	check(control.custom_minimum_size.x>=44 and control.custom_minimum_size.y>=44,"Shortcut retains touch hit area")
	check(not control.tooltip_text.is_empty(),"Shortcut retains accessible purpose")
	for state in ["normal","hover","pressed","disabled","focus"]:
		check(control.get_theme_stylebox(state) is StyleBoxEmpty,"Shortcut has no frame in "+state)
func verify() -> void:
	var profile=Profile.new("user://nightfall_icon_ui_fixture.json")
	profile.data.settings.reduced_effects=true
	var home=Haven.new()
	home.profile=profile
	root.add_child(home)
	for dimensions in [Vector2i(430,760),Vector2i(320,568)]:
		root.size=dimensions
		home.navigate("mission")
		await settle()
		borderless(home.find_child("SettingsButton",true,false))
		borderless(home.find_child("ZoneMapButton",true,false))
		for entry in [["SalvageContracts","contracts"],["BossTraining","training"],["MasteryRewards","rewards"],["DailyObjectives","daily"]]:
			home.navigate("mission")
			await settle()
			var shortcut: Button=home.find_child(entry[0],true,false)
			borderless(shortcut)
			check(root.get_visible_rect().encloses(shortcut.get_global_rect()),"Shortcut fits phone")
			shortcut.pressed.emit()
			check(home.page==entry[1],"Icon opens correct real destination")
		home.navigate("mission")
		await settle()
		var start: Button=null
		for child in home.body.get_children():
			if child is Button and child.text=="Start expedition":start=child
		check(start!=null and start.get_theme_stylebox("normal") is StyleBoxTexture,"Start expedition keeps primary painted button")
		check(home.body.get_global_rect().end.y<=home.navigation.get_global_rect().position.y,"Expedition fits above dock")
		await capture("expedition-icons-"+str(dimensions.x))
		home.find_child("SettingsButton",true,false).pressed.emit()
		check(home.page=="settings","Settings icon opens settings")
	check(profile.data.active_attempt.is_empty(),"Navigation cannot start an expedition")
	home.queue_free()
	await process_frame
	print("Expedition icon UI: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
