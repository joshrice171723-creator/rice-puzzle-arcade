extends RefCounted
## One persistent textured mesh per character, weighted around feet, hips and arms.
## Animation changes vertices continuously rather than switching generated poses.
const SCAVENGER = preload("res://assets/hero-cast/scavenger-casting.png")
const ENGINEER = preload("res://assets/engineer.png")
const COLS := 12
const ROWS := 18

static func deform_point(uv: Vector2, size: Vector2, clock: float, stride: float, move_blend: float, cast_age: float, dodge: float) -> Vector2:
	var point := Vector2((uv.x-0.46)*size.x,(uv.y-0.99)*size.y)
	var leg := smoothstep(0.62,0.88,uv.y)
	var side := smoothstep(0.40,0.58,uv.x)*2-1
	var step := sin(stride+side*PI/2)
	point.x += step*4.5*leg*move_blend
	point.y -= maxf(0,step)*4.0*leg*move_blend
	var upper := 1-smoothstep(0.62,0.92,uv.y)
	point.x += sin(stride)*1.4*upper*move_blend
	point.y -= (sin(clock*2.8)*0.45+absf(cos(stride))*1.1*move_blend)*upper
	var sleeve := (1-smoothstep(0.25,0.39,uv.x)+smoothstep(0.67,0.84,uv.x))*smoothstep(0.24,0.36,uv.y)*(1-smoothstep(0.59,0.72,uv.y))
	point.x += sin(stride+PI)*sleeve*move_blend*2.0
	point.y += cos(stride)*sleeve*side*move_blend*1.6
	var cast := 0.0
	if cast_age >= -0.18 and cast_age < 0.30:
		cast = smoothstep(-0.18,0.0,cast_age)*(1-smoothstep(0.04,0.30,cast_age))
	var arm := smoothstep(0.59,0.83,uv.x)*smoothstep(0.23,0.38,uv.y)*(1-smoothstep(0.65,0.77,uv.y))
	var shoulder := Vector2(size.x*0.12,-size.y*0.62)
	point = point.lerp(shoulder+(point-shoulder).rotated(-0.48*cast),arm)
	point.x += upper*(cast*1.3+dodge*6)
	point.y += upper*dodge*3
	var cloth := (1-smoothstep(0.16,0.40,uv.x))*smoothstep(0.39,0.50,uv.y)*(1-smoothstep(0.64,0.76,uv.y))
	point.x += sin(clock*7.0+uv.y*6)*cloth*(0.5+move_blend*1.8)
	return point

static func draw_motion(canvas: Node2D, pos: Vector2, offset: Vector2, face: float, clock: float, stride: float, move_blend: float, cast_age: float, dodge: float, engineer: bool, reduced: bool) -> void:
	var texture: Texture2D = ENGINEER if engineer else SCAVENGER
	var source := Rect2(15,70,510,580) if engineer else Rect2(1640,110,403,562)
	var size := Vector2(source.size.x/source.size.y*80,80)
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	var texture_size := Vector2(texture.get_width(),texture.get_height())
	for row in ROWS+1:
		for col in COLS+1:
			var uv := Vector2(float(col)/COLS,float(row)/ROWS)
			var local := deform_point(uv,size,clock,stride,move_blend,cast_age,dodge)
			vertices.append(pos+offset+Vector2(local.x*face,local.y+5.6))
			uvs.append((source.position+uv*source.size)/texture_size)
	for row in ROWS:
		for col in COLS:
			var a := row*(COLS+1)+col
			indices.append_array(PackedInt32Array([a,a+1,a+COLS+1,a+1,a+COLS+2,a+COLS+1]))
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	canvas.set_meta("hero_mesh",mesh)
	if dodge > 0 and not reduced:
		canvas.draw_mesh(mesh,texture,Transform2D(0,Vector2(-face*14*dodge,0)),Color(0.62,0.77,1,dodge*0.18))
	canvas.draw_mesh(mesh,texture)
