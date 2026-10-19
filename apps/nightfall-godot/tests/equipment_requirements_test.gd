extends SceneTree
const Profile = preload("res://profile.gd")
const Rules = preload("res://equipment_requirements.gd")
const Training = preload("res://combat_progression.gd")
const Loot = preload("res://loot.gd")
const PATH := "user://nightfall_equipment_requirements_test.json"
var checks := 0
var failures := 0

func check(ok: bool, words: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(words)

func add_item(p: RefCounted, slot: String, level: int = 1, family: String = "pistol") -> Dictionary:
	var item := Loot.equipment(slot,"rare",p.data.next_item,"outrider",family)
	item.level = level
	p.data.next_item += 1
	p.data.inventory.append(item)
	return item

func train(p: RefCounted, class_id: String, skill: String, level: int) -> void:
	p.data.class_combat[class_id].xp[skill] = float(Training.threshold(level))
	p.sync_training_alias()

func _initialize() -> void:
	call_deferred("verify")

func verify() -> void:
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	var p := Profile.new(PATH)
	for rarity in p.Content.RARITIES:
		var starter := Loot.equipment("weapon",rarity,100)
		check(Rules.eligible(starter,Training.fresh()),"Rarity alone never gates level-one equipment")
	for family in ["pistol","scattergun","crossbow","sabre","wand"]:
		var item := Loot.equipment("weapon","common",100,"outrider",family)
		item.level = 5
		var skill: String = {"sabre":"strength","wand":"magic"}.get(family,"ranged")
		check(Rules.requirement(item)=={"skill":skill,"level":9},family+" uses the correct selected-class skill and level")
	p.data.credits = 10000
	p.data.parts = 1000
	var high := add_item(p,"weapon",3)
	var before: Dictionary = p.data.duplicate(true)
	check(not p.equip(high.id) and p.data==before and "Ranged 5" in p.error,"Ineligible equip reports its requirement without mutation")
	train(p,"scavenger","ranged",5)
	check(p.equip(high.id),"Meeting exact selected-class threshold permits equip")
	check(p.save_loadout("1","Trained"),"Eligible equipment can be saved")
	p.data.missions["4"] = ["clear"]
	p.data.loadouts["1"]["class"] = "engineer"
	before = p.data.duplicate(true)
	check(not p.apply_loadout("1") and p.data==before,"Saved class cannot borrow another class's equipment eligibility")
	p.data.inventory[1].level = 3
	train(p,"scavenger","defence",5)
	check(p.select_class("engineer") and p.data.equipment.weapon==0 and p.data.equipment.helmet==-1,"Fresh class selects eligible owned weapon and leaves unmet armor empty")
	check(p.item_by_id(1).level==3 and p.item_by_id(high.id).level==3,"Class switching preserves higher-level inventory")
	p.data.inventory[0].level = 3
	p.data.equipment.weapon = high.id
	check(p.select_class("engineer"),"No eligible owned weapon cannot deadlock class switching")
	var training_weapon := p.item_by_id(p.data.equipment.weapon)
	check(training_weapon.level==1 and training_weapon.get("training_item",false) and p.stats().power>0,"Fallback is a real usable level-one training item")
	var count: int = p.data.inventory.size()
	check(p.select_class("engineer") and p.data.inventory.size()==count,"Repeated class switching never duplicates training weapons")
	before = p.data.duplicate(true)
	check(not p.upgrade_item(training_weapon.id) and not p.quick_upgrade_item(training_weapon.id) and not p.salvage(training_weapon.id) and p.data==before,"Training reserve cannot be converted into upgrades or salvage currency")
	check(p.valid(p.data) and p.save(),"Empty nonweapon slots and training reserve remain valid durable saves")
	var loaded := Profile.new(PATH)
	check(loaded.load_save() and loaded.data==p.data,"Eligibility reconciliation survives restart without losing inventory")
	var low := add_item(p,"weapon",1)
	check(p.equip(low.id),"New class can equip its eligible ordinary equipment")
	before = p.data.duplicate(true)
	check(not p.upgrade_item(low.id) and p.data==before and "Ranged 3" in p.error,"Equipped upgrade cannot invalidate eligibility or spend funds")
	train(p,"engineer","ranged",3)
	check(p.quick_upgrade_cost(low.id).levels==1 and p.quick_upgrade_item(low.id) and low.level==2,"Bulk upgrade stops at the highest eligible level")
	var donor_a := add_item(p,"weapon",3)
	var donor_b := add_item(p,"weapon",1)
	before = p.data.duplicate(true)
	check(not p.merge_items(low.id,[donor_a.id,donor_b.id]) and p.data==before,"Higher-level donor cannot invalidate an equipped merge target")
	check(p.equip(training_weapon.id) and p.merge_items(low.id,[donor_a.id,donor_b.id]) and low.level==3 and p.data.equipment.weapon==training_weapon.id,"Unequipped merge keeps highest level without auto-equipping an ineligible result")
	p.data.equipment.weapon = low.id
	check(p.stats().power==0,"Ineligible legacy equipment cannot contribute Power through saved references")
	p.data.equipment.weapon = training_weapon.id
	p.data.inventory[5].level = 3
	check(p.stats().medkit==0,"An ineligible gadget cannot supply its once-per-run healing effect")
	var legacy := Profile.new(PATH)
	legacy.data.inventory[0].level = 3
	var legacy_owned: int = legacy.data.inventory.size()
	legacy.path = "user://missing-equipment-reconciliation/save.json"
	before = legacy.data.duplicate(true)
	check(legacy.start_attempt(1).is_empty() and legacy.data==before,"Failed expedition save rolls back training reserve creation and equipment reconciliation")
	legacy.path = PATH
	var attempt := legacy.start_attempt(1)
	check(not attempt.is_empty() and legacy.data.inventory.size()==legacy_owned+1 and legacy.item_by_id(0).level==3 and legacy.stats().power==40,"Starting a legacy expedition preserves ineligible owned weapon and equips real training reserve")
	legacy.finish_attempt(attempt.id,{"victory":false})
	var arena = load("res://main.tscn").instantiate()
	arena.testing = true
	arena.profile = p
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.show()
	arena.home.page = "gear"
	arena.home.selected_item = low.id
	arena.home.rebuild()
	for frame in 5: await process_frame
	var requirement: Label = arena.home.find_child("ItemRequirement",true,false)
	check(requirement!=null and "Ranged 5" in requirement.text and arena.home.find_child("EquipItem",true,false).disabled,"Item popup names unmet selected-class requirement and disables Equip")
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var directory := ProjectSettings.globalize_path("res://../../artifacts/nightfall-godot/equipment-requirements")
		DirAccess.make_dir_recursive_absolute(directory)
		root.get_texture().get_image().save_png(directory.path_join("locked-item.png"))
	arena.queue_free()
	await process_frame
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	print("Equipment requirements: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
