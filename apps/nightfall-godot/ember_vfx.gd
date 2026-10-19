extends RefCounted
## Continuous mesh deformation and procedural material; no animation sheet.
const SHADER = preload("res://ember.gdshader")
const LIFT := Vector2(0,-34)
const IMPACT_SECONDS := 0.72
const SEGMENTS := 24
static var glow: GradientTexture2D
static var shader_material: ShaderMaterial
static var body_meshes: Dictionary = {}
static var ribbon_meshes: Dictionary = {}
static var spark_mesh: ArrayMesh

static func prepare(canvas: Node2D) -> void:
	if shader_material == null:
		shader_material = ShaderMaterial.new()
		shader_material.shader = SHADER
	if canvas.material != shader_material:
		canvas.material = shader_material

static func soft_light(canvas: Node2D, at: Vector2, size: Vector2, alpha: float) -> void:
	if glow == null:
		glow = GradientTexture2D.new()
		glow.width = 64
		glow.height = 64
		glow.fill = GradientTexture2D.FILL_RADIAL
		glow.fill_from = Vector2(0.5,0.5)
		glow.fill_to = Vector2(1,0.5)
		glow.gradient = Gradient.new()
		glow.gradient.colors = PackedColorArray([Color(1,0.69,0.24,0.64),Color(1,0.32,0.02,0)])
	canvas.draw_texture_rect(glow,Rect2(at-size*0.5,size),false,Color(1,1,1,alpha))

static func cast_pose(run: RefCounted) -> Dictionary:
	for event: Dictionary in run.vfx_events:
		if event.kind == "ember_cast" and event.life > 0:
			return {"age":event.duration-event.life,"direction":event.direction}
	if run.spells.has("ember"):
		var wait: float = run.spells.ember.get("wait",1.0)
		if wait > 0 and wait <= 0.18:
			var target: Dictionary = run.nearest_enemy(run.player,425)
			if not target.is_empty():
				return {"age":-wait,"direction":run.player.direction_to(target.pos)}
	return {}

static func body_points(at: Vector2, size: Vector2, angle: float, age: float, seed: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for n in SEGMENTS:
		var theta := float(n)*TAU/SEGMENTS
		var wave := 1.0+sin(theta*3+age*12+seed)*0.055+sin(theta*5-age*9)*0.025
		points.append(at+(Vector2.from_angle(theta)*size*wave).rotated(angle))
	return points

static func mesh_for(vertices: PackedVector2Array, uv: PackedVector2Array, indices: PackedInt32Array) -> ArrayMesh:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uv
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	return mesh

static func body_mesh(kind: int) -> ArrayMesh:
	if not body_meshes.has(kind):
		var vertices := PackedVector2Array([Vector2.ZERO])
		var uv := PackedVector2Array([Vector2(kind*64+0.5,64.5)])
		var indices := PackedInt32Array()
		for n in SEGMENTS:
			var radial := Vector2.from_angle(float(n)*TAU/SEGMENTS)
			vertices.append(radial)
			uv.append(radial*0.5+Vector2(kind*64+0.5,64.5))
			indices.append_array(PackedInt32Array([0,n+1,(n+1)%SEGMENTS+1]))
		body_meshes[kind] = mesh_for(vertices,uv,indices)
	return body_meshes[kind]

static func body(canvas: Node2D, at: Vector2, size: Vector2, angle: float, age: float, seed: float, alpha: float, kind: int = 1) -> void:
	if alpha <= 0 or size.x <= 0 or size.y <= 0:
		return
	prepare(canvas)
	var axis := Vector2.from_angle(angle)
	canvas.draw_mesh(body_mesh(kind),null,Transform2D(axis*size.x,Vector2(-axis.y,axis.x)*size.y,at),Color(age,seed,alpha,1))

static func ribbon_mesh(kind: int) -> ArrayMesh:
	if not ribbon_meshes.has(kind):
		var vertices := PackedVector2Array()
		var uv := PackedVector2Array()
		var indices := PackedInt32Array()
		for n in 13:
			var t := float(n)/12
			var half_width := 0.05+pow(t,0.7)*0.95
			vertices.append_array(PackedVector2Array([Vector2(t,half_width),Vector2(t,-half_width)]))
			uv.append_array(PackedVector2Array([Vector2(kind*64+t,128),Vector2(kind*64+t,129)]))
			if n < 12:
				var a := n*2
				indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
		ribbon_meshes[kind] = mesh_for(vertices,uv,indices)
	return ribbon_meshes[kind]

static func ribbon(canvas: Node2D, at: Vector2, direction: Vector2, length_value: float, width: float, age: float, seed: float, alpha: float, kind: int = 2) -> void:
	if alpha <= 0 or length_value <= 0 or width <= 0:
		return
	prepare(canvas)
	canvas.draw_mesh(ribbon_mesh(kind),null,Transform2D(direction*length_value,direction.orthogonal()*width,at-direction*length_value),Color(age,seed,alpha,1))

static func spark(canvas: Node2D, at: Vector2, size: Vector2, angle: float, age: float, alpha: float) -> void:
	if alpha <= 0:
		return
	prepare(canvas)
	if spark_mesh == null:
		spark_mesh = mesh_for(PackedVector2Array([Vector2(-0.5,-0.5),Vector2(0.5,-0.5),Vector2(0.5,0.5),Vector2(-0.5,0.5)]),PackedVector2Array([Vector2(256,0),Vector2(257,0),Vector2(257,1),Vector2(256,1)]),PackedInt32Array([0,1,2,0,2,3]))
	var axis := Vector2.from_angle(angle)
	canvas.draw_mesh(spark_mesh,null,Transform2D(axis*size.x,Vector2(-axis.y,axis.x)*size.y,at),Color(age,0,alpha,1))

static func draw_cast(canvas: Node2D, run: RefCounted, offset: Vector2, reduced: bool) -> void:
	var pose := cast_pose(run)
	if pose.is_empty() or pose.age > 0.13:
		return
	var age: float = pose.age+0.18
	var progress := clampf(age/0.18,0,1)
	var alpha := clampf((0.31-age)/0.13,0,1)
	var hand: Vector2 = run.player+offset+LIFT+pose.direction*27
	for n in (1 if reduced else 3):
		var theta := age*14+n*TAU/3
		var at := hand+Vector2.from_angle(theta)*(24-progress*12)
		ribbon(canvas,at,Vector2.from_angle(theta+PI/2),18,5,age,float(n),alpha*0.75)
	body(canvas,hand,Vector2.ONE*(5+progress*11),pose.direction.angle(),age,0,alpha)

static func draw_ground(canvas: Node2D, run: RefCounted, offset: Vector2, reduced: bool) -> void:
	var pose := cast_pose(run)
	if not pose.is_empty() and pose.age < 0.12:
		soft_light(canvas,run.player+offset+pose.direction*20,Vector2(115,63),0.25 if reduced else 0.65)
	for shot: Dictionary in run.shots:
		if shot.get("kind","") == "ember":
			soft_light(canvas,shot.pos+offset,Vector2(122,66),0.20 if reduced else 0.55)
	for event: Dictionary in run.vfx_events:
		if event.kind == "ember_hit":
			var progress := clampf((event.duration-event.life)/IMPACT_SECONDS,0,1)
			soft_light(canvas,event.pos+offset,Vector2(155,85),(1-progress)*(0.25 if reduced else 0.85))

static func draw_projectile(canvas: Node2D, shot: Dictionary, offset: Vector2, _time: float, reduced: bool) -> void:
	var direction: Vector2 = shot.velocity.normalized()
	var at: Vector2 = shot.pos+offset+LIFT
	var age := maxf(0,0.85-float(shot.life))
	var fade := minf(1,float(shot.life)*12)
	for n in (1 if reduced else 3):
		var side := float(n)-1
		ribbon(canvas,at-direction*8+direction.orthogonal()*side*7,direction,53+side*8,10-side*2,age,float(n),fade*(0.7 if reduced else 0.85))
	body(canvas,at,Vector2(20,17),direction.angle(),age,0,fade)
	if not reduced:
		for n in 5:
			var cycle := fposmod(age*2.5+n*0.2,1)
			var pos := at-direction*(22+cycle*48)+direction.orthogonal()*sin(cycle*5+n)*13
			spark(canvas,pos,Vector2(9,3)*(1-cycle),direction.angle(),age,(1-cycle)*fade)

static func draw_impact(canvas: Node2D, event: Dictionary, offset: Vector2, reduced: bool) -> void:
	var age: float = event.duration-event.life
	var progress := clampf(age/IMPACT_SECONDS,0,1)
	var at: Vector2 = event.pos+offset+LIFT
	var fire_alpha := (1-smoothstep(0.20,0.64,progress))*(0.65 if reduced else 0.94)
	var smoke_alpha := smoothstep(0.22,0.50,progress)*(1-smoothstep(0.65,1.0,progress))*(0.30 if reduced else 0.55)
	for n in (3 if reduced else 5):
		var theta := n*TAU/5+0.4
		var ray := Vector2.from_angle(theta)
		var center := at+ray*(8+progress*29)-Vector2(0,progress*progress*32)
		body(canvas,center,Vector2.ONE*(17+progress*20),0,age,float(n),smoke_alpha,3)
	for n in (3 if reduced else 6):
		var theta := n*TAU/6+progress*0.8
		var ray := Vector2.from_angle(theta)
		var center := at+ray*sin(minf(progress*2.2,1)*PI/2)*27
		body(canvas,center,Vector2.ONE*(8+sin(progress*PI)*14),theta,age,float(n),fire_alpha)
	body(canvas,at,Vector2.ONE*(14+progress*20),0,age,0,fire_alpha*(1-progress))
	if not reduced:
		for n in 10:
			var ray := Vector2.from_angle(n*TAU/10+0.27)
			var pos := at+ray*(8+progress*(47+n%3*9))+Vector2(0,progress*progress*30)
			spark(canvas,pos,Vector2(11,4)*(1-progress),ray.angle(),age,(1-progress)*0.9)
