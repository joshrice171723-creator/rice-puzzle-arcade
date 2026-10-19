extends RefCounted
## Permanent availability, distinct from ranks and evolutions earned inside a run.
const Combat = preload("res://combat_content.gd")
const STARTERS := {
	"scavenger": ["ember", "frost", "chain"],
	"engineer": ["ember", "chain", "wisp"],
	"warden": ["frost", "lance", "ground"],
	"arcanist": ["ember", "frost", "wisp"]}
const BRANCHES := {
	"scavenger": ["wisp", "blades", "lance", "ground", "gravity"],
	"engineer": ["frost", "lance", "ground", "blades", "gravity"],
	"warden": ["ember", "wisp", "blades", "chain", "gravity"],
	"arcanist": ["chain", "lance", "blades", "ground", "gravity"]}
const COSTS := [1, 1, 2, 2, 3]
const POINT_CAP := 9

static func cost(class_id: String, ability: String) -> int:
	var index: int = BRANCHES.get(class_id, []).find(ability)
	return COSTS[index] if index >= 0 else 0

static func parents(class_id: String, ability: String) -> Array:
	var path: Array = BRANCHES.get(class_id, [])
	var index: int = path.find(ability)
	if index in [0, 1]:
		return [STARTERS[class_id][index]]
	if index in [2, 3]:
		return [path[index - 2]]
	if index == 4:
		return [path[2], path[3]]
	return []

static func pool(class_id: String, unlocks: Array) -> Array:
	var result: Array = STARTERS[class_id].duplicate()
	for id: String in BRANCHES[class_id]:
		if id in unlocks:
			result.append(id)
	return result

static func spent(class_id: String, unlocks: Array) -> int:
	var total := 0
	for id: String in unlocks:
		total += cost(class_id, id)
	return total

static func prerequisites_met(class_id: String, ability: String, unlocks: Array) -> bool:
	var available := pool(class_id, unlocks)
	for id in parents(class_id, ability):
		if id not in available:
			return false
	return true
