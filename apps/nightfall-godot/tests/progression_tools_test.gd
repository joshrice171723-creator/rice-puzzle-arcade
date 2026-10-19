extends SceneTree
const Profile = preload("res://profile.gd")
const Run = preload("res://run.gd")
const Skills = preload("res://skill_tree.gd")
const PATH := "user://nightfall_progression_tools_test.json"
var checks := 0
var failures := 0

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
	call_deferred("verify")

func settle() -> void:
	for frame in 6:
		await process_frame

func button_in(node: Node, prefix: String) -> Button:
	if node is Button and node.text.begins_with(prefix):
		return node
	for child in node.get_children():
		var found := button_in(child, prefix)
		if found != null:
			return found
	return null

func verify() -> void:
	cleanup()
	var p = Profile.new(PATH)
	var legacy: Dictionary = p.fresh()
	legacy.version = 2
	legacy.erase("loadouts")
	legacy.erase("locked_items")
	legacy.erase("skill_unlocks")
	legacy.mastery.scavenger = 4500
	legacy.active_attempt = {"id": 10, "checkpoint": "unchanged"}
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	check(p.load_save() and p.valid(p.data), "Version 2 migrates to valid version 3")
	check(p.data.active_attempt == legacy.active_attempt and p.data.inventory == legacy.inventory, "Migration preserves checkpoint and inventory")
	check(p.skill_points("scavenger") == 0 and p.data.skill_unlocks.scavenger.is_empty(), "Migration keeps mastery separate from combat talent points")
	p.data.active_attempt = {}
	check(p.save_loadout("1", "Scavenging"), "Save current equipment build")
	var extra: Dictionary = p.Loot.equipment("weapon", "rare", p.data.next_item)
	p.data.inventory.append(extra)
	p.data.next_item += 1
	p.data.missions["4"] = ["clear"]
	check(p.select_class("engineer") and p.equip(extra.id) and p.save_loadout("2", "Boss hunting"), "Second build owns a different class and weapon")
	check(p.data.loadouts["1"].equipment.weapon == 0 and p.data.loadouts["1"]["class"] == "scavenger", "Saved build never aliases current equipment")
	check(not p.salvage(0), "Unequipped build item cannot be salvaged")
	p.data.credits = 1000
	p.data.parts = 100
	check(p.upgrade_item(extra.id), "Upgrade a saved item normally")
	check(p.apply_loadout("1") and p.data["class"] == "scavenger" and p.data.equipment.weapon == 0, "Apply restores all gear and class")
	check(p.apply_loadout("2") and p.stats().power > 43 and p.item_by_id(extra.id).level == 2, "Build uses live upgraded item values")
	check(p.remove_loadout("1") and p.set_item_locked(0, true) and not p.salvage(0), "Explicit lock protects an item after its build is removed")
	check(p.set_item_locked(0, false) and p.salvage(0), "Only an unlocked unequipped unsaved item can be salvaged")
	check(p.valid(p.data), "Salvage leaves no stale build or lock references")
	check(not p.save_loadout("4", "Invalid") and not p.save_loadout("1", " ") and not p.save_loadout("1", "x".repeat(21)), "Reject invalid build slots and names")
	check(not p.unlock_skill("warden", "ember"), "Locked class cannot purchase skills")
	check(not p.unlock_skill("scavenger", "gravity"), "Capstone requires both parent branches")
	p.data.mastery.engineer = 0
	check(not p.unlock_skill("engineer", "frost"), "Mastery alone cannot grant combat talent points")
	for stat in p.Training.STATS:
		p.data.combat_xp[stat] = float(p.Training.threshold(10))
	for ability: String in Skills.BRANCHES.scavenger:
		check(p.unlock_skill("scavenger", ability), "Unlock prerequisite-ordered node " + ability)
	check(p.skill_points("scavenger") == 0 and p.ability_pool("scavenger").size() == 8, "Nine earned points unlock all five nodes")
	check(not p.unlock_skill("scavenger", "wisp"), "Duplicate unlock cannot spend again")
	check(p.ability_pool("engineer") == Skills.STARTERS.engineer, "Class unlock pools remain independent")
	var invalid: Dictionary = p.data.duplicate(true)
	invalid.skill_unlocks.scavenger = ["gravity"]
	check(not p.valid(invalid), "Broken tree dependencies rejected when loading")
	invalid = p.data.duplicate(true)
	invalid.loadouts["2"].equipment.weapon = 99999
	check(not p.valid(invalid), "Missing equipment in saved builds rejected")
	invalid = p.data.duplicate(true)
	invalid.locked_items = [99999]
	check(not p.valid(invalid), "Dangling item locks rejected")
	check(p.save(), "Save prepared profile")
	var reloaded = Profile.new(PATH)
	check(reloaded.load_save() and reloaded.data.loadouts == p.data.loadouts and reloaded.data.skill_unlocks == p.data.skill_unlocks, "Build and skill ownership survive restart")
	p.data.active_attempt = {"id": 44}
	var before: Dictionary = p.data.duplicate(true)
	check(not p.save_loadout("1", "Locked") and not p.apply_loadout("2") and not p.remove_loadout("2") and not p.set_item_locked(extra.id, true) and not p.unlock_skill("engineer", "frost") and p.data == before, "Active expedition blocks build and skill mutations")
	p.data.active_attempt = {}
	for stat in p.Training.STATS:
		p.data.combat_xp[stat] = float(p.Training.threshold(11))
	before = p.data.duplicate(true)
	p.path = "user://missing-progression-tools-dir/save.json"
	check(not p.save_loadout("1", "Write fail") and p.data == before, "Failed build write rolls back")
	check(not p.apply_loadout("2") and p.data == before, "Failed build equip write rolls back")
	check(not p.remove_loadout("2") and p.data == before, "Failed build clear write rolls back")
	check(not p.set_item_locked(extra.id, true) and p.data == before, "Failed lock write rolls back")
	check(not p.unlock_skill("engineer", "frost") and p.data == before, "Failed skill write refunds point and ownership")
	p.path = PATH
	p.error = ""
	# Repeated seeded drafts must never offer a class-locked spell.
	var observed: Array = []
	for seed_value in 60:
		var run = Run.new(seed_value)
		run.configure(1, p.stats())
		for level in range(2, 15):
			run.level = level
			run.make_offers()
			var ids: Array = []
			for offer in run.offers:
				check(offer.id not in ids, "No duplicate level-up choice")
				ids.append(offer.id)
				if offer.id in run.Content.SPELLS:
					check(offer.id in Skills.STARTERS.engineer, "Locked spell excluded from Engineer drafts")
					if offer.id not in observed:
						observed.append(offer.id)
	check(observed.size() == 3, "Every starter can appear")
	check(p.unlock_skill("engineer", "frost"), "Earned point expands Engineer pool")
	var found_frost := false
	for seed_value in 50:
		var run = Run.new(seed_value)
		run.configure_contract(p.stats(), "ring")
		run.level = 2
		run.make_offers()
		found_frost = found_frost or run.offers.any(func(offer): return offer.id == "frost")
	check(found_frost, "New permanent unlock appears in actual contract level-up draft")
	var run = Run.new(10)
	run.configure(1, p.stats())
	run.phase = "upgrade"
	run.level = 2
	run.make_offers()
	var restored = Run.new(99)
	check(restored.restore(run.snapshot()) and restored.available_spells == run.available_spells and restored.offers == run.offers, "Checkpoint preserves pool and pending choices")
	restored.paused = false
	restored.choose_offer(0)
	check(restored.spells.size() == 1 and restored.phase == "waves", "Restored draft grants an actual automatic spell")
	var next_run = Run.new(1)
	next_run.configure(1, p.stats())
	check(next_run.spells.is_empty() and next_run.available_spells.has("frost"), "Run ranks reset while permanent availability persists")
	var old_snapshot: Dictionary = run.snapshot()
	old_snapshot.erase("available_spells")
	check(restored.restore(old_snapshot) and restored.available_spells.size() == 8, "Pre-tree saved run retains its original ability pool")
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	arena.profile = p
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	var home: Control = arena.home
	home.navigate("gear")
	await settle()
	button_in(home, "Builds").pressed.emit()
	await settle()
	check(home.page == "builds" and home.active_tab() == "gear", "Gear opens saved builds within the Gear tab")
	home.body.get_node("BuildName").text = "Field kit"
	home.body.get_node("BuildName").text_changed.emit("Field kit")
	button_in(home, "Save current").pressed.emit()
	await settle()
	check(p.data.loadouts["1"].name == "Field kit", "Build form saves chosen name")
	before = p.data.loadouts.duplicate(true)
	button_in(home, "Replace with current").pressed.emit()
	await settle()
	check(p.data.loadouts == before and button_in(home, "Confirm replace") != null, "Replacing a build requires a second tap")
	button_in(home, "Confirm replace").pressed.emit()
	await settle()
	button_in(home, "Clear build").pressed.emit()
	await settle()
	check(p.data.loadouts.has("1"), "Clearing a build requires a second tap")
	button_in(home, "Confirm clear").pressed.emit()
	await settle()
	check(not p.data.loadouts.has("1"), "Clear confirmation removes saved build")
	home.navigate("gear")
	await settle()
	button_in(home, "Filter").pressed.emit()
	await settle()
	home.body.get_node("SlotFilter").item_selected.emit(1)
	await settle()
	home.body.get_node("RarityFilter").item_selected.emit(3)
	await settle()
	button_in(home, "Show inventory").pressed.emit()
	await settle()
	var grid: GridContainer = home.body.get_node("InventoryScroll/InventoryGrid")
	check(grid.columns == 5 and grid.get_child_count() == 1 and grid.get_child(0).name == "Item%d" % extra.id, "Combined slot and rarity filter displays matching item in five-wide grid")
	grid.get_child(0).pressed.emit()
	await settle()
	button_in(home, "Lock item").pressed.emit()
	await settle()
	check(extra.id in p.data.locked_items, "Detail screen locks actual inventory item")
	home.navigate("class")
	await settle()
	home.find_child("OpenClassSkills", true, false).pressed.emit()
	home.find_child("TalentPreviewOpenTree", true, false).pressed.emit()
	await settle()
	check(home.page == "skills" and home.active_tab() == "class", "Class opens its permanent tree")
	for stat in p.Training.STATS:
		p.data.combat_xp[stat] = float(p.Training.threshold(12))
	home.body.get_node("ClassSkillTree/Skill_lance").pressed.emit()
	await settle()
	check(not home.body.get_node("HBoxContainer/UnlockSkill").disabled if home.body.has_node("HBoxContainer/UnlockSkill") else not button_in(home, "Unlock ·").disabled, "Earned point enables eligible tree node")
	button_in(home, "Unlock ·").pressed.emit()
	await settle()
	check("lance" in p.ability_pool("engineer"), "Tree button permanently unlocks real draft ability")
	for viewport in [Vector2i(320, 568), Vector2i(390, 844), Vector2i(430, 760)]:
		root.size = viewport
		for page in ["gear", "filters", "builds", "skills", "class"]:
			home.navigate(page)
			await settle()
			check(home.body.get_global_rect().end.y <= home.navigation.position.y and home.body.size.x <= 386, page + " fits phone at " + str(viewport))
		for class_id in Skills.STARTERS:
			home.inspected_class = class_id
			home.page = "skills"
			home.rebuild()
			await settle()
			check(home.body.get_global_rect().end.y <= home.navigation.position.y, class_id + " tree fits including locked classes")
	arena.queue_free()
	await process_frame
	cleanup()
	print("Nightfall progression tools: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
