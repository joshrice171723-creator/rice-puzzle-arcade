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
	var hero = home.find_child("ClassCoverArt",true,false)
	var character_view = home.find_child("ClassCharacterViewport",true,false)
	check(hero is TextureRect and hero.texture is ViewportTexture and hero.get_meta("animated_cover",false) and hero.get_meta("cover_class","")=="arcanist" and hero.get_meta("cover_art_source","").ends_with("assets/class-showcase/arcanist.png") and character_view.class_id=="arcanist" and character_view.size==Vector2i(560,840) and character_view.animation_player.is_playing() and hero.find_child("ClassEquippedActor",true,false)==null,"Arcanist showcase uses its supersampled approved art rig, separate from the gameplay actor")
	var opening_time: float = character_view.animation_player.current_animation_position
	await create_timer(0.4).timeout
	check(character_view.animation_player.current_animation_position != opening_time,"Class character idle animation advances continuously")
	check(home.find_child("SelectClass",true,false).disabled,"Locked preview cannot equip the future class")
	for id in ["scavenger","warden","arcanist","engineer"]:
		home.find_child("PreviewClass_"+id,true,false).pressed.emit()
		await process_frame
		check(home.inspected_class == id,"Portrait selects the "+id+" preview")
		hero=home.find_child("ClassCoverArt",true,false)
		var expected_asset: String="assets/class-showcase/scavenger.png" if id=="scavenger" else ("assets/class-showcase/arcanist.png" if id=="arcanist" else "assets/class-showcase/roster.png")
		character_view=home.find_child("ClassCharacterViewport",true,false)
		check(hero is TextureRect and hero.texture is ViewportTexture and hero.get_meta("animated_cover",false) and hero.get_meta("cover_class","")==id and hero.get_meta("cover_art_source","").ends_with(expected_asset) and character_view.class_id==id and character_view.animation_player.is_playing(),"Class page animates the approved "+id+" cover art independently")
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
	hero = home.find_child("ClassCoverArt",true,false)
	check(hero is TextureRect and not hero.texture is ViewportTexture and not hero.get_meta("animated_cover",true) and home.find_child("ClassCharacterViewport",true,false)==null and not hero.is_processing(),"Reduced effects uses a static class character cover")
	arena.profile.data.settings.reduced_effects = before.settings.reduced_effects
	check(arena.profile.data == before and arena.attempt_id == 0,"Class UI testing never spends, equips or starts a run")
	arena.queue_free()
	await process_frame
	print("Nightfall class showcase: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
