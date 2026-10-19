extends RefCounted
## Optional material run. Campaign victory rules never call this objective.
const DURATION := 180.0
const BEACON_READY := 90.0
const EXIT := preload("res://world_geometry.gd").CENTER
const RADIUS := 60.0
const CHARGE := 3.0
const REWARDS := {"credits": 80, "parts": 2, "survivor_xp": 45, "mastery_xp": 25}

static func unlocked(profile: RefCounted) -> bool:
	return "clear" in profile.data.missions.get("1", [])

static func ready(run: RefCounted) -> bool:
	return run.elapsed >= BEACON_READY and run.field.caches_opened >= 3

static func tick(run: RefCounted, delta: float) -> void:
	if run.phase not in ["waves", "boss"] or run.paused or run.health <= 0:
		return
	if ready(run) and run.player.distance_to(EXIT) <= RADIUS:
		run.extract_progress = minf(CHARGE, run.extract_progress + delta)
		if run.extract_progress >= CHARGE:
			run.phase = "victory"
			run.field.collect_drops(run.player, 160)
	else:
		run.extract_progress = 0.0

static func objective(run: RefCounted) -> String:
	if run.field.caches_opened < 3:
		return "OPEN CACHES • %d/3" % run.field.caches_opened
	if run.elapsed < BEACON_READY:
		return "BEACON READY IN %ds" % ceili(BEACON_READY - run.elapsed)
	return "RETURN TO THE CENTRAL BEACON"
