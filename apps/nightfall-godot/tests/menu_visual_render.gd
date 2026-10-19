extends SceneTree
## Full noncombat visual catalog. All state is disposable and never saved.
var destination := ""
var failures := 0
var captures := 0
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			destination = arg.trim_prefix("--capture-dir=")
	call_deferred("capture")
func frame(arena: Node, name_value: String) -> void:
	for tick in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	if arena.home.visible and arena.home.body.get_global_rect().end.y > arena.home.navigation.position.y:
		failures += 1
		push_error("Menu overlaps navigation: " + name_value)
	assert(root.get_texture().get_image().save_png(destination.path_join(name_value + ".png")) == OK)
	captures += 1
func capture() -> void:
	assert(not destination.is_empty() and DirAccess.dir_exists_absolute(destination))
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	arena.profile.data.settings.reduced_effects = true
	var starter: Dictionary = arena.profile.data.duplicate(true)
	var home: Control = arena.home
	for dimensions in [Vector2i(430,760), Vector2i(320,568)]:
		root.size = dimensions
		var suffix := "-%dx%d" % [dimensions.x, dimensions.y]
		arena.profile.data = starter.duplicate(true)
		for page in ["shop","gear","mission","haven","class","talents","settings","zones","contracts","training","arcanum","mastery","skills","daily","calendar","builds","filters","sets","cache","rare_choice","rewards","craft"]:
			home.navigate(page)
			await frame(arena, page + "-starter" + suffix)
		for id in ["workshop","infirmary","quartermaster"]:
			home.facility = id
			home.navigate("facility")
			await frame(arena, "facility-"+id+suffix)
		arena.profile.data.credits = 2480
		arena.profile.data.parts = 240
		arena.profile.data.gems = 120
		arena.profile.data.rare_choices = 1
		for rank in 6:
			for slot in home.Content.SLOTS:
				var item: Dictionary = arena.profile.Loot.equipment(slot, home.Content.RARITIES[rank], arena.profile.data.next_item)
				arena.profile.data.next_item += 1
				arena.profile.data.inventory.append(item)
		var boots: Dictionary = arena.profile.Loot.equipment("boots","epic",arena.profile.data.next_item)
		arena.profile.data.next_item += 1
		arena.profile.data.inventory.append(boots)
		home.navigate("gear")
		await frame(arena,"gear-populated"+suffix)
		home.selected_item = boots.id
		home.rebuild()
		await frame(arena,"gear-popup"+suffix)
		home.page = "substats"
		home.rebuild()
		await frame(arena,"substats-populated"+suffix)
		home.page = "merge"
		home.selected_item = 0
		home.rebuild()
		await frame(arena,"merge-populated"+suffix)
		home.navigate("rare_choice")
		await frame(arena,"rare-choice-earned"+suffix)
		home.page = "cache"
		home.cache_receipt = true
		arena.profile.data.last_cache = {"category":"armor", "item":boots}
		home.rebuild()
		await frame(arena,"cache-receipt"+suffix)
		home.cache_receipt = false
		home.inspected_class = "arcanist"
		home.navigate("class")
		await frame(arena,"class-locked"+suffix)
		home.inspected_class = ""
		arena.profile.data.facilities.workshop = 2
		home.facility = "workshop"
		home.navigate("facility")
		await frame(arena,"facility-complete"+suffix)
		home.navigate("shop")
		home.ads_available = true
		home.rebuild()
		await frame(arena,"shop-video-ready"+suffix)
		home.ads_available = false
		home.confirmation = "key"
		home.rebuild()
		await frame(arena,"shop-purchase-confirm"+suffix)
		home.shop_flow.pending = "visual-fixture"
		home.shop_flow.message = "Loading your optional video..."
		home.rebuild()
		await frame(arena,"shop-loading"+suffix)
		home.shop_flow.pending = ""
		home.message = "Video unavailable. Your key balance has not changed."
		home.rebuild()
		await frame(arena,"shop-unavailable"+suffix)
		arena.profile.data.active_attempt = {"id":999,"mission":1}
		home.navigate("mission")
		await frame(arena,"mission-resume"+suffix)
		arena.profile.data.active_attempt = {}
		arena.profile.data.missions["5"] = ["clear"]
		arena.profile.data.breaker_plates = 8
		home.navigate("craft")
		await frame(arena,"craft-funded"+suffix)
		home.confirmation = "craft"
		home.rebuild()
		await frame(arena,"craft-confirm"+suffix)
	root.size = Vector2i(430,760)
	home.hide()
	arena.set_process(false)
	arena.run.kills = 194
	arena.run.level = 12
	arena.run.elapsed = 287
	arena.reward_receipt = {"credits":225,"parts":5,"gems":2,"survivor_xp":85,"mastery_xp":45,"keys":1,"new_medals":["clear","combat","scavenger"],"gear":["Outrider Boots","Beacon Ring"],"lost":3}
	for view in ["victory","defeat","pause","help","progress","diagnostics","ad"]:
		arena.reward_flow.pending = ""
		arena.help_view = view == "help"
		arena.progress_view = view == "progress"
		arena.diagnostics = view == "diagnostics"
		arena.run.phase = view if view in ["victory","defeat"] else "waves"
		arena.run.paused = view not in ["victory","defeat"]
		if view == "ad":
			arena.reward_flow.pending = "qa-rescue"
			arena.reward_flow.message = "Loading your optional rescue video..."
		arena.last_screen = ""
		arena.update_modal()
		await frame(arena,"modal-"+view+"-430x760")
		if not Rect2(0,0,430,760).encloses(arena.modal.get_global_rect()):
			failures += 1
			push_error("Modal does not fit: " + view)
	assert(arena.attempt_id == 0)
	print("Nightfall all-menu captures: %d captures, %d layout failures; disposable fixtures only." % [captures,failures])
	quit(1 if failures else 0)
