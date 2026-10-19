extends SceneTree
const Profile = preload("res://profile.gd")
const PATH := "user://nightfall_gear_popup_test.json"
var checks := 0
var failures := 0
func _initialize() -> void:
	call_deferred("verify")
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)
func settle() -> void:
	for frame in 8:
		await process_frame
func click_at(position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	root.push_input(motion)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = position
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event)
	await settle()
func cleanup() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
func verify() -> void:
	cleanup()
	var p = Profile.new(PATH)
	p.data.credits = 10000
	p.data.parts = 1000
	for index in 32:
		p.data.inventory.append(p.Loot.equipment(p.Content.SLOTS[index % 8], "epic", p.data.next_item))
		p.data.next_item += 1
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	arena.profile = p
	root.add_child(arena)
	arena.set_physics_process(false)
	var home: Control = arena.home
	home.show()
	home.navigate("gear")
	await settle()
	home.body.get_node("InventoryScroll").scroll_vertical = 88
	await settle()
	var original_scroll: int = home.inventory_scroll
	check(original_scroll > 0, "Fixture scrolls real owned inventory")
	for viewport in [Vector2i(430, 760), Vector2i(320, 568)]:
		root.size = viewport
		home.selected_item = 3
		home.rebuild()
		await settle()
		var overlay: Control = home.get_node("ItemDetailOverlay")
		check(overlay.get_node("ItemDetailPopup").visible and home.body.has_node("InventoryScroll"), "Popup overlays the preserved Gear grid")
		check(root.get_visible_rect().encloses(overlay.get_node("ItemDetailPopup").get_global_rect()), "Entire popup fits " + str(viewport))
		check(overlay.mouse_filter == Control.MOUSE_FILTER_STOP and home.navigation.get_child(0).focus_mode == Control.FOCUS_NONE, "Popup blocks background pointer and keyboard focus")
		var scale: float = minf(viewport.x / 430.0, viewport.y / 760.0)
		await click_at(Vector2(48, 720) * scale)
		check(home.page == "gear" and home.selected_item == 3, "Actual background navigation click is blocked")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		root.push_input(escape)
		await settle()
		check(home.selected_item == -1 and not home.has_node("ItemDetailOverlay"), "Escape closes popup")
		check(home.inventory_scroll == original_scroll, "Close restores original inventory scroll")
		check(home.navigation.get_child(0).focus_mode == Control.FOCUS_ALL, "Close restores navigation keyboard focus")
	root.size = Vector2i(430, 760)
	home.selected_item = 3
	home.rebuild()
	await settle()
	var before: Dictionary = p.data.duplicate(true)
	var cost: Dictionary = p.quick_upgrade_cost(3)
	find_button(home, "QuickUpgradeItem").pressed.emit()
	await settle()
	check(p.data == before and home.confirmation == "quick_upgrade", "First Quick Upgrade tap only confirms total levels and cost")
	find_button(home, "QuickUpgradeItem").pressed.emit()
	await settle()
	check(p.item_by_id(3).level == 5 and p.data.credits == before.credits - cost.credits and p.data.parts == before.parts - cost.parts, "Confirmed Quick Upgrade charges exact aggregate cost once")
	check(find_button(home, "QuickUpgradeItem").disabled, "Max-level item disables Quick Upgrade")
	home.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	check(not root.get_tree().quit_on_go_back, "Back remains consumed throughout the native notification")
	await settle()
	check(home.selected_item == -1 and not home.has_node("ItemDetailOverlay") and root.get_tree().quit_on_go_back, "Android Back closes popup and restores default back handling")
	home.selected_item = 0
	p.data.active_attempt = {"id": 4}
	home.rebuild()
	await settle()
	check(find_button(home, "UpgradeItem").disabled and find_button(home, "QuickUpgradeItem").disabled, "Active expedition blocks all upgrades in popup")
	check(arena.attempt_id == 0, "Popup fixture never starts a player expedition")
	arena.queue_free()
	await process_frame
	cleanup()
	print("Nightfall Gear popup: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func find_button(node: Node, node_name: String) -> Button:
	if node is Button and node.name == node_name:
		return node
	for child in node.get_children():
		var found := find_button(child, node_name)
		if found != null:
			return found
	return null
