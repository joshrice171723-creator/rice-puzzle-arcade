extends RefCounted
## Continuous world-space spell geometry. Positions, radii and lifetime come from Run.
const Shapes = preload("res://draw_shapes.gd")
const Magic = preload("res://magic.gd")
const HeroMotion = preload("res://hero_cast.gd")
const Ember = preload("res://ember_vfx.gd")
const ATLAS = preload("res://assets/combat-vfx/arcane-effects-atlas.png")
const SPELL_EFFECTS := ["chain", "frost", "ember", "lance", "gravity"]
const LIFT := Vector2(0,-28)
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
	# Draw commands consume mesh resources after _draw returns. Hold until next frame.
	canvas.set_meta("vfx_meshes",[])
	for index in mini(run.zones.size(),3):
		var zone: Dictionary = run.zones[index]
		var radius: float = zone.get("radius",0.0)
		var life: float = zone.get("life",0.0)
		if radius <= 0.0 or life <= 0.0:
			continue
		var at: Vector2 = zone.pos + offset
		if zone.get("kind", "ground") in ["collapse", "gravity_pull"]:
			gravity(canvas, at, radius, 1.0 - clampf(life / 0.6, 0.0, 1.0), time, reduced, 0.55)
		else:
			var fade := minf(1.0, life * 2.5)
			Ember.body(canvas,at,Vector2.ONE*radius,0,time*0.2,0,fade*(0.45 if reduced else 0.8),9)
			Shapes.ring(canvas,at,radius,1.3,Color(0.57,0.80,1.0,fade*0.35))
			canvas.draw_arc(at, radius * 0.80, 0.0 if reduced else time * 0.25, (0.0 if reduced else time * 0.25) + PI * 1.55, 32, Color(1.0, 0.82, 0.45, fade * 0.38), 1.3, true)
			var marks := PackedVector2Array()
			for rune in (6 if reduced else 10):
				var angle := TAU * rune / (6.0 if reduced else 10.0) + (0.0 if reduced else time * 0.16)
				var radial := Vector2.from_angle(angle)
				var center := at + radial * radius * 0.88
				marks.append(center - radial * 3.0)
				marks.append(center + radial * 3.0)
				marks.append(center - radial.orthogonal() * 2.0)
				marks.append(center + radial.orthogonal() * 2.0)
			canvas.draw_multiline(marks, Color(0.72, 0.86, 1.0, fade * 0.70), 1.3, true)

static func draw_projectiles(canvas: Node2D, run: RefCounted, offset: Vector2, time: float, reduced: bool) -> void:
	for index in mini(run.shots.size(), MAX_PROJECTILES):
		draw_shot(canvas, run.shots[index], offset, time, reduced)
	draw_wisps(canvas, run, offset, time, reduced, false)
	draw_wisps(canvas, run, offset, time, reduced, true)


static func draw_shot(canvas: Node2D, shot: Dictionary, offset: Vector2, time: float, reduced: bool) -> void:
	var at: Vector2 = shot_visual_position(shot) + offset
	var velocity: Vector2 = shot.get("velocity",Vector2.RIGHT)
	var direction := velocity.normalized() if velocity.length_squared() > 0.001 else Vector2.RIGHT
	match shot.get("kind","pistol"):
		"ember":
			Ember.draw_projectile(canvas,shot,offset,time,reduced)
		"wand":
			Ember.ribbon(canvas,at,direction,24,5,time,0,0.65,6)
			Ember.body(canvas,at,Vector2(9,7),direction.angle(),time,0,1,5)
			var rays := PackedVector2Array()
			for n in 3:
				var ray := Vector2.from_angle(time*4+n*PI/3)*8
				rays.append(at-ray)
				rays.append(at+ray)
			canvas.draw_multiline(rays,Color(0.90,0.93,1,0.75),1.1,true)
		"crossbow":
			var side := direction.orthogonal()
			canvas.draw_line(at-direction*15,at+direction*9,Color("b27a48"),3,true)
			canvas.draw_line(at-direction*14-side,at+direction*8-side,Color("f5d095"),1,true)
			canvas.draw_colored_polygon(PackedVector2Array([at+direction*16,at+direction*6+side*4,at+direction*8,at+direction*6-side*4]),Color("e3e7ed"))
			for sign_value in [-1,1]:
				canvas.draw_colored_polygon(PackedVector2Array([at-direction*7,at-direction*14+side*5*sign_value,at-direction*18+side*5*sign_value,at-direction*14]),Color("6086ba"))
		"sabre":
			var age := 1.0-clampf(float(shot.life)/0.24,0,1)
			var sweep := smoothstep(0.05,0.65,age)
			var aim: Vector2 = shot.get("direction",Vector2.RIGHT)
			var angle := aim.angle()-1.1+sweep*2.2
			var radius: float = shot.get("radius",80.0)
			var fade := 1.0-smoothstep(0.55,1,age)
			var points := PackedVector2Array()
			for n in 16:
				points.append(shot.pos+offset+Vector2(0,-10)+Vector2.from_angle(angle-n*0.065)*radius)
			canvas.draw_polyline(points,Color(0.66,0.78,1,fade*0.25),9,true)
			canvas.draw_polyline(points,Color(0.89,0.95,1,fade*0.85),2.5,true)
			blade(canvas,at+Vector2.from_angle(angle)*radius*0.42,angle,time,true)
		"blade":
			var spin: float = direction.angle()+time*13.0
			blade(canvas,at,spin,time,reduced)
		_:
			# Pointed physical brass round: no spear texture or stretched laser beam.
			var side := direction.orthogonal()
			canvas.draw_colored_polygon(PackedVector2Array([at + direction * 6.0, at + direction * 2.0 + side * 2.6, at - direction * 5.0 + side * 2.6, at - direction * 5.0 - side * 2.6, at + direction * 2.0 - side * 2.6]), Color("e6a447"))
			canvas.draw_line(at - direction * 3.0 - side, at + direction * 3.0 - side, Color("fff0b7"), 1.7, true)
			if not reduced:
				canvas.draw_line(at - direction * 6.0, at - direction * 12.0, Color(1.0, 0.72, 0.35, 0.36), 1.6, true)

static func shot_visual_position(shot: Dictionary) -> Vector2:
	var grounded: Vector2 = shot.pos+LIFT
	var kind: String = shot.get("kind","pistol")
	if kind not in ["pistol","scattergun","crossbow","wand"] or not shot.has("visual_launch"):
		return grounded
	var launch: Dictionary = shot.visual_launch
	var origin: Vector2 = launch.origin
	var aim: Vector2 = launch.aim
	var muzzle := HeroMotion.muzzle_offset(launch.class_id,kind,launch.face,aim,launch.clock,0,0,0,0,kind,0,Vector2.RIGHT,launch.get("appearance",{}))
	var distance := origin.distance_to(shot.pos)
	# Blend the short launch height correction into the unchanged torso-height path.
	# Close targets converge before their existing collision boundary, not after it.
	var converge := minf(80.0,maxf(0.01,float(launch.contact_distance)))
	var weight := 1.0-smoothstep(0.0,converge,distance)
	return grounded+(muzzle-LIFT)*weight


static func draw_wisps(canvas: Node2D, run: RefCounted, offset: Vector2, time: float, reduced: bool, front: bool = true) -> void:
	if run.spells.has("wisp"):
		var count := clampi(int(run.spell_mod("wisp","count",1)),1,4)
		for index in count:
			var world: Vector2 = Magic.wisp_position(run,index)
			if (world.y >= run.player.y) != front:
				continue
			var tangent: Vector2 = (world - run.player).orthogonal().normalized()
			var at: Vector2 = world + offset + LIFT
			var pulse := 1.0+sin(time*7+index)*0.06
			Ember.ribbon(canvas,at-tangent*5,tangent,35,9,time,float(index),0.45 if reduced else 0.8,6)
			Ember.body(canvas,at,Vector2(13,11)*pulse,tangent.angle(),time,float(index),0.9,5)
			for enemy: Dictionary in run.enemies:
				var hit_left: float = run.wisp_hits.get(enemy.id,0.0)-run.elapsed
				if hit_left > 0.94 and enemy.pos.distance_to(world) < 45:
					Ember.body(canvas,at,Vector2.ONE*(12+(1.1-hit_left)*50),0,time,0,(hit_left-0.94)*3,5)


static func draw_effects(canvas: Node2D, run: RefCounted, offset: Vector2, time: float, reduced: bool) -> void:
	Ember.draw_cast(canvas,run,offset,reduced)
	draw_spell_gesture(canvas,run,offset,time,reduced)
	for event: Dictionary in run.vfx_events:
		if event.kind == "ember_hit":
			Ember.draw_impact(canvas,event,offset,reduced)
		elif event.kind == "bullet_hit":
			var duration := maxf(0.01, float(event.get("duration", 0.12)))
			var fade := clampf(float(event.get("life", 0.0)) / duration, 0.0, 1.0)
			var at: Vector2 = event.pos + offset + LIFT
			var direction: Vector2 = event.get("direction", Vector2.RIGHT)
			var chips := PackedVector2Array()
			for chip in (2 if reduced else 4):
				var ray := direction.rotated(-1.0 + chip * 0.66) * (5.0 + (1.0 - fade) * 7.0)
				chips.append(at + ray * 0.4)
				chips.append(at + ray)
			canvas.draw_multiline(chips, Color(1.0, 0.85, 0.55, fade), 1.7, true)
	for index in mini(run.effects.size(),MAX_EFFECTS):
		var effect: Dictionary = run.effects[index]
		if not handles_effect(effect.kind) or effect.get("duration",0.0) <= 0 or effect.life <= 0:
			continue
		var remaining := clampf(float(effect.life) / float(effect.duration),0.0,1.0)
		var age := 1.0 - remaining
		var fade := minf(1.0,remaining * 2.0)
		var from: Vector2 = effect.from + offset
		var to: Vector2 = effect.to + offset
		var strength := 0.40 if reduced else 0.92
		match effect.kind:
			"chain":
				lightning(canvas, from + LIFT, to + LIFT, age, fade * strength, reduced)
			"frost":
				frost(canvas, from, maxf(1.0, effect.from.distance_to(effect.to)), age, fade, reduced)

			"ember":
				# New hits own a longer transient sequence; old saved hits still render.
				if not run.vfx_events.any(func(event: Dictionary): return event.kind == "ember_hit" and event.pos.distance_to(effect.from) < 1):
					Ember.draw_impact(canvas,{"pos":effect.from,"direction":Vector2.UP,"life":effect.life,"duration":effect.duration},offset,reduced)
			"lance":
				stone_line(canvas, from + LIFT, to + LIFT, clampf(float(run.spell_mod("lance", "width", 20)), 12.0, 40.0), age, fade, reduced)
			"gravity":
				gravity(canvas, from, maxf(1.0, effect.from.distance_to(effect.to)), age, time, reduced, fade * strength)


static func draw_spell_gesture(canvas: Node2D, run: RefCounted, offset: Vector2, time: float, reduced: bool) -> void:
	var pose := HeroMotion.pose(run)
	if pose.is_empty() or pose.get("spell", "") in ["", "ember", "wisp"]:
		return
	var age: float = pose.age
	var fade := (1.0-clampf(age/0.30,0,1)) if age >= 0 else smoothstep(-0.18,0,age)
	if fade <= 0:
		return
	var direction: Vector2 = pose.direction
	var at: Vector2 = run.player+offset+LIFT+direction*24
	var radius := 9.0+fade*5.0
	match pose.spell:
		"frost", "lance":
			var vertices := PackedVector2Array()
			var colors := PackedColorArray()
			for n in (2 if reduced else 3):
				var ray := Vector2.from_angle(time*3+n*TAU/3)
				crystal_faces(vertices,colors,at+ray*radius,ray,8*fade+4,3,fade,pose.spell=="frost")
			draw_triangles(canvas,vertices,colors,10 if pose.spell=="frost" else 11)
		"chain":
			for n in (1 if reduced else 2):
				var tip := at+Vector2.from_angle(time*5+n*PI)*(radius+5)
				lightning(canvas,at,tip,clampf(age+0.18,0,1),fade*0.7,true)
		"ground":
			canvas.draw_arc(at,radius,0,TAU,20,Color(0.76,0.84,1,fade*0.8),1.3,true)
			canvas.draw_arc(at,radius*0.65,time*2,time*2+PI*1.5,16,Color(1,0.82,0.48,fade*0.8),1.2,true)
		"gravity":
			Ember.body(canvas,at,Vector2.ONE*radius,0,time,0,fade*0.75,8)
			for n in (2 if reduced else 4):
				var angle := time*5+n*TAU/4
				Ember.ribbon(canvas,at+Vector2.from_angle(angle)*radius,Vector2.from_angle(angle+PI/2),10,2,time,n,fade*0.6,6)
		"blades":
			for n in 2:
				var side := direction.orthogonal()*(9+n*5)*(1 if n==0 else -1)
				var vertices := PackedVector2Array()
				var colors := PackedColorArray()
				crystal_faces(vertices,colors,at+side-direction*6,direction,20*fade,3,fade,true)
				draw_triangles(canvas,vertices,colors,10)


static func lightning(canvas: Node2D, from: Vector2, to: Vector2, age: float, alpha: float, reduced: bool) -> void:
	var delta := to - from
	var side := delta.normalized().orthogonal()
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var previous := from
	var segments := 5 if reduced else 8
	for index in segments:
		var t := float(index + 1) / segments
		var jitter := (sin(index*3.7+age*38.0)+sin(index*7.1-age*23.0)*0.4)*minf(12.0,delta.length()*0.08)
		var next := to if index == segments - 1 else from + delta * t + side * jitter
		points.append(previous)
		points.append(next)
		colors.append(Color(0.70, 0.72, 1.0, alpha))
		if not reduced and index % 3 == 1:
			points.append(next)
			points.append(next - delta.normalized() * 11.0 + side * (15.0 if index % 2 else -15.0))
			colors.append(Color(0.55, 0.62, 1.0, alpha * 0.5))
		previous = next
	if not reduced:
		canvas.draw_multiline(points,Color(0.42,0.28,1,alpha*0.17),10,true)
	canvas.draw_multiline_colors(points, colors, 2.2 if reduced else 3.1, true)
	canvas.draw_multiline(points,Color(0.91,0.95,1,alpha),1.0,true)
	var flash := PackedVector2Array()
	for index in 4:
		var ray := Vector2.from_angle(index * PI / 4.0 + age * 2.0) * (9.0 - age * 4.0)
		flash.append(to - ray)
		flash.append(to + ray)
	canvas.draw_multiline(flash, Color(0.92, 0.94, 1.0, alpha), 1.8, true)


static func frost(canvas: Node2D, at: Vector2, radius: float, age: float, fade: float, reduced: bool) -> void:
	# Contact illuminates the full actual area immediately; growth is visual only.
	Ember.body(canvas,at,Vector2.ONE*radius,0,age,0,fade*(0.35 if reduced else 0.75),7)
	var count := 6 if reduced else 14
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	for index in count:
		var angle := TAU * index / float(count) + 0.2
		var radial := Vector2.from_angle(angle)
		var growth := smoothstep(0.0,0.32,age+0.06-float(index%3)*0.035)
		var fracture := smoothstep(0.42,0.95,age)
		var base := at+radial*radius*(0.40+float(index%3)*0.18)+radial*fracture*12
		var length_value := radius*(0.30+float(index%3)*0.06)*growth*(1-fracture*0.50)
		var direction := (radial*0.5+Vector2(0,-0.8)).normalized().rotated(fracture*sin(index)*0.8)
		crystal_faces(vertices,colors,base,direction,length_value,8+index%3*2,fade,true)
		if not reduced and fracture > 0:
			crystal_faces(vertices,colors,base+radial*fracture*20-Vector2(0,sin(fracture*PI)*20),direction.rotated(fracture*4),length_value*0.32,3,fade*fracture,true)
	draw_triangles(canvas,vertices,colors,10)


static func stone_line(canvas: Node2D, from: Vector2, to: Vector2, width: float, age: float, fade: float, reduced: bool) -> void:
	# Damage is instantaneous: the complete line erupts on the first frame.
	var delta := to - from
	var direction := delta.normalized()
	var side := direction.orthogonal()
	var count := clampi(int(delta.length() / 44.0), 2, 10)
	if reduced:
		count = mini(count, 5)
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	for index in count:
		var t := (float(index) + 0.5) / count
		var scatter := sin(index * 5.1) * age * width * 0.4
		var at := from + delta * t + side * scatter
		var lift := sin(age * PI) * (5.0 + index % 3 * 2.0)
		crystal_faces(vertices,colors,at-Vector2(0,lift),direction.rotated(sin(index*2.3)*age*0.35),39-age*12,width*0.42,fade,false)
		if not reduced:
			crystal_faces(vertices,colors,at+side*(age*18)-Vector2(0,lift*2),direction.rotated(age*5+index),10,4,fade,false)
	draw_triangles(canvas,vertices,colors,11)


static func gravity(canvas: Node2D, at: Vector2, radius: float, age: float, time: float, reduced: bool, alpha: float) -> void:
	Ember.body(canvas,at,Vector2.ONE*radius,0,time,0,alpha*(0.6 if reduced else 0.9),8)
	Shapes.ring(canvas,at,radius,1.2,Color(0.62,0.56,1.0,alpha*0.30))
	if reduced:
		return
	for index in 8:
		var phase := fposmod(time * 0.85 + float(index) * 0.173, 1.0)
		var reach := radius * (1.0 - phase) * 0.92
		var angle := index * 2.4 + time * 0.9 + phase * 1.2
		var center := at + Vector2.from_angle(angle) * reach
		var direction := (at-center).normalized().rotated(-0.35)
		Ember.ribbon(canvas,center,direction,14,3,time,float(index),sin(phase*PI)*alpha*0.8,6)

static func triangle(vertices: PackedVector2Array, colors: PackedColorArray, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	vertices.append_array(PackedVector2Array([a,b,c]))
	colors.append_array(PackedColorArray([color,color,color]))

static func crystal_faces(vertices: PackedVector2Array, colors: PackedColorArray, base: Vector2, direction: Vector2, length_value: float, width: float, alpha: float, ice: bool) -> void:
	var tip := base+direction*length_value
	var side := direction.orthogonal()*width
	var shoulder := base+direction*length_value*0.22
	var ridge := base+direction*length_value*0.30-side*0.18
	var light := Color(0.76,0.96,1,alpha) if ice else Color(0.65,0.63,0.72,alpha)
	var dark := Color(0.12,0.40,0.80,alpha*0.85) if ice else Color(0.23,0.20,0.31,alpha)
	var middle := Color(0.35,0.74,0.97,alpha*0.95) if ice else Color(0.42,0.38,0.49,alpha)
	triangle(vertices,colors,tip,shoulder-side,ridge,light)
	triangle(vertices,colors,tip,ridge,shoulder+side,middle)
	triangle(vertices,colors,shoulder-side,base-direction*4,ridge,middle)
	triangle(vertices,colors,shoulder+side,ridge,base-direction*4,dark)

static func draw_triangles(canvas: Node2D, vertices: PackedVector2Array, colors: PackedColorArray, material_kind: int = 0) -> void:
	if vertices.is_empty():
		return
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	if material_kind > 0:
		Ember.prepare(canvas)
		var uv := PackedVector2Array()
		var corners := [Vector2(0.5,0),Vector2(0,0.75),Vector2(0.48,0.7),Vector2(0.5,0),Vector2(0.48,0.7),Vector2(1,0.75),Vector2(0,0.75),Vector2(0.5,1),Vector2(0.48,0.7),Vector2(1,0.75),Vector2(0.48,0.7),Vector2(0.5,1)]
		for n in vertices.size():
			uv.append(corners[n%12]+Vector2(material_kind*64,0))
		arrays[Mesh.ARRAY_TEX_UV] = uv
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var retained: Array = canvas.get_meta("vfx_meshes",[])
	retained.append(mesh)
	canvas.set_meta("vfx_meshes",retained)
	canvas.draw_mesh(mesh,null)

static func blade(canvas: Node2D, at: Vector2, angle: float, time: float, reduced: bool) -> void:
	var vertices := PackedVector2Array()
	var colors := PackedColorArray()
	var axis := Vector2.from_angle(angle)
	var side := axis.orthogonal()
	if not reduced:
		for n in 2:
			var behind := Vector2.from_angle(angle-0.3-n*0.25)
			Ember.ribbon(canvas,at+behind*22,behind.orthogonal(),21,4,time,float(n),0.42-n*0.13,6)
	crystal_faces(vertices,colors,at-axis*9,axis,36,7,1,true)
	triangle(vertices,colors,at-axis*10-side*12,at-axis*6+side*12,at-axis*14,Color("c8ae73"))
	triangle(vertices,colors,at-axis*10-side*3,at-axis*23-side*3,at-axis*10+side*3,Color("554575"))
	triangle(vertices,colors,at-axis*23-side*3,at-axis*23+side*3,at-axis*10+side*3,Color("8977aa"))
	triangle(vertices,colors,at-axis*23-side*4,at-axis*27,at-axis*23+side*4,Color("d9c0ff"))
	draw_triangles(canvas,vertices,colors)

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
