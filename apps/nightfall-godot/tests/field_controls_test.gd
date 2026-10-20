extends SceneTree
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
func _initialize() -> void:
	call_deferred("verify")
func settle() -> void:
	for frame in 4: await process_frame
func touch(at: Vector2, pressed: bool, index: int = 0) -> InputEventScreenTouch:
	var event=InputEventScreenTouch.new()
	event.position=at;event.pressed=pressed;event.index=index
	return event
func verify() -> void:
	var arena=load("res://main.tscn").instantiate()
	arena.testing=true
	root.add_child(arena)
	arena.set_physics_process(false)
	arena.home.hide()
	arena.run.configure(1,arena.profile.stats())
	arena.run.paused=false
	arena.run.spawn_wait=100;arena.run.fire_wait=100
	await settle()
	for pair in [[KEY_W,Vector2.UP],[KEY_UP,Vector2.UP],[KEY_A,Vector2.LEFT],[KEY_LEFT,Vector2.LEFT],[KEY_S,Vector2.DOWN],[KEY_DOWN,Vector2.DOWN],[KEY_D,Vector2.RIGHT],[KEY_RIGHT,Vector2.RIGHT]]:
		arena.run.player=arena.run.World.CENTER
		var event=InputEventKey.new()
		event.physical_keycode=pair[0];event.pressed=true
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		arena._physics_process(0.1)
		check((arena.run.player-arena.run.World.CENTER).normalized().is_equal_approx(pair[1]),"Keyboard moves correctly: "+OS.get_keycode_string(pair[0]))
		var released=event.duplicate()
		released.pressed=false;Input.parse_input_event(released)
		Input.flush_buffered_events()
	check(arena.touch_id==-1 and not arena.mouse_stick,"Keyboard leaves the floating stick hidden")
	for pair in [[KEY_UP,Vector2.UP],[KEY_LEFT,Vector2.LEFT],[KEY_DOWN,Vector2.DOWN],[KEY_RIGHT,Vector2.RIGHT]]:
		arena.run.player=arena.run.World.CENTER
		var event=InputEventKey.new()
		event.keycode=pair[0];event.pressed=true
		Input.parse_input_event(event);Input.flush_buffered_events()
		arena._physics_process(0.1)
		check((arena.run.player-arena.run.World.CENTER).normalized().is_equal_approx(pair[1]),"Logical Android arrow moves: "+OS.get_keycode_string(pair[0]))
		var released=event.duplicate()
		released.pressed=false;Input.parse_input_event(released);Input.flush_buffered_events()
		var stopped: Vector2=arena.run.player
		arena._physics_process(0.1)
		check(arena.run.player==stopped,"Released logical arrow stops movement")
	for origin in [Vector2(95,280),Vector2(340,310),Vector2(180,500)]:
		root.push_input(touch(origin,true),true)
		check(arena.touch_id==0 and arena.stick_origin==origin,"Touch anchors the stick at any free part of the field")
		var drag=InputEventScreenDrag.new()
		drag.index=0;drag.position=origin+Vector2(90,-20)
		root.push_input(drag,true)
		check(arena.stick.length()<=1.001 and arena.stick.x>0.9,"Floating stick follows held drag and clamps speed")
		root.push_input(touch(origin+Vector2(50,0),true,1),true)
		check(arena.touch_id==0 and arena.stick_origin==origin,"Second finger cannot steal the active movement stick")
		root.push_input(touch(origin,false,0),true)
		check(arena.touch_id==-1 and arena.stick==Vector2.ZERO and not arena.mouse_stick,"Release removes the stick and stops movement")
	arena.run.dodge_wait=0
	var button_at: Vector2=arena.dodge_button.get_global_rect().get_center()
	root.push_input(touch(button_at,true),true)
	root.push_input(touch(button_at,false),true)
	check(arena.touch_id==-1,"Dodge button touch is not captured as movement")
	check(arena.run.dodge_wait>0,"Touching Dodge triggers the actual dodge action")
	arena.run.paused=true
	root.push_input(touch(Vector2(200,300),true),true)
	check(arena.touch_id==-1,"Paused screens cannot start a movement gesture")
	arena.run.paused=false
	arena.home.show()
	arena.home.page="mission";arena.home.zone_index=0;arena.home.rebuild()
	await settle()
	var next=arena.home.find_child("NextZone",true,false)
	check(next!=null and not next.disabled,"Expedition exposes the shared next-zone arrow")
	next.pressed.emit();await settle()
	check(arena.home.zone_index==1,"Next arrow changes the zone island")
	check(arena.home.find_child("NextZone",true,false)!=null,"Browsing retains the zone arrows")
	arena.home.browse_zone(50);await settle()
	check(arena.home.zone_index==19 and arena.home.find_child("NextZone",true,false).disabled,"Zone browsing stops at the twentieth zone")
	arena.home.browse_zone(-50);await settle()
	check(arena.home.zone_index==0 and arena.home.find_child("PreviousZone",true,false).disabled,"Zone browsing stops at the first zone")
	arena.home.page="settings";arena.home.rebuild();await settle()
	for key in ["damage_numbers","health_bars"]:
		var setting=arena.home.find_child("Setting_"+key,true,false)
		check(setting!=null,"Settings expose "+key)
	arena.profile.data.settings.health_bars=false
	arena.home.hide();await settle()
	check(not arena.health_bar.visible,"Health-bar preference hides the actual hero HUD meter")
	arena.queue_free();await process_frame
	print("Field controls and navigation: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
