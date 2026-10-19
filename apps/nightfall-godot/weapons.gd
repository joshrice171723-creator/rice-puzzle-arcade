extends RefCounted
## Equal-budget weapon families; all attacks are automatic and use the equipped item.
const TYPES := {
	"pistol": {"name":"Service Pistol", "interval":0.60, "range":225.0, "speed":500.0, "count":1, "scale":1.0, "pierce":0, "elemental":false, "description":"Precise brass rounds. Reliable damage at medium range."},
	"scattergun": {"name":"Scrap Scattergun", "interval":1.0, "range":170.0, "speed":460.0, "count":3, "scale":0.5, "pierce":0, "elemental":false, "description":"Three pellets in a cone. Strong up close; loses reach."},
	"crossbow": {"name":"Salvager Crossbow", "interval":1.0, "range":290.0, "speed":580.0, "count":1, "scale":1.6, "pierce":1, "elemental":false, "description":"A heavy bolt pierces two foes. Slow, deliberate shots."},
	"wand": {"name":"Beacon Wand", "interval":0.65, "range":210.0, "speed":380.0, "count":1, "scale":0.95, "pierce":0, "elemental":true, "description":"Arcane motes deal elemental damage. Shorter reach than a pistol."},
	"sabre": {"name":"Outrider Sabre", "interval":0.85, "range":80.0, "speed":0.0, "count":1, "scale":1.25, "pierce":0, "elemental":false, "description":"Sweeps up to three foes in front of you. Requires close combat."}}

static func family(item: Dictionary) -> String:
	for id: String in TYPES:
		if item.get("name", "") == TYPES[id].name:
			return id
	return "pistol"

static func aim_direction(origin: Vector2, target: Dictionary, speed: float, lifetime: float) -> Vector2:
	var relative: Vector2 = target.pos-origin
	var velocity: Vector2 = target.get("velocity",Vector2.ZERO)
	if speed <= 0 or velocity.length_squared() < 0.001:
		return relative.normalized()
	var a := velocity.length_squared()-speed*speed
	var b := 2*relative.dot(velocity)
	var c := relative.length_squared()
	var intercept := INF
	if absf(a) < 0.001:
		if absf(b) > 0.001:
			var t := -c/b
			if t > 0: intercept = t
	else:
		var discriminant := b*b-4*a*c
		if discriminant >= 0:
			var root := sqrt(discriminant)
			for t in [(-b-root)/(2*a),(-b+root)/(2*a)]:
				if t > 0: intercept = minf(intercept,t)
	if intercept <= lifetime:
		return (relative+velocity*intercept).normalized()
	return relative.normalized()

static func fire(run: RefCounted, target: Dictionary) -> bool:
	var spec: Dictionary = TYPES[run.weapon_id]
	if run.shots.size() + int(spec.count) > run.MAX_SHOTS:
		return false
	var aim := aim_direction(run.player,target,spec.speed,float(spec.range)/maxf(1,spec.speed))
	if aim.length_squared() < 0.01:
		aim = run.facing
	run.add_vfx("weapon_cast", run.player, aim, 0.24)
	run.vfx_events.back().weapon = run.weapon_id
	for index in int(spec.count):
		var direction := aim.rotated((index - (int(spec.count) - 1) * 0.5) * 0.15)
		var shot := {"pos":run.player, "velocity":direction * float(spec.speed), "direction":direction,
			"life":float(spec.range) / maxf(1.0, spec.speed), "kind":run.weapon_id, "basic":true,
			"elemental":spec.elemental, "damage":run.damage * run.field.damage_multiplier() * float(spec.scale),
			"pierce":int(spec.pierce) + run.passive_rank("pierce"), "hits":[]}
		if run.weapon_id == "sabre":
			shot.life = 0.24
			shot.delay = 0.10
			shot.radius = spec.range
		run.shots.append(shot)
	if run.weapon_id in ["pistol", "scattergun", "crossbow"]:
		run.add_feedback("muzzle", run.player + aim * 20 - Vector2(0, 28), aim)
	return true
