extends SceneTree
## Opt-in rendered stress measurement. Isolated profile, real AI/collision; no rewards saved.
var arena: Node2D
var frames := 0
var last_usec := 0
var intervals: Array[float] = []
var sections := {}
var physics_peak := 0.0
var target := 120
var output := "user://crowd-performance.json"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg.begins_with("--population="): target = int(arg.trim_prefix("--population="))
	call_deferred("start")

func start() -> void:
	arena = load("res://main.tscn").instantiate()
	arena.testing = true
	arena.profile = preload("res://profile.gd").new("user://crowd-performance-isolated.json")
	root.add_child(arena)
	root.title = "Nightfall performance measurement — isolated profile"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	arena.run.configure(1,arena.profile.stats())
	arena.run.elapsed = 165
	arena.run.spells = {"ember":{"rank":3,"branch":"spread","wait":0.1,"evolved":true},"chain":{"rank":3,"branch":"spread","wait":0.7,"evolved":true},"frost":{"rank":3,"branch":"focus","wait":1.1,"evolved":true}}
	arena.home.hide()
	arena.run.paused = false
	process_frame.connect(sample)

func sample() -> void:
	frames += 1
	var now := Time.get_ticks_usec()
	if frames > 90:
		intervals.append((now-last_usec)/1000.0)
		for key in arena.draw_profile:
			sections[key] = sections.get(key,0.0)+arena.draw_profile[key]
		physics_peak = maxf(physics_peak,arena.physics_ms)
	last_usec = now
	# Hold population and survival constant solely for like-for-like render pressure.
	arena.run.health = arena.run.max_health()
	if arena.run.phase == "upgrade": arena.run.choose_offer(0)
	if arena.run.phase == "shrine": arena.run.leave_shrine()
	arena.stick = Vector2.from_angle(arena.run.elapsed*0.6)
	while arena.run.enemies.size() < target:
		arena.run.spawn_enemy(false,["drifter","runner","spitter","bulwark","hexer"][arena.run.next_id%5])
	if frames >= 450:
		intervals.sort()
		var total := 0.0
		for duration in intervals: total += duration
		for key in sections: sections[key] /= intervals.size()
		var report := {"population":target,"samples":intervals.size(),"mean_ms":total/intervals.size(),"p95_ms":intervals[int(intervals.size()*0.95)],"physics_peak_ms":physics_peak,"draw_sections_ms":sections,"renderer":RenderingServer.get_current_rendering_method(),"resolution":str(root.size),"headless":DisplayServer.get_name()=="headless"}
		var file := FileAccess.open(output,FileAccess.WRITE)
		file.store_string(JSON.stringify(report,"\t"))
		print(JSON.stringify(report))
		quit()
