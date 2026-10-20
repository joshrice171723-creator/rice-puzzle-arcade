extends SceneTree
const Dynamic = preload("res://dynamic_rig_mesh.gd")
var checks := 0
var failures := 0
class Probe extends Node2D:
	var shifted := false
	var uv_test := false
	var topology_test := false
	var alternate := false
	var mesh: ArrayMesh
	var texture: ImageTexture
	func _ready() -> void:
		var source := Image.create(2,1,false,Image.FORMAT_RGBA8)
		source.set_pixel(0,0,Color.RED)
		source.set_pixel(1,0,Color.BLUE)
		texture = ImageTexture.create_from_image(source)
	func _draw() -> void:
		draw_rect(Rect2(0,0,96,96),Color.BLACK)
		if topology_test:
			var points:=PackedVector2Array([Vector2(10,10),Vector2(35,10),Vector2(35,35),Vector2(10,35)])
			mesh=Dynamic.update(self,"test_pool",1,points,PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO]),PackedInt32Array([0,2,3] if alternate else [0,1,2]))
			draw_mesh(mesh,null)
			return
		var delta := Vector2(40,0) if shifted and not uv_test else Vector2.ZERO
		var vertices := PackedVector2Array([Vector2(10,10)+delta,Vector2(35,10)+delta,Vector2(10,35)+delta])
		var tint := Color.WHITE if uv_test else (Color.GREEN if shifted else Color.RED)
		var uv := Vector2(0.9 if shifted else 0.1,0.5)
		mesh = Dynamic.update(self,"test_pool",0,vertices,PackedVector2Array([uv,uv,uv]),PackedInt32Array([0,1,2]),PackedColorArray([tint,tint,tint]))
		draw_mesh(mesh,texture if uv_test else null)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	if DisplayServer.get_name()=="headless":
		print("Dynamic rig mesh: native renderer required for pixel/buffer verification")
		quit()
		return
	var viewport := SubViewport.new()
	viewport.size = Vector2i(96,96)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var probe := Probe.new()
	viewport.add_child(probe)
	for n in 3: await process_frame
	await RenderingServer.frame_post_draw
	var before := viewport.get_texture().get_image()
	var identity := probe.mesh.get_instance_id()
	check(before.get_pixel(15,15).r>0.9 and before.get_pixel(15,15).g<0.1,"Initial packed vertex color is red")
	check(RenderingServer.mesh_surface_get_format_vertex_stride(probe.mesh.surface_get_format(0),3)==8,"Dynamic surface uses documented eight-byte 2D vertices")
	probe.shifted = true
	probe.queue_redraw()
	for n in 3: await process_frame
	await RenderingServer.frame_post_draw
	var after := viewport.get_texture().get_image()
	check(probe.mesh.get_instance_id()==identity,"Changing pose reuses the surface resource")
	check(after.get_pixel(15,15).r<0.1 and after.get_pixel(55,15).g>0.9 and after.get_pixel(55,15).r<0.1,"Vertex and RGBA attribute updates move the triangle and preserve channel order")
	probe.uv_test = true
	probe.shifted = false
	probe.queue_redraw()
	for n in 3: await process_frame
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().get_pixel(15,15).r>0.9,"UV buffer selects the first authored atlas region")
	probe.shifted = true
	probe.queue_redraw()
	for n in 3: await process_frame
	await RenderingServer.frame_post_draw
	check(viewport.get_texture().get_image().get_pixel(15,15).b>0.9,"Changing UVs selects the next atlas region without a new mesh")
	probe.topology_test=true
	probe.queue_redraw()
	for n in 3: await process_frame
	await RenderingServer.frame_post_draw
	var first_topology:=probe.mesh.get_instance_id()
	check(viewport.get_texture().get_image().get_pixel(30,15).r>0.9,"First same-count topology draws upper-right triangle")
	probe.alternate=true
	probe.queue_redraw()
	for n in 3: await process_frame
	await RenderingServer.frame_post_draw
	var different:=viewport.get_texture().get_image()
	check(probe.mesh.get_instance_id()!=first_topology and different.get_pixel(30,15).r<0.1 and different.get_pixel(15,30).r>0.9,"Different triangle indices at equal vertex count select the correct cached surface")
	print("Dynamic rig mesh: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
