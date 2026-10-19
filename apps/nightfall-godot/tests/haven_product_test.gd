extends SceneTree
const Profile = preload("res://profile.gd")
const Flow = preload("res://shop_reward.gd")
const PATH := "user://nightfall_home_product_test.json"
var checks := 0
var failures := 0
var capture_dir := ""

func check(value: bool, description: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(description)

func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			capture_dir = arg.trim_prefix("--capture-dir=")
	call_deferred("verify")

func settle() -> void:
	for frame in 6:
		await process_frame

func find_button(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := find_button(child, prefix)
		if found != null:
			return found
	return null

func verify() -> void:
	cleanup()
	var p = Profile.new(PATH)
	var legacy: Dictionary = p.fresh()
	legacy.version = 1
	legacy.inventory.resize(6)
	legacy.equipment.erase("ring")
	legacy.equipment.erase("pants")
	legacy.next_item = 6
	legacy.credits = 900
	legacy.inventory[0].level = 4
	legacy.active_attempt = {"id": 1, "mission": 1, "checkpoint": "preserve-this"}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(p.load_save() and p.valid(p.data), "Six-slot save migrates to valid eight-slot profile")
	check(p.data.inventory.size() == 8 and p.data.inventory[0].level == 4 and p.data.credits == 900, "Migration preserves existing items, IDs, upgrades and money")
	check(p.data.active_attempt == legacy.active_attempt, "Migration preserves the active checkpoint unchanged")
	check(p.load_save() and p.data.inventory.size() == 8, "Repeated load of legacy file never duplicates new slots")
	p.data.active_attempt = {}
	p.data.inventory[0].level = 1
	check(p.stats().hp == 210 and p.stats().power == 40 and p.stats().armor == 35, "Eight slots retain original starter stat budget")
	p.data.gems = 50
	check(p.purchase_supply("key") and p.data.gems == 25 and p.data.cache_keys == 1, "Shop spends exact gems and grants one key")
	check(p.purchase_supply("parts") and p.data.credits == 700 and p.data.parts == 10, "Material purchase spends credits and grants exact quantity")
	var before: Dictionary = p.data.duplicate(true)
	p.path = "user://missing-home-product-folder/save.json"
	check(not p.purchase_supply("key") and p.data == before, "Failed purchase write rolls back spending and grant")
	p.path = PATH
	var flow = Flow.new()
	var token: String = flow.begin(p)
	check(not token.is_empty() and flow.begin(p).is_empty(), "Only one shop video request at a time")
	check(not flow.reward("stale", p) and p.data.cache_keys == 1, "Unrelated callback grants no key")
	flow.finish(token)
	check(p.data.cache_keys == 1 and p.shop_videos_left() == 2, "Closing without earned callback grants nothing and consumes no quota")
	token = flow.begin(p)
	check(flow.reward(token, p) and p.data.cache_keys == 2 and p.shop_videos_left() == 1, "Completion callback grants one persisted key")
	check(flow.reward(token, p) and p.data.cache_keys == 2, "Duplicate callback is idempotent")
	flow.finish(token)
	check(not flow.reward(token, p), "Late callback after close cannot grant twice")
	token = flow.begin(p)
	p.path = "user://missing-home-product-folder/save.json"
	check(not flow.reward(token, p) and p.data.cache_keys == 2, "Ad save failure preserves earned pending reward without partial grant")
	flow.finish(token)
	check(flow.pending == token and flow.earned and flow.closed, "Closing after write failure keeps reward available to retry")
	p.path = PATH
	check(flow.reward(token, p) and flow.pending.is_empty() and p.data.cache_keys == 3, "Retry after failed save grants once then clears pending")
	check(flow.begin(p).is_empty() and p.shop_videos_left() == 0, "Daily cap rejects further requests")
	var reloaded = Profile.new(PATH)
	check(reloaded.load_save() and reloaded.data.cache_keys == 3 and reloaded.shop_videos_left() == 0, "Rewards and quota persist across restart")
	p.data.shop_day = "2000-01-01"
	check(p.shop_videos_left() == 2, "New UTC day refreshes availability")
	p.data.active_attempt = {"id": 4}
	var during_run: String = flow.begin(p)
	check(not during_run.is_empty() and p.purchase_supply("parts") and not p.equip(0), "Shop supplies work during a saved expedition without permitting loadout changes")
	flow.finish(during_run)
	p.data.active_attempt = {}
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	arena.profile = p
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	check(Input.emulate_mouse_from_touch, "Native menu buttons receive emulated pointer events")
	arena.home.hide()
	check(not Input.emulate_mouse_from_touch, "Returning to combat restores original touch handling")
	arena.home.show()
	var home: Control = arena.home
	check(home.navigation.get_child_count() == 5 and home.navigation.get_child(2).text == "Expedition", "Five tabs put Expedition in the center")
	check(home.wallet.get_child_count() == 3, "Header uses three currency icons with balances")
	check(home.compact_amount(9999) == "9999" and home.compact_amount(12000) == "12K" and home.compact_amount(2500000) == "2.5M", "Large currency balances fit the compact header")
	home.navigation.get_child(0).pressed.emit()
	await settle()
	var purchase: Button = find_button(home, "Supply key ·")
	var gems_before: int = p.data.gems
	purchase.pressed.emit()
	await settle()
	check(p.data.gems == gems_before, "First shop tap shows confirmation without spending")
	find_button(home, "Confirm: Supply key").pressed.emit()
	await settle()
	check(p.data.gems == gems_before - 25, "Second shop tap commits the displayed purchase")
	home.navigation.get_child(3).pressed.emit()
	await settle()
	find_button(home, "Infirmary").pressed.emit()
	await settle()
	check(home.page == "facility" and home.facility == "infirmary", "Base Infirmary button opens the actual upgrade page")
	home.navigation.get_child(1).pressed.emit()
	await settle()
	find_button(home, "Sort: Rarity").pressed.emit()
	await settle()
	check(home.inventory_sort == "Slot", "Visible Sort button changes inventory order")
	for index in 42:
		var item: Dictionary = p.Loot.equipment(p.Content.SLOTS[index % 8], p.Content.RARITIES[index % 4], p.data.next_item)
		p.data.next_item += 1
		p.data.inventory.append(item)
	p.data.missions = {"1": ["clear"], "2": ["clear"], "3": ["clear"], "4": ["clear"]}
	p.data.parts = 100
	p.data.credits = 2480
	p.data.gems = 120
	home.ads_available = true
	for viewport in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 760)]:
		root.size = viewport
		for page in ["shop", "gear", "mission", "haven", "class", "zones", "facility"]:
			home.page = page
			home.rebuild()
			await settle()
			check(home.body.get_global_rect().end.y <= home.navigation.position.y, page + " fits above tabs at " + str(viewport))
			check(home.body.size.x <= 386, page + " fits phone width")
			if page == "gear":
				check(find_button(home, "Sort:").size.x >= 100, "Sort control has room for its label")
				var scroll: ScrollContainer = home.body.get_node("InventoryScroll")
				var grid: GridContainer = scroll.get_node("InventoryGrid")
				check(grid.columns == 5 and grid.get_child_count() == 50, "Full inventory stays five wide with all owned items")
				var hero_position: Vector2 = home.body.get_child(1).global_position
				scroll.scroll_vertical = 10000
				await settle()
				check(scroll.scroll_vertical > 0 and home.body.get_child(1).global_position == hero_position, "Inventory scroll moves items while equipped hero stays fixed")
				grid.get_child(49).pressed.emit()
				await settle()
				check(home.selected_item >= 0 and home.body.get_global_rect().end.y <= home.navigation.position.y, "Last inventory item opens a fitting details page")
				home.selected_item = -1
			if page == "mission":
				check(find_button(home, "Zones").size.x >= 62, "Zones control has room for its label")
		for class_id in home.Content.CLASSES:
			home.inspected_class = class_id
			home.page = "class"
			home.rebuild()
			await settle()
			check(home.body.get_global_rect().end.y <= home.navigation.position.y, class_id + " class preview fits")
		home.inspected_class = ""
	# Exercise the actual controller callbacks, not only the isolated reward model.
	home.page = "shop"
	home.shop_flow = Flow.new()
	var native_token: String = home.shop_flow.begin(p)
	var keys: int = p.data.cache_keys
	arena.earned_rescue(native_token)
	arena.finished_rescue(native_token, true)
	check(p.data.cache_keys == keys + 1 and home.shop_flow.pending.is_empty(), "Controller routes shop reward and close callbacks to persistent key grant")
	arena.earned_rescue(native_token)
	check(p.data.cache_keys == keys + 1, "Controller ignores replayed native callback")
	home.inspected_class = "engineer"
	home.page = "class"
	home.rebuild()
	await settle()
	check(p.select_class("engineer"), "Unlocked Engineer selection persists through the same profile path")
	home.facility = "infirmary"
	check(p.upgrade_facility("infirmary") and p.stats().medkit == 0.25, "Infirmary upgrade still changes actual loadout")
	# Captures use disposable fixtures, never the player's profile.
	if not capture_dir.is_empty() and DisplayServer.get_name() != "headless":
		root.size = Vector2i(430, 760)
		p.data["class"] = "scavenger"
		home.inspected_class = ""
		home.ads_available = false
		home.message = ""
		p.error = ""
		for page in ["shop", "gear", "mission", "haven", "class"]:
			home.page = page
			home.inventory_scroll = 0
			home.rebuild()
			await settle()
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png(capture_dir.path_join(page + ".png")) == OK, "Capture saved: " + page)
	arena.queue_free()
	await process_frame
	cleanup()
	print("Nightfall home product: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
