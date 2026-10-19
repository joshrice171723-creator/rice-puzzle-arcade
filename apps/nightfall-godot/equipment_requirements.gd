extends RefCounted
## Upgrade level sets eligibility; rarity and item bonuses never supply skill levels.
const Training = preload("res://combat_progression.gd")
const Weapons = preload("res://weapons.gd")
const Content = preload("res://haven_content.gd")
const ARMOR := ["helmet","body","boots","pants"]
const WEAPON_BASE_LEVELS := {"pistol":1,"scattergun":1,"crossbow":1,"sabre":1,"wand":1}
const ARMOR_BASE_LEVELS := {"outrider":1,"ironwatch":1,"riftweaver":1}

static func requirement(item: Dictionary) -> Dictionary:
	if item.is_empty():
		return {}
	var skill := "vitality"
	var floor_level := 1
	if item.slot in ARMOR:
		skill = "defence"
		floor_level = ARMOR_BASE_LEVELS.get(Content.set_id(item),1)
	elif item.slot == "weapon":
		var family := Weapons.family(item)
		skill = "strength" if family == "sabre" else ("magic" if family == "wand" else "ranged")
		floor_level = WEAPON_BASE_LEVELS.get(family,1)
	return {"skill":skill,"level":maxi(floor_level,1+2*(clampi(int(item.get("level",1)),1,30)-1))}

static func eligible(item: Dictionary, experience: Dictionary) -> bool:
	var need := requirement(item)
	return not need.is_empty() and Training.level(experience.get(need.skill,0.0)) >= need.level

static func description(item: Dictionary, experience: Dictionary, hero_name: String) -> String:
	var need := requirement(item)
	if need.is_empty():
		return "Empty slot"
	return "Requires %s %d · %s has %d" % [str(need.skill).capitalize(),need.level,hero_name,Training.level(experience.get(need.skill,0.0))]
