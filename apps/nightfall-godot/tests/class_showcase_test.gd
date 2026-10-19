extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	var home = arena.home
	var before: Dictionary = arena.profile.data.duplicate(true)
	home.inspected_class = "arcanist"
	home.navigate("class")
	await process_frame
	var hero = home.find_child("ClassHero",true,false)
	check(hero != null and hero.portrait.material is ShaderMaterial,"Arcanist preview has animated hero")
	var initial_position: Vector2 = hero.position
	await create_timer(0.12).timeout
	check(hero.elapsed > 0 and hero.position == initial_position,"Hero animates while staying planted on the pedestal")
	check(home.find_child("SelectClass",true,false).disabled,"Locked preview cannot equip the future class")
	home.hide()
	await process_frame
	var frozen: float = hero.elapsed
	await create_timer(0.12).timeout
	check(not hero.is_processing() and is_equal_approx(frozen,hero.elapsed),"Hidden showcase stops its animation clock")
	home.show()
	await create_timer(0.12).timeout
	check(hero.elapsed > frozen,"Visible showcase resumes character motion")
	for id in ["scavenger","warden","arcanist","engineer"]:
		home.find_child("PreviewClass_"+id,true,false).pressed.emit()
		await process_frame
		check(home.inspected_class == id,"Portrait selects the "+id+" preview")
		check(home.body.get_global_rect().end.y <= home.navigation.position.y,"Showcase fits above navigation for "+id)
		check(arena.profile.data == before,"Previewing "+id+" does not change the player's profile")
	home.find_child("OpenClassSkills",true,false).pressed.emit()
	check(home.page == "skills","Skill Tree opens the real class tree")
	home.navigate("class")
	home.find_child("OpenClassMastery",true,false).pressed.emit()
	check(home.page == "mastery","Mastery opens the real permanent talents")
	arena.profile.data.settings.reduced_effects = true
	home.navigate("class")
	hero = home.find_child("ClassHero",true,false)
	check(hero.portrait.material == null and not hero.is_processing(),"Reduced effects removes the idle shader and magic motion")
	arena.profile.data.settings.reduced_effects = before.settings.reduced_effects
	check(arena.profile.data == before and arena.attempt_id == 0,"Class UI testing never spends, equips or starts a run")
	print("Nightfall class showcase: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
