extends SceneTree
## Disposable visual fixtures: no player save is loaded or written.
var destination := ""
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			destination = arg.trim_prefix("--capture-dir=")
	call_deferred("capture")
func frame(name: String) -> void:
	for tick in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(destination.path_join(name + ".png")) == OK)
func capture() -> void:
	assert(not destination.is_empty() and DirAccess.dir_exists_absolute(destination))
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	arena.home.page = "gear"
	arena.profile.data.settings.reduced_effects = true
	var starter: Dictionary = arena.profile.data.duplicate(true)
	for dimensions in [Vector2i(430, 760), Vector2i(320, 568), Vector2i(860, 760)]:
		root.size = dimensions
		arena.profile.data = starter.duplicate(true)
		arena.home.selected_item = -1
		arena.home.rebuild()
		await frame("gear-starter-%dx%d" % [dimensions.x, dimensions.y])
	root.size = Vector2i(430, 760)
	for family: String in arena.run.Weapons.TYPES:
		arena.profile.item_by_id(arena.profile.data.equipment.weapon).name = arena.run.Weapons.TYPES[family].name
		arena.home.rebuild()
		await frame("gear-equipped-"+family)
	arena.profile.data = starter.duplicate(true)
	for rank in 6:
		var item: Dictionary = arena.profile.Loot.equipment(arena.home.Content.SLOTS[rank], arena.home.Content.RARITIES[rank], arena.profile.data.next_item)
		arena.profile.data.next_item += 1
		arena.profile.data.inventory.append(item)
	arena.home.rebuild()
	await frame("gear-mixed-rarity-fixture-430x760")
	var tile: Button = arena.home.body.get_node("InventoryScroll/InventoryGrid").get_child(0)
	tile.pressed.emit()
	await frame("gear-inspection-430x760")
	var boots: Dictionary = arena.profile.Loot.equipment("boots", "epic", arena.profile.data.next_item)
	arena.profile.data.next_item += 1
	arena.profile.data.inventory.append(boots)
	arena.profile.data.credits = 2480
	arena.profile.data.parts = 36
	arena.profile.data.gems = 120
	for dimensions in [Vector2i(430, 760), Vector2i(320, 568)]:
		root.size = dimensions
		arena.home.selected_item = boots.id
		arena.home.rebuild()
		await frame("gear-popup-epic-boots-fixture-%dx%d" % [dimensions.x, dimensions.y])
	root.size = Vector2i(430, 760)
	arena.home.confirmation = "quick_upgrade"
	var quick_cost: Dictionary = arena.profile.quick_upgrade_cost(boots.id)
	arena.home.message = "Upgrade %d levels · %d credits + %d parts" % [quick_cost.levels, quick_cost.credits, quick_cost.parts]
	arena.home.rebuild()
	await frame("gear-popup-quick-confirm-fixture-430x760")
	arena.profile.data = starter.duplicate(true)
	for dimensions in [Vector2i(430, 760), Vector2i(320, 568)]:
		root.size = dimensions
		for page in ["shop", "mission", "haven", "class"]:
			arena.home.navigate(page)
			await frame("menu-%s-%dx%d" % [page, dimensions.x, dimensions.y])
	assert(arena.attempt_id == 0)
	print("Nightfall Gear captures: starter 430, 320, desktop; mixed-rarity fixture; inspection. No player save used.")
	quit()
