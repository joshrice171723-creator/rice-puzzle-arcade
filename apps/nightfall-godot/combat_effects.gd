extends RefCounted
## Authored world-space spell sprites. Positions, radii and lifetime come from Run.
const Magic = preload("res://magic.gd")
const ATLAS = preload("res://assets/combat-vfx/arcane-effects-atlas.png")
const SPELL_EFFECTS := ["chain", "frost", "ember", "lance", "gravity"]
const LIFT := Vector2(0,-18)
const MAX_PROJECTILES := 64
const MAX_EFFECTS := 64
# Explicit occupied regions exclude neighboring glow and keep the two poses aligned.
const FRAMES := [
	Rect2(1,80,311,225), Rect2(320,12,307,320), Rect2(629,18,309,321), Rect2(944,98,309,210),
	Rect2(3,420,309,177), Rect2(315,407,312,195), Rect2(629,421,310,175), Rect2(945,385,307,230),
	Rect2(1,660,311,245), Rect2(320,620,307,323), Rect2(629,635,309,305), Rect2(944,685,309,230),
	Rect2(3,1005,309,210), Rect2(315,1010,312,190), Rect2(629,1015,310,180), Rect2(948,938,304,304)]

static func handles_effect(kind: String) -> bool:
	return kind in SPELL_EFFECTS

static func draw_ground(canvas: Node2D, run: RefCounted, offset: Vector2, time: float, reduced: bool) -> void:
	for index in mini(run.zones.size(),3):
		var zone: Dictionary = run.zones[index]
		var radius: float = zone.get("radius",0.0)
		var life: float = zone.get("life",0.0)
		if radius <= 0.0 or life <= 0.0:
			continue
		var at: Vector2 = zone.pos + offset
		if zone.get("kind","ground") == "collapse":
			var charge := 1.0 - clampf(life / 0.6,0.0,1.0)
			var extent := radius * 2.0 * (0.58 + charge * 0.32)
			quad(canvas,15,at,Vector2(extent,extent),0.0 if reduced else time * -1.3,Color(1,1,1,0.32 if reduced else 0.60))
		else:
			var fade := minf(1.0,life * 2.5)
			var pulse := 0.64 if reduced else 0.68 + sin(time * 2.4) * 0.08
			quad(canvas,7,at,Vector2.ONE * radius * 2.0,0,Color(1,1,1,fade * pulse))
			# The friendly zone boundary stays tied to the actual circular radius.
			canvas.draw_arc(at,radius,0,TAU,40,Color(0.57,0.80,1.0,fade * 0.17),1.0,true)

static func draw_projectiles(canvas: Node2D, run: RefCounted, offset: Vector2, time: float, reduced: bool) -> void:
	var pose := 0 if reduced else int(time * 10.0) % 2
	for index in mini(run.shots.size(),MAX_PROJECTILES):
		var shot: Dictionary = run.shots[index]
		var at: Vector2 = shot.pos + offset + LIFT
		var velocity: Vector2 = shot.get("velocity",Vector2.RIGHT)
		var direction := velocity.normalized() if velocity.length_squared() > 0.001 else Vector2.RIGHT
		match shot.get("kind","pistol"):
			"ember":
				quad(canvas,pose * 8,at - direction * 12.0,Vector2(47,40),direction.angle(),Color(1,1,1,0.85 if reduced else 1.0))
			"blade":
				quad(canvas,6 + pose * 8,at - direction * 5.0,Vector2(47,34),direction.angle(),Color.WHITE)
			_:
				# A compact painted gold-white tracer; it remains a physical pistol shot.
				quad(canvas,5,at - direction * 3.0,Vector2(21,12),direction.angle(),Color(1.0,0.94,0.78,0.92))
	if run.spells.has("wisp"):
		var count := clampi(int(run.spell_mod("wisp","count",1)),1,4)
		for index in count:
			var world: Vector2 = Magic.wisp_position(run,index)
			var tangent: Vector2 = (world - run.player).orthogonal().normalized()
			var at: Vector2 = world + offset + LIFT - tangent * 8.0
			quad(canvas,3 + pose * 8,at,Vector2(38,38),tangent.angle(),Color(1,1,1,0.78 if reduced else 1.0))

static func draw_effects(canvas: Node2D, run: RefCounted, offset: Vector2, time: float, reduced: bool) -> void:
	for index in mini(run.effects.size(),MAX_EFFECTS):
		var effect: Dictionary = run.effects[index]
		if not handles_effect(effect.kind) or effect.get("duration",0.0) <= 0 or effect.life <= 0:
			continue
		var remaining := clampf(float(effect.life) / float(effect.duration),0.0,1.0)
		var age := 1.0 - remaining
		var fade := minf(1.0,remaining * 2.0)
		var from: Vector2 = effect.from + offset
		var to: Vector2 = effect.to + offset
		var pose := 0 if reduced else int((time + age * 0.25) * 12.0) % 2
		var strength := 0.40 if reduced else 0.92
		match effect.kind:
			"chain":
				beam(canvas,4 + pose * 8,from + LIFT,to + LIFT,38 if reduced else 52,fade * strength)
			"frost":
				var radius: float = maxf(1.0,effect.from.distance_to(effect.to))
				var extent := radius * 2.0 * (0.88 + age * 0.12)
				quad(canvas,2 + pose * 8,from,Vector2.ONE * extent,0.0 if reduced else age * 0.16,Color(1,1,1,fade * (0.35 if reduced else 0.72)))
			"ember":
				var extent := 46.0 + age * 22.0
				quad(canvas,1 + pose * 8,from + LIFT,Vector2.ONE * extent,0,Color(1,1,1,fade * strength))
			"lance":
				var width := clampf(float(run.spell_mod("lance","width",20)) * 1.8,25.0,72.0)
				beam(canvas,5 + pose * 8,from + LIFT,to + LIFT,width,fade * strength)
			"gravity":
				var radius: float = maxf(1.0,effect.from.distance_to(effect.to))
				var extent := radius * 2.0 * (0.94 - age * 0.30)
				quad(canvas,15,from + LIFT,Vector2.ONE * extent,0.0 if reduced else -time * 2.0,Color(1,1,1,fade * (0.30 if reduced else 0.62)))

static func beam(canvas: Node2D, frame: int, from: Vector2, to: Vector2, width: float, alpha: float) -> void:
	var distance := from.distance_to(to)
	if distance < 1.0:
		return
	quad(canvas,frame,(from + to) * 0.5,Vector2(distance,width),(to - from).angle(),Color(1,1,1,alpha))

static func quad(canvas: Node2D, frame: int, center: Vector2, size: Vector2, rotation: float, tint: Color) -> void:
	if not center.is_finite() or not size.is_finite() or size.x <= 0 or size.y <= 0 or tint.a <= 0:
		return
	var source: Rect2 = FRAMES[clampi(frame,0,FRAMES.size()-1)].grow(-1.0)
	var atlas_size := Vector2(ATLAS.get_width(),ATLAS.get_height())
	var uv := PackedVector2Array([source.position / atlas_size,(source.position + Vector2(source.size.x,0)) / atlas_size,source.end / atlas_size,(source.position + Vector2(0,source.size.y)) / atlas_size])
	var half := size * 0.5
	var vertices := PackedVector2Array()
	for local: Vector2 in [Vector2(-half.x,-half.y),Vector2(half.x,-half.y),Vector2(half.x,half.y),Vector2(-half.x,half.y)]:
		vertices.append(center + local.rotated(rotation))
	# One atlas and no per-sprite transform/material changes allow normal 2D batching.
	canvas.draw_primitive(vertices,PackedColorArray([tint]),uv,ATLAS)
