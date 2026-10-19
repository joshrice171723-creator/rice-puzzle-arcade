extends RefCounted
## Cached circular geometry avoids rebuilding antialiased line strips each frame.
static var rings: Dictionary = {}
static var disc: ArrayMesh
const SEGMENTS := 64

static func ring(canvas: Node2D, at: Vector2, radius: float, width: float, color: Color) -> void:
	if radius <= 0 or width <= 0 or color.a <= 0:
		return
	var key := Vector2(radius,width)
	if not rings.has(key):
		var vertices := PackedVector2Array()
		var colors := PackedColorArray()
		var indices := PackedInt32Array()
		for n in SEGMENTS+1:
			var radial := Vector2.from_angle(float(n)*TAU/SEGMENTS)
			for band in 4:
				var reach: float = radius + [-width*0.5-0.5,-width*0.5,width*0.5,width*0.5+0.5][band]
				vertices.append(radial*maxf(0,reach))
				colors.append(Color(1,1,1,0 if band in [0,3] else 1))
		for n in SEGMENTS:
			for band in 3:
				var a := n*4+band
				indices.append_array(PackedInt32Array([a,a+1,a+4,a+1,a+5,a+4]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_INDEX] = indices
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		# Callers use fixed authored radii. Bound the cache even if future content does not.
		if rings.size() >= 64:
			rings.erase(rings.keys()[0])
		rings[key] = mesh
	canvas.draw_mesh(rings[key],null,Transform2D(0,at),color)

static func circle(canvas: Node2D, at: Vector2, radius: float, color: Color) -> void:
	if radius <= 0 or color.a <= 0:
		return
	if disc == null:
		var vertices := PackedVector2Array([Vector2.ZERO])
		var indices := PackedInt32Array()
		for n in SEGMENTS:
			vertices.append(Vector2.from_angle(float(n)*TAU/SEGMENTS))
			indices.append_array(PackedInt32Array([0,n+1,(n+1)%SEGMENTS+1]))
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_INDEX] = indices
		disc = ArrayMesh.new()
		disc.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	canvas.draw_mesh(disc,null,Transform2D(Vector2(radius,0),Vector2(0,radius),at),color)
