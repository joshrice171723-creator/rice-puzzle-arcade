extends RefCounted
## Persistent mastery unlocks, with attempt-local proc state kept in checkpoints.
const TALENTS := {
	"scavenger": [
		["Cache Sense", "Marks unopened caches within 250 range."],
		["Unbound Step", "Phase Step removes the Spitter's slowing effect."],
		["Opening Shot", "After Phase Step, your next basic hit deals 25% more damage."],
		["Last Light", "Survive one lethal hit at 1 HP per expedition, with 2 seconds of protection."]],
	"engineer": [
		["Efficient Assembly", "Construction costs 10% less Field Scrap."],
		["Overclock", "Repair Swarm gives its target turret 15% faster firing for 4 seconds."],
		["Reclaim", "Dismantle a nearby structure to recover 40% of the scrap actually spent."],
		["Linked Repairs", "Repair Swarm also restores 5% HP to one damaged structure within 150 of its target."]]}
var slow_left := 0.0
var opening_shot := false
var last_light_used := false

func snapshot() -> Dictionary:
	return {"slow_left": slow_left, "opening_shot": opening_shot, "last_light_used": last_light_used}

func restore(value: Dictionary) -> void:
	slow_left = clampf(value.get("slow_left", 0.0), 0, 2)
	opening_shot = value.get("opening_shot", false)
	last_light_used = value.get("last_light_used", false)

func phase_step(run: RefCounted) -> void:
	if run.mastery_level >= 10:
		slow_left = 0.0
	if run.mastery_level >= 15:
		opening_shot = true

func basic_damage(run: RefCounted, shot: Dictionary, amount: float) -> float:
	if run.class_id == "scavenger" and run.mastery_level >= 15 and opening_shot and shot.get("kind", "pistol") == "pistol":
		opening_shot = false
		return amount * 1.25
	return amount

func survive_lethal(run: RefCounted) -> bool:
	if run.class_id != "scavenger" or run.mastery_level < 20 or last_light_used or run.health > 0:
		return false
	last_light_used = true
	run.health = 1.0
	run.hurt_wait = 2.0
	run.ability_notice = "Last Light • survived at 1 HP"
	return true

func cache_positions(run: RefCounted) -> Array[Vector2]:
	var found: Array[Vector2] = []
	if run.class_id == "scavenger" and run.mastery_level >= 5:
		for site in run.field.sites:
			if site.kind == "cache" and not site.opened and run.player.distance_to(site.pos) <= 250:
				found.append(site.pos)
	return found
