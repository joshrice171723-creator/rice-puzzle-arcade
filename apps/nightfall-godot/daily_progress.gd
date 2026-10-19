extends RefCounted
## Daily progress is committed with expedition banking, never per UI refresh.

const OBJECTIVES := [
	{"id": "kills", "label": "Defeat enemies", "target": 100},
	{"id": "caches", "label": "Open field caches", "target": 3},
	{"id": "attempts", "label": "Finish expeditions", "target": 2},
	{"id": "clears", "label": "Clear a mission or contract", "target": 1}]
const CALENDAR := [
	{"credits": 75}, {"parts": 3}, {"credits": 100}, {"cache_keys": 1},
	{"parts": 5}, {"gems": 10}, {"cache_keys": 2}]
const BONUS := {"credits": 75, "parts": 3, "cache_keys": 1}

static func fresh() -> Dictionary:
	return {"day": -1, "progress": {"kills": 0, "caches": 0, "attempts": 0, "clears": 0},
		"claimed": false, "pending_bonuses": 0, "calendar_count": 0, "calendar_day": -1}

static func valid(state: Variant) -> bool:
	if not state is Dictionary:
		return false
	for key in ["day", "calendar_day", "pending_bonuses", "calendar_count"]:
		if not state.get(key) is int or state[key] < (-1 if key in ["day", "calendar_day"] else 0):
			return false
	if not state.get("claimed") is bool or not state.get("progress") is Dictionary:
		return false
	for objective in OBJECTIVES:
		var value: Variant = state.progress.get(objective.id)
		if not value is int or value < 0 or value > objective.target:
			return false
	return state.calendar_day <= state.day and (not state.claimed or completed(state) >= 3)

static func completed(state: Dictionary) -> int:
	var count := 0
	for objective in OBJECTIVES:
		if state.progress[objective.id] >= objective.target:
			count += 1
	return count

static func available_bonuses(state: Dictionary) -> int:
	return state.pending_bonuses + int(completed(state) >= 3 and not state.claimed)

static func at_day(state: Dictionary, day: int) -> Dictionary:
	var next := state.duplicate(true)
	# A clock rollback cannot refresh objectives or permit a second calendar claim.
	if day > next.day:
		if completed(next) >= 3 and not next.claimed:
			next.pending_bonuses += 1
		next.day = day
		next.progress = fresh().progress
		next.claimed = false
	return next

static func record(state: Dictionary, outcome: Dictionary) -> void:
	if not outcome.get("progress_eligible", false):
		return
	var won: bool = outcome.get("victory", false)
	if not won and float(outcome.get("seconds", 0)) < 60:
		return
	var gains := {"kills": maxi(0, int(outcome.get("kills", 0))),
		"caches": maxi(0, int(outcome.get("caches", 0))), "attempts": 1, "clears": int(won)}
	for objective in OBJECTIVES:
		state.progress[objective.id] = mini(objective.target, state.progress[objective.id] + gains[objective.id])

static func reward_text(reward: Dictionary) -> String:
	var parts: PackedStringArray = []
	var names := {"credits": "Credits", "parts": "Parts", "gems": "Gems", "cache_keys": "Supply keys"}
	for key in reward:
		parts.append("%d %s" % [reward[key], names[key]])
	return " · ".join(parts)
