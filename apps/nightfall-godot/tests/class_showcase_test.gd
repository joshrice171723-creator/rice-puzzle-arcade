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
	check(hero != null and hero.portrait.get_script()==preload("res://gear_actor.gd") and hero.appearance["class"]=="arcanist","Arcanist showcase uses the shared equipped articulated actor")
	var initial_position: Vector2 = hero.position
	await create_timer(0.12).timeout
	check(hero.elapsed > 0 and hero.position == initial_position,"Shared actor clock advances while its pedestal anchor stays planted")
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
	check(home.page == "talents","Class opens the dedicated talent preview")
	for id in ["scavenger","warden","arcanist","engineer"]:
		home.inspected_class=id
		home.tree_ability=""
		home.rebuild()
		await process_frame
		for branch in 3:
			home.find_child("TalentBranch_"+str(branch),true,false).pressed.emit()
			await process_frame
			check(home.inspected_class == id and home.active_tab() == "class","Talent preview follows inspected class")
			check(home.find_child("TalentPath",true,false).get_child_count()>15,"Talent preview has branching nodes and prerequisite arrows")
			check(arena.profile.data==before,"Preview paths do not change equipment,XP or unlocks")
	home.tree_ability="gravity"
	home.rebuild()
	home.find_child("TalentNode_gravity",true,false).pressed.emit()
	home.find_child("TalentPreviewOpenTree",true,false).pressed.emit()
	check(home.page == "skills" and home.tree_ability == "gravity","Preview opens the selected ability in the real skill tree")
	home.navigate("class")
	home.find_child("OpenCombatTraining",true,false).pressed.emit()
	check(home.page == "combat_training" and home.active_tab() == "class","Class opens permanent combat training")
	home.navigate("talents")
	home.find_child("TalentPreviewOpenMastery",true,false).pressed.emit()
	check(home.page == "mastery","Talent preview retains the real permanent mastery talents")
	arena.profile.data.settings.reduced_effects = true
	home.navigate("class")
	hero = home.find_child("ClassHero",true,false)
	check(hero.portrait.material == null and not hero.is_processing(),"Reduced effects removes the idle shader and magic motion")
	arena.profile.data.settings.reduced_effects = before.settings.reduced_effects
	check(arena.profile.data == before and arena.attempt_id == 0,"Class UI testing never spends, equips or starts a run")
	print("Nightfall class showcase: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
