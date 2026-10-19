extends RefCounted
## Combat-state-driven animation for hostile attacks, class powers and equipped weapons.
const Shapes = preload("res://draw_shapes.gd")
const Fx = preload("res://combat_effects.gd")
const Ember = preload("res://ember_vfx.gd")
const Enemies = preload("res://enemy_combat.gd")
const Motion = preload("res://enemy_motion.gd")
const LIFT := Vector2(0,-28)
const DANGER := Color("ff806c")

static func arc_points(center: Vector2, radius: float, direction: float, span: float, count: int = 20) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in count + 1:
		points.append(center + Vector2.from_angle(direction - span * 0.5 + span * index / count) * radius)
	return points

static func draw_telegraphs(canvas: Node2D, run: RefCounted, offset: Vector2, reduced: bool, outline_only: bool = false) -> void:
	for enemy: Dictionary in run.enemies:
		if enemy.hp <= 0 or enemy.tell <= 0 or (outline_only and not enemy.boss):
			continue
		var from: Vector2 = enemy.pos + offset
		var target: Vector2 = enemy.target + offset
		var direction: Vector2 = enemy.forward
		var progress := clampf(1.0 - enemy.tell / maxf(0.01, enemy.windup), 0, 1)
		var color := Color(DANGER, 0.65 + progress * 0.35)
		match enemy.attack:
			"slam", "summon":
				var radius := 80.0 if enemy.attack == "slam" else 110.0
				if not outline_only:
					Shapes.circle(canvas,target,radius,Color(DANGER,0.07+progress*0.08))
				Shapes.ring(canvas,target,radius,1.4,color)
				canvas.draw_arc(target, radius - 4, -PI * 0.5, -PI * 0.5 + TAU * progress, 36, Color("ffe4b9"), 2.1, true)
			"rush", "pounce":
				var reach := Enemies.rush_speed(run, enemy) * Enemies.rush_duration(enemy)
				var side := direction.orthogonal() * (30.0 if enemy.boss else 21.0)
				var end := from + direction * reach
				if not outline_only:
					canvas.draw_colored_polygon(PackedVector2Array([from-side, from+side, end+side, end+direction*15, end-side]), Color(DANGER, 0.08 + progress * 0.08))
				canvas.draw_polyline(PackedVector2Array([from-side,end-side,end+direction*15,end+side,from+side]), color, 1.3, true)
				var arrow := from + direction * reach * progress
				canvas.draw_polyline(PackedVector2Array([arrow-direction*7-side*0.28,arrow,arrow-direction*7+side*0.28]), Color("ffe4b9"), 2.0, true)
			"swipe", "cleave":
				canvas.draw_polyline(arc_points(from,80 if enemy.attack == "cleave" else 42,direction.angle(),2.8 if enemy.attack == "cleave" else 2.5), color, 1.8, true)
			"spit", "toss", "hex":
				for angle in ([-0.28,0.0,0.28] if enemy.attack == "hex" else ([-0.22,0.0,0.22] if enemy.attack == "toss" else [0.0])):
					var aim := from.direction_to(target).rotated(angle)
					var marks := PackedVector2Array()
					for n in 5:
						marks.append(from+aim*(30+n*25))
						marks.append(from+aim*(40+n*25))
					canvas.draw_multiline(marks,Color(DANGER,0.35+progress*0.45),1.2,true)
				if not outline_only:
					Ember.body(canvas,from+LIFT+direction*12,Vector2.ONE*(4+progress*6),0,run.elapsed,0,0.65,12)

static func slash(canvas: Node2D, origin: Vector2, direction: Vector2, radius: float, age: float, hostile: bool, reduced: bool) -> void:
	var progress := smoothstep(0.05,0.60,age)
	var fade := 1.0-smoothstep(0.55,1.0,age)
	var angle := direction.angle()-1.2+progress*2.4
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var color := Color(1,0.48,0.31,fade) if hostile else Color(0.88,0.91,1,fade)
	for index in 16:
		var a := angle - float(index)*0.065
		var b := a - 0.065
		var outer := radius*(1.0-float(index)*0.008)
		var inner := outer-(1.0-float(index)/16)*(9 if hostile else 13)
		var tint := Color(color,fade*(1.0-float(index)/16))
		Fx.triangle(vertices,colors,origin+Vector2.from_angle(a)*outer,origin+Vector2.from_angle(b)*outer,origin+Vector2.from_angle(a)*inner,tint)
		Fx.triangle(vertices,colors,origin+Vector2.from_angle(b)*outer,origin+Vector2.from_angle(b)*inner,origin+Vector2.from_angle(a)*inner,tint)
	Fx.draw_triangles(canvas,vertices,colors)
	if not hostile:
		Fx.blade(canvas,origin+Vector2.from_angle(angle)*radius*0.47,angle,age,true)

static func rock(canvas: Node2D, at: Vector2, angle: float, size: float, alpha: float) -> void:
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var center := at + Vector2(-size*0.13,-size*0.1).rotated(angle)
	var outline := PackedVector2Array()
	for n in 6:
		outline.append(at+Vector2.from_angle(angle+n*TAU/6)*size*(0.88+float(n%2)*0.15))
	for n in 6:
		var light := 0.62 if n in [3,4] else (0.42 if n in [2,5] else 0.25)
		Fx.triangle(vertices,colors,center,outline[n],outline[(n+1)%6],Color(light,light*0.82,light*0.88,alpha))
	Fx.draw_triangles(canvas,vertices,colors,11)

static func draw_hostile(canvas: Node2D, shot: Dictionary, offset: Vector2, clock: float, reduced: bool) -> void:
	var at: Vector2 = shot.pos + offset + LIFT
	var direction: Vector2 = shot.velocity.normalized()
	if shot.get("kind", "spit") == "hex":
		Ember.body(canvas,at,Vector2(12,10),direction.angle(),clock,0,0.85,8)
		Shapes.ring(canvas,at,10,1.5,Color("efbdff"))
		if not reduced: Ember.ribbon(canvas,at,direction,23,4,clock,0,0.7,6)
	elif shot.get("kind","spit") == "rubble":
		if not reduced:
			Ember.body(canvas,at-direction*10,Vector2(13,8),direction.angle(),clock,0,0.25,3)
		rock(canvas,at,clock*8+shot.pos.x*0.01,10,1)
		Shapes.ring(canvas,at,12,1.3,Color(1,0.53,0.35,0.55))
	else:
		Ember.body(canvas,at,Vector2(10,8),direction.angle(),clock,0,1,12)
		if not reduced:
			for n in 3:
				var tail := at-direction*(10+n*5)+direction.orthogonal()*sin(clock*13+n)*2
				Ember.body(canvas,tail,Vector2.ONE*(3.5-n*0.7),0,clock,n,0.55-n*0.14,12)

static func shield(canvas: Node2D, at: Vector2, clock: float, ratio: float, reduced: bool) -> void:
	Ember.body(canvas,at,Vector2(33,42),0,clock,0,0.26 if reduced else 0.45,13)
	canvas.draw_set_transform(at,0,Vector2(0.79,1))
	canvas.draw_arc(Vector2.ZERO,42,-PI*0.5,-PI*0.5+TAU*ratio,40,Color(0.66,0.88,1,0.70),1.7,true)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_effects(canvas: Node2D, run: RefCounted, offset: Vector2, clock: float, reduced: bool) -> void:
	for shot: Dictionary in run.hostile_shots:
		draw_hostile(canvas,shot,offset,clock,reduced)
	for effect: Dictionary in run.effects:
		var duration := maxf(0.001,float(effect.duration))
		var age := 1.0-clampf(float(effect.life)/duration,0,1)
		var fade := 1.0-smoothstep(0.35,1.0,age)
		var at: Vector2 = effect.from+offset
		match effect.kind:
			"slam", "trap":
				var trap: bool = effect.kind == "trap"
				var radius := 80.0
				# Full damage footprint appears on impact; subsequent debris carries no damage.
				Shapes.ring(canvas,at,radius,1.4,Color(1,0.52 if trap else 0.31,0.20,fade*0.55))
				canvas.draw_arc(at,radius*smoothstep(0,0.35,age),0,TAU,40,Color(1,0.75,0.51,fade*0.75),3.0,true)
				for n in (4 if reduced else 8):
					var ray := Vector2.from_angle(n*TAU/8+0.2)
					var point := at+ray*(10+age*56)-Vector2(0,sin(age*PI)*22)
					rock(canvas,point,age*4+n,5+n%3,fade)
				if trap:
					Ember.draw_impact(canvas,{"pos":effect.from,"direction":Vector2.UP,"life":effect.life,"duration":effect.duration},offset,reduced)
			"summon":
				Ember.body(canvas,at,Vector2.ONE*110,0,clock,0,fade*0.9,8)
				for n in (3 if reduced else 6):
					var ray := Vector2.from_angle(n*TAU/6+age)
					Ember.ribbon(canvas,at+ray*55,Vector2.DOWN,35+age*25,5,clock,n,fade*0.5,6)
			"turret":
				# Hitscan impact and recoil happen together; do not imply delayed bolt damage.
				var target: Vector2 = effect.to+offset+LIFT
				var direction := (target-at-LIFT).normalized()
				canvas.draw_line(at+LIFT,target,Color(1,0.82,0.52,fade*0.5),1.4,true)
				Ember.spark(canvas,target,Vector2(4,4),0,clock,fade)
	for event: Dictionary in run.vfx_events:
		var age := 1.0-clampf(float(event.life)/maxf(0.001,event.duration),0,1)
		var fade := 1.0-smoothstep(0.45,1,age)
		var at: Vector2 = event.pos+offset
		match event.kind:
			"enemy_swipe": slash(canvas,at+Vector2(0,-10),event.direction,42,age,true,reduced)
			"enemy_cleave": slash(canvas,at+Vector2(0,-10),event.direction,80,age,true,reduced)
			"enemy_death":
				var corpse: Dictionary = event.enemy.duplicate()
				corpse.pos = event.pos
				Motion.draw(canvas,corpse,run.mission,offset,clock,reduced,age)
			"hostile_hit":
				Ember.body(canvas,at+LIFT,Vector2.ONE*(8+age*13),0,clock,0,fade*0.7,12)
			"hero_hit":
				for n in (3 if reduced else 6):
					var ray := Vector2.from_angle(n*TAU/6+0.2)
					Ember.spark(canvas,at+LIFT+ray*(8+age*22),Vector2(2,5)*(1-age),ray.angle()+PI/2,clock,fade*0.8)
			"shield_hit":
				Ember.body(canvas,at+LIFT,Vector2(35,44)*(1+age*0.15),0,clock,0,fade*0.75,13)
			"structure_hit":
				for n in (3 if reduced else 5):
					var ray := Vector2.from_angle(n*TAU/5+0.4)
					rock(canvas,at+LIFT+ray*age*22-Vector2(0,sin(age*PI)*12),age*4+n,3,fade)
			"wand_hit", "blade_hit":
				Ember.body(canvas,at+LIFT,Vector2.ONE*(10+age*15),0,clock,0,fade*0.65,5)
			"spawn":
				Ember.body(canvas,at,Vector2(28,13),0,clock,0,fade*0.7,8)
			"rift_pulse":
				Ember.body(canvas,at,Vector2.ONE*145,0,age,0,fade*0.45,7)
				canvas.draw_arc(at,145*smoothstep(0,0.45,age),0,TAU,64,Color(0.74,0.58,1,fade*0.85),3,true)
				for n in (4 if reduced else 8):
					var ray := Vector2.from_angle(n*TAU/8)
					Ember.ribbon(canvas,at+ray*age*130,ray,20,5,clock,n,fade*0.7,6)
			"dodge":
				if not reduced:
					Ember.ribbon(canvas,at+LIFT,-event.direction,36,9,clock,0,fade*0.38,6)
	if run.shield > 0:
		shield(canvas,run.player+offset+Vector2(0,-29),clock,clampf(run.shield/(run.max_health()*0.20),0,1),reduced)
	for structure: Dictionary in run.defenses.structures:
		if structure.repair_left > 0:
			for n in (2 if reduced else 4):
				var center: Vector2 = structure.pos+offset+Vector2.from_angle(clock*2+n*PI/2)*23+Vector2(0,-18+sin(clock*3+n)*9)
				rock(canvas,center,clock*2+n,3.0,0.85)
				Ember.spark(canvas,center,Vector2(2.5,2.5),0,clock,0.65)
