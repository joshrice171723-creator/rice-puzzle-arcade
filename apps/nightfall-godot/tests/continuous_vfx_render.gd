extends SceneTree
const Ember = preload("res://ember_vfx.gd")
const FLOOR = preload("res://assets/world/flagstones.png")
var failures := 0
var checks := 0
class Probe extends Node2D:
	var age := 0.20
	var effects := false
	var material_only := false
	var material_kind := 5
	var cached := false
	var ribbon := false
	func _draw() -> void:
		draw_texture_rect(FLOOR,Rect2(0,0,300,200),false,Color(0.8,0.9,1,1))
		draw_rect(Rect2(4,4,20,20),Color(0.3,0.6,0.9,0.5))
		if effects:
			if cached:
				if ribbon:
					Ember.ribbon(self,Vector2(200,100),Vector2.RIGHT,100,25,age,0,1,material_kind)
				else:
					Ember.body(self,Vector2(150,100),Vector2(40,30),0.3,age,0,1,material_kind)
			elif material_only:
				var uvs := PackedVector2Array()
				for n in Ember.SEGMENTS:
					uvs.append(Vector2.from_angle(float(n)*TAU/Ember.SEGMENTS)*0.5+Vector2(material_kind*64+0.5,0.5))
				draw_polygon(Ember.body_points(Vector2(150,100),Vector2(40,40),0,0,0),PackedColorArray([Color(age,0,1,1)]),uvs)
			else:
				Ember.draw_projectile(self,{"pos":Vector2(150,125),"velocity":Vector2.RIGHT*450,"life":0.85-age,"kind":"ember"},Vector2.ZERO,age,false)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func capture(probe: Node2D) -> Image:
	probe.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
func _initialize() -> void:
	call_deferred("verify")
func verify() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Continuous shader verification requires graphics rendering")
		quit(1)
		return
	root.size = Vector2i(300,200)
	var probe := Probe.new()
	root.add_child(probe)
	var ordinary: Image = await capture(probe)
	Ember.prepare(probe)
	var passthrough: Image = await capture(probe)
	check(ordinary.get_data() == passthrough.get_data(),"Arena textures, tint and alpha pass through the VFX shader unchanged")
	probe.effects = true
	var previous: Image = await capture(probe)
	check(previous.get_data() != passthrough.get_data(),"Procedural flame actually renders")
	for step in 8:
		probe.age += 1.0/60
		var current: Image = await capture(probe)
		check(current.get_data() != previous.get_data(),"Shader flow advances at every consecutive frame")
		previous = current
	var paused: Image = await capture(probe)
	check(paused.get_data() == previous.get_data(),"Frozen simulation time freezes material flow as well as geometry")
	probe.material_only = true
	probe.age = 30.2
	var flowing: Image = await capture(probe)
	probe.age += 1.0/60
	var flowing_next: Image = await capture(probe)
	check(flowing.get_data() != flowing_next.get_data(),"Material flow continues beyond one second on fixed geometry")
	for kind in [1,2,3,5,6,7,8,9,12,13]:
		probe.material_kind = kind
		probe.age = 0.2
		var start: Image = await capture(probe)
		probe.age = 0.23
		var moved: Image = await capture(probe)
		check(start.get_data() != moved.get_data(),"Effect material %d changes continuously on actual rendered geometry" % kind)
		var held: Image = await capture(probe)
		check(moved.get_data() == held.get_data(),"Effect material %d freezes when simulation time is held" % kind)
	probe.cached = true
	for ribbon in [false,true]:
		probe.ribbon = ribbon
		for kind in ([2,6,9,13] if ribbon else [1,3,5,7,8,12]):
			probe.material_kind = kind
			probe.age = 2.1
			var start: Image = await capture(probe)
			check(start.get_data()!=passthrough.get_data(),"Cached effect %d is visibly rendered" % kind)
			probe.age += 0.03
			var moved: Image = await capture(probe)
			check(start.get_data()!=moved.get_data(),"Cached GPU geometry/material %d moves continuously" % kind)
			var frozen: Image = await capture(probe)
			check(moved.get_data()==frozen.get_data(),"Cached effect %d respects paused simulation" % kind)
			check(Ember.body_mesh(kind)==Ember.body_mesh(kind),"Body mesh is reused without per-frame allocation")
			check(Ember.ribbon_mesh(kind)==Ember.ribbon_mesh(kind),"Ribbon mesh is reused without per-frame allocation")
	probe.effects = false
	var cleaned: Image = await capture(probe)
	check(cleaned.get_data() == passthrough.get_data(),"Removing transient effects leaves no shader residue")
	print("Nightfall continuous shader render: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
