extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("verify")

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func visible_controls(node: Node) -> Array[Control]:
	var result: Array[Control] = []
	if node is Control and node.is_visible_in_tree():
		result.append(node)
	for child in node.get_children():
		result.append_array(visible_controls(child))
	return result

func settle() -> void:
	for frame in 5:
		await process_frame

func verify() -> void:
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	for viewport in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 760)]:
		root.size = viewport
		for page in ["mission", "gear", "haven", "class", "talents", "settings", "cache", "rare_choice", "rewards", "contracts", "training", "arcanum", "mastery"]:
			arena.home.page = page
			arena.home.rebuild()
			await settle()
			for control in visible_controls(arena.home):
				check(root.get_visible_rect().encloses(control.get_global_rect()), "%s screen overflow at %s: %s %s" % [page, viewport, control.get_class(), control.get_global_rect()])
			check(arena.home.body.get_global_rect().end.y <= arena.home.navigation.position.y, "%s content must not overlap navigation" % page)
		arena.home.page = "arcanum"
		for index in 8:
			arena.home.guide_index = index
			arena.home.rebuild()
			await settle()
			check(arena.home.body.get_global_rect().end.y <= arena.home.navigation.position.y, "Ability guide %d fits without scrolling" % index)
		arena.home.page = "training"
		for number in range(1, 6):
			arena.home.training_mission = number
			arena.home.rebuild()
			await settle()
			check(arena.home.body.get_global_rect().end.y <= arena.home.navigation.position.y, "Boss %d practice page fits without scrolling" % number)
		arena.home.page = "gear"
		for id in [0, 5]:
			arena.home.selected_item = id
			arena.home.rebuild()
			await settle()
			check(arena.home.body.get_global_rect().end.y <= arena.home.navigation.position.y, "Equipment detail fits above navigation")
		arena.home.selected_item = -1
		var epic: Dictionary = arena.profile.Loot.equipment("helmet", "epic", 99)
		arena.profile.data.inventory.append(epic)
		arena.home.selected_item = 99
		arena.home.rebuild()
		await settle()
		check(arena.home.body.get_global_rect().end.y <= arena.home.navigation.position.y, "Unequipped Epic detail and comparison fit the phone")
		arena.profile.data.inventory.pop_back()
		arena.home.page = "cache"
		arena.home.cache_receipt = true
		arena.profile.data.last_cache = {"category": "armor", "item": epic}
		arena.home.rebuild()
		await settle()
		check(arena.home.body.get_global_rect().end.y <= arena.home.navigation.position.y, "Chest receipt fits without scrolling")
		arena.home.cache_receipt = false
		arena.home.selected_item = -1
		arena.home.hide()
		arena.run.paused = false
		arena.run.phase = "shrine"
		for site in [0, 1]:
			arena.run.field.active_site = site
			arena.run.field.sites[site].offers = ["emberleaf", "obsidian"]
			arena.last_screen = ""
			arena.update_modal()
			await settle()
			check(root.get_visible_rect().encloses(arena.modal.get_global_rect()), "Shrine choices fit without scrolling")
		arena.run.phase = "pack"
		arena.run.field.bag.clear()
		for count in 8:
			arena.run.field.add_loot("parts", "Workshop Parts", count + 1)
		arena.pending_discard = 0
		arena.last_screen = ""
		arena.update_modal()
		await settle()
		check(root.get_visible_rect().encloses(arena.modal.get_global_rect()), "Full pack with discard confirmation fits phone")
		arena.run.phase = "build"
		arena.run.blueprints.assign(["barricade", "turret", "trap", "ward"])
		arena.last_screen = ""
		arena.update_modal()
		await settle()
		check(root.get_visible_rect().encloses(arena.modal.get_global_rect()), "All unlocked structures fit without scrolling")
		arena.run.class_id = "engineer"
		arena.run.mastery_level = 20
		arena.last_screen = ""
		arena.update_modal()
		await settle()
		check(root.get_visible_rect().encloses(arena.modal.get_global_rect()), "Engineer reclamation fits with all structures")
		arena.run.class_id = "scavenger"
		arena.run.mastery_level = 0
		arena.home.show()
	# Read-only fixtures must never create a real campaign save or grant rewards.
	check(arena.attempt_id == 0, "UI fixtures do not start a saved expedition")
	print("Nightfall Haven layout: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
