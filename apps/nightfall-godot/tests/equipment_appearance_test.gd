extends SceneTree
const Appearance = preload("res://equipment_appearance.gd")
const Profile = preload("res://profile.gd")
const Run = preload("res://run.gd")
const PATH := "user://nightfall_equipment_appearance_fixture.json"
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		push_error(message)
func _initialize() -> void:
	var profile=Profile.new(PATH)
	profile.save()
	var before: Dictionary=profile.data.duplicate(true)
	var fresh:=Appearance.from_profile(profile)
	check(Appearance.valid(fresh) and fresh.slots.helmet=="outrider" and fresh.weapon=="pistol","Starter gear has its actual Outrider look")
	check(profile.data==before,"Resolving appearance never changes profile")
	for stat in profile.Training.STATS:
		profile.combat_experience()[stat]=profile.Training.MAX_XP
	for family in ["outrider","ironwatch","riftweaver"]:
		for slot in Appearance.ARMOR:
			var item: Dictionary=profile.Loot.equipment(slot,"rare",profile.data.next_item,family)
			profile.data.inventory.append(item)
			profile.data.next_item+=1
			check(profile.equip(item.id),"Equip eligible "+family+" "+slot)
			var visual:=Appearance.from_profile(profile)
			check(visual.slots[slot]==family and visual.items[slot].id==item.id,"Equipped slot resolves authored family "+slot)
	var visual:=Appearance.from_profile(profile)
	check(Appearance.valid(visual) and profile.stats().appearance==visual,"Mission stats expose the exact current visual loadout")
	var frozen:=visual.duplicate(true)
	var run=Run.new(18)
	run.configure(1,profile.stats())
	var legacy_owned: Dictionary=run.snapshot()
	legacy_owned.erase("appearance")
	profile.data.active_attempt={"id":1,"class":"scavenger","checkpoint":Marshalls.variant_to_base64(legacy_owned,false)}
	check(profile.saved_run().appearance==frozen,"Real legacy attempt recovers its frozen owned equipment references")
	profile.data.active_attempt={}
	profile.data.equipment.boots=-1
	check(Appearance.from_profile(profile).slots.boots=="none","Empty slot requests neutral undersuit, not implicit armor")
	check(run.appearance==frozen,"Mission appearance cannot alias later profile changes")
	var snapshot: Dictionary=run.snapshot()
	var resumed=Run.new()
	check(resumed.restore(snapshot) and resumed.appearance==frozen,"Checkpoint preserves mixed equipped appearance")
	snapshot.appearance.slots.helmet="none"
	check(resumed.appearance==frozen,"Restored appearance cannot alias checkpoint dictionary")
	var invalid: Dictionary=run.snapshot()
	invalid.appearance.slots.body="unknown"
	check(not resumed.restore(invalid),"Corrupt armor family rejected")
	invalid=run.snapshot()
	invalid.appearance["class"]="engineer"
	check(not resumed.restore(invalid),"Appearance cannot change a saved run's class identity")
	invalid=run.snapshot()
	invalid.appearance.weapon="wand"
	check(not resumed.restore(invalid),"Visual weapon must match actual saved weapon")
	var legacy: Dictionary=run.snapshot()
	legacy.erase("appearance")
	check(resumed.restore(legacy) and resumed.appearance.slots.body=="none" and resumed.appearance.weapon==run.weapon_id,"Old checkpoints keep weapon and receive neutral visual armor")
	profile.combat_experience().defence=0.0
	visual=Appearance.from_profile(profile)
	profile.data.active_attempt={"id":1,"class":"scavenger","checkpoint":Marshalls.variant_to_base64(legacy_owned,false)}
	check(profile.saved_run().appearance.slots.body=="riftweaver","Legacy mission look survives newly enforced equip gates without changing stats")
	profile.data.active_attempt={}
	for slot in Appearance.ARMOR:
		if slot=="boots":continue
		check(visual.slots[slot]=="none" if not profile.equipment_eligible(profile.item_by_id(profile.data.equipment[slot])) else true,"Ineligible armor cannot remain visible "+slot)
	for id in profile.Content.CLASSES:
		check(Appearance.from_profile(profile,id)["class"]==id,"Class showcase keeps inspected identity "+id)
	var neutral:=Appearance.fresh()
	check(Appearance.valid(neutral),"Neutral appearance is valid")
	check(Appearance.signature(neutral)!=Appearance.signature(frozen),"Visible loadouts have distinct stable signatures")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(PATH+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	print("Equipment appearance: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
