extends RefCounted
## Stable surface resources; update only documented 2D vertex/attribute regions.
const MAX_VARIANTS := 4

static func update(canvas: Node2D, pool_key: String, slot: int, vertices: PackedVector2Array, uv: PackedVector2Array, indices: PackedInt32Array, colors: PackedColorArray = PackedColorArray()) -> ArrayMesh:
	var pool: Array = canvas.get_meta(pool_key,[])
	while pool.size() <= slot:
		pool.append({})
	var variants: Dictionary = pool[slot]
	var key := str(vertices.size())+":"+str(not colors.is_empty())+":"+str(hash(indices))
	var entry: Dictionary = variants.get(key,{})
	if entry.is_empty():
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_TEX_UV] = uv
		arrays[Mesh.ARRAY_INDEX] = indices
		if not colors.is_empty(): arrays[Mesh.ARRAY_COLOR] = colors
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays,[],{},Mesh.ARRAY_FLAG_USE_DYNAMIC_UPDATE)
		# Region updates do not rebuild bounds; camera-space batches may travel off their first frame.
		mesh.custom_aabb = AABB(Vector3(-4096,-4096,-1),Vector3(8192,8192,2))
		var format := mesh.surface_get_format(0)
		entry = {"mesh":mesh,"uv":uv,"colors":colors,"stride":RenderingServer.mesh_surface_get_format_attribute_stride(format,vertices.size()),"uv_offset":RenderingServer.mesh_surface_get_format_offset(format,vertices.size(),Mesh.ARRAY_TEX_UV),"color_offset":RenderingServer.mesh_surface_get_format_offset(format,vertices.size(),Mesh.ARRAY_COLOR)}
		if variants.size() >= MAX_VARIANTS: variants.erase(variants.keys()[0])
		variants[key] = entry
	else:
		var mesh: ArrayMesh = entry.mesh
		mesh.surface_update_vertex_region(0,0,vertices.to_byte_array())
		if entry.uv == uv and entry.colors == colors:
			canvas.set_meta(pool_key,pool)
			return mesh
		var attributes := PackedByteArray()
		attributes.resize(vertices.size()*int(entry.stride))
		for n in vertices.size():
			var base: int = n*entry.stride
			attributes.encode_float(base+entry.uv_offset,uv[n].x)
			attributes.encode_float(base+entry.uv_offset+4,uv[n].y)
			if not colors.is_empty():
				var at: int = base+entry.color_offset
				attributes[at] = clampi(roundi(colors[n].r*255),0,255)
				attributes[at+1] = clampi(roundi(colors[n].g*255),0,255)
				attributes[at+2] = clampi(roundi(colors[n].b*255),0,255)
				attributes[at+3] = clampi(roundi(colors[n].a*255),0,255)
		mesh.surface_update_attribute_region(0,0,attributes)
		entry.uv = uv
		entry.colors = colors
	pool[slot] = variants
	canvas.set_meta(pool_key,pool)
	return entry.mesh
